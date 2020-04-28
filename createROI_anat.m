function R = createROI_anat(S)
% R = createROI_anat(S) loads a file using BrikLoad and returns a matlab
% matrix with binary values indicating where this file = some value
% S is a struct with the following fields:
% roiDir - directory of ROI file
% roiFile - ROI file
% roiVal - what value to look for in the file to create a binary mask
% returns struct with roiMask and roiSize
% AL Feb 24 2020

%load ROI file
opt=struct();
opt.Format='matrix';

try
    roiMaskName = [S.roiDir,S.roiFile];
    [roiData,roiInfo]=BrikLoad(roiMaskName,opt);
catch
    error(strcat('cant find ROI file: ',roiMaskName));
end


R.roiMask = roiData==S.roiVal;
R.roiSize = size(roiData);