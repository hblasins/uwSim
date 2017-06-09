% Matches real image with simulated images at different depths.

%% Initialize
clear; close all;
ieInit;
%% Load  all the simulated files

renderingsFolder = '/Users/trishalian/GitRepos/render_toolbox/UnderwaterChart/renderings/PBRT';

depth_m = 0:20; % m

simulatedRGB = cell(1,length(depth_m));

for d = 1:length(depth_m)
    oiFilePath = fullfile(renderingsFolder,sprintf('UnderwaterChart_1.00_%0.2f_0.00_0.00_0.00_0.00.mat',depth_m(d)));
    [rgbImageSimulated, avgMacbeth] = processSimulatedChart(oiFilePath);
    simulatedRGB{d} = avgMacbeth;
end

% Save
comment = 'Depth is third dimension in rgbSimulated, i.e. rgbSimulated(:,:,1) is the simulated image at depth = 0 m.';
save('simulatedRGB_Depth.mat','simulatedRGB','depth_m','comment');


%% Load all real images

realImageFolder = '/Users/trishalian/Dropbox/Images';

% See function below
fn = getfn(realImageFolder, 'CR2$');

measuredRGB = cell(1,length(fn));
imageNames = cell(1,length(fn));

for i = 1:length(fn)
    
    rawCameraFilePath = fn{i};
    [~, imageNames{i}, ext] = fileparts(rawCameraFilePath);
    [sensorReal,cp_real,img,meta] = readCameraImage(rawCameraFilePath);
    
    % --------------------------------
    % --- CHANGE THIS FOR FILTERS ----
    wave = 400:10:700;
    fName = fullfile(uwSimulationRootPath,'Canon1DMarkIII');
    camera = ieReadColorFilter(wave,fName);
    sensorReal = sensorSet(sensorReal,'filter transmissivities',camera);
    % --------------------------------
    % --------------------------------
    
    vcAddObject(sensorReal);
    sensorWindow();
    
    ipReal = ipCreate;
    ipReal = ipSet(ipReal,'name','Canon');
    ipReal = ipCompute(ipReal,sensorReal);
    
    vcAddObject(ipReal);
    ipWindow();
    
    [data, mLocs, psize, cp_real] = ...
        macbethSelect(sensorReal,1,1,cp_real);
    avg = cellfun(@nanmean,data,'UniformOutput',false);
    
    % Rearrange into macbeth chart for easier viewing and processing
    rgbAverageMeasured = zeros(4,6,3);
    for yy = 1:4
        for xx = 1:6
            id = (xx-1)*4 + (4-yy)+1;
            currRGB = avg{id};
            currRGB = reshape(currRGB,[1 1 3]);
            rgbAverageMeasured(yy,xx,:) = currRGB;
        end
    end
    
    measuredRGB{i} = rgbAverageMeasured;
end

% Save
comment = 'Third dimension matches the list of filenames.';
save('realRGB_Depth.mat','measuredRGB','imageNames','comment');

%% For every real image, match with the simulated values
load('simulatedRGB_Depth.mat');
load('realRGB_Depth.mat');

% matches = cell{}
% for m = 1:size(measuredRGB,3)
%     
%     RMS = zeros(size(simulatedRGB,3),1);
%     
%     for s = 1:size(simulatedRGB,3)    
%         RMS(s) = rms(measuredRGB{m} - simulatedRGB{s});
%     end
%     
%     minIndex = min(RMS);
%     
%     
% end

%%
function filenames = getfn(mydir, pattern)
%GETFN Get filenames in directory and subdirectories.
%
%   FILENAMES = GETFN(MYDIR, PATTERN)
%
% Example: Get all files that end with 'txt' in the current directory and
%          all subdirectories 
%
%    fn = getfn(pwd, 'txt$')
%
%   Thorsten.Hansen@psychol.uni-giessen.de  2016-07-06
if nargin == 0
  mydir = pwd;
end
% computes common variable FILENAMES: get all files in MYDIR and
% recursively traverses subdirectories to get all files in these
% subdirectories: 
getfnrec(mydir) 
% if PATTERN is given, select only those files that match the PATTERN:                 
if nargin > 1 
  idx = ~cellfun(@isempty, regexp(filenames, pattern));
  filenames = filenames(idx);
end
    function getfnrec(mydir)
    % nested function, works on common variable FILENAMES
    % recursively traverses subdirectories and returns filenames
    % with path relative to the top level directory
      d = dir(mydir);
      filenames = {d(~[d.isdir]).name};
      filenames = strcat(mydir, filesep, filenames); 
      dirnames = {d([d.isdir]).name};
      dirnames = setdiff(dirnames, {'.', '..'});  
      for i = 1:numel(dirnames)
        fulldirname = [mydir filesep dirnames{i}];
        filenames = [filenames, getfn(fulldirname)];
      end  
    end % nested function
end