var path = require('path');
var util = require('util');
var logger = require('./logger');
var xml2js = require('xml2js');
var glob = require('glob');
var co = require('co');
var fs = require('co-fs');
var thunk = require('thunkify');
var nconf = require('nconf');
var debug = require('debug')('mssql:parse');

nconf
    .argv()
    .env();

// thunkify
glob = thunk(glob);
var parser = new xml2js.Parser({
    explicitArray: false
});
var parseString = thunk(parser.parseString);

co(function * () {
    var files = yield glob(path.resolve(__dirname, '../deps/autohammer/**/TPCC*.xml'));
    var len = files.length;
    var testResult = {};
    var sumTPMC = 0;
    var sumTPM = 0;
    var total = 0;
    for (var i = 0, l = files.length; i < l; i++) {
        var file = files[i];
        debug('parse file: %s', file);

        var content = yield fs.readFile(file);

        try {
            var json = yield parseString(content);
        } catch (e) {
            logger.error("parseString error: " + e);
            continue;
        }

        total++;

        var configruation = json.autohammer.get_configuration;
        var result = json.autohammer.run_tpcc.tpcc_results;

        //console.log(util.inspect(result, false, null));

        var test = configruation.test;
        var warehouses = configruation.warehouses;
        var runThreads = configruation.run_threads;
        var dbName = configruation.database_name;

        testResult[test + '_' + dbName + '_' + runThreads] = {
            tpm: parseFloat(result.server_tpm),
            tpmC: parseFloat(result.NOTPM),
            vUsers: parseInt(runThreads),
            dbName: dbName
        };
        sumTPMC += parseFloat(result.NOTPM);
        sumTPM += parseFloat(result.server_tpm);

        debug('tpm: %s, tpmC: %s, virtualUsers: %s',
            result.server_tpm.trim(),
            result.NOTPM.trim(),
            runThreads
        );
    }

    if (files && files.length) {
        for (var i = 0, l = files.length; i < l; i++) {
            yield rmdir(path.dirname(files[i]));
        }

        testResult.averageTPM = sumTPM / total;
        testResult.averageTPMC = sumTPMC / total;
        testResult.successNum = total;
        testResult.failNum = files.length - total;

        yield fs.writeFile(nconf.get('name'), JSON.stringify(testResult, null, 4), {});
    }
})();

function * rmdir(dir) {
    var list = yield fs.readdir(dir);
    var len = list.length;
    while (len--) {
        var filename = path.join(dir, list[len]);
        var stat = yield fs.stat(filename);

        if (filename == "." || filename == "..") {
            // pass these files
        } else if (stat.isDirectory()) {
            // rmdir recursively
            yield rmdir(filename);
        } else {
            // rm fiilename
            yield fs.unlink(filename);
        }
    }
    yield fs.rmdir(dir);
};