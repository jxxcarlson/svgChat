module Evergreen.V18.Types exposing (..)

import Dict
import Lamdera
import Random
import Set


type alias Message =
    { id : Lamdera.ClientId
    , handle : String
    , content : String
    }


type ChatMsg
    = ClientJoined Lamdera.ClientId
    | ClientTimedOut Lamdera.ClientId
    | MsgReceived Message
    | UserLeftChat String


type alias Color =
    { red : Float
    , green : Float
    , blue : Float
    }


type ClientStatus
    = SignedIn
    | SignedOut


type alias ClientAttributes =
    { x : Float
    , y : Float
    , radius : Float
    , color : Color
    , fontColor : Color
    , handle : String
    , clientStatus : ClientStatus
    , passwordHash : String
    , clientId : Maybe Lamdera.ClientId
    }


type alias ClientDict =
    Dict.Dict String ClientAttributes


type alias Position =
    { x : Float
    , y : Float
    }


type DragState
    = Static Position
    | Moving Position


type SignMode
    = SignUpMode
    | SignInMode


type AppMode
    = ChatMode
    | StartMode SignMode


type alias FrontendModel =
    { messages : List ChatMsg
    , messageFieldContent : String
    , clientDict : ClientDict
    , clientId : Maybe Lamdera.ClientId
    , isDragging : Bool
    , dragState : DragState
    , userHandle : String
    , password : String
    , repeatedPassword : String
    , appMode : AppMode
    , message : String
    }


type alias BackendModel =
    { messages : List Message
    , clients : Set.Set Lamdera.ClientId
    , clientDict : ClientDict
    , seed : Random.Seed
    }


type FrontendMsg
    = MessageFieldChanged String
    | MessageSubmitted
    | DragStart
    | DragMove Position
    | DragStop Position
    | GotUserHandle String
    | GotPassword String
    | GotRepeatedPassword String
    | SignUp
    | JoinChat
    | LeaveChat
    | ClearChatRoom
    | EnterSignUpMode
    | EnterSignInMode
    | EnterChatMode
    | Noop


type ToBackend
    = ClientJoin String String
    | ClientLeave String
    | InitClientDict
    | MsgSubmitted String String
    | UpdateClientDict Lamdera.ClientId ClientAttributes
    | CheckClientRegistration String String


type BackendMsg
    = BNoop


type ToFrontend
    = ClientJoinReceived Lamdera.ClientId
    | ClientTimeoutReceived Lamdera.ClientId
    | RoomMsgReceived Message
    | FreshClientDict ClientDict
    | RegisterClientId Lamdera.ClientId String ClientDict
    | UpdateFrontEndClientDict ClientDict
    | HandleAvailable Lamdera.ClientId Bool
    | AuthenticationFailure
    | SystemMessage String
