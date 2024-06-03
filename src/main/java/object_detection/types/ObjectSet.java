package object_detection.types;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.*;

public class ObjectSet {

    public ObjectSet(CameraIntrinsics intrinsics, List<Point> pointCloud){
        this.objects = new ArrayList<>();
        this.intrinsics = intrinsics;
        this.pointCloud = pointCloud;
    }

    public ObjectSet(){
        this.objects = new ArrayList<>();
        this.intrinsics = null;
        this.pointCloud = null;
    }

    /**
     * Given a single frame that has a camera pose and a list of bounding boxes, get all new objects based on projections
     * from PointCloud to the current screen, using the bounding boxes as a way to group the points
     * @param f : current frame
     */
    public void processFrame(Frame f){
        // 1) Get pointCloud projections onto current frame
        assert this.pointCloud != null;
        assert this.intrinsics != null;
        Map<Integer, Point2D> projM = f.projectPoints(this.pointCloud, this.intrinsics);

        // 2) Create a bitmap that holds the index of the bounding box that contains the pixel at bitmap[i][j]
        int[][] bitmap = new int[(int) intrinsics.ImageSize[0]][(int) intrinsics.ImageSize[1]];

        for(int b = 0; b < f.boxes.size(); b++){
            BoundingBox2D bbox = f.boxes.get(b);
            // for each box, write to all points in bitmap that fall in box
            for(int i = bbox.x; i >= 0 && i < bbox.x+bbox.w && i < bitmap[0].length; i++){
                for(int j = bbox.y; j >= 0 && j < bbox.y+bbox.h && j < bitmap.length; j++){
                    bitmap[j][i] = (b+1); // reserve 0 for uncategorized, so shift idx by 1
                }
            }
        }

        // 3) Find all points that fall within each box, add point to candidate objects
        List<PointSet> candidates = new ArrayList<>();
        for(int i = 0; i < f.boxes.size(); i++){
            candidates.add(new PointSet(i));
        }

        for(Map.Entry<Integer, Point2D> entry : projM.entrySet()){
            int idx = bitmap[(int) entry.getValue().getY()][(int) entry.getValue().getX()];
            if(idx > 0){
                // if the point falls within a specific bounding box, add its 3D counterpart to the corresponding candidate object
                candidates.get(idx-1).addPoint(this.pointCloud.get(entry.getKey()));
            }
        }

        // 4) Now that we have a full list of candidate objects, we can do object resolution by combining candidates with overlapping points
        for(PointSet c : candidates){
            if(c.pset.size() > 2){
                this.reconcileCandidate(c, 0.7);
            }
        }

    }

    /**
     * Given a candidate object, find possible similar objects, then perform intersections
     * @param c : a single candidate object
     */
    public void reconcileCandidate(PointSet c, double threshold){
        for (PointSet obj : this.objects) {
            // calculate overlapping points, if beyond some threshold, find intersection of the sets
            int count = 0;
            for (Point p : obj.pset) {
                if(c.pset.contains(p)){
                    count++;
                }
            }

            if (count > (c.pset.size() * threshold)) {
                //combine via intersection and return, since we know that we just combined those objects
                obj.pset.retainAll(c.pset);
                return;
            }
        }

        // if we have not combined with any object yet, just add PointSet to objects
        this.objects.add(c);
    }



    @Override
    public String toString(){
        return "ObjectSet of : " + this.objects.size() + " objects:";
    }


    /* ##########################
        Members
    ############################# */
    public List<PointSet> objects;
    final private CameraIntrinsics intrinsics;
    private final List<Point> pointCloud;
}