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
    beta = b*interp1(angles,angleDistr,alpha(:),'linear',0);
    beta = reshape(beta,[nRadii nDistSamples]);
    
    
    tmp = exp(-b*Ddiag).*beta.*exp(-b*Dprim);
    Ir = sum(tmp,2)*I0*dDist;
    
    
    figure;
    hold on; grid on; box on;
    title(sprintf('# distance samples %i',nDistSamples));
    plot(r,Ir,'g');
    
    %% Uniform distance sampling
    
    numRays = 10000;
    uf.rr = zeros(numRays,1);
    uf.angle = zeros(numRays,1);
    uf.int = zeros(numRays,1);
    for i=1:numRays;
        
        uf.d(i) = rand(1,1)*distance;
        uf.angle(i) = drawFromDistribution(angles,angleDistr);
        uf.rr(i) = uf.d(i)*tand(uf.angle(i));
 
        bt = b*interp1(angles,angleDistr,uf.angle(i),'linear',0);
        uf.int(i) = exp(-b*(distance-uf.d(i)))*bt*exp(-b*(sqrt(uf.d(i).^2+uf.rr(i).^2)))*I0;
    end
    
    binEdges = r;
    binWidth = binEdges(2)-binEdges(1);
    binCenters = binWidth/2:binWidth:binEdges(end);
    
    
    binIndx = discretize(uf.rr(:),binEdges);
    validLocs = ~isnan(binIndx(:));
    uf.IrEst = accumarray(binIndx(validLocs),uf.int(validLocs));
    uf.numRays = accumarray(binIndx(validLocs),ones(sum(validLocs),1));
    
    ufIrEst = zeros(length(binCenters),1);
    ufIrEst(1:length(uf.IrEst)) = uf.IrEst; %./uf.numRays;
    
    plot(binCenters(:),ufIrEst,'b','LineWidth',2);
    
    
    %% Non-Uniform distance sampling
    
    
    dstDistr = 1:length(d);
    dstDistr = dstDistr/(sum(dstDistr));
    
    nf.rr = zeros(numRays,1);
    nf.angle = zeros(numRays,1);
    nf.int = zeros(numRays,1);
    for i=1:numRays;
                
        nf.d(i) = drawFromDistribution(d,dstDistr);
        nf.angle(i) = drawFromDistribution(angles,angleDistr);
        nf.rr(i) = nf.d(i)*tand(nf.angle(i));
 
        bt = b*interp1(angles,angleDistr,nf.angle(i),'linear',0);
        nf.int(i) = exp(-b*(distance-nf.d(i)))*bt*exp(-b*(sqrt(nf.d(i).^2+nf.rr(i).^2)))*I0;
    end
    
    %%
    
    
    binIndx = discretize(nf.rr(:),binEdges);
    validLocs = ~isnan(binIndx(:));
    nf.IrEst = accumarray(binIndx(validLocs),nf.int(validLocs));
    nf.numRays = accumarray(binIndx(validLocs),ones(sum(validLocs),1));
    
    nfIrEst = zeros(length(binCenters),1);
    nfIrEst(1:length(nf.IrEst)) = nf.IrEst; %./nf.numRays;
    
  
    plot(binCenters(:),nfIrEst,'r','LineWidth',2);
    
    
end
