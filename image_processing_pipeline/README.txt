%% To begin, copy images to be processed into folder 'files_in_CTscans'.  Images must be in Analyze (img/hdr) format.
%
%% IMAGE FILE NAMING CONVENTION
% image files placed in 'files_in_CTscans' should be named ct_scanID_image.img
% for example, ct_36843_image.img
%
%
%% IN THE FILES LISTED BELOW (found in depends/) UNCOMMENT THE INDICATED LINES AND 
%% REPLACE '...' WITH ABSOLUTE PATH TO ROOT FOLDER 'image_processing_pipeline'
% 1) runMe_downsample.m, lines 6, 7, 8, 9
% 2) pred_lung_bmi_1atAtime.py, lines 44, 45, 46 
% 3) upsample.m, line 9
% 4) Step1_imagePreprocessing_v2_noplot, lines 4, 5, 6
% 5) predictLungTumors.m line 31
% 
%
%% RUNNING LUNG SEGMENTATION SCRIPT ON GPU NODE AS BATCH JOB VIA SLURM
% 1) Log in to HPC cluster
% 2) Navigate to root directory
%       $ cd .../image_processing_pipeline/
% 3) Run the lung segmentation script*
%       $ sbatch predictLungMask.sbatch
% 4) Check status of job* 
%       $ squeue -u unixid
% Script will automatically read all image files in folder 'files_in_CTscans' and results will be saved in script-generated folder 'files_out_predLungMasks'
%
%
%% RUNNING LUNG TUMOR / BLOOD VESSEL SEGMENTATION SCRIPT ON HPC IN INTERACTIVE MODE
% 1) Log in to High Performance Computing (HPC) cluster*
% 2) Navigate to root directory
%       $ cd .../image_processing_pipeline_noOutputFiles/
% 3) start an interactive session*
%       $ srun --qos=interactive -c12 --mem=128g --x11 --pty bash 
% 4) load Analyze and Matlab*
%       $ module load analyze/12.0-1122
%       $ export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/gstore/apps/analyze/12.0-1122/AVW-12.0/AMD_LINUX64/lib" 
%       $ module load matlab/2021a
% start matlab in either terminal mode or desktop mode
%       $ matlab -nodesktop -nosplash % terminal mode
%       $ matlab                      % desktop mode
% run Matlab .m file 'predictLungTumors.m' from Matlab command line
%       >> predictLungTumors
% Script will automatically read all image files in folder 'files_in_CTscans' and results will be saved in script-generated folder 'files_out_predTumorMasks'
%
%
%% ADDITIONAL NOTES
% 1) Script predictLungTumors.m assumes that script predictLungMask.sbatch has been run and lung masks are available in folder 'files_out_predLungMasks'
% 2) micro-CT scans need to be reconstructed such that they match the example images located in folder 'files_in_CTscans'
% 3) Scans included in folder 'files_in_CTscans' correspond to images shown in Figures 2, 4 and S9**
%
%
% FOOTNOTES
% *code listed here is specific to the computing environment used in Ferl et al. 2022 and should be modified as needed 
% for your computing environment
%
% **Figure 2: scans 11221 - 29472 and 39483         
%   Figure 4: scans 36301 - 38803 
%   Figure S9: scans 57090117 - 580070317  
%