

Input to System:
- pointcloud
- keyframes:
  - camera angles (x,y,z + angle ?)
  - 2D points captured
  - YOLO-captured bounding boxes

1) Take pointcloud, and downsample
2) For each frame:
  a. project downsampled pointcloud onto frame
  b. overlay 2D bounding boxes from YOLO
  c. create candidate objects based on points falling within boxes
  d. do overlap combinations based on thresholding voxels
3) Given final objectset, transmit corners to GUI
4) Display corners over original downsampled pointcloud to show objects


Output of System:
- pointcloud
- 3D bounding box of objects



Projecting 3D points onto 2D screen based on camera pose:
1) Calculate camera matrix = K * [R, t'] where R is rotation matrix, t is translation vector, and K is intrinsic of camera pose
2) Get projection by appling projPoints = [point, 1] * cameraMatrix' 
3) Divide projPoints[1:2] by projPoints[3] (i.e. divide x and y coordinates by z)
4) Return projPoints if z > 0 (infront of camera), or x,y fall into size of image (0-ImageSize.x, 0-ImageSize.y)