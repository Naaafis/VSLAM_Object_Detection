#!/bin/bash

# Define the target directory for dataset installation
TARGET_DIR="/src/main/java/vslam"

# Check for correct usage
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {TUM_RGB|EuRoC_Mav}"
    exit 1
fi

# Setup dataset URLs and filenames based on the argument
if [ "$1" = "TUM_RGB" ]; then
    URL="https://cvg.cit.tum.de/rgbd/dataset/freiburg3/rgbd_dataset_freiburg3_long_office_household.tgz"
    FILENAME="rgbd_dataset_freiburg3_long_office_household.tgz"
elif [ "$1" = "EuRoC_Mav" ]; then
    URL="http://robotics.ethz.ch/~asl-datasets/ijrr_euroc_mav_dataset/machine_hall/MH_01_easy/MH_01_easy.zip"
    FILENAME="MH_01_easy.zip"
else
    echo "Invalid dataset name. Choose either TUM_RGB or EuRoC_Mav."
    exit 2
fi

# Create target directory if it does not exist
mkdir -p $TARGET_DIR

# Change to the target directory
cd $TARGET_DIR

# Download the dataset
echo "Downloading $FILENAME ..."
wget $URL -O $FILENAME

# Extract the dataset
echo "Extracting $FILENAME ..."
if [[ $FILENAME == *.tgz ]]; then
    tar -xzvf $FILENAME
elif [[ $FILENAME == *.zip ]]; then
    unzip $FILENAME
fi

# Remove the compressed file after extraction
rm $FILENAME

echo "Installation and extraction complete!"

