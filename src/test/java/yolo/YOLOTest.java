package yolo;

import org.bytedeco.opencv.opencv_core.*;
import static org.bytedeco.opencv.global.opencv_imgcodecs.imwrite;
import static org.bytedeco.opencv.global.opencv_imgcodecs.imread;
import static org.bytedeco.opencv.global.opencv_imgproc.rectangle;
import static org.bytedeco.opencv.global.opencv_imgproc.LINE_8;

import java.util.List;
import java.io.File;
import java.io.IOException;
import java.io.FileWriter;

public class YOLOTest {
    private static YOLONet yoloNet;

    public static void main(String[] args) {
        String imagePath = "src/test/java/yolo/TestFrame.png";
        String outputDir = "src/test/java/yolo";
        String csvDir = "src/test/java/yolo";

        // Ensure output directories exist
        new File(outputDir).mkdirs();
        new File(csvDir).mkdirs();

        yoloNet = new YOLONet(
            "src/main/java/yolo/yolov4.cfg",
            "src/main/java/yolo/yolov4.weights",
            "src/main/java/yolo/coco.names",
                608, 608);

        if (!yoloNet.setup()) {
            System.err.println("Failed to setup YOLONet");
            return;
        }

        Mat image = imread(imagePath);
        if (image.empty()) {
            System.err.println("Image not found or unable to open.");
            return;
        }
        List<YOLONet.ObjectDetectionResult> results = yoloNet.predict(image);
        File csvFile = new File(csvDir, new File(imagePath).getName().replace(".png", ".csv"));

        try (FileWriter writer = new FileWriter(csvFile)) {
            writer.write("Class,Confidence,X,Y,Width,Height\n");

            for (YOLONet.ObjectDetectionResult result : results) {
                rectangle(image, new Point(result.x, result.y),
                          new Point(result.x + result.width, result.y + result.height),
                          Scalar.MAGENTA, 2, LINE_8, 0);
                writer.write(String.format("%s,%f,%d,%d,%d,%d\n",
                    result.className, result.confidence, result.x, result.y, result.width, result.height));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        String outputPathString = new File(outputDir, new File(imagePath).getName()).toString();
        imwrite(outputPathString, image);
        System.out.println("Processed and saved: " + outputPathString);
    }
}
