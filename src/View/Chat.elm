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
    Html.div (HA.style "margin-top" "115px"::HA.style "background-color" "#f3fceb":: HA.style "padding" "10px" :: fontStyles)
        [ model.messages
            |> List.reverse
            |> List.map (viewMessage model)
            |> Html.div
                [ HA.id "message-box"
                , HA.style "height" "430px"
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
          case handleOfClient model clientId of
            Nothing -> Html.div [ HA.style "font-style" "italic" ] [ Html.text "" ]
            Just handle ->
               Html.div [ HA.style "font-style" "italic" ] [ Html.text <| handle ++ " joined the chat" ]

        ClientTimedOut clientId ->
          case handleOfClient model clientId of
            Nothing -> Html.div [ HA.style "font-style" "italic" ] [ Html.text "" ]
            Just handle ->
               Html.div [ HA.style "font-style" "italic" ] [ Html.text <| handle ++ " left the chat" ]

        UserLeftChat userHandle ->
            Html.div [ HA.style "font-style" "italic" ] [ Html.text <| userHandle ++ " left the chat" ]

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


handleOfClient : Model -> ClientId -> Maybe String
handleOfClient model clientId =
  let
    info = Dict.get clientId model.clientDict
  in
   Maybe.map .handle info
