module Evergreen.Migrate.V28 exposing (..)

import Evergreen.V18.Types as Old
import Evergreen.V28.Types as New exposing(SignMode(..), AppMode(..), DragState(..), Position)
import Lamdera.Migrations exposing (..)
import Set
import Dict

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
              }, Cmd.none)


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgUnchanged


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
    MsgUnchanged


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
