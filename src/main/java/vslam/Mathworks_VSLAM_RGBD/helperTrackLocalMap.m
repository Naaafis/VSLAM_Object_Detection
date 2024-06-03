function [localKeyFrameIds, currPose, mapPointIdx, featureIdx, isKeyFrame] = ...
    helperTrackLocalMap(mapPoints, vSetKeyFrames, mapPointIdx, ...
    featureIdx, currPose, currFeatures, currPoints, intrinsics, scaleFactor, numLevels, ...
    newKeyFrameAdded, lastKeyFrameIndex, currFrameIndex, numSkipFrames, numPointsKeyFrame)
%helperTrackLocalMap Refine camera pose by tracking the local map
%
%   This is an example helper function that is subject to change or removal 
%   in future releases.
%
%   Inputs
%   ------
%   mapPoints         - A worldpointset object storing map points
%   vSetKeyFrames     - An imageviewset storing key frames
%   mapPointsIndices  - Indices of map points observed in the current frame
%   featureIndices    - Indices of features in the current frame 
%                       corresponding to map points denoted by mapPointsIndices                      
%   currPose          - Current camera pose
%   currFeatures      - ORB Features in the current frame 
%   currPoints        - Feature points in the current frame
%   intrinsics        - Camera intrinsics 
%   scaleFactor       - scale factor of features
%   numLevels         - number of levels in feature exatraction
%   newKeyFrameAdded  - A boolean scalar indicating if a new key frame is
%                       added recently
%   lastKeyFrameIndex - Frame index of the last key frame
%   currFrameIndex    - Frame index of the current frame
%   numSkipFrames     - Largest number of frames to skip
%   numPointsKeyFrame - Minimum number of points tracked by a key frame
%   
%   Outputs
%   -------
%   localKeyFrameIds  - ViewIds of the local key frames 
%   currPose          - Refined camera pose of the current frame
%   mapPointIdx       - Indices of map points observed in the current frame
%   featureIdx        - Indices of features in the current frame corresponding
%                       to mapPointIdx
%   isKeyFrame        - A boolean scalar indicating if the current frame is
%                       a key frame

%   Copyright 2019-2022 The MathWorks, Inc.

persistent numPointsRefKeyFrame localPointsIndices localKeyFrameIdsInternal

if isempty(numPointsRefKeyFrame) || newKeyFrameAdded
    [localPointsIndices, localKeyFrameIdsInternal, numPointsRefKeyFrame] = ...
    updateRefKeyFrameAndLocalPoints(mapPoints, vSetKeyFrames, mapPointIdx);
end

% Project the map into the frame and search for more map point correspondences
newMapPointIdx = setdiff(localPointsIndices, mapPointIdx, 'stable');
localFeatures  = getFeatures(mapPoints, vSetKeyFrames.Views, newMapPointIdx); 
[projectedPoints, inlierIndex, predictedScales, viewAngles] = removeOutlierMapPoints(mapPoints, ...
    currPose, intrinsics, newMapPointIdx, scaleFactor, numLevels);

newMapPointIdx = newMapPointIdx(inlierIndex);
localFeatures  = localFeatures(inlierIndex,:);

