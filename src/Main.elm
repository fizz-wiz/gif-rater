module Main exposing (..)

import Http
import Json.Decode as Decode
import RemoteData exposing (WebData)
import Html.Events exposing (onClick)
import Html exposing (Html, div, h1, text, img, button)
import Json.Decode.Pipeline exposing (decode, required)
import Html.Attributes exposing (src, disabled, class, style)


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
    | NewGifRequest (WebData Gif)
    | NewGif Topic
    | UpvoteRequest (WebData Vote)
    | Upvote
    | DownvoteRequest (WebData Vote)
    | Downvote



-- MODEL


type alias Topic =
    String


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
    , topics : List Topic
    , sessionUpvotes : List Vote
    , sessionDownvotes : List Vote
    , voteRequest : WebData Vote
    }


initialModel : Model
initialModel =
    { gif = RemoteData.NotAsked
    , topics = [ "dogs" ]
    , sessionUpvotes = []
    , sessionDownvotes = []
    , voteRequest = RemoteData.NotAsked
    }


init : ( Model, Cmd Msg )
init =
    ( { initialModel | gif = RemoteData.Loading }, fetchGif "dogs" )



-- UPDATE


gifDecoder : Decode.Decoder Gif
gifDecoder =
    decode Gif
        |> required "id" Decode.int
        |> required "url" Decode.string
        |> required "embedUrl" Decode.string


fetchGif : Topic -> Cmd Msg
fetchGif topic =
    Http.get ("/gifs?topic=" ++ topic) gifDecoder
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

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
            , fetchGif "dogs"
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
            , fetchGif "dogs"
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


view : Model -> Html Msg
view model =
    div [ class "body" ]
        [ div [ class "card" ]
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
