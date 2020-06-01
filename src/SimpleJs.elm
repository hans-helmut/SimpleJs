port module SimpleJs exposing
    ( JsParam
    , Model
    , Msg(..)
    , callJs
    , callJsValue
    , init
    , receiveJs
    , receiveJsValue
    )

import Dict
import Json.Decode
import Json.Encode



-- Use a Dict to store call-back functions
-- A List is not workung, as Functions are not compareable
-- counter points to the next entry
-- Functions create new messages, because functions create models could not be stored inside the model due to recursion


type alias Model msg =
    { f : Dict.Dict Int (Json.Decode.Value -> msg) -- index: key given to JS, value: message send with Json.Encode.Value (as from JS) as parameter
    , c : Int
    , errorf : String -> msg
    }


type Msg
    = Received Json.Encode.Value


type alias JsParam =
    { key : Int
    , fun : List String
    , param : List Json.Encode.Value
    }


type alias JsResult =
    { key : Int -- index for model.f
    , value : Json.Encode.Value
    }


defaultJsResult : JsResult
defaultJsResult =
    { key = -1
    , value = Json.Encode.string ""
    }


init : (String -> msg) -> Model msg
init fun =
    { f = Dict.empty
    , c = 0
    , errorf = fun
    }


setf : Dict.Dict Int (Json.Decode.Value -> msg) -> Model msg -> Model msg
setf f m =
    { m | f = f }


getf : Model msg -> Dict.Dict Int (Json.Decode.Value -> msg)
getf m =
    m.f


setc : Int -> Model msg -> Model msg
setc c m =
    { m | c = c }


getc : Model msg -> Int
getc m =
    m.c


decodeJsResult : Json.Decode.Decoder JsResult
decodeJsResult =
    Json.Decode.map2
        JsResult
        (Json.Decode.field "k" Json.Decode.int)
        (Json.Decode.field "r" Json.Decode.value)



-- Function called after receiving
-- JS Function Name
-- JS Function Params
-- model (the big one from the main module)


callJs :
    (Json.Decode.Value -> msg)
    -> List String
    -> List Json.Encode.Value
    -> { a | simplejs : Model msg }
    -> ( { a | simplejs : Model msg }, Cmd msg )
callJs fun jsfunction params m =
    let
        f : Dict.Dict Int (Json.Decode.Value -> msg)
        f =
            Dict.insert m.simplejs.c fun m.simplejs.f

        v : Json.Encode.Value
        v =
            Json.Encode.object
                [ ( "k", Json.Encode.int m.simplejs.c )
                , ( "f", Json.Encode.list Json.Encode.string jsfunction )
                , ( "p", Json.Encode.list (\val -> val) params )
                ]

        -- sync: boolean
        -- pure: ??
    in
    ( { m | simplejs = setf f m.simplejs |> setc (getc m.simplejs + 1) }, callJsValue v )



-- model (the big one from the main module)


receiveJs : Json.Decode.Value -> { a | simplejs : Model msg } -> ( msg, { a | simplejs : Model msg } )
receiveJs val model =
    let
        r : JsResult
        r =
            Result.withDefault defaultJsResult (Json.Decode.decodeValue decodeJsResult val)

        ms =
            case Dict.get r.key model.simplejs.f of
                Just fun ->
                    fun r.value

                Nothing ->
                    model.simplejs.errorf ("Internal Error, no function stored for missing key " ++ String.fromInt r.key)
    in
    ( ms, { model | simplejs = setf (Dict.remove r.key model.simplejs.f) model.simplejs } )


port callJsValue : Json.Encode.Value -> Cmd msg


port receiveJsValue : (Json.Encode.Value -> msg) -> Sub msg
