module Frontend exposing (Model, app)

import Authentication
import Browser.Dom as Dom
import Browser.Events
import Client
import Cmd.Extra exposing (withCmd, withCmds, withNoCmd)
import Config
import Dict
import Element exposing (Element, column, alignTop, focusStyle, paddingXY, row, spacing)
import Element.Background as Background
import Html exposing (Html)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as D
import Lamdera exposing (ClientId)
import Style
import Svg exposing (Svg)
import Task
import Time
import Types exposing (..)
import View.Chat as Chat
import View.Board as Board
import View.Dashboard as Dashboard
import View.Roster as Roster
import View.Start as Start
import Widget.Style
import Widget.Button as Button exposing(Size(..))
import Config


{-| Lamdera applications define 'app' instead of 'main'.

Lamdera.frontend is the same as Browser.application with the
additional update function; updateFromBackend.

-}
app =
    Lamdera.frontend
        { init = \_ _ -> init
        , update = update
        , updateFromBackend = updateFromBackend
        , view =
            \model ->
                { title = "SVG Chat"
                , body = [ view model ]
                }
        , subscriptions = subscriptions
        , onUrlChange = \_ -> Noop
        , onUrlRequest = \_ -> Noop
        }


type alias Model =
    FrontendModel


subscriptions model =
    case model.dragState of
        Static _ ->
            Browser.Events.onMouseDown (D.map DragStart Client.decodePosition)

        Moving _ ->
            Sub.batch
                [ Browser.Events.onMouseMove (D.map DragMove Client.decodePosition)
                , Browser.Events.onMouseUp (D.map DragStop Client.decodePosition)
                ]


