function figureHandle  = plotPhaseFunction(phaseTextFile, wavelength)

%% Read text file
fileID = fopen(phaseTextFile,'r');
formatSpec = '%f';
A = fscanf(fileID,formatSpec);

numWavelengths = A(1);
wls = A(2:(1+numWavelengths));

A = A(1+numWavelengths+1:end);
phaseFunction = reshape(A,[numWavelengths,180])';

%% Plot

[~,wlsIdx] = min(abs(wls-wavelength)); %index of closest value
beta = phaseFunction(:,wlsIdx);
angles = 0:179;

figureHandle = figure;
plot(angles,beta);
title(strcat(strcat('Phase function for \lambda = ',num2str(wavelength)),' nm'))
ylabel('phase function $\tilde{\beta} (sr^{-1})$','Interpreter','Latex')
xlabel('scattering angle $\psi$ (deg)','Interpreter','Latex')
xlim([angles(1) angles(end)])
set(gca,'YScale','log');
grid on

end

