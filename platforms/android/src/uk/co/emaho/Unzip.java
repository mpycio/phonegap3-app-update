package uk.co.emaho;
import android.util.Log;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 *
 * @author jon simon (jondev.net)
 */
public class Unzip {
    private File _zipFile;
    private File _location;

    public Unzip(File zipFile, File location) {
        _zipFile = zipFile;
        _location = location;

        hanldeDirectory("");
    }

    public void unzip() {

        try {
            FileInputStream inputStream = new FileInputStream(_zipFile);
            ZipInputStream zipStream = new ZipInputStream(inputStream);
            ZipEntry zEntry = null;
            while ((zEntry = zipStream.getNextEntry()) != null) {
                if(zEntry.getName().startsWith("__MACOSX")) {
                    Log.d("Unzip", "Skipping " + zEntry.getName());
                    continue;
                }
                Log.d("Unzip", "Unzipping " + zEntry.getName() + " at " + _location);

                if (zEntry.isDirectory()) {
                    hanldeDirectory(zEntry.getName());
                } else {
                    FileOutputStream fout = new FileOutputStream(
                            this._location + "/" + zEntry.getName());
                    BufferedOutputStream bufout = new BufferedOutputStream(fout);
                    byte[] buffer = new byte[1024];
                    int read = 0;
                    while ((read = zipStream.read(buffer)) != -1) {
                        bufout.write(buffer, 0, read);
                    }

                    zipStream.closeEntry();
                    bufout.close();
                    fout.close();
                }
            }
            zipStream.close();
            Log.d("Unzip", "Unzipping complete. path :  " + _location);
        } catch (Exception e) {
            Log.d("Unzip", "Unzipping failed");
            e.printStackTrace();
        }

    }

    public void hanldeDirectory(String dir) {
        File f = new File(_location, dir);
        if (!f.isDirectory()) {
            f.mkdirs();
        }
    }
}
