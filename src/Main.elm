module Main exposing (..)

import Http
import List.Extra
import Json.Decode as Decode
import RemoteData exposing (WebData)
import Navigation exposing (Location)
import UrlParser exposing (Parser, (</>))
import Html.Events exposing (onClick, onInput)
import Json.Decode.Pipeline exposing (decode, required)
import Html.Attributes exposing (src, disabled, class, style, value, href)
import Html exposing (Html, a, div, h1, ul, li, span, text, img, button, label, select, option)


main : Program Never Model Msg
main =
    Navigation.program LocationChange
        { subscriptions = (\_ -> Sub.none)
        , view = view
        , update = update
        , init = init
        }


type Msg
    = Noop
    | LocationChange Location
    | TopicsRequest (WebData (List Topic))
    | ChangeTopic String
    | NewGifRequest (WebData Gif)
    | NewGif Topic
    | UpvoteRequest (WebData Vote)
    | Upvote
    | DownvoteRequest (WebData Vote)
    | Downvote
    | TopRatedGifsRequest (WebData (List TopRatedGif))



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


type alias TopRatedGif =
    { id : Int
    , url : String
    , embedUrl : String
    , topic : String
    , net_votes : Int
    }


type alias Vote =
    { id : Int
    }


type alias Model =
    { route : Route
    , gif : WebData Gif
    , topics : WebData (List Topic)
    , selectedTopicId : Int
    , sessionUpvotes : List Vote
    , sessionDownvotes : List Vote
    , voteRequest : WebData Vote
    , topRated : WebData (List TopRatedGif)
    }


initialModel : Model
initialModel =
    { route = VoteRoute
    , gif = RemoteData.NotAsked
    , topics = RemoteData.NotAsked
    , selectedTopicId = 0
    , sessionUpvotes = []
    , sessionDownvotes = []
    , voteRequest = RemoteData.NotAsked
    , topRated = RemoteData.NotAsked
    }


init : Location -> ( Model, Cmd Msg )
init location =
    ( { initialModel
        | route = parseLocation location
        , topics = RemoteData.Loading
        , gif = RemoteData.Loading
      }
    , fetchTopics
    )



-- Routing


votePath : String
votePath =
    "#"


topRatedPath : String
topRatedPath =
    "#top-rated"


type Route
    = VoteRoute
    | TopRatedRoute
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    UrlParser.oneOf
        [ UrlParser.map VoteRoute UrlParser.top
        , UrlParser.map TopRatedRoute (UrlParser.s "top-rated")
        ]


parseLocation : Location -> Route
parseLocation location =
    case (UrlParser.parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute



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


topRatedGifDecoder : Decode.Decoder TopRatedGif
topRatedGifDecoder =
    decode TopRatedGif
        |> required "id" Decode.int
        |> required "url" Decode.string
        |> required "embedUrl" Decode.string
        |> required "topic" Decode.string
        |> required "netVotes" Decode.int


topRatedGifsDecoder : Decode.Decoder (List TopRatedGif)
topRatedGifsDecoder =
    Decode.list topRatedGifDecoder


fetchTopRatedGifs : Cmd Msg
fetchTopRatedGifs =
    Http.get "/gifs/top" topRatedGifsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map TopRatedGifsRequest


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


routeCmd : Route -> Topic -> Cmd Msg
routeCmd route topic =
    case route of
        VoteRoute ->
            fetchGif topic

        TopRatedRoute ->
            fetchTopRatedGifs

        NotFoundRoute ->
            Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        LocationChange location ->
            let
                newRoute =
                    parseLocation location
            in
                ( { model | route = newRoute }
                , routeCmd newRoute (findTopicById model.selectedTopicId model.topics)
                )

        TopicsRequest (RemoteData.Success topics) ->
            case List.head topics of
                Nothing ->
                    Debug.crash "No topics"

                Just selectedTopic ->
                    ( { model
                        | topics = RemoteData.Success topics
                        , selectedTopicId = selectedTopic.id
                      }
                    , routeCmd model.route selectedTopic
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

        TopRatedGifsRequest (RemoteData.Failure error) ->
            -- TODO
            Debug.crash ("Get top rated images - error: " ++ (toString error))

        TopRatedGifsRequest response ->
            ( { model | topRated = response }, Cmd.none )



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


viewVotingPage : Model -> Html Msg
viewVotingPage model =
    div []
        [ div [ class "rate-gifs" ]
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
        ]


viewTopRatedPage : Model -> Html Msg
viewTopRatedPage model =
    case model.topRated of
        RemoteData.NotAsked ->
            div [] [ text "" ]

        RemoteData.Loading ->
            div [] [ text "Loading..." ]

        RemoteData.Failure error ->
            Debug.crash "RemoteData.Failure error in model"

        RemoteData.Success gifs ->
            if List.length gifs == 0 then
                text "No top rated images yet, please rate some!"
            else
                div [ class "image-grid" ]
                    (List.map
                        (\gif ->
                            div [ class "image-grid__item" ]
                                [ div [ class "gif image-grid__gif", style [ ( "background-image", ("url(" ++ gif.embedUrl ++ ")") ) ] ] []
                                , span [ class "image-grid__label" ] [ text ("Net votes: " ++ (toString gif.net_votes)) ]
                                ]
                        )
                        gifs
                    )


viewPageContent : Model -> Html Msg
viewPageContent model =
    case model.route of
        VoteRoute ->
            viewVotingPage model

        TopRatedRoute ->
            viewTopRatedPage model

        NotFoundRoute ->
            h1 [] [ text "404, Not found!" ]


viewHeader : Html Msg
viewHeader =
    div [ class "header" ]
        [ h1 [ class "title" ] [ text "gif-rater" ]
        , a [ class "m-l-auto", href votePath ] [ text "Rate Some Gifs" ]
        , a [ href topRatedPath ] [ text "Top Rated" ]
        ]


view : Model -> Html Msg
view model =
    div [ class "body" ]
        [ viewHeader
        , viewPageContent model
        ]
