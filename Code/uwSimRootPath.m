function [rootPath, parentDir]=uwSimRootPath()

% function rootPath=uwSimRootPath()
%
% Returns the absolute path for the directory containing the computational
% multispectral flash code.
%
% Copyright, Henryk Blasinski 2017

rootPath = which('uwSimRootPath');
rootPath = fileparts(rootPath);

id = strfind(rootPath,'/');
parentDir = rootPath(1:(id(end)-1));

end
