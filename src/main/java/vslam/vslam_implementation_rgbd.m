function vslam_implementation_rgbd(dataset_name)
    
    % Import dependencies
    addpath('./Mathworks_VSLAM_RGBD/');

    % Define the base folder for datasets
    datasetFolder = [dataset_name, '/'];

    % Check if the dataset exists, if not download and prepare it
    if ~exist(datasetFolder, 'dir')
        if strcmp(dataset_name, 'tum_rgbd_dataset')
            % Define the URL and local folder for download
            baseDownloadURL = "https://cvg.cit.tum.de/rgbd/dataset/freiburg3/rgbd_dataset_freiburg3_long_office_household.tgz";
            dataFolder = fullfile('tum_rgbd_dataset', filesep);
            tgzFileName = [dataFolder, 'fr3_office.tgz'];

            % Create a folder to save the downloaded file
            if ~exist(dataFolder, 'dir')
                mkdir(dataFolder);
                disp('Downloading fr3_office.tgz (1.38 GB). This download can take a few minutes.');
                h = waitbar(0, 'Downloading Dataset... Please wait.', 'Name', 'Downloading fr3_office');
                websave(tgzFileName, baseDownloadURL, weboptions('Timeout', Inf));
                % Update and close waitbar after download completes
                waitbar(1, h, 'Download Complete. Extracting...');
                pause(1); % Pause to show complete message
                close(h);

                % Extract contents of the downloaded file
                disp('Extracting fr3_office.tgz (1.38 GB) ...');
                h = waitbar(0, 'Extracting files... This may take a while.', 'Name', 'Extracting Data');
                untar(tgzFileName, dataFolder);

                % Close waitbar after extraction completes
                waitbar(1, h, 'Extraction Complete.');
                pause(1); % Pause to show complete message
                close(h);
            end

            imageFolder = [dataFolder, 'rgbd_dataset_freiburg3_long_office_household/'];

            % Initialize image dataset stores for color and depth images
            imgFolderColor = [imageFolder, 'rgb/'];
            imgFolderDepth = [imageFolder, 'depth/'];
            imdsColor = imageDatastore(imgFolderColor);
            imdsDepth = imageDatastore(imgFolderDepth);
        
            % Note that the color and depth images are generated in an un-synchronized way in the dataset. Therefore, we need to associate color images to depth images based on the time stamp.
            % Load time stamp data of color images
            timeColor = helperImportTimestampFile([imageFolder, 'rgb.txt']);
            
            % Load time stamp data of depth images
            timeDepth = helperImportTimestampFile([imageFolder, 'depth.txt']);
            
            % Align the time stamp
            indexPairs = helperAlignTimestamp(timeColor, timeDepth);
            
            % Select the synchronized image data
            imdsColor     = subset(imdsColor, indexPairs(:, 1));
            imdsDepth     = subset(imdsDepth, indexPairs(:, 2));

        elseif strcmp(dataset_name, 'imperial_college_london')
            % Define the URL and local folder for download
            baseDownloadURL = "http://www.doc.ic.ac.uk/~ahanda/living_room_traj2_frei_png.tar.gz";
            dataFolder = fullfile('imperial_college_london', filesep);
            tgzFileName = [dataFolder, 'living_room_traj2_frei_png.tar.gz'];

            % Create a folder to save the downloaded file
            if ~exist(dataFolder, 'dir')
                mkdir(dataFolder);
                disp('Downloading living_room_traj2_frei_png.tar.gz (486 MB). This download can take a few minutes.');
                h = waitbar(0, 'Downloading Dataset... Please wait.', 'Name', 'Downloading living_room_traj2');
                websave(tgzFileName, baseDownloadURL, weboptions('Timeout', Inf));
                % Update and close waitbar after download completes
                waitbar(1, h, 'Download Complete. Extracting...');
                pause(1); % Pause to show complete message
                close(h);

                % Extract contents of the downloaded file
                disp('Extracting living_room_traj2 (486 MB) ...');
                h = waitbar(0, 'Extracting files... This may take a while.', 'Name', 'Extracting Data');
                untar(tgzFileName, dataFolder);

                % Close waitbar after extraction completes
                waitbar(1, h, 'Extraction Complete.');
                pause(1); % Pause to show complete message
                close(h);
            end

            imageFolder = [dataFolder];

            % Initialize image dataset stores for color and depth images
            imgFolderColor = [imageFolder, 'rgb/'];
            imgFolderDepth = [imageFolder, 'depth/'];
            imdsColor = imageDatastore(imgFolderColor);
            imdsDepth = imageDatastore(imgFolderDepth);
        else
            error('Dataset name not recognized or dataset-specific download steps not defined.');
        end
    else
        % If dataset is already present, set the image folder path
        if strcmp(dataset_name, 'tum_rgbd_dataset')
            imageFolder = [datasetFolder, 'rgbd_dataset_freiburg3_long_office_household/'];
            % Initialize image dataset stores for color and depth images
            imgFolderColor = [imageFolder, 'rgb/'];
            imgFolderDepth = [imageFolder, 'depth/'];
            imdsColor = imageDatastore(imgFolderColor);
            imdsDepth = imageDatastore(imgFolderDepth);
        
            % Note that the color and depth images are generated in an un-synchronized way in the dataset. Therefore, we need to associate color images to depth images based on the time stamp.
            % Load time stamp data of color images
            timeColor = helperImportTimestampFile([imageFolder, 'rgb.txt']);
            
            % Load time stamp data of depth images
            timeDepth = helperImportTimestampFile([imageFolder, 'depth.txt']);
            
            % Align the time stamp
            indexPairs = helperAlignTimestamp(timeColor, timeDepth);
            
            % Select the synchronized image data
            imdsColor     = subset(imdsColor, indexPairs(:, 1));
            imdsDepth     = subset(imdsDepth, indexPairs(:, 2));
        elseif strcmp(dataset_name, 'imperial_college_london')
            imageFolder = [datasetFolder];

            % Initialize image dataset stores for color and depth images
            imgFolderColor = [imageFolder, 'rgb/'];
            imgFolderDepth = [imageFolder, 'depth/'];
            imdsColor = imageDatastore(imgFolderColor);
            imdsDepth = imageDatastore(imgFolderDepth);
        end 
    end

    % Process the image sequence
    [worldPointSetOutput, optimizedPoses, pointCloudsAll, intrinsics] = ProcessImageSequence(imdsColor, imdsDepth);

    % Save the outputs to .mat files
    % save('worldPointSetOutput.mat', 'worldPointSetOutput');
    % save('optimizedPoses.mat', 'optimizedPoses');
    % save('pointCloudsAll.mat', 'pointCloudsAll');
    % save('cameraIntrinsics.mat', 'intrinsics');

    % save outputs to CSV files in directories given as name:
    savePosesToCSV(optimizedPoses, 'CameraPoses');
    savePointCloudToCSV(pointCloudsAll);
    saveIntrinsicsToCSV(intrinsics);

    % Iterate over KeyFrames and execute extractPointsByViewId
    keyFramesDir = './KeyFrames';
    keyFrameFiles = dir(fullfile(keyFramesDir, 'KeyFrame_*.png'));

    for i = 1:length(keyFrameFiles)
        filename = keyFrameFiles(i).name;
        viewId = str2double(regexp(filename, '\d+', 'match', 'once')); % Extracting the numeric part from filename
        extractPointsByViewId(viewId, worldPointSetOutput);
    end

