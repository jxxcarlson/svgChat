module View.Roster exposing(view)

import Element exposing (Element, el, alignTop, width, height, scrollbarY, clipX, px, text, column, row, spacing, padding, paddingXY)
import Element.Font as Font
import Element.Background as Background
import Lamdera exposing (ClientId)
import Types exposing (..)
import Dict
import Svg exposing (Svg)
import Svg.Attributes
import Widget.Bar
import Client
import Style
import Config
import Time exposing (utc, toHour, toMinute, toSecond)


type alias Model = FrontendModel

view : Model -> Element FrontendMsg
view model =
  column [alignTop, spacing 12, width (px 420), scrollbarY,  clipX, padding 40, height (px 500), Background.color Style.paleGreen] [
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
        , timeSignedIn ca
     ]
 in
  column [width (px Config.playgroundWidth), height (px Config.playgroundWidth), Font.size 16, spacing 6]
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
    SignedIn ->  el [] (text "here since")
    SignedOut ->  el [Font.color Style.gray] (text "away")

timeSignedIn : ClientAttributes -> Element FrontendMsg
timeSignedIn ca =
  el [] (text (toUtcString ca.signInTime))


toUtcString : Time.Posix -> String
toUtcString time =
  (String.fromInt (toHour utc time) |> String.padLeft 2 '0')
  ++ ":" ++
  (String.fromInt (toMinute utc time) |> String.padLeft 2 '0')
  ++ ":" ++
  (String.fromInt (toSecond utc time) |> String.padLeft 2 '0')
  ++ " (UTC)"


clientColorBar : Float -> Float -> Float -> Element FrontendMsg
clientColorBar r g b =
  Widget.Bar.make 80
     |> Widget.Bar.withRGB r g b
     |> Widget.Bar.horizontal
     |> Widget.Bar.withSize 50
     |> Widget.Bar.toElement
