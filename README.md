phonegap3-app-update
====================

PhoneGap plugin for updating application www contents from URL.

phonnegap create hello com.example.hello HelloWorld
cd hello
phonegap plugin add ../AppUpdate
phonegap build ios


            <button id="appUpdateBtn" style="padding: 10px 50px;margin: 20px 0">Update app</button>
            <p id="result"></p>
            <script src="js/appUpdate.js"></script>
            <script>
            document.getElementById("appUpdateBtn").addEventListener("click", function(){
                AppUpdate.update(
                    function(msg){
                        document.getElementById("result").innerHTML = msg;
                    },
                    function(errMsg){
                        document.getElementById("result").innerHTML = msg;
                    },
                    "http://emaho.co.uk/AppUpdate-test.zip"
                );
            }, false);
            </script>
