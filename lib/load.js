var fs = require('fs');
var path = require('path');
var nconf = require('nconf');
var spawn = require('child_process').spawn;
var logger = require('./logger');


nconf
    .argv()
    .env()
    .file(path.resolve(__dirname, '../config/config.json'));

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
                warehouses,
                dbName,
                loadThreads,
                nconf.get('database:data_path'),
                nconf.get('database:log_path')
            ]
        );

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