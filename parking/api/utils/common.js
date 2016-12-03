var elasticsearch = require('elasticsearch');
var elasticConfig = require('../../config/elasticconfig');

var indexName = "parking";
var client = new elasticsearch.Client(elasticConfig.config());


var  indexExists = function() {  
    return client.indices.exists({
        index: indexName
    });
}


var initIndex = function() {  
    return client.indices.create({
        index: indexName
    });
}

var  deleteIndex=function () {  
    return client.indices.delete({
        index: indexName
    });
}


var initMapping =function() {  
	var body = {
    	estacionamiento:{
        		properties: {
	                geo: {"type" : "geo_point"}                
            }
    	}
            
    }

    return client.indices.putMapping({
        index: indexName,
        type: "estacionamiento",
        body:body
    });
}

var cliente = function() {
	return client;
};


module.exports.cliente=cliente;
module.exports.initMapping = initMapping;
module.exports.deleteIndex = deleteIndex;
module.exports.initIndex = initIndex;
module.exports.indexExists=indexExists;