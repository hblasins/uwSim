function [scene, mappings] = underwaterMexximpRemodeller(scene, mappings, names, conditionValues, conditionNumber)

% This is an example of how to modify the incoming mexximp scene directly,
% with a "remodeler" hook funtion.  It modifies the scene struct that will
% be used during subsequent processing and rendering.
%
% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.

%% Get condition values

cameraDistance = rtbGetNamedNumericValue(names, conditionValues, 'cameraDistance', []);
% flashDistanceFromChart = rtbGetNamedNumericValue(names, conditionValues, 'flashDistanceFromChart', []);
% flashDistanceFromCamera = rtbGetNamedNumericValue(names, conditionValues, 'flashDistanceFromCamera', []);

%% Move camera
% 
% The chart is located 5000 mm in the +y-axis away from the origin in the
% default scene.

% % To get the camera to the right distance to the chart, we move it here.
moveDistance = 5000-cameraDistance;
cameraPosition = [0 moveDistance 0];

% build a lookat for the camera
cameraTransform = mexximpLookAt(cameraPosition, [0 10000 0], [0 0 1]);

% find the camera node
cameraNodeSelector = strcmp({scene.rootNode.children.name}, 'Camera');
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

%% Move the point light

% Point light starts at the same distance from the chart as the camera
% % To get the camera to the right distance to the chart, we move it here.
% moveDistanceY = 5000-flashDistanceFromChart;
% flashTranslate = [flashDistanceFromCamera moveDistanceY 0];
% 
flashNodeSelector = strcmp({scene.rootNode.children.name}, 'PointLight');
scene.rootNode.children(flashNodeSelector).transformation = mexximpTranslate([0 0 0]);

end