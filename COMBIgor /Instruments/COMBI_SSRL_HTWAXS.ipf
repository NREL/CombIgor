#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//to use this, you must first link Igor to MatLab dynamic libraries. This is done by 
//1 Have Matlab Libraries on your computer (usually from having MatLab on you computer)
//2 Data>LoadWaves>Loat Matlab MAT files....
//3 clicking button on bottom to find Matlab libraries
//4 navgating to folder of saved libraries, igor saves this location for future use.

Menu "COMBIgor"
	SubMenu "Instruments"
		 SubMenu "HT WAXS @ SSRL"
	 		"Load 1D Integrations (*.csv) as vector data",/Q, SSRL_HTWAXS_Load1D()
	 		"Load Detectors (*.mat) as matrix data",/Q,SSRL_HTWAXS_LoadRaw()
	 		"-"
	 		"(Plotting"
	 		"Plot Detector",/Q,SSRL_HTWAXS_Detector()
	 		"-"
	 		"(Integrations"
	 		"Integrate Chi from A&B Cursors", SSRL_HTWAXS_ChiIntFromCursorAB()
	 		"Integrate Q from A&B Cursors", SSRL_HTWAXS_QIntFromCursorAB()
	 		"-"
	 		"(Averages"
	 		"Average Chi from A&B Cursors", SSRL_HTWAXS_ChiAveFromCursorAB()
	 		"Average Q from A&B Cursors", SSRL_HTWAXS_QAveFromCursorAB()
		 end
	end
end


///////////Celeste's functions//////////////////////

//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
function SSRL_HTWAXS_Load1D()
	COMBI_GiveGlobal("sInstrumentName","SSRL_HTWAXS","COMBIgor")
	COMBI_InstrumentDefinition()
	//DisplayProcedure/W=$"COMBI_SSRL_HTWAXS.ipf"/L=0
end


//returns a list of descriptors for each of the globals used to define file loading. There can be as many Instrument globals as needed, please specify a new "case" in the strswitch for each.
Function/S SSRL_HTWAXS_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for
	
	//this instrument's name
	string sInstrument = "SSRL_HTWAXS"
	
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
		case "SSRL_HTWAXS":
			sReturnstring = "SSRL_HTWAXS"
			break
		//these are the specific variables that are collected by the Define process
		case "sIntensity":
			sReturnstring =  "Intensity:"
			break
		case "sQ":
			sReturnstring =  "X axis in Q:"
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
function SSRL_HTWAXS_Define()

	//get Instrument name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	string sIntensity
	string sQ
	
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		sIntensity = COMBI_GetInstrumentString(sThisInstrumentName,"sIntensity",sProject)
		sQ = COMBI_GetInstrumentString(sThisInstrumentName,"sQ",sProject)

	else 
		//not previously defined, start with default values 
		sIntensity = "SSRL_Intensity" 
		sQ = "SSRL_Q"
		//set the global
		Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)
	endif
	
		
	//get names for data types
	//cleanupname makes sure the data type name is allowed
	sIntensity = cleanupname(COMBI_DataTypePrompt(sProject,sIntensity,SSRL_HTWAXS_Descriptions("sIntensity"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sIntensity,"CANCEL"))
		return -1
	endif
	//cleanupname makes sure the data type name is allowed
	sQ = cleanupname(COMBI_DataTypePrompt(sProject,sQ,SSRL_HTWAXS_Descriptions("sQ"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sQ,"CANCEL"))
		return -1
	endif
	
	//mark as defined by storing instrument globals in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sIntensity",sIntensity,sProject)// store Instrument global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sQ",sQ,sProject)// store Instrument global 
	//mark as defined by storing the instrument name in the main globals
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,"COMBIgor")

	//reload definition panel
	COMBI_InstrumentDefinition()
	
end







//this function loads a folder of integrated *.csv files 	
//inputs: 
	//sProject: the project we are operating in
	//sIntensity: the destination intensity wave
	//sQ: the destination x-axis wave
function SSRL_HTWAXS_LoadFolder(sProject,sIntensity,sQ)
	//define strings and variables	
	string sProject, sIntensity, sQ
	variable vIndex
	string sThisInstrumentName = "SSRL_HTWAXS"
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root: 
	
	// get global wavelength
	variable vWavelength = Combi_GetInstrumentNumber(sThisInstrumentName,"vWavelength",sProject)

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
	//stores some path info in v_flag and s_path variables ******why??
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log


	/////this section makes sure the number of files is 44, or sets an offset if not/////
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
		DoAlert/T="Mismatched number of samples!",0,"There must be one file in this folder per sample on the mapping grid. COMBIgor has found "+num2str(vNumberOfFiles)+" files but "+num2str(vTotalSamples)+" samples in the mapping grid for this project."
		if(vTotalSamples>vNumberOfFiles)
			DoAlert/T="Is this a subset of samples?",1,"Are you trying to load a partial measurement?"
			if(V_flag==1)
				vFirstSample = COMBI_NumberPrompt(vFirstSample,"What was the first sample number measured?","This will shift File #1 to this file number and proceed with loading","Define sampling offset")
			else
				SetDataFolder $sTheCurrentUserFolder 
				return -1
			endif
		else
			SetDataFolder $sTheCurrentUserFolder 
			return -1
		endif
	endif
	
	
	//////this section handles file name parsing//////		
	//grabs first section of first file name (0th file)
	string sFirstFile = removeending(IndexedFile(pLoadPath,0,".csv"),".csv")	
	//splits it into two ascii chunks (sPrefixPart and sSuffixPart)
	////this will not work if the 0th file doesn't have 0001 in it
	String expr="([[:ascii:]]*)0001([[:ascii:]]*)"
	string sPrefixPart, sSuffixPart
	SplitString/E=(expr) sFirstFile, sPrefixPart, sSuffixPart
	
	
	///////this section gets user input for the file prefix and suffix, total number of files, and library name//////
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
	DoPrompt/HELP=sThisHelp "SSRL Integrated Files", sDataFileNamePrefix, sDataFileNameSuffix, vFirstFileNum, vLastFileNum
	if (V_Flag)
		SetDataFolder $sTheCurrentUserFolder 
		return -1//user cancelled
	endif
	//prompt for the library name
	string sNewLibrary = COMBI_LibraryPrompt(sProject,"New","Name of Library",0,1,0,2)
	if(stringmatch(sNewLibrary,"CANCEL"))
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	
	//////this section loads all of the data into SSRLScansFolder//////
	//make a new folder to put the loaded files and set it as root
	setdatafolder root: 
	NewDataFolder/O/S SSRLScansFolder
	//initialize loop index
	int iSample
	//loop from firstFileNum-1 to lastFileNum-1
	for(iSample=(vFirstFileNum-1);iSample<(vLastFileNum);iSample+=1)
		string sWaveName, sFileName
		//set the destination wave name as "SSRLXRD_scanNum", correcting for a constant index length (so you have SSRLXRD_01 instead of SSRLXRD_1)
		sWaveName = "SSRLXRD_"+COMBI_PadIndex((iSample+1),2)
		//sets the source file name based on previous user inputs, correcting for constant index length
		sfileName = sDataFileNamePrefix+COMBI_PadIndex((iSample+1),4)+sDataFileNameSuffix+".csv"
		//load numeric wave from sfileName into sWaveName, from pLoadPath
		LoadWave/J/M/O/D/N=$sWaveName/p=pLoadPath/K=1/Q/L={0,1,0,0,0} sfileName
		//renames the wave to get rid of the automatic 0 that igor puts at the end of the wave
		rename $"root:SSRLScansFolder:"+sWaveName+"0",$sWaveName
	endfor
	
	
	////this function call uses the canned sorting function to organize this data into the correct Combi structure////
	//uses the user-defined vFirstSample and the vNumberOfFiles to take care of any potential offset
	//all 1 and 2 values subtracted from vFirstSample, vFirstFile etc are there to correct off-by-one errors (indexing from 0 instead of 1)
	Combi_SortNewVectors(sProject, "root:SSRLScansFolder:","SSRLXRD_","",2,sNewLibrary,sQ+";"+sIntensity,num2str(vFirstSample-1),num2str(vFirstSample+vNumberOfFiles-2),num2str(vFirstFileNum-1),num2str(vLastFileNum-1),0)

	//kill path and empty scans folder
	Killpath/A
	KillDataFolder/Z root:SSRLScansFolder	
	
	////this section sets the scale for the vector data so that you can make a Gizmo////
	//get data path to Intensity and set scale in column dim
	wave wIntensity = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sIntensity
	wave wQ = $Combi_DataPath(sProject,2)+sNewLibrary+":"+sQ
	SetScale/I x,wQ[0],wQ[(dimsize(wIntensity,0)-1)],wIntensity

	////this section adds important info to data log////
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File Folder: "+sThisLoadFolder
	sLogEntry2 = "Library Samples: "+num2str(vFirstSample)+" to "+num2str(vFirstSample+vNumberOfFiles-1)
	sLogEntry3 = "From File Indexes: "+num2str(vFirstFileNum-1)+" to "+num2str(vLastFileNum-1)
	sLogEntry4 = "Data Types: "+sQ+","+sIntensity
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sNewLibrary,"SSRL_HTWAXS",1,sLogText)			
	
	//reset the data folder to user
	SetDataFolder $sTheCurrentUserFolder 
