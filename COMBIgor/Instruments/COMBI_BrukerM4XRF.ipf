#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Description/Summary of Procedure File
// Version History
// V1: Dylan Bardgett, July 2019 : Original draft of procedures

//Description of procedure purpose:
//This procedure imports the raw output data (either a single .txt file or a folder of files) generated from the Bruker M4 Tornado micro-XRF into an Igor experiment.

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Instrument
Static StrConstant sInstrument = "BrukerM4XRF"


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this instrument
Menu "COMBIgor"
	SubMenu "Instruments"
	 	"BrukerM4XRF",/Q, COMBI_BrukerM4XRF()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//returns a list of descriptors for each of the globals used to define file loading. 
Function/S BrukerM4XRF_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for
	
	//This section builds the menu, access panel, and the Define process for this instrument
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring =""
	//FOR DEVELOPERS: Here you will add or remove specific cases depending
	//on what your instrument needs. 
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "InInstrumentMenu":
			twGlobals[1][0] = "No"
			break
		//This case determines whether the function is in the Access Panel; change to "No" if you don't want it there
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "BrukerM4XRF":
			sReturnstring = "BrukerM4XRF"
			break
		//these are the specific variables that are collected by the Define process
		case "sXDest":
			sReturnstring =  "X stage position (mm) label:"
			break
		case "sYDest":
			sReturnstring = "Y stage position (mm) label:"
			break
		case "sYAxis":
			sReturnstring =  "Y axis: Intensity"
			break
		case "sXAxis":
			sReturnstring =  "X axis: Energy (keV)"
			break
		//provide the value of the lowest energy sampled in the spectra
		case "vInitialEnergy":
			sReturnstring = "The lowest energy value"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	//puts global value into 0th row and 0th column of globals wave for other functions to access
	twGlobals[0][0] = sReturnstring 
	return sReturnstring
end


