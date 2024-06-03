
# Entry into System

Things that are true:
1. A student should be able to build the system, then press run, then open a localhost and see the video and the point cloud of each object
2. A student should also be able to choose between different object and get information (need interactive display)
3. The entry needs to do the entire workflow
    - get keyframes and featurepoints
    - get objects from keyframes
    - start object detection
    - finish object detection and update database
    - ping GUI server
    - GUI server pulls information and displays point cloud to user

TODO: function to process each frame within the ObjectSet