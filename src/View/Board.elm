module View.Board exposing (view)

import Client
import Config
import Dict
import Element exposing (Element, alignTop, column, el, height, paddingXY, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html)
import Lamdera exposing (ClientId)
import Style
import Svg exposing (Svg)
import Svg.Attributes
import Types exposing (..)
import Widget.Bar


type alias Model =
    FrontendModel


view : Int -> Int -> Model -> Element FrontendMsg
view width_ height_ model =
    column [ alignTop, width (px width_), height (px height_), Border.width 1, Background.color Style.backgroundColor ]
        [ renderSVGAsHtml Config.playgroundWidth Config.playgroundHeight model.clientDict |> Element.html ]


renderSVGAsHtml : Int -> Int -> ClientDict -> Html FrontendMsg
renderSVGAsHtml width height clientDict =
    Svg.svg
        [ Svg.Attributes.height (String.fromInt height)
        , Svg.Attributes.width (String.fromInt width)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt width ++ " " ++ String.fromInt height)
        ]
        [ renderAsSvg width height clientDict ]


renderAsSvg : Int -> Int -> ClientDict -> Svg FrontendMsg
renderAsSvg width height clientDict =
    let
        entities =
            Dict.toList clientDict
                |> List.map Tuple.second
                |> List.filter (\attr -> attr.clientStatus == SignedIn)
                |> List.map Client.render
                |> List.foldr (::) []

        br : Svg FrontendMsg
        br =
            backGroundRectangle width height { red = 0.1, green = 0.1, blue = 0.15 }
    in
    Svg.g [] entities


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
