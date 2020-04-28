#!/usr/bin/env python
# coding: utf-8

# In[ ]:
import sys
import numpy
import pandas as pd


print(sys.argv[1])

print(sys.argv[2])

print(sys.argv[3])

def regressor(file,outputPath,prefix):
    confound_full = pd.read_csv(file, sep='\t')
    regressor = ['csf','trans_x','trans_y','trans_z','rot_x','rot_y','rot_z',
        'trans_x_derivative1','trans_y_derivative1','trans_z_derivative1','rot_x_derivative1','rot_y_derivative1','rot_z_derivative1']
    confound_motion_outliers = confound_full.filter(regex="motion_outlier")
    confound_motion = confound_full[regressor]
    confound_select = pd.concat([confound_motion_outliers,confound_motion],axis = 1)
    for i in regressor:
        print(i)
        df=confound_full[i]
        df=df.fillna(value=0)
        df.to_csv(outputPath+prefix+"_"+i+".1D",sep=' ',index=False,header=False,float_format='%.4f')
    
    motion_outlier=[]
    dfm=confound_motion_outliers 
    for i in range(len(dfm)):
        if sum(dfm.iloc[i])>0:
            motion_outlier.append (0)
        else:
            motion_outlier.append (1)
    motion_outlier=pd.DataFrame(motion_outlier).to_csv(outputPath+prefix+'_motion_outliers.1D',sep=' ',index=False,header=False)
    
    return

regressor(sys.argv[1],sys.argv[2],sys.argv[3])

# arguments needed: 1) confound filename with full path, 2) output directory path, 3) file prefix for output file naming

# for path testing
# /home/aleshins/2019_SL1/fmri_prep/output/fmriprep/sub-001/ses-1/func/sub-001_ses-1_task-main_run-1_desc-confounds_regressors.tsv
# /home/aleshins/2019_SL1/afni/sub-001/regressors/