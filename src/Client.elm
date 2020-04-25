module Client exposing(newAttributes)

import Types exposing(..)
import Random
import Svg exposing (Svg)
import Svg.Attributes

newAttributes : Random.Seed -> Float -> Float -> (ClientAttributes, Random.Seed)
newAttributes seed maxX maxY =
  let
    (handle, seed1) = map String.toUpper (word 3 seed)
    (x, seed2) = Random.step (Random.float 0 maxX) seed1
    (y, seed3) = Random.step (Random.float 0 maxY) seed2
    (r, seed4) = Random.step (Random.float 0.3 1) seed3
    (g, seed5) = Random.step (Random.float 0.3 1) seed4
    (b, seed6) = Random.step (Random.float 0.3 1) seed5

  in
    ({ x  = x
    , y = y
    , radius = 20
    , color = { red = r, green = g, blue = b}
    , handle = handle}
    , seed6)


map : (a -> a) -> (a, b) -> (a, b)
map f (a_, b_) = (f a_, b_)

-- randomHandle : Seed -> (String, Seed)
-- randomHandle seed =


letter : Random.Generator Char
letter =
  Random.map (\n -> Char.fromCode (n + 97)) (Random.int 0 25)

letters : Int -> Random.Seed -> ( List Char, Random.Seed )
letters k seed = Random.step (Random.list k letter) seed

wordFromChars : List Char -> String
wordFromChars chars =
  chars |> List.map String.fromChar |> String.join ""

word : Int -> Random.Seed -> (String, Random.Seed)
word k seed =
  letters k seed
    |> \(a,b) -> (wordFromChars a, b )



type alias ClientAttributes =
    { x : Float
    , y : Float
    , radius : Float
    , color : Color
    , handle : String
    }


renderClient : ClientAttributes -> Svg msg
renderClient ca =
    Svg.circle
        [ Svg.Attributes.width (String.fromFloat (2 * ca.radius))
        , Svg.Attributes.height (String.fromFloat (2 * ca.radius))
        , Svg.Attributes.cx (String.fromFloat ca.x)
        , Svg.Attributes.cy (String.fromFloat ca.y)
        , Svg.Attributes.r (String.fromFloat ca.radius)
        , Svg.Attributes.fill (toCssString ca.color)
        -- , Mouse.onDown
        --     (\r ->
        --         let
        --             ( x, y ) =
        --                 r.clientPos
        --         in
        --         { cell = position, coordinates = { x = x, y = y } }
        --     )
        ]
        []



{-| Use a faster toCssString
Using `++` instead of `String.concat` which avh4/color uses makes this much faster.
-}
toCssString : Color -> String
toCssString color =
    let


        r =
            color.red

        g =
            color.green

        b =
            color.blue

        pct x =
            ((x * 10000) |> round |> toFloat) / 100

        roundTo x =
            ((x * 1000) |> round |> toFloat) / 1000
    in
    "rgb("
        ++ String.fromFloat (pct r)
        ++ "%,"
        ++ String.fromFloat (pct g)
        ++ "%,"
        ++ String.fromFloat (pct b)
        ++ ")"
