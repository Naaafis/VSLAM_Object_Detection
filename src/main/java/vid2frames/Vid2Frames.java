package vid2frames;

import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class Vid2Frames {
    public static void main(String[] args) {
        String videoFilePath = "src/main/java/vid2frames/input_video.mov";
        String outputDirPath = "src/main/java/vid2frames/frames";

        File outputDir = new File(outputDirPath);
        if (!outputDir.exists()) {
            outputDir.mkdirs();
        }

        extractFrames(videoFilePath, outputDirPath);
    }

    private static void extractFrames(String videoFilePath, String outputDirPath) {
        try (FFmpegFrameGrabber frameGrabber = new FFmpegFrameGrabber(videoFilePath)) {
            frameGrabber.start();

            Java2DFrameConverter converter = new Java2DFrameConverter();
            Frame frame;
            int frameNumber = 0;

            // Frame rate of the video file
            double frameRate = frameGrabber.getFrameRate();
            // Interval to capture the frame (every 0.2 seconds for 5 frames per second)
            int frameInterval = (int) Math.round(frameRate / 5);
            int savedFrameNumber = 0; // Number of frames actually saved

            while ((frame = frameGrabber.grabFrame()) != null) {
                if (frame.image != null) {
                    if (frameNumber % frameInterval == 0) {
                        BufferedImage bi = converter.convert(frame);
                        String path = String.format("%s/frame_%d.png", outputDirPath, frameNumber);
                        ImageIO.write(bi, "png", new File(path));
                        System.out.println("Saved: " + path);
                        savedFrameNumber++;
                    }
                    frameNumber++;
                }
            }

            frameGrabber.stop();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
