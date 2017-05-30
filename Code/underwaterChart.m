%% Simulate and compare with real images
% Render simulated underwater images with parameters and compare RGB values
% with images taken in the Carribean. 

% Trisha Lian

%% Initialize
clear all; 
close all; 
clc;

ieInit;


%% Choose renderer options
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.recipeName = 'UnderwaterChart'; % Name of the render
hints.renderer = 'PBRT'; % We're only using PBRT right now
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% Change the docker container
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @underwaterMexximpRemodeller;
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @underwaterPBRTRemodeller;
hints.batchRenderStrategy.converter.rewriteMeshData = false;

resourceFolder = rtbWorkingFolder('folderName','resources',...
                                  'rendererSpecific',false,...
                                  'hints',hints);
                              
%% Load scene

parentSceneFile = fullfile(uwSimulationRootPath,'..','Scenes','underwaterRealisticBlackWalls.dae'); 
[scene, elements] = mexximpCleanImport(parentSceneFile,...
    'flipUVs',true,...
    'imagemagicImage','hblasins/imagemagic-docker',...
    'toReplace',{'jpg','png'},...
    'targetFormat','exr',...
    'workingFolder',resourceFolder);

% Add a camera
scene = mexximpCentralizeCamera(scene);

%% Make light spectrums

% Sunlight (aka distant light)
fName = fullfile(rtbRoot,'RenderData','D65.spd');
[wls,spd] = rtbReadSpectrum(fName);
spd = spd.*10^10;
rtbWriteSpectrumFile(wls, spd, fullfile(resourceFolder, 'DistantLight.spd')); 
        
% Macbeth cube reflectances
for i = 1:24
    macbethPath = fullfile(rtbRoot(),'RenderData','Macbeth-ColorChecker',sprintf('mccBabel-%i.spd',i));
    copyfile(macbethPath, rtbWorkingFolder('hints', hints)); 
end

%% Write conditions and generate scene files

% Build up condition vectors
% ---
%{
waterDepth =       [4 7 10 13 16 19   4 4 4 4   4 4 4 4   4   4 4  4].*10^3; % mm
chlorophyll =      [0 0  0  0  0  0   0 2 4 6   0 0 0 0   0   0 0  0];
dom =              [0 0  0  0  0  0   0 0 0 0   0 0.5 1 1.5   0   0 0  0];
smallParticleConc= [0 0  0  0  0  0   0 0 0 0   0 0 0 0   0 0.01 0.05 0.1];
largeParticleConc= [0 0  0  0  0  0   0 0 0 0   0 0 0 0   0 0.01 0.05 0.1];
%}
% ---

waterDepth = 6*10^3;
nConditions = length(waterDepth);

pixelSamples = ones(1,nConditions).*32;
volumeStepSize = ones(1,nConditions).*50;
cameraDistance = ones(1,nConditions).*1000; % mm

chlorophyll = ones(1,nConditions).*4.0;
dom = ones(1,nConditions).*0.0;
smallParticleConc = ones(1,nConditions).*0.01;
largeParticleConc = ones(1,nConditions).*0.01;

absorptionFiles = cell(nConditions,1);
scatteringFiles = cell(nConditions,1);
phaseFiles = cell(nConditions,1);

for i = 1:nConditions
    % Create absorption curve
    [sig_a, waves] = createAbsorptionCurve(chlorophyll(i),dom(i));
    absorptionFileName = sprintf('abs_%i.spd',i);
    rtbWriteSpectrumFile(waves, sig_a, fullfile(resourceFolder, absorptionFileName));
    
    % Create scattering curve and phase function
    [phase, sig_s, waves] = calculateScattering(smallParticleConc(i),largeParticleConc(i),'mode','default');
    scatteringFileName = sprintf('scat_%i.spd',i);
    rtbWriteSpectrumFile(waves,sig_s,fullfile(resourceFolder,scatteringFileName));
    phaseFileName = sprintf('phase_%i.txt',i);
    WritePhaseFile(waves,phase,fullfile(resourceFolder,phaseFileName));
    
    % Pass file names to conditions
    absorptionFiles{i} = absorptionFileName;
    scatteringFiles{i} = scatteringFileName;
    phaseFiles{i} = phaseFileName;
end

%% Create the conditions file

names = {'pixelSamples','cameraDistance','waterDepth','volumeStepSize', ...
    'absorptionFiles','scatteringFiles','phaseFiles'};

values = cell(nConditions, numel(names));
values(:,1) = num2cell(pixelSamples,1);
values(:,2) = num2cell(cameraDistance,1);
values(:,3) = num2cell(waterDepth,1);
values(:,4) = num2cell(volumeStepSize,1);
values(:,5) = absorptionFiles;
values(:,6) = scatteringFiles;
values(:,7) = phaseFiles;


% Write the parameters in a conditions file. 
conditionsFile = 'UnderwaterChartConditions.txt';
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, names, values);

