function camPoses = helperImportGroundTruth(fileName, imds)
%helperImportGroundTruth Import ground truth camera poses from a .txt file
%
%   This is an example helper function that is subject to change or removal 
%   in future releases.
%
%   Copyright 2023 The MathWorks Inc.

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 9);

% Specify range and delimiter
opts.DataLines = [4, Inf];
opts.Delimiter = " ";

% Specify column names and types
opts.VariableNames = ["timestamp", "tx", "ty", "tz", "qx", "qy", "qz", "qw", "Var9"];
opts.SelectedVariableNames = ["timestamp", "tx", "ty", "tz", "qx", "qy", "qz", "qw"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";

% Specify variable properties
opts = setvaropts(opts, "Var9", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Var9", "EmptyFieldRule", "auto");

% Import the data
groundtruth = readtable(fileName, opts);

% Initialize the output
camPoses = repmat(rigidtform3d, 1, numel(imds.Files));

firstT = [groundtruth(1,:).tx groundtruth(1,:).ty groundtruth(1,:).tz];
firstR = quat2rotm([groundtruth(1,:).qw groundtruth(1,:).qx groundtruth(1,:).qy groundtruth(1,:).qz]);

% Find the ground truth data corresponding to the image based on the timestamp 
[~,imageTS] = fileparts(imds.Files);
imgTimestamp = str2double(imageTS);
index = interp1(groundtruth.timestamp, 1:numel(groundtruth.timestamp), imgTimestamp, 'nearest', 'extrap');

for i=1:numel(imds.Files)
    groundtruth_raw = groundtruth(index(i),:);

    % Transform all the camera poses to the coordinate system of the first camera
    % Rotation
    q = [groundtruth_raw.qw groundtruth_raw.qx groundtruth_raw.qy groundtruth_raw.qz];
    camPoses(i).R = firstR'*quat2rotm(q);
    
    % Translation
    camPoses(i).Translation = ([groundtruth_raw.tx groundtruth_raw.ty groundtruth_raw.tz]-firstT) * firstR;
end
end