end


function [worldPointSetOutput, optimizedPoses, pointCloudsAll, intrinsics] = ProcessImageSequence(imdsColor, imdsDepth)
    % Inspect the first RGB-D image
    currFrameIdx  = 1;
    currIcolor    = readimage(imdsColor, currFrameIdx);
    currIdepth    = readimage(imdsDepth, currFrameIdx);
    % imshowpair(currIcolor, currIdepth, "montage");
    
    % Map Initialization: The pipeline starts by initializing the map that holds 3-D world points. 
    % This step is crucial and has a significant impact on the accuracy of the final SLAM result. 
    % Initial ORB feature points are extracted from the first color image using helperDetectAndExtractFeatures. 
    % Their corresponding 3-D world locations can be computed from the pixel coordinates of the feature 
    % points and the depth value using helperReconstructFromRGBD.

    % Set random seed for reproducibility
    rng(0);
    
    % Create a cameraIntrinsics object to store the camera intrinsic parameters.
    % The intrinsics for the dataset can be found at the following page:
    % https://vision.in.tum.de/data/datasets/rgbd-dataset/file_formats
    focalLength    = [535.4, 539.2];    % in units of pixels
    principalPoint = [320.1, 247.6];    % in units of pixels
    imageSize      = size(currIcolor,[1,2]); % in pixels [mrows, ncols]
    depthFactor    = 5e3;
    intrinsics     = cameraIntrinsics(focalLength,principalPoint,imageSize);
    
    % Detect and extract ORB features from the color image
    scaleFactor = 1.2;
    numLevels   = 8;
    [currFeatures, currPoints] = helperDetectAndExtractFeatures(currIcolor, scaleFactor, numLevels); 
    
    initialPose = rigidtform3d();
    [xyzPoints, validIndex] = helperReconstructFromRGBD(currPoints, currIdepth, intrinsics, initialPose, depthFactor);

    % Initialize Place Recognition Database
    % Loop detection is performed using the bags-of-words approach. A visual vocabulary represented as a bagOfFeatures object is created offline with the ORB descriptors extracted from a large set of images in the dataset by calling:
    % bag = bagOfFeatures(imds,CustomExtractor=@helperORBFeatureExtractorFunction, TreeProperties=[5, 10], StrongestFeatures=1);
    % where imds is an imageDatastore object storing the training images and helperORBFeatureExtractorFunction is the ORB feature extractor function. See Image Retrieval with Bag of Visual Words for more information.
    % The loop closure process incrementally builds a database, represented as an invertedImageIndex object, that stores the visual word-to-image mapping based on the bag of ORB features.

    % Load the bag of features data created offline
    bofData         = load("bagOfFeaturesDataSLAM.mat");
    
    % Initialize the place recognition database
    loopDatabase    = invertedImageIndex(bofData.bof, SaveFeatureLocations=false);
    
    % Add features of the first key frame to the database
    currKeyFrameId = 1;
    addImageFeatures(loopDatabase, currFeatures, currKeyFrameId);

    % Data Management and Visualization
    % After the map is initialized using the first pair of color and depth image, you can use imageviewset and worldpointset to store the first key frames and the corresponding map points:

    % Create an empty imageviewset object to store key frames
    vSetKeyFrames = imageviewset;
    
    % Create an empty worldpointset object to store 3-D map points
    mapPointSet   = worldpointset;
    
    % Add the first key frame
    vSetKeyFrames = addView(vSetKeyFrames, currKeyFrameId, initialPose, Points=currPoints,...
        Features=currFeatures.Features);
    
    % Add 3-D map points
    [mapPointSet, rgbdMapPointsIdx] = addWorldPoints(mapPointSet, xyzPoints);
    
    % Add observations of the map points
    mapPointSet = addCorrespondences(mapPointSet, currKeyFrameId, rgbdMapPointsIdx, validIndex);
    
    % Update view direction and depth
    mapPointSet = updateLimitsAndDirection(mapPointSet, rgbdMapPointsIdx, vSetKeyFrames.Views);
    
    % Update representative view
    mapPointSet = updateRepresentativeView(mapPointSet, rgbdMapPointsIdx, vSetKeyFrames.Views);
    
    % Visualize matched features in the first key frame
    featurePlot = helperVisualizeMatchedFeaturesRGBD(currIcolor, currIdepth, currPoints(validIndex));
    
    % Visualize initial map points and camera trajectory
    xLim = [-4 4];
    yLim = [-3 1];
    zLim = [-1 6];
    mapPlot  = helperVisualizeMotionAndStructure(vSetKeyFrames, mapPointSet, xLim, yLim, zLim);
    
    % Show legend
    showLegend(mapPlot);

    % Tracking
    % The tracking process is performed using every RGB-D image and determines when to insert a new key frame. 
    % ViewId of the last key frame
    lastKeyFrameId    = currKeyFrameId;
    
    % Index of the last key frame in the input image sequence
    lastKeyFrameIdx   = currFrameIdx; 
    
    % Indices of all the key frames in the input image sequence
    addedFramesIdx    = lastKeyFrameIdx;
    
    currFrameIdx      = 2;
    isLoopClosed      = false;

    % Each frame is processed as follows:
    % ORB features are extracted for each new color image and then matched (using matchFeatures), with features in the last key frame that have known corresponding 3-D map points.
    % Estimate the camera pose using Perspective-n-Point algorithm, which estimates the pose of a calibrated camera given a set of 3-D points and their corresponding 2-D projections using estworldpose.
    % Given the camera pose, project the map points observed by the last key frame into the current frame and search for feature correspondences using  matchFeaturesInRadius.
    % With 3-D to 2-D correspondences in the current frame, refine the camera pose by performing a motion-only bundle adjustment using bundleAdjustmentMotion.
    % Project the local map points into the current frame to search for more feature correspondences using matchFeaturesInRadius and refine the camera pose again using bundleAdjustmentMotion.
    % The last step of tracking is to decide if the current frame should be a new key frame. A frame is a key frame if both of the following conditions are satisfied:
    % At least 20 frames have passed since the last key frame or the current frame tracks fewer than 100 map points or 25% of points tracked by the reference key frame.
    % The map points tracked by the current frame are fewer than 90% of points tracked by the reference key frame.
    % If the current frame is to become a key frame, continue to the Local Mapping process. Otherwise, start Tracking for the next frame.
    
    % Main loop
    isLastFrameKeyFrame = true;
    while ~isLoopClosed && currFrameIdx < numel(imdsColor.Files)
    
        currIcolor = readimage(imdsColor, currFrameIdx);
        currIdepth = readimage(imdsDepth, currFrameIdx);
    
        [currFeatures, currPoints]    = helperDetectAndExtractFeatures(currIcolor, scaleFactor, numLevels);
    
        % Track the last key frame
        % trackedMapPointsIdx:  Indices of the map points observed in the current left frame 
        % trackedFeatureIdx:    Indices of the corresponding feature points in the current left frame
        [currPose, trackedMapPointsIdx, trackedFeatureIdx] = helperTrackLastKeyFrame(mapPointSet, ...
            vSetKeyFrames.Views, currFeatures, currPoints, lastKeyFrameId, intrinsics, scaleFactor);
        
        if isempty(currPose) || numel(trackedMapPointsIdx) < 30
            currFrameIdx = currFrameIdx + 1;
            continue
        end
        
        % Track the local map and check if the current frame is a key frame.
        % A frame is a key frame if both of the following conditions are satisfied:
        %
        % 1. At least 20 frames have passed since the last key frame or the 
        %    current frame tracks fewer than 100 map points. 
        % 2. The map points tracked by the current frame are fewer than 90% of 
        %    points tracked by the reference key frame.
        %
        % localKeyFrameIds:   ViewId of the connected key frames of the current frame
        numSkipFrames     = 20;
        numPointsKeyFrame = 100;
        [localKeyFrameIds, currPose, trackedMapPointsIdx, trackedFeatureIdx, isKeyFrame] = ...
            helperTrackLocalMap(mapPointSet, vSetKeyFrames, trackedMapPointsIdx, ...
            trackedFeatureIdx, currPose, currFeatures, currPoints, intrinsics, scaleFactor, numLevels, ...
            isLastFrameKeyFrame, lastKeyFrameIdx, currFrameIdx, numSkipFrames, numPointsKeyFrame);
    
        % Visualize matched features
        updatePlot(featurePlot, currIcolor, currIdepth, currPoints(trackedFeatureIdx));
        
        if ~isKeyFrame
            currFrameIdx = currFrameIdx + 1;
            isLastFrameKeyFrame = false;
            continue
        else
            % Match feature points between the stereo images and get the 3-D world positions
            [xyzPoints, validIndex] = helperReconstructFromRGBD(currPoints, currIdepth, ...
                intrinsics, currPose, depthFactor);
    
            [untrackedFeatureIdx, ia] = setdiff(validIndex, trackedFeatureIdx);
            xyzPoints = xyzPoints(ia, :);
            isLastFrameKeyFrame = true;
        end
    
        % Update current key frame ID
        currKeyFrameId  = currKeyFrameId + 1;

        % Local Mapping
        % Local mapping is performed for every key frame. When a new key frame is determined, add it to the key frames and update the attributes of the map points observed by the new key frame. To ensure that mapPointSet contains as few outliers as possible, a valid map point must be observed in at least 3 key frames. 
        % New map points are created by triangulating ORB feature points in the current key frame and its connected key frames. For each unmatched feature point in the current key frame, search for a match with other unmatched points in the connected key frames using matchFeatures. The local bundle adjustment refines the pose of the current key frame, the poses of connected key frames, and all the map points observed in these key frames.

        % Add the new key frame    
        [mapPointSet, vSetKeyFrames] = helperAddNewKeyFrame(mapPointSet, vSetKeyFrames, ...
            currPose, currFeatures, currPoints, trackedMapPointsIdx, trackedFeatureIdx, localKeyFrameIds);
            
        % Remove outlier map points that are observed in fewer than 3 key frames
        if currKeyFrameId == 2
            triangulatedMapPointsIdx = [];
        end
        
        [mapPointSet, trackedMapPointsIdx] = ...
            helperCullRecentMapPoints(mapPointSet, trackedMapPointsIdx, triangulatedMapPointsIdx, ...
            rgbdMapPointsIdx);
        
        % Add new map points computed from disparity 
        [mapPointSet, rgbdMapPointsIdx] = addWorldPoints(mapPointSet, xyzPoints);
        mapPointSet = addCorrespondences(mapPointSet, currKeyFrameId, rgbdMapPointsIdx, ...
            untrackedFeatureIdx);
        
        % Create new map points by triangulation
        minNumMatches = 10;
        minParallax   = 0.35;
        [mapPointSet, vSetKeyFrames, triangulatedMapPointsIdx, rgbdMapPointsIdx] = helperCreateNewMapPointsStereo( ...
            mapPointSet, vSetKeyFrames, currKeyFrameId, intrinsics, scaleFactor, minNumMatches, minParallax, ...
            untrackedFeatureIdx, rgbdMapPointsIdx);
    
        % Update view direction and depth
        mapPointSet = updateLimitsAndDirection(mapPointSet, [triangulatedMapPointsIdx; rgbdMapPointsIdx], ...
            vSetKeyFrames.Views);
    
        % Update representative view
        mapPointSet = updateRepresentativeView(mapPointSet, [triangulatedMapPointsIdx; rgbdMapPointsIdx], ...
            vSetKeyFrames.Views);
    
        % Local bundle adjustment
        [mapPointSet, vSetKeyFrames, triangulatedMapPointsIdx, rgbdMapPointsIdx] = ...
            helperLocalBundleAdjustmentStereo(mapPointSet, vSetKeyFrames, ...
            currKeyFrameId, intrinsics, triangulatedMapPointsIdx, rgbdMapPointsIdx);

        % Check if the KeyFrames directory exists; if not, create it
        keyFramesDir = './KeyFrames';
        if ~exist(keyFramesDir, 'dir')
            mkdir(keyFramesDir);
        end

        % Store feature locations for this key frame
        keyFramePointsDir = './KeyFramePoints';
        if ~exist(keyFramePointsDir, 'dir')
            mkdir(keyFramePointsDir); 
        end

        % Save the current key frame image using currKeyFrameId
        filename = sprintf('%s/KeyFrame_%04d.png', keyFramesDir, currKeyFrameId);
        imwrite(currIcolor, filename);

        % Save feature points information
        saveKeyFramePoints(keyFramePointsDir, currKeyFrameId, currPoints(trackedFeatureIdx), trackedMapPointsIdx);
    
        % Visualize 3-D world points and camera trajectory
        updatePlot(mapPlot, vSetKeyFrames, mapPointSet);

        % Loop Closure
        % The loop closure detection step takes the current key frame processed by the local mapping process and tries to detect and close the loop. Loop candidates are identified by querying images in the database that are visually similar to the current key frame using evaluateImageRetrieval. A candidate key frame is valid if it is not connected to the last key frame and three of its neighbor key frames are loop candidates.
        % When a valid loop candidate is found, use estgeotform3d to compute the relative pose between the loop candidate frame and the current key frame. The relative pose represents a 3-D rigid transformation stored in a rigidtform3d object. Then add the loop connection with the relative pose and update mapPointSet and vSetKeyFrames.
        % Check loop closure after some key frames have been created    
        if currKeyFrameId > 20
            
            % Minimum number of feature matches of loop edges
            loopEdgeNumMatches = 120;
            
            % Detect possible loop closure key frame candidates
            [isDetected, validLoopCandidates] = helperCheckLoopClosure(vSetKeyFrames, currKeyFrameId, ...
                loopDatabase, currIcolor, loopEdgeNumMatches);
            
            if isDetected 
                % Add loop closure connections
                maxDistance = 0.1;
                [isLoopClosed, mapPointSet, vSetKeyFrames] = helperAddLoopConnectionsStereo(...
                    mapPointSet, vSetKeyFrames, validLoopCandidates, currKeyFrameId, ...
                    currFeatures, currPoints, loopEdgeNumMatches, maxDistance);
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

    % Finally, apply pose graph optimization over the essential graph in vSetKeyFrames to correct the drift. The essential graph is created internally by removing connections with fewer than minNumMatches matches in the covisibility graph. After pose graph optimization, update the 3-D locations of the map points using the optimized poses.
    
    % Optimize the poses
    minNumMatches      = 50;
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

    % Dense Reconstruction from Depth Image
    % Given the refined camera poses, you can reproject all the valid image points in the associated depth images back to the 3-D space to perform dense reconstruction. 
    % Create an array of pointCloud objects to store the world points constructed

    % from the key frames
    ptClouds =  repmat(pointCloud(zeros(1, 3)), numel(addedFramesIdx), 1);
    
    % Ignore image points at the boundary 
    offset = 40;
    [X, Y] = meshgrid(offset:2:imageSize(2)-offset, offset:2:imageSize(1)-offset);
    
    for i = 1: numel(addedFramesIdx)
        Icolor = readimage(imdsColor, addedFramesIdx(i));
        Idepth = readimage(imdsDepth, addedFramesIdx(i));
    
        [xyzPoints, validIndex] = helperReconstructFromRGBD([X(:), Y(:)], ...
            Idepth, intrinsics, optimizedPoses.AbsolutePose(i), depthFactor);
    
        colors = zeros(numel(X), 1, 'like', Icolor);
        for j = 1:numel(X)
            colors(j, 1:3) = Icolor(Y(j), X(j), :);
        end
        ptClouds(i) = pointCloud(xyzPoints, Color=colors(validIndex, :));
    end
    
    % Concatenate the point clouds
    pointCloudsAll = pccat(ptClouds);
    
    figure
    pcshow(pointCloudsAll,VerticalAxis="y", VerticalAxisDir="down");
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
end

