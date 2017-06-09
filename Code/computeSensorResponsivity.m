close all;
clear all;
clc;

lambda = 1;                                     % Responsivity smoothness tuning parameter.

dataDir = '.';
illuminantFName = 'illuminant.mat';

wavelenghts = 400:5:700;                        % Estimated responsivity wavelength sampling.
nWaves = length(wavelenghts);


rect = [1645 1047 57 63];                       % Coordinates for the ROI with monochromator data.


%% Load raw data from camera images.

% First convert to uncompressed DNG using Adobe DNG converter
% (This may take a while).
cmd = sprintf('''/Applications/Adobe DNG Converter.app/Contents/MacOS/Adobe DNG Converter'' -l -u %s/*.GPR',dataDir);
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

%% Compute the responsivity curves
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

%% Plot and save the results

figure; 
plot(wavelenghts, responsivity);
xlabel('Wavelength, nm');

ieSaveSpectralFile(wavelenghts,responsivity,'GoPro 5 spectral responsivity curves.','./GoPro5Responsivity.mat');

