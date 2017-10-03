function [sig_a, wave] = createAbsorptionCurve(chlConc,cdomConc,varargin)

p = inputParser;
p.addRequired('chlConc',@isnumeric);
% Chlorophyll concentrations vary from 0.01 mg/m^3 for oceans, through 10 mg/m^-3 for coasts all the way to 100 mg/m^-3 for lakes.
p.addRequired('cdomConc',@isnumeric);
% Reasonable cdomConc values are [0, 0.1] for oceans, [0.1, 0.5] for lakes, up to ~10 for some rivers. 
p.addOptional('wave',400:10:700,@isvector);
p.addOptional('plankton',[0.0155 0.0169 0.017 0.0178 0.0184 0.0178 0.0181 0.0171 0.0146 0.0131 0.0121 0.0108 0.0097 0.0088 0.0078 0.0064 0.0052 0.0046 0.0048 0.0049 0.0041 0.0042 0.0049 0.0059 0.0061 0.0054 0.0076 0.0114 0.0111 0.0062 0.0016]);
p.addOptional('planktonWave',400:10:700);

p.parse(chlConc, cdomConc, varargin{:});
inputs = p.Results;

wave = inputs.wave;

% Read pure water absorption curve (unknown data source)
% pureWaterSpectrum = [0.03508;0.0331178181818182;0.0304084545454545;0.0285622727272727;0.0261179090909091;0.0249024545454546;0.0230985909090909;0.0214038181818182;0.0199097272727273;0.0188507272727273;0.0176193636363636;0.0178593261623872;0.0180950159611381;0.0182952512144344;0.0185011228313671;0.0189912671755725;0.0198799569743234;0.0207700104094379;0.0218096092990978;0.0235416627342123;0.025760534351145;0.0292073150589868;0.0329300957668286;0.0371120582928522;0.0402446571825121;0.0420976197085357;0.0441563095072866;0.0466933629424011;0.0495247800138792;0.052768560721721;0.0562924323386537;0.0610131221374046;0.06542926648161;0.0707649562803609;0.0768314642609299;0.0858581540596808;0.100351889312977;0.121569090909091;0.148863636363636;0.180922121212121;0.221221818181818;0.243104545454545;0.257201818181818;0.267508181818182;0.277863333333333;0.285397272727273;0.292786515151515;0.299452727272727;0.306260909090909;0.314608181818182;0.325243636363636;0.348965984848485;0.374211818181818;0.393068863636364;0.407539393939394;0.422467622377622;0.441645885780886;0.470824755244755;0.505271958041958;0.557488251748252;0.617854545454545];
% pureWaterWave = [400;405;410;415;420;425;430;435;440;445;450;455;460;465;470;475;480;485;490;495;500;505;510;515;520;525;530;535;540;545;550;555;560;565;570;575;580;585;590;595;600;605;610;615;620;625;630;635;640;645;650;655;660;665;670;675;680;685;690;695;700];

% Data from Mobley C. 'Light and Water', 1994, page. 90
pureWaterWave = 200:10:800;
pureWaterSpectrum = [3.07, 1.99, 1.31, 0.927, 0.720, 0.559, 0.457, 0.373, 0.288, 0.215, 0.141, 0.105, 0.0844, 0.0678, 0.0561,...
                     0.0463, 0.0379, 0.03, 0.022, 0.0191, 0.0171, 0.0162, 0.0153, 0.0144, 0.0145, 0.0145, 0.0156, 0.0156,...
                     0.0176, 0.0196, 0.0257, 0.0357, 0.0477, 0.0507, 0.0558, 0.0638, 0.0708, 0.0799, 0.108, 0.157, 0.244, 0.289,...
                     0.309, 0.319, 0.329, 0.349, 0.4, 0.43, 0.45, 0.5, 0.65, 0.839, 1.169, 1.799, 2.38, 2.47, 2.55, 2.51, 2.36, 2.16, 2.07];
                     

pureWaterSpectrum = interp1(pureWaterWave,pureWaterSpectrum,inputs.wave);
        
% Absorption from non-algal particles (NAP)
% See Bricaud 1998
if chlConc ~= 0
    cnap = 0.0124*chlConc^0.724*exp(-0.011*(inputs.wave-440));
else
    cnap = 0;
end

% Absorption from colored dissolved organic matter (CDOM a.k.a. gelbstoff)
if(cdomConc ~= 0)
    cdom = cdomConc*exp(-0.014*(inputs.wave - 440));
else
    cdom = 0;
end

% Absorption from phytoplankton
if (chlConc ~= 0) 
    % Get plankton absorption at 440 in order to scale it by the cholorophyll concentration
    plankton = interp1(inputs.planktonWave,inputs.plankton,inputs.wave);
    plankton440 = interp1(inputs.wave,plankton,440);
    
    scale = (0.0378*chlConc^0.627)/plankton440;
    planktonAbsorption = plankton*scale;
else 
    planktonAbsorption = 0;
end

% Total absorption
sig_a = pureWaterSpectrum(:) + cnap(:) + cdom(:) + planktonAbsorption(:);
        

end
