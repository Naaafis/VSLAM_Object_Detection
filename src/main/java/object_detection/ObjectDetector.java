package object_detection;

import com.opencsv.exceptions.CsvValidationException;
import database.MongoDBInteraction;
import object_detection.types.*;
import org.bytedeco.ffmpeg.avutil.Cmp_Const_Pointer_Const_Pointer;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ObjectDetector {


    /**
     * The starting function that creates an object set, compiles informatino, and returns it
     * @throws FileNotFoundException
     */
    public static void startProcess(String dataset) throws IOException, CsvValidationException {

        // for now, we can just set paths to the directories that hold keyframes and featurepoint CSVs
        String bbox_dir_pth;
        String pose_dir_path;
        CameraIntrinsics intrinsics;
        List<Point> pointCloud;

        if(dataset.equals("1")){
            bbox_dir_pth = "src/main/java/vslam/tum_rgbd/BoundedInfo";
            pose_dir_path = "src/main/java/vslam/tum_rgbd/CameraPoses";
            intrinsics = new CameraIntrinsics("src/main/java/vslam/tum_rgbd/CameraIntrinsics.csv");
            pointCloud = Downsampler.get_voxels("src/main/java/vslam/tum_rgbd/pointcloud.csv", 0.05F);
        }
        else{
            bbox_dir_pth = "src/main/java/vslam/imperial_london/BoundedInfo";
            pose_dir_path = "src/main/java/vslam/imperial_london/CameraPoses";
            intrinsics = new CameraIntrinsics("src/main/java/vslam/imperial_london/CameraIntrinsics.csv");
            pointCloud = Downsampler.get_voxels("src/main/java/vslam/imperial_london/pointcloud.csv", 0.05F);
        }

        // get files
        File[] bbox_CSVs = getDirFiles(bbox_dir_pth);
        File[] pose_CSVs = getDirFiles(pose_dir_path);

        // sort to guarantee correct order for keyframes
        Arrays.sort(bbox_CSVs);
        Arrays.sort(pose_CSVs);

        /* #################################################
        In the section below, we create a new ObjectSet, and iterate over each Keyframe
         ################################################## */
   
        if(dataset.equals("1")){
            intrinsics = new CameraIntrinsics("src/main/java/vslam/tum_rgbd/CameraIntrinsics.csv");
            pointCloud = Downsampler.get_voxels("src/main/java/vslam/tum_rgbd/pointcloud.csv", 0.05F);
        } else if(dataset.equals("2")){
            intrinsics = new CameraIntrinsics("src/main/java/vslam/imperial_london/CameraIntrinsicsTUM.csv");
            pointCloud = Downsampler.get_voxels("src/main/java/vslam/imperial_london/pointcloudTUM.csv", 0.05F);
        }

        ObjectSet os = new ObjectSet(intrinsics, pointCloud);

        // iterate through each frame, create the frame, then process it
        for(int i = 0; i < pose_CSVs.length; i++){
            CameraPose cp = new CameraPose(pose_CSVs[i].getPath());
            Frame f = new Frame(bbox_CSVs[i].getPath(), cp);
            os.processFrame(f);
            System.out.println("Processed frame " + i);
        }

        // update MongoDB
        MongoDBInteraction mdbi = new MongoDBInteraction();
        mdbi.updateObjectSet(7, os);
    }

    /**
     * A helper function used to pull all files out of a directory path
     * @param dir_pth
     * @return
     */
    public static File[] getDirFiles(String dir_pth){
        File[] f_arr;
        // get the csv files of each frame
        try {
            f_arr = new File(dir_pth).listFiles();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        // some error checking
        if(f_arr == null || f_arr.length == 0){
            System.err.println("ERROR: no feature csvs found at given path");
        }

        return f_arr;
    }

    public static void main(String[] args) throws IOException, CsvValidationException {
        startProcess("1");
    }

}
