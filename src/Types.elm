module Types exposing (..)

import Lamdera exposing (ClientId)
import Set exposing (Set)
import Dict exposing(Dict)
import Random exposing(Seed)
import Html.Events.Extra.Mouse as Mouse

type alias FrontendModel =
    { messages : List ChatMsg
    , messageFieldContent : String
    , clientDict : ClientDict
    , clientId : Maybe ClientId
    , isDragging : Bool
    , dragState : DragState }

type alias Position = {x : Float, y: Float}

type DragState
  = Static Position
  | Moving Position


type alias BackendModel =
    { messages : List Message
    , clients : Set ClientId
    , clientDict : ClientDict
    , seed : Random.Seed
     }

type alias ClientDict = Dict ClientId ClientAttributes

-- type alias SvgMessage = ClientAttributes

type alias ClientAttributes =
    { x : Float
    , y : Float
    , radius : Float
    , color : Color
    , fontColor : Color
    , handle : String
    , clientStatus : ClientStatus
    }

type ClientStatus = SignedIn | SignedOut

type alias Color = {red: Float, green : Float, blue: Float}


type FrontendMsg
    = MessageFieldChanged String
    | MessageSubmitted
    | DragStart
    | DragMove Position
    | DragStop Position
    | Noop


type ToBackend
    = ClientJoin
    | MsgSubmitted String
    | UpdateClientDict ClientId ClientAttributes


type BackendMsg
    = BNoop


type ToFrontend
    = ClientJoinReceived ClientId
    | ClientTimeoutReceived ClientId
    | RoomMsgReceived Message
    | FreshClientDict ClientDict
    | RegisterClientId ClientId ClientDict
    | UpdateFrontEndClientDict ClientDict


type alias Message =
    ( String, String )


type ChatMsg
    = ClientJoined ClientId
    | ClientTimedOut ClientId
    | MsgReceived ClientId String
