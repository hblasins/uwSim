% close all;
clear all;
clc;

% Distance to the target
distance = 10;

% Radius is the distance from the point where the ray intersects the sensor
% plane.
nRadii = 100;
rMax = 20;
r = linspace(0,rMax,nRadii)';
dRadii = r(2)-r(1);

binEdges = r;
binWidth = binEdges(2)-binEdges(1);
binCenters = binWidth/2:binWidth:binEdges(end);

% Initial light intensity
I0 = 1;

% Scattering coefficient
b = 0.001;

% Phase function
nAngles = 1000;
angleMax = 90;
angles = linspace(0,angleMax,nAngles);
dAngles = angles(2)-angles(1);

angleDistr = exp(-((angles-0).^2)/100);
angleDistr = angleDistr/(sum(angleDistr));


for nDistSamples = 10;
    
    %% The 'Ground Truth' model
    %  We approximate the integral.
    
    % Equal width distance intervals along the ray
    d = linspace(0,distance,nDistSamples);
    dDist = d(2) - d(1);
    
    R = repmat(r,[1 nDistSamples]);
    D = repmat(d,[nRadii 1]);
    Dprim = distance - D;
    Ddiag = sqrt(R.^2 + D.^2);
    
    alpha = max(atand(R./D),0);
    
    % VSF
    beta = interp1(angles,angleDistr,alpha(:),'linear',0);
    beta = reshape(beta,[nRadii nDistSamples]);
    
    
    tmp = exp(-b*Ddiag).*(b*beta).*exp(-b*Dprim);
    Ir = sum(tmp,2)*I0*dDist;
    
    
    figure;
    hold on; grid on; box on;
    title(sprintf('# distance samples %i',nDistSamples));
    plot(r,Ir,'g');
    
    
    rId = 1:1:nRadii;
    figure; 
    hold on; grid on; box on;
    plot(d,tmp);
    xlabel('Distance');
    
    
    % Probability f(r|d)
    
    tmp = probRgivenD(d(2:end),angles(:),angleDistr(:),r);
    
    tst = tmp/distance;
    tst(isnan(tst) | isinf(tst)) = 0;
    tst = tst./repmat(sum(tst,2),[1 nDistSamples-1]);
    
    figure;
    plot(d(2:end),tst');
    
    
end
