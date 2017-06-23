% This script takes the Macbeth chart RGB intensities extracted from the
% captured and simulated data and finds the simulated water parameters that
% explain best the RGB data catprued in the real world.
%
% Copyright, Henryk Blasinski 2017

close all;
clear all;
clc;

ieInit;

[codePath, parentPath] = uwSimRootPath();
% If resultFolder = [] no results are saved.
% resultFolder = fullfile(parentPath,'Results','Matching');
resultFolder = [];

%% Create a Canon G7X camera model
wave = 400:10:700;

fName = fullfile(parentPath,'Parameters','CanonG7X');
transmissivities = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',transmissivities);
sensor = sensorSet(sensor,'name','Canon G7X');
sensor = sensorSet(sensor,'noise flag',0);

%%

fName = fullfile(parentPath,'Results','Matching','simulatedRGB.mat');
load(fName);
fName = fullfile(parentPath,'Results','Matching','measuredRGB.mat');
load(fName);

nReal = size(measuredRGB,2);
nSim = size(simulatedRGB,2);

uniqueDepth = unique(depthV);
uniqueCdom = unique(cdomV);
uniqueChl = unique(chlV);


for m = 1:nReal
    
    [~, imgName] = fileparts(fNames{m});
    
    error = zeros(nSim,1);
    for s = 1:nSim
        
        % We allow for an unknown scaling between the simulated and
        % measured data.
        %
        % min |measuredRGB*a - simulatedRGB|
        % subject to a>=0
        %
        % A snipet of CVX code that produces the solution 
        %
        % cvx_begin quiet
        %    variable a
        %    minimize norm(measuredRGB{m}(:)*a - simulatedRGB{s}(:))
        %    subject to
        %        a>=0
        % cvx_end
        
        % Or Matlab's optimization toolbox
        problem.H = measuredRGB{m}(:)'*measuredRGB{m}(:);
        problem.f = -measuredRGB{m}(:)'*simulatedRGB{m}(:);
        problem.lb = 0;
        problem.solver = 'quadprog';
        problem.options = optimoptions(problem.solver,'MaxIter',1000,...
            'TolCon',1e-12,'Display','off');
        
        a = quadprog(problem);
        
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
        
        fileName = fullfile(parentPath,fNames{m});
        [realSensor, cp] = readCameraImage(fileName, sensor);

        
        ip = ipCompute(ipCreate,realSensor);
        img = ipGet(ip,'sensor channels');
        
        % Save full resolution camera image
        % img = img/(5*max(img(:)));
        % fName = fullfile(resultFolder,sprintf('%s.png',imgName));
        % imwrite(img,fName);
        
        
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
    
    %% Sensitivity analysis
    %  Plot how sensitive the error is as we vary different water
    %  parameters.
    
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
    
    
    % Error volume
    % Find parameters for which the error is less than 10%, and see where
    % they are placed in teh 3D space.
    
    ids = find(error < min(error(:)*1.05));
    [sortedError, loc] = sort(error(ids));
    
    subDepth = depthV(ids);
    subCdom = cdomV(ids);
    subChl = chlV(ids);
    
    cmap = jet(length(subDepth(:)));
    
    figure;
    hold on; grid on; box on;
    
    for i=1:length(subDepth(:))
        plot3(subDepth(loc(i))/1000,subCdom(loc(i)),subChl(loc(i)),'.','MarkerSize',20,'Color',cmap(i,:));
    end
    xlim([min(depthV(:)) max(depthV(:))]/1000);
    ylim([min(cdomV(:)) max(cdomV(:))]);
    zlim([min(chlV(:)) max(chlV(:))]);
    
    set(gca,'yscale','log');
    set(gca,'zscale','log');
    set(gca,'view',[-68 30]);
    xlabel('Depth, m');
    ylabel('CDOM conc, mg/m^3');
    zlabel('chl conc, mg/m^3');
    
    title(sprintf('%s',imgName),'Interpreter','none');
end







