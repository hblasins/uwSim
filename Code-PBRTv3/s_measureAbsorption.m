% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

thickness = 1;
height = 0.01;
depth = 0.01;

%% Create a backlight

recipe = piRead(fullfile(piRootPath,'data','V3','transmissionTest','transmissionTest.pbrt'));
recipe.set('pixel samples', 32);

resolution = [640   480];
recipe.set('film resolution',resolution);
recipe.set('film diagonal', 6);
recipe.set('fov',0.1);
recipe.set('chromaticaberration',1);
recipe.set('maxdepth',1);
recipe.integrator.subtype = 'spectralvolpath';
recipe.sampler.subtype = 'stratified';
recipe.sampler.jitter.type = 'bool';
recipe.sampler.jitter.value = 'false';

recipe.set('outputFile','/Users/hblasinski/Documents/MATLAB/iset3d/local/transmission/baseline.pbrt');

baseline = piSceneSubmerge(recipe,'height',height,'width', thickness ,'depth', depth, 'offsetW', 0, ...
                                                                            'wallOnly', true, ...
                                                                            'wallYZ', true, ...
                                                                            'wallXZ', true);
                                                                        
piWrite(baseline,'creatematerials',true);

[reference, result] = piRender(baseline,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                               'meanluminance',-1);
ieAddObject(reference);
sceneWindow();


%% Create a water sample

params = [ 0 0 0;
          10 0 0;
          10 1 1];


for p=1:size(params,1)   
    
    
    
    [sample, properties] = piSceneSubmerge(recipe,'height', height, 'width', thickness, 'depth',  depth, 'offsetW', 0, ...
                                           'cPlankton', params(p,1), 'aCDOM440', params(p,2) ,'aNAP400', params(p,3),...
                                           'waterSct', false, 'cSmall', 0,  'wallYZ', true, ...
                                                                            'wallXZ', true);
                                       
    sample.set('outputFile',fullfile(piRootPath,'local','transmission',sprintf('sample_%i.pbrt',p)));
    piWrite(sample,'creatematerials',true);

    [withSample(p), result] = piRender(sample,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                       'meanluminance',-1);

    ieAddObject(withSample(p));
    sceneWindow();

    % Estimate total attenuation

    delta = 30;
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
    abs = -log(abs) / (thickness);

    trueAbs = interp1(properties.wave(:), properties.absorption(:), wave(:));
    
    figure; 
    hold on; grid on; box on;
    plot(wave,[abs, trueAbs ]);
    xlabel('Wavelength, nm');
    ylabel('Absorption coefficient');
    legend('From simulation','expected');
    title(sprintf('cPlankton %.3f, aCDOM440 %.3f, aNAP400 %.3f',params(p,1),params(p,2),params(p,3)));
    
    
end





