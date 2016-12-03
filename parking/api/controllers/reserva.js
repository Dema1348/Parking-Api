'use strict';
var util = require('util');
var reservaService = require('../service/reservaService');
var Q = require('q');


var detalleReserva= function(req, res) {

  reservaService
      .detalleReserva(req.swagger.params.id.value,req.headers.api_key,res);
}


var createReserva= function(req, res) {

  reservaService
      .createReserva(req.body,req.headers.api_key,res);
}


var deleteReserva= function(req, res) {

  reservaService
      .deleteReserva(req.swagger.params.id.value,req.headers.api_key,res);
}

var reservaPagadas= function(req, res) {

  reservaService
      .reservaPagadas(res);
}

var reservaEstados= function(req, res) {

  reservaService
      .reservaEstados(res);
}




module.exports.detalleReserva=detalleReserva;
module.exports.createReserva=createReserva;
module.exports.deleteReserva=deleteReserva;
module.exports.reservaPagadas=reservaPagadas;
module.exports.reservaEstados=reservaEstados;