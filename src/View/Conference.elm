module View.Conference exposing(view)

import Element exposing (Element, el, width, height, px, text, column, row, spacing, paddingXY)
import Element.Border as Border
import Element.Background as Background
import Style
import Html exposing(Html)
import Element exposing(Element)
import Lamdera exposing (ClientId)
import Types exposing (..)
import Dict
import Svg exposing (Svg)
import Svg.Attributes
import Widget.Bar
import Client

type alias Model = FrontendModel

view : Int -> Int  -> Model -> Element FrontendMsg
view width_ height_ model =
  column [ width (px width_), height (px height_), Border.width 1, Background.color Style.backgroundColor]
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