end







////this function loads a single integrated *.csv file into the root folder
function/S SSRL_HTWAXS_LoadFile()
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdataFolder root: 
	// get import path global
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	
	// if there's an import folder, use it
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		//load from the input file to SSRLFileIn
		LoadWave /P=pUserPath /A=SSRLFileIn /J
	// if there isn't an import folder, get a folder
	else
		LoadWave /A=SSRLFileIn /J
	endif
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
end





////this function will be executed when the user selects to load data button in the Instrument definition panel
function SSRL_HTWAXS_Load()

	//initializes the instrument
	Combi_InstrumentReady("SSRL_HTWAXS")
	//get Instrument name and project name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//prompts for project, load type (ie individual file or folder), and wavelength
	string sLoadType
	variable vWavelength = 1.5406
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sLoadType, "Load Type:", popup, "Folder;File"
	prompt vWavelength, "Radiation Wavelength (Angstroms):"
	DoPrompt/HELP="This tells COMBIgor how to load data." "Loading Input", sLoadType, vWavelength
	if (V_Flag)
		return -1
	endif
	
	//sets the user-defined prompts as globals for the instrument
	Combi_GiveInstrumentGlobal("SSRL_HTWAXS","vWavelength",num2str(vWavelength),sProject)
	//if the user is loading an entire folder, call the LoadFolder function
	if(stringmatch(sLoadType,"Folder"))
		// get globals
		string sQ = Combi_GetInstrumentString("SSRL_HTWAXS","sQ",sProject)
		string sIntensity = Combi_GetInstrumentString("SSRL_HTWAXS","sIntensity",sProject)		
		//if the user has the command line setting on, print the call line so the user can use it programmatically
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "SSRL_HTWAXS_LoadFolder(\""+sProject+"\",\""+sIntensity+"\",\""+sQ+"\")"
		endif
		//call the LoadFolder function
		SSRL_HTWAXS_LoadFolder(sProject,sIntensity,sQ)
	//if the user is just loading a single file, call the LoadFile function
	elseif(stringmatch(sLoadType,"File"))
		SSRL_HTWAXS_LoadFile()
	endif
	
end



