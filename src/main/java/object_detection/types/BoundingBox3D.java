package object_detection.types;

public class BoundingBox3D {


    /**
     * This class represents a single object in 3D space, and holds the points that fall within it, and its bounds
     * @param ps : the first pointset used to
     */
    public BoundingBox3D(PointSet ps){
        this.ps = ps;
    }


    /* ###################
        Members
    ##################### */
    private PointSet ps;
}
