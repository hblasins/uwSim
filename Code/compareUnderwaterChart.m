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
oiFilePath = '/Users/trishalian/GitRepos/render_toolbox/UnderwaterChart/renderings/PBRT/UnderwaterChart_1.00_0.00_0.00_0.00_0.00_0.00.mat'; % simulated
rawCameraFilePath = '/Users/trishalian/Dropbox/Images/Underwater/07/IMG_4924.CR2'; % real


%% Run OI through a sensor/ip

[rgbImageSimulated, rgbAverageSimulated] = processSimulatedChart(oiFilePath);

%% Extract patches from real image

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
avgMeasured = cellfun(@nanmean,data,'UniformOutput',false);

% Rearrange into macbeth chart for easier viewing and processing
rgbAverageMeasured = zeros(4,6,3);
for yy = 1:4
    for xx = 1:6
        id = (xx-1)*4 + (4-yy)+1;
        currRGB = avgMeasured{id};
        currRGB = reshape(currRGB,[1 1 3]);
        rgbAverageMeasured(yy,xx,:) = currRGB;
    end
end

%% Compare values

% Plot the mean values as a scatter plot
avgReal_R = rgbAverageMeasured(:,:,1); avgReal_G = rgbAverageMeasured(:,:,2); avgReal_B = rgbAverageMeasured(:,:,3);
avgSim_R = rgbAverageSimulated(:,:,1); avgSim_G = rgbAverageSimulated(:,:,2); avgSim_B = rgbAverageSimulated(:,:,3);

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

scaling = rgbAverageSimulated(4,1)./rgbAverageMeasured(4,1);
scaling = nanmean(nanmean(nanmean(scaling,1),2));
fprintf('Approximate scaling factor is %0.2f \n',scaling);
figure; clf;
subplot(2,1,1);
imageReal = flipud(imresize(rgbAverageMeasured,50,'nearest'))*scaling;
imshow(imageReal);
title(sprintf('Color Patches from Real Image'))
[~, fileName] = fileparts(rawCameraFilePath);
imwrite(imageReal,sprintf('Measured_%s.png',fileName));

subplot(2,1,2);
imageSim = flipud(imresize(rgbAverageSimulated,50,'nearest'));
imshow(imageSim);
[~, fileName] = fileparts(oiFilePath);
title(sprintf('Color Patches from Simulated Image'))
imwrite(imageSim,sprintf('Simulated_%s.png',fileName));
