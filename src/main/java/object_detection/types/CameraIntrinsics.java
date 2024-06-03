package object_detection.types;

import org.ejml.data.DMatrixRMaj;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Scanner;

public class CameraIntrinsics {

    public CameraIntrinsics(String intr_path) throws FileNotFoundException {
        Scanner scanner = new Scanner(new File(intr_path));

        // get FocalLength
        String[] line = scanner.nextLine().split(",");
        this.FocalLength = new float[]{Float.parseFloat(line[0]), Float.parseFloat(line[1])};

        // get PrinciplePoints
        String[] line2 = scanner.nextLine().split(",");
        this.PrincipalPoint = new float[]{Float.parseFloat(line2[0]), Float.parseFloat(line2[1])};

        // get ImageSize
        String[] line3 = scanner.nextLine().split(",");
        this.ImageSize = new float[]{Float.parseFloat(line3[0]), Float.parseFloat(line3[1])};

        // read K (3x3)
        double[][] ktemp = new double[3][3];
        int i = 0;
        for(int y = 0; y < 3; y++) {
            String[] line4 = scanner.nextLine().split(",");
            // build a row
            ktemp[i][0] = Float.parseFloat(line4[0]);
            ktemp[i][1] = Float.parseFloat(line4[1]);
            ktemp[i][2] = Float.parseFloat(line4[2]);
            i++;
        }

        this.K = new DMatrixRMaj(ktemp);
    }

    /* ###############
        Members
     ############### */
    float[] FocalLength;
    float[] PrincipalPoint;
    float[] ImageSize;
    DMatrixRMaj K;

}
