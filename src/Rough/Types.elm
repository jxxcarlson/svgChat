module Rough.Types exposing(..)


{-

Ideas on types

-}


{-| We will need this because we will be hosting
many different events

-}
type Event = Event {
    id : Int
 ,  name : String
  , url : String
}

type User =
  User {
      username : String
    , name : String
    , passwordHash : String
    , position : Position
    , clientId : Maybe ClientId
    , signInTime : Posix
    , signOutTime : Posix
    , status : Status
    , eventId : Int -- Like a relational database, ha ha!
    -- the below could be quite different depending on what we render
    , fontColor : Color
    , color : Color
  }

type Status
    = SignedIn
    | SignedOut

type aias Position = { x: Int, y: Int }


{- Below are the front and backend model types used in svgChat

  A key piece of data is the clientDict:

  type alias Username = String

  type alias ClientDict = Dict Username User

-}






ype alias FrontendModel =
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


type alias BackendModel =
    { messages : List Message
    , clients : Set ClientId
    , clientDict : ClientDict
    , currentTime : Posix
    , seed : Random.Seed
    }
