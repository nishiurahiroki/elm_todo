import { Elm } from './Main'

import * as firebase from 'firebase/app'
import 'firebase/auth'
import 'firebase/firestore'

import firebaseConfig from './js/firebase/Config.js'

firebase.initializeApp(firebaseConfig)

const db = firebase.firestore()

const app = Elm.Main.init()

app.ports.submitLoginInfo.subscribe(({ userId, password }) => {
  firebase.auth().signInWithEmailAndPassword(userId, password)
  .then(() => {
    app.ports.getLoginResult.send({
      userId,
      password,
      isLoggedIn : true
    })
  })
  .catch(function(error) {
    app.ports.getLoginResult.send({
      userId : '',
      password : '',
      isLoggedIn : false
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

firebase.auth().onAuthStateChanged(user => {
  if(user) {
    // TODO something.
  }
})
