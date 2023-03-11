module Weather exposing (..)

import Http
import Json.Decode as D
import Url.Builder exposing (crossOrigin, string)


type alias Location =
    { latitude : Float, longitude : Float }


type alias Weather =
    { name : String
    , temperature : Float
    , icon : String
    }


decoderLocation : D.Decoder Location
decoderLocation =
    D.map2 Location
        (D.field "latitude" D.float)
        (D.field "longitude" D.float)


decodeWeather : D.Decoder Weather
decodeWeather =
    D.map3 Weather
        (D.field "name" D.string)
        (D.at [ "main", "temp" ] D.float)
        (D.field "weather"
            (D.index 0 (D.field "icon" D.string))
        )


getWeatherFor : String -> (Result Http.Error Weather -> msg) -> Location -> Cmd msg
getWeatherFor apiKey toMsg { latitude, longitude } =
    let
        url =
            crossOrigin
                "https://api.openweathermap.org"
                [ "data", "2.5", "weather" ]
                [ string "lat" (String.fromFloat latitude)
                , string "lon" (String.fromFloat longitude)
                , string "appid" apiKey
                , string "units" "metric"
                ]
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg decodeWeather
        }
