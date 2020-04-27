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

view : Model -> Element FrontendMsg
view model =
  column [spacing 12] [
    el [Font.bold, Font.size 24] (Element.text "Dashboard")
  , row [spacing 12] [
     userHandleInput model, joinChatButton, leaveChatButton
    ]
  , row [spacing 12] [clearChatRoonButton ]
  ]




clearChatRoonButton =
    Button.make ClearChatRoom "Clear chat room"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement

leaveChatButton =
    Button.make LeaveChat "Leave chat"
        |> Button.withWidth (Bounded 100)
        |> Button.toElement

joinChatButton =
    Button.make JoinChat "Join chat"
        |> Button.withWidth (Bounded 100)
        |> Button.toElement

userHandleInput model  =
    TextField.make GotUserHandle model.userHandle "Handle (2-3 chars)"
        |> TextField.withHeight 30
        |> TextField.withWidth 80
        |> TextField.withLabelWidth 120
        |> TextField.toElement


passwordInput model  =
    TextField.make GotPassword model.password "Password"
        |> TextField.withHeight 30
        |> TextField.withWidth 80
        |> TextField.withLabelWidth 120
        |> TextField.toElement

repeatedPasswordInput model  =
    TextField.make GotRepeatedPassword model.password "Password again"
        |> TextField.withHeight 30
        |> TextField.withWidth 80
        |> TextField.withLabelWidth 120
        |> TextField.toElement
