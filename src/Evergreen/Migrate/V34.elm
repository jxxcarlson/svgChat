module Evergreen.Migrate.V34 exposing (..)

import Evergreen.V29.Types as Old
import Evergreen.V34.Types as New
import Lamdera.Migrations exposing (..)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelUnchanged


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
        case old of
          Old.MessageFieldChanged _ -> MsgOldValueIgnored
          Old.MessageSubmitted -> MsgOldValueIgnored
          Old.DragStart -> MsgOldValueIgnored
          Old.DragMove _ -> MsgOldValueIgnored
          Old.DragStop _ -> MsgOldValueIgnored
          Old.GotUserHandle _ -> MsgOldValueIgnored
          Old.GotPassword _ -> MsgOldValueIgnored
          Old.GotRepeatedPassword _ -> MsgOldValueIgnored
          Old.SignUp -> MsgOldValueIgnored
          Old.JoinChat -> MsgOldValueIgnored
          Old.LeaveChat -> MsgOldValueIgnored
          Old.ClearChatRoom -> MsgOldValueIgnored
          Old.EnterSignUpMode -> MsgOldValueIgnored
          Old.EnterSignInMode -> MsgOldValueIgnored
          Old.EnterChatMode -> MsgOldValueIgnored
          Old.Noop -> MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
