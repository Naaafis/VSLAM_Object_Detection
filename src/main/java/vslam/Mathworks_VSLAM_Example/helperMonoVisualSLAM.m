function [xyzPoint, camPoses] = helperMonoVisualSLAM(image)

%   Copyright 2023 The MathWorks Inc.

%#codegen

persistent vslam xyzPointsInternal camPosesInternal

if isempty(vslam)
    % Create a monovslam class to process the image data
    focalLength    = [535.4, 539.2];    % in units of pixels
    principalPoint = [320.1, 247.6];    % in units of pixels
    imageSize      = [480,     640];    % in units of pixels
    intrinsics     = cameraIntrinsics(focalLength, principalPoint, imageSize);

    vslam = monovslam(intrinsics);
end

% Process each image frame
addFrame(vslam, image);

% Get 3-D map points and camera poses
if isempty(xyzPointsInternal) || hasNewKeyFrame(vslam)
    xyzPointsInternal = mapPoints(vslam);
    camPosesInternal = poses(vslam);
end

xyzPoint = xyzPointsInternal;

% Convert camera poses to homogeneous transformation matrices
camPoses = cat(3, camPosesInternal.A);