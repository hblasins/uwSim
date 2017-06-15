% Convert to video

close all;
clear all;
clc;

nAngles = 100;

waterDepth = 6; % m
chlorophyll = 0.0;
cdom = 0.0; 
smallParticleConc = 0.01;
largeParticleConc = 0.01;

[~, parentPath] = uwSimRootPath();
dataPath = fullfile(parentPath,'Results','Staggered3D');
resultPath = fullfile(parentPath,'Results');

% Create video writer
videoname = fullfile(resultPath,'staggered3D');
vidObj = VideoWriter(videoname,'MPEG-4'); %
open(vidObj);

for i=1:2*nAngles
    
    cntr = i;
    if i>nAngles
        cntr = 2*nAngles - i + 1;
    end
    fName = sprintf('%i_uwSim-Staggered3D_%i_%0.2f_%0.2f_%0.2f.png', ...
        cntr,...
        waterDepth, ...
        chlorophyll, ...
        cdom, ...
        smallParticleConc);
    
    fName = fullfile(dataPath,fName);
    
    img = imread(fName);
    
    fid = figure(1); clf;
    imshow(img,'Border','tight');
    
    
    % Write each frame to the file.
    for m=1:2 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
end

close(vidObj);


