function [ sensor,  cp, img, meta] = readCameraImage( path, sensor )

[directory, file] = fileparts(path);

% Read raw sensor image
cmd = sprintf('dcraw -v -r 1 1 1 1 -H 0 -o 0 -d -j -4 %s',path);
system(cmd);
fName = fullfile(directory,sprintf('%s.pgm',file));
img = double(imread(fName));
img = img/max(img(:));
delete(fName);


% Read shared metadata
fName = fullfile(directory,'params.xml');
data1 = xml2struct(fName);

% Read image specific metadata
fName = fullfile(directory,sprintf('%s.xml',file));
data2 = xml2struct(fName);

meta = data1.parameters;
fieldNames = fieldnames(data2.parameters);

for i=1:size(fieldNames)
    meta.(fieldNames{i}) = data2.parameters.(fieldNames{i});
end

% Create an ISET image sensor
sensor = sensorSet(sensor,'size',size(img));
sensor = sensorSet(sensor,'volts',img);

cp = eval(data2.parameters.macbethCorners.RAW.Text);

end

