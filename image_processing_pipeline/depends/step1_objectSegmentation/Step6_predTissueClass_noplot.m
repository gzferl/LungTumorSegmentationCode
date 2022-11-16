function Step6_out = Step6_predTissueClass


%% Load unlabeled watershed arrays
Xcr_path = dir('files_out_predTumorMasks/Step3b_watershedTransform_output/*.mat');
load(fullfile(Xcr_path.folder, Xcr_path.name));
n = size(Xcr);
n = n(2)-1;

%% Add columns to Xcr for tumor, vessel, and 'other' masks
X_ROIs.pathToOriginalScan=[];
X_ROIs.watershedSegments=[];
X_ROIs.lungMask=[];
X_ROIs.tumorMask=[];
X_ROIs.vesselMask=[];
X_ROIs.otherMask=[];

%% Load and extract trained classification model
load('depends/step1_objectSegmentation/BayesOptMdl_3class_maxEval500_sizeCutoff0_Kfolds10_norm1.mat');
Mdl_SVM = BayesOptMdl{2,1}{1,6};
    
for i=1:n
      %% Extract unlabeled watershed object i
    Wi = Xcr(i).watershed;
    nSeg = size(unique(Wi));
    nSeg = nSeg(1)-1;
    
    %% Load feature array i
    Fi = load(['files_out_predTumorMasks/Step5_generateFeatureArray_output/watershedImage', num2str(i), '_features_normalized.mat']);
    Fi = Fi.b;

    %% Predict tissues classes for feature array
    classPredi = predict(Mdl_SVM, Fi);
    
    %% Assign values to tumor, vessel and other ROI masks
    Wi_tumor = Wi;
    Wi_vessel = Wi;
    Wi_other = Wi;
    Wi_all = Wi;
    
    for j=1:nSeg
        cPij = classPredi(j);
        if cPij==1
            Wi_tumor([Wi_tumor==j])=1;
        else
            Wi_tumor([Wi_tumor==j])=0;
        end
    end
    
    for j=1:nSeg
        cPij = classPredi(j);
        if cPij==2
            Wi_vessel([Wi_vessel==j])=1;
        else
            Wi_vessel([Wi_vessel==j])=0;
        end
    end
    
    for j=1:nSeg
        cPij = classPredi(j);
        if cPij==3
            Wi_other([Wi_other==j])=1;
        else
            Wi_other([Wi_other==j])=0;
        end
    end
    
    for j=1:nSeg
        cPij = classPredi(j);
        if cPij==3
            Wi_all([Wi_all==j])=3;
        elseif cPij==2
            Wi_all([Wi_all==j])=2;
        else
            Wi_all([Wi_all==j])=1;
        end
    end
    
    
    %% Add tissue masks to output structure
    X_ROIs(i).pathToOriginalScan=Xcr(i).filenames;
    X_ROIs(i).lungMask=Xcr(i).MaskIn;
    X_ROIs(i).tumorMask=logical(Wi_tumor);
    X_ROIs(i).vesselMask=logical(Wi_vessel);
    X_ROIs(i).otherMask=logical(Wi_other);
    X_ROIs(i).watershedSegments=Xcr(i).watershed;
    
    %% Create label map for tumor, vessels, other
    Wi_tumor_labels = Wi.*Wi_tumor; 
    Wi_vessel_labels = Wi.*Wi_vessel; 
    Wi_other_labels = Wi.*Wi_other;   
    
    %% Write tumor, vessel, other tissue masks to nifti files
    filenamei = Xcr(1).filenames(i).name;
    filenamei = strrep(filenamei, '.img', '');
    niftiwrite(single(Wi_tumor), fullfile('files_out_predTumorMasks', [filenamei '_tumorROI.nii']));
    niftiwrite(single(Wi_vessel), fullfile('files_out_predTumorMasks', [filenamei '_vesselROI.nii']));
    niftiwrite(single(Wi_other), fullfile('files_out_predTumorMasks', [filenamei '_otherROI.nii']));
    niftiwrite(single(Wi_all), fullfile('files_out_predTumorMasks', [filenamei '_allROIs.nii']));
    niftiwrite(single(Wi_tumor_labels), fullfile('files_out_predTumorMasks', [filenamei '_tumorLabels.nii']));  
    niftiwrite(single(Wi_vessel_labels), fullfile('files_out_predTumorMasks', [filenamei '_vesselLabels.nii']));  
    niftiwrite(single(Wi_other_labels), fullfile('files_out_predTumorMasks', [filenamei '_otherLabels.nii']));    
    niftiwrite(single(Wi), fullfile('files_out_predTumorMasks', [filenamei '_allLabels.nii']));   
    
end

end
