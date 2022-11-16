function Step2out = Step2_imageCoregistration_v2

%% USER DEFINED VARIABLES
% USER DEFINED VARIABLES - BEGIN

% Parameters for MATLAB geometric object transformation optimizer
%optimizer.GradientMagnitudeTolerance (default = 1.000000e-04)
gradTol = 5e-4;
%optimizer.MinimumStepLength (default = 1e-5)
minStep = 5e-5;
%optimizer.MaximumStepLength (default = 0.0625)
maxStep = 0.0625;
%optimizer.MaximumIterations (default = 100)
maxIt = 100;
%optimizer.RelaxationFactor (default = 0.5)
relaxFac = 0.9;

% USER DEFINED VARIABLES - END

% Specify file to load from Step 1 (do not include .mat extension)
AllScansBinarized = dir(['**/','files_out_predTumorMasks/Step1_imagePreprocessing_output', '/*.mat']);
AllScansBinarized = strsplit(AllScansBinarized.name,'.mat');
AllScansBinarized = char(AllScansBinarized(1));



%% Get current folder
pwdOut = pwd;

%% load binarized scans from Step1; will load object 'X' which contains masked, binarized, eroded images
load(fullfile('files_out_predTumorMasks/Step1_imagePreprocessing_output', [AllScansBinarized '.mat']));


n1 = length(X) - 1; 

%% Specify variables for storage of coregistered binary images and geometric object transformation matrices
%Xcr(1).filenames = X.filenames; %AUG 2021
Xcr(1).filenames = X(length(X)).filenames; %AUG 2021 filenmaes stored in last element in X object
Xcr.MaskIn = [];
Xcr.binaryImageIn = [];
Xcr.tformMask = [];

%% Create folder to store results
timestamp = datestr(now,30);
filename_tmp = fullfile([AllScansBinarized '_' timestamp]);

mkdir('files_out_predTumorMasks/Step2_imageCoregistration_output');


%% Read reference mask into MATLAB
% mask_reference = niftiread('REF_LUNG_MASK_FOR_COREGISTRATION.nii');  
mask_reference = niftiread('100_090117_lung_orig-REF_LUNG_MASK_FOR_COREGISTRATION.nii');

sizeV = size(mask_reference);
nx = sizeV(1);
ny = sizeV(2);
nz = sizeV(3);

% Add reference mask to output structure
Xcr(n1+1).MaskIn = logical(mask_reference);

% Extract binarized reference image from input structure and add to output structure
VtmpBW_ref = reshape(logical(mask_reference),nx,ny,nz); % logical array
Xcr(n1+1).binaryImageIn = VtmpBW_ref;

%% loop over all images
for (i = 1:n1)
        %% Read grayscale image into MATLAB
        cd 'files_out_predTumorMasks/Step1_imagePreprocessing_output';
        d = dir(fullfile(['file' num2str(i) '_*']));
        V_filename = d.name;
        Vtmp = niftiread(V_filename);
        cd '../../';
 
        
        %% Extract binarized image
        VtmpBW = X(i).Vout; 

        
        %% Save orignial binarize image to structure
        Xcr(i).binaryImageIn = logical(VtmpBW);
        
        
        %% Load tissue mask
        mask_tmp = niftiread(X(i).lung_mask); 
        
        %% Save original mask to structure
        Xcr(i).MaskIn = logical(mask_tmp);
   
        
        %% Generate geometric object transformation based on mask coregistration
        [optimizer, metric] = imregconfig('monomodal');
        optimizer.GradientMagnitudeTolerance = gradTol;
        optimizer.MinimumStepLength = minStep;
        optimizer.MaximumStepLength = maxStep;
        optimizer.MaximumIterations = maxIt;
        optimizer.RelaxationFactor = relaxFac;
        
        
        lastwarn('');
        
        tform_mask = imregtform(mask_tmp, mask_reference, 'affine', optimizer, metric);
        
        % Try re-running imregtform with lower max step length if warning is thrown
        if length(lastwarn) > 0
            optimizer.MaximumStepLength = 0.001;
            tform_mask = imregtform(mask_tmp, mask_reference, 'affine', optimizer, metric);
            optimizer.MaximumStepLength = maxStep;
        end
        
        
        %% Save geometric object transformation to Structure
        Xcr(i).tformMask = tform_mask;
        
        %% Warp mask using tform_mask
        mask_warped = imwarp(mask_tmp, tform_mask, 'OutputView', imref3d(size(mask_tmp)));
        
        %% Warp binary image using tform_mask
        VtmpBW_warped = imwarp(VtmpBW, tform_mask, 'OutputView', imref3d(size(VtmpBW)));
        
        %% Warp grayscale image using tform_mask
        Vtmp_warped = imwarp(Vtmp, tform_mask, 'OutputView', imref3d(size(Vtmp)));
        
        % Replace 0 with -1000 in Vtmp_warped
        Vtmp_warped(Vtmp_warped == 0) = -1000;
        
        % Save warped grayscale image to file
        fileName1 = fullfile(pwdOut, 'files_out_predTumorMasks/Step2_imageCoregistration_output/', ['file' int2str(i) '_warpedToRefScan_maxIt' int2str(maxIt) 'gradTol' int2str(gradTol) 'maxStep' int2str(maxStep) '_'  timestamp '.nii']);  % create file name
        niftiwrite(Vtmp_warped,fileName1)

        close all  
    
end

Xcr(n1+1).tformMask = 'Reference_Scan';

fileName2 = fullfile(pwdOut, ['files_out_predTumorMasks/Step2_imageCoregistration_output/All_masks_and_BinaryImages_warpedToRefScan_maxIt' int2str(maxIt) '_' timestamp]);  % create file name
save(fileName2, 'Xcr', '-v7.3')


end
