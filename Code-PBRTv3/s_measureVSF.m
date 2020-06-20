% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create a backlight

i = 1;
resolution = [320   240];
delta = 10;

totalLight = [];


angles = [1 15 30 45 60 75 90 105 120 135 150 165 179];
% angles = 45;
for a=1:length(angles)
    
    angle = angles(a);
    
    x = sind(angle);
    z = -cosd(angle);

    recipe = piCreateBacklight('from',[x 0 z]);
    [recipe, properties] = piSceneSubmerge(recipe,'sizeX', 0.01, 'sizeY', 0.01, 'sizeZ', 0.01, 'cLarge', 0.00);

    recipe.set('pixel samples',32);

    recipe.set('film resolution',resolution);
    recipe.set('film diagonal', 6);
    recipe.set('fov',0.1);
    recipe.set('chromaticaberration',1);
    recipe.set('maxdepth',1);
    recipe.integrator.subtype = 'spectralvolpath';
    
    recipe.set('outputFile',fullfile(piRootPath,'local','VSF',sprintf('vsf_%i.pbrt',a)));
    piWrite(recipe,'creatematerials',true);
    [withSample(i), result] = piRender(recipe,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                              'scaleIlluminance',false);

    ieAddObject(withSample(i));
    sceneWindow();
    
    wave = sceneGet(withSample(i),'wave');
    light = sceneGet(withSample(i), 'roi energy', [resolution(1)/2-delta resolution(2)/2-delta 2*delta 2*delta]);
    light(light == 0) = NaN;
    
    light = mean(light,1,'omitnan');

    totalLight = cat(1,totalLight,light);
    
    i = i+1;
end
%% Phase function
%  Phase function need not be wavelength dependent

selWaves = [450 550 650];

for w=1:length(selWaves)

    estimate = totalLight(:,wave == selWaves(w));
    estimate = estimate / max(estimate);
    
    true = interp1(properties.wave,properties.vsf,selWaves(w));
    true = true / max(true);
    
    figure;
    hold on; grid on; box on;
    plot(180 - angles, estimate);
    plot(properties.angles / pi * 180, true);
    legend('estimated','true');
    set(gca,'yscale','log');
    title(sprintf('Phase function at %i nm',selWaves(w)));
    
end

%% Volume Scattering function

selAngles = [1, 45, 120, 179];

for a = 1:length(selAngles)
    
    angle = (180 - selAngles(a)) / 180;
    
    estimate = interp1(angles, totalLight, selAngles(a));
    estimate = estimate / max(estimate);
    
    true = interp1(properties.angles, properties.vsf',angle * pi);
    true = true / max(true);
    
    figure; 
    hold on; grid on; box on;
    plot(properties.wave, true(:));
    plot(wave, estimate(:));
    xlabel('Wavelength, nm');
    ylabel('Intensity');
    legend('true','estimate');
    title(sprintf('Volume Scattering Function at %i deg',180 - selAngles(a)));
    
end


