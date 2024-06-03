package yolo;

import org.bytedeco.opencv.opencv_core.*;
import static org.bytedeco.opencv.global.opencv_imgcodecs.imwrite;
import static org.bytedeco.opencv.global.opencv_imgcodecs.imread;
import static org.bytedeco.opencv.global.opencv_imgproc.rectangle;
import static org.bytedeco.opencv.global.opencv_imgproc.LINE_8;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class YOLODetector {
    private static YOLONet yoloNet;

    public static void main(String[] args) {
        String keyFramesDir = "src/main/java/vslam/KeyFrames";
        String outputDir = "src/main/java/vslam/BoundedKeyFrames";
        String csvDir = "src/main/java/vslam/BoundedInfo";
        Path outputPath = Paths.get(outputDir);
        Path csvPath = Paths.get(csvDir);

        // Ensure output directories exist
        try {
            Files.createDirectories(outputPath);
            Files.createDirectories(csvPath);
        } catch (Exception e) {
            e.printStackTrace();
            return;
        }

        yoloNet = new YOLONet(
                "src/main/java/yolo/yolov4.cfg",
                "src/main/java/yolo/yolov4.weights",
                "src/main/java/yolo/coco.names",
                608, 608);

        if (!yoloNet.setup()) {
            System.err.println("Failed to setup YOLONet");
            return;
        }

        long totalStartTime = System.nanoTime();
        try (Stream<Path> paths = Files.walk(Paths.get(keyFramesDir))) {
            List<String> files = paths.filter(Files::isRegularFile)
                                      .map(Path::toString)
                                      .collect(Collectors.toList());

            int totalFrames = files.size();
            long totalFrameTime = 0;

            for (String file : files) {
                long startTime = System.nanoTime();
                Mat image = imread(file);
                List<YOLONet.ObjectDetectionResult> results = yoloNet.predict(image);
                long endTime = System.nanoTime();
                long duration = (endTime - startTime) / 1_000_000; // Convert to milliseconds

                totalFrameTime += duration;
                System.out.println("Processed " + file + " in " + duration + " ms.");

                File csvFile = new File(csvPath + "/" + new File(file).getName().replace(".png", ".csv"));
                try (FileWriter writer = new FileWriter(csvFile)) {
                    writer.write("Class,Confidence,X,Y,Width,Height\n");
                    for (YOLONet.ObjectDetectionResult result : results) {
                        rectangle(image, new Point(result.x, result.y),
                                  new Point(result.x + result.width, result.y + result.height),
                                  Scalar.MAGENTA, 2, LINE_8, 0);
                        writer.write(String.format("%s,%f,%d,%d,%d,%d\n", 
                            result.className, result.confidence, result.x, result.y, result.width, result.height));
                    }
                }
                imwrite(outputDir + "/" + new File(file).getName(), image);
            }

            long totalEndTime = System.nanoTime();
            long totalDuration = (totalEndTime - totalStartTime) / 1_000_000;
            System.out.println("Total processing time: " + totalDuration + " ms for " + totalFrames + " frames.");
            System.out.println("Average time per frame: " + (totalFrameTime / totalFrames) + " ms.");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
