% Convert to video

close all;
clear all;
clc;

[codePath, parentPath] = uwSimRootPath();
resultFolder = fullfile(parentPath,'Results','FlashMovement');

if ~exist(resultFolder,'dir') || isempty(dir(resultFolder))
    
    msg = sprintf('The folder %s does not exist or is empty.\n',resultFolder);
    msg = [msg 'You need to run renderFlashMovement.m first to generate the data.\n'];
    
    error(msg);
end

%%

waterDepth = 1; % m
cameraDistance = 2;
chlorophyll = 0.0;
cdom = 0.0; 
smallParticleConc = 0.05;
largeParticleConc = 0.05;

zpos = 2010;
% Make sure that the ypos range reflects the range of values you generated
% the data for:
ypos = -200:15:200; % mm 
nAngles = length(ypos);

[~, parentPath] = uwSimRootPath();
dataPath = fullfile(parentPath,'Results','FlashMovement');
resultPath = fullfile(parentPath,'Images');

% Create video writer
videoname = fullfile(resultPath,'flashMovement');
vidObj = VideoWriter(videoname,'MPEG-4'); %
open(vidObj);

for i=1:2*nAngles
    
    cntr = i;
    if i>nAngles
        cntr = 2*nAngles - i + 1;
    end
    fName = sprintf('%i_UnderwaterChart_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%0.2f_%.2f_%.2f_default.mat', ...
        cntr,...
        cameraDistance, ...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc,...
        largeParticleConc,...
        ypos(cntr),zpos);
    
    fName = fullfile(dataPath,fName);
    load(fName);
    
    img = oiGet(oi,'rgb');
    
    fid = figure(1); clf;
    imshow(imresize(img,2),'Border','tight');
    text(15,20,sprintf('%3i mm',round(ypos(cntr))),'Color','red','Fontsize',20);
    
    % Write each frame to the file.
    for m=1:5 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
end

close(vidObj);


