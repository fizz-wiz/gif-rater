module Main exposing (..)

import Http
import Json.Decode as Decode
import RemoteData exposing (WebData)
import Html.Attributes exposing (src)
import Html exposing (Html, div, h1, text, img)
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



-- MODEL


type alias Topic =
    String


type alias Gif =
    { url : String
    , embedUrl : String
    }


type alias Model =
    { gif : WebData Gif
    , topics : List Topic
    }


initialModel : Model
initialModel =
    { gif = RemoteData.NotAsked
    , topics = [ "dogs" ]
    }


init : ( Model, Cmd Msg )
init =
    ( { initialModel | gif = RemoteData.Loading }, fetchGif "dogs" )



-- UPDATE


gifDecoder : Decode.Decoder Gif
gifDecoder =
    decode Gif
        |> required "url" Decode.string
        |> required "embedUrl" Decode.string


fetchGif : Topic -> Cmd Msg
fetchGif topic =
    Http.get ("/gifs?topic=" ++ topic) gifDecoder
        |> RemoteData.sendRequest
        |> Cmd.map NewGifRequest


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
        ]
