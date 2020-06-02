module Main exposing (main)

import Browser
import Html exposing (..)
import Json.Encode
import SimpleJs



-- MAIN


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = NoOp
    | SimpleJsReceived Json.Encode.Value -- for SimpleJs
    | SimpleJsError String -- for SimpleJs


type alias Model =
    { simplejs : SimpleJs.Model Msg -- for SimpleJs
    }


init : {} -> ( Model, Cmd Msg )
init flags =
    SimpleJs.callJs
        (\val -> NoOp)
        -- JS-function
        [ "console", "log" ]
        --JS params
        [ Json.Encode.string "One"
        , Json.Encode.int 2
        , Json.Encode.float 3.4
        ]
        --model
        { simplejs = SimpleJs.init SimpleJsError }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SimpleJsReceived val ->
            -- for SimpleJs
            let
                ( ms, mo ) =
                    SimpleJs.receiveJs val model
            in
            update ms mo

        SimpleJsError s ->
            -- for SimpleJs
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    SimpleJs.receiveJsValue SimpleJsReceived



-- for SimpleJs


view : Model -> Html Msg
view model =
    div []
        [ text "Please look at the browser's console"
        ]
