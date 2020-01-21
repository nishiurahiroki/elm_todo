port module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Url.Parser exposing (Parser, (</>),(<?>),  int, map, oneOf, s, string, top)
import Url.Parser.Query as Query
import File exposing (File)
import File.Select as Select
import Task


type alias Model =
  {
    key : Nav.Key,
    url : Url.Url,
    addModel : AddModel,
    searchModel : SearchModel,
    detailModel : DetailModel,
    loginModel : LoginModel,
    editModel : EditModel
  }

type alias LoginModel =
  {
    userId : String,
    password : String,
    isLoginSuccess : Bool
  }

type alias AddModel =
  {
    title : String,
    description : String,
    imageUrlString : String
  }

type alias SearchModel =
  {
    title : String,
    description : String,
    todoList : List TodoListItem
  }

type alias DetailModel =
  {
    id : String,
    title : String,
    description : String
  }

type alias EditModel =
  {
    id : String,
    title : String,
    description : String
  }

type alias TodoListItem =
  {
    id : String,
    title : String,
    description : String
  }

port sendLoginRequest : LoginModel -> Cmd msg
port addTodo : AddModel -> Cmd msg
port showMessage : String -> Cmd msg
port sendSearchRequest : SearchModel -> Cmd msg
port sendDeleteRequest : String -> Cmd msg
port sendGetDetailRequest : String -> Cmd msg
port sendGetEditRequest : String -> Cmd msg
port sendUpdateRequest : EditModel -> Cmd msg

port getLoginResult : (LoginModel -> msg) -> Sub msg
port getAddTodoResult : (Bool -> msg) -> Sub msg
port getDeleteTodoResult : (Bool -> msg) -> Sub msg
port getSearchResult : (List TodoListItem -> msg) -> Sub msg
port getDetailModel : (DetailModel -> msg) -> Sub msg
port getEditModel : (EditModel -> msg) -> Sub msg
port getUpdateResult : (Bool -> msg) -> Sub msg

type Route =
  LoginPage  |
  TopPage    |
  AddPage    |
  ListPage   |
  DetailPage (Maybe String) |
  EditPage (Maybe String) |
  NotFoundPage

routeParser : Parser (Route -> a) a
routeParser =
  oneOf
    [ Url.Parser.map LoginPage   top
    , Url.Parser.map TopPage     (Url.Parser.s "top")
    , Url.Parser.map AddPage     (Url.Parser.s "add")
    , Url.Parser.map ListPage    (Url.Parser.s "list")
    , Url.Parser.map DetailPage  (Url.Parser.s "detail" <?> Query.string "id")
    , Url.Parser.map EditPage    (Url.Parser.s "edit" <?> Query.string "id")
    ]


