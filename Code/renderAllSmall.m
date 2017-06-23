% This script is identical to renderAll.m but generates a much smaller data
% set (10 different depths, 5 chlorophyll concentrations and 5 cdom
% concetrations).

% Copyright, Trisha Lian, Henryk Blasinski 2017

%% Initialize

clear;
close all;
clc;

ieInit;

[codePath, parentPath] = uwSimRootPath();

destPath = fullfile(parentPath,'Results','All');
if ~exist(destPath,'dir'), mkdir(destPath); end

%% Choose rendering options

hints.imageWidth = 320;
hints.imageHeight = 240;

hints.recipeName = 'UnderwaterChart-All'; % Name of the render
hints.renderer = 'PBRT'; % Use PBRT as the renderer
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% Change the docker container
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

% Helper function used to move scene objects and camera around
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @mexximpRemodeller;

% Helper function used to control PBRT parameters (e.g. light spectra, reflectance spectra, underwater parameters)
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @PBRTRemodeller;

% Don't copy a new mesh file for every scene (TODO: Is this what this does?)
hints.batchRenderStrategy.converter.rewriteMeshData = false;

% Specify where resource files such as spectra or textures will be stored.
resourceFolder = rtbWorkingFolder('folderName','resources',...
    'rendererSpecific',false,...
    'hints',hints);

%% Load scene

% Import the scene file. In this case it is a Collada file exported from
% Blender (underwaterRealisticFlat.blend).

