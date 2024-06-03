
## Notes

Notes from Rohan:
- could use MATLAB coder to move MATLAB code to C/C++ code
    - not sure if this is possible for Java code as well
    - Prof. mentioned wanting Java code s.t. other students can read and critique codebase
- use MATLAB functions, create new MATLAB objects for data structures / database system
- dataset used by MATLAB example: https://cvg.cit.tum.de/data/datasets/rgbd-dataset 


#### Performing VSLAM using online dataset 

- Open up MATLAB console
- Install necessary Mathworks Library: Vision, Visual SLAM (users will be queried to download necessary packages)
- In MATLAB console, set imagesPath to 'rgbd_dataset_freiburg3_long_office_household/rgb'
- Run the vslam_implementation.m script with the imagesPath as input
- Use output of worldPointSet for figuring out which key features belong to which objects
