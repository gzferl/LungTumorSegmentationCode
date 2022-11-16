print('Predicting lung masks for downsampled images using trained 3D U-net:', flush = True)

print('\n')
print('\n')

import os, sys
import keras
import glob
import random
import numpy as np
import h5py
import time
import pandas as pd
# image code
import SimpleITK as sitk

# third party
import tensorflow as tf
import scipy.io as sio
import numpy as np
from keras.backend.tensorflow_backend import set_session
from scipy.interpolate import interpn


import time
import scipy
import nibabel as nib

sys.path.append("depends/")
from lung_vnet_bmi import res_vnet

from keras.models import Input, Model
from keras.utils.training_utils import multi_gpu_model


if __name__=='__main__':
    input_tensor = Input(shape=(256,256,256,1))
    
    model  = res_vnet(input_tensor)
    
    model = multi_gpu_model(model, gpus=2)
     
    # REPLACE '...' WITH ABSOLUTE PATH TO ROOT FOLDER 'image_processing_pipeline'
    # model.load_weights('.../image_processing_pipeline/depends/step0_lungSeg/run2_best_weights_bmi_lung_vnet_bmi_lr0.0001.hdf5')
    # base_path = '.../image_processing_pipeline/files_out_predLungMasks'
    # ct_paths = np.sort(glob.glob('.../image_processing_pipeline/files_in_CTscans/**image.nii'))
   
    
    affine_ref = np.eye(4)
    affine_ref[0,0]=2
    affine_ref[1,1]=2
    affine_ref[2,2]=2
    
    start_time = time.time()
    for i in range(len(ct_paths)):
        start_time_i = time.time()
        inp_m = []
        if True:    
            ct = nib.load(ct_paths[i]).get_data()
            inp_m.append(ct)

            ct = ct
            inp_m.append(ct)
            inp_m = np.array(inp_m)
            inp_m = np.expand_dims(inp_m, axis=-1)

            
            mask_h5 = np.round(model.predict(inp_m))

            
            mask_b = mask_h5[0]
            array_img = nib.Nifti1Image(mask_b, affine_ref)
            nib.save(array_img, os.path.join(base_path,
                                             ct_paths[i].split('/')[-1].replace('image.nii', 
                                                                                  'lung.nii')))

  


            print('Lung mask for animal {} generated in {} seconds'.format(i, time.time()-start_time_i), flush = True)


print('\n')
print('Lung masks for all animals generated in {} seconds'.format(time.time()-start_time), flush = True)
print('\n')
print('\n')
print('\n')
