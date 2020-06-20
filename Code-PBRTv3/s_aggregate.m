%% Extract sensor RGB pixel intensities of real and simulated Macbeth chart.
% 
% This script loads the simulated underwater Macbeth chart radiance images  
% projected onto the sensor and computes the RAW sensor pixel intensities
% for each of the 24 chart patches. 
%
% We perform the same operation (i.e. sample 24 Macbeth chart patches) on a
% subset of images captured with real camera in underwater environments.
%
% Copyright, Henryk Blasinski 2017
%% Initialize and find folders for reading/writing

ieInit;

%% Parameters for simulating the under water environment

resultDir = fullfile('/','Volumes','G-RAID','Projekty','uwSimulation','NewResults');
dataDir = fullfile(resultDir,'CanonImages-Vol2');

dataFiles = dir(fullfile(dataDir,'*.mat'));

data = zeros(numel(dataFiles), 24*3);
properties = zeros(numel(dataFiles), 6);
filename = cell(numel(dataFiles),1);

for d = 1:numel(dataFiles)
    
    fprintf('Analyzing image %i/%i\n',d,numel(dataFiles));
    load(fullfile(dataFiles(d).folder, dataFiles(d).name));
    try
        meanRGB = cell2mat(cellfun(@nanmean, sensorValues, 'UniformOutput',false));
        settings = [params.currDepth, params.currPlankton, params.currCDOM, params.currNAP, params.currSmall, params.currLarge];
        
        data(d,:) = meanRGB;
        properties(d,:) = settings;
        filename{d} = dataFiles(d).name;
    catch
    end
end

save(fullfile(resultDir,'aggregateSim-Vol2.mat'), 'data','properties','filename');

