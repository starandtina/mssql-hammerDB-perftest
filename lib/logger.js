var logan = require('logan');

logan.set({
    error: ['%', 'red'],
    success: ['%', 'green'],
    info: ['%', 'cyan']
})

module.exports = logan;