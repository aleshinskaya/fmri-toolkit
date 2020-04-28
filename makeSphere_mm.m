function [sphere] = makeSphere_mm(v,radius_mm,vox_res,bound_v)
%sphere = makeSphere_mm(center coord, radius_mm, vox_res, bound_v)
%v = center coordinate, 3D column vector
%radius_mm = how large will the final sphere be in terms of mm? eg 6 for 3
%2mm voxels
%vox_res: vector of voxel dimensions (3-element column vector of voxel dims, eg [2,2,2]')
%bound_v are the upper boundaries for values of v (ie, the volume size):
%3-element column vector
%column vector
% AL 2016


%Step 1. Create a Cube

%how many voxels to place into the proposed cube?
%volume of a sphere = 4/3 * pi * r^3

sphere_vol = (4/3) * pi * radius_mm^3;
voxelVol = vox_res(1) * vox_res(2) * vox_res(3);

%number of voxels in the radius:
numVoxPerRad = ceil(radius_mm/(voxelVol/3));

dim=numVoxPerRad;
count = 0;
    for k=-dim:dim        
    for l=-dim:dim  
    for m=-dim:dim  
		
        add = [k;l;m];
        vv = v+add; 
		
		%check if coords are within boundary of volume and only add them if they are
		if(vv<bound_v & vv>0)
	  	    count=count+1;
    	    cube(count,:) = [vv(1) vv(2) vv(3)]	;
		end
    end
    end
    end
  

%Step 2. Make Cube into Sphere
%include voxels as long as the squared distance between each point and the center 
% of the sphere is less than the desired radius for the sphere, squared... 


%how far is this point from the center in terms of voxels?
% mask = ( ((cube(:,1)-v(1)).^2) + ((cube(:,2)-v(2)).^2) + ((cube(:,3)-v(3)).^2) <= radius^2 );

%how far is this point from the center in terms of mm?
mask =  (((cube(:,1)-v(1))*vox_res(1)).^2 +  ((cube(:,2)-v(2))*vox_res(2)).^2 + ((cube(:,3)-v(3))*vox_res(3)).^2 <= radius_mm^2);

sphere = cube(mask,:);


