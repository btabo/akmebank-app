const express = require("express");
const path = require("path");
const axios = require("axios");
var passport = require('passport');
var Strategy = require('passport-local').Strategy;
var db = require('./db');

passport.use(new Strategy(
  function (username, password, cb) {
    db.users.findByUsername(username, function (err, user) {
      if (err) { return cb(err); }
      if (!user) { return cb(null, false); }
      if (user.password != password) { return cb(null, false); }
      return cb(null, user);
    });
  }));

passport.serializeUser(function (user, cb) {
  cb(null, user.id);
});

passport.deserializeUser(function (id, cb) {
  db.users.findById(id, function (err, user) {
    if (err) { return cb(err); }
    cb(null, user);
  });
});


const app = express();
const port = process.env.PORT || "8000";

app.set("views", path.join(__dirname, "views"));
app.set("view engine", "pug");
app.use(express.static(path.join(__dirname, "public")));
app.use(require('morgan')('combined'));
app.use(require('body-parser').urlencoded({ extended: true }));
app.use(require('express-session')({ secret: 'keyboard cat', resave: false, saveUninitialized: false }));
app.use(passport.initialize());
app.use(passport.session());

app.get("/", (req, res) => {
  res.render("index", { title: "Home" });
});

app.get("/user",
  require('connect-ensure-login').ensureLoggedIn(),
  async function (req, res) {
    var user = await getUserByName(req.user.username);
    res.render("user", { title: "User Profile", userName: req.user.username, userProfile: user });
  });

app.get("/accounts",
  require('connect-ensure-login').ensureLoggedIn(),
  async function (req, res) {
    var user = await getUserByName(req.user.username);
    var accounts = await getAccountsByUser(user);
    res.render("accounts", { title: "Accounts", userName: req.user.username, accounts: accounts });
  });

app.get("/login", (req, res) => {
  res.render("login", { title: "Home" });
});


app.post('/login',
  passport.authenticate('local', { failureRedirect: '/login' }),
  function (req, res) {
    res.redirect('/accounts');
  });

app.get('/logout',
  function (req, res) {
    req.logout();
    res.redirect('/');
  });

app.listen(port, () => {
  console.log(`Listening to requests on http://localhost:${port}`);
});


async function getAccountsByUser(user) {
  var accountNumbers = user.accountNumbers;
  var accounts = [];
  for (var i = 0; i < accountNumbers.length; i++) {
    var account = await getAccountById(accountNumbers[i]);
    accounts.push(account);
  }
  return accounts;
}

async function getUserByName(name) {
  var users = await listUsers()
  for (var i = 0; i < users.length; i++) {
    if (users[i].firstName.toLowerCase() == name.toLowerCase()) {
      return users[i];
    }
  }
  return {};
}

async function listUsers() {
  var url = getQueryURL() + '/users'
  var res = await listEntities(url);
  return res
}

async function getAccountById(id) {
  var url = getQueryURL() + '/accounts/' + id;
  var res = await listEntities(url);
  return res
}

async function listEntities(url) {
  var res;
  await axios.get(url)
    .then(function (response) {
      res = response.data;
    })
    .catch(function (error) {
      console.log(error);
    });
  return res;
}

function getQueryURL() {
  var url = process.env.QUERY_SERVICE_URL
  if (url == null || url == "") {
    url = 'http://account-query:8080'
    console.log('QUERY_SERVICE_URL not defined. Falling back to: ' + url)
  }
  return url
}
