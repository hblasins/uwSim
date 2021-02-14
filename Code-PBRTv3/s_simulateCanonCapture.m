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
dataDir = fullfile(resultDir,'data-Vol2');

outputDir = fullfile(resultDir,'CanonImages-Vol2');
if ~exist(outputDir,'dir'), mkdir(outputDir); end

sceneFiles = dir(fullfile(dataDir,'*.mat'));

for f=1:length(sceneFiles)
    
    [~, sequence] = fileparts(sceneFiles(f).name);
    fName = fullfile(outputDir, sprintf('%s_Canon.mat',sequence));
    if exist(fName,'file')
        continue;
    end
    
    disp(fName);
   
    data = load(fullfile(sceneFiles(f).folder,sceneFiles(f).name));
    
    oi = oiCreate();
    oi = oiSet(oi,'fov',sceneGet(data.scene,'fov'));
    oi = oiCompute(oi,data.scene);
    ieAddObject(oi);
    oiWindow();
    
    sensor = sensorSet(sensor,'size',oiGet(oi,'size'));
    sensor = sensorSet(sensor,'pixel size same fill factor',oiGet(oi,'hres'));
    sensor = sensorCompute(sensor,oi);
    ieAddObject(sensor);
    sensorWindow();
    
    sensorValues = macbethSelect(sensor, 0, 1, cornerPoints);
    
    
    ip = ipCreate;
    ip = ipSet(ip,'demosaic method','bilinear');
    ip = ipSet(ip,'transform method','current');
    ip = ipSet(ip,'correction method illuminant','none');
    ip = ipSet(ip,'conversion method sensor','none');
    ip = ipCompute(ip,sensor);
    ieAddObject(ip);
    ipWindow();
  
    ispValues = macbethSelect(ip, 0, 1, cornerPoints);
    ispResult= ipGet(ip,'result');
    ispImage = ipGet(ip,'data srgb');
    
    params = rmfield(data,'scene');
    
    save(fName,'sensorValues','ispValues','ispImage','params','ispResult');
    
    % If you have a lot of data you'd beter remove some 
    % oi, scene and ip files from ISET global variables.
    vcDeleteSomeObjects('sensor',1:length(vcGetObjects('sensor')));    
    vcDeleteSomeObjects('oi',1:length(vcGetObjects('oi')));
    vcDeleteSomeObjects('ip',1:length(vcGetObjects('ip')));
end

