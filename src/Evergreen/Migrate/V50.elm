module Evergreen.Migrate.V50 exposing (..)

import Evergreen.V48.Types as Old
import Evergreen.V50.Types as New exposing (AppMode(..), DragState(..), Position, SignMode(..), PanelType(..))
import Lamdera.Migrations exposing (..)
import Set
import Dict
import Time exposing (Posix, Zone)

frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelMigrated
        ( { messages = []
          , messageFieldContent = ""
          , clientDict = Dict.empty
          , clientId = Nothing
          , isDragging = False
          , dragState = Static { x = 50, y = 50 }
          , password = ""
          , repeatedPassword = ""
          , userHandle = "---"
          , appMode = StartMode SignInMode
          , message = ""
          , zone = Time.utc
          , panelSelected = RosterPanel
          }
        , Cmd.none
        )


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelUnchanged


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    case old of
        Old.MessageFieldChanged _ ->
            MsgOldValueIgnored

        Old.MessageSubmitted ->
            MsgOldValueIgnored

        Old.DragStart _ ->
            MsgOldValueIgnored

        Old.DragMove _ ->
            MsgOldValueIgnored

        Old.DragStop _ ->
            MsgOldValueIgnored

        Old.GotUserHandle _ ->
            MsgOldValueIgnored

        Old.GotPassword _ ->
            MsgOldValueIgnored

        Old.GotRepeatedPassword _ ->
            MsgOldValueIgnored

        Old.SignUp ->
            MsgOldValueIgnored

        Old.JoinChat ->
            MsgOldValueIgnored

        Old.LeaveChat ->
            MsgOldValueIgnored

        Old.EnterSignUpMode ->
            MsgOldValueIgnored

        Old.EnterSignInMode ->
            MsgOldValueIgnored

        Old.EnterChatMode ->
            MsgOldValueIgnored

        Old.Noop ->
            MsgOldValueIgnored

        Old.DeleteMe ->
            MsgOldValueIgnored

        Old.RequestClearAllUsers ->
            MsgOldValueIgnored

        Old.ClearMessages ->
            MsgOldValueIgnored

        Old.AdjustTimeZone _ -> MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
