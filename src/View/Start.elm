module View.Start exposing (view)

import Config
import Dict
import Element exposing (Element, centerX, centerY, column, el, fill, height, padding, paddingXY, px, row, spacing, text, width)
import Element.Background as Background
import Element.Font as Font
import Lamdera exposing (ClientId)
import Style
import Svg exposing (Svg)
import Svg.Attributes
import Types exposing (..)
import Widget.Button as Button exposing (Size(..))
import Widget.TextField as TextField exposing (LabelPosition(..))


type alias Model =
    FrontendModel


view : Model -> Element FrontendMsg
view model =
    column [ width fill, height fill, Background.color Style.black ]
        [ column [ centerX, centerY, width (px Config.playgroundWidth), height (px Config.playgroundWidth), Background.color Style.ochre ]
            [ signInUpModel model
            , el [ paddingXY 32 8, Font.size 16, Font.italic ] (text "Username: 2 to 6 characters")
            ]
        ]


signInUpModel : Model -> Element FrontendMsg
signInUpModel model =
    case model.appMode of
        StartMode SignInMode ->
            signIn model

        StartMode SignUpMode ->
            signUp model

        _ ->
            signIn model


signUp : Model -> Element FrontendMsg
signUp model =
    column [ spacing 12, padding 30 ]
        [ el [ Font.bold, Font.size 24 ] (Element.text "Sign up")
        , userHandleInput model
        , passwordInput model
        , repeatedPasswordInput model
        , signUpButton
        , cancelSignUpButton
        , el [ Font.size 14 ] (text model.message)
        ]


signIn : Model -> Element FrontendMsg
signIn model =
    column [ spacing 12, padding 30 ]
        [ el [ Font.bold, Font.size 24, paddingXY 0 20] (Element.text "Welcome to SVG Chat")
        , userHandleInput model
        , passwordInput model
        , joinChatButton
        , signUpModeButton
        , el [ Font.size 14 ] (text model.message)
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
    Button.make JoinChat "Sign in"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement


signUpButton =
    Button.make SignUp "Sign up"
        |> Button.withWidth (Bounded 120)
        |> Button.toElement


userHandleInput model =
    TextField.make GotUserHandle model.userHandle "Authentication name"
        |> TextField.withHeight 30
        |> TextField.withWidth 120
        |> TextField.withLabelWidth 120
        |> TextField.withLabelPosition LabelAbove
        |> TextField.toElement


passwordInput model =
    TextField.make GotPassword model.password "Password"
        |> TextField.withHeight 30
        |> TextField.withWidth 120
        |> TextField.withLabelWidth 70
        |> TextField.withLabelPosition LabelAbove
        |> TextField.toElement


repeatedPasswordInput model =
    TextField.make GotRepeatedPassword model.repeatedPassword "Password again"
        |> TextField.withHeight 30
        |> TextField.withWidth 120
        |> TextField.withLabelWidth 120
        |> TextField.withLabelPosition LabelAbove
        |> TextField.toElement
