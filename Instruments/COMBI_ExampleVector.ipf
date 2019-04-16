#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Description/Summary of Procedure File
// Version History
// V1: Celeste Melamed _ Dec 2018 : Original Example Vector Loader 
// V1.01: Celeste Melamed _ Dec 2018 : Adding comments for developers

//Description of procedure purpose:
//This Procedure contains an example for a generic instrument named "ExampleVector", this can be followed as an example for creating new vector instruments in COMBIgor
//The loader has an option for a single file loader, and also a full folder of Combi data
//Each of the functions shown here must exist to work with the Instrument definition panel, all function names should have "Example" replaced with the corresponding Instrument name.


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Instrument
//FOR DEVELOPERS: Define a unique instrument name here.
Static StrConstant sInstrument = "ExampleVector"


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this instrument
//FOR DEVELOPERS: Change COMBI_ExampleVector() to COMBI_YourInstrument() (to match the last function
//in this file), and change "Example Vector Instrument" to whatever description you want
//in the drop-down COMBIgor menu for your instrument. If there is additional functionality for your
//Instrument, you can add another nested Submenu.
Menu "COMBIgor"
	SubMenu "Instruments"
	 	"Example Vector Instrument",/Q, COMBI_ExampleVector()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




//returns a list of descriptors for each of the globals used to define file loading. 
//FOR DEVELOPERS: In this function, you will define the instrument globals used for your
//unique instrument loader. For example, a data loader may need to know the
//column where a specific data type lives (ie the thickness column in an XRF loader).
//This can be stored as an Instrument global using the "vSomeNumber" case by changing the 
//name and the description. You may have multiple of each type -- ie more than one string,
//or only integers, etc -- and that's totally fine.
//There can be as many Instrument globals as needed, specify a new "case" in the strswitch for each.
Function/S ExampleVector_Descriptions(sGlobalName)
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
		case "ExampleVector":
			sReturnstring = "ExampleVector"
			break
		//these are the specific variables that are collected by the Define process
		case "sYAxis":
			sReturnstring =  "Y axis:"
			break
		case "sXAxis":
			sReturnstring =  "X axis:"
			break
		case "vSomeNumber":
			sReturnstring = "Some number for measurement (ie wavelength):"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	//puts global value into 0th row and 0th column of globals wave for other functions to access
	twGlobals[0][0] = sReturnstring 
	return sReturnstring
end





