function predefine_spheres(radius_mm,voxDims,brainSize,outFileName1,outFileName2)
%predefine_spheres(radius_mm,voxDims,brainSize)
%radius_mm: sphere radius in mm
%voxDims: column vector
%Predefines all full-sized spheres in brain volume
%Note, this may thus leave out smaller
% spheres on edges of brain.
%AL 4 Oct 2016

radius_vox = radius_mm/mean(voxDims);
testSphere = makeSphere_mm([30,30,30]',radius_mm,voxDims,brainSize');
sphereSize=length(testSphere);
fprintf('defining spheres with %d mm radius with sphere size %d',radius_mm,sphereSize);

brainSize_vector = brainSize(1)*brainSize(2)*brainSize(3);
sphereSize_vector = sphereSize*3;
emptyBrain = zeros(brainSize);
allSpheres_vector = struct();

for x=1:brainSize(1)
 	for y=1:brainSize(2)
		for z=1:brainSize(3)           
            
           
            center = [x;y;z];
            
            sphere = makeSphere_mm(center,radius_mm,voxDims,brainSize');
            center_vec = sub2ind(brainSize,x,y,z);
            sphere_vec = sub2ind(brainSize,sphere(:,1),sphere(:,2),sphere(:,3)) ;
            allSpheres_vector(center_vec).sphere = sphere_vec ;
            
           
        end
        fprintf('.')
    end
    fprintf('%.2f',x/brainSize(1))
    
end


%save in two parts

midInd = floor(brainSize_vector/2);

allSpheres_vector_1 = allSpheres_vector(1:midInd);
allSpheres_vector_2 = allSpheres_vector(midInd+1:end);

save(outFileName1,'allSpheres_vector_1','-v7.3')
save(outFileName2,'allSpheres_vector_2','-v7.3')
%
% how to use on a brain:
% allBrains = zeros(sphereSize_vector,brainSize_vector);
% curBrain = emptyBrain;
% curBrain(sphere) = 1;
% 
% %reshape sphere-mask brain into vector
% flatBrain=reshape(curBrain,brainSize_vector,1);
% 
% %figure out vector position of the center coords of the brain
% center_vec = sub2ind(brainSize,x,y,z);
% allBrains(center_vec,:) = flatBrain;

end