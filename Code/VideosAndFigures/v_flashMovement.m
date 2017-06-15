% Convert to video

close all;
clear all;
clc;


waterDepth = 1; % m
cameraDistance = 2;
chlorophyll = 0.0;
cdom = 0.0; 
smallParticleConc = 0.05;
largeParticleConc = 0.05;

zpos = 2010;
ypos = -200:15:200; % mm 
nAngles = length(ypos);

[~, parentPath] = uwSimRootPath();
dataPath = fullfile(parentPath,'Images','SimulatedImages','FlashMovement');
resultPath = fullfile(parentPath,'Results');

% Create video writer
videoname = fullfile(resultPath,'flashMovement');
vidObj = VideoWriter(videoname,'MPEG-4'); %
open(vidObj);

for i=1:2*nAngles
    
    cntr = i;
    if i>nAngles
        cntr = 2*nAngles - i + 1;
    end
    fName = sprintf('%i_UnderwaterChart_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%.2f_%.2f_default.png', ...
        cntr,...
        cameraDistance, ...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc,...
        largeParticleConc,...
        ypos(cntr),zpos);
    
    fName = fullfile(dataPath,fName);
    
    img = imread(fName);
    
    fid = figure(1); clf;
    imshow(imresize(img,2),'Border','tight');
    text(15,20,sprintf('%3i mm',round(ypos(cntr))),'Color','red','Fontsize',20);
    
    % Write each frame to the file.
    for m=1:5 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
end

close(vidObj);


