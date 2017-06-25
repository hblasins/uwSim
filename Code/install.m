% Add relevant directories with source code to Matlab path.
%
% Copyright, Henryk Blasinski 2017

close all;
clear all;
clc;

% When Matlab is started with the launcher, the PATH variable is empty and
% hence no calls to binary programs will work

% By default, docker-machine and docker for mac are installed in
% /usr/local/bin:
initPath = getenv('PATH');
if isempty(strfind(initPath, '/usr/local/bin'))
    disp('Adding ''/usr/local/bin'' to PATH.');
    setenv('PATH', ['/usr/local/bin:', initPath]);
end


[codePath, parentDir] = uwSimRootPath;

addpath(codePath);

addpath(fullfile(codePath,'Utilities'));
addpath(fullfile(codePath,'Remodellers'));
addpath(fullfile(codePath,'VideosAndFigures'));
addpath(genpath(fullfile(codePath,'ISETtools')));

addpath(fullfile(parentDir,'Parameters'));
