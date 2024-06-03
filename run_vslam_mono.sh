#!/bin/bash

# Define the script that runs the VSLAM implementation
<<<<<<< HEAD
<<<<<<< HEAD
MATLAB_SCRIPT="/src/main/java/vslam/vslam_implementation_rgbd.m"

# Check if the correct number of arguments was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {tum_rgbd_dataset|imperial_college_london}"
    exit 1
fi

# Determine which dataset to use based on the argument provided
if [ "$1" = "tum_rgbd_dataset" ]; then
    DATASET_NAME="tum_rgbd_dataset"
elif [ "$1" = "imperial_college_london" ]; then
    DATASET_NAME="imperial_college_london"
else
    echo "Invalid dataset name. Choose either 'tum_rgbd_dataset' or 'imperial_college_london'"
    exit 2
fi
=======
MATLAB_SCRIPT="/src/main/java/vslam/vslam_implementation.m"

# Define the dataset name
DATASET_NAME="self_made_dataset"
>>>>>>> divider
=======
MATLAB_SCRIPT="/src/main/java/vslam/vslam_implementation.m"

# Define the dataset name
DATASET_NAME="self_made_dataset"
>>>>>>> 197296f30ca7b0c49c8308bf3194348f11ab6a30

# Navigate to the MATLAB script directory (assuming MATLAB can be called from command line)
cd src/main/java/vslam

# Run the MATLAB script with the dataset path
matlab -batch "vslam_implementation('${DATASET_NAME}')"

echo "VSLAM processing complete"

