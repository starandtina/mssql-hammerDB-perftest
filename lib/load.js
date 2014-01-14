var path = require('path');
var nconf = require('nconf');
var spawn = require('child_process').spawn;
var logger = require('./logger');
var debug = require('debug')('mssql:load');

nconf
    .argv()
    .env();

var config = nconf.get('config') || nconf.get('CONFIG');

if (!config) {
    logger.error('No configuration file found, specify via --config or set CONFIG');
    process.exit(1);
}

nconf.file(config);

var host = nconf.get('database:host');
var port = nconf.get('database:port');
var username = nconf.get('database:username');
var password = nconf.get('database:password');
var warehouses = nconf.get('tpcc:warehouses');
var loadThreads = nconf.get('tpcc:load_threads');

warehouses.forEach(function (warehouse) {
    var dbName = 'tpcc' + warehouse;
    var dbNameKey = 'tpcc:' + warehouse;

    if (!nconf.get(dbNameKey)) {
        var loadProcess = spawn(
            nconf.get('tclsh86t'), [
                nconf.get('mssql:load_gen_script'),
                host,
                username,
                password,
                warehouse,
                dbName,
                loadThreads,
                nconf.get('database:data_path'),
                nconf.get('database:log_path')
            ]
        );

        debug('spawn: warehouse[%s], dbName[%s]', warehouse, dbName);

        loadProcess.stdout.on('data', function (data) {
            logger.info('warehouse[' + warehouse + '], dbName[' + dbName + ']:' + data);
        });

        loadProcess.stderr.on('data', function (data) {
            logger.error('warehouse[' + warehouse + '], dbName[' + dbName + ']:' + data);
        });

        loadProcess.on('close', function (code) {
            if (code === 0) {
                nconf.set(dbNameKey, dbName);
                nconf.save();
            }

            logger.success('warehouse[' + warehouse + '], dbName[' + dbName + ']:' + 'child process exited with code ' + code);
        });
    } else {
        logger.error(dbNameKey + ' has existed');
    }
});

//
// Save the configuration object to disk
//