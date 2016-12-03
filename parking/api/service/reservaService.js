'use strict';
var log= require('../utils/logger');
var token= require('../utils/token');
var Q = require('q');
var oracledb = require('oracledb');
var dbConfig = require('../../config/dbconfig.js');
var numRows = 10;
var moment = require('moment');
var nodemailer = require('nodemailer');




var createReserva=function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {
    	console.log(data);
        var bindvars = {
	      P_HORA_ENTRADA:  new Date(data.horaEntrada),
	      P_HORA_SALIDA: new Date(data.horaSalida), 
	      P_HORARIO_ID: data.idHorario, 
	      P_PATENTE: data.autoPatente,
	      P_PERSONA_RUT: token.decodeToken(api).rut, 
	      ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
	    };
     
	    log.info(bindvars);

    connection.execute("BEGIN INSERTAR_RESERVA(:P_HORA_ENTRADA, :P_HORA_SALIDA,:P_HORARIO_ID,:P_PATENTE,:P_PERSONA_RUT, :ID_OPERACION); END;",bindvars)
       		 .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        res.json({message:"NO TIENE LOS PERMISOS PARA CREAR LA RESERVA"});   
                        connection.close(); 
                }else if(code ==1){
                        res.status(403);
                        res.json({message:"NO EXISTE  EL HORARIO PARA REGISTRAR LA RESERVA"});
                        connection.close();
                }else if(code==2){
                        var transporter = nodemailer.createTransport('smtps://team.parking.dc@gmail.com:parking2016@smtp.gmail.com');
                        var mailOptions = {
                            from: '"Parking Team 👥" <team.parking.dc@gmail.com>', 
                            to: token.decodeToken(api).correo,
                            subject: 'Arriendo ✔', 
                            html: '<b>Arriendo exitoso 🐴</b>' // html body 
                        };

                        transporter.sendMail(mailOptions, function(error, info){
                            if(error){
                                return console.log(error);
                            }
                            console.log('Correo enviado: ' + info.response);
                        });

                        res.status(200);
                        res.json({message:"RESERVA CREADA CON EXITO."});
                        connection.close();


                }else if(code ==3){
                        res.status(403);
                        res.json({message:"YA TIENE RESERVAS EL BLOQUE SELECCIONADO"});
                        connection.close();
                }else if(code ==4){
                        res.status(403);
                        res.json({message:"NO PUEDE AUTO RESERVARSE SU MISMO ESTACIONAMIENTO"});
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

var detalleReserva= function (data,api,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
        E_RUT:decodeData.rut,
        E_ID_SERVICIO: data,
        ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }

      };  

            log.info(bindvars); 
  

         connection.execute("BEGIN DETALLE_RESERVA(:E_RUT,:E_ID_SERVICIO, :ID_OPERACION,:salida ); END;",bindvars)
            .then(function(result) {
              var code=result.outBinds.ID_OPERACION;
              if(code == 1){
              	res.status(400);
                res.json({message:"NO EXISTE LA RESERVA BUSCADA"});
                connection.close();
                 
                }else if(code==2){
                  var cursor=result.outBinds.salida;
                  fetchRowsFromRSArray(connection, cursor, numRows)
                    .then(function(resultCurso) {
                        connection.close(); 
                        var reserva={};
                        reserva=mappingReserva(resultCurso)[0];
                        console.log(reserva);
                        res.status(200);  
                        res.json(reserva);         
                    })     
                }else if(code==4){
                	res.status(403);
                    res.json({message:"NO ES EL DUEÑO O ARRENDADOR DEL SERVICIO"});
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


var deleteReserva= function (data,api,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
        P_ID_SERVICIO: data,
        P_PERSONA_RUT:decodeData.rut,
        ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      };  

      log.info(bindvars); 

        connection.execute("BEGIN ELIMINAR_RESERVA(:P_ID_SERVICIO, :P_PERSONA_RUT, :ID_OPERACION ); END;",bindvars)
            .then(function(result) {
              var code=result.outBinds.ID_OPERACION;
                if(code == 0){
              		res.status(403);
                    res.json({message:"Incorrecta solicitud."});
                    connection.close();            
                }
              	else if(code == 1){
              		res.status(403);
                    res.json({message:"NO EXISTE  LA RESERVA QUE DESEA ELIMINAR."});
                    connection.close();
                }else if(code==2){
                	res.status(200);
                    res.json({message:"ARRIENDO CANCELADO CON EXITO."});
                    connection.close();
                }else if(code==3){
                	res.status(403);
                    res.json({message:"PARA ELIMINAR UNA RESERVA DEBE HACERLO CON 24 HORAS DE ANTICIPACIÓN DESDE EL HORARIO DE ENTRADA DEL VEHICULO"});
                    connection.close();
                }else if(code==4){
                	res.status(403);
                    res.json({message:"NO ES EL DUEÑO O ARRENDADOR DEL SERVICIO"});
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

var reservaPagadas= function(res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
      
        log.info(bindvars);
        connection.execute("BEGIN LISTAR_PAGOS( :ID_OPERACION,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.ID_OPERACION;
                  if(code == 1){
                     res.status(400);   
                     res.json({message:"Incorrecta solicitud."}); 
                    
                  }else if(code == 2){
                       var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var pagos=[];
                            pagos=mappingPagos(resultCurso);
                            console.log(pagos);
                            res.status(200);  
                            res.json(pagos);           
                        }) 
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
                    return res;
                })


      }).catch(function(err) {
        log.error(err.message); 
        res.status(500);
        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
        connection.close();
      });  

};


var reservaEstados= function(res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
      
        log.info(bindvars);
        connection.execute("BEGIN ESTADO_PAGOS( :ID_OPERACION,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.ID_OPERACION;
                  if(code == 1){
                     res.status(400);   
                     res.json({message:"Incorrecta solicitud."}); 
                    
                  }else if(code == 2){
                       var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var estados=[];
                            estados=mappingEstadoPagos(resultCurso)[0];
                            console.log(estados);
                            res.status(200);  
                            res.json(estados);           
                        }) 
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
                    return res;
                })


      }).catch(function(err) {
        log.error(err.message); 
        res.status(500);
        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
        connection.close();
      });  

};



