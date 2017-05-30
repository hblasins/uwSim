%%% RenderToolbox3 Copyright (c) 2012-2013 The RenderToolbox3 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox3/wiki/About-Us
%%% RenderToolbox3 is released under the MIT License.  See LICENSE.txt.

%% Scene description

% Trisha Lian

% Render several cubes colored with the macbeth color chart spectrums. Each
% cube on the chart is 24x24 mm.

% The scene is lit by a point source (flash) 200 mm next to the camera
% center and moves with the camera. There is also a distant, directional
% light source above the water ( see PBRT's "distant" light source). The
% distant light is angled about 5 degrees from the normal of the "ground,"
% facing the chart (in the x direction).

% For underwaterRealistic_XXX.dae, there are two 2x2 m walls in the
% scene. One is 500 mm behind the chart and the second is 1 m behind the
% origin. These sandwich the camera and chart in order to prevent the
% distant directional illumination from entering from the sides of the
% water volume.

% For underwaterRealisticBlackWalls.dae the walls are further apart. See
% the following diagram:

%   ||                                                              ||
%   ||                                                              ||
%   || <-- 0.5 m --> CAMERA <------ 5 m ------> CHART <-- 0.5 m --> ||
%   ||                   ---------->                                ||
%   ||                        Camera moves this way                 ||
% Black Wall                                                    Black wall

% To visualize the scene, you can try opening the Blender
% file. (Note: The spotlight in the Blender file is converted into a
% distant light in the mappings file.) The water volume is a box defined by
% the points p0 and p1 indicated in the mappings file - they extend the
% range of the two walls. The height of the box varies with water depth.

% The user can adjust the water depth and the distance between the camera
% and the chart, as well as the water parameters and light spectrums.

%%
ieInit;
stDockerConfig;

%% Choose files to render
parentSceneFile = 'underwaterRealisticBlackWalls.dae'; % Collada file (from Blender)
mappingsFile = 'UnderwaterChartMappings.txt'; % RTB instructions
conditionsFile = 'UnderwaterChartConditions.txt'; % We'll save the generated conditions to this file (it'll be created in the working directory)

%% Choose renderer options.
hints.imageWidth = 100;
hints.imageHeight = 100;
hints.recipeName = 'underwaterLight'; % Name of the render
hints.renderer = 'PBRT'; % We're only using PBRT right now

% Move to working folder (in render-toolbox)
ChangeToWorkingFolder(hints);

camDist = 1000; % Distance from camera center to chart (mm) Note: Max distance is 5000 mm
waterDepth = 10000;
wave = 400:10:700;

chlorophyllConc = 30.0;
cdomConc = 0.0;

smallPart = 0.01;
largePart = 0.01;

%% Use docker?
hints.copyResources = 1;
SetupPBRTDocker(hints);

%% Make light spectrums
% MAKE ADJUSTMENTS TO SPECTRA HERE.

resources = GetWorkingFolder('resources', false, hints);
load B_cieday % From psychtoolbox

ambient = 'D65';

% Control the distant light
[wls,spd] = ReadSpectrum(sprintf('%s.spd',ambient));
WriteSpectrumFile(wls, spd, ...
    fullfile(resources, 'DistantLight.spd')); % The mappings file will assign DistantLight.spd to the distant light.

fName = fullfile(slRootPath,'Parameters','ximeaLights.mat');
illuminants = ieReadSpectra(fName,wave);
nIlluminants = size(illuminants,2);

illuminants = 1e9*[zeros(length(wave),1), illuminants];

conditionName = sprintf('%s_%i_%i_%0.3f_%0.3f_%0.3f_%0.3f',...
                        ambient,camDist,waterDepth,...
                        chlorophyllConc,cdomConc,smallPart,largePart);
                    

