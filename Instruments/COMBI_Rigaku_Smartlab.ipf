#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "COMBIgor"
	SubMenu "Instruments"
		 SubMenu "Rigaku Smartlab"
	 		"Convert file numbering",/Q, Rigaku_Numbering()
	 		"Load *.ras data",/Q, Rigaku_LoadXRR() 
	 		"Log offset of patterns",/Q, LogOffset()
		 end
	end
end


///////////Dennice's functions//////////////////////
////Smartlab mapping function names files with _001001, _001002 ... _005005 --> example in a 5x5 map
///Convert file names to 001 style numbering
function Rigaku_Numbering()

string mypath, path_string
    NewPath/O/Q myPath    // Display choose folder dialog
    if (V_flag != 0)
        Print "User cancelled"
        return -1  
	endif
	
	PathInfo myPath
	path_string = S_path
	print path_string

//THis is redundant, but this is all I got right now
	variable vNumRows, vNumCol
	string sPrefixPart="", sSuffixPart=""
	variable vFileRows = vNumRows
	prompt vFileRows, "Number of rows (max X in 00X00Y):"
	variable vFileColumns = vNumCol
	prompt vFileColumns, "Number of columns (max Y in 00X00Y:"
	string sFilePrefix = sPrefixPart
	prompt sFilePrefix, "File Prefix:"
	string sFileSuffix =sSuffixPart
	prompt sFileSuffix, "File Suffix:"
	string sThisHelp
	sThisHelp = "Number of files in the chosen folder to convert from 00X00Y format to 00#"
	DoPrompt/HELP=sThisHelp "Smartlab Files", vFileRows, vFileColumns, sFilePrefix,sFileSuffix


//Make a look to iterate
variable iOuterNum, iInnerNum, iNewIter
	iNewIter = 1
		string sFileOld, sFileNew

//Loop for first digit
for(iInnerNum=1; iInnerNum<vFileRows+1; iInnerNum++)
	//Loop for second number
	for(iOuterNum=1; iOuterNum<vFileColumns+1; iOuterNum++)
	//Rename a file, using a symbolic path:
	sFileOld = sfilePrefix+"00"+num2str(iInnerNum)+"00"+num2str(iOuterNum)+sFileSuffix+".ras"
	if(iNewIter < 10)
	sFileNew = sFilePrefix+"00"+num2str(iNewIter)+sFileSuffix+".ras"
	else 
		sFileNew = sFilePrefix+"0"+num2str(iNewIter)+sFileSuffix+".ras"
	endif
	//Print path_string
	MoveFile/P=myPath sFileOld as sFileNew
	iNewIter = iNewIter+1
endfor
endfor

end
//////


//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
function Rigaku_LoadXRR()
	COMBI_GiveGlobal("sInstrumentName","Rigaku_Smartlab","COMBIgor")
	COMBI_InstrumentDefinition()
end


