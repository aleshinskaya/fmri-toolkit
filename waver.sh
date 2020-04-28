#! /usr/bin/tcsh

#read in arguments
set fileDir = $argv[1]
set scanType = $argv[2]
set vols = $argv[3]
set TR = $argv[4]

printf $fileDir'\n'
printf $scanType'\n'
printf $vols'\n'
printf $TR'\n'


#waver the regressor files--all that exist in the directory for
#current scan type


set files = `find $fileDir*$scanType* `
printf %s\\n $files 


foreach file($files) 
	waver -WAV -dt $TR -numout $vols -peak 1 -tstim `cat $file` > $file'_wav.1D'
end

# ./rename.sh 's/'.1D_wav'/'_wav'/' *
rename.sh '.1D_wav' '_wav' $fileDir*'1D_wav'*

# #in case we had some wavered files in that directory already, and these were rewavered, remove them
rm $fileDir*wav_wav*
rm $fileDir*wav.wav*
rm $fileDir*wav.1D_wav.1D*






