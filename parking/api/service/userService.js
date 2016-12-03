'use strict';
var log= require('../utils/logger');
var token= require('../utils/token');
var moment= require('moment');
var Q = require('q');
var oracledb = require('oracledb');
oracledb.autoCommit = true;
var dbConfig = require('../../config/dbconfig.js');
var numRows = 10;




var create=function (data,res) {

        
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var bindvars = {
            E_RUT:  data.rut,
            DIV:  data.div, 
            FECHA_NAC: new Date(data.fechaNac),
            NOMBRE:data.nombre,
            AP_PATERNO:data.apPaterno,
            AP_MATERNO:data.apMaterno,
            SEXO:data.sexo,
            CV:data.cv,
            NUM_TARJETA:data.numeroTarjeta,
            E_CORREO:data.correo,
            PASSWORD:data.password,
            TELEFONO:data.telefono,
            ESTADO:1,
            ROL_ID:data.rol,
            ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
        };

        console.log(bindvars);

        connection.execute("BEGIN INSERTAR_PERSONA_Y_USUARIO(:E_RUT, :DIV, :FECHA_NAC, :NOMBRE, :AP_PATERNO, :AP_MATERNO, :SEXO, :CV, :NUM_TARJETA, :E_CORREO, :PASSWORD, :TELEFONO, :ESTADO, :ROL_ID, :ID_OPERACION); END;",bindvars)
                .then(function(result) {
                        console.log(result.outBinds);
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        res.json({message:"EL RUT YA SE ENCUENTRA REGISTRADO."});  
                         connection.close();  
                }else if(code ==1){
                        res.status(400);
                        res.json({message:"EL CORREO YA SE ENCUENTRA REGISTRADOS."});
                         connection.close();
                }else if(code==2){
                        res.status(400);
                        res.json({message:"INCORRECTO FORMATO DEL SEXO."});
                         connection.close();
                }else if(code==3){
                        res.status(400);
                        res.json({message:"INCORRECTO ROL DEL USUARIO."});
                         connection.close();
                }else if(code==4){
                        res.status(200);
                        res.json({message:"USUARIO CREADO CON EXITO."});
                        connection.commit();
                         connection.close();
                }else if(code==5){
                        res.status(500);
                        res.json({message:"Ha ocurrido un problema con nuestra en nuestro sistema intentelo mas tarde, gracias."});
                         connection.close();
                }else if(code==6){
                        res.status(400);
                        res.json({message:"Incorrecta solicitud."});
                         connection.close();
                }else if(code==7){
                        res.status(400);
                        res.json({message:"EL CORREO TIENE UN FORMATO INVALIDO."});
                         connection.close();
                }else if(code==8){
                        res.status(400);
                        res.json({message:"EL RUT TIENE UN FORMATO INVALIDO."});
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

var findEstacionamientos= function(api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_RUT:  token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
   
        connection.execute("BEGIN LISTAR_ESTA_USUARIO(:E_RUT, :ID_OPERACION,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.ID_OPERACION;
                  if(code == 1){
                     var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var estacionamientos=[];
                            estacionamientos=mappingEstacionamientos(resultCurso);
                            console.log(estacionamientos);
                            res.status(200);  
                            res.json(estacionamientos);           
                        })
                   }else if(code == 4){
                        res.status(400);   
                        res.json({message:"Incorrecta solicitud."}); 
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

var updateRol=function(api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          P_PERSONA_RUT:  token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
        };
   
        connection.execute("BEGIN UPDATE_ROL(:P_PERSONA_RUT, :ID_OPERACION ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.ID_OPERACION;
                  console.log(code);
                  if(code == 1){
                       res.status(400);   
                       res.json({message:"Incorrecta solicitud."}); 
                  }else if(code == 2){
                        res.status(400);   
                        res.json({message:"Ya posee el perfil de dueño."});   
                  }else if(code == 3){
                        res.status(200);   
                        res.json({message:"Perfil actualizado con éxito."});             
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



var findAutos= function(api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_RUT:  token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
   
        connection.execute("BEGIN LISTAR_AUTO_USUARIO(:E_RUT, :ID_OPERACION,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.ID_OPERACION;
                  if(code == 1){
                     var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var autos=[];
                            autos=mappingAuto(resultCurso);
                            console.log(autos);
                            res.status(200);  
                            res.json(autos);           
                        })
                   }else if(code == 4){
                        res.status(400);   
                        res.json({message:"Incorrecta solicitud."}); 
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

var findReservas= function(api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_RUT:  token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
   
        connection.execute("BEGIN LISTAR_RESERVAS_USUARIO(:E_RUT, :ID_OPERACION,:salida ); END;",bindvars)
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
                            var reservas=[];
                            reservas=mappingReservas(resultCurso);
                            res.status(200);  
                            res.json(reservas);           
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


var findPagos= function(api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_RUT:  token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
      
        log.info(bindvars);
        connection.execute("BEGIN LISTAR_PAGOS_USUARIO(:E_RUT, :ID_OPERACION,:salida ); END;",bindvars)
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

var findPendientes= function(api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_RUT:  token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
      
        log.info(bindvars);
        connection.execute("BEGIN LISTAR_CALIFICACIONESP_USUARIO(:E_RUT, :ID_OPERACION,:salida ); END;",bindvars)
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
                            var pendientes=[];
                            pendientes=mappingPendientes(resultCurso);
                            console.log(pendientes);
                            res.status(200);  
                            res.json(pendientes);           
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



var createRate=function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var bindvars = {
          P_ID:  data.id,
          P_RATE:  data.rate, 
          P_COMENTARIO: data.comentario, 
          P_PERSONA_RUT: token.decodeToken(api).rut, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
        };


    connection.execute("BEGIN UPDATE_CALIFICACION(:P_RATE, :P_ID,:P_COMENTARIO,:P_PERSONA_RUT,:ID_OPERACION); END;",bindvars)
             .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        res.json({message:"LA CALIFICACION NO SE ENCUENTRA REGISTRADO EN LA BASE DE DATOS"});   
                        connection.close(); 
                }else if(code ==1){
                        res.status(403);
                        res.json({message:"NO TIENE LOS PERMISOS PARA CREAR UN AUTO"});
                        connection.close();
                }else if(code==2){
                        res.status(200);
                        res.json({message:"CALIFICACION REALIZADA CON EXITO"});
                        connection.close();
                }else if(code==3){
                        res.status(200);
                        res.json({message:"LA CALIFICACION DEBE ESTAR ENTRE 1 y 5"});
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


var updatesUser= function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var bindvars = {
          P_PERSONA_RUT:  data.rut,
          P_ESTADO:  data.estado, 
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
        };
        
       
                         

    connection.execute("BEGIN UPDATE_ESTADO_USER(:P_PERSONA_RUT, :P_ESTADO,:ID_OPERACION); END;",bindvars)
             .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(400);
                        connection.close(); 
                }else if(code ==1){
                        res.status(403);
                        res.json({message:"EL USUARIO NO EXISTE"});
                        connection.close();
                }else if(code==2){
                        res.status(200);
                        res.json({message:"CAMBIO REALIZADO CON EXITO"});
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

function mappingEstacionamientos(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.id=array[i][0];
    obj.costo=array[i][1];
    obj.geo= {lat: array[i][2],
              lon: array[i][3]};
    obj.comuna= array[i][4];
    obj.estado= array[i][5];
    obj.horarios= array[i][6];
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};


function mappingAuto(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.patente=array[i][0] || '';
    obj.marca=array[i][1] || '';
    obj.color= array[i][2] || '';
     obj.motor= array[i][3] || '';
    obj.chasis= array[i][4] || '';
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};


function mappingReservas(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.id=array[i][0];
    obj.horaEntrada=moment(array[i][1]).format();
    obj.horaSalida= moment(array[i][2]).format(),
    obj.total= array[i][3],
    obj.fecha= moment(array[i][4]).format(),
    obj.autoPatente= array[i][5],
    obj.correo= array[i][6],
    obj.telefono= array[i][7],
    obj.nombre= array[i][8],
    obj.apPaterno= array[i][9],
    obj.apMaterno= array[i][10],
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};


function mappingPagos(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.horaEntrada=moment(array[i][0]).format();
    obj.horaSalida= moment(array[i][1]).format(),
    obj.total= array[i][2],
    obj.estadoPago= array[i][3],
    obj.type= array[i][4]
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};

function mappingPendientes(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.id=array[i][0];
    obj.horaEntrada=moment(array[i][1]).format();
    obj.horaSalida= moment(array[i][2]).format(),
    obj.nombre= array[i][3],
    obj.apPaterno= array[i][4],
    obj.apMaterno= array[i][5],
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

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