function Step5a_out = Step5a_write_watershedArrays_to_nifti

mkdir 'files_out_predTumorMasks/Step5_generateFeatureArray_output';

%% Load matlab file containing paths to original CT images
Xcr_path = dir('files_out_predTumorMasks/Step3b_watershedTransform_output/*.mat');
load(fullfile(Xcr_path.folder, Xcr_path.name));

n = size(Xcr);
n = n(2)-1;

filenames = Xcr.filenames;
save('files_out_predTumorMasks/Step5_generateFeatureArray_output/Xcr_filenames.mat', 'filenames')

for i=1:n
    niftiwrite(Xcr(i).watershed, fullfile('files_out_predTumorMasks/Step5_generateFeatureArray_output', ['watershedImage' num2str(i) '.nii']));
    niftiwrite(Xcr(i).watershedWarped, fullfile('files_out_predTumorMasks/Step5_generateFeatureArray_output', ['watershedImageWarped' num2str(i) '.nii']));
end

end
