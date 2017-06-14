% Matches real image with simulated images at different depths.

clear; 
close all;
ieInit;

wave = 400:10:700;
[codePath, parentPath] = uwSimRootPath();

% rtb4Folder = getpref('RenderToolbox4','workingFolder');
% renderingsFolder  = fullfile(rtb4Folder,'UnderwaterChart','renderings','PBRT');

renderingsFolder = fullfile(parentPath,'Results','All');
imagesFolder = fullfile(parentPath,'Images','Underwater');
resultFolder = fullfile(parentPath,'Results','Matching');
if ~exist(resultFolder,'dir'), mkdir(resultFolder); end

%% Rendering parameters

cameraDistance = 1000;

depth = linspace(1,20,10)*10^3; % mm
chlorophyll = logspace(-2,0,5);
dom = logspace(-2,0,5);

smallParticleConc = 0.0;
largeParticleConc = 0.0;

[depthV, chlV, cdomV, spV, lpV] = ndgrid(depth, chlorophyll, dom,...
    smallParticleConc,...
    largeParticleConc);

%% Create a Canon G7X camera model
fName = fullfile(parentPath,'Parameters','CanonG7X');
transmissivities = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',transmissivities);
sensor = sensorSet(sensor,'name','Canon G7X');
sensor = sensorSet(sensor,'noise flag',0);

%% Load simulated images

simulatedRGB = cell(1,numel(depthV));

for d = 1:numel(depthV)
    
    fName = sprintf('UnderwaterChart-All_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f.mat', ...
        cameraDistance/10^3, ...
        depthV(d)/10^3, ...
        chlV(d), ...
        cdomV(d), ...
        spV(d), ...
        lpV(d));
    
    oiFilePath = fullfile(renderingsFolder,fName);
    data = load(oiFilePath);
    [rgbImageSimulated, avgMacbeth] = simulateCamera(data.oi,sensor);
    simulatedRGB{d} = avgMacbeth;
end

fName = fullfile(parentPath,'Results','Matching','simulatedRGB.mat');
save(fName,'simulatedRGB','depthV','chlV','cdomV','spV','lpV');

%% Load real images

% We can get all the images in a particular folder
% fNames = getFilenames(imagesFolder, 'CR2$');

% OR we manually select three images we'd like to match
fNames = {fullfile(imagesFolder,'07','IMG_4900.CR2'),...
          fullfile(imagesFolder,'12','IMG_7092.CR2'),...
          fullfile(imagesFolder,'10','IMG_6327.CR2')};

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

fName = fullfile(parentPath,'Results','Matching','measuredRGB.mat');
save(fName,'measuredRGB','imageNames','fNames','meta');

%% For every real image, match with the simulated values
nReal = size(measuredRGB,2);
nSim = size(simulatedRGB,2);

for m = 1:size(measuredRGB,2)

     [~, imgName] = fileparts(fNames{m});
     [realSensor, cp, ~, meta{i}] = readCameraImage(fNames{m}, sensor);
    
     error = zeros(nSim,1);
     for s = 1:nSim
         
         % We allow for an unknown scaling between the simulated and
         % measured data.
         cvx_begin quiet
            variable a
            minimize norm(measuredRGB{m}(:)*a - simulatedRGB{s}(:))
            subject to
                a>=0
         cvx_end
         
         
         error(s) = norm(measuredRGB{m}(:)*a - simulatedRGB{s}(:));
     end

     [~, minIndex] = min(error);
     
     % Display results
     
     figure;
     subplot(1,3,1);
     hold on; grid on; box on;
     plot(measuredRGB{m},simulatedRGB{minIndex},'o');
     xlabel('Measured');
     ylabel('Simulated');
     title(imageNames{m},'interpreter','none');

     subplot(1,3,2);
     measImg = reshape(measuredRGB{m},[4 6 3]);
     measImg = measImg/max(measImg(:));
     measImg = imresize(measImg,100,'nearest');
     imshow(measImg);
     title('Measured');
     
     subplot(1,3,3);
     simImg = reshape(simulatedRGB{minIndex},[4 6 3]);
     simImg = simImg/max(simImg(:));
     simImg = imresize(simImg,100,'nearest');
     imshow(simImg);
     title('Simulated');
     
     fprintf('%s: depth: %s (measured) %.2f (estimated): chlC %.2f: cdomC %.2f\n',imageNames{m},...
         meta{m}.depth.Text,depthV(minIndex)/1000,chlV(minIndex),cdomV(minIndex));
     
     % Save images and results
     
     ip = ipCompute(ipCreate,realSensor);
     img = ipGet(ip,'sensor channels');
     img = img/max(img(:));
     fName = fullfile(resultFolder,sprintf('%s.png',imgName));
     imwrite(img,fName);
     
     fName = fullfile(resultFolder,sprintf('%s_sim.png',imgName));
     imwrite(simImg,fName);
     
     fName = fullfile(resultFolder,sprintf('%s_meas.png',imgName));
     imwrite(measImg,fName);
     
     measRGB = measuredRGB{m};
     simRGB = simulatedRGB{minIndex};
     chlC = chlV(minIndex);
     depth = depthV(minIndex);
     cdomC = cdomV(minIndex);
     metadata = meta{m};
     
     fName = fullfile(resultFolder,sprintf('%s_result.mat',imgName));
     save(fName,'measRGB','simRGB','chlC','depth','cdomC','metadata');
     
     
end

