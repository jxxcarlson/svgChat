module Backend exposing (Model, app)

import Lamdera exposing (ClientId, SessionId)
import Set exposing (Set, map)
import Task
import Types exposing (..)
import Dict
import Random
import Client



app =
    Lamdera.backend
        { init = init
        , update = update
        , subscriptions = \m -> Sub.none
        , updateFromFrontend = updateFromFrontend
        }


type alias Model =
    BackendModel


init : ( Model, Cmd BackendMsg )
init =
    ( { messages = []
    , clients = Set.empty
    , clientDict = Dict.empty
    , seed = Random.initialSeed 123499115}
    , Cmd.none )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        BNoop ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        -- A new client has joined! Add them to our clients list, and send them all messages we have so far.
        ClientJoin userHandle passwordHash ->
          case userIsValid userHandle passwordHash model.clientDict of
            False -> (model, Lamdera.sendToFrontend clientId AuthenticationFailure)
            True ->
              case findClientDataByHandle userHandle model.clientDict of
                Nothing -> (model, Lamdera.sendToFrontend clientId AuthenticationFailure)
                Just (clientId_, clientAttributes) ->
                  let

                      newClientAttributes =
                        {clientAttributes | clientStatus = SignedIn }

                      dict1 = Dict.remove clientId_ model.clientDict
                      dict2 = Dict.insert clientId newClientAttributes dict1

                      newModel =
                        { model | clients = Set.insert clientId model.clients
                                  , clientDict =  dict2

                         }

                      sendHelloMessageToAllClients =
                        broadcast newModel.clients (ClientJoinReceived clientId)

                      sendMessageHistoryToNewlyJoinedClient =
                        model.messages
                            -- |> List.reverse -- Que? Is this a bug?
                            |> List.map RoomMsgReceived
                            |> List.map (Lamdera.sendToFrontend clientId)
                            |> Cmd.batch
                  in
                    ( newModel
                    , Cmd.batch
                        [ sendHelloMessageToAllClients
                        , sendMessageHistoryToNewlyJoinedClient
                        , Lamdera.sendToFrontend clientId (RegisterClientId clientId dict2)
                        , broadcast newModel.clients (UpdateFrontEndClientDict dict2)
                        ]
                    )


        ClientLeave userHandle ->
          let
            newClientDict = setStatus SignedOut clientId model.clientDict
          in
            ({model | clientDict = newClientDict
              , messages = {id = clientId, handle = userHandle, content = "left the chat" } :: model.messages},
                broadcast model.clients (UpdateFrontEndClientDict newClientDict)
              )



        InitClientDict ->
            let
              newClientDict = Dict.empty
            in
              ({model | clientDict = newClientDict}, broadcast model.clients (UpdateFrontEndClientDict newClientDict))

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
          case userHandleAvailable handle model.clientDict of
            False -> (model, Lamdera.sendToFrontend clientId (SystemMessage "name not available"))
            True ->
              let
                available = Debug.log "AVAIL" (userHandleAvailable handle model.clientDict)
                (newDict , newSeed_) = case available of
                  False -> (model.clientDict, model.seed)
                  True ->
                    let
                      (newClientAttributes, newSeed) = Client.newAttributesWithName model.seed 500 500 SignedIn handle passwordHash
                    in
                    (Dict.insert clientId newClientAttributes model.clientDict, newSeed)
                _ = Debug.log "NEW DICT" newDict
              in
                ({ model | seed = newSeed_, clientDict = newDict}
                  , Cmd.batch [
                        Lamdera.sendToFrontend clientId (HandleAvailable clientId available)
                        , Lamdera.sendToFrontend clientId (RegisterClientId clientId newDict)
                      , broadcast model.clients (UpdateFrontEndClientDict newDict)
                     ] )
---
broadcast clients msg =
    clients
        |> Set.toList
        |> List.map (\clientId -> Lamdera.sendToFrontend clientId msg)
        |> Cmd.batch


setStatus : ClientStatus -> ClientId -> ClientDict -> ClientDict
setStatus clientStatus clientId clientDict =
  case Dict.get clientId clientDict of
    Nothing -> clientDict
    Just attributes ->
      let
        newAttributes = { attributes | clientStatus = clientStatus }
      in
        Dict.insert clientId newAttributes clientDict

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

    _ = Debug.log "DICT" clientDict

    _ = Debug.log "PHASH" passwordHash
  in
  case Dict.get id clientDict of
    Nothing -> False
    Just attributes -> Debug.log "PHASH (D)" attributes.passwordHash == passwordHash

purgeUser : String -> ClientDict -> ClientDict
purgeUser userHandle clientDict =
  purgeClientDictionary (findClientIdByHandle userHandle clientDict) clientDict

findClientIdByHandle : String -> ClientDict -> ClientId
findClientIdByHandle handle clientDict =
    List.filter (\(id, clientAttributes) -> clientAttributes.handle == handle) (clientDict |> Dict.toList)
    |> List.map Tuple.first
    |> List.head
    |> Maybe.withDefault "INVALID"

findClientDataByHandle : String -> ClientDict -> Maybe (ClientId, ClientAttributes)
findClientDataByHandle handle clientDict =
    List.filter (\(id, clientAttributes) -> clientAttributes.handle == handle) (clientDict |> Dict.toList)
    |> List.head

purgeClientDictionary : ClientId -> ClientDict -> ClientDict
purgeClientDictionary clientId clientDict =
  Dict.remove clientId  clientDict
