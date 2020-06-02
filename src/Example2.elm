module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Events
import Json.Decode
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
    = GotNumber Float
    | GotRoot Float
    | SimpleJsReceived Json.Encode.Value -- for SimpleJs
    | SimpleJsError String -- for SimpleJs


type alias Model =
    { r : Float
    , simplejs : SimpleJs.Model Msg -- for SimpleJs
    }


init : {} -> ( Model, Cmd Msg )
init flags =
    ( Model 0 (SimpleJs.init SimpleJsError)
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotNumber n ->
            -- for SimpleJs
            SimpleJs.callJs
                (\val ->
                    GotRoot
                        (Result.withDefault
                            0
                            (Json.Decode.decodeValue
                                Json.Decode.float
                                val
                            )
                        )
                )
                -- JS-function
                [ "Math", "sqrt" ]
                --JS params
                [ Json.Encode.float n
                ]
                --model
                model

        GotRoot r ->
            ( { model | r = r }
            , Cmd.none
            )

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
        [ text "Enter a number: "
        , input [ Html.Events.onInput (\v -> GotNumber (Maybe.withDefault 0.0 (String.toFloat v))) ] []
        , br [] []
        , text ("Root from JS: " ++ String.fromFloat model.r)
        ]
