# SimpleJS

My goal was to create the simplest possible and community accepted way to call Javascript from Elm. It uses a webworker to avoid a hanging GUI caused by long running JS (but would also work without webworker after a few changes)

After proper initialisation no code changes regarding the interface are necessary. Just add the JS function to the webworker (file `src/myjsfunctions.js` in the example), and call `SimpleJs.callJs` from your `update` function using the following parameters:

```elm
callJs :
    (Json.Decode.Value -> msg)
    -> List String
    -> List Json.Encode.Value
    -> { a | simplejs : Model msg }
    -> ( { a | simplejs : Model msg }, Cmd msg )
```

* A (An anonymous) function, taking the returned value of the JS function and creating a message
* The name of your JS function as list of strings. In case your JS function has a dot-separated name, like `a.b.c`, use `["a","b","c"]`
* A list containing a `Json.Encode.Value` for each of the expected function parameters
* And your global model.

For setup please see the examples in `src/`. You need to extend your messages with

```elm
    | SimpleJsReceived Json.Encode.Value
    | SimpleJsError String
```

add to your model record 

```elm
    simplejs : SimpleJs.Model Msg
```

Then init the model with 

```elm
    (SimpleJs.init SimpleJsError)
```

and add to the subscriptiones

```elm
    SimpleJs.receiveJsValue SimpleJsReceived 
```

and add some additional JS code to your index.html like

```html
    <script>
    var app = Elm.Main.init({
        node: document.getElementById('elm'),
        flags: {lang: navigator.language || navigator.userLanguage }
    });

    let sjsworker = new Worker("worker.js")

    app.ports.callJsValue.subscribe(function(v) {
        // console.log ("sending ", v , " to worker")
        sjsworker.postMessage(v)
    })

    sjsworker.onmessage = function (e) {
        // console.log ("receives ", e , " from worker")
        app.ports.receiveJsValue.send(e.data)
    }

    </script>

```

Here is a complete example (`src/Example1.elm`) calling
```javascript
console.log("One", 2, 3.4)
```

in Elm:

```elm
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
```

Calling 
```javascript
math.sqrt()
```

in Elm's `update` just needs

```elm
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
```elm

Limits:
* Exact one callback is supported, no multiple callbacks, like subscriptions from JS, or calls without callback (cause a memory leak)
* Only functions can be called, no longer living JS objects can be called.
* As async/await is supported, it may not work on older browsers.

TODO:
* Better error-handling
* Function for simpler initialisation, like `Browser.element`
* Flag for allowing multiple callbacks
* Allow to create and store JS objects (not simple...)
* Optimize build, e.g minimize webworker
