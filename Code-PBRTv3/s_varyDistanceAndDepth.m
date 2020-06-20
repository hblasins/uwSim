% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

sceneDir = '/Volumes/G-RAID/Projekty/uwSimulation/DistanceAndDepth';
if ~exist(sceneDir,'dir')
    mkdir(sceneDir);
end

%% Create a backlight

th = 0.05/2;

macbethRecipe = piCreateMacbethChart('width', 0.05, 'height', 0.05, 'depth', 0.05);
macbethRecipe.set('from',[0 0 1]);
macbethRecipe.set('pixel samples', 1024);
macbethRecipe.set('film resolution',[320 240]);
macbethRecipe.set('film diagonal', 6);
macbethRecipe.set('fov',20);
macbethRecipe.set('chromaticaberration',1);
macbethRecipe.set('maxdepth',10);
macbethRecipe.integrator.subtype = 'spectralvolpath';

wave = 395:5:705;
d65energy = illuminantGet(illuminantCreate('d65',wave),'energy');
d65energy = d65energy/max(d65energy);
data = [wave(:), d65energy(:)]';

piLightAdd(macbethRecipe,'name','Sunlight','type','distant',...
                         'from',[0 100 1], 'to', [0 0 0],...
                          'light spectrum', data(:));

macbethRecipe.set('outputFile',fullfile(sceneDir,'baseline','macbeth.pbrt'));

piWrite(macbethRecipe,'creatematerials',true);
[mbScene, result] = piRender(macbethRecipe,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                               'scaleIlluminance',false);
ieAddObject(mbScene);
sceneWindow();


%% Create chart at different distances

% distances = linspace(-1,2,10);
% depths = linspace(0,2,10);

distances = logspace(-1,2,100);
depths = logspace(-1,1,100);

[distVec, depthVec] = ndgrid(distances, depths);

currPlankton = 0;
currCDOM = 0;
currNAP = 0;
currSmall = 0;
currLarge = 0;

for d=1:numel(distVec)  
    
    currDepth = depthVec(d);
    currDist = distVec(d);
    
    [sample, properties] = piSceneSubmerge(macbethRecipe,'sizeX', 200, 'sizeY', 2*currDepth, 'sizeZ',  200, ...
                                           'cPlankton', currPlankton, 'aCDOM440', currCDOM ,'aNAP400', currNAP,...
                                           'cSmall',currSmall, 'cLarge', currLarge, ...
                                           'waterSct', true, 'cSmall', 0,  'wallYZ', true, ...
                                                                           'wallXY', true);
                                                                        
    sample.set('from',[0 0 currDist]);
    sample.set('fov', 2*atand( tand(10) * (1-th) / (currDist - th)));
                                                                        
                                       
    sample.set('outputFile',fullfile(sceneDir,'depth',sprintf('depth_%i.pbrt',d)));
    piWrite(sample,'creatematerials',true);

    [scene, result] = piRender(sample,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                       'scaleIlluminance',false);

    
    fName = fullfile(dataDir,sprintf('uwMbChart_%i.mat',p));
    save(fName,'scene','currPlankton','currCDOM','currNAP','currSmall','currLarge','currDepth','currDist',...
                       'distances','depths');
    
end
