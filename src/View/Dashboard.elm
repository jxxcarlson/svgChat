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


type alias Model = FrontendModel
--
-- view : Model -> Element FrontendMsg
-- view model =
--   case model.clientId of
--     Nothing -> signInUpModel model
--     Just clientId -> dashboard model


view : Model -> Element FrontendMsg
view model =
  column [spacing 12] [
    el [Font.bold, Font.size 24] (Element.text "Dashboard")
  , row [spacing 12] [
     leaveChatButton, gotoSignInButton, clearChatRoonButton
    ]
  ]


gotoSignInButton =
       Button.make EnterSignInMode "Sign in"
           |> Button.withWidth (Bounded 120)
           |> Button.toElement



clearChatRoonButton =
    Button.make ClearChatRoom "Clear chat room"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement

leaveChatButton =
    Button.make LeaveChat "Leave chat"
        |> Button.withWidth (Bounded 100)
        |> Button.toElement
