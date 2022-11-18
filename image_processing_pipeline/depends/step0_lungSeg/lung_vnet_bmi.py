import os
import keras
from keras.layers import Conv2D, Conv3D, Conv2DTranspose, Conv3DTranspose, Concatenate, concatenate
from keras.layers import merge, UpSampling3D, MaxPooling3D, BatchNormalization
from keras.layers import Activation
from keras.models import Input, Model
import numpy as np

import h5py
from keras.utils import HDF5Matrix
from keras.losses import binary_crossentropy
from sklearn.model_selection import train_test_split
from keras.optimizers import Adam, RMSprop
import keras.backend as K
from keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint, TensorBoard
from keras.utils.training_utils import multi_gpu_model
from keras import regularizers
from keras.layers import Conv3D
#from vnet_tb import UNet_3D
import pandas as pd
import nibabel as nib

import tensorflow as tf
from keras import backend as K
from keras import initializers
from keras import regularizers
from keras import constraints
from keras.engine import InputSpec
import glob

from keras.layers.convolutional import Conv3D



## Losses
def dice_coeff(y_true, y_pred):
    smooth = 1.
    y_true_f = K.flatten(y_true)
    y_pred_f = K.flatten(y_pred)
    intersection = K.sum(y_true_f * y_pred_f)
    score = (2. * intersection + smooth) / (K.sum(y_true_f) + K.sum(y_pred_f) + smooth)
    return score


def sensitivity(y_true, y_pred):
    smooth = .000001
    y_true_f = K.flatten(y_true)
    y_pred_f = K.flatten(y_pred)
    intersection = K.sum(y_true_f * y_pred_f)
    score = (intersection + smooth) / (K.sum(y_true_f) + smooth)
    return 1-score


def dice_loss(y_true, y_pred):
    loss = 1 - dice_coeff(y_true, y_pred)
    return loss

def volume_diff(y_true, y_pred):
    smooth = 0.00001
    y_true_f = K.flatten(y_true)
    y_pred_f = K.flatten(y_pred)

    loss = K.abs(K.sum(y_true_f-y_pred_f**2)) / (K.sum(y_true_f**2) + smooth)
    return loss


def volume_diff_l1(y_true, y_pred):
    smooth = 0.00001
    y_true_f = K.flatten(y_true)
    y_pred_f = K.flatten(y_pred)

    loss = K.sum(K.abs(y_true_f - y_pred_f)) / (K.sum(y_true_f) + smooth)
    return loss

def vol_dice_loss(y_true, y_pred):
    loss = sensitivity(y_true, y_pred)+ weighted_binary_crossentropy(y_true, y_pred)+dice_loss(y_true, y_pred)
    return loss

def weighted_binary_crossentropy(y_true, y_pred):
    loss=K.mean((0.94*y_true+0.03)*K.binary_crossentropy(y_true, y_pred), axis=-1)
    return loss


def bce_dice_loss(y_true, y_pred):
    loss = sensitivity(y_true, y_pred) + dice_loss(y_true, y_pred)+ volume_diff_l1(y_true, y_pred)
    return loss

def bce_dice_loss_wrapper(input_tensor):
    def custom_loss(y_true, y_pred):
        return vol_dice_loss(y_true, y_pred)-vol_dice_loss(y_true, input_tensor[:,:,:,:,:1])
    return custom_loss



## Convolutional block
def conv_block(nb_filters, kernel_sizes,
              dilation, nb_layers, prev):
    for i in range(nb_layers):
        
        prev = BatchNormalization(axis=1)(prev)
        prev = Conv3D(nb_filters,
                      kernel_sizes,
                      dilation_rate = dilation,
                      padding='same',
                      activation = 'relu')(prev)

        return prev

def skip_bock(nb_filters_in, nb_filters_out, prev):
    if nb_filters_in != nb_filters_out:
        prev = Conv3D(nb_filters_out, 1,
                      padding='same')(prev)
    return prev


def res_block(nb_filters_out,
              kernel_sizes, dilation,
              nb_layers, prev):
    nb_filters_in = prev.shape[2]
    for i in range(2):
        conv_1 = conv_block(int(nb_filters_out/4), kernel_sizes,
                            dilation[0], nb_layers, prev)
        conv_2 = conv_block(int(nb_filters_out/4), kernel_sizes,
                            dilation[1], nb_layers, prev)
        conv_3 = conv_block(int(nb_filters_out/4), kernel_sizes,
                            dilation[2], nb_layers, prev)
        conv_4 = conv_block(int(nb_filters_out/4), kernel_sizes,
                            dilation[3], nb_layers, prev)
        conv = Concatenate(axis=-1)([conv_1,conv_2, 
                                     conv_3, conv_4])
        prev = conv
    
    conv = Conv3D(nb_filters_out, kernel_sizes,
                  padding='same', 
                  activation = 'relu')(conv)
    
    skip = skip_bock(nb_filters_in, nb_filters_out,
                     prev)

    return merge([skip,conv], mode='sum')

def deepblock(m, dim, depth, factor,
              dilation_l = [1,1,2,2], 
              dilation_c = [1,1,1,1]):
    if depth > 0:
        m = Conv3D(dim, 3,padding='same')(m)
        if depth > 3:
            n = conv_block(dim, 3, 1, 2,m)
            n = conv_block(dim, 3, 1, 2,n)
            
        else:
            n = conv_block(dim, 3, 1, 2,m)
            n = conv_block(dim, 3, 1, 2,n)
        
        m = MaxPooling3D((2, 2, 2), strides=(2, 2, 2))(n)
        m = deepblock(m,16, depth-1, factor*2)
        m = UpSampling3D()(m)
        m = Concatenate(axis=-1)([n, m])
    return Conv3D(dim, 3, activation='relu', padding='same')(m)


