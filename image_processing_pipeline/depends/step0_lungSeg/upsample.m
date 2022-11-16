ticb = tic;

warning('off','all');

fprintf('\n');
fprintf('Upsampling predicted lung masks to original image dimensions...')

%% REPLACE '...' WITH ABSOLUTE PATH TO ROOT FOLDER 'image_processing_pipeline'
%addpath(genpath('.../image_processing_pipeline/depends'));

% Load folder paths and file name 
load('pathsTemp.mat');
folderName_CTin = cell2mat(X(1));
folderName_maskOut = cell2mat(X(2));
folderName_depends = cell2mat(X(3));
delete(fullfile(folderName_depends, 'pathsTemp.mat'));

%% Move Nifti files and batch log file to folderName_maskOut folder
movefile(fullfile(folderName_CTin, '*nii'), folderName_maskOut);
movefile(fullfile(folderName_depends, '../pred_lung_vnet-*'), folderName_maskOut);

%% Extract names of all .img files in folder at folderName_CTin
fileNames = dir(fullfile(folderName_CTin, '*img'));
n = size(fileNames);
n = n(1);

%% Upsample predicted lung masks
for i=1:n
    % Load downsampled lung mask i
    filenameLungi = fileNames(i).name;
    filenameLungi = strrep(filenameLungi,'image.img','lung.nii');
    lungMaski = niftiread(fullfile(folderName_maskOut, filenameLungi));
    
    % Remove small objects from lung mask (Keep only largest, connected object)
    CC = bwconncomp(lungMaski);
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~,idx] = max(numPixels);
    filtered_vol = false(size(lungMaski));
    filtered_vol(CC.PixelIdxList{idx}) = true;
    lungMaski = single(filtered_vol);
    lungMaskiUp = lungMaski;
    
    % Load padding data for file i
    filenameMati = fileNames(i).name;
    filenameMati = strrep(filenameMati,'.img','.mat');
    load(fullfile(folderName_CTin, filenameMati));

    % Extract size of downsampled image with padding
    sizeDownWithPad = size(lungMaski);
    xP = sizeDownWithPad(1);
    yP = sizeDownWithPad(2);
    zP = sizeDownWithPad(3);
    
    % Extract pre- and post-x,y,z padding sizes
    xprei = padOut.dim(1,1);
    yprei = padOut.dim(1,2);
    zprei = padOut.dim(1,3);
    x1posti = padOut.dim(2,1);
    y1posti = padOut.dim(2,2);
    z1posti = padOut.dim(2,3);
    
    % Crop lung mask to remove padding
    lungMaskiUp(1:xprei, :, :) = 2;
    lungMaskiUp(:, 1:yprei, :) = 2;
    lungMaskiUp(:, :, 1:zprei) = 2;
    lungMaskiUp((xP-x1posti+1):xP, :, :) = 2;
    lungMaskiUp(:, (yP-y1posti+1):yP, :) = 2;
    lungMaskiUp(:, :, (zP-z1posti+1):zP) = 2;
    lungMaskiUp(lungMaskiUp==2) = [];
    lungMaskiUp = reshape(lungMaskiUp, padOut.sizeDown);
    
    % Upsample lung mask
    lungMaskiUp = imresize3(lungMaskiUp, padOut.sizeOrig, 'method', 'nearest');
    
    % Write upsampled lung mask to file
    niftiwrite(lungMaskiUp, fullfile(folderName_maskOut, strrep(filenameLungi,'.nii','_orig.nii')))
    
    % Write original image with upsampled mask to file
    saveCTimgWithMask(folderName_maskOut, strrep(filenameMati,'.mat','_orig.nii'), strrep(filenameLungi,'.nii','_orig.nii'))
end

delete(fullfile(folderName_CTin, '*.mat'));

tocb = toc(ticb);
fprintf('%f', tocb/60)
fprintf(' minutes')
fprintf('\n');

%% Print matlab configuration details
fprintf('\n');
fprintf('============================');
fprintf('\n');
ver('')
fprintf('============================');
fprintf('\n');
fprintf('MATLAB toolboxes used for this analysis:')
fprintf('\n');
license('inuse')
fprintf('============================');
fprintf('\n');  

