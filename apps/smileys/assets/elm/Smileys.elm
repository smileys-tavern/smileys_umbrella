module SmileysSearch exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Keyboard exposing (..)
import Char exposing (..)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Platform.Cmd

import Json.Encode as JE
import Json.Decode as JD exposing (..)
import Json.Decode.Extra exposing ((|:))
import Dict

type alias Flags =
  { websocketUrl : String,
    userToken : String
  }

-- TODO: change file name from Smileys.elm to Search.elm or something after starting module #2
main =
  Html.programWithFlags { init = init, view = view, update = update, subscriptions = subscriptions }


-- Model
type alias SearchResults = 
    {results: List PostSummary,
     amt: Int
    }

type alias PostSummary =
    {title : String, 
     hash : String,
     votepublic : Int,
     name : String, 
     body : String,
     thumb : String, 
     parenttype : String,
     link : String, 
     imageurl : String, 
     tags : String,
     roomname : String,
     posturl: String
    }

type alias Model = 
    {search : String,
     results : SearchResults,
     amount_results : Int,
     user_input : Char,
     status : String,
     current_channel : String,
     page : Int,
     user_token : String,
     phxSocket : Phoenix.Socket.Socket Msg
    }

pageSize : Int
pageSize = 25

initPhxSocket : String -> Phoenix.Socket.Socket Msg
initPhxSocket websocketUrl =
    Phoenix.Socket.init websocketUrl
        -- |> Phoenix.Socket.withDebug    

initSearchResults : SearchResults
initSearchResults =
    (SearchResults [] 0)

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    { websocketUrl, userToken } =
      flags
  in
    let
        (phxSocket, searchResults, user_token) =
            ( initPhxSocket websocketUrl, initSearchResults, userToken)
    in
        (Model "" searchResults 0 ' ' "" "" 0 user_token phxSocket, Cmd.none)

-- Update
searchDecoder : JD.Decoder SearchResults
searchDecoder =
    succeed
        SearchResults
        |: (field "results" (JD.list postSummaryDecoder))
        |: (field "amt" int)

postSummaryDecoder : JD.Decoder PostSummary
postSummaryDecoder =
    succeed
        PostSummary
        |: (field "title" string)
        |: (field "hash" string)
        |: (field "votepublic" int)
        |: (field "name" (oneOf [ string, null "" ]))
        |: (field "body" (oneOf [ string, null "" ]))
        |: (field "thumb" (oneOf [ string, null "" ]))
        |: (field "parenttype" (oneOf [ string, null "" ]))
        |: (field "link" (oneOf [ string, null "" ]))
        |: (field "imageurl" (oneOf [ string, null "" ]))
        |: (field "tags" (oneOf [ string, null "" ]))
        |: (field "roomname" string)
        |: (field "posturl" string)

term : JE.Value
term =
    JE.object [ ( "term", JE.string "searchfor" ), ( "offset", JE.int 0 ), ( "user_token", JE.string "" ) ]

