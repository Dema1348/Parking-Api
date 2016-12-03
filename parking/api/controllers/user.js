'use strict';
var util = require('util');
var userService = require('../service/userService');
var Q = require('q');


var create= function(req, res) {

 	userService
      .create(req.body,res);
}

var findEstacionamientos=function(req,res){
	userService
		.findEstacionamientos(req.headers.api_key,res);
}

var updateRol=function(req,res){
	userService
		.updateRol(req.headers.api_key,res);
}

var findAutos=function(req,res){
	userService
		.findAutos(req.headers.api_key,res);
}


var findReservas=function(req,res){
	userService
		.findReservas(req.headers.api_key,res);
}

var findPagos=function(req,res){
	userService
		.findPagos(req.headers.api_key,res);
}

var findPendientes= function(req,res) {
	userService
		.findPendientes(req.headers.api_key,res);

}

var createRate= function(req,res) {
	userService
		.createRate(req.body,req.headers.api_key,res);

}

var updatesUser= function(req,res) {
	userService
		.updatesUser(req.body,req.headers.api_key,res);
};


module.exports.create=create;
module.exports.findEstacionamientos=findEstacionamientos;
module.exports.findReservas=findReservas;
module.exports.updateRol=updateRol;
module.exports.findAutos=findAutos;
module.exports.findPagos=findPagos;
module.exports.findPendientes=findPendientes;
module.exports.createRate=createRate;
module.exports.updatesUser=updatesUser;