function extractPointsByViewId(viewId, worldPointSet)
    % Define directories and file paths
    % keyFramesDir = './KeyFrames';
    keyFramePointsDir = './KeyFramePoints';

    % Construct filename for the image
    % imageFilename = sprintf('%s/KeyFrame_%04d.png', keyFramesDir, viewId);
    
    % Load and display the image
    % currImage = imread(imageFilename);
    % figure;
    % imshow(currImage);
    % title(['Image for View ID: ', num2str(viewId)]);
    % hold on;

    % Load corresponding CSV file for world point indices and pixel locations
    csvFilename = sprintf('%s/KeyFramePoints_%04d.csv', keyFramePointsDir, viewId);
    dataMatrix = readmatrix(csvFilename);

    % Extract pixel locations and indices of world points
    % pixelLocations = dataMatrix(:, 1:2); % Assuming first two columns are pixel X, Y
    mapPointsIdx = dataMatrix(:, 3);     % Assuming third column is mapPointsIdx

    % Extract world points using the indices
    worldPoints = worldPointSet.WorldPoints(mapPointsIdx, :);

    % Append world points to the CSV
    updatedDataMatrix = [dataMatrix, worldPoints]; % Concatenate world points
    writematrix(updatedDataMatrix, csvFilename);   % Write it back

    % % Overlay features on the image
    % plot(pixelLocations(:,1), pixelLocations(:,2), 'yo', 'MarkerSize', 5, 'LineWidth', 2);
    % 
    % % Optionally save or display the image
    % figure;
    % imshow(currImage);
    % hold on;
    % plot(pixelLocations(:,1), pixelLocations(:,2), 'yo', 'MarkerSize', 5, 'LineWidth', 2);
    % title('Features Overlayed on Image');
end

