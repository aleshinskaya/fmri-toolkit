function [clusterMap]= makeClusters_surface(C,D)
% [clusterMap]= makeClusters_surface(S,D)
% best run using outputs from t-test function
% D is a struct with a list of surface file properties
% - dataDir
% - icold (eg 128)
% - hemi (l, r, or m)
% C is a struct with settings:
% - clusterThresh
% - infix (for filename output)
% - inputData (what we will be thresholding, clustering, & outputting)
% loads intermediate surface files for all items in D according to
% directory, icold, and hemi
% inputData is an average but must come from the set of files from D

outfilename= sprintf('clusters_%.4f_%s',C.clusterThresh, C.infix)

%load one sample surface to get nvertices
surfintermediate=sprintf('%s/ico%d_%sh.intermediate_al.asc', C.surfDir, D(1).icold, D(1).hemi);
[v,f]=freesurfer_asc_load(surfintermediate);
nvertices=size(v,1);

   
%allocate space for node2area 
numFiles=length(D); 
all_node2area=zeros(nvertices,numFiles);
 
 
%get node2area values from all files
for i=1:numFiles   
    surfintermediate=sprintf('%s/ico%d_%sh.intermediate_al.asc',D(i).dataDir, D(i).icold, D(i).hemi);
    [v,f]=freesurfer_asc_load(surfintermediate);
    all_node2area(:,i)=surfing_surfacearea(v,f);
end

node2area=mean(all_node2area,2);

%run neighbours search
neighbours = surfing_surface_nbrs(f);

%run clusterize
[cl,clsize]=surfing_clusterize(C.inputData(:)>C.clusterThresh,neighbours,node2area);

%produce output
ncl=numel(cl);
nv=nvertices;
clusterMap=zeros(nv,2);

for k=1:ncl
    clusterMap(cl{k},2)=k+.5;
    clusterMap(cl{k},1)=clsize(k);
    clusterMap(cl{k},3)=C.inputData(cl{k}); 
end


if(C.toWrite)
    % write output
    fnout=[C.surfDir outfilename '.niml.dset'];
    fprintf('writing to file %s \n',fnout)
    dset=struct();
    dset.data=clusterMap;
    afni_niml_writesimple(fnout, dset);
end