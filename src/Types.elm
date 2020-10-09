module Types exposing (..)

import Dict exposing (Dict)
import Html.Events.Extra.Mouse as Mouse
import Lamdera exposing (ClientId)
import Random exposing (Seed)
import Set exposing (Set)
import Time exposing (Posix)


type alias FrontendModel =
    { messages : List ChatMsg
    , messageFieldContent : String
    , clientDict : ClientDict
    , clientId : Maybe ClientId
    , isDragging : Bool
    , dragState : DragState
    , userHandle : String
    , password : String
    , repeatedPassword : String
    , appMode : AppMode
    , message : String
    , panelSelected : PanelType
    , zone : Time.Zone
    }


type AppMode
    = ConferenceMode
    | StartMode SignMode


type SignMode
    = SignUpMode
    | SignInMode


type alias Position =
    { x : Float, y : Float }


type DragState
    = Static Position
    | Moving Position


type alias BackendModel =
    { messages : List Message
    , clients : Set ClientId
    , clientDict : ClientDict
    , currentTime : Posix
    , seed : Random.Seed
    }


type alias UserHandle =
    String


type alias ClientDict =
    Dict UserHandle ClientAttributes



-- key is the user handle
-- type alias SvgMessage = ClientAttributes


type alias ClientAttributes =
    { x : Float
    , y : Float
    , radius : Float
    , color : Color
    , fontColor : Color
    , handle : String
    , clientStatus : ClientStatus
    , passwordHash : String
    , signInTime : Posix
    , clientId : Maybe ClientId
    }


type ClientStatus
    = SignedIn
    | SignedOut


type alias Color =
    { red : Float, green : Float, blue : Float }


type FrontendMsg
    = MessageFieldChanged String
    | MessageSubmitted
    | DragStart Position
    | DragMove Position
    | DragStop Position
    | GotUserHandle String
    | GotPassword String
    | GotRepeatedPassword String
    | SignUp
    | JoinChat
    | LeaveChat
    | DeleteMe
    | RequestClearAllUsers
    | EnterSignUpMode
    | EnterSignInMode
    | EnterChatMode
    | SelectPanel PanelType
    | ClearMessages
    | AdjustTimeZone Time.Zone

    | Noop

type PanelType = RosterPanel | ChatPanel

type ToBackend
    = ClientJoin String String
    | ClientLeave String
    | DeleteUser String
    | MsgSubmitted String String
    | UpdateClientDict ClientId ClientAttributes
    | CheckClientRegistration String String
    | ClearAll
    | ClearStoredMessages


type BackendMsg
    = BNoop
    | Tick Posix


type ToFrontend
    = ClientJoinReceived ClientId
    | ClientTimeoutReceived ClientId
    | RoomMsgReceived Message
    | FreshClientDict ClientDict
    | RegisterClientId ClientId String ClientDict
    | UpdateFrontEndClientDict ClientDict
    | HandleAvailable ClientId Bool
    | Failure String
    | SystemMessage String


type alias Message =
    { id : ClientId, handle : String, content : String }


type ChatMsg
    = ClientJoined ClientId
    | ClientTimedOut ClientId
    | MsgReceived Message
    | UserLeftChat String
