#include <stdio.h>
#include <stdlib.h>
#include <AVW.h>
#include <AVW_ImageFile.h>
#include <file_io.h>
#include <pFit_kbarck.h>

#define MAX_FILENAME_LG 2000
#define TRUE 1
#define FALSE 0
#define BIN_THRESHOLD 1


void usage() {
	printf("watershedAVW: CORRECT USAGE:\n\n");
	printf("watershedAVW  (flag options) \n");
	printf("       -i    : input file w/ directory\n");
	printf("       -o    : output file w/ directory\n");
	printf("       -e    : element file w/ directory\n");
// 	printf("       -u  	: upper threshold\n");
// 	printf("       -l  	: lower threshold\n");
}
/* 
 * Saves an AWV_Volume with specified outputFileName.
 */
void writeVolumeFile(char *outputFileName, AVW_Volume *outputVolume) {
	char string[120];
	AVW_ImageFile *outputFile;

	if ((outputFile = AVW_CreateImageFile(outputFileName, "AnalyzeImage(7.5)",
//	if ((outputFile = AVW_CreateImageFile(outputFileName, "AnalyzeAVW",
			outputVolume->Width, outputVolume->Height, outputVolume->Depth,
			outputVolume->DataType))== NULL) {
		sprintf(string,"Unable to open %s", outputFileName);
		AVW_Error(string);
		exit(0);
	}

	if(AVW_WriteVolume(outputFile, 0, outputVolume) != AVW_SUCCESS) {
		sprintf(string,"Write failed to %s", outputFileName);
		AVW_Error(string);
		AVW_CloseImageFile(outputFile);
		return;
	}
	AVW_CloseImageFile(outputFile);
}

int main(int argc, char *argv[]) {
	char string[MAX_FILENAME_LG],inputFileName[MAX_FILENAME_LG], outputFileName[MAX_FILENAME_LG], elementFileName[MAX_FILENAME_LG];
	int i, loadElement = FALSE;
	AVW_Volume	*inputVolume = NULL, *outVolume = NULL, *structEl_3x3 = NULL;
	AVW_ImageFile	*inputFile;

	if( argc < 2 ) {
	   usage();
	   exit(0);
	}

	/*
	 * Process command-line arguments
	 */
	for(i = 1; i < argc; i++) {
	    /*  check for option flag */
	    if( *argv[i] == '-' ) {			/* argument is an option */
			switch( *(argv[i]+1) ) {
			    case 'i':        /*  input file */
					if( ++i >= argc ) break;
					strncpy(inputFileName, argv[i], MAX_FILENAME_LG);
					break;
			    case 'o':        /*  output file */
					if( ++i >= argc ) break;
					strncpy(outputFileName, argv[i], MAX_FILENAME_LG);
					break;
			    case 'e':        /*  output file */
					if( ++i >= argc ) break;
					loadElement = TRUE;
					strncpy(elementFileName, argv[i], MAX_FILENAME_LG);
					break;
			}					
		}
	}

	if ((inputFile = AVW_OpenImageFile(inputFileName, "r")) == NULL) {
		printf("ERROR: unable to open image file - %s\n", inputFileName);
		return(0);
	}
	
	
	if ((inputVolume = AVW_ReadVolume(inputFile, 0, NULL)) == NULL) {
		printf("ERROR: unable to read volume file - %s\n", inputFileName);
		AVW_CloseImageFile(inputFile);
		return(0);
	}

	AVW_CloseImageFile(inputFile);
	
	if (loadElement) {
		if ((inputFile = AVW_OpenImageFile(elementFileName, "r")) == NULL) {
			printf("ERROR: unable to open image file - %s\n", elementFileName);
			return(0);
		}

		if ((structEl_3x3 = AVW_ReadVolume(inputFile, 0, NULL)) == NULL) {
			printf("ERROR: unable to read volume file - %s\n", elementFileName);
			AVW_CloseImageFile(inputFile);
			return(0);
		}
		AVW_CloseImageFile(inputFile);
	}
	else {
		structEl_3x3 = AVW_CreateVolume(NULL, 3, 3, 3, AVW_UNSIGNED_CHAR);
		AVW_SetVolume(structEl_3x3, 1);
	}
	
	if ((outVolume = AVW_WatershedVolume(inputVolume, 1.0, 1.0, structEl_3x3, outVolume)) == NULL) {
		sprintf(string,"Watershed failed.");
		AVW_Error(string);
		return;
	}
//	printf("datatype %d\n", outVolume->DataType);
	outVolume = AVW_ConvertVolume(outVolume, AVW_SIGNED_INT, outVolume);
	
	writeVolumeFile(outputFileName, outVolume);

}
