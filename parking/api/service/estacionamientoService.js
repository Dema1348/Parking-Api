'use strict';
var log= require('../utils/logger');
var token= require('../utils/token');
var Q = require('q');
var oracledb = require('oracledb');
var dbConfig = require('../../config/dbconfig.js');
var common = require('../utils/common');
var numRows = 10;
var client = common.cliente();
var indexName="parking";
var typeName="estacionamiento";
var moment = require('moment');
var _ = require('lodash');






var createEstacionamiento=function (data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
	      P_COSTO:  data.costo,
        P_COMUNA_ID: data.comunaId, 
        P_PERSONA_RUT: decodeData.rut, 
	      P_LATITUD:  data.geo.lat, 
	      P_LOGITUD: data.geo.lon, 
        P_ESTADO:data.estado,
	      ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        ID_ESTACIONAMIENTO:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        NOMBRE_COMUNA:  { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 100 }
	    };

   

     connection.execute("BEGIN INSERTAR_ESTACIONAMIENTO(:P_COSTO, :P_COMUNA_ID,:P_PERSONA_RUT, :P_LOGITUD,:P_LATITUD,:P_ESTADO,:ID_OPERACION,:ID_ESTACIONAMIENTO,:NOMBRE_COMUNA); END;",bindvars)
       		 .then(function(result) {
                var code=result.outBinds.ID_OPERACION;

                if(code == 0){
                        res.status(403);
                        res.json({message:"NO TIENE LOS PERMISOS PARA CREAR UN ESTACIONAMIENTO"});
                        connection.close();
                }else if(code==1){
                        res.status(400);
                        res.json({message:"EL COSTO DEBE SER POSITIVO."});
                        connection.close();
                }else if(code==2){
                        res.status(400);
                        res.json({message:"NO EXISTE LA COMUNA REGISTRADA."});
                        connection.close();
                }else if(code==3){
                        var id_estacionamiento=result.outBinds.ID_ESTACIONAMIENTO;
                        var nombre_comuna=result.outBinds.NOMBRE_COMUNA;
                        data.comuna=nombre_comuna;
                        data.id=id_estacionamiento;
                        data.dueno={
                          nombre: decodeData.nombre,
                          apPaterno: decodeData.apPaterno,
                          apMaterno: decodeData.apMaterno,
                          rut: decodeData.rut,
                          telefono: decodeData.telefono,
                          correo: decodeData.correo
                        }
                        goElastic(connection,res,data);

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

var findByGeo=function(data,res) {
  var body={};
  body ={
    query:{
          filtered: {
                query: {
                    term: {
                      estado: 1
                      }
                  },
                  filter : {
                        and : [
                            {
                            geo_distance:
                             {
                                distance:  data.rango?data.rango:'25km',
                                geo: {
                                        lat: data.lat,
                                        lon: data.lon
                                        }
                              }
                            }
                        ]
                    }
          }
      }
  }

  client.search({
                index: indexName,
                body:body
                }).then(function(result) {
                              var hits =[]; 
                              hits=result.hits.hits;
                              for (var i = hits.length - 1; i >= 0; i--) {
                                hits[i]=hits[i]._source;
                              };
                              log.info(hits);
                              res.status(200);
                              res.json(hits);
                             
                               
                    }, function (err) {
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    log.error(err)
                  })
          

};


var findByComuna= function(data,res) {
  var body={};
  body ={
    query:{
          filtered: {
                query: {
                    term: {
                      comunaId: data.comuna
                      }
                  }
          }
      }
  }

  client.search({
                index: indexName,
                body:body
                }).then(function(result) {
                              var hits =[]; 
                              hits=result.hits.hits;
                              for (var i = hits.length - 1; i >= 0; i--) {
                                hits[i]=hits[i]._source;
                              };
                              log.info(hits);
                              res.status(200);
                              res.json(hits);
                             
                               
                    }, function (err) {
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    log.error(err)
                  })
          

};

var disabled= function (data,api,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
        P_ID_ESTACIONAMIENTO:  1*data,
        P_PERSONA_RUT: decodeData.rut,
        ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      };    

     connection.execute("BEGIN DESABILITAR_ESTACIONAMIENTO(:P_ID_ESTACIONAMIENTO,:P_PERSONA_RUT, :ID_OPERACION); END;",bindvars)
           .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(403);
                        res.json({message:"EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD"});
                        connection.close();
                }else if(code==2){
                        res.status(400);
                        res.json({message:"NO EXISTE El ESTACIONAMIENTO QUE QUIERE SER ACTUALIZADO"});
                        connection.close();
                }else if(code==3){
                        updateEstado(connection,res,data,0);

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

var enabled= function (data,api,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
        P_ID_ESTACIONAMIENTO:  1*data,
        P_PERSONA_RUT: decodeData.rut,
        ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      };    

     connection.execute("BEGIN HABILITAR_ESTACIONAMIENTO(:P_ID_ESTACIONAMIENTO,:P_PERSONA_RUT, :ID_OPERACION); END;",bindvars)
           .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(403);
                        res.json({message:"EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD"});
                        connection.close();
                }else if(code==2){
                        res.status(400);
                        res.json({message:"NO EXISTE El ESTACIONAMIENTO QUE QUIERE SER ACTUALIZADO"});
                        connection.close();
                }else if(code==3){
                        updateEstado(connection,res,data,1);

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

function goElastic(connection,res,data) {
  client.create({
                  index: indexName,
                  type: typeName,
                  id:data.id,
                  body:  data
                  
              }).then(function(result) {
                res.status(200);
                res.json({message:"ESTACIONAMIENTO CREADO CON EXITO."});
                connection.commit();
                connection.close();
                 
              }, function (err) {
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    log.error(err)
                    connection.rollback();
                    connection.close();
         })
          


};

function updateEstado(connection,res,data,estado) {
  var body={};
  body ={
    doc: {
      estado: estado
    }
  }
console.log(estado);

  client.update({
                  index: indexName,
                  type: typeName,
                  id:data,
                  body:  body
                  
              }).then(function(result) {
                log.info(result)
                res.status(200);
                res.json({message:estado?"ESTACIONAMIENTO HABILITADO CON EXITO.":"ESTACIONAMIENTO DESABILITADO CON EXITO"});
                connection.commit();
                connection.close();
                 
              }, function (err) {
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    log.error(err)
                    connection.rollback();
                    connection.close();
         })
          


};

var deleteEstacionamiento= function (data,api,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

        var decodeData=token.decodeToken(api);

        var bindvars = {
        P_ID_ESTA:  data,
        P_PERSONA_RUT: decodeData.rut,
        ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      };    

     connection.execute("BEGIN ELIMINAR_ESTA(:P_ID_ESTA,:P_PERSONA_RUT, :ID_OPERACION); END;",bindvars)
           .then(function(result) {
                var code=result.outBinds.ID_OPERACION;
                if(code == 0){
                        res.status(403);
                        res.json({message:"EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD"});
                        connection.close();
                }else if(code==2){
                        res.status(400);
                        res.json({message:"NO EXISTE El ESTACIONAMIENTO QUE QUIERE ELIMINAR"});
                        connection.close();
                }else if(code==3){
                       goElasticDelete(connection,res,data)
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

function goElasticDelete(connection,res,data) {
  
  client.delete({
                  index: indexName,
                  type: typeName,
                  id:data           
              }).then(function(result) {
                res.status(200);
                res.json({message:"ESTACIONAMIENTO ELIMINADO CON EXITO."});
                connection.commit();
                connection.close();
                 
              }, function (err) {
                    res.status(400);
                    res.json({message:"Incorrecta solicitud."});
                    log.error(err)
                    connection.rollback();
                    connection.close();
         })
          


};



var findHorarios= function(data,api,res) {
    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_RUT:  token.decodeToken(api).rut, 
          E_ESTA: 1*data,
          ID_OPERACION:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
   
        connection.execute("BEGIN LISTAR_HORARIO_ESTA(:E_RUT,:E_ESTA, :ID_OPERACION,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.ID_OPERACION;
                  if(code == 1){
                     var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var horarios=[];
                            horarios=mappingHorarios(resultCurso);
                            res.status(200);  
                            res.json(horarios);         
                        })
                   }else if(code == 2){
                        res.status(400);   
                        res.json({message:"NO ES EL DUEÑO DEL ESTACIONAMIENTO."}); 
                  }
                   else if(code == 4){
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


function mappingHorarios(array) {
 var arrayMapping=[];
 var lastID=-1;
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.fecha=moment(array[i][0]).format();
    obj.horaTermino=moment(array[i][1]).format();
    obj.horaInicio= moment(array[i][2]).format();
    obj.idHorario=array[i][3];
    obj.type="Libre";
    if(lastID!= obj.idHorario){
      if(array[i][4]){
         
      }
      arrayMapping.push(obj);
      lastID=obj.idHorario;
     }
   
    if(array[i][4]){
      var obj2={};
      obj2.fecha=moment(array[i][0]).format();
      obj2.horaTermino=moment(array[i][4]).format();
      obj2.horaInicio= moment(array[i][5]).format();
      obj2.idHorario=array[i][3];
      obj2.type="Ocupado";
      obj2.idReserva=array[i][6];
      arrayMapping.push(obj2);
    }
    
  };

  return arrayMapping;

};

function bloquesOcupados(array) {
  var arrayMapping=[];
  var newBloques=[];
  var bloquePadre={};
  for (var x= 0; x < array.length; x++) {
     
        if(array[x].hasBloques){
          bloquePadre=array[x];
           for (var i = 0; i < array.length; i++) {
               if(array[i].type=="Ocupado" && array[i].idHorario==bloquePadre.idHorario){
                 log.info("Bloque ocupado")
                    var cotaInferior=subDate(bloquePadre.horaInicio,array[i].horaInicio);
                    var cotaSuperior=subDate(array[i].horaTermino,bloquePadre.horaTermino);
                    log.info("Division de bloque");
                    var newBloqueInferior={};
                    newBloqueInferior.fecha=bloquePadre.fecha;
                    newBloqueInferior.horaInicio= moment(bloquePadre.horaInicio).format();
                    newBloqueInferior.horaTermino=moment(bloquePadre.horaInicio).add(cotaInferior-1, 'minutes').format();
                    newBloqueInferior.idHorario=bloquePadre.idHorario;
                    newBloqueInferior.type="Libre inferior";
                    newBloques.push(newBloqueInferior);
                    log.info("Libre inferior");
                    var newBloqueSuperior={};
                    newBloqueSuperior.fecha=bloquePadre.fecha;
                    newBloqueSuperior.horaInicio= moment(bloquePadre.horaTermino).add(-cotaSuperior+1, 'minutes').format();
                    newBloqueSuperior.horaTermino=moment(bloquePadre.horaTermino).format();
                    newBloqueSuperior.idHorario=bloquePadre.idHorario;
                    newBloqueSuperior.type="Libre Superior";
                    newBloques.push(newBloqueSuperior);
                    log.info("Libre Superior");



            }

          }
        }

      
  };
  var finalArray=array.concat(newBloques);
  return finalArray;
};


function subDate(horaInicio,horaTermino) {
  var start = moment(horaInicio);
  var end = moment(horaTermino);
  var duration = moment.duration(end.diff(start));
  var minutos = duration.asMinutes();


  return minutos;
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

module.exports.createEstacionamiento=createEstacionamiento;
module.exports.findByGeo=findByGeo;
module.exports.findByComuna=findByComuna;
module.exports.deleteEstacionamiento=deleteEstacionamiento;
module.exports.disabled=disabled;
module.exports.enabled=enabled;
module.exports.findHorarios=findHorarios;