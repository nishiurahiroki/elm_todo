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
    addTodoInfo : AddTodoInfo,
    searchInfo : SearchInfo
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

type alias SearchInfo =
  {
    title : String,
    description : String,
    todoList : List TodoListItem
  }

type alias TodoListItem =
  {
    id : String,
    title : String,
    description : String
  }

port submitLoginInfo : LoginInfo -> Cmd msg
port addTodo : AddTodoInfo -> Cmd msg
port showMessage : String -> Cmd msg
port sendSearchRequest : SearchInfo -> Cmd msg
port sendDeleteRequest : String -> Cmd msg

port getLoginResult : (LoginInfo -> msg) -> Sub msg
port getAddTodoResult : (Bool -> msg) -> Sub msg
port getDeleteTodoResult : (Bool -> msg) -> Sub msg
port getSearchResult : (List TodoListItem -> msg) -> Sub msg

type Route =
  LoginPage |
  TopPage   |
  AddPage   |
  ListPage  |
  NotFoundPage

routeParser : Parser (Route -> a) a
routeParser =
  oneOf
    [ Url.Parser.map LoginPage   top
    , Url.Parser.map TopPage     (Url.Parser.s "top")
    , Url.Parser.map AddPage     (Url.Parser.s "add")
    , Url.Parser.map ListPage    (Url.Parser.s "list")
    ]


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
  DeleteTodo String |
  AddFinishedTodo Bool |
  SearchTodo String String |
  ShowSearchResult (List TodoListItem) |
  ShowDeleteResultMessage Bool

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
      },
      searchInfo = {
        title = "",
        description = "",
        todoList = []
      }
    },
    Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    { addTodoInfo, searchInfo } = model
  in
    case msg of
      LinkClicked urlRequest ->
        case urlRequest of
          Browser.Internal url ->
            let
              currentPage = Url.Parser.parse routeParser url |> Maybe.withDefault NotFoundPage
              listPageInitilalCmd = if currentPage == ListPage then
                                     sendSearchRequest searchInfo
                                    else
                                     Cmd.none
            in
              (model,
               Cmd.batch [
                Nav.pushUrl model.key (Url.toString url),
                listPageInitilalCmd
               ]
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
            Nav.pushUrl model.key "top"
          )
        else
          ( {model | isLoginFail = True},
            Cmd.none
          )

      AddTodo title description ->
        (model, addTodo { title = title, description = description })

      DeleteTodo id ->
        (model, sendDeleteRequest id)

      AddFinishedTodo isAddSuccess ->
        if isAddSuccess then
          ({
            model | addTodoInfo = {
              title = "",
              description = ""
            }
          }, showMessage "登録に成功しました" )
        else
          (model, showMessage "登録に失敗しました")

      SearchTodo title description ->
        (model , sendSearchRequest { searchInfo | title = title, description = description })

      ShowSearchResult todoList ->
        ({
          model | searchInfo = {
              searchInfo |
                todoList = todoList
          }
        }, Cmd.none)

      ShowDeleteResultMessage isSuccess ->
        let
          message = if isSuccess then "削除しました" else "削除に失敗しました"
        in
          (model, Cmd.batch [
                    showMessage message,
                    sendSearchRequest { searchInfo | title = model.searchInfo.title, description = model.searchInfo.description }
                  ]
          )


view : Model -> Html Msg
view model =
  case Url.Parser.parse routeParser model.url of
    Nothing ->
      viewNotFound model

    Just route ->
      case route of
        LoginPage ->
          viewLogin model

        TopPage ->
          addHeader <| viewTop model

        AddPage ->
          addHeader <| viewAdd model

        ListPage ->
          addHeader <| viewList model

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

viewList : Model -> Html Msg
viewList model =
  div [] [
    div [] [ text "検索" ],
    div [] [
      text "タイトル : ",
      input [ type_ "text" ] []
    ],
    div [] [
      text "説明 内容 : ",
      input [ type_ "text" ][]
    ],
    div [] [
      button [ onClick <| SearchTodo model.searchInfo.title model.searchInfo.description ] [ text "検索" ]
    ],
    div [] [
      table [] [
        thead [] [
          tr [] [
            th [] [ text "TODO ID" ],
            th [] [ text "TODO タイトル" ],
            th [] [ text "TODO 説明" ],
            th [] [ text "詳細" ],
            th [] [ text "削除" ]
          ]
        ],
        tbody []
          <| List.map (\todo -> tr [] [
            td [] [ text todo.id ],
            td [] [ text todo.title ],
            td [] [ text todo.description ],
            td [] [
              button [] [ text "詳細" ]
            ],
            td [] [
              button [ onClick <| DeleteTodo todo.id ] [ text "削除" ]
            ]
          ])
          <| model.searchInfo.todoList
      ]
    ]
  ]

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    getLoginResult Login,
    getAddTodoResult AddFinishedTodo,
    getSearchResult ShowSearchResult,
    getDeleteTodoResult ShowDeleteResultMessage
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