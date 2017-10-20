function [ res ] = drawFromDistribution( vals, probs )

qAngles = 0:0.01:max(vals);
pdf = interp1(vals,probs,qAngles,'linear');
pdf(pdf < 0) = 0;
pdf = pdf/sum(pdf);

cdf = cumsum(pdf);
[cdf, mask] = unique(cdf);
angles = qAngles(mask);

query = rand(1,1);
res = interp1(cdf,angles,query,'linear',0);


end

