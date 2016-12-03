'use strict';
var util = require('util');
var authService = require('../service/authService');
var Q = require('q');


var login= function(req, res) {
	
  authService
  .login(req.body,res);

}

var loginAdmin= function(req, res) {
  console.log(req.body);
  authService
  .loginAdmin(req.body,res);

}

var loginAdminF= function(req, res) {
  console.log(req.body);
  authService
  .loginAdminF(req.body,res);

}

module.exports.login=login;
module.exports.loginAdmin=loginAdmin;
module.exports.loginAdminF=loginAdminF;