init : ( Model, Cmd FrontendMsg )
init =
    -- When the app loads, we have no messages and our message field is blank.
    -- We send an initial message to the backend, letting it know we've joined,
    -- so it knows to send us history and new messages
    ( { messages = []
      , messageFieldContent = ""
      , clientDict = Dict.empty
      , clientId = Nothing
      , isDragging = False
      , dragState = Static { x = 50, y = 50 }
      , userHandle = ""
      , password = ""
      , repeatedPassword = ""
      , appMode = StartMode SignInMode
      , message = ""
      , panelSelected = RosterPanel
      , zone = Time.utc
      }
    , Task.perform AdjustTimeZone Time.here
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        -- Authentication has changed the contents of the message field
        MessageFieldChanged s ->
            ( { model | messageFieldContent = s }, Cmd.none )

        -- Authentication has hit the Send button
        MessageSubmitted ->
            ( { model | messageFieldContent = "", messages = model.messages }
            , Cmd.batch
                [ Lamdera.sendToBackend (MsgSubmitted model.userHandle model.messageFieldContent)
                , focusOnMessageInputField
                , scrollChatToBottom
                ]
            )

        DragStart pos ->
            case inBounds pos of
                False ->
                    model |> withNoCmd

                True ->
                    let
                        data =
                            setClientPosition pos model.userHandle model.clientDict
                    in
                    case data of
                        Nothing ->
                            ( model, Cmd.none )

                        Just ( clientAttributes, newDict ) ->
                            ( { model
                                | isDragging = True
                                , clientDict = newDict
                                , dragState = Moving (toPosition model.dragState)
                              }
                            , Lamdera.sendToBackend (UpdateClientDict model.userHandle clientAttributes)
                            )

        DragMove pos ->
            case inBounds pos of
                False ->
                    model |> withNoCmd

                True ->
                    let
                        data =
                            setClientPosition pos model.userHandle model.clientDict
                    in
                    case data of
                        Nothing ->
                            ( model, Cmd.none )

                        Just ( clientAttributes, newDict ) ->
                            ( { model
                                | dragState =
                                    if model.isDragging then
                                        Moving pos

                                    else
                                        Static (toPosition model.dragState)
                                , clientDict = newDict
                              }
                            , Lamdera.sendToBackend (UpdateClientDict model.userHandle clientAttributes)
                            )

        DragStop pos ->
            ( { model | isDragging = False, dragState = Static pos }, Cmd.none )

        GotUserHandle str ->
            ( { model | userHandle = str }, Cmd.none )

        GotPassword str ->
            ( { model | password = str }, Cmd.none )

        GotRepeatedPassword str ->
            ( { model | repeatedPassword = str }, Cmd.none )

        JoinChat ->
            ( model, joinChat model.userHandle (Client.encrypt model.password) )

        ClearMessages ->
            ( { model | messages = [] }, Cmd.none )

        SignUp ->
            case Authentication.validateSignUp model.userHandle model.password model.repeatedPassword of
                [] ->
                    ( model, Lamdera.sendToBackend (CheckClientRegistration model.userHandle (Client.encrypt model.password)) )

                errors ->
                    ( { model | message = String.join "; " errors }, Cmd.none )

        EnterSignUpMode ->
            ( { model | appMode = StartMode SignUpMode }, Cmd.none )

        EnterSignInMode ->
            ( { model | appMode = StartMode SignInMode }, Cmd.none )

        EnterChatMode ->
            ( { model | appMode = ConferenceMode }, Cmd.none )

        LeaveChat ->
            ( { model | clientId = Nothing, appMode = StartMode SignInMode }, leaveChat model.userHandle )

        DeleteMe ->
            ( { model | appMode = StartMode SignInMode }, deleteMe model.userHandle )

        RequestClearAllUsers ->
            ( { model | appMode = StartMode SignInMode }, clearAll )

        AdjustTimeZone newZone ->
            { model | zone = newZone } |> withCmd Cmd.none

        SelectPanel panel ->
          { model | panelSelected = panel } |> withNoCmd

        Noop ->
            ( model, Cmd.none )




{-| This is the added update function. It handles all messages that can arrive from the backend.
-}
updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        ClientJoinReceived clientId ->
            { model | messages = ClientJoined clientId :: model.messages }
                |> withCmd scrollChatToBottom

        RoomMsgReceived msgReceived ->
            { model | messages = MsgReceived msgReceived :: model.messages }
                |> withCmd scrollChatToBottom

        ClientTimeoutReceived clientId ->
            { model | messages = ClientTimedOut clientId :: model.messages }
                |> withCmd scrollChatToBottom

        FreshClientDict freshDict ->
            { model | clientDict = freshDict } |> withNoCmd

        RegisterClientId clientId userHandle freshDict ->
            { model
                | clientId = Just clientId
                , userHandle = userHandle
                , password = ""
                , repeatedPassword = ""
                , clientDict = freshDict
                , appMode = ConferenceMode
                , dragState = Static (clientPosition userHandle freshDict)
            }
                |> withNoCmd

        UpdateFrontEndClientDict newDict ->
            { model | clientDict = newDict } |> withNoCmd

        HandleAvailable clientId isAvailable ->
            case isAvailable of
                False ->
                    { model | message = "Not available" } |> withNoCmd

                True ->
                    { model | appMode = ConferenceMode } |> withNoCmd

        SystemMessage str ->
            ( { model | message = str }, Cmd.none )

        Failure message ->
            { model | message = message } |> withNoCmd



-- VIEW


view : Model -> Html FrontendMsg
view model =
    Element.layoutWith
        { options =
            [ focusStyle Widget.Style.noFocus]
        }
        [ Background.color Style.warmMediumGray, Element.clipX, Element.clipY  ]
        (mainView model)


mainView : Model -> Element FrontendMsg
mainView model =
    case model.appMode of
        StartMode _ ->
            Start.view model

        ConferenceMode ->
            viewBoard model


viewBoard : Model -> Element FrontendMsg
viewBoard model =
  row [] [
      Board.view Config.playgroundWidth Config.playgroundHeight model
    , column [] [
        menuBar model
       , case model.panelSelected of
           ChatPanel -> Chat.view model
           RosterPanel -> Roster.view model
       , Dashboard.view model
    ]
    ]

menuBar model =
  row [alignTop] [ chooseRoster model, chooseChat model ]

chooseRoster model =
    Button.make (SelectPanel RosterPanel) "Roster"
        |> Button.withWidth (Bounded 158)
        |> Button.withSelected (model.panelSelected == RosterPanel)
        |> Button.toElement

chooseChat model =
    Button.make (SelectPanel ChatPanel) "Chat"
        |> Button.withWidth (Bounded 159)
        |> Button.withSelected (model.panelSelected == ChatPanel)
        |> Button.toElement
    --
    -- row [ spacing 12, paddingXY 60 60 ]
    --     [ column [ spacing 12 ]
    --         [ Chat.view model
    --         , Dashboard.view model
    --         ]
    --     , Board.view 502 502 model
    --     , Roster.view model
    --     ]


timeoutInMs =
    5 * 1000



-- HELPERS: SIGN IN, SIGN UP, MANAGE USER


deleteMe userHandle =
    Lamdera.sendToBackend (DeleteUser userHandle)



-- CHAT HELPERS


clearMessages =
    Lamdera.sendToBackend ClearStoredMessages


joinChat str password =
    Lamdera.sendToBackend (ClientJoin str password)


leaveChat str =
    Lamdera.sendToBackend (ClientLeave str)



scrollChatToBottom : Cmd FrontendMsg
scrollChatToBottom =
    Dom.getViewportOf "message-box"
        |> Task.andThen (\info -> Dom.setViewportOf "message-box" 0 info.scene.height)
        |> Task.attempt (\_ -> Noop)


focusOnMessageInputField : Cmd FrontendMsg
focusOnMessageInputField =
    Task.attempt (always Noop) (Dom.focus "message-input")



-- USER TOKEN GRAPHICS

{-| Is the point inside the Board?
-}
inBounds : Position -> Bool
inBounds pos =
    pos.x
        > Config.cornerX
        && pos.x
        < Config.cornerX
        + Config.playgroundWidth
        && pos.y
        > Config.cornerY
        && pos.y
        < Config.cornerY
        + Config.playgroundHeight




clientPosition : UserHandle -> ClientDict -> Position
clientPosition userHandle clientDict =
    case Dict.get userHandle clientDict of
        Nothing ->
            { x = 50, y = 50 }

        Just info ->
            { x = info.x, y = info.x }

toPosition : DragState -> Position
toPosition dragState =
    case dragState of
        Static pos ->
            pos

        Moving pos ->
            pos


setClientPosition : Position -> String -> ClientDict -> Maybe ( ClientAttributes, ClientDict )
setClientPosition pos userHandle clientDict =
    case Dict.get userHandle clientDict of
        Nothing ->
            Nothing

        Just info ->
            let
                newInfo =
                    { info | x = pos.x - Config.dragOffsetX
                           , y =  pos.y - Config.dragOffsetY }
            in
            Just ( newInfo, Dict.insert userHandle newInfo clientDict )

-- DANGEROUS

 
clearAll =
    Lamdera.sendToBackend ClearAll

