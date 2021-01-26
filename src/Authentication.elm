module Authentication exposing (..)




validateSignUp : String -> String -> String -> List String
validateSignUp userHandle password repeatedPassword =
    []
        |> passWordsMatch password repeatedPassword
        |> handleInRange userHandle


handleInRange : String -> List String -> List String
handleInRange handle strings =
    if String.length handle < 2 then
        "Authentication name needs at least three characters" :: strings

    else
        strings


passWordsMatch : String -> String -> List String -> List String
passWordsMatch p1 p2 strings =
    if p1 == p2 then
        strings

    else
        "passwords don't match" :: strings
