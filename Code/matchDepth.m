% Matches real image with simulated images at different depths.

clear; 
close all;
ieInit;

wave = 400:10:700;
[codePath, parentPath] = uwSimRootPath();

rtb4Folder = getpref('RenderToolbox4','workingFolder');
renderingsFolder  = fullfile(rtb4Folder,'UnderwaterChart','renderings','PBRT');
imagesFolder = fullfile(parentPath,'Images','Underwater','02');

depth_m = 0:20; % m

%% Create a Canon G7X camera model
fName = fullfile(parentPath,'Parameters','CanonG7X');
transmissivities = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',transmissivities);
sensor = sensorSet(sensor,'name','Canon G7X');
sensor = sensorSet(sensor,'noise flag',0);

%% Load simulated images

simulatedRGB = cell(1,length(depth_m));

for d = 1:length(depth_m)
    oiFilePath = fullfile(renderingsFolder,sprintf('UnderwaterChart_1.00_%0.2f_0.00_0.00_0.00_0.00.mat',depth_m(d)));
    data = load(oiFilePath);
    [rgbImageSimulated, avgMacbeth] = simulateCamera(data.oi,sensor);
    simulatedRGB{d} = avgMacbeth;
end


%% Load real images

fNames = getFilenames(imagesFolder, 'CR2$');
nFiles = length(fNames);

measuredRGB = cell(1,nFiles);
imageNames = cell(1,nFiles);
meta = cell(1,nFiles);

for i = 1:nFiles
    
    rawCameraFilePath = fNames{i};
    [~, imageNames{i}, ext] = fileparts(rawCameraFilePath);
    [realSensor, cp, ~, meta{i}] = readCameraImage(rawCameraFilePath, sensor);
    
    vcAddObject(realSensor);
    sensorWindow();
    
    realIp = ipCreate;
    realIp = ipSet(realIp,'name','Canon G7X');
    realIp = ipCompute(realIp,realSensor);
    
    vcAddObject(realIp);
    ipWindow();
    
    data = macbethSelect(realSensor,1,1,cp);
    avg = cell2mat(cellfun(@nanmean,data,'UniformOutput',false)');
    
    measuredRGB{i} = avg;
end

%% For every real image, match with the simulated values
nReal = size(measuredRGB,2);
nSim = size(simulatedRGB,2);

for m = 1:size(measuredRGB,2)

     RMS = zeros(nSim,1);

     for s = 1:nSim
         RMS(s) = rms(rms(measuredRGB{m} - simulatedRGB{s}));
     end

     [~, minIndex] = min(RMS);
     
     figure;
     hold on; grid on; box on;
     plot(measuredRGB{m},simulatedRGB{minIndex},'o');
     xlabel('Measured');
     ylabel('Simulated');
     title(imageNames{m},'interpreter','none');

     fprintf('%s: depth: %s (measured) %.2f (estimated)\n',imageNames{m},...
         meta{m}.depth.Text,depth_m(minIndex));
end

