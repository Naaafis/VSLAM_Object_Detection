package object_detection.types;

import org.ejml.data.*;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Scanner;

public class CameraPose {

    public CameraPose(String pose_path) throws FileNotFoundException {
        // create scanners
        Scanner scanner = new Scanner(new File(pose_path));

        float[] q = new float[3];
        String[] line = scanner.nextLine().split(",");
        q[0] = Float.parseFloat(line[0]);
        q[1] = Float.parseFloat(line[1]);
        q[2] = Float.parseFloat(line[2]);
        // wrap vector in FMatrix
        this.translation = new DMatrixRMaj(new double[]{q[0], q[1], q[2]});

        // read R (3x3 orientation)
        float[][] t = new float[3][3];
        int i = 0;
        for(int y = 0; y < 3; y++) {
            String[] line2 = scanner.nextLine().split(",");
            // build a row
            t[i][0] = Float.parseFloat(line2[0]);
            t[i][1] = Float.parseFloat(line2[1]);
            t[i][2] = Float.parseFloat(line2[2]);
            i++;
        }
        // wrap matrix in FMatrix
        this.R = new DMatrixRMaj(new double[][]{
                {t[0][0], t[0][1], t[0][2]},
                {t[1][0], t[1][1], t[1][2]},
                {t[2][0], t[2][1], t[2][2]}
        });
    }


    /* ##################
        Members
    #################### */
    DMatrixRMaj R;
    DMatrixRMaj translation;

}
