import { Elm } from './Main'

import * as firebase from 'firebase/app'
import 'firebase/auth'
import 'firebase/firestore'

import firebaseConfig from './js/firebase/Config.js'

firebase.initializeApp(firebaseConfig)

const db = firebase.firestore()

const app = Elm.Main.init()

app.ports.sendLoginRequest.subscribe(({ userId, password }) => {
  firebase.auth().signInWithEmailAndPassword(userId, password)
  .then(() => {
    app.ports.getLoginResult.send({
      userId,
      password,
      isLoginSuccess : true
    })
  })
  .catch(function(error) {
    app.ports.getLoginResult.send({
      userId : '',
      password : '',
      isLoginSuccess : false
    })
  })
})

app.ports.addTodo.subscribe(({title, description}) => {
  db.collection('todoList').add({
    title,
    description
  })
  .then(()  => app.ports.getAddTodoResult.send(true))
  .catch(() => app.ports.getAddTodoResult.send(false))
})

app.ports.sendSearchRequest.subscribe(({id, description}) => {
  console.log(id) // TODO
  console.log(description) // TODO
  db.collection('todoList').get().then(snapShot => {
    app.ports.getSearchResult.send(
      snapShot.docs.map(todo =>
        ({
          id : todo.id,
          title : todo.data().title,
          description : todo.data().description
        })
      )
    )
  })
})

app.ports.sendDeleteRequest.subscribe(id => {
  db.collection('todoList').doc(id).delete()
    .then(() => app.ports.getDeleteTodoResult.send(true))
    .catch(() => app.ports.getDeleteTodoResult.send(false))
})

const GET_TODO_PORTS = [
  {
    cmd : app.ports.sendGetDetailRequest,
    sub : app.ports.getDetailModel
  },
  {
    cmd : app.ports.sendGetEditRequest,
    sub : app.ports.getEditModel
  }
]

GET_TODO_PORTS.forEach(({sub, cmd}) => {
  cmd.subscribe(id => {
    db.collection('todoList').doc(id).get()
      .then(todo => {
        if(todo.exists) {
          sub.send({
            id,
            title : todo.data().title,
            description : todo.data().description
          })
        } else {
          sub.send({
            id : '',
            title : '',
            description : ''
          })
        }
      })
      .catch(error => sub.send({
        id : '',
        title : '',
        description : ''
      }))
  })
})

app.ports.sendUpdateRequest.subscribe(({ id, title, description }) => {
  const updateTodo = db.collection('todoList').doc(id)
  updateTodo.update({
    title,
    description
  })
  .then(() => app.ports.getUpdateResult.send(true))
  .catch(() => app.ports.getUpdateResult.send(false))
})

app.ports.showMessage.subscribe(message => alert(message))

firebase.auth().onAuthStateChanged(user => {
  if(user) {
    // TODO something.
  }
})
