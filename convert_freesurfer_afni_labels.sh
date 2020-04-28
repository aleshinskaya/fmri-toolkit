#! /usr/bin/tcsh

# arg1 = freesurfer directory for that subject, arg2 = filename, arg3 = epifile with full path to resample to
# output files written to input file directory


set surfDir = $argv[1]
set inputFile = $argv[2]
set alignFile = $argv[3]


cd $surfDir

# freesurfer to nifti
mri_label2vol --label label/$inputFile.label --temp mri/orig.mgz --o label/$inputFile.nii --identity

cd $surfDir'/label/'

# nifti to afni
3dcopy $inputFile.nii $inputFile

# remove niftii
rm *.nii

# make a copy of the alignment file to ensure it is in orig space
3dcopy $alignFile 'temp_align_epi+orig'

#resample to alignment epi file
3dresample -master 'temp_align_epi+orig' -inset $inputFile+orig -prefix $inputFile'_RS+orig'


# clear temporary files
rm $inputFile'+orig'* 
rm 'temp_align_epi+orig'*