function [ rPdf ] = probRgivenD( distance, angles, angleDistr, r )

nDistances = size(distance,2);

rr = tand(angles(:))*distance;


dAngles = angles(2) - angles(1);

% a = interp1(angles,angleDistr,atand(r./distance),'linear');
% scale = (1./(1+(r./distance).^2))*(1/distance);

% pdf = angleDistr(:).*scale;
pdf = repmat(angleDistr(1:end-1)*dAngles,[1 nDistances])./diff(rr);
pdf(isnan(pdf) | isinf(pdf)) = 0;

for i=1:nDistances
    
    indices = find((rr(:,i)<Inf));
    rPdf(:,i) = interp1(rr(indices,i),pdf(indices,i),r,'linear');
    
end
end

