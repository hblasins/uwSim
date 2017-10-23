close all;
clear all;
clc;

% Distance to the target
distance = 10;

% Radius is the distance from the point where the ray intersects the sensor
% plane.
nRadii = 1000;
rMax = 20;
r = linspace(0,rMax,nRadii)';
dRadii = r(2)-r(1);

binEdges = r;
binWidth = binEdges(2)-binEdges(1);
binCenters = binWidth/2:binWidth:binEdges(end);


% Phase function
nAngles = 1000;
angleMax = 90;
angles = linspace(0,angleMax,nAngles);
dAngles = angles(2)-angles(1);

angleDistr = exp(-((angles-0).^2)/100);
angleDistr = angleDistr/(sum(angleDistr)*dAngles);
angleDistr = angleDistr(:);

% Discrete vs. continuous valued distributions !!!
%Theory

pdf = probRgivenD(distance,angles,angleDistr,r);

% figure; 
% plot(rr,angleDistr);

% Practice
nRays = 10000;
angle = zeros(nRays,1);
radius = zeros(nRays,1);
for i=1:nRays
   
     angle(i) = drawFromDistribution(angles,angleDistr);
     radius(i) = distance*tand(angle(i)); 
    
end

figure;
hold on; grid on; box on;
hst = histcounts(radius,binEdges);
hst = hst/(sum(hst)*binWidth);
bar(binCenters,hst);
plot(r,pdf,'g','LineWidth',2);
xlim([0 10]);
