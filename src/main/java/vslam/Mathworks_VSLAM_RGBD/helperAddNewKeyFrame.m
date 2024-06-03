function [mapPoints, vSetKeyFrames] = helperAddNewKeyFrame(mapPoints, vSetKeyFrames,...
    cameraPose, currFeatures, currPoints, mapPointsIndices, featureIndices, keyFramesIndices)
%helperAddNewKeyFrame add key frames to the key frame set
%
%   This is an example helper function that is subject to change or removal
%   in future releases.

%   Copyright 2019-2023 The MathWorks, Inc.
%#codegen

viewId = vSetKeyFrames.Views.ViewId(end)+1;

vSetKeyFrames = addView(vSetKeyFrames, viewId, cameraPose,...
    'Features', currFeatures.Features, ...
    'Points', currPoints);

viewsAbsPoses = vSetKeyFrames.Views.AbsolutePose;

for i = 1:numel(keyFramesIndices)
    localKeyFrameId = keyFramesIndices(i);
    if isSimMode()
        [index3d, index2d] = findWorldPointsInView(mapPoints, localKeyFrameId);
    else
        [index3dCg, index2dCg] = findWorldPointsInView(mapPoints, localKeyFrameId);
        index3d = index3dCg{1};
        index2d = index2dCg{1};
    end
    [~, ia, ib] = intersect(index3d, mapPointsIndices, 'stable');

    prePose   = viewsAbsPoses(localKeyFrameId);
    relPose = rigidtform3d(prePose.R' * cameraPose.R, ...
        (cameraPose.Translation-prePose.Translation)*prePose.R);

    if numel(ia) > 5
        if isSimMode()
            vSetKeyFrames = addConnection(vSetKeyFrames, localKeyFrameId, viewId, relPose, ...
                'Matches', [index2d(ia),featureIndices(ib)]);
        else
            coder.varsize('matches', [inf 2], [1, 0]);
            fIndices = featureIndices(ib(:));
            matches = [index2d(ia), fIndices];
            vSetKeyFrames = addConnection(vSetKeyFrames, localKeyFrameId, viewId, relPose, ...
                'Matches', matches);
        end
    end
end

mapPoints = addCorrespondences(mapPoints, viewId, mapPointsIndices, ...
    featureIndices);
end

function tf = isSimMode()
    tf = isempty(coder.target);
end