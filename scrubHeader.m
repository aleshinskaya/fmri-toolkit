function cleanHeader = scrubHeader(oldHeader,newLabels,newFileName,isTal)

[nData,~] = size(newLabels);

oldHeader.HISTORY_NOTE = '';
oldHeader.BRICK_LABS = newLabels;
oldHeader.BRICK_STATAUX = zeros(1,nData);

if(isTal)    
oldHeader.SCENE_DATA(1) = 2;
else 
oldHeader.SCENE_DATA(1) = 0;
end
oldHeader.BRICK_FLOAT_FACS= zeros(1,nData);
oldHeader.BRICK_TYPES = zeros(1,nData)+3;
oldHeader.DATASET_RANK(2) = nData;
oldHeader.RootName = newFileName;

cleanHeader = oldHeader;
end