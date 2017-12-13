module Main exposing (..)

import Http
import List.Extra
import Json.Decode as Decode
import RemoteData exposing (WebData)
import Html.Events exposing (onClick, onInput)
import Json.Decode.Pipeline exposing (decode, required)
import Html.Attributes exposing (src, disabled, class, style, value)
import Html exposing (Html, div, h1, text, img, button, label, select, option)


main : Program Never Model Msg
main =
    Html.program
        { subscriptions = (\_ -> Sub.none)
        , view = view
        , update = update
        , init = init
        }


type Msg
    = Noop
    | TopicsRequest (WebData (List Topic))
    | ChangeTopic String
    | NewGifRequest (WebData Gif)
    | NewGif Topic
    | UpvoteRequest (WebData Vote)
    | Upvote
    | DownvoteRequest (WebData Vote)
    | Downvote



-- MODEL


type alias Topic =
    { id : Int
    , name : String
    }


type alias Gif =
    { id : Int
    , url : String
    , embedUrl : String
    }


type alias Vote =
    { id : Int
    }


type alias Model =
    { gif : WebData Gif
    , topics : WebData (List Topic)
    , selectedTopicId : Int
    , sessionUpvotes : List Vote
    , sessionDownvotes : List Vote
    , voteRequest : WebData Vote
    }


initialModel : Model
initialModel =
    { gif = RemoteData.NotAsked
    , topics = RemoteData.NotAsked
    , selectedTopicId = 0
    , sessionUpvotes = []
    , sessionDownvotes = []
    , voteRequest = RemoteData.NotAsked
    }


init : ( Model, Cmd Msg )
init =
    ( { initialModel
        | topics = RemoteData.Loading
        , gif = RemoteData.Loading
      }
    , fetchTopics
    )



-- UPDATE


topicDecoder : Decode.Decoder Topic
topicDecoder =
    decode Topic
        |> required "id" Decode.int
        |> required "name" Decode.string


topicsDecoder : Decode.Decoder (List Topic)
topicsDecoder =
    Decode.list topicDecoder


fetchTopics : Cmd Msg
fetchTopics =
    Http.get "/topics" topicsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map TopicsRequest


gifDecoder : Decode.Decoder Gif
gifDecoder =
    decode Gif
        |> required "id" Decode.int
        |> required "url" Decode.string
        |> required "embedUrl" Decode.string


fetchGif : Topic -> Cmd Msg
fetchGif topic =
    Http.get ("/gifs?topic=" ++ (toString topic.id)) gifDecoder
        |> RemoteData.sendRequest
        |> Cmd.map NewGifRequest


voteDecoder : Decode.Decoder Vote
voteDecoder =
    decode Vote
        |> required "id" Decode.int


upvote : Int -> Cmd Msg
upvote id =
    Http.post ("/gifs/" ++ (toString id) ++ "/upvotes") Http.emptyBody voteDecoder
        |> RemoteData.sendRequest
        |> Cmd.map UpvoteRequest


downvote : Int -> Cmd Msg
downvote id =
    Http.post ("/gifs/" ++ (toString id) ++ "/downvotes") Http.emptyBody voteDecoder
        |> RemoteData.sendRequest
        |> Cmd.map DownvoteRequest


findTopicById : Int -> WebData (List Topic) -> Topic
findTopicById id topicsResponse =
    case topicsResponse of
        RemoteData.Success topics ->
            case List.Extra.find (\x -> x.id == id) topics of
                Nothing ->
                    Debug.crash "This topic does not exist"

                Just topic ->
                    topic

        _ ->
            Debug.crash "No topics"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        TopicsRequest (RemoteData.Success topics) ->
            case List.head topics of
                Nothing ->
                    Debug.crash "No topics"

                Just selectedTopic ->
                    ( { model
                        | topics = RemoteData.Success topics
                        , selectedTopicId = selectedTopic.id
                      }
                    , fetchGif selectedTopic
                    )

        TopicsRequest (RemoteData.Failure error) ->
            -- TODO
            Debug.crash "Get topics - error"

        TopicsRequest _ ->
            ( model, Cmd.none )

        ChangeTopic topicId ->
            ( { model | selectedTopicId = Result.withDefault 0 (String.toInt topicId), gif = RemoteData.Loading }
            , fetchGif (findTopicById (Result.withDefault 0 (String.toInt topicId)) model.topics)
            )

        NewGifRequest (RemoteData.Failure error) ->
            -- TODO
            Debug.crash "Get new image - error"

        NewGifRequest response ->
            ( { model | gif = response }, Cmd.none )

        NewGif topic ->
            ( model, fetchGif topic )

        UpvoteRequest (RemoteData.Success vote) ->
            ( { model
                | sessionUpvotes = model.sessionUpvotes ++ [ vote ]
                , voteRequest = RemoteData.Success vote
                , gif = RemoteData.Loading
              }
            , fetchGif (findTopicById model.selectedTopicId model.topics)
            )

        UpvoteRequest response ->
            ( { model | voteRequest = response }, Cmd.none )

        Upvote ->
            case model.gif of
                RemoteData.Success gif ->
                    ( { model | voteRequest = RemoteData.Loading }, upvote gif.id )

                _ ->
                    ( model, Cmd.none )

        DownvoteRequest (RemoteData.Success vote) ->
            ( { model
                | sessionDownvotes = model.sessionDownvotes ++ [ vote ]
                , voteRequest = RemoteData.Success vote
                , gif = RemoteData.Loading
              }
            , fetchGif (findTopicById model.selectedTopicId model.topics)
            )

        DownvoteRequest response ->
            ( { model | voteRequest = response }, Cmd.none )

        Downvote ->
            case model.gif of
                RemoteData.Success gif ->
                    ( { model | voteRequest = RemoteData.Loading }, downvote gif.id )

                _ ->
                    ( model, Cmd.none )



-- VIEW


renderGif : WebData Gif -> Html Msg
renderGif gif =
    case gif of
        RemoteData.NotAsked ->
            div [ class "gif" ] [ text "" ]

        RemoteData.Loading ->
            div [ class "gif" ] [ text "" ]

        RemoteData.Failure error ->
            Debug.crash "RemoteData.Failure error in model"

        RemoteData.Success gif ->
            div [ class "gif", style [ ( "background-image", ("url(" ++ gif.embedUrl ++ ")") ) ] ] []


isLoading : Model -> Bool
isLoading model =
    RemoteData.isLoading model.gif || RemoteData.isLoading model.voteRequest


viewOption : Topic -> Html Msg
viewOption topic =
    option [ value (toString topic.id) ]
        [ text topic.name
        ]


viewTopicSelection : WebData (List Topic) -> Html Msg
viewTopicSelection topicsResponse =
    case topicsResponse of
        RemoteData.Success topics ->
            label []
                [ text "Topic: "
                , select [ onInput ChangeTopic ] <| List.map viewOption topics
                ]

        _ ->
            text ""


view : Model -> Html Msg
view model =
    div [ class "body" ]
        [ div [ class "topic-selection" ]
            [ viewTopicSelection model.topics
            ]
        , div [ class "card" ]
            [ renderGif model.gif
            , div [ class "vote-buttons" ]
                [ button
                    [ class "vote-button downvote-button"
                    , onClick Downvote
                    , disabled (isLoading model)
                    ]
                    [ text "👎" ]
                , button
                    [ class "vote-button upvote-button"
                    , onClick Upvote
                    , disabled (isLoading model)
                    ]
                    [ text "👍" ]
                ]
            ]
        ]
