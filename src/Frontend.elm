module Frontend exposing (Model, app)

import Browser.Dom as Dom
import Html exposing (Html)
import Element exposing (Element, row, column, spacing, paddingXY, focusStyle)
import Element.Background as Background
import Style
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
import View.Dashboard as Dashboard
import View.Start as Start
import Crypto.HMAC exposing (sha256, sha512)
import Cmd.Extra exposing(withCmd, withCmds, withNoCmd)
import Config


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
      , userHandle = "XYZ"
      , password = ""
      , repeatedPassword = ""
      , appMode = StartMode SignInMode
      , message = ""
    }
      , Cmd.none
      )



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
                [ Lamdera.sendToBackend (MsgSubmitted model.userHandle model.messageFieldContent)
                , focusOnMessageInputField
                , scrollChatToBottom
                ]
            )

        DragStart ->
             ( {model | isDragging = True, dragState = Moving (toPosition model.dragState)}, Cmd.none )

        DragMove pos->
              let
                (clientAttributes, newDict ) = setClientPosition pos model.userHandle model.clientDict
              in
                 ( { model | dragState = if model.isDragging then Moving pos else Static (toPosition model.dragState)
                     , clientDict = newDict }
                 , Lamdera.sendToBackend (UpdateClientDict model.userHandle clientAttributes) )

        DragStop pos ->
             ( { model |isDragging = False, dragState = Static pos}, Cmd.none )

        GotUserHandle str ->
             ( {model | userHandle = str}, Cmd.none)

        GotPassword str ->
           ({ model | password = str }, Cmd.none)

        GotRepeatedPassword str ->
           ({ model | repeatedPassword = str }, Cmd.none)

        JoinChat  ->
          (model,  joinChat model.userHandle (encrypt model.password))

        SignUp ->
          case validateSignUp model of
            [] ->  (model, Lamdera.sendToBackend (CheckClientRegistration model.userHandle (encrypt model.password)) )
            errors -> ({model | message = String.join "; " errors}, Cmd.none)

        EnterSignUpMode ->
          ({ model | appMode = StartMode SignUpMode}, Cmd.none)

        EnterSignInMode ->
          ({ model | appMode = StartMode SignInMode}, Cmd.none)

        EnterChatMode ->
          ({ model | appMode = ChatMode}, Cmd.none)

        LeaveChat  ->
          ({ model | clientId = Nothing, appMode = StartMode SignInMode},  leaveChat model.userHandle)

        ClearChatRoom ->
          ({model | appMode = StartMode SignInMode}, clearChatRoom)

        Noop ->
            ( model, Cmd.none )


validateSignUp : Model -> List String
validateSignUp model =
  []
    |> passWordsMatch model.password model.repeatedPassword
    |> handleInRange model.userHandle



handleInRange : String -> List String -> List String
handleInRange passwd strings =
  if String.length passwd < 2 then
    "handle needs at least two characters" :: strings
  else if String.length passwd > 4 then
   "handle must be shorter than 4" :: strings
  else
    strings

passWordsMatch : String -> String -> List String -> List String
passWordsMatch p1 p2 strings =
  if p1 == p2 then
      strings
  else
    "passwords don't match" :: strings

{-| This is the added update function. It handles all messages that can arrive from the backend.
-}
updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        ClientJoinReceived clientId ->
            { model | messages = ClientJoined clientId :: model.messages }
             |> withCmd scrollChatToBottom

        RoomMsgReceived msgReceived ->
            { model | messages = MsgReceived msgReceived :: model.messages }
             |> withCmd scrollChatToBottom

        ClientTimeoutReceived clientId ->
            { model | messages = ClientTimedOut clientId :: model.messages }
             |> withCmd scrollChatToBottom

        FreshClientDict freshDict ->
           { model | clientDict = freshDict}  |> withNoCmd

        RegisterClientId clientId userHandle freshDict   ->
            {model | clientId = Just clientId
                    , userHandle = userHandle
                    , password = ""
                    , repeatedPassword = ""
                    , clientDict = freshDict
                    , appMode = ChatMode
                    , dragState = Static (clientPosition clientId freshDict)
                  } |> withNoCmd

        UpdateFrontEndClientDict newDict ->
           { model | clientDict = newDict } |> withNoCmd


        HandleAvailable clientId isAvailable ->
          case isAvailable of
            False -> { model | message = "Not available"} |> withNoCmd
            True -> { model | appMode = ChatMode } |> withNoCmd

        SystemMessage str ->
                  ({ model | message = str}, Cmd.none)

        AuthenticationFailure ->
          { model | message = "No match"} |> withNoCmd



-- HELPERS

joinChat str password =
  Lamdera.sendToBackend (ClientJoin (String.toUpper str) password)

encrypt : String -> String
encrypt str =
    Crypto.HMAC.digest sha512 "Fee, fie, fo fum said the green giant!" str

leaveChat str =
  Lamdera.sendToBackend (ClientLeave str)
{-| This is the normal frontend update function. It handles all messages that can occur on the frontend.
-}

clearChatRoom  =
  Lamdera.sendToBackend InitClientDict


-- VIEW

view : Model -> Html FrontendMsg
view model =
   Element.layoutWith { options =
        [ focusStyle Widget.Style.noFocus ] } [ Background.color Style.warmMediumGray] (mainView model)


mainView : Model -> Element FrontendMsg
mainView model =
  case model.appMode of
    StartMode _ -> Start.view model
    ChatMode -> chatView model

chatView : Model -> Element FrontendMsg
chatView model =
  row [ spacing 12, paddingXY 60 60 ] [
      column [spacing 12] [
         Chat.view model
       , Dashboard.view model
      ]
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


setClientPosition : Position -> String -> ClientDict -> (ClientAttributes, ClientDict)
setClientPosition pos userHandle clientDict =
      -- TODO: remove magic numbers
      case Dict.get userHandle clientDict of
        Nothing -> (Client.defaultAttributes, clientDict)
        Just info ->
          let
            newInfo = {info | x = pos.x - Config.dragOffsetX, y = pos.y - Config.dragOffsetY }
          in
            (newInfo, Dict.insert userHandle newInfo clientDict)
