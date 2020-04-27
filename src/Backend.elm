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
        ClientJoin userHandle ->
            let
                (newClientAttributes, newSeed) = Client.newAttributesWithName model.seed  500 500 SignedIn userHandle

                newClientDict = Dict.insert clientId newClientAttributes model.clientDict

                newModel =
                    { model | clients = Set.insert clientId model.clients
                              , clientDict =  newClientDict
                              , seed = newSeed
                     }

                sendHelloMessageToAllClients =
                    broadcast newModel.clients (ClientJoinReceived clientId)

                sendMessageHistoryToNewlyJoinedClient =
                    model.messages
                        -- |> List.reverse -- Que? Is this a bug?
                        |> List.map RoomMsgReceived
                        |> List.map (Lamdera.sendToFrontend clientId)
                        -- |> (\list -> (Lamdera.sendToFrontend clientId (FreshClientDict newClientDict))::list)
                        |> (\list -> (Lamdera.sendToFrontend clientId (RegisterClientId clientId newClientDict))::list)
                        |> Cmd.batch
            in
            ( newModel
            , Cmd.batch
                [ sendHelloMessageToAllClients
                , sendMessageHistoryToNewlyJoinedClient
                , broadcast model.clients (UpdateFrontEndClientDict newClientDict)
                ]
            )


        ClientLeave userHandle ->
          let
            newClientDict = Dict.remove clientId model.clientDict
          in
            ({model | clientDict = newClientDict}, broadcast model.clients (UpdateFrontEndClientDict newClientDict))


        InitClientDict ->
            let
              newClientDict = Dict.empty
            in
              ({model | clientDict = newClientDict}, broadcast model.clients (UpdateFrontEndClientDict newClientDict))
              
        -- A client has sent us a new message! Add it to our messages list, and broadcast it to everyone.
        MsgSubmitted text ->
            ( { model | messages = ( clientId, text ) :: model.messages }
            , broadcast model.clients (RoomMsgReceived ( clientId, text ))
            )

        UpdateClientDict clientId_ clientAttributes ->
          let
            newDict = Dict.insert clientId_ clientAttributes model.clientDict
          in
            ({ model | clientDict = newDict}, broadcast model.clients (UpdateFrontEndClientDict newDict))


broadcast clients msg =
    clients
        |> Set.toList
        |> List.map (\clientId -> Lamdera.sendToFrontend clientId msg)
        |> Cmd.batch
