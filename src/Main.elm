module Main exposing (..)

import Http
import Html exposing (Html, div, h1, text)


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
    | NewGifRequest (Result Http.Error Gif)
    | NewGif Topic




-- MODEL

type alias Topic =
    String

type alias Gif =
    { url : String
    , embedUrl : String
    }

type alias Model =
    { maybeGif : Maybe Gif
    , topics : List Topic
    }


initialModel : Model
initialModel =
    { maybeGif = Nothing
    , topics = ["dogs"]
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        NewGifRequest (Err error) ->
            Debug.crash "Get new image - error"

        NewGifRequest (Ok image) ->
            Debug.crash "Get new image"


        NewGif topic ->
            Debug.crash "Get new iamge"


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "gif-rater changed" ]
        ]
