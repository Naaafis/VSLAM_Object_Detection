package yolo;

import org.bytedeco.javacpp.FloatPointer;
import org.bytedeco.javacpp.IntPointer;
import org.bytedeco.javacpp.indexer.FloatIndexer;
import org.bytedeco.opencv.global.opencv_dnn;
import org.bytedeco.opencv.opencv_core.*;
import org.bytedeco.opencv.opencv_dnn.Net;
import org.bytedeco.opencv.opencv_text.FloatVector;
import org.bytedeco.opencv.opencv_text.IntVector;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

import static org.bytedeco.opencv.global.opencv_core.CV_32F;
import static org.bytedeco.opencv.global.opencv_core.getCudaEnabledDeviceCount;
import static org.bytedeco.opencv.global.opencv_dnn.*;
import static org.bytedeco.opencv.global.opencv_imgproc.rectangle;

public class YOLONet {
    private Path configPath;
    private Path weightsPath;
    private Path namesPath;
    private int width;
    private int height;

    private float confidenceThreshold = 0.5f;
    private float nmsThreshold = 0.4f;

    private Net net;
    private StringVector outNames;

    private List<String> names;

    public YOLONet(String configPath, String weightsPath, String namesPath, int width, int height) {
        this.configPath = Paths.get(configPath);
        this.weightsPath = Paths.get(weightsPath);
        this.namesPath = Paths.get(namesPath);
        this.width = width;
        this.height = height;
    }

    public boolean setup() {
        net = readNetFromDarknet(configPath.toAbsolutePath().toString(), weightsPath.toAbsolutePath().toString());
        outNames = net.getUnconnectedOutLayersNames();
        if (getCudaEnabledDeviceCount() > 0) {
            net.setPreferableBackend(DNN_BACKEND_CUDA);
            net.setPreferableTarget(DNN_TARGET_CUDA);
        }

        try {
            names = Files.readAllLines(namesPath);
        } catch (IOException e) {
            System.err.println("Could not read names file!");
            e.printStackTrace();
            return false;
        }

        return !net.empty();
    }

    public List<ObjectDetectionResult> predict(Mat frame) {
        Mat inputBlob = blobFromImage(frame, 1 / 255.0, new Size(width, height), new Scalar(0.0), true, false, CV_32F);
        net.setInput(inputBlob);
        MatVector outs = new MatVector(outNames.size());
        net.forward(outs, outNames);
        return postprocess(frame, outs);
    }

    private List<ObjectDetectionResult> postprocess(Mat frame, MatVector outs) {
        IntVector classIds = new IntVector();
        FloatVector confidences = new FloatVector();
        RectVector boxes = new RectVector();
    
        for (int i = 0; i < outs.size(); i++) {
            Mat result = outs.get(i);
            FloatIndexer data = result.createIndexer();
    
            for (int j = 0; j < result.rows(); j++) {
                int centerX = (int) (data.get(j, 0) * frame.cols());
                int centerY = (int) (data.get(j, 1) * frame.rows());
                int width = (int) (data.get(j, 2) * frame.cols());
                int height = (int) (data.get(j, 3) * frame.rows());
                int left = centerX - width / 2;
                int top = centerY - height / 2;
    
                float confidence = data.get(j, 4); // Assuming the confidence score is at index 4
    
                if (confidence > confidenceThreshold) {
                    // Find the class with the highest score
                    float maxClassScore = -1;
                    int classIndex = -1;
                    for (int k = 5; k < data.cols(); k++) { // Assuming class probabilities start from index 5
                        float score = data.get(j, k);
                        if (score > maxClassScore) {
                            maxClassScore = score;
                            classIndex = k - 5; // Adjust index to get the correct class index
                        }
                    }
    
                    if (maxClassScore > confidenceThreshold) { // Check if the maximum class score is also above the threshold
                        classIds.push_back(classIndex);
                        confidences.push_back(maxClassScore);
                        boxes.push_back(new Rect(left, top, width, height));
                    }
                }
            }
        }
    
        // Apply non-maxima suppression
        IntPointer indices = new IntPointer(confidences.size());
        FloatPointer confidencesPointer = new FloatPointer(confidences.size());
        confidencesPointer.put(confidences.get());
    
        NMSBoxes(boxes, confidencesPointer, confidenceThreshold, nmsThreshold, indices, 1.0f, 0);
    
        List<ObjectDetectionResult> detections = new ArrayList<>();
        for (int i = 0; i < indices.limit(); i++) {
            int idx = indices.get(i);
            Rect box = boxes.get(idx);
            ObjectDetectionResult result = new ObjectDetectionResult();
            result.classId = classIds.get(idx);
            result.className = names.get(result.classId);
            result.confidence = confidences.get(idx);
            result.x = box.x();
            result.y = box.y();
            result.width = box.width();
            result.height = box.height();
            detections.add(result);
        }
    
        // Clean up
        // indices.release();
        // confidencesPointer.release();
        // classIds.release();
        // confidences.release();
        // boxes.release();
    
        return detections;
    }
    

    public static class ObjectDetectionResult {
        public int classId;
        public String className;
        public float confidence;
        public int x;
        public int y;
        public int width;
        public int height;
    }
}
