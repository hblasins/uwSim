function rootPath=uwSimulationRootPath()

% function rootPath=uwSimulationRootPath()
%
% Returns the absolute path for the root directory.
%
% Copyright, Henryk Blasinski 2017

rootPath = which('uwSimulationRootPath');
rootPath = fileparts(rootPath);

end
