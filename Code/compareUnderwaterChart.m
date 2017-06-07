%% Process underwater chart

% (1) In this script, we read in a a raw underwater macbeth chart image
% taken in the Caribbean with a Canon Powershot G7X. We process the voltage
% values in this raw image through a sensor and ISP that matches the real
% camera. This gives us an RGB image, processed through the camera.

% (2) Next, we read in an OI mat file generated from
% "renderUnderwaterChart.m" and process it through a simulated sensor and
% ISP that match (1). We also end up with the RGB image that we get through
% the camera system simulation.

% (3) Finally, we extract color of each macbeth patch from both
% simulated and real RGB images and compare them to each other.

% Trisha Lian

%% Initialize
clear; close all;
ieInit;

oiFilePath = ''; % simulated
rawCameraFilePath = ''; % real
% I.E.
% oiFilePath = '/Users/trishalian/GitRepos/render_toolbox/UnderwaterChart/renderings/PBRT/UnderwaterChart_2.00_1.00_0.00_0.00_0.05_0.05_20.00_2000.00_backward.mat'; % simulated
% rawCameraFilePath = '/Users/trishalian/Dropbox/Images/07/IMG_4924.CR2'; % real


%% Run OI through a sensor/ip

[rgbImageSimulated, macbethChart_simulatedImage] = processSimulatedMat(oiFilePath);

%% Extract patches from real image

[sensorReal,cp_real,img,meta] = readCameraImage(rawCameraFilePath);

wave = 400:10:700;

% TODO: Do we need to normalize this?
% sensorReal.data = sensorReal.data/max(sensorReal.data(:));
% figure; imshow(sensorData);

% Set color filters
fName = fullfile('.','Canon1DMarkIII');
camera = ieReadColorFilter(wave,fName);
sensorReal = sensorSet(sensorReal,'filter transmissivities',camera);

vcAddObject(sensorReal);
sensorWindow();

ipReal = ipCreate;
ipReal = ipSet(ipReal,'name','Canon');
ipReal = ipCompute(ipReal,sensorReal);

vcAddObject(ipReal);
ipWindow();

[data, mLocs, psize, cp_real] = ...
    macbethSelect(sensorReal,1,1,cp_real);
avgReal = cellfun(@nanmean,data,'UniformOutput',false);

% Rearrange into macbeth chart for easier viewing and processing
macbethChart_realImage = cell(4,6);
for yy = 1:4
    for xx = 1:6
        id = (xx-1)*4 + (4-yy)+1;
        currRGB = avgReal{id};
        currRGB = reshape(currRGB,[1 1 3]);
        macbethChart_realImage{yy,xx} = repmat(currRGB,[21 21 1]);
    end
end

%% Compare values

% Take the mean of both real and simulated patches from the
% macbethChart cell matrix.
avgReal = zeros(4,6,3);
avgSim = zeros(4,6,3);
for yy = 1:4
    for xx = 1:6
        currROI_real = macbethChart_realImage{yy,xx};
        avgReal(yy,xx,:) = mean(mean(currROI_real,1),2);
        currROI_sim = macbethChart_simulatedImage{yy,xx};
        avgSim(yy,xx,:) = mean(mean(currROI_sim,1),2);
    end
end

% Plot the mean values as a scatter plot
avgReal_R = avgReal(:,:,1);avgReal_G = avgReal(:,:,2); avgReal_B = avgReal(:,:,3);
avgSim_R = avgSim(:,:,1); avgSim_G = avgSim(:,:,2); avgSim_B = avgSim(:,:,3);

figure; clf;
scatter(avgReal_R(:)./max(avgReal_R(:)),avgSim_R(:)./max(avgSim_R(:)),'r'); hold on;
scatter(avgReal_G(:)./max(avgReal_G(:)),avgSim_G(:)./max(avgSim_G(:)),'g'); hold on;
scatter(avgReal_B(:)./max(avgReal_B(:)),avgSim_B(:)./max(avgSim_B(:)),'b'); hold on;

% Plot best fit line
x = [avgReal_R(:)./max(avgReal_R(:)); avgReal_G(:)./max(avgReal_G(:)); avgReal_B(:)./max(avgReal_B(:))];
y = [avgSim_R(:)./max(avgSim_R(:)); avgSim_G(:)./max(avgSim_G(:)); avgSim_B(:)./max(avgSim_B(:))];
Fit = polyfit(x,y,1); % x = x data, y = y data, 1 = order of the polynomial.
Fit(2) = 0; % Make it go through the origin.
x = 0:0.1:1;
plot(x,polyval(Fit,x))

axis([0 1 0 1]); axis square;
grid on;
xlabel('Measured RGB Values')
ylabel('Simulated RGB Values')
set(gca,'FontSize',18)

%% Plot the macbeth charts for a visual comparison

scaling = macbethChart_simulatedImage{4,1}./macbethChart_realImage{4,1};
scaling = nanmean(nanmean(nanmean(scaling,1),2));
figure; clf;
subplot(2,1,1);
imageReal = flipud(cell2mat(macbethChart_realImage))*scaling;
imshow(imageReal);
title(sprintf('Color Patches from Real Image'))
[~, fileName] = fileparts(rawCameraFilePath);
imwrite(imageReal,sprintf('Measured_%s.png',fileName));

subplot(2,1,2);
imageSim = flipud(cell2mat(macbethChart_simulatedImage));
imshow(imageSim);
[~, fileName] = fileparts(oiFilePath);
title(sprintf('Color Patches from Simulated Image'))
imwrite(imageSim,sprintf('Simulated_%s.png',fileName));
