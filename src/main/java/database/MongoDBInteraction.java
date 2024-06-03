package database;

import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.ServerApi;
import com.mongodb.ServerApiVersion;
import com.mongodb.client.*;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.ReplaceOptions;
import object_detection.types.ObjectSet;
import object_detection.types.Point;
import object_detection.types.PointSet;
import org.bson.Document;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MongoDBInteraction {

    private MongoClient mongoClient;
    private MongoDatabase database;
    private MongoCollection<Document> objectCollection;

    public MongoDBInteraction() {
        String uri = "mongodb+srv://Cluster03790:dlVzT2Z2bEh9@cluster03790.tk4cwyy.mongodb.net/myFirstDatabase?retryWrites=true";

        // Construct a ServerApi instance using the ServerApi.builder() method
        MongoClientSettings settings = MongoClientSettings.builder()
                .applyConnectionString(new ConnectionString(uri))
                .serverApi(ServerApi.builder().version(ServerApiVersion.V1).build())
                .build();

        this.mongoClient = MongoClients.create(settings);
        this.database = mongoClient.getDatabase("Objects");
        this.objectCollection = database.getCollection("objectSets");
    }


    /**
     * calls convertDocumentToObjectSet
     * @return
     */
    public ObjectSet retrieveLatestObjectSet() {
        try {
            Document doc = objectCollection.find().sort(new Document("index", -1)).first();
            if (doc == null) {
                return null;
            } else {
                return convertDocumentToObjectSet(doc);
            }
        } catch (Exception e) {
            System.out.println("Error retrieving document: " + e.getMessage());
            return null;
        }
    }

    private ObjectSet convertDocumentToObjectSet(Document doc) {
        if (doc == null) {
            return null;
        }

        List<Document> pointSetDocs = doc.getList("objectSets", Document.class);
        if (pointSetDocs == null || pointSetDocs.isEmpty()) {
            return new ObjectSet();
        }

        ObjectSet objectSet = new ObjectSet();
        for (Document pointSetDoc : pointSetDocs) {
            PointSet pointSet = convertDocumentToPointSet(pointSetDoc);
            if (pointSet != null) {
                objectSet.objects.add(pointSet);
            } else {
                System.out.println("Failed to convert point set document");
            }
        }
        return objectSet;
    }

    private PointSet convertDocumentToPointSet(Document doc) {
        if (doc == null) {
            return null;
        }

        // Using Integer.parseInt to safely convert String to Integer if necessary
        int idx;
        try {
            idx = doc.get("setId") instanceof Integer ? (Integer) doc.get("setId") : Integer.parseInt((String) doc.get("setId"));
        } catch (NumberFormatException e) {
            System.err.println("Invalid format for setId, must be an integer: " + doc.get("setId"));
            return null;
        }

        List<Document> pointsDocs = doc.getList("points", Document.class);
        if (pointsDocs == null) {
            return new PointSet(idx);
        }

        PointSet pointSet = new PointSet(idx);
        for (Document pointDoc : pointsDocs) {
            Point point = new Point(
                    pointDoc.getDouble("x").floatValue(),
                    pointDoc.getDouble("y").floatValue(),
                    pointDoc.getDouble("z").floatValue(),
                    pointDoc.getInteger("R"),
                    pointDoc.getInteger("G"),
                    pointDoc.getInteger("B")
                    );
            pointSet.addPoint(point);
        }
        return pointSet;
    }


    private Document pointSetToDocument(String setId, PointSet pointSet) {
        List<Document> pointsList = new ArrayList<>();
        for (Point p : pointSet.getPoints()) {
            pointsList.add(new Document("x", p.getX())
                    .append("y", p.getY())
                    .append("z", p.getZ())
                    .append("R", p.R)
                    .append("G", p.G)
                    .append("B", p.B));
        }
        return new Document("setId", setId)
                .append("points", pointsList);
    }

    private Document objectSetToDocument(int index, ObjectSet objectSet) {
        List<Document> objectList = new ArrayList<>();
        for (PointSet ps : objectSet.objects) {
            Document pointSetDoc = pointSetToDocument(Integer.toString(ps.getIDX()), ps);
            objectList.add(pointSetDoc);
        }
        return new Document("index", index)
                .append("objectSets", objectList);
    }

    public void updateObjectSet(int index, ObjectSet objectSet) {
        Document doc = objectSetToDocument(index, objectSet);
        ReplaceOptions options = new ReplaceOptions().upsert(true);
        objectCollection.replaceOne(Filters.eq("index", index), doc, options);
    }
}