% Make the PBRT scene file.
nativeSceneFiles = rtbMakeSceneFiles(scene,'hints', hints,'conditionsFile',conditionsPath);

%% Render!
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

%% View as an OI

renderingsFolder = rtbWorkingFolder('folderName', 'renderings',...
    'rendererSpecific',true,...
    'hints', hints);

% Load in rendered data
for i = 1:nConditions
    
    radianceData = load(radianceDataFiles{i});
    
    oiName = sprintf('%s_%i_%0.2f_%0.2f_%0.2f',hints.recipeName,waterDepth(i)/10^3,chlorophyll(i),dom(i),smallParticleConc(i));
    
    % Create an oi
    oi = oiCreate;
    oi = initDefaultSpectrum(oi);
    oi = oiSet(oi,'photons',radianceData.multispectralImage*radianceData.radiometricScaleFactor);
    oi = oiSet(oi,'name',oiName);
    
    vcAddAndSelectObject(oi);
    
    % Save oi
    fName = fullfile(renderingsFolder,strcat(oiName,'.mat'));
    depth = waterDepth(i);
    chlC = chlorophyll(i);
    cdomC = dom(i);
    smallPart = smallParticleConc(i);
    largePart = largeParticleConc(i);
    
    save(fName,'oi','depth','chlC','cdomC','smallPart','largePart');
        
end

oiWindow;

%% Run OI through a sensor/ip

sensorSimulated = cell(nConditions,1);
ipSimulated = cell(nConditions,1);
rgbSimulated = cell(nConditions,1);

for ii = 1:nConditions
    
    tmp = waterOi{ii};
    tmp.data.photons = tmp.data.photons*10e10;
    ieAddObject(tmp);
    
    wave = 400:10:700;
    fName = fullfile('.','Canon1DMarkIII');
    camera = ieReadColorFilter(wave,fName);
    
    sensorSim = sensorCreate('bayer (gbrg)');
    sensorSim = sensorSet(sensorSim,'filter transmissivities',camera);
    sensorSim = sensorSet(sensorSim,'volts',tmp);
    sensorSim = sensorSet(sensorSim,'name','Canon');
    sensorSim = sensorSet(sensorSim,'size',[hints.imageHeight, hints.imageWidth]);
    sensorSim = sensorSet(sensorSim,'pixel widthandheight',[oiGet(waterOi{1},'hres'), oiGet(waterOi{1},'wres')]);
    
    sensorSim = sensorSet(sensorSim,'name',oiGet(waterOi{ii},'name'));
    sensorSim = sensorSet(sensorSim,'noise flag',0);
%     sensor = sensorSet(sensor,'exp time',1/300);
    
    sensorSim = sensorCompute(sensorSim,tmp);
    sensorSimulated{ii} = sensorSim;
    
    expTime = sensorGet(sensorSim,'exposure time');
     
    ip = ipCreate;
    ip = ipSet(ip,'demosaic method','bilinear');
    ip = ipSet(ip,'correction method illuminant','none');
    
    ip = ipCompute(ip,sensorSim);
    ipSimulated{ii} = ip;
    
    vcAddObject(ip);
    ipWindow;
    
    % Show in a separate window
    rgbSimulated{ii} = ipGet(ip,'data srgb');
    vcNewGraphWin; image(rgbImages{ii}); axis image; axis off
end


%% Extract patches from simulated image

% For every rendered image...
for ii = 1:nConditions
    
    % Display the sensor data
     vcAddObject(sensorSimulated{ii}); 
     sensorWindow;
    
     % For 300x300 resolution rendering
    cp_sim = [49 219; 253 219; 252 83; 50 84];

    [data, mLocs, psize, cp_sim] = ...
    macbethSelect(sensorSimulated{ii},1,1,cp_sim);
    avgSimulated = cellfun(@nanmean,data,'UniformOutput',false);

    % Rearrange into macbeth chart for easier viewing and processing
    macbethChart_simulatedImage = cell(4,6);
    for yy = 1:4
        for xx = 1:6
            id = (xx-1)*4 + (4-yy)+1;
            currRGB = avgSimulated{id};
            currRGB = reshape(currRGB,[1 1 3]);
            macbethChart_simulatedImage{yy,xx} = repmat(currRGB,[21 21 1]);
        end
    end
    
%% Extract patches from real image
   
wave = 400:10:700;

sensorData = double(imread('./RealImages/IMG_4392.pgm'));
sensorData = sensorData/max(sensorData(:));
% figure; imshow(sensorData);

fName = fullfile('.','Canon1DMarkIII');
camera = ieReadColorFilter(wave,fName);

sensorReal = sensorCreate('bayer (gbrg)');
sensorReal = sensorSet(sensorReal,'filter transmissivities',camera);
sensorReal = sensorSet(sensorReal,'rows',3693);
sensorReal = sensorSet(sensorReal,'cols',5536);
sensorReal = sensorSet(sensorReal,'volts',sensorData);
sensorReal = sensorSet(sensorReal,'name','Canon');

