function out = meannan(in)

% This function works like nanmean from the Statistics Toolbox.
% It operates on 2D arrays only.
%
% Copyright, Henryk Blasinski 2017

out = [1 size(in,2)];

for i=1:size(in,2)
    loc = isnan(in(:,i)) == 0;
    out(i) = mean(in(loc,i));
end

end