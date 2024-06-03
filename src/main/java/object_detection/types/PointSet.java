package object_detection.types;

import object_detection.types.Point;

import java.util.*;

public class PointSet {

    static final int NUM_REPS = 10;
    Set<Point> pset;
    Point[] reps;

    Point centroid;

    final int IDX;

    /**
     *
     * @param pp : the points that this PointSet will contain
     */
    public PointSet(int id, Point ...pp){
        pset = new HashSet<>();

        // add every point blankly to pointset
        pset.addAll(Arrays.asList(pp));
        centroid = new Point(0,0,0);
        reps = new Point[NUM_REPS];
        IDX = id;
    }

    public void addPoint(Point p){
        pset.add(p);
    }

    public void addAll(Point ...p) {
        Collections.addAll(pset, p);
    }

    public void addAll(List<Point> p) {
        pset.addAll(p);
    }

    public Point[] getSetReps(){
        return this.reps;
    }

    /*
     * This method is used to get the points in the PointSet
     */
    public Point[] getPoints(){
        Iterator<Point> iter = this.pset.iterator();
        Point[] res = new Point[this.pset.size()];

        for(int i = 0; i < this.pset.size(); i++){
            res[i] = iter.next();
        }

        return res;
    }

    /**
     * This method is called on a specific Point, and updates the Point via
     * some disjoint sets' method.
     */
    public void updateReps(){
        // get first NUM_REPS from pset for now, will make more efficient later
        Iterator<Point> iter = this.pset.iterator();
        for(int i = 0; i < NUM_REPS; i++){

            // early exit if we have less than NUM_REPS points in the current object
            if(i == this.pset.size()) {
                return;
            }

            reps[i] = iter.next();
        }
    }

    public int getIDX() {
        return this.IDX;
    }
}
