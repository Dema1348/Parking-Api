'use strict';
var log= require('../utils/logger');
var token= require('../utils/token');
var Q = require('q');
var oracledb = require('oracledb');
oracledb.autoCommit = true;
var dbConfig = require('../../config/dbconfig');
var numRows = 10;




var createAuto=function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var bindvars = {
	      P_PATENTE:  data.patente,
	      P_COLOR:  data.color, 
	      P_MARCA:data.marca, 
	      P_MOTOR: data.motor, 
	      P_PERSONA_RUT: token.decodeToken(api).rut, 
	      P_CHASIS: data.chasis,
	      ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
	    };


    connection.execute("BEGIN INSERTAR_AUTO(:P_PATENTE, :P_COLOR,:P_MARCA,:P_MOTOR,:P_PERSONA_RUT,:P_CHASIS, :ID_OPERACION); END;",bindvars)
       		 .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        res.json({message:"EL AUTO YA SE ENCUENTRA REGISTRADO"});   
                        connection.close(); 
                }else if(code ==1){
                        res.status(403);
                        res.json({message:"NO TIENE LOS PERMISOS PARA CREAR UN AUTO"});
                        connection.close();
                }else if(code==2){
                        res.status(200);
                        res.json({message:"AUTO CREADO CON EXITO."});
                        connection.close();
                }else if(code==5){
                        res.status(500);
                        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
                        connection.close();
                }else if(code==6){
                        res.status(400);
                        res.json({message:"Incorrecta solicitud."});
                        connection.close();
                }
                    
                })
                .catch(function(err) {
                    log.error(err.message); 
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    connection.close();
                })


      }).catch(function(err) {
        log.error(err.message); 
        res.status(500);
        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
        connection.close();
      });  


}

var deleteAuto= function (data,api,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
        P_ID_AUTO:  data,
        P_PERSONA_RUT: decodeData.rut,
        ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      };   

      console.log(bindvars); 

     connection.execute("BEGIN ELIMINAR_AUTO(:P_ID_AUTO,:P_PERSONA_RUT, :ID_OPERACION); END;",bindvars)
           .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(403);
                        res.json({message:"EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD"});
                        connection.close();
                }else if(code==2){
                        res.status(400);
                        res.json({message:"NO EXISTE El AUTO QUE QUIERE ELIMINAR"});
                        connection.close();
                }else if(code==3){
                         res.status(200);
                        res.json({message:"AUTO ELIMINADO CON EXITO"});
                        connection.close();
                }else if(code==5){
                        res.status(500);
                        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
                        connection.close();
                }else if(code==6){
                        res.status(400);
                        res.json({message:"Incorrecta solicitud."});
                        connection.close();
                }
                    
                })
                .catch(function(err) {
                    log.error(err.message); 
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    connection.close();
               })


      }).catch(function(err) {
        log.error(err.message); 
        res.status(500);
        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
        connection.close();
      });  

};


var updateAuto=function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var bindvars = {
          P_PATENTE:  data.patente,
          P_COLOR:  data.color, 
          P_MARCA:data.marca, 
          P_MOTOR: data.motor, 
          P_PERSONA_RUT: token.decodeToken(api).rut, 
          P_CHASIS: data.chasis,
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
        };


    connection.execute("BEGIN UPDATE_AUTO(:P_PATENTE, :P_COLOR,:P_MARCA,:P_MOTOR,:P_PERSONA_RUT,:P_CHASIS, :ID_OPERACION); END;",bindvars)
             .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        res.json({message:"EL AUTO NO SE ENCUENTRA REGISTRADO"});   
                        connection.close(); 
                }else if(code ==1){
                        res.status(403);
                        res.json({message:"NO TIENE LOS PERMISOS PARA CREAR UN AUTO"});
                        connection.close();
                }else if(code==2){
                        res.status(200);
                        res.json({message:"AUTO ACTUALIZADO CON EXITO."});
                        connection.close();
                }else if(code==5){
                        res.status(500);
                        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
                        connection.close();
                }else if(code==6){
                        res.status(400);
                        res.json({message:"Incorrecta solicitud."});
                        connection.close();
                }
                    
                })
                .catch(function(err) {
                    log.error(err.message); 
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    connection.close();
                })


      }).catch(function(err) {
        log.error(err.message); 
        res.status(500);
        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
        connection.close();
      });  


}


function doRelease(connection)
{
  connection.release(
    function(err)
    {
      if (err) { console.error(err.message); }
    });
}

function doClose(connection, resultSet)
{
  resultSet.close(
    function(err)
    {
      if (err) { console.error(err.message); }
      doRelease(connection);
    });
}


module.exports.createAuto=createAuto;
module.exports.deleteAuto=deleteAuto;
module.exports.updateAuto=updateAuto;