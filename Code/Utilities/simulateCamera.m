% This function loads the MAT object containing an OI that is saved from
% "renderUnderwaterChart.m." It then runs it through the sensor and ip
% simulation and returns a cell matrix that contains an RGB image of the
% processed chart, along with a cell matrix that contains the average RGB
% of each square in the chart. This cell matrix is primarily used for
% plotting the average RGB values using imshow(cell2mat(xxx)).

function [rgbImageSimulated, avgSimulated] = simulateCamera(oi,sensor,varargin)

p = inputParser;
p.addOptional('cp',[22 214; 299 215; 299 26; 21 31]);
p.parse(varargin{:});
inputs = p.Results;


illum = 15;
oi = oiAdjustIlluminance(oi,illum);
ieAddObject(oi);

sensor = sensorSet(sensor,'size',oiGet(oi,'size'));
sensor = sensorSet(sensor,'pixel widthandheight',[oiGet(oi,'hres'), oiGet(oi,'wres')]);
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

