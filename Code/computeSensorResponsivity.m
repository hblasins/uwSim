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
wavelenghts = 400:5:700;                        
nWaves = length(wavelenghts);

% Responsivity smoothness tuning parameter.
lambda = 1;

% Coordinates for the ROI with monochromator data.
rect = [2731 1707 76 64];                       

%% Load raw data from camera images.

% First convert to uncompressed DNG using Adobe DNG converter
% (This may take a while).
cmd = sprintf('''/Applications/Adobe DNG Converter.app/Contents/MacOS/Adobe DNG Converter'' -l -u %s/*.CR2',dataDir);
system(cmd)

files = dir(fullfile(dataDir,'*.dng'));
nFiles = length(files);

ISO = zeros(nFiles,1);
shutter = zeros(nFiles,1);
aperture = zeros(nFiles,1);
data = zeros(nFiles,3);

warning off MATLAB:tifflib:TIFFReadDirectory:libraryWarning
for i=1:nFiles
   
    fName = sprintf(fullfile(dataDir,files(i).name));
    
    exif = imfinfo(fName);
    
    % We read in the shutter, ISO and the aperture, but
    % we assume these values are constant for all images and hence
    % ignore their impact on image intensities.
    shutter(i) = exif.DigitalCamera.ExposureTime;
    ISO(i) = exif.DigitalCamera.ISOSpeedRatings;
    aperture(i) = exif.DigitalCamera.FNumber;
    
    t = Tiff(fName,'r');
    offsets = getTag(t,'SubIFD');
    setSubDirectory(t,offsets(1));
    cfa = read(t);
    
    close(t);
    
    roi = cfa(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3),:);
    roi = reshape(roi,[(rect(3)+1)*(rect(4)+1), 3]);
    
    data(i,:) = mean(roi);
    
end

% Remove .dng files
for i=1:nFiles
    delete(fullfile(dataDir,files(i).name));
end

%% Compute the responsivity curves
data = data/max(data(:));

ill = load(illuminantFName);

illuminant = ill.illuminant;
mcWaves = ill.mcWavelengths;

% Load the illuminant spectra, convert to photons and normalize
illuminant = Energy2Quanta(ill.wav,illuminant);
illuminant = interp1(ill.wav,illuminant,wavelenghts);
input = illuminant'/max(illuminant(:));


% Compute the responsivity curves via ridge regression
R = [diag(ones(nWaves-1,1)) zeros(nWaves-1,1)];
R = R + [zeros(nWaves-1,1) diag(-1*ones(nWaves-1,1))];

responsivity = zeros(nWaves,3);
for i=1:3

    cvx_begin
        variable resp(nWaves,1)
        minimize norm(input*resp - data(:,i),2) + lambda*norm(R*resp,2)
        subject to 
            resp >= 0
    cvx_end
    
    responsivity(:,i) = resp;
    
end

figure; 
plot(wavelenghts, responsivity);
xlabel('Wavelength, nm');

%% Save the results

ieSaveSpectralFile(wavelenghts,responsivity,'Canon G7X spectral responsivity curves.',destFile);