////this function loads a folder of non-integrated *.mat files from SSRL
function SSRL_HTWAXS_LoadRaw()
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root:
	
	//choose project
	string sProject = COMBI_ChooseProject()
	if(stringmatch(sProject,""))
		return -1
	endif
	//prompt the user for a library
	string sLibrary = COMBI_LibraryPrompt(sProject,"New","Library",0,1,0,-1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	
	//grab a path for the *.mat data
	NewPath/Q/O/Z pMatFileFolder
	string sAllFiles = IndexedFile(pMatFileFolder, -1,".mat")
	int vTotalMATFiles = itemsinlist(sAllFiles)
	
	//checks for the wrong number of files in the folder
	if(COMBI_GetGlobalNumber("vTotalSamples",sProject)!=vTotalMATFiles)
		DoAlert/T="Unexpected Numbers",0,"COMBIgor expect the same number of .mat files as samples on the library."
		return -1
	endif
	
	int vTotalRows = 1000
	int vTotalColumns = 1000
	
	//this draws the import progress bar on the screen so you don't think your computer froze
	int iSample
	PauseUpdate
	string sIgorEnviromentInfo = IgorInfo(0)
	string sScreenInfo = StringByKey("SCREEN1", sIgorEnviromentInfo)
	int vWinLeft = str2num(stringfromlist(3,sScreenInfo,","))/2-100
	int vWinTop = str2num(stringfromlist(4,sScreenInfo,","))/2-30
	int vWinRight = str2num(stringfromlist(3,sScreenInfo,","))/2+100
	int vWinBottom = str2num(stringfromlist(4,sScreenInfo,","))/2+30
	NewPanel/N=ImportProgress/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as "Import Progress"
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14
	SetDrawEnv textxjust= 1,textyjust= 1
	SetDrawEnv save
	DrawText 100,20,"Importing Matrix Data"
	ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
	ValDisplay valdispProgress limits={0,vTotalMATFiles,0},barmisc={0,1},bodyWidth= 180
	Execute "ValDisplay valdispProgress value=_NUM:"+num2str(0)
	DoUpdate/W=ImportProgress
	
	//builds all the folders inside the Combi structure
	string sDataFolder = COMBI_IntoDataFolder(sProject,3)
	newdataFolder/S/O $sLibrary
	sDataFolder = sDataFolder+sLibrary
	newdataFolder/S/O SSRL_WAXS
	sDataFolder = sDataFolder+":SSRL_WAXS:"
	newdataFolder/O ForPlotting
	newdataFolder/O ImageWaves
	newdataFolder/O Scales
	SetDataFolder $sTheCurrentUserFolder 
	
	//this section handles the loading and moving of data
	variable vMax,vMin
	for(iSample=0;iSample<vTotalMATFiles;iSample+=1)
	
		//for storage
		setdataFolder $sDataFolder+"ImageWaves:"
			Make/O/D/N=(vTotalRows,vTotalColumns) $"DetectorCounts_"+num2str(iSample+1)
		setdataFolder $sDataFolder+"Scales:"
			Make/O/D/N=(vTotalRows) $"QScale_"+num2str(iSample+1)
			Make/O/D/N=(vTotalColumns) $"ChiScale_"+num2str(iSample+1)
		setdataFolder $sDataFolder+"ForPlotting:"
				Make/T/O/N=(1) $"QAxisTicks_"+num2str(iSample+1)
				Make/T/O/N=(1) $"ChiAxisTicks_"+num2str(iSample+1)
				Make/O/N=(1) $"QAxis_"+num2str(iSample+1)
				Make/O/N=(1) $"ChiAxis_"+num2str(iSample+1)
				Make/O/N=(2) $"CountRange_"+num2str(iSample+1)
		SetDataFolder $sTheCurrentUserFolder 
		
		//get waves 
		wave wSSRLDataIn = $sDataFolder+"ImageWaves:"+"DetectorCounts_"+num2str(iSample+1)
		wave wQScale = $sDataFolder+"Scales:"+"QScale_"+num2str(iSample+1)
		wave wChiScale = $sDataFolder+"Scales:"+"ChiScale_"+num2str(iSample+1)
		wave/T wQAxisTicks = $sDataFolder+"ForPlotting:"+"QAxisTicks_"+num2str(iSample+1)
		wave/T wChiAxisTicks = $sDataFolder+"ForPlotting:"+"ChiAxisTicks_"+num2str(iSample+1)
		wave wQAxis = $sDataFolder+"ForPlotting:"+"QAxis_"+num2str(iSample+1)
		wave wChiAxis = $sDataFolder+"ForPlotting:"+"ChiAxis_"+num2str(iSample+1)
		wave wCountRange = $sDataFolder+"ForPlotting:"+"CountRange_"+num2str(iSample+1)
			
		//data moving
		vMax = -inf
		vMin = inf
		string sThisFile = stringfromList(iSample,sAllFiles)
		MLLoadWave/E/Q/O/M=2/Y=4/S=1/P=pMatFileFolder sThisFile
		wave wMatrix = root:cake
		wave wChi = root:chi
		wave wQ = root:Q0
		
		int iRow,iCol
		for(iRow=0;iRow<vTotalRows;iRow+=1)
			for(iCol=0;iCol<vTotalColumns;iCol+=1)
				if(wMatrix[iRow][iCol]==0)
					wSSRLDataIn[iCol][iRow] = nan
				else
					wSSRLDataIn[iCol][iRow] = wMatrix[iRow][iCol]
					if(wMatrix[iRow][iCol]>vMax)
						vMax = wMatrix[iRow][iCol]
						wCountRange[1] = vMax
					endif
					if(wMatrix[iRow][iCol]<vMin)
						vMin = wMatrix[iRow][iCol]
						wCountRange[0] = vMin
					endif
				endif
			endfor
		endfor	
		
		wQScale[] = wQ[0][p]
		wChiScale[] = wChi[0][p]
		
		Killwaves wMatrix, wChi, wQ
	
		variable vQTick, vChiTick
		variable vQDelta = 0.5
		variable vChiDelta = 10
		variable vFirstQ = 0.5+wQScale[0] - mod(wQScale[0],vQDelta)
		variable vLastQ = wQScale[vTotalColumns-1] - mod(wQScale[vTotalColumns-1],vQDelta)
		variable vFirstChi = wChiScale[0]- mod(wChiScale[0],vChiDelta)
		variable vLastChi = wChiScale[vTotalRows-1]- mod(wChiScale[vTotalRows-1],vChiDelta)
		variable vChiStep = (wChiScale[vTotalRows-1] - wChiScale[0])/vTotalRows
		variable vQStep = (wQScale[vTotalColumns-1] - wQScale[0])/vTotalColumns
		variable vStartQ = wQScale[0]
		variable vEndChi = wChiScale[vTotalRows-1]
		variable vTotalQTicks = (vLastQ - vFirstQ)/vQDelta+1
		variable vTotalChiTicks = (vLastChi-vFirstChi)/vChiDelta+1
		
		//redim
		if(vTotalQTicks>dimsize(wQAxis,0))
			redimension/N=(vTotalQTicks) wQAxis
			redimension/N=(vTotalQTicks) wQAxisTicks
		endif
		if(vTotalChiTicks>dimsize(wChiAxis,0))
			redimension/N=(vTotalChiTicks) wChiAxis
			redimension/N=(vTotalChiTicks) wChiAxisTicks
		endif
		
		//populate
		int iQ=0, iChi=0
		for(vQTick=vFirstQ;vQTick<=vLastQ;vQTick+=vQDelta)
			wQAxis[iQ] = trunc((vQTick-vStartQ)/vQStep)
			wQAxisTicks[iQ] = num2str(vQTick)
			iQ+=1
		endfor
		for(vChiTick=vLastChi;vChiTick>=vFirstChi;vChiTick-=vChiDelta)
			wChiAxis[iChi] = trunc((vEndChi-vChiTick)/vChiStep)
			wChiAxisTicks[iChi] = num2str(vChiTick)
			iChi+=1
		endfor
		Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSample)
		DoUpdate/W=ImportProgress
	endfor
	Killwindow ImportProgress
	ResumeUpdate
	
	//queries the user if you want to make all of the plots
	DoAlert/T="Make Plots?",1,"Would you like to make plots of each loaded frame while you're at it?"
	if(V_flag==1)
		for(iSample=0;iSample<vTotalMATFiles;iSample+=1)
			SSRL_HTWAXS_PlotDetector("BlueHot",sProject,sLibrary,iSample)
		endfor
	endif
	
	
	string sChiIntFolderPath,sQIntFolderPath,sIntPrefix,sIntSuffix
	variable vQStart
	
	//does the user want to integrate in chi?
	DoAlert/T="Frame Chi Integration?",1,"Would you like to make vector data from a Chi integration of the frame?"
	if(V_flag==1)
		
		//builds a progress bar
		PauseUpdate
		NewPanel/N=IntProgress/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as "Integration Progress"
		SetDrawLayer UserBack
		SetDrawEnv fsize= 14
		SetDrawEnv textxjust= 1,textyjust= 1
		SetDrawEnv save
		DrawText 100,20,"Integrating Frame"
		ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
		ValDisplay valdispProgress limits={0,vTotalMATFiles,0},barmisc={0,1},bodyWidth= 180
		Execute "ValDisplay valdispProgress value=_NUM:"+num2str(0)
		DoUpdate/W=IntProgress
		
		sChiIntFolderPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":SSRL_WAXS:Integrations:Chi:"
		sIntPrefix = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"
		sIntSuffix = "_0"
		for(iSample=0;iSample<vTotalMATFiles;iSample+=1)
			SSRL_HTWAXS_ChiInt(sProject,sLibrary,num2str(iSample+1),0,0,999,999)
			killwindow $Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
			Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSample+1)
			DoUpdate/W=IntProgress
		endfor
		wave wThisFirstOne = $sChiIntFolderPath+sIntPrefix+num2str(1)+sIntSuffix
		vQStart = dimOffset(wThisFirstOne,0)
		vQdelta = dimdelta(wThisFirstOne,0)
		COMBI_SortNewVectors(sProject,sChiIntFolderPath,sIntPrefix,sIntSuffix,0,sLibrary,"SSRL_ChiIntegratedCounts",num2str(0),num2str(vTotalMATFiles-1),num2str(0),num2str(vTotalMATFiles-1),1)
		wave wNewData = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_ChiIntegratedCounts"
		Combi_AddDataType(sProject,sLibrary,"SSRL_Q",2,iVDim=1000)
		wave wNewDataQ = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_Q"
		wNewDataQ[][] = vQStart+q*vQdelta
		setscale/P y,vQStart,vQdelta,wNewData
		Killwindow IntProgress
		ResumeUpdate
	endif
	
	//does the user want to integrate in Q?
	DoAlert/T="Frame Q Integration?",1,"Would you like to make vector data from a Q integration of the frame?"
	if(V_flag==1)
	
		PauseUpdate
		NewPanel/N=IntProgress/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as "Integration Progress"
		SetDrawLayer UserBack
		SetDrawEnv fsize= 14
		SetDrawEnv textxjust= 1,textyjust= 1
		SetDrawEnv save
		DrawText 100,20,"Integrating Frame"
		ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
		ValDisplay valdispProgress limits={0,vTotalMATFiles,0},barmisc={0,1},bodyWidth= 180
		Execute "ValDisplay valdispProgress value=_NUM:"+num2str(0)
		DoUpdate/W=IntProgress
		
		sQIntFolderPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":SSRL_WAXS:Integrations:Q:"
		sIntPrefix = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"
		sIntSuffix = "_0"
		for(iSample=0;iSample<vTotalMATFiles;iSample+=1)
			SSRL_HTWAXS_QInt(sProject,sLibrary,num2str(iSample+1),0,0,999,999)
			killwindow $Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
			Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSample+1)
			DoUpdate/W=IntProgress
			
		endfor
		wave wThisFirstOne = $sQIntFolderPath+sIntPrefix+num2str(1)+sIntSuffix
		vQStart = dimOffset(wThisFirstOne,0)
		vQdelta = dimdelta(wThisFirstOne,0)
		COMBI_SortNewVectors(sProject,sQIntFolderPath,sIntPrefix,sIntSuffix,0,sLibrary,"SSRL_QIntegratedCounts",num2str(0),num2str(vTotalMATFiles-1),num2str(0),num2str(vTotalMATFiles-1),1)
		wave wNewData = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_QIntegratedCounts"
		Combi_AddDataType(sProject,sLibrary,"SSRL_Chi",2,iVDim=1000)
		wave wNewDataQ = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_Chi"
		wNewDataQ[][] = vQStart+q*vQdelta
		setscale/P y,vQStart,vQdelta,wNewData
		Killwindow IntProgress
		ResumeUpdate
	endif
	
	//Chi ave each?
	DoAlert/T="Frame Chi average?",1,"Would you like to make vector data from a Chi average of the frame?"
	if(V_flag==1)
		
		PauseUpdate
		NewPanel/N=IntProgress/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as "Averaging Progress"
		SetDrawLayer UserBack
		SetDrawEnv fsize= 14
		SetDrawEnv textxjust= 1,textyjust= 1
		SetDrawEnv save
		DrawText 100,20,"Averaging Frames"
		ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
		ValDisplay valdispProgress limits={0,vTotalMATFiles,0},barmisc={0,1},bodyWidth= 180
		Execute "ValDisplay valdispProgress value=_NUM:"+num2str(0)
		DoUpdate/W=IntProgress
		
		sChiIntFolderPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":SSRL_WAXS:Averages:Chi:"
		sIntPrefix = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"
		sIntSuffix = "_0"
		for(iSample=0;iSample<vTotalMATFiles;iSample+=1)
			SSRL_HTWAXS_ChiAve(sProject,sLibrary,num2str(iSample+1),0,0,999,999)
			killwindow $Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
			Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSample+1)
			DoUpdate/W=IntProgress
		endfor
		wave wThisFirstOne = $sChiIntFolderPath+sIntPrefix+num2str(1)+sIntSuffix
		vQStart = dimOffset(wThisFirstOne,0)
		vQdelta = dimdelta(wThisFirstOne,0)
		COMBI_SortNewVectors(sProject,sChiIntFolderPath,sIntPrefix,sIntSuffix,0,sLibrary,"SSRL_ChiAveragedCounts",num2str(0),num2str(vTotalMATFiles-1),num2str(0),num2str(vTotalMATFiles-1),1)
		wave wNewData = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_ChiAveragedCounts"
		Combi_AddDataType(sProject,sLibrary,"SSRL_Q",2,iVDim=1000)
		wave wNewDataQ = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_Q"
		wNewDataQ[][] = vQStart+q*vQdelta
		setscale/P y,vQStart,vQdelta,wNewData
		Killwindow IntProgress
		ResumeUpdate
	endif
	
	//Q ave each?
	DoAlert/T="Frame Q average?",1,"Would you like to make vector data from a Q average of the frame?"
	if(V_flag==1)
	
		PauseUpdate
		NewPanel/N=IntProgress/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as "Averaging Progress"
		SetDrawLayer UserBack
		SetDrawEnv fsize= 14
		SetDrawEnv textxjust= 1,textyjust= 1
		SetDrawEnv save
		DrawText 100,20,"Averaging Frames"
		ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
		ValDisplay valdispProgress limits={0,vTotalMATFiles,0},barmisc={0,1},bodyWidth= 180
		Execute "ValDisplay valdispProgress value=_NUM:"+num2str(0)
		DoUpdate/W=IntProgress
		
		sQIntFolderPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":SSRL_WAXS:Averages:Q:"
		sIntPrefix = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"
		sIntSuffix = "_0"
		for(iSample=0;iSample<vTotalMATFiles;iSample+=1)
			SSRL_HTWAXS_QAve(sProject,sLibrary,num2str(iSample+1),0,0,999,999)
			killwindow $Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
			Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSample+1)
			DoUpdate/W=IntProgress
			
		endfor
		wave wThisFirstOne = $sQIntFolderPath+sIntPrefix+num2str(1)+sIntSuffix
		vQStart = dimOffset(wThisFirstOne,0)
		vQdelta = dimdelta(wThisFirstOne,0)
		COMBI_SortNewVectors(sProject,sQIntFolderPath,sIntPrefix,sIntSuffix,0,sLibrary,"SSRL_QAveragedCounts",num2str(0),num2str(vTotalMATFiles-1),num2str(0),num2str(vTotalMATFiles-1),1)
		wave wNewData = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_QAveragedCounts"
		Combi_AddDataType(sProject,sLibrary,"SSRL_Chi",2,iVDim=1000)
		wave wNewDataQ = $COMBI_DataPath(sProject,2)+sLibrary+":SSRL_Chi"
		wNewDataQ[][] = vQStart+q*vQdelta
		setscale/P y,vQStart,vQdelta,wNewData
		Killwindow IntProgress
		ResumeUpdate
	endif
	
	Killpath pMatFileFolder
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
end