function mappingReserva(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.id=array[i][0];
    obj.horaEntrada=moment(array[i][1]).format();
    obj.horaSalida= moment(array[i][2]).format();
    obj.total= array[i][3];
    obj.fecha= moment(array[i][4]).format();
    obj.autoPatente= array[i][5];
    obj.correo= array[i][6];
    obj.telefono= array[i][7];
    obj.nombre= array[i][8];
    obj.apPaterno= array[i][9];
    obj.apMaterno= array[i][10];
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};

function mappingPagos(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.id=array[i][0];
    obj.rut=array[i][1];
    obj.div=array[i][2];
    obj.nombre= array[i][3];
    obj.apPaterno= array[i][4];
    obj.apMaterno= array[i][5];
    obj.total= array[i][6];
    obj.estadoPago= array[i][7];
    obj.fechaPago=moment(array[i][8]).format();
   
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};

function mappingEstadoPagos(array) {
   var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.total=array[i][0];
    obj.aprovados=array[i][1];
    obj.reprovados=array[i][2];
    obj.pendientes=array[i][3];
    arrayMapping.push(obj);
    
  };

  return arrayMapping;
};


function fetchRowsFromRSArray(connection, resultSet, numRows,data)
{
   var data=data||[];
   return Q.promise(function(resolve, reject) {
      resultSet.getRows(numRows,function (err, rows){
           if (err) {
            log.info(err);
            reject(err);
          } else if (rows.length === 0) { 
            resolve(data);
          } else if (rows.length > 0) {
            data=data.concat(rows);
            resolve(fetchRowsFromRSArray(connection, resultSet, numRows,data));
          }
        });
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

module.exports.detalleReserva=detalleReserva;
module.exports.deleteReserva=deleteReserva;
module.exports.createReserva=createReserva;
module.exports.reservaPagadas=reservaPagadas;
module.exports.reservaEstados=reservaEstados;