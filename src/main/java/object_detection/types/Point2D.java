package object_detection.types;

public class Point2D {

    private float x;
    private float y;

    public Point2D(float x, float y){
        this.x = x;
        this.y = y;
    }

    public float getY() {
        return y;
    }

    public float getX() {
        return x;
    }

    @Override
    public String toString(){
        return "{"+ x + ", " + y + "}";
    }
}