unmatchedfeatureIdx = setdiff(cast((1:size( currFeatures.Features, 1)).', 'uint32'), ...
    featureIdx,'stable');
unmatchedFeatures   = currFeatures.Features(unmatchedfeatureIdx, :);
unmatchedValidPoints= currPoints(unmatchedfeatureIdx);

% Search radius depends on scale and view direction
searchRadius    = 4*ones(size(localFeatures, 1), 1);
searchRadius(viewAngles<3) = 2.5;
searchRadius    = searchRadius.*predictedScales;

indexPairs = matchFeaturesInRadius(binaryFeatures(localFeatures),...
    binaryFeatures(unmatchedFeatures), unmatchedValidPoints, projectedPoints, ...
    searchRadius, 'MatchThreshold', 40, 'MaxRatio', 0.9, 'Unique', true);

% Filter by scales
isGoodScale = currPoints.Scale(indexPairs(:, 2)) >= ...
    max(1, predictedScales(indexPairs(:, 1))/scaleFactor) & ...
    currPoints.Scale(indexPairs(:, 2)) <= predictedScales(indexPairs(:, 1));
indexPairs  = indexPairs(isGoodScale, :);

% Refine camera pose with more 3D-to-2D correspondences
mapPointIdx   = [newMapPointIdx(indexPairs(:,1)); mapPointIdx];
featureIdx     = [unmatchedfeatureIdx(indexPairs(:,2)); featureIdx];
matchedMapPoints   = mapPoints.WorldPoints(mapPointIdx,:);
matchedImagePoints = currPoints.Location(featureIdx,:);

isKeyFrame = checkKeyFrame(numPointsRefKeyFrame, lastKeyFrameIndex, ...
    currFrameIndex, mapPointIdx, numSkipFrames, numPointsKeyFrame);

localKeyFrameIds = localKeyFrameIdsInternal;

if isKeyFrame
    % Refine camera pose only if the current frame is a key frame
    currPose = bundleAdjustmentMotion(matchedMapPoints, matchedImagePoints, ...
        currPose, intrinsics, 'PointsUndistorted', true, ...
        'AbsoluteTolerance', 1e-7, 'RelativeTolerance', 1e-16,'MaxIteration', 20);
end
end

function [localPointsIndices, localKeyFrameIds, numPointsRefKeyFrame] = ...
    updateRefKeyFrameAndLocalPoints(mapPoints, vSetKeyFrames, pointIndices)

if vSetKeyFrames.NumViews == 1
    localKeyFrameIds = vSetKeyFrames.Views.ViewId;
    localPointsIndices = (1:mapPoints.Count)';
    numPointsRefKeyFrame = mapPoints.Count;
    return
end

% The reference key frame has the most covisible map points 
viewIds = findViewsOfWorldPoint(mapPoints, pointIndices);
refKeyFrameId = mode(vertcat(viewIds{:}));

localKeyFrames = connectedViews(vSetKeyFrames, refKeyFrameId, "MaxDistance", 2);
localKeyFrameIds = [localKeyFrames.ViewId; refKeyFrameId];

pointIdx = findWorldPointsInView(mapPoints, localKeyFrameIds);
if iscell(pointIdx)
    numPointsRefKeyFrame = numel(pointIdx{localKeyFrameIds==refKeyFrameId});
    localPointsIndices = sort(vertcat(pointIdx{:}));
else
    numPointsRefKeyFrame = numel(pointIdx);
    localPointsIndices = sort(pointIdx);
end
end

function features = getFeatures(mapPoints, views, mapPointIdx)

% Efficiently retrieve features and image points corresponding to map points
% denoted by mapPointIdx
allIndices = zeros(1, numel(mapPointIdx));

% ViewId and offset pair
count = []; % (ViewId, NumFeatures)
viewsFeatures = views.Features;

for i = 1:numel(mapPointIdx)
    index3d  = mapPointIdx(i);
    
    viewId   = double(mapPoints.RepresentativeViewId(index3d));
    
    if isempty(count)
        count = [viewId, size(viewsFeatures{viewId},1)];
    elseif ~any(count(:,1) == viewId)
        count = [count; viewId, size(viewsFeatures{viewId},1)];
    end
    
    idx = find(count(:,1)==viewId);
    
    if idx > 1
        offset = sum(count(1:idx-1,2));
    else
        offset = 0;
    end
    allIndices(i) = mapPoints.RepresentativeFeatureIndex(index3d) + offset;
end

uIds = count(:,1);

% Concatenating features and indexing once is faster than accessing via a for loop
allFeatures = vertcat(viewsFeatures{uIds});
features    = allFeatures(allIndices, :);
end

function [projectedPoints, inliers, predictedScales, viewAngles] = removeOutlierMapPoints(...
    mapPoints, pose, intrinsics, localPointsIndices, scaleFactor, ...
    numLevels)

% 1) Points within the image bounds
xyzPoints = mapPoints.WorldPoints(localPointsIndices, :);
[projectedPoints, isInImage] = world2img(xyzPoints, pose2extr(pose), intrinsics);

if isempty(projectedPoints)
    error('Tracking failed. Try inserting new key frames more frequently.')
end

% 2) Parallax less than 60 degrees
cameraNormVector = [0 0 1] * pose.Rotation;
cameraToPoints   = xyzPoints - pose.Translation;
viewDirection    = mapPoints.ViewingDirection(localPointsIndices, :);
validByView      = sum(viewDirection.*cameraToPoints, 2) > ...
    cosd(60)*(vecnorm(cameraToPoints, 2, 2));

% 3) Distance from map point to camera center is in the range of scale
% invariant depth
minDist          = mapPoints.DistanceLimits(localPointsIndices,1)/scaleFactor;
maxDist          = mapPoints.DistanceLimits(localPointsIndices,2)*scaleFactor;
dist             = vecnorm(xyzPoints - pose.Translation, 2, 2);

validByDistance  = dist > minDist & dist < maxDist;

inliers          = isInImage & validByView & validByDistance;

% Predicted scales
level= ceil(log(maxDist ./ dist)./log(scaleFactor));
level(level<0)   = 0;
level(level>=numLevels-1) = numLevels-1;
predictedScales  = scaleFactor.^level;

% View angles
viewAngles       = acosd(sum(cameraNormVector.*cameraToPoints, 2) ./ ...
    vecnorm(cameraToPoints, 2, 2));

predictedScales  = predictedScales(inliers);
viewAngles       = viewAngles(inliers);

projectedPoints = projectedPoints(inliers, :);
end

function isKeyFrame = checkKeyFrame(numPointsRefKeyFrame, lastKeyFrameIndex, ...
    currFrameIndex, mapPointsIndices, numSkipFrames, numPointsKeyFrame)

% More than numSkipFrames frames have passed from last key frame insertion
tooManyNonKeyFrames = currFrameIndex > lastKeyFrameIndex + numSkipFrames;

% Track less than numPointsKeyFrame map points
tooFewMapPoints     = numel(mapPointsIndices) < numPointsKeyFrame;

% Tracked map points are fewer than 90% of points tracked by
% the reference key frame
tooFewTrackedPoints = numel(mapPointsIndices) < 0.9 * numPointsRefKeyFrame;

isKeyFrame = (tooManyNonKeyFrames || tooFewMapPoints) && tooFewTrackedPoints;
end