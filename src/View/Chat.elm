module View.Chat exposing(view)


import Json.Decode as D
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Lamdera exposing (ClientId)
import Task
import Types exposing (..)
import Widget.Style
import Dict
import Client
import Widget.Bar

type alias Model = FrontendModel

view : Model -> Html FrontendMsg
view model =
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

        MsgReceived message ->
            Html.div [] [ Html.text <| "[" ++ message.handle ++ "]: " ++ message.content ]


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
