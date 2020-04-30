module View.Roster exposing (view)

import Client
import Config
import Dict
import Element exposing (Element, alignTop, clipX, column, el, height, padding, paddingXY, px, row, scrollbarY, spacing, text, width)
import Element.Background as Background
import Element.Font as Font
import Lamdera exposing (ClientId)
import Style
import Svg exposing (Svg)
import Svg.Attributes
import Time exposing (toHour, toMinute, toSecond, utc)
import Types exposing (..)
import Widget.Bar


type alias Model =
    FrontendModel


view : Model -> Element FrontendMsg
view model =
    let
        clientList =
            Dict.toList model.clientDict

        n =
            List.length clientList
    in
    column [ alignTop, spacing 12, width (px 320), scrollbarY, clipX, paddingXY 30 30, height (px 500), Background.color Style.paleGreen ]
        [ el [ Font.bold, Font.size 18 ] (Element.text <| "Attendees (" ++ String.fromInt n ++ ")")
        , roster_ model clientList
        ]


roster_ : Model -> List ( String, ClientAttributes ) -> Element FrontendMsg
roster_ model clientList =
    let
        renderItem : ( ClientId, ClientAttributes ) -> Element FrontendMsg
        renderItem ( clientId, ca ) =
            row [ spacing 8, fontColor ca ]
                [ el [ width (px 25) ] (text ca.handle)
                , el [ width (px 88) ] (Client.colorBar 60 ca.color.red ca.color.green ca.color.blue)
                , status model ca
                ]
    in
    column [ Font.size 16, spacing 6 ]
        (clientList
            |> List.sortBy (\( id, ca ) -> ca.handle)
            |> List.map renderItem
        )


fontColor ca =
    case ca.clientStatus of
        SignedOut ->
            Font.color Style.gray

        SignedIn ->
            Font.color Style.black


status : Model -> ClientAttributes -> Element FrontendMsg
status model ca =
    case ca.clientStatus of
        SignedIn ->
            el [] (text ("here since " ++ toLocalTimeString model.zone ca.signInTime))

        SignedOut ->
            el [ Font.color Style.gray ] (text "away")


toLocalTimeString : Time.Zone -> Time.Posix -> String
toLocalTimeString zone time =
    (String.fromInt (toHour zone time) |> String.padLeft 2 '0')
        ++ ":"
        ++ (String.fromInt (toMinute zone time) |> String.padLeft 2 '0')


toUtcString : Time.Posix -> String
toUtcString time =
    (String.fromInt (toHour utc time) |> String.padLeft 2 '0')
        ++ ":"
        ++ (String.fromInt (toMinute utc time) |> String.padLeft 2 '0')


clientColorBar : Float -> Float -> Float -> Element FrontendMsg
clientColorBar r g b =
    Widget.Bar.make 80
        |> Widget.Bar.withRGB r g b
        |> Widget.Bar.horizontal
        |> Widget.Bar.withSize 50
        |> Widget.Bar.toElement
