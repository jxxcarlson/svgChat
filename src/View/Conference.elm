module View.Conference exposing(view)

-- import Json.Decode as D
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Lamdera exposing (ClientId)
import Style
import Task
import Types exposing (..)
import Widget.Style
import Dict
import Svg exposing (Svg)
import Svg.Attributes
import Client
-- import Html.Events.Extra.Mouse as Mouse
import Widget.Bar
-- import Browser.Events

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