% Each cube on the chart is 24x24 mm. The scene is lit by a point source
% (flash) that is by default, 200 mm next to the camera center and moves
% with the camera. There is also a distant, directional light source above
% the water (see PBRT's "distant" light source). The distant light is
% angled about 5 degrees from the normal of the ground plane, facing the
% chart. It is offset in the x-direction.

% There are two 2x2 meter walls in the scene. One is 500 mm behind the
% chart and the second is 1 m behind the origin. These two walls sandwich
% the camera and chart in order to prevent the distant directional
% illumination from entering from the sides of the water volume.

%   ||                                                              ||
%   ||                                                              ||
%   || <-- 0.5 m --> CAMERA <------ 5 m ------> CHART <-- 0.5 m --> ||
%   ||                   ---------->                                ||
%   ||                        Camera moves this way                 ||
% Black Wall                                                    Black wall

% To visualize the scene, you can try opening the Blender file. (Note: The
% spotlight in the Blender file is converted into a distant light in
% underwaterPBRTRemodeller.m) The water volume is a box defined by the
% points p0 and p1 indicated in underwaterPBRTRemodeller.m - they extend
% the range of the two walls. The height of the box varies with water
% depth.

parentSceneFile = fullfile(parentPath,'Scenes','underwaterRealisticBlackWalls.dae');
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
spd = spd.*10^10; % Add a scale factor.
rtbWriteSpectrumFile(wls, spd, fullfile(resourceFolder, 'DistantLight.spd'));

% Macbeth cube reflectances
for i = 1:24
    macbethPath = fullfile(rtbRoot(),'RenderData','Macbeth-ColorChecker',sprintf('mccBabel-%i.spd',i));
    copyfile(macbethPath, rtbWorkingFolder('hints', hints));
end

%% Write conditions and generate scene files

% Rendering parameters
pixelSamples = 32;
volumeStepSize = 50;
cameraDistance = 1000; % mm


% --- CAMERA PARAMETERS ---
% Note these are repeated in the PBRTremodeller function,
% Here we use the values only to compute the scene fov,
% given that we know that we are looking at a Macbeth chart.
patchSize = 24;
chartHeight = 4*patchSize;
chartWidth = 6*patchSize;

filmHalfDiag = 10;
targetHalfDiag = 1.2*sqrt(chartHeight^2+chartWidth^2)/2;
filmDistance = filmHalfDiag*cameraDistance/targetHalfDiag;

fov = atan2d(filmHalfDiag,filmDistance);

% --- WATER PARAMETERS ---

depth = linspace(1,20,10)*10^3; % mm
chlorophyll = logspace(-2,0,5);
cdom = logspace(-2,0,5);

smallParticleConc = 0.0;
largeParticleConc = 0.0;

nConditions = length(depth)*length(chlorophyll)*length(cdom)...
    *length(smallParticleConc)*length(largeParticleConc); % Number of images of varying parameters to render

chlorophyllConc = zeros(nConditions,1);
cdomConc = zeros(nConditions,1);
spConc = zeros(nConditions,1);
lpConc = zeros(nConditions,1);

waterDepth = cell(nConditions,1);
absorptionFiles = cell(nConditions,1);
scatteringFiles = cell(nConditions,1);
phaseFiles = cell(nConditions,1);


i = 1;
for wd=1:length(depth)
    for chl=1:length(chlorophyll)
        for dm=1:length(cdom)
            for sp=1:length(smallParticleConc)
                for lp=1:length(largeParticleConc)
                    
                    % Using the parameters defined above, create curves for absorption,
                    % scattering and phase. These are saved as text files in the resource
                    % folder and will be read in by the underwater renderer in PBRT.
                    
                    % Create absorption curve
                    [sig_a, waves] = createAbsorptionCurve(chlorophyll(chl),cdom(dm));
                    absorptionFileName = sprintf('abs_%i.spd',i);
                    rtbWriteSpectrumFile(waves, sig_a, fullfile(resourceFolder, absorptionFileName));
                    
                    % Create scattering curve and phase function
                    [phase, sig_s, waves] = calculateScattering(smallParticleConc(sp),largeParticleConc(lp),'mode','default');
                    scatteringFileName = sprintf('scat_%i.spd',i);
                    rtbWriteSpectrumFile(waves,sig_s,fullfile(resourceFolder,scatteringFileName));
                    phaseFileName = sprintf('phase_%i.txt',i);
                    WritePhaseFile(waves,phase,fullfile(resourceFolder,phaseFileName));
                    
                    % For every condition, store the corresponding absorption, scattering,
                    % and phase filename.
                    absorptionFiles{i} = absorptionFileName;
                    scatteringFiles{i} = scatteringFileName;
                    phaseFiles{i} = phaseFileName;
                    
                    % Store the parameters for every condition.
                    waterDepth{i} = depth(wd);
                    
                    chlorophyllConc(i) = chlorophyll(chl);
                    cdomConc(i) = cdom(dm);
                    spConc(i) = smallParticleConc(sp);
                    lpConc(i) = largeParticleConc(lp);
                    
                    i = i+1;
                end
            end
        end
    end
end

%% Create the conditions file

% Rearrange all the parameters into a large cell matrix, where each row
% records the parameters for each condition. The cell matrix is passed to
% rtbWriteConditionsFile, which converts it into a text file.
names = {'pixelSamples','cameraDistance','waterDepth','volumeStepSize', ...
    'absorptionFiles','scatteringFiles','phaseFiles'};

values = cell(nConditions, numel(names));
values(:,1) = num2cell(ones(1,nConditions).*pixelSamples,1);
values(:,2) = num2cell(ones(1,nConditions).*cameraDistance,1);
values(:,3) = waterDepth;
values(:,4) = num2cell(ones(1,nConditions).*volumeStepSize,1);
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
    
    fprintf('%i\n',i);
    
    radianceData = load(radianceDataFiles{i});
    
    oiName = sprintf('%s_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f', ...
        hints.recipeName, ...
        cameraDistance/10^3, ...
        waterDepth{i}/10^3, ...
        chlorophyllConc(i), ...
        cdomConc(i), ...
        spConc(i), ...
        lpConc(i));
    
    % Create an oi
    oi = oiCreate;
    oi = initDefaultSpectrum(oi);
    oi = oiSet(oi,'fov',fov);
    oi = oiSet(oi,'photons',radianceData.multispectralImage*radianceData.radiometricScaleFactor);
    oi = oiSet(oi,'name',oiName);
    
    % vcAddAndSelectObject(oi);
    
    % Save oi and rendering parameters.
    fName = fullfile(destPath,strcat(oiName,'.mat'));
    depth = waterDepth(i);
    chlC = chlorophyllConc(i);
    cdomC = cdomConc(i);
    smallPart = spConc(i);
    largePart = lpConc(i);
    camDist = cameraDistance;
    
    save(fName,'oi','depth','chlC','cdomC','smallPart','largePart','camDist');
    
    % imwrite(oiGet(oi,'rgb'),fullfile(destPath,strcat(oiName,'.png')));
    
end

oiWindow;


