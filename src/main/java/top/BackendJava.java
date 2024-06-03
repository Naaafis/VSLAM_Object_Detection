package top;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.opencsv.exceptions.CsvValidationException;
import database.MongoDBInteraction;
import object_detection.ObjectDetector;
import object_detection.types.ObjectSet;
import object_detection.types.Point;
import object_detection.types.PointSet;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.*;

@SpringBootApplication
public class BackendJava {

    public static void main(String[] args) {
        SpringApplication.run(BackendJava.class, args);
    }

    @RestController
    @RequestMapping("/api")
    public static class ObjectSetController {

        private final MongoDBInteraction dbInteraction = new MongoDBInteraction();
        private final Gson gson = new GsonBuilder().create();

        @GetMapping("/getObjects")
        public ResponseEntity<String> getObjects(@RequestParam String dataset) throws CsvValidationException, IOException {
            System.out.println("==========================");
            ObjectDetector.startProcess(dataset);
            System.out.println("==========================");
            try {
                ObjectSet objectSet = dbInteraction.retrieveLatestObjectSet();
                if (objectSet != null && objectSet.objects != null && !objectSet.objects.isEmpty()) {
                    List<Map<String, Object>> objectsList = new ArrayList<>();
                    for (PointSet ps : objectSet.objects) {
                        Map<String, Object> objData = new HashMap<>();
                        objData.put("id", ps.getIDX());
                        objData.put("predName", "Some Pred Name"); // Placeholder, adjust based on your application's data

                        List<Map<String, Object>> pointsList = new ArrayList<>();
                        for (Point p : ps.getPoints()) {
                            Map<String, Object> pointData = new HashMap<>();
                            pointData.put("x", p.getX());
                            pointData.put("y", p.getY());
                            pointData.put("z", p.getZ());
                            pointData.put("R", p.R);
                            pointData.put("G", p.G);
                            pointData.put("B", p.B);
                            pointsList.add(pointData);
                        }
                        objData.put("points", pointsList);
                        objectsList.add(objData);
                    }
                    Map<String, Object> finalResult = new HashMap<>();
                    finalResult.put("objects", objectsList);
                    return ResponseEntity.ok(gson.toJson(finalResult));
                } else {
                    return ResponseEntity.notFound().build();
                }
            } catch (Exception e) {
                return ResponseEntity.internalServerError().body("{\"error\":\"Failed to retrieve all objects: " + e.getMessage() + "\"}");
            }
        }
    }

    @Controller
    public static class BackendService {

        private final MongoDBInteraction dbInteraction = new MongoDBInteraction();
        private final Gson gson = new GsonBuilder().create();

        @RequestMapping("/")
        public String index() {
            return "html/index";
        }

        // @RequestMapping("/runProcess")
        // @ResponseBody
        // public boolean runProcess() throws IOException, CsvValidationException {
        //     System.out.println(" ============> Starting process");
        //     ObjectDetector.startProcess();
        //     return true;
        // }

        @RequestMapping("/getJSON")
        @ResponseBody
        public ResponseEntity<String> tempJson(@RequestParam String dataset) throws CsvValidationException, IOException {
            ObjectDetector.startProcess(dataset);
            try {
                ObjectSet latestObjectSet = dbInteraction.retrieveLatestObjectSet();

                Map<String, PointSet> result = new HashMap<>();
                for(PointSet p : latestObjectSet.objects){
                    result.put(Integer.toString(p.getIDX()), p);
                }

                if (!result.isEmpty()) {
                    return ResponseEntity.ok(gson.toJson(result));
                } else {
                    return ResponseEntity.notFound().build();
                }
            } catch (Exception e) {
                return ResponseEntity.internalServerError().body("{\"error\":\"Error retrieving latest object set: " + e.getMessage() + "\"}");
            }
        }

        @RequestMapping("/style/main.css")
        public String getStyle() {
            return "style/main.css";
        }

        @RequestMapping("/js/buildPC.js")
        public String getBuild() {
            return "js/buildPC.js";
        }
    }

    @Configuration
    @EnableWebMvc
    public static class WebMvcConfig implements WebMvcConfigurer {
        @Override
        public void addCorsMappings(CorsRegistry registry) {
            registry.addMapping("/**").allowedOrigins("http://localhost:5555");
        }
    }
}
