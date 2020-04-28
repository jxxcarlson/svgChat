module Client exposing(newAttributesWithName, colorBar, word, render, toCssString, decodePosition, defaultAttributes)

import Types exposing(..)
import Random
import Svg exposing (Svg)
import Svg.Attributes
import Html.Events.Extra.Mouse as Mouse
import List.Extra
import Svg.Events
import Browser.Events
import Json.Decode as  D
import Json.Encode as E
import Widget.Bar
import Element exposing(Element)


newAttributesWithName : Random.Seed -> Float -> Float -> ClientStatus -> String ->  String -> (ClientAttributes, Random.Seed)
newAttributesWithName seed maxX maxY clientStatus userHandle passwordHash =
  let
    (x, seed1) = Random.step (Random.float 0 maxX) seed
    (y, seed2) = Random.step (Random.float 0 maxY) seed1
    (k, seed3) = Random.step (Random.int 0 11) seed2
    (color, fontColor) = getColors k
  in
    ({ x  = x
    , y = y
    , radius = 20
    , color = color
    , fontColor = fontColor
    , handle = userHandle
    , passwordHash = passwordHash
    , clientStatus = clientStatus}
    , seed3)

defaultAttributes =
  { x  = 0
  , y = 0
  , radius = 20
  , color = {red =0, green = 0, blue = 0}
  , fontColor = {red =1, green = 1, blue = 1}
  , handle = "XXX"
  , passwordHash = "XXX"
  , clientStatus = SignedOut}

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


render : ClientAttributes -> Svg FrontendMsg
render ca =
  Svg.g [] [ renderCircle ca, renderHandle ca]



renderHandle : ClientAttributes -> Svg FrontendMsg
renderHandle ca =
  let
    offset = case String.length ca.handle == 2 of
        True -> 5
        False -> 0
  in
    Svg.text_
        [ Svg.Attributes.width (String.fromFloat (2 * ca.radius))
        , Svg.Attributes.height (String.fromFloat (2 * ca.radius))
        , Svg.Attributes.x (String.fromFloat (ca.x - 13 + offset))
        , Svg.Attributes.y (String.fromFloat (ca.y + 5 ))
        , Svg.Attributes.fontSize "12px"
        , Svg.Attributes.fill (toCssString ca.fontColor)
        ]
        [Svg.text ca.handle]

renderCircle : ClientAttributes -> Svg FrontendMsg
renderCircle ca =
    Svg.circle
        [ Svg.Attributes.width (String.fromFloat (2 * ca.radius))
        , Svg.Attributes.height (String.fromFloat (2 * ca.radius))
        , Svg.Attributes.cx (String.fromFloat ca.x)
        , Svg.Attributes.cy (String.fromFloat ca.y)
        , Svg.Attributes.r (String.fromFloat ca.radius)
        , Svg.Attributes.fill (toCssString ca.color)
        , Svg.Attributes.stroke "black"
        , Svg.Attributes.strokeWidth "1"
        , Svg.Events.onMouseDown DragStart

        ]
        []


decodePosition : D.Decoder Position
decodePosition =
  D.map2 Position
    (D.field "pageX" D.float)
    (D.field "pageY" D.float)

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
        ++ "%)"

colorBar : Float ->  Float -> Float -> Float -> Element FrontendMsg
colorBar width r g b =
  Widget.Bar.make 80
     |> Widget.Bar.withRGB r g b
     |> Widget.Bar.horizontal
     |> Widget.Bar.withSize width
     |> Widget.Bar.withThickness 20
     |> Widget.Bar.toElement

makeColor : Float -> Float -> Float -> Color
makeColor r g b =
  { red = r/255.0, green = g/255.0, blue = b/255.0}


green = makeColor 8 196 59
blue = makeColor 8 64 196
violet = makeColor 121 8 196
magenta = makeColor 196 8 171
magenta2 = makeColor 196 8 99
red = makeColor 196 8 8
orange = makeColor 196 80 8
ochre = makeColor 196 130 8
blueGreen = makeColor 2 209 150
cyan = makeColor 2 181 209
black = makeColor 30 30 30
white = makeColor 255 255 255

palette = [(green, black), (blue, white), (violet, white),
  (magenta, white), (magenta2, white), (red, white), (orange, black)
   , (ochre, black), (blueGreen, black), (cyan, black), (black, white)]

getColors : Int ->  (Color, Color)
getColors k =
  List.Extra.getAt (modBy (List.length palette) k) palette
    |> Maybe.withDefault (black, white)
