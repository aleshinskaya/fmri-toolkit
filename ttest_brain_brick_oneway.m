function [R]=ttest_brain_brick_oneway(S,D)
%TTEST_BRAIN_BRICK_ONEWAY(S) - performs one-way ttest on each voxel in a volume
% S is a struct with fields: 
% - outputDir: where to save the output 
% - tails: 'right','left',or 'both'
% - minObs: min # observations to do t-test
% - infix: what to append to output file name after tTest_n_oneway_
% - isTal: whether data are in standard space
% D is a multi-element struct with fields:
% - fileName: list of filenames going into the t-test 
% - dataDir: list of directories where each file lives
% - brickNum: which index of each file are we grabbing
% - maskFile: mask filename, or 'none'
% - maskThresh: threshold for masks in D 
% returns R, a structure with:
% - output_3d
% - output_labels
% - output_filename
% - success
% - header from first file loaded


%----------------------------------------------------------------%
% assume success
success = true;
err=0;


% number of files
numFiles = size(D,2);

%load first file to preallocate space for data matrix
try  
    
   fileName =[D(1).dataDir,D(1).fileName];   
   [err,data,data_header,err_msg]=BrikLoad(fileName,'matrix');
    matSize=size(data(:,:,:,1));
   [err,data,data_header,err_msg]=BrikLoad(fileName,'vector');
   dataSize = size(data(:,1));
end


if(err==0)
   
            fullDataSize = [dataSize(1),numFiles];
            allData=zeros(fullDataSize);


        %----------------------------------------------------------------%
        %load all data into data matrix and mask by individual mask

        for i=1:numFiles
            
                                
                %load mask 
                err = 0;
                if(strcmp(D(i).maskFile,'none'))
                        thisMask = ones(dataSize);
                else                   
                     thisMaskName = [D(i).dataDir,D(i).maskFile];
                     [err,mask_data,mask_header,err_msg]=BrikLoad(thisMaskName,'vector');


                        if(err~=0)
                            success=false;
                        else
                            thisMask = mask_data>D(i).maskThresh;                    
                        end
                end
            
                
                %load data
                try                   
                    thisFile = [D(i).dataDir,D(i).fileName];                     
                    [err,data,data_header,err_msg]=BrikLoad(thisFile,'vector');
                end
                
                 
                if(err~=0)
                    success=false;
                else
                    thisData= data; 
                    thisData(thisMask==0,:)= NaN;
                    allData(:,i) = thisData(:,D(i).brickNum);
                    brickLabels = getLabelsBrik(data_header);
                    thisLabel = brickLabels(D(i).brickNum,:)
                end
                
            end

end

% if we loaded each file, loop through data and do t-test/averaging
if(success==1) 
    

output_tVals = zeros(dataSize);
output_pVals=  zeros(dataSize);
output_Mean = zeros(dataSize);
output_3d = zeros([matSize,4]);

output_nVals = sum(allData~=0,2) - sum(isnan(allData),2);



        for x=1:dataSize
           
            curData = allData(x,:);
            
            %check number of observations 
            if(output_nVals(x)>=S.minObs)
                
                
                %run t-test
                [h,p,c,stats] = ttest(curData,0,.05,S.tails);

                %record this r value in the voxel
                output_tVals(x) =stats.tstat;
                output_pVals(x) = 1-p;
                
                %compute mean
                output_Mean(x) = nanmean(curData);
                
                
            else
                 output_tVals(x) =NaN;
                 output_pVals(x) = NaN;
                 output_Mean(x)= NaN;
            end

                percentComplete = x/dataSize(1);
                if(mod(x,1000)==0)
                fprintf('%.2f ',percentComplete);
                end

        end  %end for each voxel  
        
        %clear nans
        output_tVals(isnan(output_tVals)) = 0;
        output_pVals(isnan(output_pVals)) = 0;
        output_Mean(isnan(output_Mean)) = 0;
        %reshape into matrix form         
        output_3d(:,:,:,1) = reshape(output_tVals,matSize(1),matSize(2),matSize(3));
        output_3d(:,:,:,2) = reshape(output_pVals,matSize(1),matSize(2),matSize(3));
        output_3d(:,:,:,3) = reshape(output_Mean,matSize(1),matSize(2),matSize(3));
        output_3d(:,:,:,4) = reshape(output_nVals,matSize(1),matSize(2),matSize(3));

  
else
    error('Error: One or more files not found!')
end


%define output name for t-test
if(S.isTal)
    outFileName = sprintf('tTest_n%d_oneway_%s_%s+tlrc',numFiles,S.infix,thisLabel);
else
    outFileName = sprintf('tTest_n%d_oneway_%s_%s+orig',numFiles,S.infix,thisLabel);
end
fprintf('\nSaving output to %s / %s \n',S.outputDir,outFileName);
output_labels = ['tVals~pVals~Mean~nObs'];
newHeader = scrubHeader(data_header,output_labels,outFileName,S.isTal);
Opt.OverWrite='y';
Opt.Prefix=[S.outputDir,'/',outFileName];
problems=WriteBrik(output_3d,newHeader,Opt)


if(problems>0)
    success=0;
end


R.output_3d = output_3d;
R.output_labels= strsplit(output_labels,'~');
R.success = success;
R.output_filename = outFileName;
R.header = data_header;

end %end function
  

