close all;
clear all;
clc;

[codePath, parentPath] = uwSimRootPath();

resultFolder = fullfile(parentPath,'Results','Matching');

%%

fName = fullfile(parentPath,'Results','Matching','simulatedRGB.mat');
load(fName);
fName = fullfile(parentPath,'Results','Matching','measuredRGB.mat');
load(fName);

nReal = size(measuredRGB,2);
nSim = size(simulatedRGB,2);
meta = cell(nReal,1);

uniqueDepth = unique(depthV);
uniqueCdom = unique(cdomV);
uniqueChl = unique(chlV);


for m = 1:nReal
    
    [~, imgName] = fileparts(fNames{m});
    [realSensor, cp, ~, meta{m}] = readCameraImage(fNames{m}, sensor);
    
    error = zeros(nSim,1);
    for s = 1:nSim
        
        % We allow for an unknown scaling between the simulated and
        % measured data.
        cvx_begin quiet
            variable a
            minimize norm(measuredRGB{m}(:)*a - simulatedRGB{s}(:))
            subject to
                a>=0
        cvx_end
        
        
        error(s) = norm(measuredRGB{m}(:)*a - simulatedRGB{s}(:));
    end
    
    [~, minIndex] = min(error);
    
    % Display results
    
    figure;
    subplot(1,3,1);
    hold on; grid on; box on;
    plot(measuredRGB{m},simulatedRGB{minIndex},'o');
    xlabel('Measured');
    ylabel('Simulated');
    title(imageNames{m},'interpreter','none');
    
    subplot(1,3,2);
    measImg = reshape(measuredRGB{m},[4 6 3]);
    measImg = measImg/max(measImg(:));
    measImg = imresize(measImg,100,'nearest');
    imshow(measImg);
    title('Measured');
    
    subplot(1,3,3);
    simImg = reshape(simulatedRGB{minIndex},[4 6 3]);
    simImg = simImg/max(simImg(:));
    simImg = imresize(simImg,100,'nearest');
    imshow(simImg);
    title('Simulated');
    
    fprintf('%s: depth: %s (measured) %.2f (estimated): chlC %.2f: cdomC %.2f\n',imageNames{m},...
        meta{m}.depth.Text,depthV(minIndex)/1000,chlV(minIndex),cdomV(minIndex));
    
    % Save images and results
    
    if ~isempty(resultFolder)
        ip = ipCompute(ipCreate,realSensor);
        img = ipGet(ip,'sensor channels');
        img = img/max(img(:));
        fName = fullfile(resultFolder,sprintf('%s.png',imgName));
        imwrite(img,fName);
        
        
        fName = fullfile(resultFolder,sprintf('%s_sim.png',imgName));
        imwrite(simImg,fName);
        
        fName = fullfile(resultFolder,sprintf('%s_meas.png',imgName));
        imwrite(measImg,fName);
        
        measRGB = measuredRGB{m};
        simRGB = simulatedRGB{minIndex};
        chlC = chlV(minIndex);
        depth = depthV(minIndex);
        cdomC = cdomV(minIndex);
        metadata = meta{m};
        
        fName = fullfile(resultFolder,sprintf('%s_result.mat',imgName));
        save(fName,'measRGB','simRGB','chlC','depth','cdomC','metadata');
    end
    
    % Sensitivity analysis
    
    % Error vs depth
    figure;
    hold on; grid on; box on;
    
    cmap = jet(length(uniqueCdom));
    for cd=1:length(uniqueCdom)
        cdom = uniqueCdom(cd);
        
        for cl=1:length(uniqueChl)
            chl = uniqueChl(cl);
            subError = error(cdomV == cdom & chlV == chl);
            plot(uniqueDepth/10^3,subError,'color',cmap(cd,:));
        end
    end
    xlabel('Depth, m');
    ylabel('Error');
    
    
    % Error vs. CDOM concentration
    figure;
    hold on; grid on; box on;
    
    cmap = jet(length(uniqueDepth));
    for d=1:length(uniqueDepth)
        depth = uniqueDepth(d);
        for cl=1:length(uniqueChl)
            chl = uniqueChl(cl);
            subError = error(depthV == depth & chlV == chl);
            plot(uniqueCdom,subError,'color',cmap(d,:));
        end
    end
    set(gca,'xscale','log');
    xlabel('CDOM concentration');
    ylabel('Error');
    
    % Error vs. chlorophyll concentration
    figure;
    hold on; grid on; box on;
    
    cmap = jet(length(uniqueDepth));
    for d=1:length(uniqueDepth)
        depth = uniqueDepth(d);
        for cd=1:length(uniqueCdom)
            cdom = uniqueCdom(cd);
            subError = error(depthV == depth & cdomV == cdom);
            plot(uniqueChl,subError,'color',cmap(d,:));
        end
    end
    set(gca,'xscale','log');
    xlabel('Chlorophyll concentration');
    ylabel('Error');
    
end







