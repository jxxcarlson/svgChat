module Backend exposing (Model, app)

import Lamdera exposing (ClientId, SessionId)
import Set exposing (Set, map)
import Task
import Types exposing (..)
import Dict
import Random
import Client
import Time
import Cmd.Extra exposing(withCmd, withCmds, withNoCmd)
import Config




app =
    Lamdera.backend
        { init = init
        , update = update
        , subscriptions = subscriptions
        , updateFromFrontend = updateFromFrontend
        }


type alias Model =
    BackendModel


init : ( Model, Cmd BackendMsg )
init =
    ( { messages = []
    , clients = Set.empty
    , clientDict = Dict.empty
    , seed = Random.initialSeed 123499115
    , currentTime = Time.millisToPosix 0 }
    , Cmd.none )


subscriptions model =
  Time.every Config.tickInterval Tick

update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        BNoop ->
            ( model, Cmd.none )

        Tick currentTime ->
          { model | currentTime = currentTime } |> withNoCmd




updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        -- A new client has joined! Add them to our clients list, and send them all messages we have so far.
        ClientJoin userHandle passwordHash ->
          case userIsValid userHandle passwordHash model.clientDict of
            False -> (model, Lamdera.sendToFrontend clientId AuthenticationFailure)
            True ->
              case Dict.get userHandle model.clientDict of
                Nothing -> (model, Lamdera.sendToFrontend clientId AuthenticationFailure)
                Just clientAttributes ->
                  let

                      newClientAttributes =
                        {clientAttributes | clientStatus = SignedIn, clientId = Just clientId, signInTime = model.currentTime }

                      newClientDict = Dict.insert userHandle newClientAttributes model.clientDict

                      newModel =
                        { model | clients = Set.insert clientId model.clients, clientDict =  newClientDict }

                  in
                    ( newModel
                    , Cmd.batch
                        [ sendHelloMessageToAllClients newModel.clients clientId
                        , sendMessageHistoryToNewlyJoinedClient model.messages clientId
                        , Lamdera.sendToFrontend clientId (RegisterClientId clientId userHandle newClientDict)
                        , broadcast newModel.clients (UpdateFrontEndClientDict newClientDict)
                        ]
                    )


        ClientLeave userHandle ->
          let
            newClientDict = setStatus SignedOut userHandle model.clientDict
          in
            ({model | clientDict = newClientDict
              , messages = {id = clientId, handle = userHandle, content = "left the chat" } :: model.messages},
                broadcast model.clients (UpdateFrontEndClientDict newClientDict)
              )

        DeleteUser userHandle ->
          let
            newClientDict = Dict.remove userHandle model.clientDict

          in
              ({model | clientDict = newClientDict, clients = Set.remove clientId model.clients }
                , Cmd.batch [
                    broadcast model.clients (UpdateFrontEndClientDict newClientDict)
                    ])


        ClearAll ->
              ({model | clientDict = Dict.empty, messages = [], clients = Set.empty}
                , Cmd.batch [
                    broadcast model.clients (UpdateFrontEndClientDict Dict.empty)
                    ])

        ClearStoredMessages ->
              ({model |  messages = []}, Cmd.none)

        -- A client has sent us a new message! Add it to our messages list, and broadcast it to everyone.
        MsgSubmitted handle text ->
            ( { model | messages = {id = clientId, handle = handle, content = text } :: model.messages }
            , broadcast model.clients (RoomMsgReceived {id = clientId, handle = handle, content = text })
            )

        UpdateClientDict clientId_ clientAttributes ->
          let
            newDict = Dict.insert clientId_ clientAttributes model.clientDict
          in
            ({ model | clientDict = newDict}, broadcast model.clients (UpdateFrontEndClientDict newDict))

        CheckClientRegistration handle passwordHash ->
          -- Register new user
          let
            available = userHandleAvailable handle model.clientDict
          in
          case available of
            False -> (model, Lamdera.sendToFrontend clientId (SystemMessage "name not available"))
            True ->
              let
                 --  signInTime = model.currentTime
                (newClientAttributes, newSeed)
                        = Client.newAttributes model.seed 500 500 SignedIn handle passwordHash (Just clientId) model.currentTime

                newDict = Dict.insert handle newClientAttributes model.clientDict
                newModel = { model | seed = newSeed, clientDict = newDict}
              in
                ( newModel
                  , Cmd.batch [
                          sendHelloMessageToAllClients newModel.clients clientId
                        , sendMessageHistoryToNewlyJoinedClient newModel.messages clientId
                        , Lamdera.sendToFrontend clientId (HandleAvailable clientId available)
                        , Lamdera.sendToFrontend clientId (RegisterClientId clientId handle newDict)
                      , broadcast newModel.clients (UpdateFrontEndClientDict newDict)
                     ] )


-- HELPERS


sendHelloMessageToAllClients clients clientId =
    broadcast clients (ClientJoinReceived clientId)


sendMessageHistoryToNewlyJoinedClient messages clientId =
  messages
      -- |> List.reverse -- Que? Is this a bug?
      |> List.map RoomMsgReceived
      |> List.map (Lamdera.sendToFrontend clientId)
      |> Cmd.batch

broadcast clients msg =
    clients
        |> Set.toList
        |> List.map (\clientId -> Lamdera.sendToFrontend clientId msg)
        |> Cmd.batch


setStatus : ClientStatus -> String -> ClientDict -> ClientDict
setStatus clientStatus userHandle clientDict =
  case Dict.get userHandle clientDict of
    Nothing -> clientDict
    Just attributes ->
      let
        newAttributes = { attributes | clientStatus = clientStatus }
      in
        Dict.insert userHandle newAttributes clientDict

userHandleAvailable : String -> ClientDict -> Bool
userHandleAvailable name clientDict  =
  let
    names = clientDict
      |> Dict.toList
      |> List.map (.handle << Tuple.second)
  in
  (List.filter (\item -> item == name)) names == []


userIsValid : String -> String -> ClientDict -> Bool
userIsValid userHandle passwordHash clientDict =
  let
    id = findClientIdByHandle userHandle clientDict
  in
  case Dict.get id clientDict of
    Nothing -> False
    Just attributes -> attributes.passwordHash == passwordHash

findClientIdByHandle : String -> ClientDict -> ClientId
findClientIdByHandle handle clientDict =
    List.filter (\(id, clientAttributes) -> clientAttributes.handle == handle) (clientDict |> Dict.toList)
    |> List.map Tuple.first
    |> List.head
    |> Maybe.withDefault "INVALID"
