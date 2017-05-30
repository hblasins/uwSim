function WriteVSFFile(wavelengths,vsf,filename)
         

%          The VSF is a 2D matrix with the rows being the angles (0 to 180 degrees) and the columns being wavelength samples.
%          We read this in from a text file outputted by MATLAB code.
%          This first value should be the number of wavelengths in each spectrum.
%          This first row (after the first value) should be the wavelength samples. We need this to create the spectrum from sampled values.
%          E.g.
%
%          30
%          400 410 420 ... 700
%          0_1  0_2  0_3  ... 0_30
%          1_1  1_2  1_3  ... 1_30
%          ...
%          ...
%          180_1 180_2 180_3 ... 180_30
%
%          WARNING: VSF rows MUST be in degrees, at 1 degree intervals (i.e. 0,1,2,3...,178,179,180)
%          In other words there MUST be 181+1+1 = 183 rows in the text file

        
        % Write to a text file
        fileID = fopen(filename,'w');
        fprintf(fileID,'%s \n',num2str(length(wavelengths))); % Write number of wavelengths
        fprintf(fileID,'%s \n',num2str(wavelengths));
        for i = 1:size(vsf,1)
            fprintf(fileID,'%s \n',num2str(vsf(i,:)));
        end
        fclose(fileID);
        fprintf('VSF file written to %s \n',filename);
        
end