%% Helper functions

% helperImportTimestampFile Import time stamp file

function timestamp = helperImportTimestampFile(filename)
    % Input handling
    dataLines = [4, Inf];
    
    %% Set up the Import Options and import the data
    opts = delimitedTextImportOptions("NumVariables", 2);
    
    % Specify range and delimiter
    opts.DataLines = dataLines;
    opts.Delimiter = " ";
    
    % Specify column names and types
    opts.VariableNames = ["VarName1", "Var2"];
    opts.SelectedVariableNames = "VarName1";
    opts.VariableTypes = ["double", "string"];
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    opts.ConsecutiveDelimitersRule = "join";
    opts.LeadingDelimitersRule = "ignore";
    
    % Specify variable properties
    opts = setvaropts(opts, "Var2", "WhitespaceRule", "preserve");
    opts = setvaropts(opts, "Var2", "EmptyFieldRule", "auto");
    
    % Import the data
    data = readtable(filename, opts);
    
    % Convert to output type
    timestamp = table2array(data);
end

% helperAlignTimestamp align time stamp of color and depth images.
function indexPairs = helperAlignTimestamp(timeColor, timeDepth)
    idxDepth = 1;
    indexPairs = zeros(numel(timeColor), 2);
    for i = 1:numel(timeColor)
        for j = idxDepth : numel(timeDepth)
            if abs(timeColor(i) - timeDepth(j)) < 1e-4
                idxDepth = j;
                indexPairs(i, :) = [i, j];
                break
            elseif timeDepth(j) - timeColor(i) > 1e-3
                break
            end
        end
    end
    indexPairs = indexPairs(indexPairs(:,1)>0, :);