//this function plots a single pre-loaded detector image from SSRL
//need to have run LoadRaw already for this to work
function SSRL_HTWAXS_Detector()
	
	string sProject = COMBI_ChooseProject()
	if(stringmatch("",sProject))
		return-1
	endif
	
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library",0,0,0,3)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	
	variable iSample = COMBI_NumberPrompt(1,"Sample of interest:","I will plot the detector for this sample","Which Sample?")
	if(numtype(iSample)!=0)
		return -1
	endif
	if(iSample<0||iSample>(COMBI_GetGlobalNumber("vTotalSamples",sProject)-1))
		return -1
	endif
	
	string sColorTheme = COMBI_StringPrompt(COMBI_GetGlobalString("sColorOption",sProject),"Color Theme:",ctabList(),"","Choose Colors")
	if(stringmatch(sColorTheme,"CANCEL"))
		return -1
	endif
	
	//if you've selected command lines, print the command
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		print "SSRL_HTWAXS_PlotDetector(\""+sColorTheme+"\",\""+sProject+"\",\""+sLibrary+"\","+num2str(iSample)+")"
	endif
	
	//calls the PlotDetector function to actually do the plotting
	SSRL_HTWAXS_PlotDetector(sColorTheme,sProject,sLibrary,iSample)

end

//plot detector
function SSRL_HTWAXS_PlotDetector(sColorTheme,sProject,sLibrary,iSample)
	string sProject,sLibrary,sColorTheme
	int iSample
	string sDataFolder = COMBI_DataPath(sProject,3)+sLibrary+":"
	
	PauseUpdate
	wave wSSRLDataIn = $sDataFolder+"SSRL_WAXS:ImageWaves:"+"DetectorCounts_"+num2str(iSample+1)
	wave/T wQAxisTicks = $sDataFolder+"SSRL_WAXS:ForPlotting:"+"QAxisTicks_"+num2str(iSample+1)
	wave/T wChiAxisTicks = $sDataFolder+"SSRL_WAXS:ForPlotting:"+"ChiAxisTicks_"+num2str(iSample+1)
	wave wQAxis = $sDataFolder+"SSRL_WAXS:ForPlotting:"+"QAxis_"+num2str(iSample+1)
	wave wChiAxis = $sDataFolder+"SSRL_WAXS:ForPlotting:"+"ChiAxis_"+num2str(iSample+1)
	wave wCountRange = $sDataFolder+"SSRL_WAXS:ForPlotting:"+"CountRange_"+num2str(iSample+1)
	
	wavestats/Q wSSRLDataIn
	
	string sName = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+num2str(iSample+1)
	string sTitle = "Project:"+sProject+",  Library:"+sLibrary+",  Sample:"+num2str(iSample+1)
	killwindow/Z $sName
	
	NewImage/F/S=2/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sName wSSRLDataIn
	ModifyGraph/W=$sName width=500,height=500
	ModifyImage/W=$sName ''#0 ctab={V_avg,wCountRange[1],$sColorTheme,0}, minRGB=V_avg, Log=1
	ModifyGraph/W=$sName margin(left)=40,margin(bottom)=40,margin(right)=10,margin(top)=10
	ModifyGraph/W=$sName userticks(left)={wChiAxis,wChiAxisTicks},userticks(bottom)={wQAxis,wQAxisTicks}
	ModifyGraph/W=$sName gFont="Times",  fSize=12,standoff=1
	Label left "\\Z12\\F'Times' Chi (degree)"
	Label bottom "\\Z12\\F'Times'Q (2π/Å\\S-1\\M)"
	ModifyGraph/W=$sName lblMargin=5
	TextBox/W=$sName/C/N=SampleTag/F=0 "\\K(65535,0,0)\\f02 Library: "+sLibrary+",  Sample: "+num2str(1+iSample)
	DoWindow/T $sName,sTitle
	ResumeUpdate

