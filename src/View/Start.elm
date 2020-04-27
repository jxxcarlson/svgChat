module View.Start exposing(view)


import Element exposing (Element, el, centerX, centerY, width, height, padding, fill, px, text, column, row, spacing, paddingXY)
import Element.Font as Font
import Element.Background as Background
import Lamdera exposing (ClientId)
import Types exposing (..)
import Dict
import Svg exposing (Svg)
import Svg.Attributes
import Widget.Button as Button exposing(Size(..))
import Widget.TextField as TextField exposing(LabelPosition(..))
import Style


type alias Model = FrontendModel

view : Model -> Element FrontendMsg
view model =
  column [width fill, height fill, Background.color Style.black ] [
     column [centerX, centerY, width (px 500), height (px 500), Background.color Style.ochre] [
        signInUpModel model
     ]
  ]


signInUpModel : Model -> Element FrontendMsg
signInUpModel model =
  case model.appMode of
    StartMode SignInMode -> signIn model
    StartMode SignUpMode -> signUp model
    _ -> signIn model


signUp : Model -> Element FrontendMsg
signUp model =
    column [spacing 12, padding 30] [
      el [Font.bold, Font.size 24] (Element.text "Sign up")
     , userHandleInput model
     , passwordInput model, repeatedPasswordInput model
     , signUpButton, cancelSignUpButton
     , el [Font.size 14] (text model.message)
    ]


signIn : Model -> Element FrontendMsg
signIn model =
    column [spacing 12, padding 30] [
         el [Font.bold, Font.size 24] (Element.text "Sign in")
       , userHandleInput model
       , passwordInput model
       , joinChatButton
       , signUpModeButton
       , el [Font.size 14] (text model.message)
    ]



signUpModeButton =
    Button.make EnterSignUpMode "Sign up"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement

cancelSignUpButton =
    Button.make EnterSignInMode "Cancel"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement

joinChatButton =
    Button.make JoinChat "Join chat"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement

signUpButton =
    Button.make SignUp "Sign up"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement

userHandleInput model  =
    TextField.make GotUserHandle model.userHandle "Handle"
        |> TextField.withHeight 30
        |> TextField.withWidth  120
        |> TextField.withLabelWidth 120
        |> TextField.withLabelPosition LabelAbove
        |> TextField.toElement

passwordInput model  =
    TextField.make GotPassword model.password "Password"
        |> TextField.withHeight 30
        |> TextField.withWidth 120
        |> TextField.withLabelWidth 70
        |> TextField.withLabelPosition LabelAbove
        |> TextField.toElement

repeatedPasswordInput model  =
    TextField.make GotRepeatedPassword model.repeatedPassword "Password again"
        |> TextField.withHeight 30
        |> TextField.withWidth 120
        |> TextField.withLabelWidth 120
        |> TextField.withLabelPosition LabelAbove
        |> TextField.toElement
