port module Main exposing (main)

import Browser
import Http
import Json.Decode as D
import Json.Encode as E
import Native exposing (Native, activityIndicator, button, image, label)
import Native.Attributes as NA
import Native.Event as Ev
import Native.Layout as Layout
import RemoteData
import Weather


openWeatherAPIKEY : String
openWeatherAPIKEY =
    "YOUR_OPEN_WEATHER_API_KEY"


{-| Uses @nativescript/geolocation to get device location
-}
port getCurrentLocation : () -> Cmd msg


port gotCurrentLocation : (E.Value -> msg) -> Sub msg


type alias Model =
    { weatherData : RemoteData.WebData Weather.Weather
    , location : Maybe Weather.Location
    }


init : ( Model, Cmd Msg )
init =
    ( { weatherData = RemoteData.NotAsked
      , location = Nothing
      }
    , Cmd.none
    )


type Msg
    = GetLocation
    | GotLocation (Result D.Error Weather.Location)
    | GotWeather (Result Http.Error Weather.Weather)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetLocation ->
            ( model, getCurrentLocation () )

        GotLocation location ->
            let
                maybeGetWeather =
                    location
                        |> Result.map (Weather.getWeatherFor openWeatherAPIKEY GotWeather)
                        |> Result.toMaybe
            in
            ( { model
                | weatherData =
                    maybeGetWeather
                        |> Maybe.map (always RemoteData.Loading)
                        |> Maybe.withDefault RemoteData.NotAsked
              }
            , maybeGetWeather
                |> Maybe.withDefault Cmd.none
            )

        GotWeather result ->
            ( { model
                | weatherData =
                    case result of
                        Err err ->
                            RemoteData.Failure err

                        Ok weather ->
                            RemoteData.Success weather
              }
            , Cmd.none
            )


view : Model -> Native Msg
view model =
    Layout.flexboxLayout
        [ NA.flexDirection "column"
        , NA.justifyContent "center"
        , NA.alignItems "center"
        , NA.height "100%"
        ]
    <|
        case model.weatherData of
            RemoteData.NotAsked ->
                [ button
                    [ Ev.onTap GetLocation
                    , NA.text "Fetch Weather"
                    , NA.fontSize "24"
                    , NA.backgroundColor "#d3d3d3"
                    , NA.borderRadius "5"
                    , NA.width "100%"
                    ]
                    []
                ]

            RemoteData.Loading ->
                [ activityIndicator
                    [ NA.busy "true"
                    , NA.color "blue"
                    ]
                    []
                ]

            RemoteData.Failure _ ->
                [ label [ NA.text "Something went wrong", NA.textAlignment "center", NA.color "red" ] []
                ]

            RemoteData.Success weather ->
                [ image [ NA.height "100", NA.src ("https://openweathermap.org/img/w/" ++ weather.icon ++ ".png") ] []
                , label [ NA.fontSize "30", NA.text weather.name ] []
                , label [ NA.text (String.fromFloat weather.temperature ++ "℃") ] []
                ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    gotCurrentLocation (D.decodeValue Weather.decoderLocation >> GotLocation)


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
