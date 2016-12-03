'use strict';
var util = require('util');
var autoService = require('../service/autoService');
var Q = require('q');


var createAuto= function(req, res) {
 console.log(req.body);
  autoService
      .createAuto(req.body,req.headers.api_key,res);
}

var deleteAuto = function(req,res) {

  autoService
  	.deleteAuto(req.swagger.params.id.value,req.headers.api_key,res);
}


var updateAuto= function(req, res) {

  autoService
      .updateAuto(req.body,req.headers.api_key,res);
}


module.exports.createAuto=createAuto;
module.exports.deleteAuto=deleteAuto;
module.exports.updateAuto=updateAuto;