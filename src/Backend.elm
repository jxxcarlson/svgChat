module Backend exposing (Model, app)

import Client
import Cmd.Extra exposing (withCmd, withCmds, withNoCmd)
import Config
import Dict
import Lamdera exposing (ClientId, SessionId)
import Random
import Set exposing (Set, map)
import Task
import Time
import Types exposing (..)
import String exposing (fromFloat)

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
      , currentTime = Time.millisToPosix 0
      }
    , Cmd.none
    )


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
            case userIsValid userHandle passwordHash model.clientDict || True of
                False ->
                    ( model, Lamdera.sendToFrontend clientId (Failure "Password mismatch") )

                True ->
                    case Dict.get userHandle model.clientDict of
                        Nothing ->
                            ( model, Lamdera.sendToFrontend clientId  (Failure ("User name not found")) )

                        Just clientAttributes ->
                            let
                                newClientAttributes =
                                    { clientAttributes | clientStatus = SignedIn, clientId = Just clientId, signInTime = model.currentTime }

                                newClientDict =
                                    Dict.insert userHandle newClientAttributes model.clientDict

                                newModel =
                                    { model | clients = Set.insert clientId model.clients, clientDict = newClientDict }
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
                newClientDict =
                    setStatus SignedOut userHandle model.clientDict
            in
            ( { model
                | clientDict = newClientDict
                , clients = Set.remove clientId model.clients
                , messages = { id = clientId, handle = userHandle, content = "left the chat" } :: model.messages
              }
            , broadcast model.clients (UpdateFrontEndClientDict newClientDict)
            )

        DeleteUser userHandle ->
            let
                newClientDict =
                    Dict.remove userHandle model.clientDict
            in
            ( { model | clientDict = newClientDict, clients = Set.remove clientId model.clients }
            , Cmd.batch
                [ broadcast model.clients (UpdateFrontEndClientDict newClientDict)
                ]
            )

        ClearAll ->
            clearAll model

        -- fixUp model
        ClearStoredMessages ->
            ( { model | messages = [] }, Cmd.none )

        -- A client has sent us a new message! Add it to our messages list, and broadcast it to everyone.
        MsgSubmitted handle text ->
            ( { model | messages = { id = clientId, handle = handle, content = text } :: model.messages }
            , broadcast model.clients (RoomMsgReceived { id = clientId, handle = handle, content = text })
            )

        UpdateClientDict userHandle clientAttributes ->
            let
                newDict =
                    Dict.insert userHandle clientAttributes model.clientDict
            in
            ( { model | clientDict = (newDict |> antiCollision) },
                  broadcast model.clients (UpdateFrontEndClientDict newDict) )

        CheckClientRegistration handle passwordHash ->
            -- Register new user
            let
                available =
                    userHandleAvailable handle model.clientDict
            in
            case available of
                False ->
                    ( model, Lamdera.sendToFrontend clientId (SystemMessage "name not available") )

                True ->
                    let
                        --  signInTime = model.currentTime
                        ( newClientAttributes, newSeed ) =
                            -- TODO: is this working?
                            Client.newAttributes model.seed 500 500 SignedIn handle passwordHash (Just clientId) model.currentTime

                        newDict =
                            Dict.insert handle newClientAttributes model.clientDict

                        newModel =
                            { model | seed = newSeed, clientDict = newDict, clients = Set.insert clientId model.clients }
                    in
                    ( newModel
                    , Cmd.batch
                        [ sendHelloMessageToAllClients newModel.clients clientId
                        , sendMessageHistoryToNewlyJoinedClient newModel.messages clientId
                        , Lamdera.sendToFrontend clientId (HandleAvailable clientId available)
                        , Lamdera.sendToFrontend clientId (RegisterClientId clientId handle newDict)
                        , broadcast newModel.clients (UpdateFrontEndClientDict newDict)
                        ]
                    )



-- HELPERS

type alias UserPair = (UserHandle, ClientAttributes)

antiCollision : ClientDict -> ClientDict
antiCollision d = let collisions = findCollisions d
                  in updateDict d collisions

updateDict : ClientDict -> List (UserPair, UserPair) -> ClientDict
updateDict d = let f ((a, as_), (b, bs_)) acc =
                       let (newX, newY) = updateSingle as_ bs_
                           maybeUpdate d_ =
                               case d_ of
                                   Nothing -> Nothing 
                                   (Just acc_) -> Just { acc_ | x = newX, y = newY }
                       in Dict.update a maybeUpdate acc
               in List.foldr f d              

updateSingle : ClientAttributes -> ClientAttributes -> (Float, Float)
updateSingle a b =
    let dx = if a.x >= b.x then a.radius/2 else -(a.radius/2)
        dy = if a.y >= b.y then a.radius/2 else -(a.radius/2)
    in (a.x + dx * 1.2, a.y + dy * 1.2)
                       
findCollisions : ClientDict -> List (UserPair, UserPair)
findCollisions d = Dict.toList d
                   |> genPairs
                   |> List.concatMap (\(x, xs) -> findCollision x xs)
                
genPairs : List UserPair -> List (UserPair, List UserPair)
genPairs xs = xs |> List.map (\x -> (x, List.filter (\x_ -> x /= x_) xs))
                    
findCollision : UserPair -> List UserPair -> List (UserPair, UserPair)
findCollision x xs = let f x_ acc = if overlap x x_ then (x, x_)::acc else acc
                     in xs |> List.foldr f []

-- axis-aligned collision detection -- no axis borders overlap                         
overlap : UserPair -> UserPair -> Bool
overlap (ua, a) (ub, b) = ((a.x - a.radius < b.x + b.radius) &&
                           (a.x + a.radius > b.x - b.radius) &&
                           (a.y - a.radius < b.y + b.radius) &&
                           (a.y + a.radius > b.y - b.radius))
                                    
clearAll model =
    ( { model | clientDict = Dict.empty, messages = [], clients = Set.empty }
    , Cmd.batch
        [ broadcast model.clients (UpdateFrontEndClientDict Dict.empty)
        ]
    )


fixUp model =
    let
        newDict =
            Dict.remove "XXX" model.clientDict
    in
    { model | clientDict = newDict }
        |> withCmd (broadcast model.clients (UpdateFrontEndClientDict newDict))


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
        Nothing ->
            clientDict

        Just attributes ->
            let
                updater : Maybe ClientAttributes -> Maybe ClientAttributes
                updater maybeClientAttributes =
                    case maybeClientAttributes of
                        Nothing ->
                            Nothing

                        Just ca ->
                            Just { ca | clientStatus = clientStatus }
            in
            Dict.update userHandle updater clientDict



-- MANAGE USERS

userHandleAvailable : String -> ClientDict -> Bool
userHandleAvailable name clientDict =
    let
        names =
            clientDict
                |> Dict.toList
                |> List.map (.handle << Tuple.second)
    in
    List.filter (\item -> item == name) names == []


userIsValid : String -> String -> ClientDict -> Bool
userIsValid userHandle passwordHash clientDict = 
  case Dict.get userHandle clientDict of 
    Nothing -> False 
    Just attributes -> attributes.passwordHash == passwordHash


findClientIdByHandle : String -> ClientDict -> Maybe ClientId
findClientIdByHandle handle clientDict =
  Dict.get handle clientDict |> Maybe.andThen .clientId
  
