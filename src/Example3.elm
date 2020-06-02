module Main exposing (main)

import Browser
import Html exposing (..)
import Json.Decode
import Json.Encode
import SimpleJs
import Task
import Time



-- MAIN


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = Tick Time.Posix
    | AdjustTimeZoneName Time.ZoneName
    | GotDateString String
    | SimpleJsReceived Json.Encode.Value -- for SimpleJs
    | SimpleJsError String -- for SimpleJs


type alias Model =
    { zonename : Time.ZoneName
    , lang : String
    , date : String
    , simplejs : SimpleJs.Model Msg -- for SimpleJs
    }


init : { lang : String } -> ( Model, Cmd Msg )
init flags =
    ( Model (Time.Name "") flags.lang "" (SimpleJs.init SimpleJsError)
    , Task.perform AdjustTimeZoneName Time.getZoneName
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            -- for SimpleJs
            SimpleJs.callJs
                (\val ->
                    GotDateString
                        (Result.withDefault
                            ""
                            (Json.Decode.decodeValue
                                Json.Decode.string
                                val
                            )
                        )
                )
                -- JS-function
                [ "datetimestring" ]
                --JS params
                [ Json.Encode.string model.lang
                , Json.Encode.object
                    [ ( "weekday", Json.Encode.string "long" )
                    , ( "year", Json.Encode.string "numeric" )
                    , ( "month", Json.Encode.string "long" )
                    , ( "day", Json.Encode.string "2-digit" )
                    , ( "hour", Json.Encode.string "2-digit" )
                    , ( "minute", Json.Encode.string "2-digit" )
                    , ( "second", Json.Encode.string "2-digit" )
                    , ( "timeZone"
                      , Json.Encode.string
                            (case model.zonename of
                                Time.Name s ->
                                    s

                                Time.Offset i ->
                                    "GMT" ++ String.fromInt (i // 60)
                            )
                      )
                    ]
                , Json.Encode.int (Time.posixToMillis newTime)
                ]
                --model
                model

        GotDateString d ->
            ( { model | date = d }
            , Cmd.none
            )

        AdjustTimeZoneName newZone ->
            ( { model | zonename = newZone }
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
    Sub.batch
        [ Time.every 1000 Tick
        , SimpleJs.receiveJsValue SimpleJsReceived -- for SimpleJs
        ]


view : Model -> Html Msg
view model =
    div []
        [ text
            ("Current date and time in your zone ("
                ++ (case model.zonename of
                        Time.Name s ->
                            s

                        Time.Offset i ->
                            "GMT" ++ String.fromInt (i // 60)
                   )
                ++ ") and language ("
                ++ model.lang
                ++ "): "
            )
        , text model.date
        ]
