function vslam_implementation(dataset_name)
    % Import dependencies
    addpath('./Mathworks_VSLAM_Example/');

    % Define the base folder for datasets
    datasetFolder = [dataset_name, '/'];

    imageFolder = [datasetFolder, 'images/'];
    imds = imageDatastore(imageFolder);

    % Process the image sequence
    [worldPointSetOutput] = ProcessImageSequence(imds);

    % Save the outputs to .mat files
    save('worldPointSetOutput.mat', 'worldPointSetOutput');

    % Iterate over KeyFrames and execute extractPointsByViewId
    keyFramesDir = './KeyFrames';
    keyFrameFiles = dir(fullfile(keyFramesDir, 'KeyFrame_*.png'));

    for i = 1:length(keyFrameFiles)
        filename = keyFrameFiles(i).name;
        viewId = str2double(regexp(filename, '\d+', 'match', 'once')); % Extracting the numeric part from filename
        extractPointsByViewId(viewId, worldPointSetOutput);
    end
end



function worldPointSetOutput = ProcessImageSequence(imds)
    currFrameIdx = 1;
    currI = readimage(imds, currFrameIdx);

    %% Map Initilization
    % Set random seed for reproducibility
    rng(0);
    
    % Create a cameraIntrinsics object to store the camera intrinsic parameters.
    % The intrinsics for the dataset can be found at the following page:
    % https://vision.in.tum.de/data/datasets/rgbd-dataset/file_formats
    % Note that the images in the dataset are already undistorted, hence there
    % is no need to specify the distortion coefficients.
    focalLength    = [535.4, 539.2];    % in units of pixels
    principalPoint = [320.1, 247.6];    % in units of pixels
    imageSize      = size(currI,[1 2]);  % in units of pixels
    intrinsics     = cameraIntrinsics(focalLength, principalPoint, imageSize);
    
    % Detect and extract ORB features
    scaleFactor = 1.2;
    numLevels   = 8;
    numPoints   = 1000;
    [preFeatures, prePoints] = helperDetectAndExtractFeatures(currI, scaleFactor, numLevels, numPoints); 
    
    currFrameIdx = currFrameIdx + 1;
    firstI       = currI; % Preserve the first frame 
    
    isMapInitialized  = false;
    
    % Map initialization loop
    while ~isMapInitialized && currFrameIdx < numel(imds.Files)
        currI = readimage(imds, currFrameIdx);
    
        [currFeatures, currPoints] = helperDetectAndExtractFeatures(currI, scaleFactor, numLevels, numPoints); 
    
        currFrameIdx = currFrameIdx + 1;
    
        % Find putative feature matches
        indexPairs = matchFeatures(preFeatures, currFeatures, Unique=true, ...
            MaxRatio=0.9, MatchThreshold=40);
    
        preMatchedPoints  = prePoints(indexPairs(:,1),:);
        currMatchedPoints = currPoints(indexPairs(:,2),:);
    
        % If not enough matches are found, check the next frame
        minMatches = 100;
        if size(indexPairs, 1) < minMatches
            continue
        end
    
        preMatchedPoints  = prePoints(indexPairs(:,1),:);
        currMatchedPoints = currPoints(indexPairs(:,2),:);
    
        % Compute homography and evaluate reconstruction
        [tformH, scoreH, inliersIdxH] = helperComputeHomography(preMatchedPoints, currMatchedPoints);
    
        % Compute fundamental matrix and evaluate reconstruction
        [tformF, scoreF, inliersIdxF] = helperComputeFundamentalMatrix(preMatchedPoints, currMatchedPoints);
    
        % Select the model based on a heuristic
        ratio = scoreH/(scoreH + scoreF);
        ratioThreshold = 0.45;
        if ratio > ratioThreshold
            inlierTformIdx = inliersIdxH;
            tform          = tformH;
        else
            inlierTformIdx = inliersIdxF;
            tform          = tformF;
        end
    
        % Computes the camera location up to scale. Use half of the 
        % points to reduce computation
        inlierPrePoints  = preMatchedPoints(inlierTformIdx);
        inlierCurrPoints = currMatchedPoints(inlierTformIdx);
        [relPose, validFraction] = estrelpose(tform, intrinsics, ...
            inlierPrePoints(1:2:end), inlierCurrPoints(1:2:end));
    
        % If not enough inliers are found, move to the next frame
        if validFraction < 0.9 || numel(relPose)==3
            continue
        end
    
        % Triangulate two views to obtain 3-D map points
        minParallax = 1; % In degrees
        [isValid, xyzWorldPoints, inlierTriangulationIdx] = helperTriangulateTwoFrames(...
            rigidtform3d, relPose, inlierPrePoints, inlierCurrPoints, intrinsics, minParallax);
    
        if ~isValid
            continue
        end
    
        % Get the original index of features in the two key frames
        indexPairs = indexPairs(inlierTformIdx(inlierTriangulationIdx),:);
    
        isMapInitialized = true;
    
        disp(['Map initialized with frame 1 and frame ', num2str(currFrameIdx-1)])
    end % End of map initialization loop

    %% Store initial key frames and map points
    % Create an empty imageviewset object to store key frames
    vSetKeyFrames = imageviewset;
    
    % Create an empty worldpointset object to store 3-D map points
    mapPointSet   = worldpointset;
    
    % Add the first key frame. Place the camera associated with the first 
    % key frame at the origin, oriented along the Z-axis
    preViewId     = 1;
    vSetKeyFrames = addView(vSetKeyFrames, preViewId, rigidtform3d, Points=prePoints,...
        Features=preFeatures.Features);
    
    % Add the second key frame
    currViewId    = 2;
    vSetKeyFrames = addView(vSetKeyFrames, currViewId, relPose, Points=currPoints,...
        Features=currFeatures.Features);
    
    % Add connection between the first and the second key frame
    vSetKeyFrames = addConnection(vSetKeyFrames, preViewId, currViewId, relPose, Matches=indexPairs);
    
    % Add 3-D map points
    [mapPointSet, newPointIdx] = addWorldPoints(mapPointSet, xyzWorldPoints);
    
    % Add observations of the map points
    preLocations  = prePoints.Location;
    currLocations = currPoints.Location;
    preScales     = prePoints.Scale;
    currScales    = currPoints.Scale;
    
    % Add image points corresponding to the map points in the first key frame
    mapPointSet   = addCorrespondences(mapPointSet, preViewId, newPointIdx, indexPairs(:,1));
    
    % Add image points corresponding to the map points in the second key frame
    mapPointSet   = addCorrespondences(mapPointSet, currViewId, newPointIdx, indexPairs(:,2));

    % Initialize place recognition database
    % Load the bag of features data created offline
    bofData         = load("bagOfFeaturesDataSLAM.mat");
    
    % Initialize the place recognition database
    loopDatabase    = invertedImageIndex(bofData.bof,SaveFeatureLocations=false);
    
    % Add features of the first two key frames to the database
    addImageFeatures(loopDatabase, preFeatures, preViewId);
    addImageFeatures(loopDatabase, currFeatures, currViewId);

    %% Refine and visualize initial reconstruction
    % Run full bundle adjustment on the first two key frames
    tracks       = findTracks(vSetKeyFrames);
    cameraPoses  = poses(vSetKeyFrames);
    
    [refinedPoints, refinedAbsPoses] = bundleAdjustment(xyzWorldPoints, tracks, ...
        cameraPoses, intrinsics, FixedViewIDs=1, ...
        PointsUndistorted=true, AbsoluteTolerance=1e-7,...
        RelativeTolerance=1e-15, MaxIteration=20, ...
        Solver="preconditioned-conjugate-gradient");

    % Scale the map and the camera pose using the median depth of map points
    medianDepth   = median(vecnorm(refinedPoints.'));
    refinedPoints = refinedPoints / medianDepth;
    
    refinedAbsPoses.AbsolutePose(currViewId).Translation = ...
        refinedAbsPoses.AbsolutePose(currViewId).Translation / medianDepth;
    relPose.Translation = relPose.Translation/medianDepth;
    
    % Update key frames with the refined poses
    vSetKeyFrames = updateView(vSetKeyFrames, refinedAbsPoses);
    vSetKeyFrames = updateConnection(vSetKeyFrames, preViewId, currViewId, relPose);
    
    % Update map points with the refined positions
    mapPointSet = updateWorldPoints(mapPointSet, newPointIdx, refinedPoints);
    
    % Update view direction and depth 
    mapPointSet = updateLimitsAndDirection(mapPointSet, newPointIdx, vSetKeyFrames.Views);
    
    % Update representative view
    mapPointSet = updateRepresentativeView(mapPointSet, newPointIdx, vSetKeyFrames.Views);
    
    % Visualize matched features in the current frame
    % close(hfeature.Parent.Parent);
    featurePlot   = helperVisualizeMatchedFeatures(currI, currPoints(indexPairs(:,2)));
    
    % Visualize initial map points and camera trajectory
    mapPlot       = helperVisualizeMotionAndStructure(vSetKeyFrames, mapPointSet);
    
    % Show legend
    showLegend(mapPlot);

    %% Tracking
    % ViewId of the current key frame
    currKeyFrameId   = currViewId;
    
    % ViewId of the last key frame
    lastKeyFrameId   = currViewId;
    
    % Index of the last key frame in the input image sequence
    lastKeyFrameIdx  = currFrameIdx - 1; 
    
    % Indices of all the key frames in the input image sequence
    addedFramesIdx   = [1; lastKeyFrameIdx];
    
    isLoopClosed     = false;

    % Main loop (attempt to close loop while iterating over all images in
    % dataset)
    isLastFrameKeyFrame = true;
    while ~isLoopClosed && currFrameIdx < numel(imds.Files)  
        currI = readimage(imds, currFrameIdx);
    
        [currFeatures, currPoints] = helperDetectAndExtractFeatures(currI, scaleFactor, numLevels, numPoints);
    
        % Track the last key frame
        % mapPointsIdx:   Indices of the map points observed in the current frame
        % featureIdx:     Indices of the corresponding feature points in the 
        %                 current frame
        [currPose, mapPointsIdx, featureIdx] = helperTrackLastKeyFrame(mapPointSet, ...
            vSetKeyFrames.Views, currFeatures, currPoints, lastKeyFrameId, intrinsics, scaleFactor);
    
        % Track the local map and check if the current frame is a key frame.
        % A frame is a key frame if both of the following conditions are satisfied:
        %
        % 1. At least 20 frames have passed since the last key frame or the
        %    current frame tracks fewer than 100 map points.
        % 2. The map points tracked by the current frame are fewer than 90% of
        %    points tracked by the reference key frame.
        %
        % Tracking performance is sensitive to the value of numPointsKeyFrame.  
        % If tracking is lost, try a larger value.
        %
        % localKeyFrameIds:   ViewId of the connected key frames of the current frame
        numSkipFrames     = 20;
        numPointsKeyFrame = 80;
        [localKeyFrameIds, currPose, mapPointsIdx, featureIdx, isKeyFrame] = ...
            helperTrackLocalMap(mapPointSet, vSetKeyFrames, mapPointsIdx, ...
            featureIdx, currPose, currFeatures, currPoints, intrinsics, scaleFactor, numLevels, ...
            isLastFrameKeyFrame, lastKeyFrameIdx, currFrameIdx, numSkipFrames, numPointsKeyFrame);

    
        % Visualize matched features
        updatePlot(featurePlot, currI, currPoints(featureIdx));
    
        if ~isKeyFrame
            currFrameIdx        = currFrameIdx + 1;
            isLastFrameKeyFrame = false;
            continue
        else
            isLastFrameKeyFrame = true;
        end
    
        % Update current key frame ID
        currKeyFrameId  = currKeyFrameId + 1;
    
        %% Local mapping
        % Add the new key frame 
        [mapPointSet, vSetKeyFrames] = helperAddNewKeyFrame(mapPointSet, vSetKeyFrames, ...
            currPose, currFeatures, currPoints, mapPointsIdx, featureIdx, localKeyFrameIds);

        % Remove outlier map points that are observed in fewer than 3 key frames
        outlierIdx    = setdiff(newPointIdx, mapPointsIdx);
        if ~isempty(outlierIdx)
            mapPointSet   = removeWorldPoints(mapPointSet, outlierIdx);
        end
    
        % Create new map points by triangulation
        minNumMatches = 10;
        minParallax   = 3;
        [mapPointSet, vSetKeyFrames, newPointIdx] = helperCreateNewMapPoints(mapPointSet, vSetKeyFrames, ...
            currKeyFrameId, intrinsics, scaleFactor, minNumMatches, minParallax);
    
        % Local bundle adjustment
        [refinedViews, dist] = connectedViews(vSetKeyFrames, currKeyFrameId, MaxDistance=2);
        refinedKeyFrameIds = refinedViews.ViewId;
        fixedViewIds = refinedKeyFrameIds(dist==2);
        fixedViewIds = fixedViewIds(1:min(10, numel(fixedViewIds)));
    
        % Refine local key frames and map points
        [mapPointSet, vSetKeyFrames, mapPointIdx] = bundleAdjustment(...
            mapPointSet, vSetKeyFrames, [refinedKeyFrameIds; currKeyFrameId], intrinsics, ...
            FixedViewIDs=fixedViewIds, PointsUndistorted=true, AbsoluteTolerance=1e-7,...
            RelativeTolerance=1e-16, Solver="preconditioned-conjugate-gradient", ...
            MaxIteration=10);
    
        % Update view direction and depth
        mapPointSet = updateLimitsAndDirection(mapPointSet, mapPointIdx, vSetKeyFrames.Views);
    
        % Update representative view
        mapPointSet = updateRepresentativeView(mapPointSet, mapPointIdx, vSetKeyFrames.Views);
    
        % Check if the KeyFrames directory exists; if not, create it
        keyFramesDir = './KeyFrames_Mono';
        if ~exist(keyFramesDir, 'dir')
            mkdir(keyFramesDir);
        end

        % Store feature locations for this key frame
        keyFramePointsDir = './KeyFramePoints_Mono';
        if ~exist(keyFramePointsDir, 'dir')
            mkdir(keyFramePointsDir); 
        end

        % Save the current key frame image using currKeyFrameId
        filename = sprintf('%s/KeyFrame_%04d.png', keyFramesDir, currKeyFrameId);
        imwrite(currI, filename);

        % Save feature points information
        saveKeyFramePoints(keyFramePointsDir, currKeyFrameId, currPoints(featureIdx), mapPointsIdx);


        % Visualize 3D world points and camera trajectory
        updatePlot(mapPlot, vSetKeyFrames, mapPointSet);

        %% Loop closure
        % Check loop closure after some key frames have been created    
        if currKeyFrameId > 20
    
            % Minimum number of feature matches of loop edges
            loopEdgeNumMatches = 50;
    
            % Detect possible loop closure key frame candidates
            [isDetected, validLoopCandidates] = helperCheckLoopClosure(vSetKeyFrames, currKeyFrameId, ...
                loopDatabase, currI, loopEdgeNumMatches);
    
            if isDetected 
                % Add loop closure connections
                [isLoopClosed, mapPointSet, vSetKeyFrames] = helperAddLoopConnections(...
                    mapPointSet, vSetKeyFrames, validLoopCandidates, currKeyFrameId, ...
                    currFeatures, loopEdgeNumMatches);
            end
        end
    
        % If no loop closure is detected, add current features into the database
        if ~isLoopClosed
            addImageFeatures(loopDatabase,  currFeatures, currKeyFrameId);
        end
    
        % Update IDs and indices
        lastKeyFrameId  = currKeyFrameId;
        lastKeyFrameIdx = currFrameIdx;
        addedFramesIdx  = [addedFramesIdx; currFrameIdx]; %#ok<AGROW>
        currFrameIdx    = currFrameIdx + 1;
    end % End of main loop

    %% Optimizing
    if isLoopClosed
        % Optimize the poses
        minNumMatches      = 20;
        vSetKeyFramesOptim = optimizePoses(vSetKeyFrames, minNumMatches, Tolerance=1e-16);
    
        % Update map points after optimizing the poses
        mapPointSet = helperUpdateGlobalMap(mapPointSet, vSetKeyFrames, vSetKeyFramesOptim);
    
        updatePlot(mapPlot, vSetKeyFrames, mapPointSet);
    
        % Plot the optimized camera trajectory
        optimizedPoses  = poses(vSetKeyFramesOptim);
        plotOptimizedTrajectory(mapPlot, optimizedPoses)
    
        % Update legend
        showLegend(mapPlot);
    
        worldPointSetOutput = mapPointSet;
    end
    
end


%% Helper functions
% The following funciton definitions are provied in the
% Mathworks_VSLAM_Example Directory
% helperAddLoopConnections add connections between the current keyframe and the valid loop candidate.
% helperAddNewKeyFrame add key frames to the key frame set.
% helperCheckLoopClosure detect loop candidates key frames by retrieving visually similar images from the database.
% helperCreateNewMapPoints create new map points by triangulation.
% helperORBFeatureExtractorFunction implements the ORB feature extraction used in bagOfFeatures.
% helperTrackLastKeyFrame estimate the current camera pose by tracking the last key frame.
% helperTrackLocalMap refine the current camera pose by tracking the local map.
% helperVisualizeMatchedFeatures show the matched features in a frame.
% helperVisualizeMotionAndStructure show map points and camera trajectory.
% helperImportGroundTruth import camera pose ground truth from the downloaded data.

% helperDetectAndExtractFeatures detect and extract and ORB features from the image.
function [features, validPoints] = helperDetectAndExtractFeatures(Irgb, ...
    scaleFactor, numLevels, numPoints, varargin)

    % In this example, the images are already undistorted. In a general
    % workflow, uncomment the following code to undistort the images.
    %
    % if nargin > 4
    %     intrinsics = varargin{1};
    % end
    % Irgb  = undistortImage(Irgb, intrinsics);
    
    % Detect ORB features
    Igray  = im2gray(Irgb);
    
    points = detectORBFeatures(Igray, ScaleFactor=scaleFactor, NumLevels=numLevels);
    
    % Select a subset of features, uniformly distributed throughout the image
    points = selectUniform(points, numPoints, size(Igray, 1:2));
    
    % Extract features
    [features, validPoints] = extractFeatures(Igray, points);
end

% helperComputeHomography compute homography and evaluate reconstruction.
function [H, score, inliersIndex] = helperComputeHomography(matchedPoints1, matchedPoints2)

    [H, inliersLogicalIndex] = estgeotform2d( ...
        matchedPoints1, matchedPoints2, "projective", ...
        MaxNumTrials=1e3, MaxDistance=4, Confidence=90);
    
    inlierPoints1 = matchedPoints1(inliersLogicalIndex);
    inlierPoints2 = matchedPoints2(inliersLogicalIndex);
    
    inliersIndex  = find(inliersLogicalIndex);
    
    locations1 = inlierPoints1.Location;
    locations2 = inlierPoints2.Location;
    xy1In2     = transformPointsForward(H, locations1);
    xy2In1     = transformPointsInverse(H, locations2);
    error1in2  = sum((locations2 - xy1In2).^2, 2);
    error2in1  = sum((locations1 - xy2In1).^2, 2);
    
    outlierThreshold = 6;
    
    score = sum(max(outlierThreshold-error1in2, 0)) + ...
        sum(max(outlierThreshold-error2in1, 0));
end

% helperComputeFundamentalMatrix compute fundamental matrix and evaluate reconstruction.
function [F, score, inliersIndex] = helperComputeFundamentalMatrix(matchedPoints1, matchedPoints2)

    [F, inliersLogicalIndex]   = estimateFundamentalMatrix( ...
        matchedPoints1, matchedPoints2, Method="RANSAC",...
        NumTrials=1e3, DistanceThreshold=4);
    
    inlierPoints1 = matchedPoints1(inliersLogicalIndex);
    inlierPoints2 = matchedPoints2(inliersLogicalIndex);
    
    inliersIndex  = find(inliersLogicalIndex);
    
    locations1    = inlierPoints1.Location;
    locations2    = inlierPoints2.Location;
    
    % Distance from points to epipolar line
    lineIn1   = epipolarLine(F', locations2);
    error2in1 = (sum([locations1, ones(size(locations1, 1),1)].* lineIn1, 2)).^2 ...
        ./ sum(lineIn1(:,1:2).^2, 2);
    lineIn2   = epipolarLine(F, locations1);
    error1in2 = (sum([locations2, ones(size(locations2, 1),1)].* lineIn2, 2)).^2 ...
        ./ sum(lineIn2(:,1:2).^2, 2);
    
    outlierThreshold = 4;
    
    score = sum(max(outlierThreshold-error1in2, 0)) + ...
        sum(max(outlierThreshold-error2in1, 0));
end

% helperTriangulateTwoFrames triangulate two frames to initialize the map.
function [isValid, xyzPoints, inlierIdx] = helperTriangulateTwoFrames(...
    pose1, pose2, matchedPoints1, matchedPoints2, intrinsics, minParallax)

    camMatrix1 = cameraProjection(intrinsics, pose2extr(pose1));
    camMatrix2 = cameraProjection(intrinsics, pose2extr(pose2));
    
    [xyzPoints, reprojectionErrors, isInFront] = triangulate(matchedPoints1, ...
        matchedPoints2, camMatrix1, camMatrix2);
    
    % Filter points by view direction and reprojection error
    minReprojError = 1;
    inlierIdx  = isInFront & reprojectionErrors < minReprojError;
    xyzPoints  = xyzPoints(inlierIdx ,:);
    
    % A good two-view with significant parallax
    ray1       = xyzPoints - pose1.Translation;
    ray2       = xyzPoints - pose2.Translation;
    cosAngle   = sum(ray1 .* ray2, 2) ./ (vecnorm(ray1, 2, 2) .* vecnorm(ray2, 2, 2));
    
    % Check parallax
    isValid = all(cosAngle < cosd(minParallax) & cosAngle>0);
end

% helperEstimateTrajectoryError calculate the tracking error.
function rmse = helperEstimateTrajectoryError(gTruth, cameraPoses)
    locations       = vertcat(cameraPoses.AbsolutePose.Translation);
    gLocations      = vertcat(gTruth.Translation);
    scale           = median(vecnorm(gLocations, 2, 2))/ median(vecnorm(locations, 2, 2));
    scaledLocations = locations * scale;
    
    rmse = sqrt(mean( sum((scaledLocations - gLocations).^2, 2) ));
    disp(['Absolute RMSE for key frame trajectory (m): ', num2str(rmse)]);
end

% helperUpdateGlobalMap update 3-D locations of map points after pose graph optimization
function mapPointSet = helperUpdateGlobalMap(...
    mapPointSet, vSetKeyFrames, vSetKeyFramesOptim)
    %helperUpdateGlobalMap update map points after pose graph optimization
    posesOld     = vSetKeyFrames.Views.AbsolutePose;
    posesNew     = vSetKeyFramesOptim.Views.AbsolutePose;
    positionsOld = mapPointSet.WorldPoints;
    positionsNew = positionsOld;
    indices     = 1:mapPointSet.Count;
    
    % Update world location of each map point based on the new absolute pose of 
    % the corresponding major view
    for i = indices
        majorViewIds = mapPointSet.RepresentativeViewId(i);
        poseNew = posesNew(majorViewIds).A;
        tform = affinetform3d(poseNew/posesOld(majorViewIds).A);
        positionsNew(i, :) = transformPointsForward(tform, positionsOld(i, :));
    end
    mapPointSet = updateWorldPoints(mapPointSet, indices, positionsNew);
end

% function saveKeyFramePoints(dirPath, frameIndex, featurePoints)
%     % Extract locations and corresponding point indices
%     locations = featurePoints.Location;
%     indices = (1:size(locations, 1))';  % Create an index array
%     dataMatrix = [indices, locations];
% 
%     % Define filename for CSV
%     csvFilename = sprintf('%s/KeyFramePoints_%04d.csv', dirPath, frameIndex);
% 
%     % Write matrix to CSV
%     writematrix(dataMatrix, csvFilename);
% end

function saveKeyFramePoints(dirPath, keyFrameId, featurePoints, mapPointsIdx)
    % Ensure the directory exists
    if ~exist(dirPath, 'dir')
        mkdir(dirPath);
    end

    % Define the filename for the CSV file
    csvFilename = sprintf('%s/KeyFramePoints_%04d.csv', dirPath, keyFrameId);

    % Extract pixel locations from the feature points
    pixelLocations = featurePoints.Location;  % This should be an Nx2 matrix

    % Combine the indices, pixel locations, and corresponding world points indices into one matrix
    dataMatrix = [pixelLocations, mapPointsIdx];  % Concatenate horizontally

    % Write the combined data to a CSV file
    writematrix(dataMatrix, csvFilename);
end


