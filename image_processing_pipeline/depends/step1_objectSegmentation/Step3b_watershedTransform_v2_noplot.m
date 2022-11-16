function Step3bout = Step3b_watershedTransform_v2

%% USER DEFINED VARIABLES


%% specify binarized/coregistered scans to load Step2
Step2_output_file = dir(['**/','files_out_predTumorMasks/Step2_imageCoregistration_output', '/*.mat']);
Step2_output_folder = Step2_output_file.folder;
Step2_output_file = strsplit(Step2_output_file.name,'.mat');
Step2_output_file = char(Step2_output_file(1));

%% Get current folder
pwdOut = pwd;

%% load all binarized/coregistered scans from Step3
load(fullfile(Step2_output_folder, [Step2_output_file '.mat']));

%n1tmp = size(XgrayCR);
n1tmp = size(Xcr);
n1 = n1tmp(2)-1;

%% Add a column to Xcr for watershed results
Xcr(1).watershed=[];
Xcr(1).watershedWarped=[];

%% Create directory for watershed results
timestamp = datestr(now,30);
mkdir('files_out_predTumorMasks/Step3b_watershedTransform_output/');
cd 'files_out_predTumorMasks/Step3b_watershedTransform_output/'


%% loop over all images
for i = 1:n1
    
    a = size(Xcr(i).tformMask);

    %% Extract orignial binarized image and apply geometric transforms
    VtmpBW = 1*(Xcr(i).binaryImageIn);
    tform_mask = Xcr(i).tformMask;
    
    %% Write binary image to Nifti file
    niftiwrite(int8(VtmpBW), 'BVtmpBW.nii');
    
    copyfile(fullfile(pwdOut, 'depends/step1_objectSegmentation/watershedAVW'), 'watershedAVN');
    copyfile(fullfile(pwdOut, 'depends/step1_objectSegmentation/watershedAVW.c'), 'watershedAVN.c');
    system('chmod 764 watershedAVN');  
    system('chmod 764 watershedAVN.c');  
    
    %% Perform watershed segmentation using Analyze
    [x,y] = system('./watershedAVN -i BVtmpBW.nii -o BVtmpBW_watershed');
    
    
    %% Read watershed segmentation results back into MATLAB
    tmpBW_watershed = analyze75read('BVtmpBW_watershed.img');
    
    %% Reshape and add to Xcr (output) array
    Xcr(i).watershed = int8(rot90(tmpBW_watershed,3));
    
    %% Warp watershed output to reference scan and add to Xcr (output) array
    if a(2)==1
        tmpBW_watershedWarped = imwarp(rot90(tmpBW_watershed,3), tform_mask, 'OutputView', imref3d(size(tmpBW_watershed)), 'interp', 'nearest');
        Xcr(i).watershedWarped = int8(tmpBW_watershedWarped);
    else
        tmpBW_watershedWarped = rot90(tmpBW_watershed,3);
        Xcr(i).watershedWarped = int8(tmpBW_watershedWarped);
    end
    
    
    %% Delete watershed results from working folder
    system('rm -f BVtmpBW_watershed*');
    system('rm -f BVtmpBW.nii*');
    
end


system('rm -f watershedAVN');
system('rm -f watershedAVN.c');
    
%% Save updated results (Step 2 results + watershed results) to working folder
fileName2 = [Step2_output_file, '_withWatershed_', timestamp];  % create file name
save(fileName2, 'Xcr', '-v7.3')

cd '../'
cd '../'

end