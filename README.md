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

For setup please see the example in `src/Main.js`. You need to extend your messages with

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

and *add some JS code*.

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
