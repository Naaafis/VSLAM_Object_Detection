# Group8: Optimized Monocular VSLAM

## Using Maven

Maven is a tool to build and run Java projects. For this project we are using it to automate the process of installing dependencies and compiling the system.

The file named pom.xml in the main directory controls how maven builds the project on each run, and also holds dependencies. The most important fields are `properties`, which holds the information about JDK and execution, and `dependencies`, which holds information on external sources needed to compile the project. 

On each run, Maven will run test cases and compile into the target directory of the project. 

### Installation

For Mac you can just use `brew install maven`.

### Usage 

In the pom.xml file, under properties, we can add a line like the following:

`<exec.mainClass>object_detection.ObjectDetector</exec.mainClass>`

What this says is that when we call `mvn exec:java`, we search under src/java and execute the `main` method of the `ObjectDetector.java` class file. In this way we can test out any main method that we want.

The best way to use this in Intellij is by creating a build configuration using the following steps:
1. In the top right, find the dropdown of the `Run` options. (this should be the left of the play button and the debug button)
2. Press `Edit Configurations...`
3. Press `Add new configuration`
4. Find the maven icon and create this build config.
5. Give the config a name, and then under `Run`, add `clean compile exec:java`, which does each command in succession.

### Resources

- https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html
- https://maven.apache.org/run-maven/index.html 

## Working on this project:
- when creating a new branch, go into the Issues tab, click on the Issue you are working on, and create a branch off of that issue
- only change things in that branch, and then when finished we can all push into master
- within the group8 directory, create a subdirectory like:
  - group8/gui
  - group8/database
  - etc
- do your work within these subdirectories so we don't have issues resolving changes at the end


## Working with YOLO at current state

Install dependencies 

`mvn clean install -DskipTests`

Run program

`mvn exec:java`

