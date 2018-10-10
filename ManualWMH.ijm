
/////////////////////////////////////////////////
/// ManualWMH ImageJ macros
/////////////////////////////////////////////////



//global variables that are used in various macros:
var outdir = "";
var blindnum = "";
var datetimestamp = "";
var username = "";
var maskFileName = "";
var statsFileName = "";
var statsFileHandle = "";
var tempOriginalImage = "";
var maskProductFileName = "";
var statsTable = newArray(300); //Initialize Array (We will probably not have more than 300 slices)
var origImgPath = "";
var origImgFileName = "";



//function to return timestamp:
function tstamp(){  
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);   
	month++; if (month<10) month="0"+month;
	if (dayOfMonth<10) dayOfMonth="0"+dayOfMonth;
	if (hour<10) hour="0"+hour;
	if (minute<10) minute="0"+minute;
	if (second<10) second="0"+second;
	s=""+year+""+month+""+dayOfMonth+""+hour+""+minute+"";
	return s;
}



//function to assign values to output variables:
function prepOutput(){
	outdir = "/Users/Shared/";
	//outdir = "/data/images/wmhi-ij-output/";
	//outdir = "C:/temp/";
	//TBD get path where user wants to output mask and data file:
	//     outdir=getDirectory("select a directory to write your mask and statistics");

	//confirm directory exists and is a directory:
	if (!File.exists(outdir)) exit("Directory does not exist: " + outdir);
	if (!File.isDirectory(outdir)) exit(""+outdir+" is not a directory.");

	//get blindnum:
	Dialog.create("Save mask and stats: scan ID");
	Dialog.addMessage("Specify the scan ID (lowercase, no spaces). \nThis will be part of the output filenames.");
	Dialog.addString("Scan ID: ", "XXX");
	Dialog.show();
	blindnum = Dialog.getString();

	//get today's date:
	datetimestamp = tstamp();

	//get username:
	Dialog.create("Your username");
	Dialog.addMessage("Type your username for naming the output, without @domain.suffix.");
	Dialog.addString("Your username: ", "username");
	Dialog.show();
	username = Dialog.getString();

	//construct path+filename for mask and stats output files, including "wmhi-ij":
	maskFileName = "" + blindnum + "-wmhi-ij-mask-" + username + "-" + datetimestamp;
	maskProductFileName = "" + blindnum + "-wmhi-ij-maskProduct-" + username + "-" + datetimestamp;
	statsFileName = "" + blindnum + "-wmhi-ij-stats-" + username + "-" + datetimestamp + ".txt";
}



function getOrigSliceData(sliceAction,sliceNumber) {
	sliceQty = nSlices;
	zoom = getZoom();
	getMinAndMax(displayMin, displayMax);
	getThreshold(threshMin, threshMax);
	sliceWidth = getWidth();
	sliceHeight = getHeight();
	getVoxelSize(voxelWidth, voxelHeight, voxelDepth, voxelUnit);
	voxelVolume = voxelWidth * voxelHeight * voxelDepth;
	if(sliceNumber < 10) {
		sliceStatsLine = origImgPath + "," + origImgFileName + "," + sliceQty + ",00" + sliceNumber + "," + sliceAction + "," + zoom + "," + displayMin + "," + displayMax + "," + threshMin + "," + threshMax + "," + sliceWidth + "," + sliceHeight + "," + voxelWidth + "," + voxelHeight + "," + voxelDepth + "," + voxelUnit + "," + voxelVolume + ",";

	}
	else if(sliceNumber < 100) {
		sliceStatsLine = origImgPath + "," + origImgFileName + "," + sliceQty + ",0" + sliceNumber + "," + sliceAction + "," + zoom + "," + displayMin + "," + displayMax + "," + threshMin + "," + threshMax + "," + sliceWidth + "," + sliceHeight + "," + voxelWidth + "," + voxelHeight + "," + voxelDepth + "," + voxelUnit + "," + voxelVolume + ",";

	}
	else {
		sliceStatsLine = origImgPath + "," + origImgFileName + "," + sliceQty + "," + sliceNumber + "," + sliceAction + "," + zoom + "," + displayMin + "," + displayMax + "," + threshMin + "," + threshMax + "," + sliceWidth + "," + sliceHeight + "," + voxelWidth + "," + voxelHeight + "," + voxelDepth + "," + voxelUnit + "," + voxelVolume + ",";

	}
	return sliceStatsLine;
}



