package uk.co.emaho;

    import android.net.Uri;
    import android.os.AsyncTask;
    import android.util.Log;

    import org.apache.cordova.CordovaPlugin;
    import org.apache.cordova.CallbackContext;

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

            String path = uri.getPath();
            File filesDir = AppUpdate.this.cordova.getActivity().getFilesDir();
            File file = new File(filesDir, path);
            if (file.canRead()) {
                Uri newUri = Uri.fromFile(file);
                // or this ->Uri.parse(file.toString());

//                Uri.Builder builder = new Uri.Builder();
//                builder.scheme("file").path(fileDir);
//                for (String segment : uri.getPathSegments()) {
//                    builder.appendPath(segment);
//                }
//
//                Uri newUri = builder.build();
                Log.d("AppUpdate:remapUri", String.format("override path: %s", newUri.toString()));
                return newUri;

            } else {
                // file:///android_asset/www/index.html
                Uri.Builder builder = new Uri.Builder();
                builder.scheme("file").path("/android_asset/");
                for (String segment : uri.getPathSegments()) {
                    builder.appendPath(segment);
                }

                Uri newUri = builder.build();
                Log.d("AppUpdate:remapUri", String.format("original path: %s", newUri.toString()));
                return newUri;
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
                    File file = new File(AppUpdate.this.cordova.getActivity().getCacheDir(), "AppUpdate.zip");
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
                File filesPath = AppUpdate.this.cordova.getActivity().getFilesDir();
                File cachePath = AppUpdate.this.cordova.getActivity().getCacheDir();
                File zipFile = new File(cachePath, "AppUpdate.zip");

                Unzip unzip = new Unzip(zipFile, new File(filesPath, "www"));
                unzip.unzip();

                // reload new index page
                AppUpdate.this.webView.reload();
            }
        }
    }
