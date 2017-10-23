close all;
clear all;
clc;

% Distance to the target
distance = 10;

% Radius is the distance from the point where the ray intersects the sensor
% plane.
nRadii = 50;
rMax = 10;
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


for nDistSamples = 100;
    
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
    
    %{
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
    
    
    binIndx = discretize(uf.rr(:),binEdges);
    validLocs = ~isnan(binIndx(:));
    uf.IrEst = accumarray(binIndx(validLocs),uf.int(validLocs));
    uf.numRays = accumarray(binIndx(validLocs),ones(sum(validLocs),1));
    
    ufIrEst = zeros(length(binCenters),1);
    ufIrEst(1:length(uf.IrEst)) = uf.IrEst; %./uf.numRays;
    
    % plot(binCenters(:),ufIrEst,'b','LineWidth',2);
    
    
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
    
    binIndx = discretize(nf.rr(:),binEdges);
    validLocs = ~isnan(binIndx(:));
    nf.IrEst = accumarray(binIndx(validLocs),nf.int(validLocs));
    nf.numRays = accumarray(binIndx(validLocs),ones(sum(validLocs),1));
    
    nfIrEst = zeros(length(binCenters),1);
    nfIrEst(1:length(nf.IrEst)) = nf.IrEst; %./nf.numRays;
    
    %}
    
    %% Correct model
    numRays = 50000;
    cr.rr = zeros(numRays,1);
    cr.angle = zeros(numRays,1);
    cr.int = zeros(numRays,1);
    for i=1:numRays;
        
        cr.d(i) = rand(1,1)*distance;
        cr.angle(i) = drawFromDistribution(angles,angleDistr);
        cr.rr(i) = cr.d(i)*tand(cr.angle(i));
 
        bt = b*interp1(angles,angleDistr,cr.angle(i),'linear',0);
        cr.int(i) = exp(-b*(distance-cr.d(i)))*bt*exp(-b*(sqrt(cr.d(i).^2+cr.rr(i).^2)))*I0*dDist;
    end
    
    
    
    % First we need to bin the rays by radius and by distance at which
    % stattering occured. Next we average by the number of rays from a
    % particular distance, and sum them up.
    
    distBinId = discretize(cr.d,d);
    radBinId = discretize(cr.rr,binEdges);
    validLocs = ~isnan(radBinId(:));
    
    radBinId = radBinId(validLocs);
    distBinId = distBinId(validLocs);
    int = cr.int(validLocs);
    
    TMP = accumarray([radBinId(:), distBinId(:)],int);
    CNT = accumarray([radBinId(:), distBinId(:)],ones(length(int),1));
    TMP = TMP./CNT;
    TMP(isnan(TMP)) = 0;
    crIrEst = zeros(length(binCenters),1);
    crIrEst(1:size(TMP,1)) = sum(TMP,2);
    
    
    plot(binCenters(:),crIrEst,'mx');
    
    %{
    probDGivenR = CNT./repmat(sum(CNT,2),[1 size(CNT,2)]);
    figure;
    hold on; grid on; box on;
    plot(probDGivenR');
    %}
    
    %% Model where we weight by probability
    
    numRays = 50000;
    pw.rr = zeros(numRays,1);
    pw.angle = zeros(numRays,1);
    pw.int = zeros(numRays,1);
    pw.weight = zeros(numRays,1);
    for i=1:numRays;
        
        pw.d(i) = rand(1,1)*distance;
        pw.angle(i) = drawFromDistribution(angles,angleDistr);
        pw.rr(i) = pw.d(i)*tand(pw.angle(i));
 
        pw.weight(i) = interp1(binEdges,probRgivenD(pw.d(i),angles(:),angleDistr(:),binEdges),pw.rr(i));
        
        bt = b*interp1(angles,angleDistr,pw.angle(i),'linear',0);
        pw.int(i) = exp(-b*(distance-pw.d(i)))*bt*exp(-b*(sqrt(pw.d(i).^2+pw.rr(i).^2)))*I0*dDist;
        
    end
    
    radBinId = discretize(pw.rr,binEdges);
    validLocs = ~isnan(radBinId(:));
    

    int = pw.int(validLocs).*pw.weight(validLocs);
    
    TMP = accumarray(radBinId(:),int);
    CNT = accumarray(radBinId(:), pw.weight(validLocs));
    TMP = TMP./CNT;
    TMP(isnan(TMP)) = 0;
    
    pwIrEst = zeros(length(binCenters),1);
    pwIrEst(1:size(TMP,1)) = TMP;
    
    
    plot(binCenters(:),pwIrEst/max(pwIrEst)*max(crIrEst),'co');
    
    
    
end
