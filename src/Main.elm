module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Url.Parser exposing (Parser, (</>), int, map, oneOf, s, string, top)

-- TODO change Browser.application

type alias Model =
  {
    key : Nav.Key,
    url : Url.Url,
    loginUserId : String,
    loginUserPassword : String
  }

type Route =
  LoginPage |
  TopPage |
  NotFoundPage

routeParser : Parser (Route -> a) a
routeParser =
  oneOf
    [ Url.Parser.map LoginPage   top
    , Url.Parser.map TopPage     (Url.Parser.s "top")
    ]

toRoute : String -> Route
toRoute string =
  case Url.fromString string of
    Nothing ->
      LoginPage

    Just url ->
      Maybe.withDefault NotFoundPage (Url.Parser.parse routeParser url)


type Msg =
  InputLoginUserIdText   String |
  InputLoginPasswordText String |
  Login |
  UrlChanged  Url.Url |
  LinkClicked Browser.UrlRequest

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  (
    {
      loginUserId = "",
      loginUserPassword = "",
      url = url,
      key = key
    },
    Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          (model,
           Cmd.batch <| [Nav.pushUrl model.key (Url.toString url)]
          )
        Browser.External url ->
          (model,
           Nav.load url
          )

    UrlChanged url ->
      (model,
       Cmd.none
      )

    InputLoginUserIdText userId ->
      ({ model | loginUserId = userId}, Cmd.none)

    InputLoginPasswordText password ->
      ({ model | loginUserPassword = password }, Cmd.none)

    Login -> -- TODO success or failure.
      ( model,
        Nav.load "/top"
      )

view : Model -> Html Msg
view model =
  case toRoute <| Url.toString model.url of
    LoginPage ->
      viewLogin model

    TopPage ->
      viewTop model

    NotFoundPage ->
      viewNotFound model

viewLogin : Model -> Html Msg
viewLogin model =
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
        button [ onClick Login ] [ text "ログイン" ]
      ]
    ]

viewTop : Model -> Html Msg
viewTop model =
  div [] [
    p [] [
      li [] [
        a [ href "/top" ] [ text "トップ画面" ]
      ],
      li [] [
        a [ href "/list" ] [ text "一覧画面" ]
      ],
      li [] [
        a [ href "/add" ] [ text "追加画面" ]
      ],
      li [] [
        a [ href "/logout" ] [ text "ログアウト" ]
      ]
    ]
  ]

viewNotFound : Model -> Html Msg
viewNotFound model =
  div [] [ text "Not found page." ]

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none


main : Program () Model Msg
main =
  Browser.application
    {
      init = init,
      update = update,
      view =
        \m ->
          {
            title = "elm todo application",
            body = [ view m ]
          },
      subscriptions = subscriptions,
      onUrlChange = UrlChanged,
      onUrlRequest = LinkClicked
    }