//This function will be executed when the user selects to define the Instrument in the Instrument definition panel
function BrukerM4XRF_Define()
	//get Instrument name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	//Might be something like string sIntensity for XRD intensity, or variable vThicknessColumn for XRF thickness source column
	string sXDest, sYDest ,sYAxis, sXAxis
	variable vInitialEnergy
	
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		//FOR DEVELOPERS: Make sure these all match the globals defined above!
		sYAxis = COMBI_GetInstrumentString(sThisInstrumentName,"sYAxis",sProject)
		sXAxis = COMBI_GetInstrumentString(sThisInstrumentName,"sXAxis",sProject)
		sXDest = COMBI_GetInstrumentString(sThisInstrumentName,"sXDest",sProject)
		sYDest = COMBI_GetInstrumentString(sThisInstrumentName,"sYDest",sProject)
		vInitialEnergy = COMBI_GetInstrumentNumber(sThisInstrumentName,"vInitialEnergy",sProject)

	else 
		//if not previously defined, start with default values 
		sXDest = "Xmm_XRF"
		sYDest = "Ymm_XRF"
		sYAxis = "BrukerXRF_Intensity" 
		sXAxis = "BrukerXRF_Energy_keV"
		vInitialEnergy = -0.9548 //This is the default lowest energy value (in keV), where the next energy sampled is -0.9448 keV.
	endif
	
	//set the global
		Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)
		
	//get names for data types
	//cleanupname makes sure the data type name is allowed
	sYAxis = cleanupname(COMBI_DataTypePrompt(sProject,sYAxis,BrukerM4XRF_Descriptions("sYAxis"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sYAxis,"CANCEL"))
		return -1
	endif
	//cleanupname makes sure the data type name is allowed
	sXAxis = cleanupname(COMBI_DataTypePrompt(sProject,sXAxis,BrukerM4XRF_Descriptions("sXAxis"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sXAxis,"CANCEL"))
		return -1
	endif
	
	vInitialEnergy = COMBI_NumberPrompt(vInitialEnergy,"Initial Energy:","This will be used to create the abscissa for the intensity plots","Initial Energy:")
	if(numtype(vInitialEnergy)!=0)
		return -1
	endif
	
	//mark as defined by storing instrument globals in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sYAxis",sYAxis,sProject)// store Instrument global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sXAxis",sXAxis,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vInitialEnergy",num2str(vInitialEnergy),sProject)
	//mark as defined by storing the instrument name in the main globals
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,"COMBIgor")

	//reload definition panel
	COMBI_InstrumentDefinition()
	
end


////this function will be executed when the user selects to load data button in the Instrument definition panel
//This function will handle the actual loading of the data. This will check if the user wants to 
//load a single file or a full folder, and then redirect to the appropriate function. 
function BrukerM4XRF_Load()

	//initializes the instrument
	Combi_InstrumentReady("BrukerM4XRF")
	//get Instrument name and project name, store in local strings
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//prompts for project, load type (ie individual file or folder), and wavelength
	string sLoadType
	variable vInitialEnergy = -0.9548
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sLoadType, "Load Type:", popup, "Folder;File"
	DoPrompt/HELP="This tells me how you want to load data." "Loading Input", sLoadType
	//this breaks if the user selects cancel
	if (V_Flag)
		return -1
	endif
	
	//if the user is loading an entire folder, call the LoadFolder function
	if(stringmatch(sLoadType,"Folder"))
		// get globals
		string sXAxis = Combi_GetInstrumentString("BrukerM4XRF","sXAxis",sProject)
		string sYAxis = Combi_GetInstrumentString("BrukerM4XRF","sYAxis",sProject)		
		//if the user has the command line setting on, print the call line so the user can use it programmatically
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "BrukerM4XRF_LoadFolder(\""+sProject+"\",\""+sYAxis+"\",\""+sXAxis+"\")"
		endif
		//call the LoadFolder function
		BrukerM4XRF_LoadFolder(sProject,sYAxis,sXAxis)
	//if the user is just loading a single file, call the LoadFile function
	elseif(stringmatch(sLoadType,"File"))
		BrukerM4XRF_LoadFile(sProject)
	endif
	
end


//this function loads a folder of *.txt files where each txt has the X-axis in Row 1 and the Y-axis in Row 2
//inputs: 
	//sProject: the project we are operating in
	//sYAxis: the destination Y-axis wave
	//sXAxis: the destination X-axis wave
function BrukerM4XRF_LoadFolder(sProject,sYAxis,sXAxis)
	//define strings and variables	
	string sProject, sYAxis, sXAxis
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	variable vIndex
	string sThisInstrumentName = "BrukerM4XRF"
	// get global wavelength to use if necessary (currently not being used)
	variable vInitialEnergy = Combi_GetInstrumentNumber(sThisInstrumentName,"vInitialEnergy",sProject)

	//////this section gets the data path/////
	// get global import folder
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	//if the predefined import folder exists, set the initial path to that folder
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		NewPath/Z/Q/O pLoadPath
	//if it doesn't exist, just start a new path
	else
		NewPath/Z/Q/O pLoadPath
	endif
	//stores some path info in v_flag and s_path variables
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log

	/////this section makes sure the number of files is 44, or sets an offset if not/////
	//
	//vTotalSamples is the number of samples on a standard library (usually 44)
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
		string sAllFiles = IndexedFile(pLoadPath,-1,".txt")
	//grabs the total number of files in the folder you gave it
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	//default start of samples to 1 (ie no offset)
	variable vFirstSample = 1
	//throw an error if the total number of files isn't the total expected number of samples
	if (vNumberOfFiles != vTotalSamples)
		//handles partial library
		DoAlert/T="Mismatched number of samples",0,"There must be one file in this folder per sample on the mapping grid. COMBIgor has found "+num2str(vNumberOfFiles)+" files but "+num2str(vTotalSamples)+" samples in the mapping grid for this project."
		if(vTotalSamples>vNumberOfFiles)
			DoAlert/T="Is this a subset of samples?",1,"Are you trying to load a partial measurement?"
			if(V_flag==1)
				vFirstSample = COMBI_NumberPrompt(vFirstSample,"What was the first sample number measured?","This will shift File #1 to this file number and proceed with loading","Define sampling offset")
			else
				SetDataFolder $sTheCurrentUserFolder //return to users active data folder
				return -1
			endif
		else
			SetDataFolder $sTheCurrentUserFolder //return to users active data folder
			return -1
		endif
	endif
	
	//////this section handles file name parsing//////
	//This code will only work if your file names are in the format "prefix01suffix.txt"
	//This is the default naming scheme of the Bruker M4 Tornado XRF with the automatic sample numbering turned on, so
	//you shouldn't need to worry too much about this part.
	//
	//grabs first section of first file name (0th file)
	string sFirstFile = removeending(IndexedFile(pLoadPath,0,".txt"),".txt")	
	//splits it into two ascii chunks (sPrefixPart and sSuffixPart)
	String expr="([[:ascii:]]*)_([[:digit:]]+)_([[:digit:]]+)"
	string sLibraryName, sLibraryNumber, sSampleNumber
	SplitString/E=(expr) sFirstFile, sLibraryName, sLibraryNumber, sSampleNumber
	string sPrefixPart = sLibraryName+"_"+sLibraryNumber+"_", sSuffixPart = ""
	
	///////this section gets user input for the file prefix and suffix, total number of files, and library name//////
	//
	//user prompt initialize -- takes in splitstring output for prefix and suffix
	string sDataFileNamePrefix=sPrefixPart
	string sDataFileNameSuffix=sSuffixPart
	//initialize first and last file numbers to 1 and vTotalSamples
	variable vFirstFileNum = 1
	variable vLastFileNum = Combi_GetGlobalNumber("vTotalSamples",sProject)
	//prompt descriptions for the user
	prompt sDataFileNamePrefix, "File Prefix:"
	prompt sDataFileNameSuffix, "File Suffix:"
	prompt vFirstFileNum, "From File Index:"
	prompt vLastFileNum, "To File Index:"
	string sThisHelp = "Helps find the files to load"
	//actually do the prompt with initialized values
	DoPrompt/HELP=sThisHelp "Files", sDataFileNamePrefix, sDataFileNameSuffix, vFirstFileNum, vLastFileNum
	if (V_Flag)
		SetDataFolder $sTheCurrentUserFolder //return to users active data folder
		return -1//user cancelled
	endif
	//prompt for the library name
	string sNewLibrary = COMBI_LibraryPrompt(sProject,"New","Name of Library",0,1,0,2)
	if(stringmatch(sNewLibrary,"CANCEL"))
		SetDataFolder $sTheCurrentUserFolder//return to users active data folder 
		return -1
	endif
	
	//////this section loads all of the data into ScansFolder//////
	//make a new folder to put the loaded files and set it as root
	NewDataFolder/O/S ScansFolder
	//initialize loop index
	int iSample
	//loop from firstFileNum-1 to lastFileNum-1
	if (Combi_GetGlobalNumber("vTotalSamples",sProject)>=10)
		for(iSample=(vFirstFileNum-1);iSample<(vLastFileNum);iSample+=1)
			string sWaveName, sFileName
			//set the destination wave name as "LoadedWave_scanNum", correcting for a constant index length (so you have LoadedWave_01 instead of LoadedWave_1)
			sWaveName = "LoadedWave_"+COMBI_PadIndex((iSample+1),2)
			//sets the source file name based on previous user inputs, correcting for constant index length
			sfileName = sDataFileNamePrefix+COMBI_PadIndex((iSample+1),2)+sDataFileNameSuffix+".txt"
			//load numeric wave from sfileName into sWaveName, from pLoadPath
			//FOR DEVELOPERS: This code needs to be edited to load your specific file type.
			//This will likely be done by adding or removing flags from the LoadWave function (/J and /M are examples of flags).
			//Check out the Igor documentation for LoadWave and figure out what your file type needs. 
			LoadWave/G/M/O/D/N=$sWaveName/p=pLoadPath/K=1/Q/L={20,21,0,0,2} sfileName
			//renames the wave to get rid of the automatic 0 that igor puts at the end of the wave
			rename $"root:ScansFolder:"+sWaveName+"0",$sWaveName
		endfor
	elseif (Combi_GetGlobalNumber("vTotalSamples",sProject)<=10)
		for(iSample=(vFirstFileNum-1);iSample<(vLastFileNum);iSample+=1)
			//set the destination wave name as "LoadedWave_scanNum", correcting for a constant index length (so you have LoadedWave_01 instead of LoadedWave_1)
			sWaveName = "LoadedWave_"+COMBI_PadIndex((iSample+1),1)
			//sets the source file name based on previous user inputs, correcting for constant index length
			sfileName = sDataFileNamePrefix+COMBI_PadIndex((iSample+1),1)+sDataFileNameSuffix+".txt"
			//load numeric wave from sfileName into sWaveName, from pLoadPath
			//FOR DEVELOPERS: This code needs to be edited to load your specific file type.
			//This will likely be done by adding or removing flags from the LoadWave function (/J and /M are examples of flags).
			//Check out the Igor documentation for LoadWave and figure out what your file type needs. 
			LoadWave/G/M/O/D/N=$sWaveName/p=pLoadPath/K=1/Q/L={20,21,0,0,2} sfileName
			//renames the wave to get rid of the automatic 0 that igor puts at the end of the wave
			rename $"root:ScansFolder:"+sWaveName+"0",$sWaveName
		endfor
	endif
	setdatafolder root:
	
	////this function call uses the canned sorting function to organize this data into the correct Combi structure////
	//uses the user-defined vFirstSample and the vNumberOfFiles to take care of any potential offset
	//all 1 and 2 values subtracted from vFirstSample, vFirstFile etc are there to correct off-by-one errors (indexing from 0 instead of 1)
	Combi_SortNewVectors(sProject, "root:ScansFolder:","LoadedWave_","",strlen(sSampleNumber),sNewLibrary,sXAxis+";"+sYAxis,num2str(vFirstSample-1),num2str(vFirstSample+vNumberOfFiles-2),num2str(vFirstFileNum-1),num2str(vLastFileNum-1),0)

	//kill path and empty scans folder
	Killpath/A
	KillDataFolder/Z root:ScansFolder	
	
	////this section sets the scale for the vector data so that you can make a Gizmo////
	//get data path to Intensity and set scale in column dim
	wave wIntensity = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sYAxis
	wave wEnergy = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sXAxis
	SetScale/I x,wEnergy[0],wEnergy[(dimsize(wIntensity,0)-1)],wIntensity

	////this section adds important info to data log////
	//FOR DEVELOPERS: Make sure you edit this!!!!
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File Folder: "+sThisLoadFolder
	sLogEntry2 = "Library Samples: "+num2str(vFirstSample)+" to "+num2str(vFirstSample+vNumberOfFiles-1)
	sLogEntry3 = "From File Indexes: "+num2str(vFirstFileNum-1)+" to "+num2str(vLastFileNum-1)
	sLogEntry4 = "Data Types: "+sXAxis+","+sYAxis
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sNewLibrary,"BrukerM4XRF",1,sLogText)			
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
end