end

//doing integrations of Chi
function SSRL_HTWAXS_ChiIntFromCursorAB()

	//name of top image 
	string sImageName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	
	//cursor values 
	int vACursorQIndex=min(pcsr(A),pcsr(B))
	int vACursorChiIndex=min(qcsr(A),qcsr(B))
	int vBCursorQIndex=max(pcsr(B),pcsr(A))
	int vBCursorChiIndex=max(qcsr(B),qcsr(A))
	
	//slpit image name
	String expr="Project_([[:ascii:]]*)_Library_([[:ascii:]]*)_Sample_([[:ascii:]]*)"
	string sProject, sLibrary, sSample
	SplitString/E=(expr) sImageName, sProject, sLibrary, sSample
	
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		print "SSRL_HTWAXS_ChiInt(\""+sProject+"\",\""+sLibrary+"\",\""+sSample+"\","+num2str(vACursorQIndex)+","+num2str(vACursorChiIndex)+","+num2str(vBCursorQIndex)+","+num2str(vBCursorChiIndex)+")"
	endif
	
	SSRL_HTWAXS_ChiInt(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)

end

//programmatic chi integrations
function SSRL_HTWAXS_ChiInt(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)
	string sProject,sLibrary,sSample
	int vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	int iSample = str2num(sSample)-1
	
	string sDataFolder = COMBI_DataPath(sProject,3)+sLibrary+":"
	wave wSSRLDataIn = $sDataFolder+"SSRL_WAXS:ImageWaves:"+"DetectorCounts_"+sSample
	wave wQScale = $sDataFolder+"SSRL_WAXS:Scales:"+"QScale_"+sSample
	wave wChiScale = $sDataFolder+"SSRL_WAXS:Scales:"+"ChiScale_"+sSample
	
	int vQLength = abs(vACursorQIndex-vBCursorQIndex)
	int vChiLength = abs(vACursorChiIndex-vBCursorChiIndex)
	//A is start, B is end
	variable vQStart= wQScale[vACursorQIndex]
	variable vQEnd=wQScale[vBCursorQIndex]
	variable vChiStart=wChiScale[vACursorChiIndex]
	variable vChiEnd =wChiScale[vBCursorChiIndex]
	//wave to hold integtation	
	setdatafolder $sDataFolder
	setdatafolder SSRL_WAXS
	newdatafolder/O/S Integrations
	newdatafolder/O/S Chi
	string sAllDataWaves = ReplaceString(",", stringbyKey("WAVES",DataFolderDir(2)),";")
	int iWavesInFolder = itemsinlist(listmatch(sAllDataWaves,"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"*"))
	Make/O/N=(vQLength+1) $"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	SetDataFolder $sTheCurrentUserFolder 
	wave wChiIntegration = $sDataFolder+"SSRL_WAXS:Integrations:Chi:"+"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	Note wChiIntegration "Integration Notes:"
	Note wChiIntegration "Project: "+sProject
	Note wChiIntegration "Library: "+sLibrary
	Note wChiIntegration "Sample: "+sSample
	Note wChiIntegration "Q: ("+num2str(vQStart)+") to ("+num2str(vQEnd)+")"
	Note wChiIntegration "Chi: ("+num2str(vChiStart)+") to ("+num2str(vChiEnd)+")"
	SetScale/I X,vQStart,vQEnd,wChiIntegration
	
	//populate
	int iQ,iChi
	for(iQ=vACursorQIndex;iQ<=vBCursorQIndex;iQ+=1)
		int QInt = iQ-vACursorQIndex
		variable vTotalCounts = 0
		for(iChi=vACursorChiIndex;iChi<=vBCursorChiIndex;iChi+=1)
			if(numtype(wSSRLDataIn[iQ][iChi])==0)
				vTotalCounts+=wSSRLDataIn[iQ][iChi]
			endif
		endfor
		wChiIntegration[QInt]=vTotalCounts
	endfor
	
	//name of top image 
	string sAllImages = WinList("*", ";","WIN:1")//all plots
	string sImageName = Stringfromlist(0,sAllImages)//top most plot window
	string sThisImage = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample
	
	if(whichlistItem(sAllImages,sThisImage)>=0)
		setactivesubwindow $sThisImage
		//draw
		SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65535),dash= 3,fillpat= 0,linethick= 1.5, save
		DrawRect/W=$sThisImage vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	endif
	
	//display
	Display/K=1  wChiIntegration[]
	Label left "Counts"
	Label bottom "Q (Å\\S-1\\M)"
	ModifyGraph log(left)=1
	ModifyGraph mode=7,hbFill=5
	ModifyGraph tick(left)=2,tick(bottom)=3,mirror=2
end

//doing averages of Chi
function SSRL_HTWAXS_ChiAveFromCursorAB()

	//name of top image 
	string sImageName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	
	//cursor values 
	int vACursorQIndex=min(pcsr(A),pcsr(B))
	int vACursorChiIndex=min(qcsr(A),qcsr(B))
	int vBCursorQIndex=max(pcsr(B),pcsr(A))
	int vBCursorChiIndex=max(qcsr(B),qcsr(A))
	
	//slpit image name
	String expr="Project_([[:ascii:]]*)_Library_([[:ascii:]]*)_Sample_([[:ascii:]]*)"
	string sProject, sLibrary, sSample
	SplitString/E=(expr) sImageName, sProject, sLibrary, sSample
	
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		print "SSRL_HTWAXS_ChiInt(\""+sProject+"\",\""+sLibrary+"\",\""+sSample+"\","+num2str(vACursorQIndex)+","+num2str(vACursorChiIndex)+","+num2str(vBCursorQIndex)+","+num2str(vBCursorChiIndex)+")"
	endif
	
	SSRL_HTWAXS_ChiAve(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)

end

//programmatic averages of chi
function SSRL_HTWAXS_ChiAve(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)
	string sProject,sLibrary,sSample
	int vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	
	int iSample = str2num(sSample)-1
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	string sDataFolder = COMBI_DataPath(sProject,3)+sLibrary+":"
	wave wSSRLDataIn = $sDataFolder+"SSRL_WAXS:ImageWaves:"+"DetectorCounts_"+sSample
	wave wQScale = $sDataFolder+"SSRL_WAXS:Scales:"+"QScale_"+sSample
	wave wChiScale = $sDataFolder+"SSRL_WAXS:Scales:"+"ChiScale_"+sSample
	
	int vQLength = abs(vACursorQIndex-vBCursorQIndex)
	int vChiLength = abs(vACursorChiIndex-vBCursorChiIndex)
	//A is start, B is end
	variable vQStart= wQScale[vACursorQIndex]
	variable vQEnd=wQScale[vBCursorQIndex]
	variable vChiStart=wChiScale[vACursorChiIndex]
	variable vChiEnd =wChiScale[vBCursorChiIndex]
	//wave to hold integtation	
	setdatafolder $sDataFolder
	setdatafolder SSRL_WAXS
	newdatafolder/O/S Averages
	newdatafolder/O/S Chi
	string sAllDataWaves = ReplaceString(",", stringbyKey("WAVES",DataFolderDir(2)),";")
	int iWavesInFolder = itemsinlist(listmatch(sAllDataWaves,"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"*"))
	Make/O/N=(vQLength+1) $"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	SetDataFolder $sTheCurrentUserFolder 
	wave wChiIntegration = $sDataFolder+"SSRL_WAXS:Averages:Chi:"+"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	Note wChiIntegration "Average Notes:"
	Note wChiIntegration "Project: "+sProject
	Note wChiIntegration "Library: "+sLibrary
	Note wChiIntegration "Sample: "+sSample
	Note wChiIntegration "Q: ("+num2str(vQStart)+") to ("+num2str(vQEnd)+")"
	Note wChiIntegration "Chi: ("+num2str(vChiStart)+") to ("+num2str(vChiEnd)+")"
	SetScale/I X,vQStart,vQEnd,wChiIntegration
	
	//populate
	int iQ,iChi
	for(iQ=vACursorQIndex;iQ<=vBCursorQIndex;iQ+=1)
		int QInt = iQ-vACursorQIndex
		variable vTotalCounts = 0
		variable vTotalAdds = 0
		for(iChi=vACursorChiIndex;iChi<=vBCursorChiIndex;iChi+=1)
			if(numtype(wSSRLDataIn[iQ][iChi])==0)
				vTotalCounts+=wSSRLDataIn[iQ][iChi]
				vTotalAdds+=1
			endif
		endfor
		wChiIntegration[QInt]=vTotalCounts/vTotalAdds
	endfor
	
	//name of top image 
	string sAllImages = WinList("*", ";","WIN:1")//all plots
	string sImageName = Stringfromlist(0,sAllImages)//top most plot window
	string sThisImage = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample
	
	if(whichlistItem(sAllImages,sThisImage)>=0)
		setactivesubwindow $sThisImage
		//draw
		SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65535),dash= 3,fillpat= 0,linethick= 1.5, save
		DrawRect/W=$sThisImage vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	endif
	
	//display
	Display/K=1  wChiIntegration[]
	Label left "Counts"
	Label bottom "Q (Å\\S-1\\M)"
	ModifyGraph log(left)=1
	ModifyGraph mode=7,hbFill=5
	ModifyGraph tick(left)=2,tick(bottom)=3,mirror=2
end

//doing integrations of Q
function SSRL_HTWAXS_QIntFromCursorAB()

	//name of top image 
	string sImageName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	
	//cursor values 
	int vACursorQIndex=min(pcsr(A),pcsr(B))
	int vACursorChiIndex=min(qcsr(A),qcsr(B))
	int vBCursorQIndex=max(pcsr(B),pcsr(A))
	int vBCursorChiIndex=max(qcsr(B),qcsr(A))
	
	//slpit image name
	String expr="Project_([[:ascii:]]*)_Library_([[:ascii:]]*)_Sample_([[:ascii:]]*)"
	string sProject, sLibrary, sSample
	SplitString/E=(expr) sImageName, sProject, sLibrary, sSample
	
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		print "SSRL_HTWAXS_QInt(\""+sProject+"\",\""+sLibrary+"\",\""+sSample+"\","+num2str(vACursorQIndex)+","+num2str(vACursorChiIndex)+","+num2str(vBCursorQIndex)+","+num2str(vBCursorChiIndex)+")"
	endif
	
	SSRL_HTWAXS_QInt(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)

end

//doing averages of Q
function SSRL_HTWAXS_QAveFromCursorAB()

	//name of top image 
	string sImageName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	
	//cursor values 
	int vACursorQIndex=min(pcsr(A),pcsr(B))
	int vACursorChiIndex=min(qcsr(A),qcsr(B))
	int vBCursorQIndex=max(pcsr(B),pcsr(A))
	int vBCursorChiIndex=max(qcsr(B),qcsr(A))
	
	//slpit image name
	String expr="Project_([[:ascii:]]*)_Library_([[:ascii:]]*)_Sample_([[:ascii:]]*)"
	string sProject, sLibrary, sSample
	SplitString/E=(expr) sImageName, sProject, sLibrary, sSample
	
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		print "SSRL_HTWAXS_QInt(\""+sProject+"\",\""+sLibrary+"\",\""+sSample+"\","+num2str(vACursorQIndex)+","+num2str(vACursorChiIndex)+","+num2str(vBCursorQIndex)+","+num2str(vBCursorChiIndex)+")"
	endif
	
	SSRL_HTWAXS_QAve(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)

end

//programmatic integrations of Q
function SSRL_HTWAXS_QInt(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)
	string sProject,sLibrary,sSample
	int vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	
	int iSample = str2num(sSample)-1
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	string sDataFolder = COMBI_DataPath(sProject,3)+sLibrary+":"
	wave wSSRLDataIn = $sDataFolder+"SSRL_WAXS:ImageWaves:"+"DetectorCounts_"+sSample
	wave wQScale = $sDataFolder+"SSRL_WAXS:Scales:"+"QScale_"+sSample
	wave wChiScale = $sDataFolder+"SSRL_WAXS:Scales:"+"ChiScale_"+sSample
	
	int vQLength = abs(vACursorQIndex-vBCursorQIndex)
	int vChiLength = abs(vACursorChiIndex-vBCursorChiIndex)
	//A is start, B is end
	variable vQStart= wQScale[vACursorQIndex]
	variable vQEnd=wQScale[vBCursorQIndex]
	variable vChiStart=wChiScale[vACursorChiIndex]
	variable vChiEnd =wChiScale[vBCursorChiIndex]
	//wave to hold integtation	
	setdatafolder $sDataFolder
	setdatafolder SSRL_WAXS
	newdatafolder/O/S Integrations
	newdatafolder/O/S Q
	string sAllDataWaves = ReplaceString(",", stringbyKey("WAVES",DataFolderDir(2)),";")
	int iWavesInFolder = itemsinlist(listmatch(sAllDataWaves,"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"*"))
	Make/O/N=(vChiLength+1) $"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	SetDataFolder $sTheCurrentUserFolder 
	wave wQIntegration = $sDataFolder+"SSRL_WAXS:Integrations:Q:"+"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	Note wQIntegration "Integration Notes:"
	Note wQIntegration "Project: "+sProject
	Note wQIntegration "Library: "+sLibrary
	Note wQIntegration "Sample: "+sSample
	Note wQIntegration "Q: ("+num2str(vQStart)+") to ("+num2str(vQEnd)+")"
	Note wQIntegration "Chi: ("+num2str(vChiStart)+") to ("+num2str(vChiEnd)+")"
	SetScale/I X,vChiStart,vChiEnd,wQIntegration
	
	//populate
	int iQ,iChi
	for(iChi=vACursorChiIndex;iChi<=vBCursorChiIndex;iChi+=1)
		int QInt = iChi-vACursorChiIndex
		variable vTotalCounts = 0
		for(iQ=vACursorQIndex;iQ<=vBCursorQIndex;iQ+=1)
			if(numtype(wSSRLDataIn[iQ][iChi])==0)
				vTotalCounts+=wSSRLDataIn[iQ][iChi]
			endif
		endfor
		wQIntegration[QInt]=vTotalCounts
	endfor
	
	//name of top image 
	string sAllImages = WinList("*", ";","WIN:1")//all plots
	string sImageName = Stringfromlist(0,sAllImages)//top most plot window
	string sThisImage = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample
	
	if(whichlistItem(sAllImages,sThisImage)>=0)
		setactivesubwindow $sThisImage
		//draw
		SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65535),dash= 3,fillpat= 0,linethick= 1.5, save
		DrawRect/W=$sThisImage vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	endif
	
	//display
	Display/K=1  wQIntegration[]
	Label left "Counts"
	Label bottom "Chi (degree)"
	ModifyGraph log(left)=1
	ModifyGraph mode=7,hbFill=5
	ModifyGraph tick(left)=2,tick(bottom)=3,mirror=2
end


//programmatic averages of Q
function SSRL_HTWAXS_QAve(sProject,sLibrary,sSample,vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex)
	string sProject,sLibrary,sSample
	int vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	int iSample = str2num(sSample)-1
	
	string sDataFolder = COMBI_DataPath(sProject,3)+sLibrary+":"
	wave wSSRLDataIn = $sDataFolder+"SSRL_WAXS:ImageWaves:"+"DetectorCounts_"+sSample
	wave wQScale = $sDataFolder+"SSRL_WAXS:Scales:"+"QScale_"+sSample
	wave wChiScale = $sDataFolder+"SSRL_WAXS:Scales:"+"ChiScale_"+sSample
	
	int vQLength = abs(vACursorQIndex-vBCursorQIndex)
	int vChiLength = abs(vACursorChiIndex-vBCursorChiIndex)
	//A is start, B is end
	variable vQStart= wQScale[vACursorQIndex]
	variable vQEnd=wQScale[vBCursorQIndex]
	variable vChiStart=wChiScale[vACursorChiIndex]
	variable vChiEnd =wChiScale[vBCursorChiIndex]
	//wave to hold integtation	
	setdatafolder $sDataFolder
	setdatafolder SSRL_WAXS
	newdatafolder/O/S Averages
	newdatafolder/O/S Q
	string sAllDataWaves = ReplaceString(",", stringbyKey("WAVES",DataFolderDir(2)),";")
	int iWavesInFolder = itemsinlist(listmatch(sAllDataWaves,"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"*"))
	Make/O/N=(vChiLength+1) $"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	SetDataFolder $sTheCurrentUserFolder 
	wave wQIntegration = $sDataFolder+"SSRL_WAXS:Averages:Q:"+"Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample+"_"+num2str(iWavesInFolder)
	Note wQIntegration "Averaging Notes:"
	Note wQIntegration "Project: "+sProject
	Note wQIntegration "Library: "+sLibrary
	Note wQIntegration "Sample: "+sSample
	Note wQIntegration "Q: ("+num2str(vQStart)+") to ("+num2str(vQEnd)+")"
	Note wQIntegration "Chi: ("+num2str(vChiStart)+") to ("+num2str(vChiEnd)+")"
	SetScale/I X,vChiStart,vChiEnd,wQIntegration
	
	//populate
	int iQ,iChi
	for(iChi=vACursorChiIndex;iChi<=vBCursorChiIndex;iChi+=1)
		int QInt = iChi-vACursorChiIndex
		variable vTotalCounts = 0
		variable vTotalAdds = 0
		for(iQ=vACursorQIndex;iQ<=vBCursorQIndex;iQ+=1)
			if(numtype(wSSRLDataIn[iQ][iChi])==0)
				vTotalCounts+=wSSRLDataIn[iQ][iChi]
				vTotalAdds+=1
			endif
		endfor
		wQIntegration[QInt]=vTotalCounts/vTotalAdds
	endfor
	
	//name of top image 
	string sAllImages = WinList("*", ";","WIN:1")//all plots
	string sImageName = Stringfromlist(0,sAllImages)//top most plot window
	string sThisImage = "Project_"+sProject+"_Library_"+sLibrary+"_Sample_"+sSample
	
	if(whichlistItem(sAllImages,sThisImage)>=0)
		setactivesubwindow $sThisImage
		//draw
		SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65535),dash= 3,fillpat= 0,linethick= 1.5, save
		DrawRect/W=$sThisImage vACursorQIndex,vACursorChiIndex,vBCursorQIndex,vBCursorChiIndex
	endif
	
	//display
	Display/K=1  wQIntegration[]
	Label left "Counts"
	Label bottom "Chi (degree)"
	ModifyGraph log(left)=1
	ModifyGraph mode=7,hbFill=5
	ModifyGraph tick(left)=2,tick(bottom)=3,mirror=2
end