for nn=1:(nIlluminants+1)
    
    % Point light spectrum
    spd = illuminants(:,nn);
    WriteSpectrumFile(wave, spd, ...
        fullfile(resources, 'PointLight.spd')); % The mappings file will assign PointLight.spd to the point light.
    
    %% Make absorption curve, scattering curve, and phase matrix
    % Note: sig_s and sig_a should be in m^-1 units. We later divide by 1000 IN
    % PBRT to convert to mm^-1 units. Because the phase function has units of
    % sr^-1 it needs no scaling.
    
    absorptionFile = fullfile(resources, 'abs.spd');
    sig_a = createAbsorptionCurve(chlorophyllConc,cdomConc);
    WriteSpectrumFile(wave, sig_a, absorptionFile);
    
    
    % See "WritephaseFile.mat" for details on what the phase file looks like
    phaseStyles = {'default','direct','forward','backward'};
    % phaseStyles = {'default'};
    
    % Calculate scattering curve and phase function
    phaseFile = cell(length(phaseStyles),1);
    scatteringFile = cell(length(phaseStyles),1);
    for ii=1:length(phaseStyles)
        phaseFile{ii} = fullfile(resources, sprintf('phase_%s.txt',phaseStyles{ii}));
        
        % Note: This is a bit misleading, since the sig_s curves (i.e.
        % scatteringFile) is the same no matter what the phase style is.
        % however we follow the naming conventions of the phase matrix since we
        % solve for sig_s when calculating the VSF and the phase
        scatteringFile{ii} = fullfile(resources, sprintf('scat_%s.spd',phaseStyles{ii}));
        
        % You can limit the phase to certain angles here (see diagram on p.62 of LoW):
        % default [0,180], backward [90,180], forward [0,90], or direct (0)
        [phase, sig_s] = calculateScattering(smallPart,largePart,'mode',phaseStyles{ii});
        
        % Be careful here of mismatch between wavelengths defined here and
        % wavelengths defined in the "calculateScattering" function.
        % TODO: Error check?
        WriteSpectrumFile(wave,sig_s,scatteringFile{ii});
        WritePhaseFile(wave,phase,phaseFile{ii});
    end
    
    % Replicate for parameters structure
    phaseFiles = cell(length(phaseStyles)*length(camDist),1);
    scatFiles = cell(length(phaseStyles)*length(camDist),1);
    camDistances = cell(length(phaseStyles)*length(camDist),1);
    labels = cell(length(phaseStyles)*length(camDist),1);
    
    for ii=1:length(phaseStyles)
        
        phaseFiles((ii-1)*length(camDist)+1:ii*length(camDist)) = repmat(phaseFile(ii),[length(camDist),1]);
        scatFiles((ii-1)*length(camDist)+1:ii*length(camDist)) = repmat(scatteringFile(ii),[length(camDist),1]);
        camDistances((ii-1)*length(camDist)+1:ii*length(camDist)) = {camDist};
        if nn==1
            labels((ii-1)*length(camDist)+1:ii*length(camDist)) = cellfun(@(x) sprintf('%i mm, Sct: %s, %s',x,phaseStyles{ii},ambient),{camDist},'UniformOutput',false);
        else
            labels((ii-1)*length(camDist)+1:ii*length(camDist)) = cellfun(@(x) sprintf('%i mm, Sct: %s, %s + LED %i',x,phaseStyles{ii},ambient,nn-1),{camDist},'UniformOutput',false);
        end
    end
    
    
    %% Choose OI parameters
    % CHANGE PARAMETERS HERE.
    
    
    % Automatically compute the focal length, so that the VOF is constant for
    % different camera to target distances.
    fDist = cellfun(@(x) 0.8*(20*x)/(24*sqrt(36+16)),{camDist},'UniformOutput',false);
    
    
    oiParams = struct( ...
        'lensType', 'pinhole', ... % This is hard coded in mappings file.
        'filmDistance', fDist, ...
        'filmDiag',{20}, ...
        'cameraDistance',{camDist}, ...
        'waterDepth',{waterDepth}, ... % Distance from camera to water surface (mm) Note: Increasing this will slow down rendering a lot, as it expands the volume of water drastically.
        'absorptionCurveFile',absorptionFile,...
        'scatteringCurveFile',scatFiles,...
        'phaseFile',phaseFiles,...
        'volumeStepSize',{100}); % Specifies how accurate the volume rendering is, a smaller step size will be slower but more accurate. (Ranges I've tried are around 50-150)
    
    
    pixelSamples = 32;
    
    %% Generate a conditions file based on OI parameters.
    % The conditions file specifies how many different renders we want to do,
    % each with a different parameter. See the RTB wiki for more info.
    
    % Variable names in the mappings file
    varNames = {'imageName', 'groupName','filmDistance',...
        'filmDiag', 'cameraTranslate', 'lightTranslate','waterDepth', ...
        'absorptionCurveFile','scatteringCurveFile','phaseFile','volumeStepSize','pixelSamples'};
    
    varValues = cell(0, numel(varNames));
    
    for ii = 1:numel(oiParams)
        
        filmDiag = oiParams(ii).filmDiag;
        filmDistance = oiParams(ii).filmDistance;
        phaseFile = oiParams(ii).phaseFile;
        absorptionCurveFile = oiParams(ii).absorptionCurveFile;
        scatteringCurveFile = oiParams(ii).scatteringCurveFile;
        volumeStepSize = oiParams(ii).volumeStepSize;
        cameraTranslate = 5000 - oiParams(ii).cameraDistance; % Chart is at 5000, camera is at origin in original scene
        lightTranslate = cameraTranslate; % Move light with camera (the mappings file won't take repeated "variables" for different objects)
        waterDepth = oiParams(ii).waterDepth;
        
        imageName = sprintf('%s-radianceWater-%d',hints.recipeName, ii);
        radianceWaterVals{ii} = {imageName, 'waterMode',...
            filmDistance,...
            filmDiag,...
            cameraTranslate,...
            lightTranslate,...
            waterDepth,...
            absorptionCurveFile,...
            scatteringCurveFile,...
            phaseFile,...
            volumeStepSize,...
            pixelSamples};
        
        if ii==1
            imageName = sprintf('%s-radianceNoWater-%d',hints.recipeName, ii);
            radianceNoWaterVals = {imageName, 'noWaterMode',...
                filmDistance,...
                filmDiag,...
                cameraTranslate,...
                lightTranslate,...
                waterDepth,...
                absorptionCurveFile,...
                scatteringCurveFile,...
                phaseFile,...
                volumeStepSize,...
                pixelSamples};
            varValues = cat(1, varValues, radianceNoWaterVals);
            
        end
        
        imageName = sprintf('%s-depth-%d',hints.recipeName, ii);
        depthVals{ii} = {imageName, 'depthMode',...
            filmDistance,...
            filmDiag,...
            cameraTranslate,...
            lightTranslate,...
            waterDepth,...
            absorptionCurveFile,...
            scatteringCurveFile,...
            phaseFile,...
            volumeStepSize,...
            pixelSamples};
        
        varValues = cat(1, varValues, radianceWaterVals{ii});
        varValues = cat(1, varValues, depthVals{ii});
    end
    
    WriteConditionsFile(conditionsFile, varNames, varValues);
    
    %% Render for radiance and depth.
    nativeSceneFiles = MakeSceneFiles(parentSceneFile, conditionsFile, mappingsFile, hints);
    radianceDataFiles = BatchRender(nativeSceneFiles, hints);
    
    %% Build ISET optical images
    
    dataRoot = GetWorkingFolder('renderings', true, hints);
    if ~exist(conditionName,'dir');
        mkdir(conditionName);
    end
    
    fName = fullfile(conditionName,'Leds.mat');
    ieSaveSpectralFile(wave,illuminants(:,2:end),'',fName);
    
    waterOi = cell(numel(oiParams),1);
    for ii = 1:numel(oiParams)
        
        % Read and display depth
        imageName = strcat(depthVals{ii}{1},'_depth.exr');
        depthFile = FindFiles(dataRoot, imageName);
        [depthSliceInfo, depthData] = ReadMultichannelEXR(depthFile{1});
        depthMap = depthData(:,:,2);
        
        % Create oi (WATER)
        imageName = strcat(radianceWaterVals{ii}{1},'.mat');
        radianceFile = FindFiles(dataRoot,imageName);
        photonData = load(radianceFile{1});
        waterOi{ii} = BuildOI(photonData.multispectralImage, depthMap, oiParams(ii));
        waterOi{ii} = oiSet(waterOi{ii},'name',labels{ii});
        vcAddAndSelectObject(waterOi{ii});
        % Save all data as a .mat file
        [path, file, ext] = fileparts(oiParams(ii).phaseFile);
        if nn==1
            %name = sprintf('%s_Water_%s_%s',hints.recipeName,file,ambient);
            name = fullfile('.',conditionName,sprintf('Ambient_%s',file));
        else
            % name = sprintf('%s_Water_%s_%s+led_%i',hints.recipeName,file,ambient,nn-1);
            name = fullfile('.',conditionName,sprintf('Ambient+led_%i_%s',nn-1,file));
        end
        parameters = oiParams(ii);
        oi = waterOi{ii};
        save(name,'oi','parameters');
        
        if ii==1
            % Create oi (NO WATER)
            imageName = strcat(radianceNoWaterVals{1},'.mat');
            radianceFile = FindFiles(dataRoot,imageName);
            photonData = load(radianceFile{1});
            oi = BuildOI(photonData.multispectralImage, depthMap, oiParams(ii));
            oi = oiSet(oi,'name','No water');
            vcAddAndSelectObject(oi);
            % Save all data as a .mat file
            if nn==1
                %name = sprintf('%s_Water_%s_%s',hints.recipeName,file,ambient);
                name = fullfile('.',conditionName,sprintf('NoWater_Ambient_%s',file));
            else
                % name = sprintf('%s_Water_%s_%s+led_%i',hints.recipeName,file,ambient,nn-1);
                name = fullfile('.',conditionName,sprintf('NoWater_Ambient+led_%i_%s',nn-1,file));
            end
            parameters = oiParams(ii);
            save(name,'oi','parameters');
        end
        
    end
    
    % Display optical images
    oiWindow();
    
end

%% Build sensor images

sensor = sensorCreate('monochrome');
sensor = sensorSet(sensor,'size',[hints.imageHeight, hints.imageWidth]);
sensor = sensorSet(sensor,'pixel widthandheight',[oiGet(waterOi{1},'hres'), oiGet(waterOi{1},'wres')]);

measVals = cell(length(waterOi),1);
rawData = cell(length(waterOi),1);
for ii=1:length(waterOi)
    
    tmp = waterOi{ii};
    tmp.data.photons = tmp.data.photons*1e10;
    ieAddObject(tmp);
    
    sensor = sensorCompute(sensor,tmp);
    sensor = sensorSet(sensor,'name',oiGet(waterOi{ii},'name'));
    sensor = sensorSet(sensor,'noise flag',0);
    
    
    expTime = sensorGet(sensor,'exposure time');
    rawData{ii} = sensorGet(sensor,'volts')/expTime;
    
    cp = [4 82;97 82;98 20;4 20];
    [data, ~, ~, cp] = macbethSelect(sensor,1,1,cp);
    tmp = cellfun(@nanmean,data,'UniformOutput',false);
    measVals{ii} = [tmp{:}]'/expTime;
    
    ieAddObject(sensor);
end

phaseStyles = {'default','direct','forward','backward'};

sensorWindow();


figure;
hold on; grid on; box on;
plot(measVals{1},measVals{3} + measVals{4} - measVals{2},'o');
xlabel('Full model');
ylabel('Component sum');

model = rawData{1}(:);
est = rawData{3}(:) + rawData{4}(:) - rawData{2}(:);

nF = max([model; est]);

figure;
hold on; grid on; box on;
plot(model/nF,est/nF,'.');
xlabel('Total');
ylabel('Forward + Backward - Attn');
xlim([0 1]);
ylim([0 1]);
set(gca,'fontsize',12);

figure;
imagesc(rawData{2}./rawData{1}); colorbar;


