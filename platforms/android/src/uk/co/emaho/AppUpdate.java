package uk.co.emaho;

    import android.net.Uri;
    import android.os.AsyncTask;
    import android.os.Environment;
    import android.util.Log;
    import android.webkit.WebView;

    import org.apache.cordova.CordovaInterface;
    import org.apache.cordova.CordovaPlugin;
    import org.apache.cordova.CallbackContext;

    import org.apache.cordova.CordovaWebViewClient;
    import org.apache.cordova.PluginResult;
    import org.json.JSONArray;
    import org.json.JSONException;

    import java.io.BufferedInputStream;
    import java.io.File;
    import java.io.FileOutputStream;
    import java.io.InputStream;
    import java.io.OutputStream;
    import java.net.URL;
    import java.net.URLConnection;
    import java.util.Locale;

    /**
     * This class echoes a string called from JavaScript.
     */
    public class AppUpdate extends CordovaPlugin {

        protected CallbackContext callbackContext;

        @Override
        public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
            this.callbackContext = callbackContext;

            if (action.equals("update")) {
                String urlString = args.getString(0);
                new DownloadFileAsync().execute(urlString);
                this.webView.reload();

                return true;
            }

            return false;
        }

        @Override
        public Uri remapUri(Uri uri) {

            // we only handle file schema, everything else goes unmapped
            if(!uri.getScheme().equalsIgnoreCase("file")) {
                return uri;
            }

            String scheme = uri.getScheme();
            if (scheme.equalsIgnoreCase("data")) {
                String path = uri.getPath();
                String fileDir = Environment.getExternalStorageDirectory().getAbsolutePath() + "/www";
                File file = new File(fileDir + path);
                if (file.canRead()) {
                    Uri.Builder builder = new Uri.Builder();
                    builder.scheme("file").path(fileDir);
                    for (String segment : uri.getPathSegments()) {
                        builder.appendPath(segment);
                    }

                    return builder.build();
                } else {
                    // file:///android_asset/www/index.html
                    Uri.Builder builder = new Uri.Builder();
                    builder.scheme("file").path("/android_asset/www");
                    for (String segment : uri.getPathSegments()) {
                        builder.appendPath(segment);
                    }

                    return builder.build();
                }
            } else {
                return  uri;
            }
        }

        class DownloadFileAsync extends AsyncTask<String, String, String> {

            @Override
            protected void onPreExecute() {
                super.onPreExecute();
            }

            @Override
            protected String doInBackground(String... urlString) {
                int count;

                try {
                    URL url = new URL(urlString[0]);
                    URLConnection connection = url.openConnection();
                    connection.connect();

                    int lenghtOfFile = connection.getContentLength();

                    InputStream input = new BufferedInputStream(url.openStream());
                    String fileDir = Environment.getExternalStorageDirectory().getAbsolutePath();
                    File file = new File(fileDir, "/AppUpdate.zip");
                    OutputStream output = new FileOutputStream(file);

                    byte data[] = new byte[1024];
                    long total = 0;

                    while ((count = input.read(data)) != -1) {
                        total += count;
                        publishProgress(""+(int)((total*100)/lenghtOfFile));
                        output.write(data, 0, count);
                    }

                    output.flush();
                    output.close();
                    input.close();
                } catch (Exception e) {
                    AppUpdate.this.callbackContext.error(e.getMessage());
                }

                return null;
            }

            protected void onProgressUpdate(String... progress) {
                PluginResult progressResult = new PluginResult(PluginResult.Status.OK, progress[0]);
                progressResult.setKeepCallback(true);
                AppUpdate.this.callbackContext.sendPluginResult(progressResult);
            }

            @Override
            protected void onPostExecute(String unused) {
                String fileDir = Environment.getExternalStorageDirectory().getAbsolutePath();
                String fileName = fileDir + "/AppUpdate.zip";
                String unzipPath = fileDir + "/www/";

                Unzip unzip = new Unzip(fileName, unzipPath);
                unzip.unzip();

                // reload new index page
                AppUpdate.this.webView.reload();
            }
        }
    }
