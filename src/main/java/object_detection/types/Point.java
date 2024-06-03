package object_detection.types;

public class Point {


    /* #################
        METHODS
     ################ */

    public Point(float xx, float yy, float zz){
        this.x = xx;
        this.y = yy;
        this.z = zz;
    }

    public Point(float xx, float yy, float zz, int r, int g, int b){
        this.x = xx;
        this.y = yy;
        this.z = zz;
        this.R = r;
        this.G = g;
        this.B = b;
    }

    /**
     * helper function for equals overriding
     * @param aa : first point
     * @param bb : second point
     * @param err : error between aa and bb that is acceptable
     * @return true if points are close enough
     */
    public static boolean equals(Point aa, Point bb, float err){
        return (Math.abs(aa.x - bb.x) < err) && (Math.abs(aa.y - bb.y) < err) && (Math.abs(aa.z - bb.z) < err);
    }

    @Override
    public boolean equals(Object o){
        if(getClass() != o.getClass()){
            return false;
        }
        Point p = (Point) o;
        return Point.equals(this, p, (float) 6);
    }

    @Override
    public int hashCode() {
        float res = this.x + this.y + this.z;
        return Float.hashCode(res);
    }
    @Override
    public String toString() {
        return "Point(" + this.x + " ," + this.y + " ," + this.z + ")";
    }

    public float getY() {
        return y;
    }

    public float getX() {
        return x;
    }

    public float getZ() {
        return z;
    }

    public int[] getColor(){
        return new int[]{this.R, this.G, this.B};
    }


    /* #################
        members
     ################ */

    // index
    static int count = 0;
    private float x;
    private float y;
    private float z;
    public int R;
    public int G;
    public int B;

}
