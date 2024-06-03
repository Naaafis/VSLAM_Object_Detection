#!/bin/bash

# Define the POM file location
POM_FILE="pom.xml"

# Function to modify the POM file to use YOLODetector
use_yolo_detector() {
    # Backup the original POM file
    cp $POM_FILE "${POM_FILE}.bak"

    # Replace the main class to use YOLODetector
    sed -i 's\<exec.mainClass>top.BackendJava</exec.mainClass>\<exec.mainClass>yolo.YOLODetector</exec.mainClass>\g' $POM_FILE

}

# Function to restore the original POM file
restore_original_pom() {
    # Restore the original POM file from backup
    mv "${POM_FILE}.bak" $POM_FILE
}

# Use YOLODetector for object detection
use_yolo_detector

# Run Maven commands to clean, build, and execute the project
mvn clean install -DskipTests
mvn exec:java

# Restore the original POM configuration
restore_original_pom

echo "Object detection has completed. The POM file has been restored to its original configuration."
