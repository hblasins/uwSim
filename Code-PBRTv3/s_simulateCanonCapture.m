ieInit;

wave = 400:10:700;

fName = fullfile('/','Volumes','G-RAID','Projekty','uwSimulation','Parameters','CanonG7X');
transmissivities = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',transmissivities);
sensor = sensorSet(sensor,'name','Canon G7X');
sensor = sensorSet(sensor,'noise flag',0);

cornerPoints = [96 221;304 220;306 81;96 80];

resultDir = fullfile('/','Volumes','G-RAID','Projekty','uwSimulation','NewResults');
dataDir = fullfile(resultDir,'data');

sceneFiles = dir(fullfile(dataDir,'*.mat'));

for f=1:length(sceneFiles)
   
    data = load(fullfile(sceneFiles(f).folder,sceneFiles(f).name));
    
    oi = oiCreate();
    oi = oiSet(oi,'fov',sceneGet(data.mbUwScene,'fov'));
    oi = oiCompute(oi,data.mbUwScene);
    
    ieAddObject(oi);
    oiWindow();
    
    sensor = sensorSet(sensor,'size',oiGet(oi,'size'));
    sensor = sensorSet(sensor,'pixel size same fill factor',oiGet(oi,'hres'));

    sensor = sensorCompute(sensor,oi);
    ieAddObject(sensor);
    sensorWindow();
    
    rgbValues = macbethSelect(sensor, 0, 1, cornerPoints);
    
    ip = ipCreate;
    ip = ipSet(ip,'demosaic method','bilinear');
    ip = ipSet(ip,'correction method illuminant','none');
    ip = ipCompute(ip,sensor);
    ieAddObject(ip);
    ipWindow();
  

    rgbImageSimulated = ipGet(ip,'data srgb');
    
end

