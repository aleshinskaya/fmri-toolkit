function [clusterMap]= makeClusters_volume(C)
% [clusterMap]= makeClusters_volume(C)
% best run using outputs from t-test function
% C is a struct with settings:
% - inputData (3D matrix)  -- what we will be thresholding, clustering, & outputting
% - mask (3D matrix with 0's for exclusion, or [])
% - clusterThresh
% - toWrite, true means write output to a file
% - outputDir (directory to write to, only if writing out)
% - header, a sample data header, only if writing out
% - minClust, minimum cluster size to write out, only if writing out
% - infix for filename output, only if writing out





data =  C.inputData;
matSize = size(data);

if(length(matSize)~=3)
    error('C.inputData must be 3D!')
end


%identify neighbours
neighbours = surfing_volume_nbrs(matSize,1:2);

%mask
if(~isempty(C.mask))
   data(mask==0) = 0;
end

%threshold 
data_thresh = data>C.clusterThresh;
data_thresh_vec = data_thresh(:);

%pass to clusterize 
[cl,clsize]=surfing_clusterize(data_thresh_vec,neighbours);

%produce output in vector form
ncl=numel(cl);
nv=size(data_thresh_vec,1);
clusterMap=zeros(nv,3);

for k=1:ncl   
    clusterMap(cl{k},1)=clsize(k);
    clusterMap(cl{k},2)=k+.5;
    clusterMap(cl{k},3)=C.inputData(cl{k});       
end

%write out result optionally
if(C.toWrite)

  ncl=numel(clsize);
  out_data=zeros(nv,2);
  output_labels = 'cluster_size~cluster_ind';
        for k=1:ncl  
            if(clsize(k) > C.minClust)
                out_data(cl{k},2)=k+.5;
                out_data(cl{k},1)=clsize(k);
            end
        end
  

    outfilename= sprintf('clusters_%.4f_%s',C.clusterThresh, C.infix);
    out_data_mat=reshape(out_data,[matSize,2]);    
    fprintf('writing to file %s \n',outfilename);
    newHeader = scrubHeader(C.header,output_labels,outfilename,C.isTal);
    Opt.OverWrite='y';
    Opt.Prefix=[C.outputDir,'/',outfilename];
    problems=WriteBrik(out_data_mat,newHeader,Opt)


end
    
end

