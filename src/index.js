import { Elm } from './Main'

import * as firebase from 'firebase/app'
import 'firebase/auth'

import firebaseConfig from './js/firebase/Config.js'

firebase.initializeApp(firebaseConfig)

const app = Elm.Main.init()

app.ports.submitLoginInfo.subscribe(({ userId, password }) => {
  firebase.auth().signInWithEmailAndPassword(userId, password).catch(function(error) {
    app.ports.getLoginResult.send({
      userId : '',
      password : '',
      isLoggedIn : false
    })
  })
})

firebase.auth().onAuthStateChanged(user => {
  if(user) {
    app.ports.getLoginResult.send({
      userId : user.email,
      password : '',
      isLoggedIn : true
    })
  }
})