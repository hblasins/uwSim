close all;
clear all;
clc;

ieInit;

wave = 400:10:700;

sensorData = double(imread('IMG_3536.pgm'));
sensorData = sensorData/max(sensorData(:));
figure; imshow(sensorData);


fName = fullfile('.','Canon1DMarkIII');
camera = ieReadColorFilter(wave,fName);

sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSet(sensor,'filter transmissivities',camera);
sensor = sensorSet(sensor,'rows',3693);
sensor = sensorSet(sensor,'cols',5536);
sensor = sensorSet(sensor,'volts',sensorData);
sensor = sensorSet(sensor,'name','Canon');

vcAddObject(sensor);
sensorWindow();


ip = ipCreate;
ip = ipSet(ip,'name','Canon');
ip = ipCompute(ip,sensor);

vcAddObject(ip);
ipWindow();

