module View.Dashboard exposing(view)

import Element exposing (Element, el, width, height, px, text, column, row, spacing, paddingXY)
import Element.Font as Font
import Lamdera exposing (ClientId)
import Types exposing (..)
import Dict
import Svg exposing (Svg)
import Svg.Attributes
import Widget.Button as Button exposing(Size(..))
import Widget.TextField as TextField
import Widget.Bar
import Client



type alias Model = FrontendModel
--
-- view : Model -> Element FrontendMsg
-- view model =
--   case model.clientId of
--     Nothing -> signInUpModel model
--     Just clientId -> dashboard model


view : Model -> Element FrontendMsg
view model =
  column [spacing 18, paddingXY 7 24] [
   row [spacing 4] [
     el [Font.size 18, width (px 144)] (text (clientInfo model))
     , clientColorBar model
    ]
  , row [spacing 12] [
     leaveChatButton, clearChatRoonButton
   ]
  ]


clientColorBar : Model -> Element FrontendMsg
clientColorBar model =
  case model.clientId of
    Nothing -> Element.none
    Just clientId ->
      case Dict.get clientId model.clientDict of
        Nothing -> Element.none
        Just ca ->
          Client.colorBar 102 ca.color.red ca.color.green ca.color.blue

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
            x = info.x |> roundTo 0 |> String.fromFloat
            y = info.y |> roundTo 0 |> String.fromFloat
          in
            handle ++ ", x: " ++ x ++ ", y: " ++ y


roundTo : Int -> Float -> Float
roundTo k x =
  let
    factor = 10.0 ^ (toFloat k)
    xx = round (factor * x) |> toFloat
  in
   xx/factor

gotoSignInButton =
       Button.make EnterSignInMode "Sign in"
           |> Button.withWidth (Bounded 120)
           |> Button.toElement



clearChatRoonButton =
    Button.make ClearChatRoom "Clear chat room"
        |> Button.withWidth (Bounded 130)
        |> Button.toElement

leaveChatButton =
    Button.make LeaveChat "Leave chat"
        |> Button.withWidth (Bounded 130)
        |> Button.toElement
