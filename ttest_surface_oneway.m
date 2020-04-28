function R = ttest_surface_oneway(S,D)
%[outFileName,R,success] = ttest_surface_oneway(S,D)
% performs t-test over a set of surface files in SUMA format
% S is a struct with fields 
% - minObs (minimal number of observations for t-value to be output)
% - outputDir (directory to save data)
% - tails for t-test ('right', 'left', or 'both')
% - infix for output file name
% - postfix for output file name
% D is a struct with fields:
% - dataDir
% - fileName
% - brickNum (index)
% - maskFile 
% - maskThresh
% output named [S.outputDir,'tTest_n',nObs,S.infix,S.postfix]
% saves to .mat and to .niml.dset
% returns R struct with filename of output, data, and success(1 or 0)
% AL March 5 2020



%fileExtention: filename that follows the subjectID
%subjects: list of subjectIDs
%dataDir: top level directory under which individual subject folders are
%stored
%varName: which variable within the datafile should be used
%outFileDir: where outputs should be written
%postFix: any suffix to add to output, can be ''
%assumes data are mat files in subject's Ref/ directory. 
%appends affix tTest_ to infilename
%written 21 July 2013


%----------------------------------------------------------------%
% assume success
success = true;
err=0;

R = struct();

% number of files
numFiles = size(D,2);

%load first file to preallocate space for data matrix
err=0;
fileName =[D(1).dataDir,D(1).fileName];   
try       
   [dataStruct] = afni_niml_readsimple(fileName);
   data_selected = dataStruct.data(:,D(1).brickNum);
   dataSize = size(data_selected);   
catch
    err=1;
    fprintf('\nfile %s not found!',fileName);
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
                     [datastruct] = afni_niml_readsimple(thisMaskName);
                     maskData = datastruct.data;                   

                    if(err~=0)
                        success=false;
                    else
                        thisMask = mask_data>D(i).maskThresh;                    
                    end
                end
            
                
                %load data
                try                   
                    thisFile = [D(i).dataDir,D(i).fileName] 
                    [dataStruct] = afni_niml_readsimple(thisFile);
                catch 
                    err=1;
                end
                
                 
                if(err~=0)
                    success=false;
                    fprintf('\nDid not find data file %s\n',thisFile);
                else
                    thisData= dataStruct.data; 
                    thisData(thisMask==0,:)= NaN;
                    allData(:,i) = thisData(:,D(i).brickNum);                 
                    thisLabel = dataStruct.labels{D(i).brickNum}
                end
                
            end

end



R.success=success;

if(success==1) 
    
   
  %set absolute 0's to NaNs 
  nanMask = allData==0;
  allData(nanMask) = NaN;

  
  %perform ttest across subjects, for each voxel
  [h,p,c,stats] = ttest(allData,0,.05,'right',2);  
  
  %store tvalue
  output_tVals = stats.tstat;  
  
  %remove Infs
  output_tVals(isinf(output_tVals)) = NaN;
   
  %threshold by minObs
  minObsMask = stats.df<S.minObs;
  output_tVals(minObsMask==1) = NaN;
  
  %replace NaNs with 0's 
  output_tVals(isnan(output_tVals)) = 0;
  
  %store p value
  output_pVals = 1-p;  
  output_pVals(isnan(p)) = 0;
  
  %store n
  output_df = stats.df;  
  
  %create average
  output_mean = mean(allData,2);
  output_mean(isnan(output_mean))=0;


  %define and write output
  R.data=[output_tVals,output_pVals,output_df,output_mean]; R.labels = {'tvals','pvals','df','mean'};R.stats={'none'};
  outFileName = sprintf('tTest_n%d_%s_%s',numFiles,S.infix,S.postfix);
  afni_niml_writesimple(R,[[S.outputDir,outFileName],'.niml.dset']);
  R.outFileName = outFileName;
  save([outFileName,'.mat'],'output_tVals','output_pVals','output_df','output_mean');
  
else
  fprintf('\nDid not perform t-test due to one or more errors!\n')
end

end
