%% Render underwater chart

% Render a simulated macbeth chart underwater to show it's 3D nature. 

% Copyright, Trisha Lian, Henryk Blasinski 2017

%% Initialize

clear; 
close all; 
clc;

ieInit;

[codePath, parentPath] = uwSimRootPath();

destPath = fullfile(parentPath,'Results','Staggered3D');
if ~exist(destPath,'dir'), mkdir(destPath); end

%% Choose rendering options

hints.imageWidth = 320;
hints.imageHeight = 240;

hints.recipeName = 'uwSim-Staggered3D';
hints.renderer = 'PBRT'; % Use PBRT as the renderer
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% Change the docker container
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

% Helper function used to move scene objects and camera around
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @mexximpRemodellerStaggered3D;

% Helper function used to control PBRT parameters (e.g. light spectra, reflectance spectra, underwater parameters)
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @PBRTRemodellerStaggered3D;

% Don't copy a new mesh file for every scene (TODO: Is this what this does?)
hints.batchRenderStrategy.converter.rewriteMeshData = false;

% Specify where resource files such as spectra or textures will be stored. 
resourceFolder = rtbWorkingFolder('folderName','resources',...
                                  'rendererSpecific',false,...
                                  'hints',hints);
                              
%% Load scene 


parentSceneFile = fullfile(parentPath,'Scenes','underwater3DStaggered.dae'); 
[scene, elements] = mexximpCleanImport(parentSceneFile,...
    'flipUVs',true,...
    'imagemagicImage','hblasins/imagemagic-docker',...
    'toReplace',{'jpg','png'},...
    'targetFormat','exr',...
    'workingFolder',resourceFolder);

% Add a camera at a central location in the scene. We will move the camera
% to the right position later in the script.
scene = mexximpCentralizeCamera(scene);

%% Make light spectra

% Sunlight (aka distant light)
fName = fullfile(rtbRoot,'RenderData','D65.spd');
[wls,spd] = rtbReadSpectrum(fName);
%spd = spd.*10^10; % Add a scale factor.
rtbWriteSpectrumFile(wls, spd, fullfile(resourceFolder, 'DistantLight.spd')); 
        
% Macbeth cube reflectances
for i = 1:24
    macbethPath = fullfile(rtbRoot(),'RenderData','Macbeth-ColorChecker',sprintf('mccBabel-%i.spd',i));
    copyfile(macbethPath, rtbWorkingFolder('hints', hints)); 
end

%% Write conditions and generate scene files

% --- WATER PARAMETERS ---

nConditions = 100; % Number of images of varying parameters to render

% This parameters is special to this staggered3D scene. We want to show the
% 3D nature of the scene, so we move the camera in an arc while keeping it
% pointed at the chart. 
% The chart is centered at (0,5000,0):m
r = 2000;
xc = 0; yc = 5000;
theta = linspace(-90,-150,nConditions);
xpoints = r*cosd(theta) + xc;
ypoints = r*sind(theta) + yc;

%{
figure(1); clf;
scatter(xpoints,ypoints); axis image; 
axis([-6000 6000 -1000 6000]); 
hold on; scatter(0,5000,'rx');
%}

cameraPosition = [xpoints; ypoints; zeros(1,nConditions)]; % mm

waterDepth = ones(1,nConditions).*6*10^3; % mm
pixelSamples = ones(1,nConditions).*32;
volumeStepSize = ones(1,nConditions).*50;

chlorophyll = ones(1,nConditions).*0.0;
cdom = ones(1,nConditions).*0.0; 
smallParticleConc = ones(1,nConditions).*0.01;
largeParticleConc = ones(1,nConditions).*0.01;

absorptionFiles = cell(nConditions,1);
scatteringFiles = cell(nConditions,1);
phaseFiles = cell(nConditions,1);

for i = 1:nConditions
    
    % Using the parameters defined above, create curves for absorption,
    % scattering and phase. These are saved as text files in the resource
    % folder and will be read in by the underwater renderer in PBRT.
    
    % Create absorption curve
    [sig_a, waves] = createAbsorptionCurve(chlorophyll(i),cdom(i));
    absorptionFileName = sprintf('abs_%i.spd',i);
    rtbWriteSpectrumFile(waves, sig_a, fullfile(resourceFolder, absorptionFileName));
    
    % Create scattering curve and phase function
    [phase, sig_s, waves] = calculateScattering(smallParticleConc(i),largeParticleConc(i),'mode','default');
    scatteringFileName = sprintf('scat_%i.spd',i);
    rtbWriteSpectrumFile(waves,sig_s,fullfile(resourceFolder,scatteringFileName));
    phaseFileName = sprintf('phase_%i.txt',i);
    writePhaseFile(waves,phase,fullfile(resourceFolder,phaseFileName));
    
    % For every condition, store the corresponding absorption, scattering,
    % and phase filename. 
    absorptionFiles{i} = absorptionFileName;
    scatteringFiles{i} = scatteringFileName;
    phaseFiles{i} = phaseFileName;
    
end

%% Create the conditions file

% Rearrange all the parameters into a large cell matrix, where each row
% records the parameters for each condition. The cell matrix is passed to
% rtbWriteConditionsFile, which converts it into a text file. 
names = {'pixelSamples','cameraPosition','waterDepth','volumeStepSize', ...
    'absorptionFiles','scatteringFiles','phaseFiles'};

values = cell(nConditions, numel(names));
values(:,1) = num2cell(pixelSamples,1);
values(:,2) = num2cell(cameraPosition,1);
values(:,3) = num2cell(waterDepth,1);
values(:,4) = num2cell(volumeStepSize,1);
values(:,5) = absorptionFiles;
values(:,6) = scatteringFiles;
values(:,7) = phaseFiles;

% Write the parameters in a conditions file. 
conditionsFile = 'UnderwaterChartConditions.txt';
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, names, values);

% The text file is then read in by RTB and for each condition, a new scene
% file (.pbrt) is created according to the parameters of each condition.
nativeSceneFiles = rtbMakeSceneFiles(scene,'hints', hints,'conditionsFile',conditionsPath);

%% Render!
% Render all .pbrt files. 
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

%% View as an OI

renderingsFolder = rtbWorkingFolder('folderName', 'renderings',...
    'rendererSpecific',true,...
    'hints', hints);

% For each rendered condition, we load in the radiance data (height x width
% x wavelength) and create an optical image (oi) object for ISET. The water
% parameters and the oi object is saved in a .mat file. 
for i = 1:nConditions
    
    radianceData = load(radianceDataFiles{i});
   
    oiName = sprintf('%i_%s_%i_%0.2f_%0.2f_%0.2f_%0.2f',i,hints.recipeName,...
        waterDepth(i)/10^3,chlorophyll(i),cdom(i),...
        smallParticleConc(i),largeParticleConc(i));
    
    % Create an oi
    oi = oiCreate;
    oi = initDefaultSpectrum(oi);
    oi = oiSet(oi,'photons',radianceData.multispectralImage*radianceData.radiometricScaleFactor);
    oi = oiSet(oi,'name',oiName);
    
    vcAddAndSelectObject(oi);
    
    % Save oi
    fName = fullfile(destPath,strcat(oiName,'.mat'));
    depth = waterDepth(i);
    chlC = chlorophyll(i);
    cdomC = cdom(i);
    smallPart = smallParticleConc(i);
    largePart = largeParticleConc(i);
    
    save(fName,'oi','depth','chlC','cdomC','smallPart','largePart');
    
    imwrite(oiGet(oi,'rgb'),fullfile(destPath,strcat(oiName,'.png')));
        
end

oiWindow;

 
