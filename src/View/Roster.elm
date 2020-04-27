module View.Roster exposing(view)
--
-- import Browser.Dom as Dom
-- import Html exposing (Html)
-- import Html.Attributes as HA
-- import Html.Events as HE
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
-- import Json.Decode as D
import Lamdera exposing (ClientId)
import Style
import Task
import Types exposing (..)
import Widget.Style
import Dict
import Svg exposing (Svg)
import Svg.Attributes
-- import Client
-- import Html.Events.Extra.Mouse as Mouse
import Widget.Bar
-- import Browser.Events

type alias Model = FrontendModel

view : Model -> Element FrontendMsg
view model =
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
        -- , clientColorBar ca.color.red ca.color.green ca.color.blue
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
