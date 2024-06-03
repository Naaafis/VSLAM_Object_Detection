package object_detection.types;

import com.opencsv.exceptions.CsvValidationException;
import object_detection.Downsampler;
import org.ejml.data.DMatrix3x3;
import org.ejml.data.DMatrix3;
import org.ejml.data.DMatrix4;
import org.ejml.data.DMatrixRMaj;
import org.ejml.dense.fixed.CommonOps_DDF3;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.*;

import static org.ejml.dense.row.CommonOps_DDRM.*;

public class Frame {


    public Frame(String bboxpth, CameraPose cp) throws FileNotFoundException {
        this.bboxpath = bboxpth;
        this.boxes = getBoxes(bboxpth);
        this.camera = cp;
    }

    public List<BoundingBox2D> getBoxes(String bboxpath) throws FileNotFoundException {
        Scanner scanner = new Scanner(new File(bboxpath));
        scanner.nextLine(); // Skip header

        ArrayList<BoundingBox2D> res = new ArrayList<>();
        while (scanner.hasNextLine()) {
            String[] line = scanner.nextLine().split(",");
            // create the box accordingly
            int x = Integer.parseInt(line[2]);
            int y = Integer.parseInt(line[3]);
            int w = Integer.parseInt(line[4]);
            int h = Integer.parseInt(line[5]);
            res.add(new BoundingBox2D(x,y,w,h,line[0]));
        }
        scanner.close();

        return res;
    }

    /**
     * Given a list of 3D points, returns a list of 2D points corresponding to where those 3D points fall within the current 2D frame
     * @param points : 3D points
     * @return : map of 2D points, indexed by which 3D point they correspond to
     */
    public Map<Integer, Point2D> projectPoints(List<Point> points, CameraIntrinsics intrinsics){
        Map<Integer, Point2D> res = new HashMap<>();

        // calculate cameraMatrix as K * [R, t']
        DMatrixRMaj cameraMatrixTemp = new DMatrixRMaj();
        concatColumns(camera.R, camera.translation, cameraMatrixTemp);

        DMatrixRMaj cameraMatrix = new DMatrixRMaj();
        mult(intrinsics.K, cameraMatrixTemp, cameraMatrix);

        int i = 0;
        for(Point p : points){
            // pad point (x,y,z) --> (x,y,z,1)
            DMatrixRMaj pvec = new DMatrixRMaj(new double[]{p.getX(), p.getY(), p.getZ(), 1});

            // get projection --> projPoint
            DMatrixRMaj projPoint = new DMatrixRMaj();
            multTransAB(pvec, cameraMatrix, projPoint);

            // divide x,y by z value
            double x_div = projPoint.get(0,0) / projPoint.get(0,2);
            double y_div = projPoint.get(0,1) / projPoint.get(0,2);

            // check if point is visible in current frame
            if(projPoint.get(0,2) > 0){
                if(x_div < intrinsics.ImageSize[1]
                    && x_div >= 0
                    && y_div < intrinsics.ImageSize[0]
                    && y_div >= 0){
                    res.put(i, new Point2D((float) x_div, (float) y_div));
                }
            }
            i++;
        }

        return res;
    }

    /* #########################
        Members
    ########################### */
    String bboxpath;
    List<BoundingBox2D> boxes;
    CameraPose camera;

}
