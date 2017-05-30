function [ oi ] = renderUnderwaterChart(lightWave, surfaceSpectrum, ledSpectra, targetDistance, depth, chlConc, cdomConc, smallPartConc, largePartConc, varargin )

p = inputParser;
p.addOptional('width',100);
p.addOptional('height',100);

p.parse(varargin{:});
inputs = p.Results;

% Renderer options.
hints.imageWidth = inputs.width;
hints.imageHeight = inputs.height;
hints.recipeName = 'UnderwaterChart-LED'; % Name of the render
hints.renderer = 'PBRT'; % We're only using PBRT right now
hints.copyResources = 1;
hints.batchRenderStrategy = RtbAssimpStrategy(hints);
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @coralColorsMexximpRemodeller;
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @coralColorsPBRTRemodeller;

% Change the docker container
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

resources = rtbWorkingFolder('folderName','resources', 'hints', hints);

filmDiag = 20;
nLeds = size(ledSpectra,2);

% [wavesDaylight, daylight] = rtbReadSpectrum('D65.spd');
% daylight = daylight/max(daylight(:));


%% Save data to resources folder

for cC = chlConc
    for cdom = cdomConc

        [sig_a, waves] = createAbsorptionCurve(cC,cdom);
        absorptionFile = fullfile(resources, sprintf('abs_%.3f_%.3f.spd',cC,cdom));
        rtbWriteSpectrumFile(waves, sig_a, absorptionFile);
    end
end
                
for sp = smallPartConc
    for lp = largePartConc
        
        [phase, sig_s, waves] = calculateScattering(sp,lp);
        rtbWriteSpectrumFile(waves,sig_s,fullfile(resources,sprintf('scat_%.3f_%.3f.spd',sp,lp)));
        WritePhaseFile(waves,phase,fullfile(resources,sprintf('phase_%.3f_%.3f.spd',sp,lp)));
        
    end
end

rtbWriteSpectrumFile(lightWave,surfaceSpectrum,fullfile(resources,'D65.spd'));

for i=1:24
    [waves, data] = rtbReadSpectrum(sprintf('mccBabel-%i.spd',i));
    rtbWriteSpectrumFile(waves,data,fullfile(resources,sprintf('mccBabel-%i.spd',i)));
end


for ledID=1:nLeds
    rtbWriteSpectrumFile(lightWave,ledSpectra(:,ledID),fullfile(resources,sprintf('LED%i.spd',ledID-1)));
end



%% Choose files to render
parentSceneFile = 'underwaterRealisticBlackWalls.dae';  % Collada file (from Blender)
conditionsFile = 'UnderwaterChartConditions.txt';

scene = mexximpCleanImport(fullfile(rtbsRootPath,'MakeUnderwaterChart','Blender',parentSceneFile),'ignoreRootTransform',true);

%% Start rendering

nConditions = length(targetDistance)*length(depth)*length(chlConc)*length(cdomConc)*...
               length(smallPartConc)*length(largePartConc)*nLeds;

names = {'imageName','mode','ledID','pixelSamples','volumeStep','filmDist','filmDiag','cameraDistance','depth',...
    'chlConc','cdomConc','smallPartConc','largePartConc'};

values = cell(nConditions,numel(names));
cntr = 1;
for td = targetDistance
    for de = depth
        for cC = chlConc
            for cdom = cdomConc
                for sp = smallPartConc
                    for lp = largePartConc
                        for ledID=0:(nLeds-1)
                        
                        
                        % Generate condition entries
                        values(cntr,1) = {sprintf('LED%i_%i_%i_%.3f_%.3f_%.3f_%.3f',ledID,td,de,cC,cdom,sp,lp)};
                        values(cntr,2) = {'water'};
                        values(cntr,3) = num2cell(ledID,1);
                        values(cntr,4) = num2cell(8,1);
                        values(cntr,5) = num2cell(50,1);
                        values(cntr,6) = num2cell(0.8*(filmDiag*td)/(24*sqrt(36+16)),1);
                        values(cntr,7) = num2cell(filmDiag,1);
                        values(cntr,8) = num2cell(td,1);
                        values(cntr,9) = num2cell(de,1);
                        values(cntr,10) = num2cell(cC,1);
                        values(cntr,11) = num2cell(cdom,1);
                        values(cntr,12) = num2cell(sp,1);
                        values(cntr,13) = num2cell(lp,1);
                        
                        cntr = cntr+1;
                        
                        end
                    end
                end
            end
        end
    end
end

rtbWriteConditionsFile(conditionsFile,names,values);

nativeSceneFiles = rtbMakeSceneFiles(scene, 'hints', hints, ...
        'conditionsFile',conditionsFile);

radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
 
%%  Show results
oi = cell(nLeds,1);
for i=1:length(radianceDataFiles)
    radianceData = load(radianceDataFiles{i});
                
    % Create an oi
    oiParams.lensType = 'pinhole';
    oiParams.filmDistance = values{i,4};
    oiParams.filmDiag = 20;
    
    
    oi{i} = BuildOI(radianceData.multispectralImage, [], oiParams);
    oi{i} = oiSet(oi{i},'name',values{i,1});
    
end



end

