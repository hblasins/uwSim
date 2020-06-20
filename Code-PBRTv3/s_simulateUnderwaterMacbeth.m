% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

resultDir = fullfile('/','Volumes','G-RAID','Projekty','uwSimulation','NewResults');
sceneDir = fullfile(resultDir,'scenes');
dataDir = fullfile(resultDir,'data');

if ~exist(sceneDir,'dir'), mkdir(sceneDir); end
if ~exist(dataDir,'dir'), mkdir(dataDir); end

%% Create baseline Macbeth chart,
%  The camera is about 1m away from the target.

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
data = [wave(:), d65energy(:)];
d65str = sprintf('%f ',data');

macbethRecipe.world{2} = sprintf('LightSource "distant" "point from" [0 100 1] "point to" [0 0 0] "spectrum L" [%s]',d65str);
macbethRecipe.set('outputFile',fullfile(sceneDir,'baseline','macbeth.pbrt'));

piWrite(macbethRecipe,'creatematerials',true);
[mbScene, result] = piRender(macbethRecipe,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                               'meanluminance',-1);
ieAddObject(mbScene);
sceneWindow();

fName = fullfile(dataDir,'macbethChart.mat');
save(fName,'mbScene');


%% Create a water sample

sizeX = 5;
sizeZ = 5;

depths = linspace(1,20,3);
plankton = logspace(-3,2,3);
cdom = logspace(-5,-1,3);
nap = logspace(-5,-1,3);
large = logspace(-5,-1,3);
small = logspace(-5,-1,3);


[depthsVec, planktonVec, cdomVec, napVec, largeVec, smallVec] = ndgrid(depths, plankton, cdom, nap, large, small);

nRenders = numel(depthsVec);

for p=1:nRenders
    
    currPlankton = planktonVec(p);
    currCDOM = cdomVec(p);
    currNAP = napVec(p);
    currSmall = smallVec(p);
    currLarge = largeVec(p);
    currDepth = depthsVec(p);
    
    [macbethUwRecipe, properties] = piSceneSubmerge(macbethRecipe, 'sizeX', sizeX, 'sizeY', currDepth*2, 'sizeZ',  sizeZ, ...
                                                   'cPlankton', currPlankton, 'aCDOM440', currCDOM ,'aNAP400', currNAP, ...
                                                   'cSmall', currSmall, 'cLarge', currLarge,...
                                                   'wallYZ', true, 'wallXZ', false, 'wallXY', true);
                                       
    macbethUwRecipe.set('outputFile',fullfile(sceneDir,sprintf('underwater_%i',p),sprintf('macbeth_uw_%i.pbrt',p)));
    piWrite(macbethUwRecipe,'creatematerials',true);

    [mbUwScene, result] = piRender(macbethUwRecipe,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                                   'meanluminance',-1);

    ieAddObject(mbUwScene);
    sceneWindow();

    
    fName = fullfile(dataDir,sprintf('uwMbChart_%i.mat',p));
    save(fName,'mbUwScene','currPlankton','currCDOM','currNAP','currSmall','currLarge','currDepth',...
                           'plankton','cdom','nap','small','large','depths');
end





