module Evergreen.Migrate.V29 exposing (..)

import Evergreen.V28.Types as Old
import Evergreen.V29.Types as New exposing(SignMode(..), AppMode(..), DragState(..), Position)
import Lamdera.Migrations exposing (..)
import Set
import Dict
import Time

frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelMigrated ( {
        messages = []
      , messageFieldContent = ""
      , clientDict = Dict.empty
      , clientId = Nothing
      , isDragging = False
      , dragState = Static {x = 50, y = 50}
      , password = ""
      , repeatedPassword = ""
      , userHandle = "---"
      , appMode = StartMode SignInMode
      , message = ""
       }, Cmd.none)


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelMigrated ( {
          messages = []
         , clients = Set.empty
         , clientDict = Dict.empty
         , seed = old.seed
        , currentTime = Time.millisToPosix 0
      }, Cmd.none)


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
    case old of
       Old.ClientJoin _ _ -> MsgOldValueIgnored
       Old.MsgSubmitted _ _ -> MsgOldValueIgnored
       Old.UpdateClientDict _ _ -> MsgOldValueIgnored
       Old.ClientLeave _ -> MsgOldValueIgnored
       Old.InitClientDict -> MsgOldValueIgnored
       Old.CheckClientRegistration _ _ -> MsgOldValueIgnored



backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    case old of
      Old.BNoop -> MsgOldValueIgnored


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    case old of
       Old.ClientJoinReceived _ -> MsgOldValueIgnored
       Old.ClientTimeoutReceived _ -> MsgOldValueIgnored
       Old.RoomMsgReceived _ -> MsgOldValueIgnored
       Old.FreshClientDict _ -> MsgOldValueIgnored
       Old.RegisterClientId _ _ _ -> MsgOldValueIgnored
       Old.UpdateFrontEndClientDict _  -> MsgOldValueIgnored
       Old.HandleAvailable _ _  -> MsgOldValueIgnored
       Old.AuthenticationFailure  -> MsgOldValueIgnored
       Old.SystemMessage _  -> MsgOldValueIgnored
