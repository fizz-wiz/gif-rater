module Main exposing (..)

import Http
import Json.Decode as Decode
import RemoteData exposing (WebData)
import Html.Events exposing (onClick)
import Html.Attributes exposing (src, disabled)
import Html exposing (Html, div, h1, text, img, button)
import Json.Decode.Pipeline exposing (decode, required)


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
            ( { model | sessionUpvotes = model.sessionUpvotes ++ [ vote ] }, fetchGif "dogs" )

        UpvoteRequest response ->
            ( { model | voteRequest = response }, Cmd.none )

        Upvote ->
            case model.gif of
                RemoteData.Success gif ->
                    ( model, upvote gif.id )

                _ ->
                    ( model, Cmd.none )

        DownvoteRequest (RemoteData.Success vote) ->
            ( { model | sessionDownvotes = model.sessionDownvotes ++ [ vote ] }, fetchGif "dogs" )

        DownvoteRequest response ->
            ( { model | voteRequest = response }, Cmd.none )

        Downvote ->
            case model.gif of
                RemoteData.Success gif ->
                    ( model, downvote gif.id )

                _ ->
                    ( model, Cmd.none )



-- VIEW


renderGif : WebData Gif -> Html Msg
renderGif gif =
    case gif of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Failure error ->
            Debug.crash "RemoteData.Failure error in model"

        RemoteData.Success gif ->
            img [ src gif.embedUrl ] []


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "gif-rater changed" ]
        , renderGif model.gif
        , button [ onClick Downvote, disabled (RemoteData.isLoading model.voteRequest) ] [ text "downvote" ]
        , button [ onClick Upvote, disabled (RemoteData.isLoading model.voteRequest) ] [ text "upvote" ]
        ]
