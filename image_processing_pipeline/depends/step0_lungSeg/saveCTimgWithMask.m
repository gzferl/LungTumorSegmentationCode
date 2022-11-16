function saveCTimgWithMask(folderName_maskOut, CTfilename, MASKfilenmame)

ctImg = niftiread(fullfile(folderName_maskOut, CTfilename));
maskPred = niftiread(fullfile(folderName_maskOut, MASKfilenmame));

% Calculate z-coordinate of hand-drawn lung mask centroid
centroidZ = regionprops(maskPred, 'Centroid');
centroidZ = centroidZ.Centroid(3);

% Add lung ROI to grayscale image
se = strel('sphere', 1);
imagei_down_wmask = ctImg;

maskPred_erode = imerode(maskPred, se);
maskPred_apply = maskPred;
maskPred_apply(maskPred_erode==1)=0;
imagei_down_wmask(maskPred_apply==1)=250;

niftiwrite(imagei_down_wmask, fullfile(folderName_maskOut, strrep(CTfilename,'.nii','_wLungMask.nii')));
end
