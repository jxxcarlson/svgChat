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


view : Model -> Element FrontendMsg
view model =
  column [spacing 18, paddingXY 7 12] [
   row [spacing 4] [
     el [Font.size 18, width (px 164)] (text (clientInfo model))
    ]
  , row [spacing 12] [
     leaveChatButton  --,  deleteMeButton
   ]
  , row [spacing 12] [clearAllButton, clearMessageslButton]
  ]


clientInfo : Model -> String
clientInfo model =
      case Dict.get model.userHandle model.clientDict of
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

clearAllButton =
    Button.make RequestClearAllUsers "Clear all"
        |> Button.withWidth (Bounded 140)
        |> Button.toElement

clearMessageslButton =
    Button.make ClearMessages "Clear messages"
        |> Button.withWidth (Bounded 140)
        |> Button.toElement


deleteMeButton =
    Button.make DeleteMe "Delete me"
        |> Button.withWidth (Bounded 140)
        |> Button.toElement

leaveChatButton =
    Button.make LeaveChat "Leave chat"
        |> Button.withWidth (Bounded 140)
        |> Button.toElement
