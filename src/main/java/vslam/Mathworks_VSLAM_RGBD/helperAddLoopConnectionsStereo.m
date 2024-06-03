function [isLoopClosed, mapPoints, vSetKeyFrames] = helperAddLoopConnectionsStereo(...
    mapPoints, vSetKeyFrames, loopCandidates, currKeyFrameId, currFeatures, ...
    currPoints, loopEdgeNumMatches, varargin)
%helperAddLoopConnectionsStereo add connections between the current key frame and
%   the valid loop candidate key frames. A loop candidate is valid if it has
%   enough covisible map points with the current key frame.

%   This is an example helper function that is subject to change or removal
%   in future releases.

%   Copyright 2019-2022 The MathWorks, Inc.

if nargin > 7
    maxDistance = varargin{1};
else
    maxDistance = 4;
end

loopClosureEdge = [];

numCandidates   = size(loopCandidates,2);
[index3d1, index2d1] = findWorldPointsInView(mapPoints, currKeyFrameId);
validFeatures1  = currFeatures.Features(index2d1, :);
validPoints1    = currPoints(index2d1, :);

for k = 1 : numCandidates
    [index3d2, index2d2] = findWorldPointsInView(mapPoints, loopCandidates(k));
    allFeatures2   = vSetKeyFrames.Views.Features{loopCandidates(k)};
    allPoints2     = vSetKeyFrames.Views.Points{loopCandidates(k)};
    validFeatures2 = allFeatures2(index2d2, :);
    validPoints2   = allPoints2(index2d2, :);
    
    indexPairs = matchFeatures(binaryFeatures(validFeatures1), binaryFeatures(validFeatures2), ...
        'Unique', true, 'MaxRatio', 0.9, 'MatchThreshold', 40);
    
    % Orientation consistency check
    orientation1 = validPoints1.Orientation(indexPairs(:,1));
    orientation2 = validPoints2.Orientation(indexPairs(:,2));
    [N, ~, bin] = histcounts(abs(orientation1 - orientation2), 0:pi/30:2*pi);
    [~, ia] = maxk(N, 3); % Select the top 3 bins
    isConsistent = ismember(bin, ia);

    indexPairs = indexPairs(isConsistent, :);

    % Check if all the candidate key frames have strong connection with the
    % current keyframe
    if size(indexPairs, 1) < loopEdgeNumMatches
        continue
    end
    
    % Estimate the relative pose of the current key frame with respect to the
    % loop candidate keyframe with the highest similarity score
    
    worldPoints1 = mapPoints.WorldPoints(index3d1(indexPairs(:, 1)), :);
    worldPoints2 = mapPoints.WorldPoints(index3d2(indexPairs(:, 2)), :);

    tform1 = pose2extr(vSetKeyFrames.Views.AbsolutePose(end));
    tform2 = pose2extr(vSetKeyFrames.Views.AbsolutePose(loopCandidates(k)));

    worldPoints1InCamera1 = transformPointsForward(tform1, worldPoints1); 
    worldPoints2InCamera2 = transformPointsForward(tform2, worldPoints2); 
    
    w = warning('off','all');
    [tform, inlierIndex] = estgeotform3d(worldPoints1InCamera1, ...
        worldPoints2InCamera2, 'rigid', 'MaxNumTrials', 1e4, 'MaxDistance', maxDistance);
    warning(w);

    % Add connection between the current key frame and the loop key frame
    matches = uint32([index2d2(indexPairs(inlierIndex, 2)), index2d1(indexPairs(inlierIndex, 1))]);
    vSetKeyFrames = addConnection(vSetKeyFrames, loopCandidates(k), currKeyFrameId, tform, 'Matches', matches);
    disp(['Loop edge added between keyframe: ', num2str(loopCandidates(k)), ' and ', num2str(currKeyFrameId)]);
    
    % Fuse co-visible map points
    matchedIndex3d1 = index3d1(indexPairs(inlierIndex, 1));
    matchedIndex3d2 = index3d2(indexPairs(inlierIndex, 2));
    mapPoints = updateWorldPoints(mapPoints, matchedIndex3d1, mapPoints.WorldPoints(matchedIndex3d2, :));
    
    loopClosureEdge = [loopClosureEdge; loopCandidates(k), currKeyFrameId];
end
isLoopClosed = ~isempty(loopClosureEdge);
end