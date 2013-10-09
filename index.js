
/*
 * GET home page.
 */
var S 	= require('string'),
fs 		= require('fs'),
async   = require('async');

var lua_scripts = {};

exports.init_db = function(db) {
	var lua_common_files = ["common", "get_by_id", "get", "get_one", "get_id", "set", "link", "get_sideloaded", "get_sums","json"];
	var lua_files = fs.readdirSync(__dirname + '/lua');
	var lua_common = "";

	for(var f in lua_common_files) {
		var name = lua_common_files[f];
		lua_common +=  fs.readFileSync(__dirname + '/lua-common/' + name + ".lua", 'utf8');
	}
	
	for(var f in lua_files) {
		var name = lua_files[f];
		var text = lua_common + fs.readFileSync(__dirname + '/lua/' + name, 'utf8');
		lua_scripts[S(name).chompRight('.lua').s] = {text: text};
	}
		//console.log(lua_scripts);
	async.each(Object.keys(lua_scripts), function(s, done) {
		console.log("Key: " + s);
		//console.log("Text: " + lua_scripts[s].text);
		
		db.script("LOAD", lua_scripts[s].text, function(err, obj) {
	 		if(err) {
	 			console.log("SCRIPT LOAD ERROR: " + err);
	 			log(s);
	 		}
	 		lua_scripts[s].sha1 = obj;
	 		done();
	 	});
	}, function(err) {
        if(err) console.log(err);
    });
};

exports.import_node = function(obj, db, done) {
 	db.evalsha(lua_scripts["import_node"].sha1, 0, JSON.stringify(obj), function(err, obj) {
 		if(err) {
 			console.log(err);
 			console.log(lua_scripts["import_node"].text);
 		}
 		done(obj);
 	});
};

exports.import_link = function(type_src, id_src, name, value, type_dst, id_dst, db, done) {
	db.evalsha(lua_scripts["import_link"].sha1, 0, type_src, id_src, name, value, type_dst, id_dst, function(err, obj) {
 		if(err) console.log(err);
 		done();
 	});
};

exports.getJSON = function(node_type, order_by, order, start, stop, values, links, ties, sums, db, done) {
	db.evalsha(lua_scripts["get"].sha1, 0, node_type, order_by, order, start, stop, values, links, ties, sums, function(err, obj) {
		if(err) {
			console.log("GET:" + err);
		} else {
			done(obj);
		}
	});
};

exports.get = function(node_type, order_by, order, start, stop, values, links, ties, sums, db, done) {
	exports.getJSON(node_type, order_by, order, start, stop, values, links, ties, sums, db, function(obj) {
		done(JSON.parse(obj));
	});
};

// Эта функция устарела. Вместо нее надо использовать call
exports.get_one = function(node_type, node_id, values, links, db, done) {
	db.evalsha(lua_scripts["get_one"].sha1, 0, node_type, node_id, values, links, function(err, obj) {
		if(err) {
			console.log("GET_ONE - DEPRECATED: " + err);
		} else {
			obj = JSON.parse(obj);
			done(obj);
		}
		
	});
};

function log(script) {
	var src = lua_scripts[script].text;
	var lines = S(src).parseCSV('\n', '');
	var len = lines.length;
	for(var i = 0; i < len; i++) {
		console.log((i+1) + ": " + lines[i]);
	}
}





exports.call = function() {
	var len = arguments.length;
	var db = arguments[len-2];
	var done = arguments[len-1];
	var script = arguments[0];
	var args = [lua_scripts[script].sha1, 0];
	for(var i = 1; i < len-2; i++) {
		args.push(arguments[i]);
	}
	args.push(function(err, obj) {
		if(err) {
			console.log("CALL " + script + " ERROR: " + err);
			log(script);
		} else {
			done(obj);
		}		
	});
	console.log(args);
	db.evalsha.apply(db, args);
}

