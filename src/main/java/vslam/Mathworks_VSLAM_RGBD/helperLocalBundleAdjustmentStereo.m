function [mapPoints, vSetKeyFrames, newPointIdx, stereoMapPointsIndices] = helperLocalBundleAdjustmentStereo(mapPoints, ...
    vSetKeyFrames, currKeyFrameId, intrinsics, newPointIdx, stereoMapPointsIndices)
%helperLocalBundleAdjustmentStereo refine the pose of the current key frame and 
%   the map of the surrrounding scene.
%
%   This is an example helper function that is subject to change or removal 
%   in future releases.

%   Copyright 2020-2022 The MathWorks, Inc.

if currKeyFrameId > 2

    [refinedViews, dist] = connectedViews(vSetKeyFrames, currKeyFrameId, MaxDistance=2);
    refinedKeyFrameIds = refinedViews.ViewId;

    % Always fix the first two key frames
    fixedViewIds = refinedKeyFrameIds(dist==2);
    fixedViewIds = fixedViewIds(1:min(10, numel(fixedViewIds)));

    % Always fix the first two key frames
    fixedViewIds = [fixedViewIds; intersect(refinedKeyFrameIds, [1 2])];

    refinedKeyFrameIds = [refinedKeyFrameIds; currKeyFrameId];

else
    refinedKeyFrameIds = [1 2];
    fixedViewIds = 1;
end

% Refine local key frames and map points
[mapPoints, vSetKeyFrames, mapPointIdx, reprojectionErrors] = bundleAdjustment(...
    mapPoints, vSetKeyFrames, refinedKeyFrameIds, intrinsics, 'FixedViewIDs', fixedViewIds, ...
    'PointsUndistorted', true, 'AbsoluteTolerance', 1e-7,...
    'RelativeTolerance', 1e-16, 'Solver', 'preconditioned-conjugate-gradient', ...
    'MaxIteration', 10);

maxError    = 6;
isInlier    = reprojectionErrors < maxError;
outlierIdx  = mapPointIdx(~isInlier);
newPointIdx = setdiff(newPointIdx, outlierIdx);

% Update map points and key frames
if ~isempty(outlierIdx)
    mapPoints = removeWorldPoints(mapPoints, outlierIdx);
end

newPointIdx = newPointIdx - arrayfun(@(x) nnz(x>outlierIdx), newPointIdx);
stereoMapPointsIndices = stereoMapPointsIndices - arrayfun(@(x) nnz(x>outlierIdx), stereoMapPointsIndices);
end