module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
  {
    count : Int
  }

type Msg =
  Increment |
  Decrement

init : () -> ( Model, Cmd Msg )
init () =
  (
    {
      count = 0
    },
    Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Increment ->
      ({ model | count = model.count + 1 }, Cmd.none)

    Decrement ->
      ({ model | count = model.count - 1 }, Cmd.none)


view : Model -> Html Msg
view model =
  div []
    [
      button [ onClick Increment ] [ text "+" ],
      text (String.fromInt model.count),
      button [ onClick Decrement ] [ text "-" ]
    ]

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none


main : Program () Model Msg
main =
  Browser.document
    {
      init = init,
      update = update,
      view =
        \m ->
          {
            title = "elm todo application",
            body = [ view m ]
          },
      subscriptions = subscriptions
    }