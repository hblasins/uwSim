function val = vcAddObject(obj)
%Add and select an object to the vcSESSION data
%
%    val = vcAddObject(obj)
%
% The object is added to the vcSESSION global variable. The object type
% can be one of the ISET object types
%
%   SCENE, OPTICALIMAGE, ISA/SENSOR, IP/VCI, DISPLAY
%
% or their aliased names in vcEquivalentObjtype
%
% The new object value is assigned the next available (new) value. To see
% the object in the appropriate window, you call the window itself.
%
% Note that the optics, pixel, and display are attached to the optical
% image, sensor, and ip respectively.  They are not top level objects.
%
% Example:
%  scene = sceneCreate;
%  newObjVal = vcAddObject(scene);
%  sceneWindow;
%
% See also:  vcAddAndSelectObject.m
%
% Copyright ImagEval Consultants, LLC, 2013

%%
global vcSESSION;

% Get a value
% Makes objType proper type and forces upper case.
objType = obj.type;
val = vcNewObjectValue(objType);

%% Assign object to the vcSESSION global.

% Should be ieSessionSet, not this.
if exist('obj','var')
    switch lower(objType)
        case {'scene'}
            vcSESSION.SCENE{val} = obj;
        case {'opticalimage'}
            vcSESSION.OPTICALIMAGE{val} = obj;
        case {'sensor'}
            vcSESSION.ISA{val} = obj;
        case {'vcimage'}
            vcSESSION.VCIMAGE{val} = obj;
        case {'display'}
            vcSESSION.DISPLAY{val} = obj;
            
            %         case {'optics'}
            %             % Optics is part of OI
            %             vcSESSION.OPTICALIMAGE{val} = oiSet(vcSESSION.OPTICALIMAGE{val},'optics',obj);
            %
            %             %         case {'pixel'}
            %             % Pixel is part of sensor
            %             vcSESSION.ISA{val} = sensorSet(vcSESSION.ISA{val},'pixel',obj);
        otherwise
            error('Unknown object type');
    end
end

vcSetSelectedObject(objType,val);


return;
