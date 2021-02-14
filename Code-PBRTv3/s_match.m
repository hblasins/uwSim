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

for i = 1:1 %nFiles
    
    
    rawCameraCalibrtionFilePath = fullfile(parentPath,calibfNames{i});
    [realSensor, ~, ~, ~, meta{i}, sensorMacbeth] = readCameraImage(rawCameraCalibrtionFilePath, sensor);
    ieAddObject(realSensor);
    sensorWindow();
    
    avg = cell2mat(cellfun(@meannan,sensorMacbeth,'UniformOutput',false)');
    surfaceRGB = avg';
    
    data = load(fullfile(dataPath,'CanonImages-Vol2','macbethChart_Canon.mat'));
    simSurfaceRGB = cell2mat(cellfun(@nanmean,data.sensorValues,'UniformOutput',false));
    simSurfaceRGB = reshape(simSurfaceRGB,[3 24]);
    
    cvx_begin
        variables R(3,3) o(1)
        minimize norm(simSurfaceRGB - (R*surfaceRGB + o))
    cvx_end
    
    corr = R*surfaceRGB + o;
    
    figure; 
    hold on; grid on; box on;
    plot(simSurfaceRGB, corr, '.');
    
    
    % Read the sensor data
    rawCameraFilePath = fullfile(parentPath,fNames{i});
    [~, imageName, ext] = fileparts(rawCameraFilePath);
    
    [realSensor, realISP, cp, ~, meta{i}, sensorMacbeth, ispMacbeth] = readCameraImage(rawCameraFilePath, sensor, 'ccm', R');
    
    ieAddObject(realSensor);
    sensorWindow();
    
    ieAddObject(realISP);
    ipWindow();
       
    img = macbethSamplesToImage(ispMacbeth, 'patchSize', 200);
    img = img/max(img(:));
    figure; imshow(img);

    
    avg = cell2mat(cellfun(@meannan,sensorMacbeth,'UniformOutput',false)');
    measuredRGB{i} = avg;
    
    corrRGB = R*avg' + o;
    
    % Match in the least squares sense.
    meas = max(corrRGB,0);
    meas = meas(:) / max(meas(:));
    % meas = meas(:);
    
    indices = 1:size(simulated.data,1);
    simData = simulated.data(indices,:)';
    
    
    normData = simData ./ repmat(max(simData,[],1),[24 * 3, 1]);
    % normData = simData;
    
    alpha = zeros(size(normData,2),1);
    for a=1:size(normData,2)
        alpha(a) = normData(:,a) \ meas;
    end
    
    err = (meas ./ (alpha') - normData ).^2;
    err = sum(err,1);
    
    [sortedErr, sortedMatch] = sort(err,'ascend');
    minErr = sortedErr(1);
    bestMatch = sortedMatch(1);
   
    match.alpha = alpha(bestMatch);
    match.values = normData(:,bestMatch);
    match.minErr = minErr;
    match.id = bestMatch;
    match.fileName = simulated.filename{indices(bestMatch)};
    match.properties = simulated.properties(indices(bestMatch),:);
    
    
    allMatches{i} = match;
    
    figure;
    hold on; grid on; box on;
    meas = reshape(meas,[3 24]);
    est =  reshape(match.values * match.alpha, [3 24]);
    plot(meas,est,'x','markersize',5);
    
    simData = load(fullfile(dataPath,'CanonImages-Vol2',match.fileName));
    
    ispImage = macbethSamplesToImage(simData.ispValues, 'patchSize', 200);
    ispImage = ispImage / max(ispImage(:));
    figure; imshow(ispImage);
end


