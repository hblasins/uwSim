% This script estimates the spectral responsivities of the camera RGB color
% filters from a collection of images of a spectralon target illuminated
% with monochromatic lights. 
%
% Note: We use Adobe DNG converter read in raw data. The data is
% demosaiced, so it can introduce some errors. We also assume that all
% imaegs have been captured using the same shutter speed, aperture and ISO
% settings. Hence we ignore the overall scaling due to these parameters.
%
% Copyright, Henryk Blasinski 2017

close all;
clear all;
clc;

%%                                     

[rPath, parentPath] = uwSimRootPath();

dataDir = fullfile(parentPath,'Images','Calibration');
illuminantFName = fullfile(parentPath,'Parameters','mcIlluminants.mat');
destFile = fullfile(parentPath,'Parameters','CanonG7x.mat');

% Estimated responsivity wavelength sampling.
wavelengths = 400:5:700;                        
nWaves = length(wavelengths);

% Responsivity smoothness tuning parameter.
lambda = 1;

% Coordinates for the ROI with monochromator data.
rect = [2731 1707 76 64];                       

%% Load raw data from camera images.

% First convert to uncompressed DNG using Adobe DNG converter
% (This may take a while).

fNames = dir(fullfile(dataDir,'*.CR2'));
nFiles = length(fNames);

ISO = zeros(nFiles,1);
shutter = zeros(nFiles,1);
aperture = zeros(nFiles,1);
data = zeros(nFiles,3);

for i=1:nFiles
   
    filePath = fullfile(dataDir,fNames(i).name);
    cmd = sprintf('dcraw -v -r 1 1 1 1 -H 0 -o 0 -j -4 -q 0 %s',filePath);
    system(cmd);
    
    [~, fileName] = fileparts(fNames(i).name);
    fName = fullfile(dataDir,sprintf('%s.ppm',fileName));
    img = double(imread(fName));
        
    exif = imfinfo(filePath);
    
    % We read in the shutter, ISO and the aperture, but
    % we assume these values are constant for all images and hence
    % ignore their impact on image intensities.
    shutter(i) = exif(1).DigitalCamera.ExposureTime;
    ISO(i) = exif(1).DigitalCamera.ISOSpeedRatings;
    aperture(i) = exif(1).DigitalCamera.FNumber;
        
    roi = img(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3),:);
    roi = reshape(roi,[(rect(3)+1)*(rect(4)+1), 3]);
    
    data(i,:) = mean(roi);
    
end

% Remove .dng files
for i=1:nFiles
    [~, fileName] = fileparts(fNames(i).name);
    delete(fullfile(dataDir,sprintf('%s.ppm',fileName)));
end

%% Compute the responsivity curves
data = data/max(data(:));

ill = load(illuminantFName);

illuminant = ill.illuminant;
mcWaves = ill.mcWavelengths;

% Load the illuminant spectra, convert to photons and normalize
illuminant = Energy2Quanta(ill.wav,illuminant);
illuminant = interp1(ill.wav,illuminant,wavelengths);
input = illuminant'/max(illuminant(:));


% Compute the responsivity curves via ridge regression
R = [diag(ones(nWaves-1,1)) zeros(nWaves-1,1)];
R = R + [zeros(nWaves-1,1) diag(-1*ones(nWaves-1,1))];

responsivity = zeros(nWaves,3);
for i=1:3

    % Now we solve a constrained quadratic program to find the
    % responsivities. 
    %
    % Below is the CVX problem formulation
    
    cvx_begin
        variable resp(nWaves,1)
        minimize norm(input*resp - data(:,i),2) + lambda*norm(R*resp,2)
        subject to 
            resp >= 0
    cvx_end
    
    
    % Or Matlab optimization toolbox formulation
    %{
    A = [input; sqrt(lambda)*R];
    b = [data(:,i); zeros(nWaves-1,1)];
    
    problem.H = A'*A;
    problem.f = -A'*b;
    problem.lb = zeros(nWaves,1);
    problem.solver = 'quadprog';
    problem.options = optimoptions(problem.solver,'MaxIter',1000,...
        'TolCon',1e-12,'Display','off');
    
    resp = quadprog(problem);
    %}
    responsivity(:,i) = resp;
    
end

figure; 
plot(wavelengths, responsivity);
xlabel('Wavelength, nm');

%% Save the results

ieSaveSpectralFile(wavelengths,responsivity,'Canon G7X spectral responsivity curves.',destFile);

