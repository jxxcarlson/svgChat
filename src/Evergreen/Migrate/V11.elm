module Evergreen.Migrate.V11 exposing (..)

import Dict
import Evergreen.V11.Types as New exposing (DragState(..), Position)
import Evergreen.V7.Types as Old
import Lamdera.Migrations exposing (..)
import Set


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelMigrated
        ( { messages = []
          , messageFieldContent = ""
          , clientDict = Dict.empty
          , clientId = Nothing
          , isDragging = False
          , dragState = Static { x = 50, y = 50 }
          , userHandle = "---"
          , message = ""
          }
        , Cmd.none
        )



-- { messages : List ChatMsg
-- , messageFieldContent : String
-- , clientDict : ClientDict
-- , clientId : Maybe ClientId
-- , isDragging : Bool
-- , dragState : DragState
-- , userHandle : String
-- , message : String }


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelMigrated
        ( { messages = []
          , clients = Set.empty
          , clientDict = Dict.empty
          , seed = old.seed
          }
        , Cmd.none
        )


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    case old of
        Old.MessageFieldChanged _ ->
            MsgOldValueIgnored

        Old.MessageSubmitted ->
            MsgOldValueIgnored

        Old.DragStart ->
            MsgOldValueIgnored

        Old.DragMove _ ->
            MsgOldValueIgnored

        Old.DragStop _ ->
            MsgOldValueIgnored

        Old.GotUserHandle _ ->
            MsgOldValueIgnored

        Old.JoinChat ->
            MsgOldValueIgnored

        Old.LeaveChat ->
            MsgOldValueIgnored

        Old.ClearChatRoom ->
            MsgOldValueIgnored

        Old.Noop ->
            MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    case old of
        Old.ClientJoin _ ->
            MsgOldValueIgnored

        Old.MsgSubmitted _ ->
            MsgOldValueIgnored

        Old.UpdateClientDict _ _ ->
            MsgOldValueIgnored

        Old.ClientLeave _ ->
            MsgOldValueIgnored

        Old.InitClientDict ->
            MsgOldValueIgnored


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
