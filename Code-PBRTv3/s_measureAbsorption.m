% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

sizeZ = 9;
sizeX = 1;
sizeY = 1;

%% Create a backlight

recipe = piRead(fullfile(piRootPath,'data','V3','transmissionTest','transmissionTest.pbrt'));
recipe.set('pixel samples', 8);

resolution = [640   480];
recipe.set('film resolution',resolution);
recipe.set('film diagonal', 6);
recipe.set('fov',0.01);
recipe.set('chromaticaberration',1);
recipe.set('maxdepth',1);
recipe.integrator.subtype = 'spectralvolpath';
recipe.sampler.subtype = 'stratified';
recipe.sampler.jitter.type = 'bool';
recipe.sampler.jitter.value = 'false';

recipe.lights{1}.lightspectrum = [(400:10:700)' ones(31,1)]';
recipe.lights{1}.lightspectrum = (recipe.lights{1}.lightspectrum(:))';

recipe.set('outputFile','/Users/hblasinski/Documents/MATLAB/iset3d/local/transmission/baseline.pbrt');

baseline = piSceneSubmerge(recipe, 'sizeX', sizeX, 'sizeY', sizeY, 'sizeZ', sizeZ, ...
                                   'wallOnly', true,  'wallYZ', false,  'wallXZ', false);
                               
piWrite(baseline,'creatematerials',true);

[reference, result] = piRender(baseline,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                               'meanluminance', -1);
ieAddObject(reference);
% sceneWindow();
rgb = sceneGet(reference,'rgb');
figure; imshow(rgb);


%% Create a water sample

params = [ 0 0 0;
          10 0 0;
          10 0.1 0.1];


for p=1:size(params,1)   
    
    
    
    [sample, properties] = piSceneSubmerge(recipe,'sizeX', sizeX, 'sizeY', sizeY, 'sizeZ',  sizeZ,  ...
                                           'cPlankton', params(p,1), 'aCDOM440', params(p,2) ,'aNAP400', params(p,3),...
                                           'waterSct', false, 'cSmall', 0,  'wallYZ', false, 'wallXZ', false);
                                       
    sample.set('outputFile',fullfile(piRootPath,'local','transmission',sprintf('sample_%i.pbrt',p)));
    piWrite(sample,'creatematerials',true);

    [withSample(p), result] = piRender(sample,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                       'meanluminance',-1);

    ieAddObject(withSample(p));
    rgb = sceneGet(withSample(p),'rgb');
    figure; imshow(rgb);
    % sceneWindow();

    % Estimate total attenuation

    delta = 5;
    light = sceneGet(reference, 'roi energy', [resolution(1)/2-delta resolution(2)/2-delta 2*delta 2*delta]);
    water = sceneGet(withSample(p), 'roi energy', [resolution(1)/2-delta resolution(2)/2-delta 2*delta 2*delta]);
    wave = oiGet(withSample(p),'wave');
    
    light = mean(light,1);
    water = mean(water,1);

    figure;
    hold on; grid on; box on;
    plot(wave,[light(:), water(:)]);
    legend('Reference','with water', 'expected water');
    set(gca,'yscale','log');
    
   
    abs = water ./ light;
    abs = abs(:);
    abs = -log(abs) / (sizeZ);

    trueAbs = interp1(properties.wave(:), properties.absorption(:), wave(:));
    
    figure; 
    hold on; grid on; box on;
    plot(wave,[abs, trueAbs ]);
    xlabel('Wavelength, nm');
    ylabel('Absorption coefficient');
    legend('From simulation','expected');
    title(sprintf('cPlankton %.3f, aCDOM440 %.3f, aNAP400 %.3f',params(p,1),params(p,2),params(p,3)));
    
    
end





