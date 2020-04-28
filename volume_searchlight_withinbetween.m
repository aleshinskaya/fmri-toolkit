function [output_rDiff_3d] = volume_searchlight_withinbetween(S)
% [output_rDiff_3d] = volume_searchlight_withinbetween(S)
% S: settings, a struct with the following fields:
% subjID - identifier for subject
% mask -  mask matrix or [] for none
% maskThresh - value threshold for the mask
% dataDir - where the data files live
% radius_mm - radius for the searchlight
% voxSize - voxel size in mm, assumes isotropic
% infix - variable to enter into filena,e
% suffix  - variable to enter into filename
% simModel - matrix with the same # entries as conditions,s where 1=within, 2=between, and
% 0=exclude for all pairs of conditions
% isTal = whether this is in tal space 
% scanType - filename of scan
% selectIndices - condition numbers
% returns output_rDiff_3d, matrix of resulting searchlight results
% dependencies: afni_matlab code
% input files expected to be found using S.dataDir/S.subjIDS.scanType
% output files will be named S.subjID_searchlight_S.scanType_S.radius_mm_mm_S.suffix;
% searchlight excludes spheres with fewer than 10 voxels; this can be
% changed below in minVox
% 
% AL 21 Jan 2020

%-------------------------------------------------------------------------------------------%
%			global settings
%-------------------------------------------------------------------------------------------%

progDir=pwd;

if(S.isTal)
    outputName = [S.subjID,'_searchlight_',S.infix,'_',num2str(S.radius_mm),'mm',S.suffix,'+tlrc'];
else     
    outputName = [S.subjID,'_searchlight_',S.infix,'_',num2str(S.radius_mm),'mm',S.suffix,'+orig'];
end

mixVox = 5;
%-------------------------------------------------------------------------------------------%
%			load data for masks & data for each run
%-------------------------------------------------------------------------------------------%

%define global opt variable for loading data
opt=struct();
opt.Format='matrix';
dataFile = [S.dataDir,S.subjID,S.scanType];

try 
 [err,data,data_header,err_msg]=BrikLoad(dataFile,opt);   
catch
   %fail gracefully
 display (['No such file ', dataFile]);
end

if(err==0) 

    fprintf('Loaded %s\n', dataFile);

    %load inherent labels
    allLabels = getLabelsBrik(data_header);
    selectedLabels = allLabels(S.selectIndices,:)
    selectedData = data(:,:,:,S.selectIndices);

    brainSize = size(selectedData(:,:,:,1));
    brainSize_vector = brainSize(1)*brainSize(2)*brainSize(3);
    numConditions=length(S.selectIndices);

    %define mask if not supplied
    if (isempty(S.mask))
        dataMask=~isnan(data(:,:,:,1));
        S.maskThresh=0;
    else
        dataMask = S.mask;
    end 


    %load or define spheres
    outputDir = [S.dataDir,'/predefined_spheres/'];
    if(exist(outputDir)==0)
       mkdir(outputDir) 
    end
    sphereFileName1 = sprintf('%s/output_predefine_spheres_radius%s_%d_%d_%d_1.mat',outputDir,num2str(S.radius_mm),brainSize(1),brainSize(2),brainSize(3))
    sphereFileName2 = sprintf('%s/output_predefine_spheres_radius%s_%d_%d_%d_2.mat',outputDir,num2str(S.radius_mm),brainSize(1),brainSize(2),brainSize(3))


    try 
        load(sphereFileName1);
        load(sphereFileName2);    
        allSpheres_vector = [allSpheres_vector_1,allSpheres_vector_2];    
    catch  
       predefine_spheres(S.radius_mm,S.voxSize,brainSize(1:3),sphereFileName1,sphereFileName2);
       load(sphereFileName1); 
       load(sphereFileName2);    
       allSpheres_vector = [allSpheres_vector_1,allSpheres_vector_2];    

    end


    %vectorize the data consistently with predefined spheres:
    for i=1:numConditions
         selectedData_v(:,i) = reshape(selectedData(:,:,:,i),brainSize_vector,1);
    end

    %vectorize the mask
    mask_v = reshape(dataMask,brainSize_vector,1);

    %within vs between model
    % 1 = within, 2 = between, 0 =exclude
    simModel=S.simModel;     

% check the sim model 
if(length(simModel)~=numConditions)
    error('Model does not match number of conditions in data!')
    anyErr=1;
end

    %------------------------%
    % Loop through Brain
    %------------------------%

    brainSize = size(selectedData);
    output_rDiff= nan(brainSize_vector,1);
    inds_v = find(all(selectedData_v ~= 0,2) & mask_v>S.maskThresh);
    numInds = length(inds_v);

    for i=1:numInds

            x=inds_v(i);

            %pull out sphere indicces
            sphere = allSpheres_vector(x).sphere;

             %pull out data
             patterns=selectedData_v(sphere,:,:); 
             %rows are voxels, cols conditions; 3rd dimension is runs
             psize = size(patterns);

             %filter out rows with all zeros, that is, any voxels which had no
             %values across conditions in ANY run         
             zeros_conds = all(patterns==0,2) ; %were voxels zero across all conditions?
             patterns = patterns(zeros_conds==0,:); %keeping only non-zero voxels in this sphere
             psize = size(patterns);

             % as long as patterns isn't all empty or all nan; there
            % should be at least 10 values in this sphere and as a
            % validity check, that the 3rd dim is equal to num runs!
            if( ~isempty(patterns) && psize(1) > mixVox) 

                %correlate across conditions
                 pattern_xCorr = corrcoef(patterns);
                 pattern_xCorr = fisher(pattern_xCorr); 

                %fit model
                withinSim_model = pattern_xCorr(simModel==1);            
                betweenSim_model = pattern_xCorr(simModel==2);
                rDiff=nanmean(withinSim_model)-nanmean(betweenSim_model);


            else %end if pattern has too few voxels

                rDiff=NaN;

            end %end if all patterns empty    

             %store output
             output_rDiff(x)=rDiff;

            percentComplete = i/numInds;
            if(mod(i,1000)==0)
            fprintf('%.2f ',percentComplete);
            end

    end %end loop through brain

    %first: are there any absolute zeros? if so, turn into 99s    
    fprintf('\n\n%d actual 0''s in data\n\n',sum(output_rDiff==0))
    output_rDiff(output_rDiff==0)=99;
    
    %replace real 0's with something else
    output_rDiff(output_rDiff==99)=-0.000000001;
       
    %get rid of nans by replacing with absolute 0's
    output_rDiff(isnan(output_rDiff))=0;
    
    %reshape
    output_rDiff_3d = reshape(output_rDiff,brainSize(1),brainSize(2),brainSize(3));

    %names of the output
    output_labels = ['rDiff',S.suffix];
    newHeader = scrubHeader(data_header,output_labels,outputName,S.isTal);
    Opt.OverWrite='y';
    Opt.Prefix=[S.outputDir,'/',outputName];
    problems=WriteBrik(output_rDiff_3d,newHeader,Opt);
    
    
    
else 

   fprintf('\n\n File %s not loaded, skipping!\n\n',dataFile)
    
end