//many thanks to chitra.conics at gmail d0t c0m for writing this function:
function ROIsIncludeThreshold() {
	n = roiManager("count");
	hasThresholdedPixels = newArray(n);
	for(i=0; i<n; i++)
		hasThresholdedPixels[i] = 0;
	getThreshold(lower,upper);
	for(i=0;i<n;i++) {
		roiManager("select",i);
		getSelectionCoordinates(x,y);
		for(j = 0; j<x.length; j++) {
			for(k = 0; k<y.length; k++) {
				pixelValue = getPixel(x[j],y[k]);
				if(pixelValue >= lower && pixelValue <= upper) {
					hasThresholdedPixels[i] = 1;
					//To Exit the Loop since at least one pixel is within the range:
					k = y.length;
					j = x.length;
				}
			}
		}
	}
	//Return zero if one or more of the ROIs contains no thresholded pixels:
	for(i=0; i<n; i++){
		if(!hasThresholdedPixels[i]) {
			return 0;
		}
	}
	return 1;
}



macro "ManualWMH instructions [F1]" {
	waitForUser("Instructions: Manual WMH segmenting", "NOTE: you do NOT need to close these instructions to continue. \n \n1. You've already pressed the [F1] key to open these instructions. \n \n2. Open the FLAIR stack:\n   ...if from single-frame DICOM volume: File -> Import -> Image Sequence. Be careful: \n        a. count number of slices, click on first slice, click OK\n        b. set NUMBER OF IMAGES and FILE NAME CONTAINS to get the correct slices,\n        c. tick only SORT NAMES NUMERICALLY\n        d. click OK \n   ...if from multi-frame DICOM volume: File -> Open \n   ...if from Analyze format volume: File -> Import -> Analyze \n \n3. Press the [F2] key to automatically prep the image and tools. \n \n4. On slices with no WMH to be segmented: press [F3] key to clear the slice. This cannot be undone. \n \n5. On each slice with WMH you want to segment: \n - adjust the threshold to highlight WMH regions in red, \n - outline each region you want to include in your WMH segmentation and type [t] to send it to the ROI manager, \n - readjust threshold to fine-tune borders, \n - Press [F4] key to turn the slice's thresholded areas into a mask and \n    delete everything outside of your ROIs. This cannot be undone. \n \n6. When all of the slices have been either zeroed or segmented, press [F5] key to \n  save mask as an analyze file and the image statistics as a text file. You will see many images flash on the screen, and the final visible stack will be your masked pixels with their original intensities.");
}



macro "ManualWMH prep [F2]" {
	run("8-bit");                           //convert to 8-bit
	resetMinAndMax();                       //scale display range to full 0-255
	prepOutput();
	setSlice(10);                           //set to a resonable first slice
	// TODO: check the order of these two lines:
	setThreshold(150,255);                  //set reasonable initial threshold 
	run("Threshold...");                    // TODO: strip brain first?
	run("View 100%");                       //zoom to original size
	run("In [+]");                          //zoom to 150%
	//run("In");                            //zoom to 200%
	roiManager("deselect");                 //open ROI manager
	//setOption("Show All", true);          //set option to show all ROIs
	roiManager("Show All");                 //set option to show all ROIs
	setTool("freehand");                    //switch to freehand

	//Initialize the statsTable Array in these following statements:
	origImgPath = getDirectory("image");
	origImgFileName = File.name;
	sliceQty = nSlices;
	sliceWidth = getWidth();
	sliceHeight = getHeight();
	getVoxelSize(voxelWidth, voxelHeight, voxelDepth, voxelUnit);
	voxelVolume = voxelWidth * voxelHeight * voxelDepth;
	for(i=1;i<=sliceQty;i++) {
		if(i<10){
			statsTable[i] = "" + origImgPath + "," + origImgFileName + "," + sliceQty + ",00" + i + "," + "NoAction,NoAction,NoAction,NoAction,NoAction,NoAction," + sliceWidth + ","+ sliceHeight + "," +  voxelWidth + "," + voxelHeight + "," + voxelDepth + "," + voxelUnit + "," + voxelVolume + ",";
  
		}
		else if(i<100) {
			statsTable[i] = "" + origImgPath + "," + origImgFileName + "," + sliceQty + ",0" + i + "," + "NoAction,NoAction,NoAction,NoAction,NoAction,NoAction," + sliceWidth + ","+ sliceHeight + "," + voxelWidth + "," + voxelHeight + "," + voxelDepth + "," + voxelUnit + "," + voxelVolume + ",";
  
		}
		else {
			statsTable[i] = "" + origImgPath + "," + origImgFileName + "," + sliceQty + "," + i + "," + "NoAction,NoAction,NoAction,NoAction,NoAction,NoAction," + sliceWidth + ","+ sliceHeight + "," + voxelWidth + "," + voxelHeight + "," + voxelDepth + "," + voxelUnit + "," + voxelVolume + ",";
  
		} 
	
	}

	//Make a temporary copy of the Image:
	tempOriginalImage = "_temp_" + blindnum + "_copyOfOriginal_" + username + "" + datetimestamp + "";
	run("NIfTI-1", "save=["+outdir+tempOriginalImage+"-nifti-1.nii]");
}



