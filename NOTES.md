xxcarlson:house_with_garden:  9:53 AM
Is there a way to get the screen width and height in Lamdera? Usually I do this with flags and have to interrogate JS.





New

supermario  9:56 AM
Here’s how I do it for the dashboard:
In the Model
, window : { width : Int, height : Int }
In my init
, window = { width = 0, height = 0 }
...
    , Cmd.batch
        [ Task.perform (\vp -> WindowResized (round vp.viewport.width) (round vp.viewport.height)) Browser.Dom.getViewport
        ]
In my update
WindowResized width height ->
    ( { model | window = { width = width, height = height } }, Cmd.none )
10:00
If you need width/height for first render then yes, no way to do that flags approach.
10:01
That said a bunch of folks in #elm-ui and @dillonkearns  too seem to advocate using media queries with CSS instead, to get responsiveness. I haven’t tried that yet. (edited) 
