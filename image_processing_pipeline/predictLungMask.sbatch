#!/bin/bash
#SBATCH --partition gpu
#SBATCH --gres=gpu:2
#SBATCH -c 8
#SBATCH --job-name predict_lung_masks
#SBATCH --output pred_lung_vnet-%J.txt
#SBATCH --qos veryshort
#SBATCH --mail-user ferlg@gene.com
#SBATCH --mail-type ALL
module load Keras/2.1.2-foss-2017a-CUDA-9.0.176-Python-3.6.3
pip install --user nibabel
pip install --user SimpleITK
module load matlab/2021a
matlab -nosplash -nodesktop -r "run depends/step0_lungSeg/runMe_downsample.m"
python 'depends/step0_lungSeg/pred_lung_bmi_1atAtime.py'
matlab -nosplash -nodesktop -r "run depends/step0_lungSeg/upsample.m"