var AppUpdate = {
    update: function(success, failure, url){
        cordova.exec(success, failure, "AppUpdate", "update", [url]);
    }
};

module.exports = AppUpdate;