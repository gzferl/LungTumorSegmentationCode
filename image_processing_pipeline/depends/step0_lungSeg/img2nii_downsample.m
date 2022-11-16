function aSize = img2nii_downsample(folderName_CTin, folderName_maskOut, fileName)

%% Read .img files into matlab (.img is the Analyze file format)
imagei_orig = analyze75read(fullfile(folderName_CTin, fileName));

%% Downsample image and mask and pad with zeroes so that dimension is 256 x 256 x 256.  If dimensions of input image are <= 256 x 256 x 256 then only padding is needed
% Downsample image and mask
imagei_down = imresize3(imagei_orig, 'scale', 0.8, 'method', 'nearest', 'Antialiasing', true);

% Pad arrays with zeroes to 256 x 256 x 256
[imagei_down, aSize, padDim] = pad3(imagei_down, 256, 256, 256);

%% Save original image to Nifti (.nii) 
niftiwrite(imagei_orig, fullfile(folderName_maskOut, strrep(fileName,'.img','_orig.nii')));

%% Save downsampled image to Nifti (.nii) 
niftiwrite(imagei_down, fullfile(folderName_CTin, strrep(fileName,'.img','.nii')));

%% Save padding dimensions to file
padOut.dim = padDim;
padOut.sizeDown = aSize;
padOut.sizeOrig = size(imagei_orig);
save(fullfile(folderName_CTin, strrep(fileName,'.img','.mat')), 'padOut');
end
