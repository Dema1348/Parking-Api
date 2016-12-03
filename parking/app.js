'use strict';

var SwaggerExpress = require('swagger-express-mw');
var SwaggerUi = require('swagger-tools/middleware/swagger-ui');
var cors = require('cors');
var token= require('./api/utils/token');
var log= require('./api/utils/logger');
var common= require('./api/utils/common');
var oracledb = require('oracledb');
var dbConfig = require('./config/dbconfig.js');

var app = require('express')();
module.exports = app; // for testing

var config = {
  appRoot: __dirname,
  swaggerSecurityHandlers: {
    api_key: function (req, authOrSecDef, ApiKey, cb) {
      // your security code
      if (token.validateToken(ApiKey)) {
        log.warn("Api key correcta");
        cb(null);
      } else {
        log.warn("Api key invalida");
        
        cb(new Error('access denied!'));
      
      }
    }
  }
};




SwaggerExpress.create(config, function(err, swaggerExpress) {
  if (err) { throw err; }

    common
      .cliente()
      .ping({
      requestTimeout: 3000,
      hello: "elasticsearch!"
    }, function (error) {
      if (error) {
        log.error('Elasticsearch  is down!');
        throw err;
      } else {
        log.debug('Elasticsearch OK ');
        log.debug('Elasticsearch IP '+common.cliente().transport._config.host);
        common
        .indexExists()
        .then(function(exist) {
           if(exist){
            log.debug("Indice ya creado");
               common.initMapping()
               .then(function() {
                 log.debug("Indice mapeado");
               },function(err) {
                log.error("No pudo ser mapeado: "+err);
                 throw err;
               })
           }else{
            log.warn("Indice no existe");
               common.initIndex().then(function() {
                 log.debug("Indice  creado ");
                 common.initMapping()
                 .then(function() {
                   log.debug("Indice mapeado");
                 },function(err) {
                  log.error("No pudo ser mapeado: "+err );
                   throw err;
                 })

              },function(err) {
                 log.error(err);
                  throw err;
              });
           }
        })

      }
    });



  oracledb.getConnection(dbConfig, function(err, connection)
  {
    if (err) {
      log.error(err.message);
      return;
    }
    log.debug('ORACLE OK');

    connection.release(
      function(err)
      {
        if (err) {
          log.error(err.message);
  
          return;
        }
      });
  });

  app.use(cors());
  app.use(SwaggerUi(swaggerExpress.runner.swagger));

  // install middleware
  swaggerExpress.register(app);

  var port = process.env.PORT || 10010;
  app.listen(port);

});
