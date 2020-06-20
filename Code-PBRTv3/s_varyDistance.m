% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

sceneDir = '/Volumes/G-RAID/Projekty/uwSimulation/NewResults-Distance';
if ~exist(sceneDir,'dir')
    mkdir(sceneDir);
end

%% Create a backlight

macbethRecipe = piCreateMacbethChart('width', 0.05, 'height', 0.05, 'depth', 0.05);
macbethRecipe.set('from',[0 0 1]);
macbethRecipe.set('pixel samples', 32);
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

distances = [1:2:20];


for d=1:length(distances)  
    
    
    [sample, properties] = piSceneSubmerge(macbethRecipe,'sizeX', 200, 'sizeY', 20, 'sizeZ',  200, ...
                                           'cPlankton', 10, 'aCDOM440', 0.001 ,'aNAP400', 0.001,...
                                           'waterSct', true, 'cSmall', 0,  'wallYZ', true, ...
                                                                            'wallXY', true);
                                                                        
    sample.set('from',[0 0 distances(d)]);
    sample.set('fov', 20 / distances(d));
                                                                        
                                       
    sample.set('outputFile',fullfile(sceneDir,'depth',sprintf('depth_%i.pbrt',d)));
    piWrite(sample,'creatematerials',true);

    [withSample(d), result] = piRender(sample,'dockerimagename','hblasins/pbrt-v3-spectral:underwater',...
                                       'scaleIlluminance',false);

    ieAddObject(withSample(d));
    sceneWindow();
    
end

%%

wave = 400:10:700;

fName = fullfile('/','Volumes','G-RAID','Projekty','uwSimulation','Parameters','CanonG7X');
transmissivities = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',transmissivities);
sensor = sensorSet(sensor,'name','Canon G7X');
sensor = sensorSet(sensor,'noise flag',0);

cornerPoints = [96 221;304 220;306 81;96 80];

for d=1:length(distances)
    
    oi = oiCreate();
    oi = oiSet(oi,'fov',sceneGet(withSample(d),'fov'));
    oi = oiCompute(oi,withSample(d));
    ieAddObject(oi);
    oiWindow();
    
    sensor = sensorSet(sensor,'size',oiGet(oi,'size'));
    sensor = sensorSet(sensor,'pixel size same fill factor',oiGet(oi,'hres'));
    sensor = sensorCompute(sensor,oi);
    ieAddObject(sensor);
    sensorWindow();
    
    sensorValues{d} = macbethSelect(sensor, 0, 1, cornerPoints);
end
%%
close all;

f1 = figure; 
hold on; grid on; box on;

f2 = figure; 
hold on; grid on; box on;

cm = jet(24);
cm  = [0 0 1;
       0 1 0;
       1 0 0];
   
coeff = zeros(24,2);
RGB = zeros(24,length(distances),3);
for p=1:24
    
    R = zeros(length(distances),1);
    G = zeros(length(distances),1);
    B = zeros(length(distances),1);
    
    for d=1:length(distances)
        
        dta = nanmean(sensorValues{d}{p});
        
        R(d) = dta(1) / sum(dta);
        G(d) = dta(2) / sum(dta);
        B(d) = dta(3) / sum(dta);
      
    end
    
    RGB(p,:,1) = R;
    RGB(p,:,2) = G;
    RGB(p,:,3) = B;
    
    figure(f1)
    plot((R),(G),'x-','color',cm(mod(p,3)+1,:));
    xlabel('(R)');
    ylabel('(G)');
    % xlim([0 1]);
    % ylim([0 1]);
    
    figure(f2)
    plot((B),(G),'x-','color',cm(mod(p,3)+1,:));
    xlabel('(B)');
    ylabel('(G)');
    % xlim([0 1]);
    % ylim([0 1]);
    
    g = [G(end); G(end-1)];
    A = [B(end) 1; B(end-1) 1];
    coeff(p,:) = A\g;
    
    b = linspace(0,1,100);
    g = b*coeff(p,1) + coeff(p,2);
    
    plot(b,g,'k');
end

alpha = mean(coeff(:,1));
beta = mean(coeff(:,2));

g = b * alpha + beta; 

plot(b,g,'r','LineWidth',2);

%
g = RGB(:,:,2);
g = g(:);

b = RGB(:,:,3);
b = b(:);
A = [b, ones(numel(b),1)];

C = [b, g];

A = A(24*5+1:end,:);
g = g(24*5+1:end);

cvx_begin
    variable ln(2,1)
    minimize norm(g - A*ln,2)
    subject to 
        (g - A*ln) <= 0
cvx_end


 b = linspace(0,1,100);
 g = b*ln(1,1) + ln(2,1);

plot(b,g,'g','LineWidth',2);









figure;
hold on; grid on; box on;
dst = zeros(24,length(distances));
dstCVX = zeros(24,length(distances));
for d=1:length(distances)
    
    for  p=1:24
        
        dta = nanmean(sensorValues{d}{p});
        
        R = dta(1) / sum(dta);
        G = dta(2) / sum(dta);
        B = dta(3) / sum(dta);
        
        dst(p,d) = abs(alpha*B - G + beta) / sqrt(alpha.^2 + 1);
        dstCVX(p,d) = abs(ln(1,1)*B - G + ln(2,1)) / sqrt(ln(1,1).^2 + 1);
        
        plot(distances(d), dst(p,d), 'x');
        
    end
    
    plot(distances(d), mean(dst(:,d)),'x','markerSize',20,'color','r');
    plot(distances(d), mean(dstCVX(:,d)),'o','markerSize',20,'color','g');
end





%%
f3 = figure; 
hold on; grid on; box on;

f4 = figure; 
hold on; grid on; box on;

for d=1:length(distances) 
    
    R = zeros(24,1);
    G = zeros(24,1);
    B = zeros(24,1);
    
    for p=1:24
        
        dta = nanmean(sensorValues{d}{p});
        
        R(p) = dta(1) / sum(dta);
        G(p) = dta(2) / sum(dta);
        B(p) = dta(3) / sum(dta);
        
    end
    
    figure(f3)
    plot((R),(G),'x','color',cm(mod(d,3)+1,:));
    xlabel('(R)');
    ylabel('(G)');
    xlim([0 1]);
    ylim([0 1]);
    
    figure(f4)
    plot((B),(G),'x','color',cm(mod(d,3)+1,:));
    xlabel('(B)');
    ylabel('(G)');
    xlim([0 1]);
    ylim([0 1]);
    
end

