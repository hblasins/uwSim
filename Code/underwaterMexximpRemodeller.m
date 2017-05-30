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

%% Add a distant light


ambient = mexximpConstants('light');
ambient.position = [0 0 0]';
ambient.type = 'directional';
ambient.name = 'SunLight';
ambient.lookAtDirection = [0 0 -1]';
ambient.ambientColor = 10*[1 1 1]';
ambient.diffuseColor = 10*[1 1 1]';
ambient.specularColor = 10*[1 1 1]';
ambient.constantAttenuation = 1;
ambient.linearAttenuation = 0;
ambient.quadraticAttenuation = 1;
ambient.innerConeAngle = 0;
ambient.outerConeAngle = 0;

scene.lights = [scene.lights ambient];

ambientNode = mexximpConstants('node');
ambientNode.name = ambient.name;
ambientNode.transformation = eye(4);

scene.rootNode.children = [scene.rootNode.children, ambientNode];


end