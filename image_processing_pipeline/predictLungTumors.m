%% NOTES FOR RUNNING SCRIPT ON AN HPC
% Log in to cluster
% Navigate to root directory for this project
%       $ cd /absolute/path/to/image_processing_pipeline/
% load R, matlab and Analyze from the shell command line using the
% following (or equivalent) commands
%       $ module load matlab/2021a
%       $ module load analyze/12.0-1122
% run matlab script predictLungTumors.m
%
% FILE NAMING CONVENTIONS 
%   A) Nifti files in folder 'files_in_CTscans' must be named
%   *_SCANID_*.nii (only one '_' before SCANID; any number of '_' after
%   SCANID), where SCANID is an integer
%   B) Lung mask must be named SCANID_lungMask.img
%
% Script predictLungTumors.m assumes that lung masks have already been
% generated using script predictLungMask.sbatch and are stored in folder
% 'files_outpredLungMasks'
%
% Please run this script in MATLAB 2021a (or later version);


clear all

warning('off','all');

timerVal99 = tic;

%% REPLACE '...' WITH ABSOLUTE PATH TO ROOT FOLDER 'image_processing_pipeline'
%addpath(genpath('.../image_processing_pipeline/depends/'));

fprintf('\n');
%% load all .img file paths in current folder into array
img_folder = 'files_in_CTscans';
filenames = dir(['**/',img_folder, '/*.img']);
% Number of files found
nn = size(filenames);
n1 = nn(1);
fprintf('\n');
X = ['Detected ',num2str(n1),' image files in folder "', img_folder, '"'];
disp(X)
clear img_folder filenames nn n1 X

tica = tic;
fprintf('\n');
fprintf('Performing image preprocessing...')
Step1_imagePreprocessing_v2_noplot             % tumor segmentation script 1
toca = toc(tica);
fprintf('%f', toca/60)
fprintf(' minutes')
fprintf('\n');

ticb = tic;
fprintf('\n');
fprintf('Performing image coregistration...')
Step2_imageCoregistration_v2_noplot           % tumor segmentation script 2
tocb = toc(ticb);
fprintf('%f', tocb/60)
fprintf(' minutes')
fprintf('\n');

ticc = tic;
fprintf('\n');
fprintf('Performing watershed segmentation...')
Step3b_watershedTransform_v2_noplot            % tumor segmentation script 3 (uses Analyze)
tocc = toc(ticc);
fprintf('%f', tocc/60)
fprintf(' minutes')
fprintf('\n');

ticd = tic;
fprintf('\n');
fprintf('Writing watershed objects to file...')
Step5a_write_watershedArrays_to_nifti_noplot   % tumor segmentation script 5a
tocd = toc(ticd);
fprintf('%f', tocd/60)
fprintf(' minutes')
fprintf('\n');

tice = tic;
fprintf('\n');
fprintf('Generating watershed object feature array...')
Step5b_generateFeatureArray_noplot             % tumor segmentation script 5b
toce = toc(tice);
fprintf('%f', toce/60)
fprintf(' minutes')
fprintf('\n');

ticf = tic;
fprintf('\n');
fprintf('Predicting watershed object tissue class...')
Step6_predTissueClass_noplot                   % Predict tissues class for watershed objects and save tumor, vessel, and other ROI masks to nifti files
tocf = toc(ticf);
fprintf('%f', tocf/60)
fprintf(' minutes')
fprintf('\n');


fprintf('\n');
fprintf('============================');
fprintf('\n');
toc99 = toc(timerVal99);
fprintf('Entire analysis took %f', toc99/60)
fprintf(' minutes')

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