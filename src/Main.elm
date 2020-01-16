port module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Url.Parser exposing (Parser, (</>), int, map, oneOf, s, string, top)


type alias Model =
  {
    key : Nav.Key,
    url : Url.Url,
    loginUserId : String,
    loginUserPassword : String,
    isLoginFail : Bool,
    addTodoInfo : AddTodoInfo
  }

type alias LoginInfo =
  {
    userId : String,
    password : String,
    isLoggedIn : Bool
  }

type alias AddTodoInfo =
  {
    title : String,
    description : String
  }

port submitLoginInfo : LoginInfo -> Cmd msg
port addTodo : AddTodoInfo -> Cmd msg

port getLoginResult : (LoginInfo -> msg) -> Sub msg
port getAddTodoResult : (Bool -> msg) -> Sub msg

type Route =
  LoginPage |
  TopPage |
  AddPage |
  NotFoundPage

routeParser : Parser (Route -> a) a
routeParser =
  oneOf
    [ Url.Parser.map LoginPage   top
    , Url.Parser.map TopPage     (Url.Parser.s "top")
    , Url.Parser.map AddPage     (Url.Parser.s "add")
    ]

toRoute : String -> Route
toRoute string =
  case Url.fromString string of
    Nothing ->
      LoginPage

    Just url ->
      Maybe.withDefault NotFoundPage (Url.Parser.parse routeParser url)


type Msg =
  InputLoginUserIdText   String  |
  InputLoginPasswordText String  |
  InputAddTodoTitle String       |
  InputAddTodoDescription String |
  SubmitLoginInfo String String  |
  Login LoginInfo |
  UrlChanged  Url.Url |
  LinkClicked Browser.UrlRequest |
  AddTodo String String |
  AddFinishedTodo Bool

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  (
    {
      loginUserId = "",
      loginUserPassword = "",
      url = url,
      key = key,
      isLoginFail = False,
      addTodoInfo = {
        title = "",
        description = ""
      }
    },
    Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    { addTodoInfo } = model
  in
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
        ({model | url = url},
         Cmd.none
        )

      InputLoginUserIdText userId ->
        ({ model | loginUserId = userId}, Cmd.none)

      InputLoginPasswordText password ->
        ({ model | loginUserPassword = password }, Cmd.none)

      InputAddTodoTitle title ->
        ({
          model |
            addTodoInfo = {
              addTodoInfo |
              title = title
            }
        }, Cmd.none)

      InputAddTodoDescription description ->
        ({
          model |
            addTodoInfo = {
              addTodoInfo |
              description = description
            }
        }, Cmd.none)

      SubmitLoginInfo userId password ->
        (model, submitLoginInfo {
          userId = userId,
          password = password,
          isLoggedIn = False
        })

      Login loginResult ->
        if loginResult.isLoggedIn then
          ( {model | isLoginFail = False},
            Nav.pushUrl model.key "/top"
          )
        else
          ( {model | isLoginFail = True},
            Cmd.none
          )

      AddTodo title description ->
        (model, addTodo { title = title, description = description })

      AddFinishedTodo isAddSuccess -> -- TODO 成功可否判定処理分け
        ({
          model | addTodoInfo = {
            title = "",
            description = ""
          }
        }, Cmd.none)

view : Model -> Html Msg
view model =
  case toRoute <| Url.toString model.url of
    LoginPage ->
      viewLogin model

    TopPage ->
      addHeader <| viewTop model

    AddPage ->
      addHeader <| viewAdd model

    NotFoundPage ->
      addHeader <| viewNotFound model

viewLogin : Model -> Html Msg
viewLogin model =
  let
    errorMessageText = if model.isLoginFail then div [] [ text "ログインに失敗しました" ] else text ""
  in
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
          button [ onClick <| SubmitLoginInfo model.loginUserId model.loginUserPassword ] [ text "ログイン" ]
        ],
        errorMessageText
      ]

addHeader : Html Msg -> Html Msg
addHeader content =
  div [] [
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
    ],
    div [] [
      content
    ]
  ]

viewTop : Model -> Html Msg
viewTop model =
  div [] [
    text "トップ画面"
  ]

viewNotFound : Model -> Html Msg
viewNotFound model =
  div [] [ text "Not found page." ]

viewAdd : Model -> Html Msg
viewAdd model =
  span [] [
    div [] [ text "新規追加画面" ],
    div [] [
      div [] [
        text "TODOタイトル : ",
        input [ type_ "text", onInput InputAddTodoTitle, value model.addTodoInfo.title ] []
      ],
      div [] [
        text "TODO説明 : ",
        textarea [ rows 8, cols 80, onInput InputAddTodoDescription, value model.addTodoInfo.description ] []
      ],
      div [] [
        text "画像登録 : ", -- TODO
        input [ type_ "file" ] []
      ],
      div [] [
        button [ onClick <| AddTodo model.addTodoInfo.title model.addTodoInfo.description ] [ text "登録" ]
      ]
    ]
  ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    getLoginResult Login,
    getAddTodoResult AddFinishedTodo
  ]

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