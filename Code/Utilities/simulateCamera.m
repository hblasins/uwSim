function [rgbImageSimulated, avgSimulated] = simulateCamera(oi,sensor,varargin)
% SIMULATECAMERA
%
% Loads a MAT-file containing an optical image (OI) that was saved by
% "renderUnderwaterChart.m." 
%  
% It then runs calculates the sensor response and carries out the image
% processing operations (ip).
%
% The function returns a cell array, with each cell containing an RGB image
% of the processed chart and a matrix that contains the average RGB of each
% square in the chart. The returned values are used for plotting the
% average RGB values using imshow(cell2mat(xxx)).
%
% See also:  extractMatches.m, renderUnderWaterChart.m 
%
% HB, SCIEN STANFORD TEAM, 2017

%%
p = inputParser;
p.addOptional('cp',[22 214; 299 215; 299 26; 21 31]);
p.parse(varargin{:});
inputs = p.Results;

%%
illum = 15;
oi = oiAdjustIlluminance(oi,illum);
ieAddObject(oi);

sensor = sensorSet(sensor,'size',oiGet(oi,'size'));

% HB:  Ask whether to use this or the original, below
sensor = sensorSet(sensor,'pixel size same fill factor',oiGet(oi,'hres'));

% HB's original changes the size and the fill factor.  We replaced with the
% code above to preserve the fill fact. (JEF/BW).
% sensor = sensorSet(sensor,'pixel width and height',[oiGet(oi,'hres'), oiGet(oi,'wres')]);
sensor = sensorCompute(sensor,oi);
ieAddObject(sensor);

data = macbethSelect(sensor,0,1,inputs.cp);
avgSimulated = cell2mat(cellfun(@meannan,data,'UniformOutput',false)');

% expTime = sensorGet(sensor,'exposure time');
% fprintf('Auto-exposure set exposure time to: %0.2f \n',expTime);

ip = ipCreate;
ip = ipSet(ip,'demosaic method','bilinear');
ip = ipSet(ip,'correction method illuminant','none');
ip = ipCompute(ip,sensor);
vcAddObject(ip);

% Uncomment these lines to see the results.
% oiWindow;
% sensorWindow;
% ipWindow;

rgbImageSimulated = ipGet(ip,'data srgb');


end

