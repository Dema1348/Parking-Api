var jwt = require('jsonwebtoken');
var log = require('../utils/logger');


var generateToken = function(user) {
	log.info(user);	
	try {
	 var token = jwt.sign(user, 'api_parking', 43200 );
	} catch(err) {
	  log.info("info: "+err);
	}

	return token;
};

var validateToken = function(token) {
	var isValid=false;
	try {
	  var decoded = jwt.verify(token, 'api_parking');
	  isValid=true;
	} catch(err) {
	  log.info("info: "+err);
	}
	return isValid;
	
};

var decodeToken = function(token) {
    try {
        var decoded = jwt.verify(token, 'api_parking');
        return decoded;
    } catch (err) {
        log.error("Error decode Token: " + err);
    }
    return null;
};


module.exports.generateToken = generateToken;
module.exports.validateToken = validateToken;
module.exports.decodeToken=decodeToken;