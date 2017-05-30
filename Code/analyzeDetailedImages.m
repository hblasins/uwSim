close all;
clear all;
clc;

ieInit;

wave = 400:10:700;
dist = 200:250:4000;
murky = [0.0, 0.1, 0.3];
measured = zeros(length(dist),length(wave),length(murky) + 2);
measuredStd = zeros(length(dist),length(wave),length(murky) + 2);

expTime = zeros(length(dist),length(wave));

for wv = 400:10:700;
    
    for i = 1:length(dist);
        fName = fullfile('..','..','render-toolbox','MakeUnderwaterChart',sprintf('MakeUnderwaterChart_Water_%i_%i.mat',3*(i-1)+1,wv));
        noScatter = load(fName);
        fprintf('Loaded distance %i, particle %.1f\n',noScatter.parameters.cameraDistance,noScatter.parameters.smallPart);
        
        fName = fullfile('..','..','render-toolbox','MakeUnderwaterChart',sprintf('MakeUnderwaterChart_Water_%i_%i.mat',3*(i-1)+2,wv));
        withScatter = load(fName);
        fprintf('Loaded distance %i, particle %.1f\n',withScatter.parameters.cameraDistance,withScatter.parameters.smallPart);

        fName = fullfile('..','..','render-toolbox','MakeUnderwaterChart',sprintf('MakeUnderwaterChart_Water_%i_%i.mat',3*(i-1)+3,wv));
        muchScatter = load(fName);
        fprintf('Loaded distance %i, particle %.1f\n',muchScatter.parameters.cameraDistance,muchScatter.parameters.smallPart);

        
        onlyMuchScatter = noScatter;
        onlyMuchScatter.oi.data.photons = max(muchScatter.oi.data.photons - noScatter.oi.data.photons,0);
        
        onlySomeScatter = noScatter;
        onlySomeScatter.oi.data.photons = max(withScatter.oi.data.photons - noScatter.oi.data.photons,0);
       
        
        ieAddObject(noScatter.oi);
        ieAddObject(withScatter.oi);
        ieAddObject(muchScatter.oi);
        ieAddObject(onlyMuchScatter.oi);
        ieAddObject(onlySomeScatter.oi);

        oiWindow();
            
        
        % imwrite(oiGet(oi,'rgb image'),sprintf('irradiance_%i_%s.png',i,clr));
        
        sensor = sensorCreate('monochrome');
        
        sensor = sensorSet(sensor,'size',oiGet(noScatter.oi,'size'));
        sensor = sensorSet(sensor,'pixel widthandheight',[oiGet(noScatter.oi,'hres') oiGet(noScatter.oi,'wres')]);
        sensor = sensorSet(sensor,'name',oiGet(noScatter.oi,'name'));
        % 
        
        expTime(i,wave == wv) = autoExposure(noScatter.oi,sensor);
        sensor = sensorSet(sensor,'exposure Time',expTime(i,wave == wv));
        
        sensorNoScatter = sensorCompute(sensor,noScatter.oi);
        sensorNoScatter = sensorSet(sensorNoScatter,'name',sprintf('%i mm, %i nm, 0.0',dist(i),wv));
        
        sensorWithScatter = sensorCompute(sensor,withScatter.oi);
        sensorWithScatter = sensorSet(sensorWithScatter,'name',sprintf('%i mm, %i nm, 0.1',dist(i),wv));

        sensorMuchScatter = sensorCompute(sensor,muchScatter.oi);
        sensorMuchScatter = sensorSet(sensorMuchScatter,'name',sprintf('%i mm, %i nm, 0.3',dist(i),wv));

        sensorOnlyMuchScatter = sensorCompute(sensor,onlyMuchScatter.oi);
        sensorOnlyMuchScatter = sensorSet(sensorOnlyMuchScatter,'name',sprintf('%i mm, %i nm, 0.3 only',dist(i),wv));

        
        sensorOnlySomeScatter = sensorCompute(sensor,onlySomeScatter.oi);
        sensorOnlySomeScatter = sensorSet(sensorOnlySomeScatter,'name',sprintf('%i mm, %i nm, 0.1 only',dist(i),wv));

        
        sz = sensorGet(sensorNoScatter,'size');
        delta = 2;
        
        volts = sensorGet(sensorNoScatter,'volts');
        voltsROI = volts(sz(1)/2 - delta : sz(1)/2 + delta, sz(1)/2 - delta : sz(1)/2 + delta);
        measured(i,wave == wv,1) = mean(voltsROI(:));
        measuredStd(i,wave == wv,1) = std(voltsROI(:));

        
        volts = sensorGet(sensorWithScatter,'volts');
        voltsROI = volts(sz(1)/2 - delta : sz(1)/2 + delta, sz(1)/2 - delta : sz(1)/2 + delta);
        measured(i,wave == wv,2) = mean(voltsROI(:));
        measuredStd(i,wave == wv,2) = std(voltsROI(:));

        
        volts = sensorGet(sensorMuchScatter,'volts');
        voltsROI = volts(sz(1)/2 - delta : sz(1)/2 + delta, sz(1)/2 - delta : sz(1)/2 + delta);
        measured(i,wave == wv,3) = mean(voltsROI(:));
        measuredStd(i,wave == wv,3) = std(voltsROI(:));

        
        volts = sensorGet(sensorOnlySomeScatter,'volts');
        voltsROI = volts(sz(1)/2 - delta : sz(1)/2 + delta, sz(1)/2 - delta : sz(1)/2 + delta);
        measured(i,wave == wv,4) = mean(voltsROI(:));
        measuredStd(i,wave == wv,4) = std(voltsROI(:));

        
        volts = sensorGet(sensorOnlyMuchScatter,'volts');
        voltsROI = volts(sz(1)/2 - delta : sz(1)/2 + delta, sz(1)/2 - delta : sz(1)/2 + delta);
        measured(i,wave == wv,5) = mean(voltsROI(:));
        measuredStd(i,wave == wv,5) = std(voltsROI(:));

        
        ieAddObject(sensorNoScatter);
        ieAddObject(sensorWithScatter);
        ieAddObject(sensorMuchScatter);
        ieAddObject(sensorOnlySomeScatter);
        ieAddObject(sensorOnlyMuchScatter);
        sensorWindow();
        
        % imwrite(sensorGet(sensor,'rgb'),sprintf('sensor_%i_%s.png',i,clr));
        %}
    end
end

figure;
imagesc(wave,dist,measured(:,:,1)./measuredStd(:,:,1));
title('SNR absorption');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

figure;
imagesc(wave,dist,measured(:,:,2)./measuredStd(:,:,2));
title('SNR low scatter');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

figure; 
imagesc(wave,dist,measured(:,:,2)./measured(:,:,1));
title('(Low scatter (0.1) + Absorption)/Absorption');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

figure; 
imagesc(wave,dist,measured(:,:,3)./measured(:,:,1))
title('(Hight scatter (0.3) + Absorption)/Absoprtion');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

figure; 
imagesc(wave,dist,measured(:,:,4)./measured(:,:,1))
title('Scattered/Absorbed');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

figure; 
imagesc(wave,dist,measured(:,:,5)./measured(:,:,1))
title('Scattered/Absorbed');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

figure;
imagesc(wave,dist,expTime);
title('Exposure Time');
colorbar;
xlabel('Wavelength, nm');
ylabel('Target distance, mm');

