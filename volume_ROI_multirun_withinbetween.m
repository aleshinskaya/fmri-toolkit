function R = volume_ROI_multirun_withinbetween(S,D)
%  R = volume_ROI_withinbetween(S,D)
% S is a struct with the following fields:
% roiMask - binary matrix indicating ROI location 
% subjID - identifier for subject
% simModel - matrix with the same # entries as conditions,s where 1=within, 2=between, and
%      0 = exclude for all pairs of conditions
% minVox - number of voxels ROI must have to not return NaN
% D: data, a struct with list of file names to load (can be 1 or more)
% with fields:
% dataDir - where the data files live
% dataFile - filename of scan
% selectIndices - condition numbers within that run
% ---- code assumes datafiles are accessible as dataDir/dataFile
% returns Struct with results 
% dependencies: afni_matlab code
% AL 24 Feb 2020


%load data 

opt=struct();
opt.Format='matrix';
allData = [];
[~,numFiles] = size(D);
anyErr=0; 
err=0;

for d=1:numFiles 
    
    dataFile = [D(d).dataDir,D(d).dataFile];

    try 
     [err,data,data_header,err_msg]=BrikLoad(dataFile,opt);   
    catch
       %fail gracefully
     display (['No such file ', dataFile]);
     err=1;
    end
    
   
    
    if(err==0) 

            %load inherent labels
            allLabels = getLabelsBrik(data_header);
            selectedLabels = allLabels(D(d).selectIndices,:);
            selectedData = data(:,:,:,D(d).selectIndices);
            nLabs = length(D(d).selectIndices);

            fprintf('Loaded %s\n', dataFile);
    
    
     if(d==1)
        allData = selectedData;
     else 
         allData(:,:,:,end+1:end+nLabs) = selectedData;
     end
     
     
    else
        anyErr=1;
        
    end
    
end 

numConditions = size(allData,4);
brainSize = size(allData(:,:,:,1));
roiSize = sum(sum(sum(S.roiMask==1)));   

if(anyErr==0)
    %check the sim model 
    simModel=S.simModel;     
    if(length(simModel)~=numConditions)
        sprintf('Model does not match number of conditions in data!')
        anyErr=1;
    end
end 

%initialize results output to NaN
rDiff=NaN;


if(anyErr==0)   

    patterns = NaN(roiSize,numConditions);

    for i=1:numConditions                     
        thisData=allData(:,:,:,i);
        patterns(:,i) =  thisData(S.roiMask==1);
    end
    
    %filter out rows with all zeros, that is, any voxels which had no
    %values across conditions         
    zeros_conds = all(patterns==0,2) ; %were voxels zero across all conditions?
    patterns = patterns(zeros_conds==0,:); %keeping only non-zero voxels in this sphere
    [numDataElems,nc] = size(patterns);

     % as long as patterns isn't all empty or all nan; there
    % should be at least 10 values in this sphere and as a
    % validity check, that the 3rd dim is equal to num runs!
    if(~isempty(patterns) & numDataElems>S.minVox) 

                %correlate across conditions
                pattern_xCorr = corrcoef(patterns);

                %fit model
                withinSim_model = pattern_xCorr(simModel==1);            
                betweenSim_model = pattern_xCorr(simModel==2);
                rDiff=nanmean(withinSim_model)-nanmean(betweenSim_model);


            else %end if pattern has too few voxels       

   end %end if all patterns empty    

   
end %end if any error

R.rDiff=rDiff;      
   
   
    

