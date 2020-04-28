function [D] = surface_searchlight_multirun_withinbetween(S,D)
% [D] = surface_searchlight_multirun_withinbetween(S,D)
% S: settings, a struct with the following fields:
% subjID - identifier for subject
% surfDir - directory of surfing/freesurfer files 
% outputDir - where to save data 
% hemi = l, r, or m
% n2vFile - fullfile (path & name of file with node2voxel results 
% maskOpt - what kind of mask 
% maskFile - name of brain mask in same space & directory as data; 
% maskThresh - value threshold for the mask
% minVox - minimum number of non-zero voxels in searchlight to include
% dataDir - where the data files live
% radius_mm - radius for the searchlight in mm
% radius_vox - radius for the searchlight in voxels
% infix - variable for middle of output filename
% suffix  - variable to enter into filename
% simModel - matrix with the same # entries as conditions,s where 1=within, 2=between, and
% 0=exclude for all pairs of conditions
% D: data, a struct with list of file names to load (can be 1 or more)
% with fields:
% scanType - filename of scan
% selectIndices - condition numbers
% returns D, searchlight results
% dependencies: afni_matlab code, surfing toolbox code 
% AL 3 2020

%-------------------------------------------------------------------------------------------%
%			global settings
%-------------------------------------------------------------------------------------------%

progDir = pwd;
surfDir = S.surfDir;
outputName=sprintf('%s/%s_searchlight_%s_%dvox_%sh_ico%d_%s_%s',S.outputDir,S.subjID,S.infix,S.radius_vox,S.hemi,S.icold,S.suffix,S.maskOpt);
% fprintf('Will be saving to %s.mat\n', outputName);
icold_highres = 128;

%-------------------------------------------------------------------------------------------%
%			load data for masks & data for each run
%-------------------------------------------------------------------------------------------%

%define global opt variable for loading data
opt=struct();
opt.Format='vector';

%load data 
allData = [];
[~,numFiles] = size(D);
anyErr=0; 

for d=1:numFiles 
    
    dataFile = [S.dataDir,S.subjID,D(d).scanName];

    try 
     [err,data,data_header,err_msg]=BrikLoad(dataFile,opt);   
    catch
       %fail gracefully
     display (['No such file ', dataFile]);
    end
    
   
    
    if(err==0) 

            %load inherent labels
            allLabels = getLabelsBrik(data_header);
            selectedLabels = allLabels(D(d).selectIndices,:)
            selectedData = data(:,D(d).selectIndices);
            nLabs = length(D(d).selectIndices);

            fprintf('Loaded %s\n', dataFile);
    
    
     if(d==1)
        allData = selectedData;
     else 
         allData(:,end+1:end+nLabs) = selectedData;
     end
     
     
    else
        anyErr=1;
        
    end
    
end 


%------load surface information---------%


%prepare n2v surface files

if(exist(S.n2vFile))
    usePreSaved=1;
else
    usePreSaved=0;
end

if(usePreSaved==0 && anyErr==0)

    surfinner=sprintf('%s/ico%d_%sh.smoothwm_al.asc', surfDir,icold_highres, S.hemi);
    surfouter=sprintf('%s/ico%d_%sh.pial_al.asc', surfDir, icold_highres, S.hemi);

    % loads coordinates and faces (=triangles) for high-res surface (which is used for voxel selection)
    [v_inner,f]=freesurfer_asc_load(surfinner);
    [v_outer,f]=freesurfer_asc_load(surfouter);

    % support low-res surface for output while voxel selection is done  using high-res surface
    surfinner_lowres=sprintf('%s/ico%d_%sh.smoothwm_al.asc', surfDir, S.icold, S.hemi);
    [v_inner_lowres,f_lowres]=freesurfer_asc_load(surfinner_lowres);
    nodeidxs=surfing_maplow2hires(v_inner_lowres',v_inner');

    nodecount_highres=size(v_inner,1);
    nodecount_lowres=numel(nodeidxs);

    fprintf('Using %d / %d nodes for low/high res\n', nodecount_lowres, nodecount_highres);

    circledef=[10 S.radius_vox]; % for historical reasons

    brikfn=S.epiFile;
    voldef=surfing_afni2spmvol(brikfn); % gets header information of volume if using afni files
    zeromask =  all(allData==0,2); 
    voldef.mask=  ~zeromask;

     n2v=surfing_voxelselection(v_inner',v_outer',f',circledef,voldef,nodeidxs);

    % for template searchlight script:
    % help surfing_reducemapping
    % help surfing_maplow2hires

    save(S.n2vFile,'n2v');
    
elseif(anyErr==0)
    
    load(S.n2vFile,'n2v')
 
end


if(anyErr==0) 
    
    %get dimensions of loaded data    
    numNodes=numel(n2v);
    brainSize =   size(allData,1);
    numConditions = size(allData,2);

    %load mask
    if (strcmp(S.maskOpt,'wholebrain'))
        nodeMask = ones(numNodes,1);
        maskThresh=0;
    else 
        
        try 
            %read maskfile - it should be a surface file I guess... 
           %dataMask,headerMask]=BrikLoad(S.maskFile,opt);
           fprintf('Loaded %s\n', S.maskFile);
%            check that mask file has same dims as data file
        catch
           %fail gracefully
         error (['No such file ', S.maskFile]);
        end
    end %end load mask 

    
    %check sim model
    %within vs between model
    % 1 = within, 2 = between, 0 = exclude   
    simModel=S.simModel;     
    if(length(simModel)~=numConditions)
        error('Model does not match number of conditions in data!')
        anyErr=1;
    end

    
end

if(anyErr==0) 
    
    %------------------------%
    % Loop through Brain
    %------------------------%

    output_rDiff = nan(numNodes,1);
    voxelCounts = zeros(numNodes,1);



    for k=1:numNodes

                patterns = allData(n2v{k},:);      
                zeros_conds = all(patterns==0,2) ; %were any voxels zero across all conditions?
                patterns = patterns(zeros_conds==0,:,:); %keeping only non-zero voxels in this sphere  
                psize = size(patterns);
                
                 if(~isempty(patterns) && psize(1) > S.minVox && nodeMask(k)==1)


                    %correlate across conditions
                    pattern_xCorr = corr(patterns,'type','Pearson');
                    %fisher-transform
                    pattern_xCorr = fisher(pattern_xCorr); 
                    %extract within and between  pairs
                    withinSim = pattern_xCorr(simModel==1);            
                    betweenSim = pattern_xCorr(simModel==2);
                    %subtract for rdiff
                    rDiff=nanmean(withinSim)-nanmean(betweenSim);
                   
                    voxelCounts(k) =  psize(1);


             else

                rDiff=NaN;
                voxelCounts(k)=0;

            end


         %store output
         output_rDiff(k)=rDiff;


        percentComplete = k/numNodes(1);
        if(mod(k,1000)==0)
        fprintf('%.2f ',percentComplete);
        end

    end %end loop through brain

end %end if any error loading files 

  %first: are there any absolute zeros? if so, turn into 99s    
    fprintf('\n\n%d actual 0''s in data\n\n',sum(output_rDiff==0))
    output_rDiff(output_rDiff==0)=99;
    
    %replace real 0's with something else
    output_rDiff(output_rDiff==99)=-0.000000001;
       
    %get rid of nans by replacing with absolute 0's
    output_rDiff(isnan(output_rDiff))=0;
    %replace nans with 0's 
    output_rDiff(isnan(output_rDiff))=0;



%write out data
D=struct(); D.data=output_rDiff; D.stats={'corrcoef'}; D.labels={S.suffix};
afni_niml_writesimple(D,[outputName,'.niml.dset']);
 
% return data and voxel counts
D.output_rDiff = output_rDiff;
D.voxelCounts = voxelCounts;
D.dataHeader = data_header;

%display which voxels are in use (within the surface mask)
 masked_nodes=zeros(numNodes,1);
 for k=1:numNodes
     masked_nodes(k)=numel(n2v{k})+.001;
 end
 
D.masked_nodes=masked_nodes;

    
%save data in output directory as a mat file  -- currently disabled
% save(outputName,'output_rDiff','S','D');

end