end

% helperDetectAndExtractFeatures detect and extract and ORB features from the image.
function [features, validPoints] = helperDetectAndExtractFeatures(Irgb, scaleFactor, numLevels)
 
    numPoints = 1000;
    
    % Detect ORB features
    Igray  = rgb2gray(Irgb);
    
    points = detectORBFeatures(Igray, ScaleFactor=scaleFactor, NumLevels=numLevels);
    
    % Select a subset of features, uniformly distributed throughout the image
    points = selectUniform(points, numPoints, size(Igray, 1:2));
    
    % Extract features
    [features, validPoints] = extractFeatures(Igray, points);
end

% helperReconstructFromRGBD reconstruct scene from color and depth image.

function [xyzPoints, validIndex] = helperReconstructFromRGBD(points, ...
    depthMap, intrinsics, currPose, depthFactor)

    ptcloud = pcfromdepth(depthMap,depthFactor,intrinsics,ImagePoints=points, DepthRange=[0.1, 5]);
    
    isPointValid = ~isnan(ptcloud.Location(:, 1));
    xyzPoints    = ptcloud.Location(isPointValid, :);
    xyzPoints    = transformPointsForward(currPose, xyzPoints);
    validIndex   = find(isPointValid);
end

% helperCullRecentMapPoints cull recently added map points.
function [mapPointSet, mapPointsIdx] = ...
    helperCullRecentMapPoints(mapPointSet, mapPointsIdx, newPointIdx, rgbdMapPointsIndices)
    outlierIdx = setdiff([newPointIdx; rgbdMapPointsIndices], mapPointsIdx);
    if ~isempty(outlierIdx)
        mapPointSet   = removeWorldPoints(mapPointSet, outlierIdx);
        mapPointsIdx  = mapPointsIdx - arrayfun(@(x) nnz(x>outlierIdx), mapPointsIdx);
    end
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
function mapPointSet = helperUpdateGlobalMap(mapPointSet, vSetKeyFrames, vSetKeyFramesOptim)

    posesOld     = vSetKeyFrames.Views.AbsolutePose;
    posesNew     = vSetKeyFramesOptim.Views.AbsolutePose;
    positionsOld = mapPointSet.WorldPoints;
    positionsNew = positionsOld;
    indices = 1:mapPointSet.Count;
    
    % Update world location of each map point based on the new absolute pose of 
    % the corresponding major view
    for i = 1: mapPointSet.Count
        majorViewIds = mapPointSet.RepresentativeViewId(i);
        tform = rigidtform3d(posesNew(majorViewIds).A/posesOld(majorViewIds).A);
        positionsNew(i, :) = transformPointsForward(tform, positionsOld(i, :));
    end
    mapPointSet = updateWorldPoints(mapPointSet, indices, positionsNew);
end

% CSV file creation for points within keyframe
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


function savePointCloudToCSV(pointCloudsAll)
    mat = [pointCloudsAll.Location, cast(pointCloudsAll.Color, "single")];
    writematrix(mat, "pointcloud.csv");
end


function savePosesToCSV(optimizedPoses, dirPath)
    mkdir(dirPath)
    
    t_size = size(optimizedPoses);
    for i=1:t_size(1)
        p = optimizedPoses.AbsolutePose(i, 1);
        % first row will be translation
        % second-fifth row will be rotation
        mat = [p.Translation; p.R];
        idx = optimizedPoses.ViewId(i,1);

        % save to directory
        fname = sprintf('%s/Pose_%04d.csv', dirPath, idx);
        writematrix(mat, fname);
    end
end


function saveIntrinsicsToCSV(intrinsics)
    mat = [intrinsics.FocalLength, 0 ; 
        intrinsics.PrincipalPoint, 0 ;
        intrinsics.ImageSize, 0 ; 
        intrinsics.K];

    writematrix(mat, 'CameraIntrinsics.csv')
end