////this function loads a single *.txt file into the root folder
function BrukerM4XRF_LoadFile(sProject)
	//FOR DEVELOPERS: The following code is fairly general and shouldn't need to be edited much.
	string sProject
	string sCurrentUserFolder = GetDataFolder(1) 
	// get global import folder
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	
	//prompt for the library name
	string sNewLibrary = COMBI_LibraryPrompt(sProject,"New","Name of Library",0,1,0,2)
	if(stringmatch(sNewLibrary,"CANCEL"))
		SetDataFolder $sCurrentUserFolder//return to users active data folder 
		return -1
	endif
	
	string dPath = "root:COMBIgor:"+sProject+":Data:"+sNewLibrary
	SetDataFolder $dPath
	
	// if there's an import folder, use it
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		//load from the input file to FileIn
		LoadWave /P=pUserPath /A=FileIn /G /L={20,21,0,0,2} //the parameters in L are specific to the Bruker M4 Tornado ".txt" output files
	// if there isn't an import folder, get a folder
	else
		LoadWave /A=FileIn /G /L={20,21,0,0,2}
	endif
	
/////this commented stuff could help add to the data log if we wanted to
//	string sThisLoadFile = S_fileName //for storing source folder in data log
//	if(strlen(sThisLoadFile)==0)
//		//no file selected
//		return ""
//	endif
//	
//	variable vPathLength = itemsinlist(sThisLoadFile,":")
//	String sFileName = stringfromlist(vPathLength-1,sThisLoadFile,":")
//	string sFilePath = removeending(sThisLoadFile,sFileName)
//		
//	return S_waveNames	
	
end


//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
//
function COMBI_BrukerM4XRF()
	COMBI_GiveGlobal("sInstrumentName","BrukerM4XRF","COMBIgor")
	COMBI_InstrumentDefinition()
end
