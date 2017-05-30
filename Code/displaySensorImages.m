close all;
clear all;
clc;

ieInit;

for clr = ['R','B']
    
    for i = 1:9;
        fName = fullfile('..','..','render-toolbox','MakeUnderwaterChart',sprintf('MakeUnderwaterChart_Water_%i_%s.mat',i,clr));
        load(fName);
        
        ieAddObject(oi);
        oiWindow();
        
        oi.data.photons = oi.data.photons*1000;
        
        imwrite(oiGet(oi,'rgb image'),sprintf('irradiance_%i_%s.png',i,clr));
        
        sensor = sensorCreate('monochrome');
        
        sensor = sensorSet(sensor,'size',oiGet(oi,'size'));
        sensor = sensorSet(sensor,'pixel widthandheight',[oiGet(oi,'hres') oiGet(oi,'wres')]);
        sensor = sensorSet(sensor,'name',oiGet(oi,'name'));
        sensor = sensorSet(sensor,'exposure Time',2);
        
        sensor = sensorCompute(sensor,oi);
        ieAddObject(sensor);
        sensorWindow();
        
        imwrite(sensorGet(sensor,'rgb'),sprintf('sensor_%i_%s.png',i,clr));
        
    end
end