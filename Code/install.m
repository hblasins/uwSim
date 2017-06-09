% Add relevant directories with source code to Matlab path.
%
% Copyright, Henryk Blasinski 2017

close all;
clear all;
clc;

[codePath, parentDir] = uwSimRootPath;

addpath(codePath);

addpath(fullfile(codePath,'Utilities'));
addpath(fullfile(codePath,'Parameters'));
