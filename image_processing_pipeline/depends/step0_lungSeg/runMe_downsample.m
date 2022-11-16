tica = tic;

warning('off','all');

%% REPLACE '...' WITH ABSOLUTE PATH TO ROOT FOLDER 'image_processing_pipeline'
% addpath(genpath('.../image_processing_pipeline/depends'));
% folderName_CTin = '.../image_processing_pipeline/files_in_CTscans';
% folderName_maskOut = '.../image_processing_pipeline/files_out_predLungMasks';
% folderName_depends = '.../image_processing_pipeline/depends';


%% Save folder paths to temporary file
X={folderName_CTin; folderName_maskOut; folderName_depends};
save(fullfile(folderName_depends, 'pathsTemp.mat'), 'X');


%% Extract names of all .img files in folder at folderName_CTin
fileNames = dir(fullfile(folderName_CTin, '*img'));
n = size(fileNames);
n = n(1);
     
fprintf('\n');
X = ['Detected ',num2str(n),' image files in folder "files_in_CTscans"'];
disp(X)
fprintf('\n');
fprintf('Downsampling and padding images to 256x256x256 voxels...')

%% Save filenames to file
save(fullfile(folderName_CTin, 'fileNamesTemp.mat'), 'fileNames');

%% Make directory for predicted lung masks
mkdir(folderName_maskOut);

%% Downsample all .img files in folder at folderName_CTin and save to Nifti
for i=1:n
    fileName = fileNames(i).name;
    aSize = img2nii_downsample(folderName_CTin, folderName_maskOut, fileName);
end


toca = toc(tica);
fprintf('%f', toca/60)
fprintf(' minutes')
fprintf('\n');

%% Print matlab connfiguration details
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
fprintf('\n');
fprintf('\n');


%% Exit Matlab
exit;
