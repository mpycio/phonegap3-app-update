phonegap3-app-update
====================

PhoneGap plugin for updating application www contents from URL. 
PhoneGap puts www folder inside the app bundle which can’t be written to. For this app to work I had to override one of the core PhoneGap methods to change path to Documents folder. 

Usage:
 phonegap plugin add https://github.com/mpycio/phonegap3-app-update.git




 phonnegap create hello com.example.hello HelloWorld
 cd hello
 phonegap plugin add https://github.com/mpycio/phonegap3-app-update.git
 phonegap build ios


Create a zip archive from within your www folder, put it somewhere on the web and change last parameter below to use your archive URL:


            <button id="appUpdateBtn" style="padding: 10px 50px;margin: 20px 0">Update app</button>
            <p id="result"></p>
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