//returns a list of descriptors for each of the globals used to define file loading. There can be as many Instrument globals as needed, please specify a new "case" in the strswitch for each.
Function/S Rigaku_Smartlab_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for
	
	//this instrument's name
	string sInstrument = "Rigaku_Smartlab"
	
	
	//This section builds the menu, access panel, and the Define process for this instrument
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring =""
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "InInstrumentMenu":
			twGlobals[1][0] = "No"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "Rigaku_Smartlab":
			sReturnstring = "Rigaku_Smartlab"
			break
		//these are the specific variables that are collected by the Define process
		case "sIntensity":
			sReturnstring =  "Intensity:"
			break
		case "sDegree":
			sReturnstring =  "X axis in degrees 2theta:"
			break
		case "vWavelength":
			sReturnstring = "Wavelength of measurement:"
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
function Rigaku_Smartlab_Define()

	//get Instrument name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	string sIntensity
	string sDegree
	
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		sIntensity = COMBI_GetInstrumentString(sThisInstrumentName, "sIntensity",sProject)
		sDegree = COMBI_GetInstrumentString(sThisInstrumentName,"sDegree",sProject)

	else 
		//not previously defined, start with default values 
		sIntensity =  "SmartlabXRR_Intensity" 
		sDegree = "SmartlabXRR_Degree"
		//set the global
		Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)
	endif
	
		
	//get names for data types
	//cleanupname makes sure the data type name is allowed
	sIntensity = cleanupname(COMBI_DataTypePrompt(sProject,sIntensity,Rigaku_Smartlab_Descriptions("sIntensity"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sIntensity,"CANCEL"))
		return -1
	endif
	//cleanupname makes sure the data type name is allowed
	sDegree = cleanupname(COMBI_DataTypePrompt(sProject,sDegree,Rigaku_Smartlab_Descriptions("sDegree"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sDegree,"CANCEL"))
		return -1
	endif
	
	//mark as defined by storing instrument globals in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sIntensity",sIntensity,sProject)// store Instrument global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sDegree",sDegree,sProject)// store Instrument global 


	//mark as defined by storing the instrument name in the main globals
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,"COMBIgor")

	//reload definition panel
	COMBI_InstrumentDefinition()
	
end

//Load *.ras files\ folder
function Rigaku_Smartlab_LoadFolder(sProject,sIntensity,sDegree)
	//define strings and variables	
	string sProject, sIntensity, sDegree
	string sThisInstrumentName = "Rigaku_Smartlab"

	// get globals
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	variable vWavelength = Combi_GetInstrumentNumber(sThisInstrumentName,"vWavelength",sProject)
		
	// get import path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O pLoadPath
	else
		NewPath/Z/Q/O pLoadPath
	endif
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	//get number of Libraries
	string sAllFiles = IndexedFile(pLoadPath,-1,".ras")
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	string sFirstFile = removeending(IndexedFile(pLoadPath,0,".ras"),".ras")
	string sLastFile = removeending(IndexedFile(pLoadPath,vNumberOfFiles-1,".ras"),".ras")
	variable vFirstFileNameLength = strlen(sFirstFile)
	variable vLastFileNameLength = strlen(sLastFile)
	
	//parse file name
	String expr="([[:ascii:]]*)001([[:ascii:]]*)"
	string sPrefixPart, sSuffixPart
	SplitString/E=(expr) sFirstFile, sPrefixPart, sSuffixPart
	
	string sFirstIndex = replaceString(sPrefixPart,sFirstFile,"")
	sFirstIndex = replaceString(sSuffixPart,sFirstIndex,"")
	variable vFirstFileNum = str2num(sFirstIndex)
	
	string sLastIndex = replaceString(sPrefixPart,sLastFile,"")
	sLastIndex = replaceString(sSuffixPart,sLastIndex,"")
	variable vLastFileNum = str2num(sLastIndex)

	//prompt user to help parse file names
	string sFilePrefix = sPrefixPart
	prompt sFilePrefix, "File Prefix:"
	string sFileSufix =sSuffixPart
	prompt sFileSufix, "File Suffix:"
	variable vIndexDigits = strlen(sLastIndex)
	prompt vIndexDigits, "Indexing Digits:"
	prompt vFirstFileNum, "From File Index:"
	prompt vLastFileNum, "To File Index:"
	string sThisHelp
	sThisHelp = "This helps me find all the files to load. The file name is constructed from the Prefix + (Index of set # of digits) + Suffix"
	DoPrompt/HELP=sThisHelp "Smartlab Files", sFilePrefix, sFileSufix, vFirstFileNum, vLastFileNum,vIndexDigits
	if (V_Flag)
		return -1// User canceled
	endif
	
	//number of Libraries
	variable vNumberOfLibraries = floor((vLastFileNum-vFirstFileNum+1)/vTotalSamples)
	vNumberOfLibraries = Combi_NumberPrompt(vNumberOfLibraries,"Number of Libraries in this folder","This tells me how many Libraries we are going to be loading, if you want to skip one, you can do that later, just tell the total Libraries me now.","Libraries in Folder?")
	if(numtype(vNumberOfLibraries)==2)
		return-1
	endif	
	if(vNumberOfLibraries<1||vNumberOfLibraries>4)//too many or too few Libraries
	
		DoAlert/T="COMBIgor error." 0,"Number of libraries has to be between one and four"
		return -1
	endif



	//prompt for the library name
	string sNewLibrary = COMBI_LibraryPrompt(sProject,"New","Name of Library",0,1,0,2)
	if(stringmatch(sNewLibrary,"CANCEL"))
		return -1
	endif
	
	
	//////this section loads all of the data into SmartlabScansFolder//////
	//make a new folder to put the loaded files and set it as root
	NewDataFolder/O/S SmartlabScansFolder
	//initialize loop index
	int iIndex
	//loop from firstFileNum-1 to lastFileNum-1
	for(iIndex=(vFirstFileNum-1);iIndex<(vLastFileNum);iIndex+=1)
		string sWaveName, sFileName
		//set the destination wave name as "SmartlabXRD_scanNum", correcting for a constant index length
		sWaveName = "Smartlab_"+COMBI_PadIndex((iIndex+1),3)
		//sets the source file name based on previous user inputs, correcting for constant index length
			sFileName = sFilePrefix+Combi_PadIndex(iIndex+1,vIndexDigits)+sFileSufix+".ras"
		//load numeric wave from sfileName into sWaveName, from pLoadPath
		LoadWave/G/M/O/D/N=$sWaveName/p=pLoadPath/K=1/Q/L={0,1,0,0,0} sfileName
		//renames the wave to get rid of the automatic 0 that igor puts at the end of the wave
		rename $"root:SmartlabScansFolder:"+sWaveName+"0",$sWaveName
	endfor
	//reset the data folder to root
	setdataFolder root:
	
	////this function call uses the canned sorting function to organize this data into the correct Combi structure////
	//uses the user-defined vFirstSample and the vNumberOfFiles to take care of any potential offset
	//all 1 and 2 values subtracted from vFirstSample, vFirstFile etc are there to correct off-by-one errors (indexing from 0 instead of 1)
	variable vFirstSample = 1
	string sNull //There is third, unused column in .ras files. Ignore it
	Combi_SortNewVectors(sProject, "root:SmartlabScansFolder:","Smartlab_","",vIndexDigits,sNewLibrary,sDegree+";"+sIntensity+";sNull",num2str(vFirstSample-1),num2str(vFirstSample+vNumberOfFiles-2),num2str(vFirstFileNum-1),num2str(vLastFileNum-1),0)
	Print "Rigaku_Smartlab_LoadFolder(\""+sProject+"\",\""+sIntensity+"\",\""+sDegree+"\")"

	//kill path and empty scans folder
	Killpath/A
	KillDataFolder/Z root:SmartlabScansFolder	
	
	////this section sets the scale for the vector data so that you can make a Gizmo////
	//get data path to Intensity and set scale in column dim
	wave wIntensity = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sIntensity
	wave wDegree = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sDegree
	SetScale/I x,wDegree[0],wDegree[(dimsize(wIntensity,0)-1)],wIntensity

	////this section adds important info to data log////
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File Folder: "+sThisLoadFolder
	sLogEntry2 = "Library Samples: "+num2str(vFirstSample)+" to "+num2str(vFirstSample+vNumberOfFiles-1)
	sLogEntry3 = "From File Indexes: "+num2str(vFirstFileNum-1)+" to "+num2str(vLastFileNum-1)
	sLogEntry4 = "Data Types: "+sDegree+","+sIntensity
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sNewLibrary,"Rigaku_Smartlab",1,sLogText)			
	