def relu1(x):
    return K.relu(x, max_value=1)



def res_vnet(i, n_out = 1, dim = 8, depth = 4, factor = 1):
    
    o = deepblock(i, dim, depth, factor)
    o = Conv3D(n_out, 3, padding='same',activation='relu')(o)
    o = BatchNormalization(axis=1)(o)
    out = Activation(relu1)(o)
    return Model(inputs=i, outputs=out)



def deeplab3D(img_shape, dilation_rates):
    lf = deepblock(i, 4, 4, 1)
    lf = Conv3D(1, 3, padding='same')(lf)
    lf = Activation(relu1)(lf)

    lf_branch = Conv3D(4, 1,
                       padding='same', 
                       activation = 'relu', 
                       name='lf_branch')(lf)
    
    b0 = Conv3D(4, 1, padding='same',
                name='b0_0')(lf)
    b0 = BatchNormalization(axis=1)(b0)
    b0 = Activation('relu',name='b0_1')(b0)
    
   
    b1 = Conv3D(4, 3, dilation_rate = dilation_rates[0],
                padding='same')(lf)
    b1 = BatchNormalization(axis=1)(b1)
    b1 = Activation('relu')(b1)
    
    b2 = Conv3D(4, 3, dilation_rate = dilation_rates[1], 
                padding='same')(lf)
    b2 = BatchNormalization(axis=1)(b2)
    b2 = Activation('relu')(b2)
    
    b3 = Conv3D(4, 3, dilation_rate = dilation_rates[2],
                padding='same')(lf)
    b3 = BatchNormalization(axis=1)(b3)
    b3 = Activation('relu')(b3)

    
    b4 = AveragePooling3D(strides=(1,1,1), 
                          padding='same')(lf)
    
    b = Concatenate(axis=-1)([b0, b1, b2,b3, b4])
    
    b = Conv3D(4, 1, padding='same')(b0)
    b = BatchNormalization(axis=1)(b)
    b = Activation('relu')(b)
    
    o = Concatenate(axis=-1)([lf_branch, b])
    
    o = Conv3D(1, 3, padding='same')(o)
    o = Activation(relu1)(o)

    return Model(inputs = i, outputs = o)


ids_train_split = range(1,2080)
ids_valid_split = range(1,640)

batch_size = 4

def train_generator():
    img_path = np.sort(glob.glob('/absolute/path/to/training_data/*image.nii'))
    mask_path = np.sort(glob.glob('/absolute/path/to/training_data/training_data/*mask.nii'))
    
    while True:
        for start in range(0, len(ids_train_split), batch_size):
            x_batch = []
            y_batch = []
            end = min(start + batch_size, len(ids_train_split))
            ids_train_batch = ids_train_split[start:end]
            for i in ids_train_batch:
                
                img = np.expand_dims(nib.load(img_path[i]).get_data(),
                                     axis=-1)
                mask = np.expand_dims(np.clip(nib.load(mask_path[i]).get_data(),
                                              0,1), axis=-1)
                
                x_batch.append(img)
                y_batch.append(mask)
                
            x_batch = np.array(x_batch)
            y_batch = np.array(y_batch)

            yield x_batch, y_batch


def valid_generator():
    img_path = np.sort(glob.glob('/absolute/path/to/validation_data/*image.nii'))
    mask_path = np.sort(glob.glob('/absolute/path/to/validation_data/*mask.nii'))
    
    while True:
        for start in range(0, len(ids_valid_split), batch_size):
            x_batch = []
            y_batch = []
            end = min(start + batch_size, len(ids_valid_split))
            ids_valid_batch = ids_valid_split[start:end]
            for i in ids_valid_batch:
                
                img = np.expand_dims(nib.load(img_path[i]).get_data(),
                                     axis=-1)
                mask = np.expand_dims(np.clip(nib.load(mask_path[i]).get_data(),
                                              0,1), axis=-1)
                
                x_batch.append(img)
                y_batch.append(mask)
                
            x_batch = np.array(x_batch)
            y_batch = np.array(y_batch)
            yield x_batch, y_batch
            
            

def train(batch_size=4, 
          lr = 0.0001, name='lung_vnet_bmi'):
    
    
    callbacks = [EarlyStopping(monitor='val_loss',
                               patience=8,
                               verbose=1,
                               min_delta=1e-4),
                 ReduceLROnPlateau(monitor='val_loss',
                                   factor=0.1,
                                   patience=4,
                                   verbose=1,
                                   epsilon=1e-4),
                 ModelCheckpoint(monitor='val_loss',
                                 filepath='best_weights_bmi_{}_lr{}.hdf5'.format(name,lr),
                                 save_best_only=True,
                                save_weights_only=True),
                 TensorBoard(log_dir='logs_{}_{}'.format(name, lr))] 
    
    input_tensor = Input(shape=(256,256,256,1))
    model  = res_vnet(input_tensor)
    
    model =multi_gpu_model(model, gpus=4)


    model.compile(optimizer=RMSprop(lr=lr),
                  loss=dice_loss,
                  metrics=[dice_coeff, 
                           volume_diff, 
                           volume_diff_l1, 
                           sensitivity, 
                           weighted_binary_crossentropy])
    model.summary()
    
    
    model.fit_generator(generator=train_generator(),
                        steps_per_epoch=600,
                        callbacks = callbacks,
                        validation_data=valid_generator(), 
                        validation_steps=150,
                        epochs=20)
    model.save_weights('weights_{}_lr{}.hdf5'.format(name,lr))

    
def main(batch_s, lr):
    train(batch_s, lr)


if __name__=='__main__':
    rates = [0.0001]
    for lr in rates:
        main(4,lr)



