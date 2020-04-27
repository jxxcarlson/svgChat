module Frontend exposing (Model, app)

import Browser.Dom as Dom
import Html exposing (Html)
import Element exposing (Element, row, spacing, paddingXY, focusStyle)
import Json.Decode as D
import Lamdera exposing (ClientId)
import Task
import Types exposing (..)
import Widget.Style
import Dict
import Svg exposing (Svg)
import Client
import Html.Events.Extra.Mouse as Mouse
import Browser.Events
import View.Roster as Roster
import View.Conference as Conference
import View.Chat as Chat



{-| Lamdera applications define 'app' instead of 'main'.

Lamdera.frontend is the same as Browser.application with the
additional update function; updateFromBackend.

-}
app =
    Lamdera.frontend
        { init = \_ _ -> init
        , update = update
        , updateFromBackend = updateFromBackend
        , view =
            \model ->
                { title = "Lamdera chat demo"
                , body = [ view model ]
                }
        , subscriptions = subscriptions
        , onUrlChange = \_ -> Noop
        , onUrlRequest = \_ -> Noop
        }


type alias Model =
    FrontendModel

subscriptions model = case model.dragState of
    Static _ ->
      Sub.none

    Moving _  ->
      Sub.batch
        [ Browser.Events.onMouseMove (D.map DragMove Client.decodePosition)
        , Browser.Events.onMouseUp ( D.map DragStop Client.decodePosition)
        ]


init : ( Model, Cmd FrontendMsg )
init =
    -- When the app loads, we have no messages and our message field is blank.
    -- We send an initial message to the backend, letting it know we've joined,
    -- so it knows to send us history and new messages
    ( { messages = []
      , messageFieldContent = ""
      , clientDict = Dict.empty
      , clientId = Nothing
      , isDragging = False
      , dragState = Static { x = 50, y = 50 }
    }
      , Lamdera.sendToBackend ClientJoin )


{-| This is the normal frontend update function. It handles all messages that can occur on the frontend.
-}
update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        -- User has changed the contents of the message field
        MessageFieldChanged s ->
            ( { model | messageFieldContent = s }, Cmd.none )

        -- User has hit the Send button
        MessageSubmitted ->
            ( { model | messageFieldContent = "", messages = model.messages }
            , Cmd.batch
                [ Lamdera.sendToBackend (MsgSubmitted model.messageFieldContent)
                , focusOnMessageInputField
                , scrollChatToBottom
                ]
            )

        DragStart ->
             ( {model | isDragging = True, dragState = Moving (toPosition model.dragState)}, Cmd.none )

        DragMove pos->
          case model.clientId of
            Nothing -> (model, Cmd.none)
            Just clientId ->
              let
                -- pos_ = { x = clamp 20 480 pos.x, y = clamp 20 480 pos.y}
                -- TODO: remove magic numbers
                (clientAttributes, newDict ) = setClientPosition pos clientId model.clientDict
              in
                 ( { model | dragState = if model.isDragging then Moving pos else Static (toPosition model.dragState)
                     , clientDict = newDict }
                 , Lamdera.sendToBackend (UpdateClientDict clientId clientAttributes) )

        DragStop pos ->
             ( { model |isDragging = False, dragState = Static pos}, Cmd.none )

        Noop ->
            ( model, Cmd.none )


{-| This is the added update function. It handles all messages that can arrive from the backend.
-}
updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    ( case msg of
        ClientJoinReceived clientId ->
            { model | messages = ClientJoined clientId :: model.messages }

        RoomMsgReceived ( clientId, text ) ->
            { model | messages = MsgReceived clientId text :: model.messages }

        ClientTimeoutReceived clientId ->
            { model | messages = ClientTimedOut clientId :: model.messages }

        FreshClientDict freshDict ->
           { model | clientDict = freshDict}

        RegisterClientId clientId freshDict   ->
            {model | clientId = Just clientId
                    , clientDict = freshDict
                    , dragState = Static (clientPosition clientId freshDict)
                  }

        UpdateFrontEndClientDict newDict ->
           { model | clientDict = newDict }


    , Cmd.batch [ scrollChatToBottom ]
    )

view : Model -> Html FrontendMsg
view model =
   Element.layoutWith { options =
        [ focusStyle Widget.Style.noFocus ] } [] (mainView model)

mainView : Model -> Element FrontendMsg
mainView model =
  row [ spacing 48, paddingXY 40 20 ] [
      Chat.view model  |> Element.html
    , Conference.view 502 502 model
    , Roster.view model

  ]




timeoutInMs =
    5 * 1000


-- CLIENT HELPERS

clientPosition : ClientId -> ClientDict -> Position
clientPosition clientId clientDict =
      case Dict.get clientId clientDict of
        Nothing -> { x = 50, y = 50}
        Just info -> { x = info.x, y = info.x }


scrollChatToBottom : Cmd FrontendMsg
scrollChatToBottom =
    Dom.getViewportOf "message-box"
        |> Task.andThen (\info -> Dom.setViewportOf "message-box" 0 info.scene.height)
        |> Task.attempt (\_ -> Noop)


focusOnMessageInputField : Cmd FrontendMsg
focusOnMessageInputField =
    Task.attempt (always Noop) (Dom.focus "message-input")



toPosition : DragState -> Position
toPosition dragState =
  case dragState of
    Static pos -> pos
    Moving pos -> pos


setClientPosition : Position -> ClientId -> ClientDict -> (ClientAttributes, ClientDict)
setClientPosition pos clientId clientDict =
      case Dict.get clientId clientDict of
        Nothing -> (Client.defaultAttributes, clientDict)
        Just info ->
          let
            newInfo = {info | x = pos.x - 440, y = pos.y - 20 }
          in
            (newInfo, Dict.insert clientId newInfo clientDict)