//this function will be executed when the user selects to define the Instrument in the Instrument definition panel
//FOR DEVELOPERS: Edit this function so that the user defines all of the Globals that you introduced in the Descriptions
//function (above). Everywhere this function has "sSomeString", "sSomeDataType", or "vSomeNumber", you will need to edit/replace
//with your own specific globals for your instrument. This function uses many COMBIgor Data functions (ie the Combi_Prompt
//functions and the Combi_GetInstrument functions), so be sure to check those out and double check that you are passing them 
//the right inputs.
function ExampleVector_Define()

	//get Instrument name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	//Might be something like string sIntensity for XRD intensity, or variable vThicknessColumn for XRF thickness source column
	string sYAxis
	string sXAxis
	
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		//FOR DEVELOPERS: Make sure these all match the globals defined above!
		sYAxis = COMBI_GetInstrumentString(sThisInstrumentName,"sYAxis",sProject)
		sXAxis = COMBI_GetInstrumentString(sThisInstrumentName,"sXAxis",sProject)

	else 
		//not previously defined, start with default values 
		//FOR DEVELOPERS: Put in reasonable default values for your specific Globals here
		sYAxis = "DefaultYAxis" 
		sXAxis = "DefaultXAxis"
		//set the global
		Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)
	endif
	
		
	//get names for data types
	//cleanupname makes sure the data type name is allowed
	//FOR DEVELOPERS: Here is a good time to check out the COMBI_DataTypePrompt function documentation and see 
	//what all those 0s and 1s are doing! Make sure that they are doing what you want. 
	sYAxis = cleanupname(COMBI_DataTypePrompt(sProject,sYAxis,ExampleVector_Descriptions("sYAxis"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sYAxis,"CANCEL"))
		return -1
	endif
	//cleanupname makes sure the data type name is allowed
	sXAxis = cleanupname(COMBI_DataTypePrompt(sProject,sXAxis,ExampleVector_Descriptions("sXAxis"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sXAxis,"CANCEL"))
		return -1
	endif
	
	//mark as defined by storing instrument globals in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sYAxis",sYAxis,sProject)// store Instrument global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sXAxis",sXAxis,sProject)// store Instrument global 
	//mark as defined by storing the instrument name in the main globals
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,"COMBIgor")

	//reload definition panel
	COMBI_InstrumentDefinition()
	
end


////this function will be executed when the user selects to load data button in the Instrument definition panel
//FOR DEVELOPERS: This function will handle the actual loading of your data. This will check if the user wants to 
//load a single file or a full folder, and then redirect to the appropriate function. (When you are building a
//new vector loader, having functionality to load a single vector file is HIGHLY RECOMMENDED -- this is very useful
//both for the developer to double check their file loading, and for the user to save time and memory if they only
//want to look at one scan.)
function ExampleVector_Load()

	//initializes the instrument
	Combi_InstrumentReady("ExampleVector")
	//get Instrument name and project name, store in local strings
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//prompts for project, load type (ie individual file or folder), and wavelength
	//FOR DEVELOPER: Edit here to reflect the specific load type and number (if necessary) for your instrument.
	string sLoadType
	variable vSomeNumber = 1.5406
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sLoadType, "Load Type:", popup, "Folder;File"
	prompt vSomeNumber, "Some scan-specific number (ie wavelength):"
	DoPrompt/HELP="This tells me how you want to load data." "Loading Input", sLoadType, vSomeNumber
	//this breaks if the user selects cancel
	if (V_Flag)
		return -1
	endif
	
	//sets the user-defined prompts as globals for the instrument
	Combi_GiveInstrumentGlobal("ExampleVector","vSomeNumber",num2str(vSomeNumber),sProject)
	//if the user is loading an entire folder, call the LoadFolder function
	if(stringmatch(sLoadType,"Folder"))
		// get globals
		string sXAxis = Combi_GetInstrumentString("ExampleVector","sXAxis",sProject)
		string sYAxis = Combi_GetInstrumentString("ExampleVector","sYAxis",sProject)		
		//if the user has the command line setting on, print the call line so the user can use it programmatically
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "ExampleVector_LoadFolder(\""+sProject+"\",\""+sYAxis+"\",\""+sXAxis+"\")"
		endif
		//call the LoadFolder function
		ExampleVector_LoadFolder(sProject,sYAxis,sXAxis)
	//if the user is just loading a single file, call the LoadFile function
	elseif(stringmatch(sLoadType,"File"))
		ExampleVector_LoadFile()
	endif
	
end



//this function loads a folder of *.csv files where each csv has the X-axis in Row 1 and the Y-axis in Row 2
//inputs: 
	//sProject: the project we are operating in
	//sYAxis: the destination Y-axis wave
	//sXAxis: the destination X-axis wave
//FOR DEVELOPERS: This function will need to be edited to make sure that it works with your specific file type
//(ie .csv, .raw, .txt, etc.) and specific wave destinations/
function ExampleVector_LoadFolder(sProject,sYAxis,sXAxis)
	//define strings and variables	
	string sProject, sYAxis, sXAxis
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	variable vIndex
	string sThisInstrumentName = "ExampleVector"
	// get global wavelength to use if necessary (currently not being used)
	variable vSomeNumber = Combi_GetInstrumentNumber(sThisInstrumentName,"vSomeNumber",sProject)

	//////this section gets the data path/////
	//FOR DEVELOPERS: The following code is fairly general and shouldn't need to be edited much.
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
	//FOR DEVELOPERS: The following code is fairly general and shouldn't need to be edited much.
	//
	//vTotalSamples is the number of samples on a standard library (usually 44)
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
		string sAllFiles = IndexedFile(pLoadPath,-1,".csv")
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
	//FOR DEVELOPERS: This code will only work if your file names are in the format prefix0001suffix.csv.
	//A good place to start when you're building your loader is to remove the file name parsing and manually
	//enter the prefix and suffix. When you're sure the rest of the code is working, see if you can get the filename
	//parsing to work. Talk to K.Talley for more file parsing info (he wrote it).
	//
	//grabs first section of first file name (0th file)
	string sFirstFile = removeending(IndexedFile(pLoadPath,0,".csv"),".csv")	
	//splits it into two ascii chunks (sPrefixPart and sSuffixPart)
	////this will not work if the 0th file doesn't have 0001 in it
	String expr="([[:ascii:]]*)0001([[:ascii:]]*)"
	string sPrefixPart, sSuffixPart
	SplitString/E=(expr) sFirstFile, sPrefixPart, sSuffixPart
	
	
	
	///////this section gets user input for the file prefix and suffix, total number of files, and library name//////
	//FOR DEVELOPERS: The following code is fairly general and shouldn't need to be edited much.
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
	for(iSample=(vFirstFileNum-1);iSample<(vLastFileNum);iSample+=1)
		string sWaveName, sFileName
		//set the destination wave name as "LoadedWave_scanNum", correcting for a constant index length (so you have LoadedWave_01 instead of LoadedWave_1)
		sWaveName = "LoadedWave_"+COMBI_PadIndex((iSample+1),2)
		//sets the source file name based on previous user inputs, correcting for constant index length
		sfileName = sDataFileNamePrefix+COMBI_PadIndex((iSample+1),4)+sDataFileNameSuffix+".csv"
		//load numeric wave from sfileName into sWaveName, from pLoadPath
		//FOR DEVELOPERS: This code needs to be edited to load your specific file type.
		//This will likely be done by adding or removing flags from the LoadWave function (/J and /M are examples of flags).
		//Check out the Igor documentation for LoadWave and figure out what your file type needs. 
		LoadWave/J/M/O/D/N=$sWaveName/p=pLoadPath/K=1/Q/L={0,1,0,0,0} sfileName
		//renames the wave to get rid of the automatic 0 that igor puts at the end of the wave
		rename $"root:ScansFolder:"+sWaveName+"0",$sWaveName
	endfor
	setdatafolder root:
	
	////this function call uses the canned sorting function to organize this data into the correct Combi structure////
	//uses the user-defined vFirstSample and the vNumberOfFiles to take care of any potential offset
	//all 1 and 2 values subtracted from vFirstSample, vFirstFile etc are there to correct off-by-one errors (indexing from 0 instead of 1)
	//FOR DEVELOPERS: You probably won't need to edit this much, but make sure you understand what it's doing and where
	//your data will be sorted to! (Especially check your x-axis, y-axis and the indexing on the sorting!)
	Combi_SortNewVectors(sProject, "root:ScansFolder:","LoadedWave_","",2,sNewLibrary,sXAxis+";"+sYAxis,num2str(vFirstSample-1),num2str(vFirstSample+vNumberOfFiles-2),num2str(vFirstFileNum-1),num2str(vLastFileNum-1),0)

	//kill path and empty scans folder
	Killpath/A
	KillDataFolder/Z root:ScansFolder	
	
	////this section sets the scale for the vector data so that you can make a Gizmo////
	//get data path to Intensity and set scale in column dim
	//FOR DEVELOPERS: You only need to do this if you want to be able to make a Gizmo out of the loaded vector
	//data. This is currently an example of scaling taken from an XRD loader, but will need to be made specific
	//for your data types.
	wave wIntensity = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sYAxis
	wave wQ = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sXAxis
	SetScale/I x,wQ[0],wQ[(dimsize(wIntensity,0)-1)],wIntensity

	////this section adds important info to data log////
	//FOR DEVELOPERS: Make sure you edit this!!!!
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File Folder: "+sThisLoadFolder
	sLogEntry2 = "Library Samples: "+num2str(vFirstSample)+" to "+num2str(vFirstSample+vNumberOfFiles-1)
	sLogEntry3 = "From File Indexes: "+num2str(vFirstFileNum-1)+" to "+num2str(vLastFileNum-1)
	sLogEntry4 = "Data Types: "+sXAxis+","+sYAxis
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sNewLibrary,"ExampleVector",1,sLogText)			
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
end



////this function loads a single *.csv file into the root folder
//FOR DEVELOPERS: This is a great place to start editing when you're building your loader! 
//The only thing that will need to be edited here is the flag(s) on LoadWave -- they will
//need to be specific for the file type of your data. 
function/S ExampleVector_LoadFile()
	
	// get import path global
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	
	// if there's an import folder, use it
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		//load from the input file to FileIn
		LoadWave /P=pUserPath /A=FileIn /J
	// if there isn't an import folder, get a folder
	else
		LoadWave /A=FileIn /J
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
//FOR DEVELOPERS: Change "ExampleVector" to the name of your Instrument; make sure your loader is appropriately named COMBI_YourInstrument.ipf
function COMBI_ExampleVector()
	COMBI_GiveGlobal("sInstrumentName","ExampleVector","COMBIgor")
	COMBI_InstrumentDefinition()
	DisplayProcedure/W=$"COMBI_ExampleVector.ipf"/L=0
end
