close all;
clear all;
clc;

ieInit;

[codePath, parentPath] = uwSimRootPath();
resultFolder = fullfile(parentPath,'Results','Scatter');
destFolder = fullfile(parentPath,'Figures');

waterDepth = 1; % m
cameraDistance = 2; % m

chlorophyll = 0.0;
cdom = 0.0;
smallParticleConc = 0.05;
largeParticleConc = 0.05;

flashDistanceFromChart = cameraDistance*1000;
flashDistanceFromCamera = 20;

%% Default
mode = 'default';

fName = sprintf('uwSim-Scatter_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%s.mat', ...
        cameraDistance, ...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc, ...
        largeParticleConc,...
        flashDistanceFromCamera,...
        flashDistanceFromChart,...
        mode);
    
[phase, sig_s, waves] = calculateScattering(smallParticleConc,largeParticleConc,'mode',mode);
defaultPhaseFunc = interp1(waves,phase',550)';

figure; semilogy(0:179,defaultPhaseFunc);
xlim([0,179]);
    
default = load(fullfile(resultFolder,fName));

defaultImg = oiGet(default.oi,'rgb image');
figure; imshow(defaultImg);
imwrite(defaultImg,fullfile(destFolder,sprintf('scatter_%s.png',mode)));


%% Forward
mode = 'forward';

fName = sprintf('uwSim-Scatter_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%s.mat', ...
        cameraDistance, ...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc, ...
        largeParticleConc,...
        flashDistanceFromCamera,...
        flashDistanceFromChart,...
        mode);
    

[phase, sig_s, waves] = calculateScattering(smallParticleConc,largeParticleConc,'mode',mode);
forwardPhaseFunc = interp1(waves,phase',550)';

figure; semilogy(0:179,forwardPhaseFunc);
xlim([0,179]);

forward = load(fullfile(resultFolder,fName));
forwardImg = oiGet(forward.oi,'rgb image');
figure; imshow(forwardImg);
imwrite(forwardImg,fullfile(destFolder,sprintf('scatter_%s.png',mode)));


%% Backward
mode = 'backward';

fName = sprintf('uwSim-Scatter_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%s.mat', ...
        cameraDistance, ...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc, ...
        largeParticleConc,...
        flashDistanceFromCamera,...
        flashDistanceFromChart,...
        mode);

[phase, sig_s, waves] = calculateScattering(smallParticleConc,largeParticleConc,'mode',mode);
backwardPhaseFunc = interp1(waves,phase',550)';

figure; semilogy(0:179,backwardPhaseFunc);
xlim([0,179]);
    
    
    
backward = load(fullfile(resultFolder,fName));

backwardImg = oiGet(backward.oi,'rgb image');
figure; imshow(backwardImg);
imwrite(backwardImg,fullfile(destFolder,sprintf('scatter_%s.png',mode)));


%% Direct
mode = 'direct';

fName = sprintf('uwSim-Scatter_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%s.mat', ...
        cameraDistance, ...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc, ...
        largeParticleConc,...
        flashDistanceFromCamera,...
        flashDistanceFromChart,...
        mode);
    
[phase, sig_s, waves] = calculateScattering(smallParticleConc,largeParticleConc,'mode',mode);
directPhaseFunc = interp1(waves,phase',550)';

figure; semilogy(0:179,directPhaseFunc);
xlim([0,179]);
    
    
direct = load(fullfile(resultFolder,fName));
directImg = oiGet(direct.oi,'rgb image');
figure; imshow(directImg);
imwrite(directImg,fullfile(destFolder,sprintf('scatter_%s.png',mode)));


%% Direct component and scattered comonent

scatter = default.oi;
scatter.data.photons = max(scatter.data.photons - direct.oi.data.photons,0);

ieAddObject(scatter);
oiWindow;

scatteredImg = oiGet(scatter,'rgb image');
figure; imshow(scatteredImg);
imwrite(scatteredImg,fullfile(destFolder,sprintf('scatter_component.png')));

