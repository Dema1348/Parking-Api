
var config= function() {
 	return {
 		 host : process.env.NODE_ELASTIC_HOST || "0.0.0.0:9200"
 	};
}

module.exports.config=config;