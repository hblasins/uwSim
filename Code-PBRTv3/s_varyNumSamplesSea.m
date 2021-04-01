% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

sceneDir = '/Volumes/G-RAID/Projekty/uwSimulation/NumSamples-Sea-Tests/scenes';
dataDir = '/Volumes/G-RAID/Projekty/uwSimulation/NumSamples-Sea-Tests/data';

if ~exist(sceneDir,'dir')
    mkdir(sceneDir);
end

if ~exist(dataDir,'dir')
    mkdir(dataDir);
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

macbethRecipe.set('outputFile',fullfile(sceneDir,'baseline','macbeth.pbrt'));

piWrite(macbethRecipe,'creatematerials',true);
[scene, result] = piRender(macbethRecipe,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                               'illuminance',-1);
% ieAddObject(scene);
% sceneWindow();

fName = fullfile(dataDir,'macbeth.mat');
save(fName,'scene');


%% Create chart at different distances

currPlankton = 50;
currCDOM = 1.0;
currNAP = 0;
currSmall = 0.2;
currLarge = 0.4;

currDepth = 2;
currDist = 2;

%% plankton
% 0.01 open ocean
% 10 coastal region
% 100 lakes
% 0.5 global oceanic average

% CDOM
% 0.01 ocean
% 0.1 sea
% 1.0 lakes, estuaries

% small [0.01, 0.2]
% large [0.01, 0.4]



for d=1:15
    
    
    
    fName = fullfile(dataDir,sprintf('uwMbChart_%i.mat',d));
    if exist(fName,'file')
        continue;
    end
    
    
    [sample, properties] = piSceneSubmerge(macbethRecipe,'sizeX', 200, 'sizeY', 2*currDepth, 'sizeZ',  200, ...
                                           'cPlankton', currPlankton, 'aCDOM440', currCDOM ,'aNAP400', currNAP,...
                                           'cSmall',currSmall, 'cLarge', currLarge, ...
                                           'waterSct', true, 'cSmall', 0,  'wallYZ', true, ...
                                                                           'wallXY', true);
    
    sample.set('pixel samples',2^d);                                                                   
    sample.set('from',[0 0 currDist]);
    sample.set('fov', 2*atand( tand(10) * (1-th) / (currDist - th)));
                                                                        
                                       
    sample.set('outputFile',fullfile(sceneDir,'depth',sprintf('depth_%i.pbrt',d)));
    piWrite(sample,'creatematerials',true);

    [scene, result] = piRender(sample,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                       'illuminance',-1);

    
    
    save(fName,'scene','currPlankton','currCDOM','currNAP','currSmall','currLarge','currDepth','currDist',...
                       'distances','depths');
    
end