macro "ManualWMH clear slice [F3]" {
	if (bitDepth!=8) exit("8-bit grayscale image required");
	// ...else:
	showMessageWithCancel("Make slice black?","Clear all voxels, making this slice black? This cannot be undone.");
	sliceAction = "sliceCleared";     
	sliceNumber = getSliceNumber();
	tempStats = getOrigSliceData(sliceAction,sliceNumber);
	statsTable[sliceNumber] = "" + tempStats + "";
	run("Select All");
	run("Clear", false);
	run("Select None");
	run("Invert", false);                   //re-invert mask (ROIs=255)
	setThreshold(150,255);                  //set reasonable initial threshold
}



macro "ManualWMH segment slice [F4]" {
	showMessageWithCancel("Segment slice?","Convert the selected, thresholded voxels to a mask and erase everything else on the slice? This cannot be undone.");
	
	//verify that the image is 8-bit:
	if (bitDepth!=8) exit("8-bit grayscale image required");

	//verify that there is at least one ROI in roiManager:
	roiQty = roiManager("count");
	if(roiQty < 1) {
		exit("At least one selection is required. Remember to type [t] to send each selection to ROI Manager");
	}

	//verify that all of the ROIs contain at least one pixel in the thresholded range (Thanks Chitra!):
	thresholdedPixelsBool = ROIsIncludeThreshold();
	if(!thresholdedPixelsBool) {
		exit("One or more of your ROIs does not contain any thresholded pixels. \n Please either adjust the threshold or use the ROI Manager to remove the empty ROIs.");
	}

	//Set sliceAction to be masked:
	sliceAction = "sliceMasked";     

	//call the pre-masked function:
	sliceNumber = getSliceNumber();
	tempStats = getOrigSliceData(sliceAction,sliceNumber);
	statsTable[sliceNumber] = "" + tempStats + "";

	//now mask the slice:
	run("Select None");
	setBatchMode(true);
	id = getImageID;
	run("Create Mask");                     //mask current slice...
	run("Copy");
	close;
	selectImage(id);
	run("Paste");
	setBatchMode(false);
	run("Select None");                     //unselect everything
	run("Invert", false);                   //invert entire mask
	n = roiManager("count");                //select all ROIs
	for (i=0; i<n; i++) {
		setKeyDown("shift");
		roiManager("select", i);
		roiManager("Update");
	}
	run("Clear Outside", false);            //clear outside of ROIs
	run("Select None");                     //deselect ROIs
	run("Invert", false);                   //re-invert mask (ROIs=255)
	roiManager("reset");                    //delete all ROIs
//      n = getSliceNumber;                     //advance to next slice
//      if (n<nSlices)
//        setSlice(n+1);
	setThreshold(150,255);                  //set reasonable initial threshold
}



function FlushOutput() {
	statsFileHandle= File.open(outdir + statsFileName);
	print(statsFileHandle, "origImgPath,origImgFileName,sliceQty,sliceNum,sliceAction,zoom,displayMin,displayMax,threshMin,threshMax,sliceWidth,sliceHeight,voxelWidth,voxelHeight,voxelDepth,voxelUnit,voxelVolume,wmhiPixels,wmhiMin,wmhiMax,wmhiMean,wmhiStd");

	for(i=1;i<=nSlices;i++)
		print(statsFileHandle, statsTable[i]);
	File.close(statsFileHandle);
}


