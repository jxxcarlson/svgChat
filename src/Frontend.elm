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
import Svg exposing (Svg)
import Svg.Attributes
import Client
import Html.Events.Extra.Mouse as Mouse
import Widget.Bar



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
    ( { messages = []
      , messageFieldContent = ""
      , clientDict = Dict.empty
      , clientId = Nothing
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
        SvgMsg clientAttributes ->
          case model.clientId of
            Nothing ->  (model, Cmd.none)
            Just clientId ->
              let
                newDict = Dict.insert clientId clientAttributes model.clientDict
              in
                ({ model | clientDict = newDict }, Cmd.none )
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

        RegisterClientId clientId ->
            {model | clientId = Just clientId}

    , Cmd.batch [ scrollChatToBottom ]
    )

view : Model -> Html FrontendMsg
view model =
   Element.layoutWith { options =
        [ focusStyle Widget.Style.noFocus ] } [] (mainView model)

mainView : Model -> Element FrontendMsg
mainView model =
  row [ spacing 24, paddingXY 40 20 ] [
      chatView model  |> Element.html
    , conferenceRoom 502 502 model
    , roster model

  ]


roster : Model -> Element FrontendMsg
roster model =
  column [spacing 12] [
    el [Font.bold, Font.size 24] (Element.text "Roster")
    , roster_ model
  ]

roster_ : Model -> Element FrontendMsg
roster_ model =
 let
   renderItem : (ClientId, ClientAttributes) -> Element FrontendMsg
   renderItem (clientId, ca) =
     row [spacing 8] [
        el [width (px 30)] (text ca.handle)
        , clientColorBar ca.color.red ca.color.green ca.color.blue
     ]
 in
  column [width (px 500), height (px 500), Font.size 16, spacing 6]
    (model.clientDict
      |> Dict.toList
      |> List.map renderItem)

clientColorBar : Float -> Float -> Float -> Element FrontendMsg
clientColorBar r g b =
  Widget.Bar.make 80
     |> Widget.Bar.withRGB r g b
     |> Widget.Bar.horizontal
     |> Widget.Bar.withSize 50
     |> Widget.Bar.toElement


conferenceRoom : Int -> Int  -> Model -> Element FrontendMsg
conferenceRoom width_ height_ model =
  column [ width (px width_), height (px height_), Border.width 1]
    [renderSVGAsHtml 500 500 model.clientDict |> Element.html]

renderSVGAsHtml : Int -> Int  -> ClientDict -> Html FrontendMsg
renderSVGAsHtml width height clientDict =
    Svg.svg
        [ Svg.Attributes.height (String.fromInt height)
        , Svg.Attributes.width (String.fromInt width)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt width ++ " " ++ String.fromInt height)
        ]
        [ renderAsSvg  width  height clientDict ]


renderAsSvg : Int -> Int -> ClientDict -> Svg FrontendMsg
renderAsSvg width  height clientDict =
    let
       entities = Dict.toList clientDict
         |> List.map (Tuple.second >> Client.render)
         |> List.foldr (::) []

       br : Svg FrontendMsg
       br = backGroundRectangle width height {red = 0.10, green = 0.10, blue =  0.15}
    in
    Svg.g [] (entities)

backGroundRectangle : Int -> Int -> Types.Color -> Svg FrontendMsg
backGroundRectangle width height color =
    Svg.rect
        [ Svg.Attributes.width (String.fromInt width)
        , Svg.Attributes.height (String.fromInt height)
        , Svg.Attributes.x (String.fromFloat 0)
        , Svg.Attributes.y (String.fromFloat 0)
        , Svg.Attributes.fill (Client.toCssString color)
        ]
        []


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
        , Html.p [] [Html.text (clientInfo model)]
        ]


clientInfo : Model -> String
clientInfo model =
  case model.clientId of
    Nothing -> "---"
    Just clientId ->
      case Dict.get clientId model.clientDict of
        Nothing -> "---"
        Just info ->
          let
            handle = info.handle
            x = info.x |> roundTo 1 |> String.fromFloat
            y = info.y |> roundTo 1 |> String.fromFloat
          in
            handle ++ ", x: " ++ x ++ ", y: " ++ y

roundTo : Int -> Float -> Float
roundTo k x =
  let
    factor = 10.0 ^ (toFloat k)
    xx = round (factor * x) |> toFloat
  in
   xx/factor

handleOfClient : Model -> ClientId -> String
handleOfClient model clientId =
  let
    info = Dict.get clientId model.clientDict
    handle = info
      |> Maybe.map .handle
      |> Maybe.withDefault "AAA"
  in
    handle

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
