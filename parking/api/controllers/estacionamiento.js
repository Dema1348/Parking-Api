'use strict';
var util = require('util');
var estacionamientoService = require('../service/estacionamientoService');
var Q = require('q');


var createEstacionamiento= function(req, res) {

   estacionamientoService
      .createEstacionamiento(req.body,req.headers.api_key,res);
}


var findByGeo=function(req,res) {
	estacionamientoService
		.findByGeo(req.query,res);
};

var findByComuna=function(req,res) {
	estacionamientoService
		.findByComuna(req.query,res);
};

var deleteEstacionamiento = function(req,res) {
  estacionamientoService
  	.deleteEstacionamiento(req.swagger.params.id.value,req.headers.api_key,res);
}

var disabled=function(req,res) {
	estacionamientoService
		.disabled(req.body,req.headers.api_key,res);
};

var enabled=function(req,res) {
	estacionamientoService
		.enabled(req.body,req.headers.api_key,res);
};


var findHorarios= function(req,res) {
	console.log(req.swagger.params.id.value);
	estacionamientoService
  	  .findHorarios(req.swagger.params.id.value,req.headers.api_key,res);
};


module.exports.createEstacionamiento=createEstacionamiento;
module.exports.findByGeo=findByGeo;
module.exports.findByComuna=findByComuna;
module.exports.disabled=disabled;
module.exports.enabled=enabled;
module.exports.deleteEstacionamiento=deleteEstacionamiento;
module.exports.findHorarios=findHorarios;