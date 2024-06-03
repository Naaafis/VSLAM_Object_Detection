package object_detection;


import com.opencsv.CSVParser;
import com.opencsv.CSVParserBuilder;
import com.opencsv.CSVReader;
import com.opencsv.CSVReaderBuilder;
import com.opencsv.exceptions.CsvValidationException;
import object_detection.types.Point;

import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Downsampler {

    /**
     * This function uses a voxel downsampling algorithm to take a dense pointcloud, and convert it to a voxel map of the world
     * @param pathname : path to the CSV file holding the xyz information
     * @param voxel_size : size of voxels (larger means less dense voxel map)
     * @return : an arraylist of points, this is the downsampled total
     * @throws IOException
     * @throws CsvValidationException
     */
    public static ArrayList<Point> get_voxels(String pathname, float voxel_size) throws IOException, CsvValidationException {

        // build CSVReader
        CSVParser csvParser = new CSVParserBuilder()
                .withSeparator(',')
                .withIgnoreQuotations(true)
                .build();

        CSVReader csvReader = new CSVReaderBuilder(new FileReader(pathname))
                .withCSVParser(csvParser)
                .build();

        // read CSV into float[][], just to build initial pointcloud
        // also, keep track of min/max of pointcloud
        List<double[]> allPoints = new ArrayList<>();
        double xmin = 999999; double xmax = -999999;
        double ymin = 999999; double ymax = -999999;
        double zmin = 999999; double zmax = -999999;

        String[] nextLine;
        while ((nextLine = csvReader.readNext()) != null) {
            double[] point = new double[6];
            point[0] = Double.parseDouble(nextLine[0]);
            point[1] = Double.parseDouble(nextLine[1]);
            point[2] = Double.parseDouble(nextLine[2]);
            point[3] = Double.parseDouble(nextLine[3]);
            point[4] = Double.parseDouble(nextLine[4]);
            point[5] = Double.parseDouble(nextLine[5]);

            allPoints.add(point);

            xmin = Math.min(xmin, point[0]);
            xmax = Math.max(xmax, point[0]);
            ymin = Math.min(ymin, point[1]);
            ymax = Math.max(ymax, point[1]);
            zmin = Math.min(zmin, point[2]);
            zmax = Math.max(zmax, point[2]);
        }

        System.out.println(" > ----------------------------");
        System.out.println("Starting with: " + allPoints.size() + " points");

        // create voxel matrix
        int num_vox_x = (int) Math.ceil(Math.abs(xmax - xmin) / voxel_size);
        int num_vox_y = (int) Math.ceil(Math.abs(ymax - ymin) / voxel_size);
        int num_vox_z = (int) Math.ceil(Math.abs(zmax - zmin) / voxel_size);

        // voxel = bucket, given 3 coordinates
        double[][][][] voxels = new double[num_vox_x][num_vox_y][num_vox_z][6];
        int[][][] count = new int[num_vox_x][num_vox_y][num_vox_z];

        // create shifts in points

        // put each point into a bucket (by summing)
        for(double[] point : allPoints){
            int x_floor = (int) Math.round(Math.floor((point[0] - xmin)/voxel_size));
            int y_floor = (int) Math.round(Math.floor((point[1] - ymin)/voxel_size));
            int z_floor = (int) Math.round(Math.floor((point[2] - zmin)/voxel_size));

            // increment count
            count[x_floor][y_floor][z_floor] += 1;
            // add point to sum
            voxels[x_floor][y_floor][z_floor][0] += point[0];
            voxels[x_floor][y_floor][z_floor][1] += point[1];
            voxels[x_floor][y_floor][z_floor][2] += point[2];
            voxels[x_floor][y_floor][z_floor][3] += point[3];
            voxels[x_floor][y_floor][z_floor][4] += point[4];
            voxels[x_floor][y_floor][z_floor][5] += point[5];
        }


        ArrayList<Point> res = new ArrayList<>();
        // average out voxels to get final pointcloud, and append to result if necessary
        for(int i = 0; i < num_vox_x; i++){
            for(int j = 0; j < num_vox_y; j++) {
                for (int k = 0; k < num_vox_z; k++) {
                    if (count[i][j][k] > 0) {
                        double x_avg = voxels[i][j][k][0] / count[i][j][k];
                        double y_avg = voxels[i][j][k][1] / count[i][j][k];
                        double z_avg = voxels[i][j][k][2] / count[i][j][k];
                        double r_avg = voxels[i][j][k][3] / count[i][j][k];
                        double g_avg = voxels[i][j][k][4] / count[i][j][k];
                        double b_avg = voxels[i][j][k][5] / count[i][j][k];
                        res.add(new Point((float) x_avg, (float) y_avg, (float) z_avg, (int) r_avg, (int) g_avg, (int) b_avg));
                    }
                }
            }
        }

        System.out.println("Downsampled to: " + res.size() + " points");
        System.out.println(" > ----------------------------");


        return res;
    }

    public static void main(String[] args) throws CsvValidationException, IOException {
        List<Point> result = Downsampler.get_voxels("src/main/java/vslam/pointcloud.csv", 0.05F);
    }
}
