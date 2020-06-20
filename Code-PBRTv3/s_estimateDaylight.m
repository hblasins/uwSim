%% Extract sensor RGB pixel intensities of real and simulated Macbeth chart.
% 
% This script loads the simulated underwater Macbeth chart radiance images  
% projected onto the sensor and computes the RAW sensor pixel intensities
% for each of the 24 chart patches. 
%
% We perform the same operation (i.e. sample 24 Macbeth chart patches) on a
% subset of images captured with real camera in underwater environments.
%
% Copyright, Henryk Blasinski 2017
%% Initialize and find folders for reading/writing

ieInit;
wave = 400:10:700;
[codePath, parentPath] = uwSimRootPath();

dataPath = fullfile(parentPath,'NewResults');
simulated = load(fullfile(dataPath,'aggregateSim-Vol2.mat'));


%% Load raw underwater images and sample the Macbeth chart.

fName = fullfile(parentPath,'Parameters','CanonG7X');
transmissivities = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',transmissivities);
sensor = sensorSet(sensor,'name','Canon G7X');
sensor = sensorSet(sensor,'noise flag',0);

% OR we manually select three images we'd like to match
fNames = {fullfile('Images','Underwater','07','IMG_4900.CR2'),...
          fullfile('Images','Underwater','12','IMG_7092.CR2'),...
          fullfile('Images','Underwater','10','IMG_6327.CR2')};
      
calibfNames = {fullfile('Images','Surface','07','IMG_4329.CR2'),...
               fullfile('Images','Surface','12','IMG_7045.CR2'),...
               fullfile('Images','Surface','10','IMG_6234.CR2')};
           
nFiles = length(fNames);

measuredRGB = cell(1,nFiles);
meta = cell(1,nFiles);

allMatches = cell(1,nFiles);

dayBasis = ieReadSpectra('cieDaylightBasis.mat',wave); 
dayBasis = Energy2Quanta(wave,dayBasis);
dayBasis = dayBasis/max(dayBasis(:));

wave = 400:10:700;
reflectance = macbethReadReflectance(wave);

d65 = illuminantCreate('d65',wave);
d65 = illuminantGet(d65,'photons');
d65 = d65/max(d65);

for i = 1:nFiles
    
    
    rawCameraCalibrtionFilePath = fullfile(parentPath,calibfNames{i});
    [realSensor, ~, ~, ~, meta{i}, sensorMacbeth] = readCameraImage(rawCameraCalibrtionFilePath, sensor);
    ieAddObject(realSensor);
    sensorWindow();
    
    avg = cell2mat(cellfun(@meannan,sensorMacbeth,'UniformOutput',false)')';
    
    cvx_begin
        variables wghts(3,1) offset(1,1)
        minimize norm(avg - offset - transmissivities'*diag(dayBasis * wghts)*reflectance,'fro')
        subject to
            dayBasis * wghts >= 0
    cvx_end
    
    illEst = dayBasis * wghts;
    illEst = illEst/max(illEst(:));
    
    figure;
    hold on; grid on; box on;
    plot([d65(:) illEst(:)]);
    legend('D65','Estimate');
    
    
end


