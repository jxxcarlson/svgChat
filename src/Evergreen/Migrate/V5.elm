module Evergreen.Migrate.V5 exposing (..)

import Dict
import Evergreen.V1.Types as Old
import Evergreen.V5.Types as New exposing (DragState(..), Position)
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
        Old.MessageFieldChanged str ->
            MsgUnchanged

        Old.MessageSubmitted ->
            MsgUnchanged

        Old.DragStart ->
            MsgUnchanged

        Old.DragMove _ ->
            MsgUnchanged

        Old.DragStop _ ->
            MsgUnchanged

        Old.Noop ->
            MsgUnchanged


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    case old of
        Old.ClientJoin ->
            MsgOldValueIgnored

        Old.MsgSubmitted _ ->
            MsgOldValueIgnored

        Old.UpdateClientDict _ _ ->
            MsgOldValueIgnored


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
