% Convert to video
close all;
clear all;
clc;

%% Depth

cameraDistance = 1;
depth = linspace(1,20,10); % mm
chlorophyll = 0.01;
cdom = 0.01;
smallParticleConc = 0.0;
largeParticleConc = 0.0;

[~, parentPath] = uwSimRootPath();
dataPath = fullfile(parentPath,'Results','All-Old');
resultPath = fullfile(parentPath,'Results');

% Create video writer
videoname = fullfile(resultPath,'depth');
vidObj = VideoWriter(videoname,'MPEG-4'); %
open(vidObj);

for i=1:length(depth)
    
    fName = sprintf('underwaterChart-All_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f.png', ...
        cameraDistance, ...
        depth(i), ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc, ...
        largeParticleConc);
    
    fName = fullfile(dataPath,fName);
    
    img = imread(fName);
    
    fid = figure(1); clf;
    imshow(img,'Border','tight');
    text(15,20,sprintf('%2i m',round(depth(i))),'Color','red','Fontsize',20);
    %     title(sprintf('x = %i mm',flashDistanceFromCamera(i)))
    
    % Write each frame to the file.
    for m=1:15 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
end

close(vidObj);


%% Chlorophyl

cameraDistance = 1;
depth = linspace(1,20,10); % mm
depth = depth(5);
chlorophyll = logspace(-2,0,5);
cdom = 0.01;
smallParticleConc = 0.0;
largeParticleConc = 0.0;

[~, parentPath] = uwSimRootPath();
dataPath = fullfile(parentPath,'Results','All');
resultPath = fullfile(parentPath,'Results');

% Create video writer
videoname = fullfile(resultPath,'chlorophyll');
vidObj = VideoWriter(videoname,'MPEG-4'); %
open(vidObj);

for i=1:length(chlorophyll)
    
    fName = sprintf('underwaterChart-All_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f.png', ...
        cameraDistance, ...
        depth, ...
        chlorophyll(i), ...
        cdom, ...
        smallParticleConc, ...
        largeParticleConc);
    
    fName = fullfile(dataPath,fName);
    
    img = imread(fName);
    
    fid = figure(1); clf;
    imshow(img,'Border','tight');
    %     title(sprintf('x = %i mm',flashDistanceFromCamera(i)))
    
    % Write each frame to the file.
    for m=1:15 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
end

close(vidObj);


%% CDOM

cameraDistance = 1;
depth = linspace(1,20,10); % mm
depth = depth(5);
chlorophyll = logspace(-2,0,5);
chlorophyll = chlorophyll(5);
cdom = logspace(-2,0,5);

smallParticleConc = 0.0;
largeParticleConc = 0.0;

[~, parentPath] = uwSimRootPath();
dataPath = fullfile(parentPath,'Results','All');
resultPath = fullfile(parentPath,'Results');

% Create video writer
videoname = fullfile(resultPath,'cdom');
vidObj = VideoWriter(videoname,'MPEG-4'); %
open(vidObj);

for i=1:length(chlorophyll)
    
    fName = sprintf('underwaterChart-All_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f.png', ...
        cameraDistance, ...
        depth, ...
        chlorophyll, ...
        cdom(i), ...
        smallParticleConc, ...
        largeParticleConc);
    
    fName = fullfile(dataPath,fName);
    
    img = imread(fName);
    
    fid = figure(1); clf;
    imshow(img,'Border','tight');
    %     title(sprintf('x = %i mm',flashDistanceFromCamera(i)))
    
    % Write each frame to the file.
    for m=1:15 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
end

close(vidObj);


