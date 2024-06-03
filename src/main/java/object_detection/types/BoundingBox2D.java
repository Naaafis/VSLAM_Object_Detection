package object_detection.types;

public class BoundingBox2D {

    public BoundingBox2D(int x, int y, int w, int h, String predName) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.predClass = predName;
    }

    public boolean within(Point2D p){
        return p.getX() <= (this.x + this.w)
                && p.getX() >= this.x
                && p.getY() >= this.y
                && p.getY() <= (this.y + this.h);
    }


    // members
    int x;
    int y;
    int w;
    int h;
    String predClass;

    @Override
    public String toString(){
        return "Bounding box: " + predClass;
    }
}
