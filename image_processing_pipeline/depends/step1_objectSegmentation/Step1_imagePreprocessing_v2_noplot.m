function Step1out = Step1_imagePreprocessing_v2

%% REPLACE '...' WITH ABSOLUTE PATH TO ROOT FOLDER 'image_processing_pipeline'
% cd('.../image_processing_pipeline/');
% img_path_plus1 = '.../image_processing_pipeline/';
% lung_path = '.../image_processing_pipeline/files_out_predLungMasks/';

%% Folder containing .img image files
img_folder = 'files_in_CTscans';

%% Location of image and lung masks
img_path = fullfile(img_path_plus1, img_folder);

%% Get current folder
pwdOut = pwd;

%% USER DEFINED VARIABLES
% USER DEFINED VARIABLES - BEGIN

% Set fillHoles=1 to fill holes using imfill
fillHoles = 1;

% set writeGrayScale=1 to save masked grayscale images to folder as
% individual Nifti files
writeGrayScale = 1;

% set shape and size of erosion element to be applied to lung mask; set to
% zero to turn off erosion
r_mask = 1;
s_mask = 'sphere';

% set shape and size of erosion/dilation element to be applied to binary
% image; set to zero to turn off erosion/dilation
r = 1;
s = 'sphere';

% specify number of erosion/dilation operations to perform, i.e. if n_ed=2 then 2 erosions
% are performed followed by 2 dilations, all using the element defined by r
% and s
n_ed = 3;

% Specify Hounsfield unit cutoffs for soft tissue
HU_softTissue_min = -300;
HU_softTissue_max = 200;

% USER DEFINED VARIABLES - END

%% load all .img file paths in current folder into array
filenames = dir(['**/',img_folder, '/*.img']);

% Number of files found
nn = size(filenames);
n1 = nn(1);

X = [];
X(n1+1).filenames = filenames;


%% Create folder for results
mkdir files_out_predTumorMasks/Step1_imagePreprocessing_output;

%% Create timestamp
timestamp = datestr(now,30);

%% Read nifti file into matlab, convert to binary images and apply lung masks
scanNumbers = [1:n1];
for i = scanNumbers
    
    fileName = filenames(i).name;
    pathname = filenames(i).folder;
    
    absPath_img = fullfile([pathname '/' fileName]);
    
    % Extract filename w/out .img extension
    tmpSplit1=strsplit(fileName,'.img');
    fileName_no_ext = vectorize(tmpSplit1(1));
    
    % Extract scan name %JULY 2021 (format Scan_#_reco#_image)
    tmpSplit2=strsplit(fileName_no_ext,'_');
    
    scanName = [vectorize(tmpSplit2(1)), '_', vectorize(tmpSplit2(2)), '_', vectorize(tmpSplit2(3))];
    scanName2 = [vectorize(tmpSplit2(1)), '_', vectorize(tmpSplit2(2))];
    
    % Assemble paths to CT image and lung mask (format Scan_#_reco#_image)
    vnetLungMaski = fullfile(lung_path, [scanName2, '_lung_orig.nii']);
    CTimagei = fullfile(img_path, [scanName, '.img']);
    
    %% Read CT image, extarct image FOV dimensions
    V = single(analyze75read(CTimagei));
    sizeV = size(V);
    nx = sizeV(1);
    ny = sizeV(2);
    nz = sizeV(3);
    
    X(i).lung_mask = vnetLungMaski;
    
    maskLung = niftiread(vnetLungMaski);
    maskLung = imfill(maskLung,'holes');
    maskLung(maskLung < 0.01) = 0;
    maskLung(maskLung > 0.99 & maskLung < 1.01) = 1;
    
    %% Remove small objects from lung mask (Keep only largest, connected object)
    CC = bwconncomp(maskLung);
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~,idx] = max(numPixels);
    filtered_vol = false(size(maskLung));
    filtered_vol(CC.PixelIdxList{idx}) = true;
    maskLung = filtered_vol;
    
    %% Copy original CT image to 'backup object'
    V_orig = single(V);
    
    %% Copy original CT image to V_masked
    V_masked = V;
    
    %% Remove all voxels with HU > HU_softTissue_max (set equal to air)
    V_masked(V>HU_softTissue_max) = -1000;
    
    %% Mask area outside lung compartment in grayscale image (set equal to air)
    V_masked(maskLung==0) = -1000;
    
    %% Write masked grayscale image to file
    if writeGrayScale == 1
        fileName1 = fullfile(['files_out_predTumorMasks/Step1_imagePreprocessing_output/' 'file' int2str(i) '_' fileName_no_ext '_masked.nii']);  % create file name
        niftiwrite(V_masked,fileName1)
    end
    
    %% Convert grayscale image to binary
    V_masked = single(V_masked);
    V_masked_BW = imbinarize(V_masked, HU_softTissue_min);
    
    %% Perform 3D hole filling
    if fillHoles == 1
        V_masked_BW = imfill(V_masked_BW,'holes');
    end
    
    %% Erode lung mask
    if r_mask > 0
        se = strel(s_mask,r_mask);
        maskLung_eroded = imerode(maskLung,se);
    end
    
    %% Mask area outside lung compartment in binary image
    if r_mask > 0
        V_masked_BW(maskLung_eroded==0) = 0;
    end
    
    %% Erode/dilate binary image using imopen and a radius=r sphere
    V_erode = V_masked_BW;
    if r > 0
        se = strel(s,r);
        for d = 1:n_ed
            V_erode = imerode(V_erode, se);
        end
        for d = 1:n_ed
            V_erode = imdilate(V_erode, se);
        end
    end
    
    %% Rename lung mask
    if r_mask > 0
        maskLung_final = maskLung_eroded;
    else
        maskLung_final = maskLung;
    end
    
    X(i).Vout = logical(V_erode);
    X(i).Vsize = size(V_erode);
    X(i).VoutPreErode = logical(V_masked_BW);
    
    
    %% Clear temporary variables from memory
    clear V_tmp
    clear V
    clear V_*
    clear mask*
    clear abs*
    clear sc*
    clear tmp*
    clear fileN*
    clear pathname*
    clear se
    clear mask*
    clear V*
    clear abs*
    clear scl*
    clear tmp*
    clear nn
    
end

threshSign = [];
if HU_softTissue_min>0
    threshSign = 'pos';
end
if HU_softTissue_min<0
    threshSign = 'minus';
end

threshSign2 = [];
if HU_softTissue_max>0
    threshSign2 = 'pos';
end
if HU_softTissue_max<0
    threshSign2 = 'minus';
end

a = ['AllScans_binarized_' threshSign int2str(abs(HU_softTissue_min)) '_' threshSign2 int2str(abs(HU_softTissue_max)) '_HU_' 'rErode' int2str(r) s '_' int2str(n_ed) 'x' '_rErodeLungMask' int2str(r_mask) s_mask '_holeFill' int2str(fillHoles)];
fileName2 = fullfile(['files_out_predTumorMasks/Step1_imagePreprocessing_output/AllScans_binarized_' threshSign int2str(abs(HU_softTissue_min)) '_' threshSign2 int2str(abs(HU_softTissue_max)) '_HU_' 'rErode' int2str(r) s '_' int2str(n_ed) 'x' '_rErodeLungMask' int2str(r_mask) s_mask '_holeFill' int2str(fillHoles)]);  % create file name

save(fileName2, 'X', '-v7.3')


clear s*
clear r*
clear HU_softTissue_min
clear HU_b*
clear n1
clear X
clear show*
clear fileName2
clear threshSign2
clear threshSign
clear writeGrayScale


end