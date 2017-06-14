function [scene, mappings] = mexximpRemodellerStaggered3D(scene, mappings, names, conditionValues, conditionNumber)

%% Get condition values

cameraPosition = rtbGetNamedNumericValue(names, conditionValues, 'cameraPosition', []);

%% Move camera

% build a lookat for the camera
cameraTransform = mexximpLookAt(cameraPosition', [0 5000 0], [0 0 1]);

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