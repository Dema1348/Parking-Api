'use strict';
var log= require('../utils/logger');
var token= require('../utils/token');
var Q = require('q');
var oracledb = require('oracledb');
oracledb.autoCommit = true;
var dbConfig = require('../../config/dbconfig');
var numRows = 10;




var createHorario=function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {
    	console.log(data);
        var bindvars = {
	      P_HORA_TERMINO:  new Date(data.horaTermino),
	      P_HORA_INICIO: new Date(data.horaInicio), 
	      P_ESTACIONAMIENTO_ID:data.idEstacionamiento, 
	      P_PERSONA_RUT: token.decodeToken(api).rut, 
	      ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
	    };
	    log.info(bindvars);

    connection.execute("BEGIN INSERTAR_HORARIO(:P_HORA_TERMINO, :P_HORA_INICIO,:P_ESTACIONAMIENTO_ID,:P_PERSONA_RUT, :ID_OPERACION); END;",bindvars)
       		 .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        res.json({message:"NO TIENE LOS PERMISOS PARA CREAR EL HORARIO"});   
                        connection.close(); 
                }else if(code ==1){
                        res.status(403);
                        res.json({message:"NO EXISTE  EL ESTACIONAMIENTO PARA REGISTRAR EL HORARIO"});
                        connection.close();
                }else if(code==2){
                        res.status(200);
                        res.json({message:"BLOQUE DE HORARIO CREADO CON EXITO."});
                        connection.close();
                }else if(code ==3){
                        res.status(403);
                        res.json({message:"YA TIENE BLOQUES REGISTRADOS EN ESE HORARIO"});
                        connection.close();
                }else if(code ==4){
                        res.status(403);
                        res.json({message:"NO PUEDE REGISTRAR ESTE HORARIO EN UN DIA INFERIOR A LA FECHA ACTUAL"});
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


module.exports.createHorario=createHorario;