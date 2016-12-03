'use strict';
var log= require('../utils/logger');
var token= require('../utils/token');
var Q = require('q');
var oracledb = require('oracledb');
var dbConfig = require('../../config/dbconfig.js');
var numRows = 10;



var login=function (data,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {
        console.dir(data);
         var bindvars = {
          l_correo:  data.correo,
          l_password:  data.password, 
          ret:  { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 40 }
        };

        connection.execute("BEGIN :ret := login(:l_correo, :l_password); END;",bindvars)
                .then(function(result) {
                  console.log(result.outBinds);
                  if(result.outBinds.ret == 'false'){
                    res.status(401);
                    res.json({message:"Credenciales invalidas"});
                    connection.close();
                   }else{
                     connection.close();
                     getData(data,res);
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

}






var getData=function (data,res) {
   oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
            l_correo:  data.correo, 
            l_cursor:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        }; 

        connection.execute("BEGIN GET_USUARIO(:l_correo, :l_cursor); END;",bindvars)
                .then(function(result) {  
                    var cursor;
                    cursor = result.outBinds.l_cursor;
                    fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var userData={};
                            userData= mapping(resultCurso)[0];
                            userData.token=token.generateToken(userData);                       
                            console.log(userData);
                            res.status(200);  
                            res.json(userData);           
                        })
                        .catch(function(err) {
                          console.log(err);
                           res.status(400);   
                          res.json({message:"Incorrecta solicitud."});
                        }).finally(function() {
                          doClose(connection, resultSet);
                        });

                   

                   
                  
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

var loginAdmin=function (data,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_CORREO:  data.correo,
          E_PW:  data.password, 
          respuesta:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
   

        connection.execute("BEGIN LOGIN_LISTAR_USUARIO(:E_CORREO, :E_PW,:respuesta,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.respuesta;
                  if(code == -1){
                    res.status(401);
                    res.json({message:"Credenciales invalidas"});
                    connection.close();
                   }else if(code == 1){
                      var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var userData={};
                            userData.usuarios=mappingAdmin(resultCurso);
                            userData.token=token.generateToken(data.correo); 
                            console.log(userData.usuarios);
                            res.status(200);  
                            res.json(userData);           
                        })
                        .catch(function(err) {
                          console.log(err);
                           res.status(400);   
                          res.json({message:"Incorrecta solicitud."});
                        }).finally(function() {
                          doClose(connection, resultSet);
                        }); 
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

}



var loginAdminF=function (data,res) {

    oracledb.getConnection(
      {
        user          : dbConfig.user,
        password      : dbConfig.password,
        connectString : dbConfig.connectString
      })
    .then(function(connection) {

         var bindvars = {
          E_CORREO:  data.correo,
          E_PW:  data.password, 
          respuesta:  { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          salida:  { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };
   

        connection.execute("BEGIN LOGIN_ADMIN_F(:E_CORREO, :E_PW,:respuesta,:salida ); END;",bindvars)
                .then(function(result) {
                  var code=result.outBinds.respuesta;
                  if(code == -1){
                    res.status(401);
                    res.json({message:"Credenciales invalidas"});
                    connection.close();
                   }else if(code == 1){
                      var cursor=result.outBinds.salida;
                      fetchRowsFromRSArray(connection, cursor, numRows)
                        .then(function(resultCurso) {
                            connection.close(); 
                            var userData={};
                            userData=mappingAdminF(resultCurso)[0];
                            console.log(userData);
                            userData.token=token.generateToken(data.correo); 
                            res.status(200);  
                            res.json(userData);           
                        })
                        .catch(function(err) {
                          console.log(err);
                           res.status(400);   
                          res.json({message:"Incorrecta solicitud."});
                        }).finally(function() {
                          doClose(connection, resultSet);
                        }); 
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

function mapping(array) {
  var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.rut=array[i][0];
    obj.div= array[i][1],
    obj.nombre= array[i][2],
    obj.apPaterno= array[i][3],
    obj.apMaterno= array[i][4],
    obj.correo= array[i][5],
    obj.telefono= array[i][6],
    obj.sexo= array[i][7],
    obj.numeroTarjeta= array[i][8],
    obj.cv= array[i][9],
    obj.rol= array[i][10],
    obj.rate= array[i][11]
    arrayMapping.push(obj);
    
  };

  return arrayMapping;


};

function mappingAdmin(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.rut=array[i][0];
    obj.div=array[i][1];
    obj.nombre= array[i][2];
    obj.apPaterno= array[i][3];
    obj.apMaterno= array[i][4];
    obj.correo= array[i][5];
    obj.telefono= array[i][6];
    obj.estado= array[i][7];
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};

function mappingAdminF(array) {
 var arrayMapping=[];
  for (var i = 0; i < array.length; i++) {
    var obj={};
    obj.nombre= array[i][0];
    obj.apPaterno= array[i][1];
    obj.apMaterno= array[i][2];
    obj.correo= array[i][3];
    arrayMapping.push(obj);
    
  };

  return arrayMapping;

};




module.exports.login=login;
module.exports.loginAdmin=loginAdmin;
module.exports.loginAdminF=loginAdminF;
module.exports.getData=getData;