module Frontend exposing (Model, app)

import Browser.Dom as Dom
import Debug exposing (toString)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Json.Decode as D
import Lamdera exposing (ClientId)
import Style
import Task
import Types exposing (..)
import Widget.Style
import Dict



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
        , subscriptions = \m -> Sub.none
        , onUrlChange = \_ -> Noop
        , onUrlRequest = \_ -> Noop
        }


type alias Model =
    FrontendModel


init : ( Model, Cmd FrontendMsg )
init =
    -- When the app loads, we have no messages and our message field is blank.
    -- We send an initial message to the backend, letting it know we've joined,
    -- so it knows to send us history and new messages
    ( { messages = [], messageFieldContent = "" , clientDict = Dict.empty}, Lamdera.sendToBackend ClientJoin )


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

        -- Empty msg that does no operations
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
           
    , Cmd.batch [ scrollChatToBottom ]
    )

view : Model -> Html FrontendMsg
view model =
   Element.layoutWith { options =
        [ focusStyle Widget.Style.noFocus ] } [] (mainView model)

mainView : Model -> Element FrontendMsg
mainView model =
  row [ spacing 12 ] [
      chatView model |> Element.html
    , svgView model
  ]

svgView : Model -> Element FrontendMsg
svgView model =
  column [alignTop, paddingXY 12 24, width (px 500), height (px 500), Background.color Style.lightBlue ] [
     el []( text "SVG: coming soon!")
  ]

chatView : Model -> Html FrontendMsg
chatView model =
    Html.div (HA.style "padding" "10px" :: fontStyles)
        [ model.messages
            |> List.reverse
            |> List.map (viewMessage model)
            |> Html.div
                [ HA.id "message-box"
                , HA.style "height" "400px"
                , HA.style "overflow" "auto"
                , HA.style "margin-bottom" "15px"
                ]
        , chatInput model MessageFieldChanged
        , Html.button (HE.onClick MessageSubmitted :: fontStyles) [ Html.text "Send" ]
        ]





chatInput : Model -> (String -> FrontendMsg) -> Html FrontendMsg
chatInput model msg =
    Html.input
        ([ HA.id "message-input"
         , HA.type_ "text"
         , HE.onInput msg
         , onEnter MessageSubmitted
         , HA.placeholder model.messageFieldContent
         , HA.value model.messageFieldContent
         , HA.style "width" "300px"
         , HA.autofocus True
         ]
            ++ fontStyles
        )
        []


viewMessage : Model -> ChatMsg -> Html msg
viewMessage model msg =
    case msg of
        ClientJoined clientId ->
            Html.div [ HA.style "font-style" "italic" ] [ Html.text <| (handleOfClient model clientId) ++ " joined the chat" ]

        ClientTimedOut clientId ->
            Html.div [ HA.style "font-style" "italic" ] [ Html.text <| (handleOfClient model clientId) ++ " left the chat" ]

        MsgReceived clientId message ->
            Html.div [] [ Html.text <| "[" ++ (handleOfClient model clientId) ++ "]: " ++ message ]


handleOfClient : Model -> ClientId -> String
handleOfClient model clientId =
  Dict.get clientId model.clientDict
    |> Maybe.map .handle
    |> Maybe.withDefault clientId

fontStyles : List (Html.Attribute msg)
fontStyles =
    [ HA.style "font-family" "Helvetica", HA.style "font-size" "14px", HA.style "line-height" "1.5" ]


scrollChatToBottom : Cmd FrontendMsg
scrollChatToBottom =
    Dom.getViewportOf "message-box"
        |> Task.andThen (\info -> Dom.setViewportOf "message-box" 0 info.scene.height)
        |> Task.attempt (\_ -> Noop)


focusOnMessageInputField : Cmd FrontendMsg
focusOnMessageInputField =
    Task.attempt (always Noop) (Dom.focus "message-input")


onEnter : FrontendMsg -> Html.Attribute FrontendMsg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                D.succeed msg

            else
                D.fail "not ENTER"
    in
    HE.on "keydown" (HE.keyCode |> D.andThen isEnter)


timeoutInMs =
    5 * 1000
