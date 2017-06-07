% This function loads the MAT object containing an OI that is saved from
% "renderUnderwaterChart.m." It then runs it through the sensor and ip
% simulation and returns a cell matrix that contains an RGB image of the
% processed chart, along with a cell matrix that contains the average RGB
% of each square in the chart. This cell matrix is primarily used for
% plotting the average RGB values using imshow(cell2mat(xxx)).

function [rgbImageSimulated, rgbAverageCell] = processSimulatedMat(oiFilePath)

% --------------------------------
% --- CHANGE THIS FOR FILTERS ----
wave = 400:10:700;
fName = fullfile('.','Canon1DMarkIII');
camera = ieReadColorFilter(wave,fName);
% --------------------------------
% --------------------------------

% Here we simulate the sensor of the Canon Powershot G7X using ISET
% commands. See ISET documentation for more information on these
% simulations commands.

load(oiFilePath);

if(~(exist('oi','var')))
    error('OI object does not exist in .mat file.')
end

illum = 15;
oi = oiAdjustIlluminance(oi,illum);
ieAddObject(oi);

sensorSimulated = sensorCreate('bayer (gbrg)');
sensorSimulated = sensorSet(sensorSimulated,'filter transmissivities',camera);
sensorSimulated = sensorSet(sensorSimulated,'volts',oi);
sensorSimulated = sensorSet(sensorSimulated,'name','Canon');
sensorSimulated = sensorSet(sensorSimulated,'size',[size(oi.data.photons,1), size(oi.data.photons,2)]);
sensorSimulated = sensorSet(sensorSimulated,'pixel widthandheight',[oiGet(oi,'hres'), oiGet(oi,'wres')]);

sensorSimulated = sensorSet(sensorSimulated,'name',oiGet(oi,'name'));
sensorSimulated = sensorSet(sensorSimulated,'noise flag',0);

sensorSimulated = sensorCompute(sensorSimulated,oi);

expTime = sensorGet(sensorSimulated,'exposure time');
fprintf('Auto-exposure set exposure time to: %0.2f',expTime);

ipSimulated = ipCreate;
ipSimulated = ipSet(ipSimulated,'demosaic method','bilinear');
ipSimulated = ipSet(ipSimulated,'correction method illuminant','none');

ipSimulated = ipCompute(ipSimulated,sensorSimulated);

vcAddObject(ipSimulated);
ipWindow;

% Show in a separate window
rgbImageSimulated = ipGet(ipSimulated,'data srgb');
% vcNewGraphWin; image(rgbSimulated); axis image; axis off

% Display the sensor data
vcAddObject(sensorSimulated);
sensorWindow;

% Select the center of each macbeth path. The following values were
% calculated for a 320x240 resolution image.
if(size(oi.data.photons,1) == 320 && size(oi.data.photons,2) == 240)
    cp_sim = [22   214;
        299   215;
        299    26;
        21    31];
    % Take the mean of the RGB values around the center of each patch,
    [data, mLocs, psize, cp_sim] = ...
        macbethSelect(sensorSimulated,1,1,cp_sim);
else
    warning('OI size doesn''t match the saved Macbeth chart points. Please reselect...')
        % Take the mean of the RGB values around the center of each patch,
    [data, mLocs, psize, cp_sim] = ...
        macbethSelect(sensorSimulated,1,1);
    cp_sim
end

avgSimulated = cellfun(@nanmean,data,'UniformOutput',false);

% Rearrange the mean values into a 4x6 cell matrix with 21x21 value
% patches for easier viewing and processing. This way it is less likely
% we get indices mixed up when comparing charts and we can display the
% chart as an image directly, using cell2mat.
rgbAverageCell = cell(4,6);
for yy = 1:4
    for xx = 1:6
        id = (xx-1)*4 + (4-yy)+1;
        currRGB = avgSimulated{id};
        currRGB = reshape(currRGB,[1 1 3]);
        rgbAverageCell{yy,xx} = repmat(currRGB,[21 21 1]);
    end
end

end

