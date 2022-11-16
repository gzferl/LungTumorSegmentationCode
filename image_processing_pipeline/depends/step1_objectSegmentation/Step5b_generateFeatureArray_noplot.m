function Step5b_out = Step5b_generateFeatureArray
% NOTE: All watershed object features are based on non-warped image (in native coordinate system),
%       except object Centroid, which is based on the reference-scan warped image


%% Load matlab file containing paths to original CT images
cd 'files_out_predTumorMasks/Step5_generateFeatureArray_output/';
load('Xcr_filenames.mat');
n = size(filenames);
n = n(1);

%% Load matlab file containing centering (C) and scaling (S) values for data normalization (these were calculated for the training data set)
load('../../depends/step1_objectSegmentation/normalizeFuncParam_C_3class_sizeCutoff0.mat');
load('../../depends/step1_objectSegmentation/normalizeFuncParam_S_3class_sizeCutoff0.mat');

for i=1:n
    
    % Read nifti file into MATLAB
    Vwi_warped = niftiread(fullfile(['watershedImageWarped' num2str(i) '.nii']));
    Vwi = niftiread(fullfile(['watershedImage' num2str(i) '.nii']));
    zDim=size(Vwi);
    zDim = zDim(3);
    
    % Read grayscale image into MATLAB
    Vi_foldername = filenames(i).folder;
    Vi_foldername = strrep(Vi_foldername, 'files_in_CTscans', 'files_out_predLungMasks');
    Vi_filename = filenames(i).name;
    Vi_filename = strrep(Vi_filename, 'image.img', 'image_orig_wLungMask.nii');
    Vi = niftiread(fullfile(Vi_foldername, Vi_filename));
    
    
    % Calculate number of segments
    numSeg = max(unique(Vwi));
    
    % extract region properties
    Vwi_features = regionprops3(Vwi, Vi, 'all');
    featureNames = Vwi_features.Properties.VariableNames;
    featureNames = [featureNames 'watershedSegment' 'Tissue'];
    
    % extract Centroids from warped watershed image
    Vwi_warped_centroid = regionprops3(Vwi_warped, 'Centroid');
    
    % Update feature array with Centroids from warped watershed image
    Vwi_features.Centroid = Vwi_warped_centroid.Centroid;
    
    watershedSeg = [];
    
    for(j=1:numSeg)
        watershedSeg = [watershedSeg j];
    end
    
    % reshape vectors to talbe dimensions
    watershedSeg = reshape(watershedSeg,numSeg,1);
    
    % update feature table
    Vwi_features = [Vwi_features table(watershedSeg)];
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%
    
    A = Vwi_features;
    
    %% Calculate Fractional Anisotropies
    eigenValues_tmp = A.EigenValues;
    eigenValues=[eigenValues_tmp{:}];
    eigenValuesT = transpose(eigenValues);
    eX=eigenValuesT(:,1);
    eY=eigenValuesT(:,2);
    eZ=eigenValuesT(:,3);
    FA = sqrt(0.5) * ((sqrt((eX-eY).^2 + (eY-eZ).^2 + (eZ-eX).^2)) ./ (sqrt(eX.^2 + eY.^2 + eZ.^2)));
    
    %% Create feature array and save to file
    watershedSeg = A.watershedSeg;
    Volume = A.Volume;
    SurfaceArea = A.SurfaceArea;
    EquivDiameter = A.EquivDiameter;
    Extent = A.Extent;
    ConvexVolume = A.ConvexVolume;
    Solidity = A.Solidity;
    Centroid1 = A.Centroid(:,1);
    Centroid2 = A.Centroid(:,2);
    Centroid3 = A.Centroid(:,3);
    PrincipalAxisLength1 = A.PrincipalAxisLength(:,1);
    PrincipalAxisLength2 = A.PrincipalAxisLength(:,2);
    PrincipalAxisLength3 = A.PrincipalAxisLength(:,3);
    Orientation1 = A.Orientation(:,1);
    Orientation2 = A.Orientation(:,2);
    Orientation3 = A.Orientation(:,3);
    MeanIntensity = A.MeanIntensity;
    MaxIntensity = double(A.MaxIntensity);
    
    FeatureArray_i = [Volume  SurfaceArea  EquivDiameter  Extent  ConvexVolume  Solidity  Centroid1  Centroid2  Centroid3 FA  PrincipalAxisLength1  PrincipalAxisLength2  PrincipalAxisLength3  Orientation1  Orientation2  Orientation3  MeanIntensity  MaxIntensity];
    
    %% save feature arrays to file
    FeatureArray_i_names = {'Volume' 'SurfaceArea' 'EquivDiameter' 'Extent' 'ConvexVolume' 'Solidity' 'Centroid1' 'Centroid2' 'Centroid3 FA' 'PrincipalAxisLength1' 'PrincipalAxisLength2' 'PrincipalAxisLength3' 'Orientation1' 'Orientation2' 'Orientation3' 'MeanIntensity' 'MaxIntensity'};
    save('watershedImage_feature_names', 'FeatureArray_i_names');
    
    fileName = fullfile(['watershedImage' num2str(i) '_features']);
    save(fileName, 'FeatureArray_i');
    
    fileName = fullfile(['watershedImage' num2str(i) '_features_normalized']);
    
    b = (FeatureArray_i - C) ./ S;
    save(fileName, 'b');
    
end

cd '../..'

end