type Msg
    = UpdateSearchTerm String
    | Presses Char
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | RequestSearch
    | ReceiveSearchResults JE.Value
    | JoinChannel
    | LeaveChannel
    | PageUp
    | PageDown
    | ShowJoinedMessage String
    | ShowLeftMessage String
    | CloseSearch
    | NoOp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model 
                  | phxSocket = phxSocket 
                  |> Phoenix.Socket.on "search_result" ("user:" ++ model.user_token) ReceiveSearchResults
                  }
                , Cmd.map PhoenixMsg phxCmd
                )

        Presses code ->
             if (code == '\r' && (String.length(model.search) > 0)) then
                let
                    channel =
                        Phoenix.Channel.init ("user:" ++ model.user_token)
                            |> Phoenix.Channel.onJoin (always (RequestSearch))
                            |> Phoenix.Channel.onClose (always (ShowLeftMessage ("user:" ++ model.user_token)))

                    ( phxSocket, phxCmd ) =
                        Phoenix.Socket.join channel model.phxSocket
                in
                    ( { model 
                      | phxSocket = phxSocket
                      , current_channel = ("user:" ++ model.user_token)
                      , page = 0
                      }
                    , Cmd.map PhoenixMsg phxCmd
                    )
            else if (code == '→') then
                let
                    newModel = if model.page > (model.results.amt // pageSize) then
                        model
                    else
                        { model | page = (model.page + 1) }
                in
                    requestSearch newModel
            else if (code == '←') then
                let
                    newModel = if model.page <= 0 then
                        model
                    else
                        { model | page = (model.page - 1) }
                in
                    requestSearch newModel
            else
                (model, Cmd.none)

        UpdateSearchTerm search ->
            if (model.current_channel /= "") then
                let
                    ( phxSocket, phxCmd ) =
                        Phoenix.Socket.leave model.current_channel model.phxSocket
                in
                    ({ model | search = search 
                     , phxSocket = phxSocket
                     } 
                    , Cmd.map PhoenixMsg phxCmd)
            else
                ({model | search = search}, Cmd.none)

        JoinChannel ->
            let
                channel =
                    Phoenix.Channel.init ("user:" ++ model.user_token)
                        |> Phoenix.Channel.onJoin (always (RequestSearch))
                        |> Phoenix.Channel.onClose (always (ShowLeftMessage ("user:" ++ model.user_token)))

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
                ( { model 
                  | phxSocket = phxSocket
                  , current_channel = ("user:" ++ model.user_token)
                  , page = 0
                  }
                , Cmd.map PhoenixMsg phxCmd
                )

        LeaveChannel ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.leave model.current_channel model.phxSocket
            in
                ( { model | phxSocket = phxSocket
                  , current_channel = "" }
                , Cmd.map PhoenixMsg phxCmd
                )

        RequestSearch ->
            requestSearch model

        ReceiveSearchResults raw ->
            case JD.decodeValue searchDecoder raw of
                Ok searchResults ->
                    ({ model 
                       | results = searchResults
                    }
                    , Cmd.none
                    )

                Err error ->
                    (model, Cmd.none)

        PageUp ->
            let
                newModel = if model.page > ((model.results.amt // pageSize) - 1) then
                    model
                else
                    { model | page = (model.page + 1) }
            in
                requestSearch newModel

        PageDown ->
            let
                newModel = if model.page <= 0 then
                    model
                else
                    { model | page = (model.page - 1) }
            in
                requestSearch newModel

        ShowJoinedMessage channelName ->
            (model
            , Cmd.none
            )

        ShowLeftMessage channelName ->
            (model
            , Cmd.none
            )

        CloseSearch ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.leave model.current_channel model.phxSocket
            in
                let
                    searchResults =
                        initSearchResults
                in
                    ( { model 
                      | results = searchResults 
                      , phxSocket = phxSocket
                      , current_channel = ""
                      }
                    , Cmd.none
                    )

        NoOp ->
            (model, Cmd.none)

-- Update Helpers
requestSearch : Model -> (Model, Cmd Msg)
requestSearch model =
    let
        payload =
            (JE.object [ ( "term", JE.string model.search ), ( "offset", JE.int (model.page * pageSize) ), ( "user_token", JE.string model.user_token ) ])
        push_ =
            Phoenix.Push.init "search_for" model.current_channel
                |> Phoenix.Push.withPayload payload

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.push push_ model.phxSocket
    in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

-- View
view : Model -> Html Msg
view model =
    div [ class "search-container" ]
      [ input [ type_ "text", placeholder "Search", autofocus True, onInput UpdateSearchTerm ] []
      , button [ class "search-activate", onClick JoinChannel ] [ text "[Enter]" ]
      , (renderSearchSummary model.results.results model.results.amt model.page model.status)
      , (renderSearchResults model.results.results)
      ]

renderSearchResult : PostSummary -> Html Msg
renderSearchResult result =
    let
      children =
        [ div [ class "search-result-title" ] [ Html.text ((String.slice 0 60 result.title) ++ " - " ++ result.body ++ ".. by "), span [ class "search-result-username" ] [ Html.text result.name ] ] 
        , div [ class "search-result-room"] [ Html.text ("/r/" ++ String.slice 0 80 result.roomname) ]
        , div [ class "search-result-votes" ] [ Html.text ("Votes " ++ toString (result.votepublic)) ] 
        ]
    in
      a [ class "search-result", href result.posturl ] children

renderSearchSummary : List PostSummary -> Int -> Int -> String -> Html Msg
renderSearchSummary results amount_results page status =
    if List.length results > 0 then
        div [ class "search-results-summary" ] [
          span [] [ text status ]
          , span [ class "search-summary-left" ] [
            button [ onClick PageDown ] [ text "<" ]
          ]
          , Html.text (" " ++ (toString (page + 1)) ++ " ")
          , span [ class "search-summary-right" ] [
            button [ onClick PageUp ] [ text ">" ]
          ]
          , span [ class "search-summary-count" ] [
            Html.text ("Results: " ++ (toString amount_results))
          ]
          , span [ class "search-summary-close" ] [
            button [ onClick CloseSearch ] [ text "[X]" ]
          ]
        ]
    else
        div [ class "hidden search-results-summary" ] []

renderSearchResults : List PostSummary -> Html Msg
renderSearchResults results =
    if List.length results > 0 then
        div [ class "search-results" ]
          (List.map renderSearchResult results)
    else
        div [ class "hidden search-results" ]
          (List.map renderSearchResult results)

-- Subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch 
      [ Phoenix.Socket.listen model.phxSocket PhoenixMsg
      , Keyboard.presses (\code -> Presses (fromCode code))
      ]