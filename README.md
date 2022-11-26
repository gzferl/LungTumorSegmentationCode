# LungTumorSegmentationCode
<p>To begin, copy images to be processed into folder &apos;files_in_CTscans&apos;. &nbsp;Images must be in Analyze (img/hdr) format.</p>
<p><br></p>
<p><strong>IMAGE FILE NAMING CONVENTION</strong></p>
<p>image files placed in &apos;files_in_CTscans&apos; should be named ct_scanID_image.img for example, ct_36843_image.img</p>
<p><br></p>
<p><strong>IN THE FILES LISTED BELOW (found in depends/) UNCOMMENT THE INDICATED LINES AND REPLACE &apos;...&apos; WITH ABSOLUTE PATH TO ROOT FOLDER &apos;image_processing_pipeline&apos;</strong></p>
<ol>
    <li>runMe_downsample.m, <em>lines 6, 7, 8, 9</em></li>
    <li>pred_lung_bmi_1atAtime.py, <em>lines 44, 45, 46&nbsp;</em></li>
    <li>upsample.m, <em>line 9</em></li>
    <li>Step1_imagePreprocessing_v2_noplot, <em>lines 4, 5, 6</em></li>
    <li>predictLungTumors.m, <em>line 31</em></li>
</ol>
<p><br></p>
<p><strong>RUNNING LUNG SEGMENTATION SCRIPT ON GPU NODE AS BATCH JOB VIA SLURM</strong></p>
<ol>
    <li>Log in to High Performance Computing (HPC) cluster<sup>*</sup></li>
    <li>Navigate to root directory<ul>
            <li>$ cd .../image_processing_pipeline/</li>
        </ul>
    </li>
    <li>Run the lung segmentation script<sup>*</sup>
        <ul>
            <li>$ sbatch predictLungMask.sbatch</li>
        </ul>
    </li>
    <li>Check status of job<sup>*</sup>&nbsp;<ul>
            <li>$ squeue -u unixid</li>
        </ul>
    </li>
</ol>
<p>Script will automatically read all image files in folder &apos;files_in_CTscans&apos; and results will be saved in script-generated folder &apos;files_out_predLungMasks&apos;</p>
<p><br></p>
<p><strong>RUNNING LUNG TUMOR / BLOOD VESSEL SEGMENTATION SCRIPT ON HPC IN INTERACTIVE MODE</strong></p>
<ol>
    <li>Log in to HPC cluster</li>
    <li>Navigate to root director<ul>
            <li>$ cd .../image_processing_pipeline_noOutputFiles/</li>
        </ul>
    </li>
    <li>start an interactive session<sup>*</sup>
        <ul>
            <li>$ srun --qos=interactive -c12 --mem=128g --x11 --pty bash</li>
        </ul>
    </li>
    <li>load Analyze and Matlab<sup>*</sup>
        <ul>
            <li>$ module load analyze/12.0-1122</li>
            <li>$ export LD_LIBRARY_PATH=&quot;${LD_LIBRARY_PATH}:/gstore/apps/analyze/12.0-1122/AVW-12.0/AMD_LINUX64/lib&quot;&nbsp;</li>
            <li>$ module load matlab/2021a</li>
        </ul>
    </li>
    <li>start matlab in either terminal mode or desktop mode<ul>
            <li>$ matlab -nodesktop -nosplash % terminal mode</li>
            <li>$ matlab &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;% desktop mode</li>
        </ul>
    </li>
    <li>run Matlab .m file &apos;predictLungTumors.m&apos; from Matlab command line<ul>
            <li>&gt;&gt; predictLungTumors</li>
        </ul>
    </li>
</ol>
<p>Script will automatically read all image files in folder &apos;files_in_CTscans&apos; and results will be saved in script-generated folder &apos;files_out_predTumorMasks&apos;</p>
<p><br></p>
<p><strong>ADDITIONAL NOTES</strong></p>
<ol>
    <li>Script predictLungTumors.m assumes that script predictLungMask.sbatch has been run and lung masks are available in folder &apos;files_out_predLungMasks&apos;</li>
    <li>micro-CT scans need to be reconstructed such that they match the example images located in folder &apos;files_in_CTscans&apos;</li>
    <li>Scans included in folder &apos;files_in_CTscans&apos; correspond to images shown in Figures 2, 4 and S9<sup>**</sup></li>
</ol>
<p><br></p>
<p><strong>FOOTNOTES</strong></p>
<p><sup>*</sup>code listed here is specific to the computing environment used in Ferl et al. 2022 and should be modified as needed for your computing environment</p>
<p><sup>**</sup>Figure 1: scans 11221 - 29472 and 39483 &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;</p>
<p>&nbsp; &nbsp;Figure 3d: scans 36301 - 38803&nbsp;</p>
<p>&nbsp; &nbsp;Figure S8: scans 57090117 - 580070317 &nbsp;</p>
