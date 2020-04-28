#! /usr/bin/tcsh

# arg1 = surfaces directory for that subject, arg2 = filename, arg3= epifile with full path
# output files written to input file directory


set inputDir = $argv[1]
set inputFile = $argv[2]
set alignFile = $argv[3]

cd $inputDir

# freesurfer to nifti
mri_convert $inputFile $inputFile.nii

# nifti to afni
3dcopy $inputFile.nii $inputFile'+orig'

# remove nifti
rm $inputFile.nii

3dcopy $alignFile 'temp_align_epi+orig'

#resample to epi
3dresample -master 'temp_align_epi+orig' -inset $inputFile'+orig' -prefix $inputFile'_RS+orig'

# clear temporary files
rm $inputFile'+orig'* 
rm 'temp_align_epi+orig'*