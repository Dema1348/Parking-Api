'use strict';
var util = require('util');
var horarioService = require('../service/horarioService');
var Q = require('q');


var createHorario= function(req, res) {

  horarioService
      .createHorario(req.body,req.headers.api_key,res);
}



module.exports.createHorario=createHorario;