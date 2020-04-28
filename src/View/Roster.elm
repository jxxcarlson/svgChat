module View.Roster exposing(view)

import Element exposing (Element, el, width, height, px, text, column, row, spacing, paddingXY)
import Element.Font as Font
import Lamdera exposing (ClientId)
import Types exposing (..)
import Dict
import Svg exposing (Svg)
import Svg.Attributes
import Widget.Bar
import Client
import Style

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
     row [spacing 8, fontColor ca] [
        el [width (px 25)] (text ca.handle)
        , el [width (px 88)] (Client.colorBar 60 ca.color.red ca.color.green ca.color.blue)
        , status ca
     ]
 in
  column [width (px 500), height (px 500), Font.size 16, spacing 6]
    (model.clientDict
      |> Dict.toList
      |> List.sortBy (\(id, ca) -> ca.handle)
      |> List.map renderItem)


fontColor ca =
  case ca.clientStatus of
    SignedOut -> Font.color Style.gray
    SignedIn -> Font.color Style.black

status : ClientAttributes -> Element FrontendMsg
status ca =
  case ca.clientStatus of
    SignedIn ->  el [Font.bold ] (text "here")
    SignedOut ->  el [Font.color Style.gray] (text "away")

clientColorBar : Float -> Float -> Float -> Element FrontendMsg
clientColorBar r g b =
  Widget.Bar.make 80
     |> Widget.Bar.withRGB r g b
     |> Widget.Bar.horizontal
     |> Widget.Bar.withSize 50
     |> Widget.Bar.toElement
