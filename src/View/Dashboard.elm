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
  , userHandleInput model
  , joinChatButton
  ]


joinChatButton =
    Button.make JoinChat "Join chat"
        |> Button.withWidth (Bounded 100)
        -- |> Button.withSelected False
        |> Button.toElement

userHandleInput model  =
    TextField.make GotUserHandle model.userHandle "Handle (2-3 chars)"
        |> TextField.withHeight 30
        |> TextField.withWidth 80
        |> TextField.withLabelWidth 120
        |> TextField.toElement