end


////this function loads a single  *.ras file into the root folder
function/S Rigaku_Smartlab_LoadFile()
	
	// get import path global
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	
	// if there's an import folder, use it
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		//load from the input file to RigakuFileIn
		LoadWave /P=pUserPath /A=SmartlabFileIn /J
	// if there isn't an import folder, get a folder
	else
		LoadWave /A=SmartlabFileIn /J
	endif
end

////this function will be executed when the user selects to load data button in the Instrument definition panel
function Rigaku_Smartlab_Load()

	//initializes the instrument
	Combi_InstrumentReady("Rigaku_Smartlab")
	//get Instrument name and project name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//prompts for project, load type (ie individual file or folder), and wavelength
	string sLoadType
	variable vWavelength = 1.5406
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sLoadType, "Load Type:", popup, "Folder;File"
	prompt vWavelength, "Radiation Wavelength (Angstroms):"
	DoPrompt/HELP="This tells me how you want to load data." "Loading Input", sLoadType, vWavelength
	if (V_Flag)
		return -1
	endif
	
	//sets the user-defined prompts as globals for the instrument
	Combi_GiveInstrumentGlobal("Rigaku_Smartlab","vWavelength",num2str(vWavelength),sProject)
	//if the user is loading an entire folder, call the LoadFolder function
	if(stringmatch(sLoadType,"Folder"))
		// get globals
		string sDegree = Combi_GetInstrumentString("Rigaku_Smartlab","sDegree",sProject)
		string sIntensity = Combi_GetInstrumentString("Rigaku_Smartlab","sIntensity",sProject)	

		//if the user has the command line setting on, print the call line so the user can use it programmatically
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "Rigaku_Smartlab_LoadFolder(\""+sProject+"\",\""+sIntensity+"\",\""+sDegree+"\",\")"
		endif
		//call the LoadFolder function
		Rigaku_Smartlab_LoadFolder(sProject,sIntensity,sDegree)
	//if the user is just loading a single file, call the LoadFile function
	elseif(stringmatch(sLoadType,"File"))
		Rigaku_Smartlab_LoadFile()
	endif
	
end

function LogOffset()

variable vOffset
variable vMultiplier = vOffset
	prompt vMultiplier, "Log offset value:"

	string sThisHelp
	sThisHelp = "Log offset - should be multiple of 10"


DoPrompt/HELP=sThisHelp "Log Offset", vMultiplier
	if (V_Flag)
		return -1// User canceled
	endif

DoLogOffsets(vMultiplier)
end
	
	//This part written by Sage
function DoLogOffsets(vMultiplier)
        variable vMultiplier
        variable iIter
        string sTraceList = TraceNameList("",";",1), sThisTrace

        for(iIter=0; iIter<ItemsInList(sTraceList); iIter++)
               sThisTrace = StringFromList(iIter,sTraceList)
               ModifyGraph muloffset($sThisTrace)={0,vMultiplier^iIter}
        endfor
end
