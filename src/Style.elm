module Style exposing
    ( backgroundColor
    , black
    , darkBlue
    , darkRed
    , floralWhite
    , gray
    , lightBlue
    , lightGray
    , mediumGray
    , ochre
    , paleGreen
    , warmMediumGray
    )

import Element


darkRed =
    Element.rgb255 150 0 0


darkBlue =
    Element.rgb255 0 0 180


lightBlue =
    Element.rgb255 192 211 250


backgroundColor =
    Element.rgb 0.9 0.97 0.8


black =
    Element.rgb255 0 0 0


ochre =
    Element.rgb255 235 174 52


gray =
    Element.rgb255 150 150 150


floralWhite =
    Element.rgb255 255 250 240


makeGray g =
    Element.rgb g g g


paleGreen =
    Element.rgb255 243 252 235


warmMediumGray =
    Element.rgb 0.7 0.7 0.7



-- Element.rgb 0.92 0.89 0.85
--
-- warmMediumGray = Element.rgb 0.87 0.84 0.8


mediumGray =
    makeGray 0.8


lightGray =
    makeGray 0.925
