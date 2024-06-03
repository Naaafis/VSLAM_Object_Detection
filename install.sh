#!/bin/bash

# Download Apache Maven
echo "Downloading Maven..."
wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# Extract the downloaded tarball
echo "Extracting Maven..."
tar -xvf apache-maven-3.9.6-bin.tar.gz

# Move Maven to the target directory
echo "Moving Maven to /tmp/"
mv apache-maven-3.9.6 /tmp/

# Set M2_HOME and update PATH
M2_HOME="/tmp/apache-maven-3.9.6"
PATH_UPDATE="/tmp/apache-maven-3.9.6/bin:\$PATH"

# Remove tarball file
rm -rf apache-maven-3.9.6-bin.tar.gz

echo "Installation complete."

# Append M2_HOME and PATH to the user's .bashrc (or other appropriate file)
echo "Updating environment variables..."
echo "export M2_HOME=$M2_HOME" >> ~/.bashrc
echo "export PATH=$PATH_UPDATE" >> ~/.bashrc

# Optional: Automatically source Java upgrade script
echo "source /ad/eng/opt/java/add_jdk17.sh" >> ~/.bashrc

echo "Please close and reopen your terminal or run 'source ~/.bashrc' to apply all changes."
echo "Please verify Java version with 'java -version'"
echo "Please verify the Maven installation with: 'mvn -version'"

