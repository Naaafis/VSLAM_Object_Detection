classdef helperVisualizeMatchedFeaturesRGBD < handle
%helperVisualizeMatchedFeaturesRGBD show the matched features in a frame
%
%   This is an example helper class that is subject to change or removal 
%   in future releases.

%   Copyright 2021 The MathWorks, Inc.

    properties (Access = private)
        Image
        
        Feature
    end
    
    methods (Access = public)
        
        function obj = helperVisualizeMatchedFeaturesRGBD(I1, I2, points)
            
            % Plot image
            hFig  = figure;
            hAxes = newplot(hFig); 
            
            % Set figure visibility and position
            hFig.Visible = 'on';
            movegui(hFig, [200 200]);
            
            % Show the image and features
            obj.Image = showMatchedFeatures(I1, I2, points, ...
                points, 'montage', 'Parent', hAxes, ...
                'PlotOptions', {'g+','g+',''});
            title(hAxes, 'Matched Features in Current Frame');
            hold(hAxes, 'on');
            
            obj.Feature = findobj(hAxes.Parent,'Type','Line'); 
        end 
        
        function updatePlot(obj, I1, I2, points)
            
            % Color and depth image
            obj.Image.CData = imfuse(I1, I2, 'montage');
            
            % Connecting lines
            obj.Feature(1).XData = NaN;
            obj.Feature(1).YData = NaN;
            
            % Right image
            obj.Feature(2).XData = points.Location(:,1) + size(I1, 2);
            obj.Feature(2).YData = points.Location(:,2);
            
            % Left image
            obj.Feature(3).XData = points.Location(:,1);
            obj.Feature(3).YData = points.Location(:,2);
            drawnow limitrate
        end
    end
end