vcAddObject(sensorReal);
sensorWindow();

ipReal = ipCreate;
ipReal = ipSet(ipReal,'name','Canon');
ipReal = ipCompute(ipReal,sensorReal);

vcAddObject(ipReal);
ipWindow();

% Macbeth select
cp_real =[1990 2176;
3688 2240;
3759 1171;
2026 1115];

[data, mLocs, psize, cp_real] = ...
    macbethSelect(sensorReal,1,1,cp_real);
avgReal = cellfun(@nanmean,data,'UniformOutput',false);

% Rearrange into macbeth chart for easier viewing and processing
macbethChart_realImage = cell(4,6);
for yy = 1:4
    for xx = 1:6
        id = (xx-1)*4 + (4-yy)+1;
        currRGB = avgReal{id};
        currRGB = reshape(currRGB,[1 1 3]);
        macbethChart_realImage{yy,xx} = repmat(currRGB,[21 21 1]);
    end
end
    
    %% Compare values
    
    % Average patches in the real and simulated charts
    avgReal = zeros(4,6,3);
    avgSim = zeros(4,6,3);
    for yy = 1:4
        for xx = 1:6
            currROI_real = macbethChart_realImage{yy,xx};
            avgReal(yy,xx,:) = mean(mean(currROI_real,1),2);
            currROI_sim = macbethChart_simulatedImage{yy,xx};
            avgSim(yy,xx,:) = mean(mean(currROI_sim,1),2);
        end
    end
    
    % Plot
    avgReal_R = avgReal(:,:,1);
    avgReal_G = avgReal(:,:,2);
    avgReal_B = avgReal(:,:,3);
    avgSim_R = avgSim(:,:,1);
    avgSim_G = avgSim(:,:,2);
    avgSim_B = avgSim(:,:,3);
    
    figure; clf; 
    scatter(avgReal_R(:)./max(avgReal_R(:)),avgSim_R(:)./max(avgSim_R(:)),'r'); hold on;
    scatter(avgReal_G(:)./max(avgReal_G(:)),avgSim_G(:)./max(avgSim_G(:)),'g'); hold on;
    scatter(avgReal_B(:)./max(avgReal_B(:)),avgSim_B(:)./max(avgSim_B(:)),'b'); hold on;
    
    % Plot best fit line
    x = [avgReal_R(:)./max(avgReal_R(:)); avgReal_G(:)./max(avgReal_G(:)); avgReal_B(:)./max(avgReal_B(:))];
    y = [avgSim_R(:)./max(avgSim_R(:)); avgSim_G(:)./max(avgSim_G(:)); avgSim_B(:)./max(avgSim_B(:))];
    Fit = polyfit(x,y,1); % x = x data, y = y data, 1 = order of the polynomial.
    Fit(2) = 0; % Make it go through the origin.
    x = 0:0.1:1;
    plot(x,polyval(Fit,x))

    axis([0 1 0 1]); axis square;
    grid on;
    xlabel('Measured RGB Values')
    ylabel('Simulated RGB Values')
    set(gca,'FontSize',18)
    
%% Plot the macbeth charts after IP pipeline

% --- REAL ---
ipWindow;
[data, mLocs, psize, cp_real] = ...
    macbethSelect(ipReal,1,1,cp_real);
avgRealIP = cellfun(@nanmean,data,'UniformOutput',false);
macbethIP_real = cell(4,6);
for yy = 1:4
    for xx = 1:6
        id = (xx-1)*4 + (4-yy)+1;
        currRGB = avgRealIP{id};
        currRGB = reshape(currRGB,[1 1 3]);
        macbethIP_real{yy,xx} = repmat(currRGB,[21 21 1]);
    end
end


% --- SIM ---
ipWindow;
[data, mLocs, psize, cp_sim] = ...
    macbethSelect(ipSimulated{ii},1,1,cp_sim);
avgSimIP = cellfun(@nanmean,data,'UniformOutput',false);
macbethIP_sim = cell(4,6);
for yy = 1:4
    for xx = 1:6
        id = (xx-1)*4 + (4-yy)+1;
        currRGB = avgSimIP{id};
        currRGB = reshape(currRGB,[1 1 3]);
        macbethIP_sim{yy,xx} = repmat(currRGB,[21 21 1]);
    end
end

% --- Display ---
    
scaling = cell2mat(macbethIP_sim)./cell2mat(macbethIP_real);
scaling = nanmean(nanmean(nanmean(scaling,1),2));
figure; clf;
subplot(2,1,1);
imageReal = flipud(cell2mat(macbethIP_real))*4;
imshow(imageReal);
title(sprintf('Color Patches from Real Image -%i',ii))
imwrite(imageReal,'MeasuredMacbeth.png');

subplot(2,1,2);
imageSim = flipud(cell2mat(macbethIP_sim));
imshow(imageSim);
title(sprintf('Color Patches from Simulated Image - %i',ii))
imwrite(imageSim,'SimulatedMacbeth.png');

end
 
