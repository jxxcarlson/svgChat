module View.Chat exposing(view)


import Json.Decode as D
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Element exposing (Element, el, alignTop, scrollbarY, width, height, px, text, column, row, spacing, paddingXY)
import Element.Border as Border
import Element.Font as Font
import Element.Background as Background
import Style
import Lamdera exposing (ClientId)
import Task
import Types exposing (..)
import Widget.Style
import Dict
import Client
import Widget.Bar

type alias Model = FrontendModel



view : Model -> Element FrontendMsg
view model =
  column [alignTop ] [
    column [ setId "message-box", height (px 500), width (px 300), scrollbarY, spacing 8, paddingXY 12 18
      , Font.size 14, Background.color Style.paleGreen]
    (model.messages
      |> List.reverse
      |> List.map (viewMessage model)
    )
    ,chatInput model MessageFieldChanged
 ]


setId id =
  Element.htmlAttribute (HA.id id)

chatInput : Model -> (String -> FrontendMsg) -> Element FrontendMsg
chatInput model msg =
    (Html.input
        ([ HA.id "message-input"
         , HA.type_ "text"
         , HE.onInput msg
         , onEnter MessageSubmitted
         , HA.style "margin-top" "12px"
         , HA.placeholder model.messageFieldContent
         , HA.value model.messageFieldContent
         , HA.style "width" "292px"
         , HA.autofocus True
         ]
            ++ fontStyles
        )
        [] )|> Element.html


viewMessage : Model -> ChatMsg -> Element msg
viewMessage model msg =
    case msg of
        ClientJoined clientId ->
          case handleOfClient model clientId of
            Nothing -> Element.none
            Just handle ->
              el [Font.italic] (text <| handle ++ " joined the chat")

        ClientTimedOut clientId ->
          case handleOfClient model clientId of
            Nothing -> Element.none
            Just handle ->
              el [Font.italic] (text <| handle ++ " left the chat")

        UserLeftChat userHandle ->
           el [Font.italic] (text <| userHandle ++ " joined the chat")

        MsgReceived message ->
          el [Font.italic] (text <| "[" ++ message.handle ++ "]: " ++ message.content )


fontStyles : List (Html.Attribute msg)
fontStyles =
    [ HA.style "font-family" "Helvetica", HA.style "font-size" "14px", HA.style "line-height" "1.5" ]


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



-- CLIENT HELPERS


handleOfClient : Model -> ClientId -> Maybe String
handleOfClient model clientId =
  let
    info = Dict.get clientId model.clientDict
  in
   Maybe.map .handle info
