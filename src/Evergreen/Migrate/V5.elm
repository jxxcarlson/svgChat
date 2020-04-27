module Evergreen.Migrate.V5 exposing (..)

import Evergreen.V1.Types as Old
import Evergreen.V5.Types as New
import Lamdera.Migrations exposing (..)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    {
      messages = []
    , messageFieldContent = ""
    , clientDict = Dict.empty
    , clientId = Nothing
    , isDragging = False
    , dragState = Static {x = 50, y = 50}
    , userHandle = "---"
    , message = ""
     }


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    old.ClientJoin -> MsgOldValueIgnored


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    old.GotUserHandle -> MsgOldValueIgnored
    old.JoinChat -> MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    Unimplemented


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
