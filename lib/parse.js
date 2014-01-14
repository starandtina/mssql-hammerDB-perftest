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

var config = nconf.get('config') || nconf.get('CONFIG');

if (!config) {
    logger.error('No configuration file found, specify via --config or set CONFIG');
    process.exit(1);
}

nconf.file(config);

// thunkify
glob = thunk(glob);
var parser = new xml2js.Parser({
    explicitArray: false
});
var parseString = thunk(parser.parseString);
var specResult = {};

co(function * () {
    var files = yield glob(path.resolve(__dirname, '../deps/autohammer/**/TPCC*.xml'));
    var len = files.length;

    while (len--) {
        debug('parse file: %s', files[len]);

        var content = yield fs.readFile(files[len]);
        var json = yield parseString(content);

        var configruation = json.autohammer.get_configuration;
        var result = json.autohammer.run_tpcc.tpcc_results;

        //console.log(util.inspect(result, false, null));

        var test = configruation.test;
        var warehouses = configruation.warehouses;
        var runThreads = configruation.run_threads;
        var dbName = configruation.database_name;

        //yield fs.rmdir(path.dirname(files[len]));

        specResult[test + '_' + warehouses + '_' + runThreads] = {
            tpm: parseFloat(result.server_tpm),
            tpmC: parseFloat(result.NOTPM),
            vUsers: parseInt(runThreads),
            dbName: dbName
        };

        debug('tpm: %s, tpmC: %s, virtualUsers: %s',
            result.server_tpm.trim(),
            result.NOTPM.trim(),
            runThreads
        );
    }

    fs.writeFile(path.resolve(__dirname, '../spec_result.json'), JSON.stringify(specResult, null, 4));
})();