type Msg =
  InputLoginUserIdText   String  |
  InputLoginPasswordText String  |
  InputAddTodoTitle String       |
  InputAddTodoDescription String |
  InputUpdateTodoTitle String    |
  InputUpdateTodoDescription String |
  SendLoginRequest String String |
  Login LoginModel |
  UrlChanged  Url.Url |
  LinkClicked Browser.UrlRequest |
  AddTodo String String |
  DeleteTodo String |
  AddFinishedTodo Bool |
  SearchTodo String String |
  ShowSearchResult (List TodoListItem) |
  ShowDeleteResultMessage Bool |
  ShowTodoDetail DetailModel |
  ShowTodoEdit EditModel |
  UpdateTodo |
  ShowUpdateResult Bool |
  RequestTodoImageFile |
  SelectTodoImageFile File |
  GetImageFileUrl String

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  (
    {
      url = url,
      key = key,
      loginModel = {
        userId = "",
        password = "",
        isLoginSuccess = True
      },
      addModel = {
        title = "",
        description = "",
        imageUrlString = ""
      },
      searchModel = {
        title = "",
        description = "",
        todoList = []
      },
      detailModel = {
        id = "",
        description = "",
        title = ""
      },
      editModel = {
        id = "",
        description = "",
        title = ""
      }
    },
    Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    { addModel, searchModel, loginModel, editModel, detailModel } = model
  in
    case msg of
      LinkClicked urlRequest ->
        case urlRequest of
          Browser.Internal url ->
            let
              currentPage = Url.Parser.parse routeParser url |> Maybe.withDefault NotFoundPage
              initialCommandList = case currentPage of
                ListPage ->
                  [sendSearchRequest searchModel]
                DetailPage id ->
                  [sendGetDetailRequest <| Maybe.withDefault "" id]
                EditPage id ->
                  [sendGetEditRequest <| Maybe.withDefault "" id]
                _ ->
                  [Cmd.none]
            in
              (model,
               Cmd.batch
                <| List.append [
                    Nav.pushUrl model.key (Url.toString url)
                   ]
                <| initialCommandList
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
        ({ model | loginModel = {
          loginModel |
            userId = userId
        }}, Cmd.none)

      InputLoginPasswordText password ->
        ({ model | loginModel = {
          loginModel |
            password = password
        }}, Cmd.none)

      InputAddTodoTitle title ->
        ({
          model |
            addModel = {
              addModel |
              title = title
            }
        }, Cmd.none)

      InputAddTodoDescription description ->
        ({
          model |
            addModel = {
              addModel |
              description = description
            }
        }, Cmd.none)

      InputUpdateTodoTitle title ->
        ({ model | editModel = {
          editModel | title = title
        }}, Cmd.none)

      InputUpdateTodoDescription description ->
        ({model | editModel = {
          editModel | description = description
        }}, Cmd.none)

      SendLoginRequest userId password ->
        (model, sendLoginRequest {
          userId = userId,
          password = password,
          isLoginSuccess = False
        })

      Login loginResult ->
        if loginResult.isLoginSuccess then
          ( {model | loginModel = loginResult},
            Nav.pushUrl model.key "top"
          )
        else
          ( {model | loginModel = loginResult},
            Cmd.none
          )

      AddTodo title description ->
        (model, addTodo { title = title, description = description, imageUrlString = "" })

      DeleteTodo id ->
        (model, sendDeleteRequest id)

      UpdateTodo ->
        (model, sendUpdateRequest editModel)

      AddFinishedTodo isAddSuccess ->
        if isAddSuccess then
          ({
            model | addModel = {
              title = "",
              description = "",
              imageUrlString = ""
            }
          }, Cmd.batch [
            showMessage "登録に成功しました",
            Nav.pushUrl model.key "list",
            sendSearchRequest { todoList = [], title = "", description = "" }
          ] )
        else
          (model, showMessage "登録に失敗しました")

      SearchTodo title description ->
        (model , sendSearchRequest { searchModel | title = title, description = description })

      ShowSearchResult todoList ->
        ({
          model | searchModel = {
              searchModel |
                todoList = todoList
          }
        }, Cmd.none)

      ShowDeleteResultMessage isSuccess ->
        let
          message = if isSuccess then "削除しました" else "削除に失敗しました"
        in
          (model, Cmd.batch [
                    showMessage message,
                    sendSearchRequest { searchModel | title = model.searchModel.title, description = model.searchModel.description }
                  ]
          )

      ShowTodoDetail result ->
        ({model | detailModel = result}, Cmd.none)

      ShowTodoEdit result ->
        ({model | editModel = result}, Cmd.none)

      ShowUpdateResult isSuccess ->
        if isSuccess then
          (model, Cmd.batch [
            showMessage "更新に成功しました",
            sendSearchRequest { todoList = [], title = "", description = "" },
            Nav.pushUrl model.key "list"
          ])
        else
          (model, showMessage "更新に失敗しました")

      RequestTodoImageFile ->
        (model, Select.file ["image/jpg", "image/png", "image/jpeg"] SelectTodoImageFile )

      SelectTodoImageFile image -> -- TODO
        (model, Task.perform GetImageFileUrl <| File.toUrl image)

      GetImageFileUrl imageUrl ->
        ({model |
            addModel = {
              addModel |
                imageUrlString = imageUrl
            }
        }, Cmd.none)


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

        DetailPage id ->
          addHeader <| viewDetail model

        EditPage id ->
          addHeader <| viewEdit model

        NotFoundPage ->
          addHeader <| viewNotFound model


viewLogin : Model -> Html Msg
viewLogin model =
  let
    errorMessageText = if model.loginModel.isLoginSuccess then text "" else div [] [ text "ログインに失敗しました" ]
  in
    div []
      [
        div [] [
          text "ユーザーID : ",
          input [ type_ "text", value model.loginModel.userId, onInput InputLoginUserIdText ] []
        ],
        div [] [
          text "パスワード : ",
          input [ type_ "password", value model.loginModel.password, onInput InputLoginPasswordText ] []
        ],
        div [] [
          button [ onClick <| SendLoginRequest model.loginModel.userId model.loginModel.password ] [ text "ログイン" ]
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

viewNotFound : Model -> Html Msg
viewNotFound model =
  div [] [ text "Not found page." ]

viewTop : Model -> Html Msg
viewTop model =
  div [] [
    text "トップ画面"
  ]

viewAdd : Model -> Html Msg
viewAdd model =
  span [] [
    div [] [ text "新規追加画面" ],
    div [] [
      div [] [
        text "TODOタイトル : ",
        input [ type_ "text", onInput InputAddTodoTitle, value model.addModel.title ] []
      ],
      div [] [
        text "TODO説明 : ",
        textarea [ rows 8, cols 80, onInput InputAddTodoDescription, value model.addModel.description ] []
      ],
      div [] [
        text "画像登録 : ",
        button [ onClick RequestTodoImageFile ] [ text "ファイル選択" ]
      ],
      div [] [
        button [ onClick <| AddTodo model.addModel.title model.addModel.description ] [ text "登録" ]
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
      input [ type_ "text" ] []
    ],
    div [] [
      button [ onClick <| SearchTodo model.searchModel.title model.searchModel.description ] [ text "検索" ]
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
              a [ href <| "/detail?" ++ "id=" ++ todo.id ] [
                button [] [ text "詳細" ]
              ]
            ],
            td [] [
              button [ onClick <| DeleteTodo todo.id ] [ text "削除" ]
            ]
          ])
          <| model.searchModel.todoList
      ]
    ]
  ]

viewDetail : Model -> Html Msg
viewDetail model =
  div [] [
    div [] [
      div [] [ text "詳細画面" ]
    ],
    div [] [
      div [] [
        text <| "TODO ID : " ++ model.detailModel.id
      ],
      div [] [
        text <| "TODO タイトル : " ++ model.detailModel.title
      ],
      div [] [
        text <| "TODO 説明" ++ model.detailModel.description
      ]
    ],
    div [] [
      a [ href <| "edit?id=" ++ model.detailModel.id ] [
        button [] [ text "編集" ]
      ]
    ]
  ]

viewEdit : Model -> Html Msg
viewEdit model =
  div [] [
    div [] [ text "詳細画面" ],
    div [] [
      div [] [
        text <| "TODO ID : " ++ model.editModel.id
      ],
      div [] [
        text "TODO タイトル : ",
        input [ type_ "text", value model.editModel.title, onInput InputUpdateTodoTitle ] []
      ],
      div [] [
        text "TODO 説明 : ",
        textarea [ onInput InputUpdateTodoDescription ] [ text model.editModel.description ]
      ],
      div [] [
        button [ onClick UpdateTodo ] [ text "更新" ]
      ]
    ]
  ]

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    getLoginResult Login,
    getAddTodoResult AddFinishedTodo,
    getSearchResult ShowSearchResult,
    getDeleteTodoResult ShowDeleteResultMessage,
    getDetailModel ShowTodoDetail,
    getEditModel ShowTodoEdit,
    getUpdateResult ShowUpdateResult
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