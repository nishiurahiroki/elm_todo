module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

-- TODO change Browser.application

type alias Model =
  {
    loginUserId : String,
    loginUserPassword : String
  }

type Msg =
  InputLoginUserIdText   String |
  InputLoginPasswordText String

init : () -> ( Model, Cmd Msg )
init () =
  (
    {
      loginUserId = "",
      loginUserPassword = ""
    },
    Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    InputLoginUserIdText userId ->
      ({ model | loginUserId = userId}, Cmd.none)

    InputLoginPasswordText password ->
      ({ model | loginUserPassword = password }, Cmd.none)


view : Model -> Html Msg
view model =
  div []
    [
      div [] [
        text "ユーザーID : ",
        input [ type_ "text", value model.loginUserId, onInput InputLoginUserIdText ] []
      ],
      div [] [
        text "パスワード : ",
        input [ type_ "password", value model.loginUserPassword, onInput InputLoginPasswordText ] []
      ],
      div [] [
        button [] [ text "ログイン" ]
      ]
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