function getNonZeroPixelStats(startX,startY,width,height) {
	print("X,Y :" + startX + "," + startY);
	countNonZeroPixels = 0;
	nonZeroPixelStats = "";
	max = getPixel(startX,startY);
	sum = 0;
	mean = 0;
	currentX = startX;
	currentY = startY;
	min = 0;
	while(currentX <= width) {
		while(currentY <= height) {
			pixelValue = getPixel(currentX,currentY);
			if(pixelValue > 0){
				if(countNonZeroPixels == 0)
					min = pixelValue;
				if(pixelValue < min)
					min = pixelValue;
				if(pixelValue > max)
					max = pixelValue;
				countNonZeroPixels++;
				sum = sum + pixelValue;		
			}
			currentY++;
		}
		currentX++;
		currentY = startY;
	}
	if(countNonZeroPixels > 0) mean = (sum/countNonZeroPixels);
	stdDeviation = calculateStdDeviation(startX, startY, width, height, mean, countNonZeroPixels);
	nonZeroPixelStats = "" + countNonZeroPixels + "," + min + "," + max + "," + mean + "," + stdDeviation + "";
	return nonZeroPixelStats;
}


function calculateStdDeviation(startX, startY, width, height, mean, countNonZeroPixels) {
	stdDeviation = 0;
	sum = 0;
	variance = 0;
	currentX = startX;
	currentY = startY;
	while(currentX <= width) {
		while(currentY <= height) {
			pixelValue = getPixel(currentX,currentY);
			if(pixelValue > 0){
				sum = sum + ((pixelValue - mean)*(pixelValue - mean));
			}
			currentY++;
		}
		currentX++;
		currentY = startY;
	}
	if(countNonZeroPixels > 0)
		variance = (sum/countNonZeroPixels-1);
	if(variance > 0)
		stdDeviation = sqrt(variance);
	return stdDeviation;
}



macro "ManualWMH output stats [F5]" {

	//write mask file:
	showMessageWithCancel("Write this stack, which should now be a mask, to a nifti file: \n " + maskFileName + ".nii?");
	
	run("Divide...", "stack value=255"); //Convert Mask from 255 to 1
	//run("Analyze... ", "save=["+outdir+maskFileName+"-analyze]");
	//run("Analyze 7.5", "save=["+outdir+maskFileName+"-analyze75]");
	run("NIfTI-1", "save=["+outdir+maskFileName+"-nifti-1.nii]");

	//close the file, leaving no chance user will accidentally save changes to original file:
	close();

	//open the mask to verify write:
	open(""+outdir+maskFileName+"-nifti-1.nii");
	setMinAndMax(0,1);

	//open the tempOriginalImage:
	open(""+outdir+tempOriginalImage+"-nifti-1.nii");
	
	//Image Algebra:
	run("Image Calculator...", "image1=["+tempOriginalImage+"-nifti-1.nii] operation=Multiply image2=["+maskFileName+"-nifti-1.nii] create stack");
	run("NIfTI-1", "save=["+outdir+maskProductFileName+"-nifti-1.nii]");
	
	//Close The maskProduct Image:
	close();

	//close tempOriginalImage:
	selectImage(""+tempOriginalImage+"-nifti-1.nii");
	close();	

	//Close the mask:
	selectImage(""+maskFileName+"-nifti-1.nii");
	close();

	//Open the maskProductFile:
	open(""+outdir+maskProductFileName+"-nifti-1.nii");
	selectImage(""+maskProductFileName+"-nifti-1.nii");

	//Get and Save Statistics for NonZero Pixels in MaxProduct
	for(sliceNum=1;sliceNum<=nSlices;sliceNum++) {
		setSlice(sliceNum);
		run("Select All");
		getSelectionBounds(startX,startY,width,height);
		nonZeroPixelStats = getNonZeroPixelStats(startX,startY,width,height);	
		statsTable[sliceNum] = "" + statsTable[sliceNum] + nonZeroPixelStats + "\n";
	}

	//Invoke Function to Write Stats to Log and Write Log to Disk
	FlushOutput();
}
