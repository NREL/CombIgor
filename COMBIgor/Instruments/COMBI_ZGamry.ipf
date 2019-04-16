#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Meagan Papac _ Dec 2018 : 

//Description of procedure purpose:
//
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Builds the drop-down menu for this instrument
Menu "COMBIgor"
	SubMenu "Instruments"
		 SubMenu "ZGamry"
		 	"Make new project from coordinate file", ZGamry_NewProject()
		 	"Load fit file", ZGamry_LoadECMFitData()
		 	SubMenu "Process fit data"
		 		"Calculate Rp", ZGamry_CalculateRp()
		 		"Calculate Ea", ZGamry_CalculateEa() 
		 	end
		 	"Load new temperature calibration file", ZGamry_LoadTCal()
		 	"Load new coordinate file", ZGamry_LoadCoordinates()
		 	"Calibrate temperature", ZGamry_CalibrateTemp()
		 end
	end
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//DO I NEED THIS?
//Returns a list of descriptors for each of the globals used to define file loading. 
//There can be as many Instrument globals as needed, add a new "case" in the strswitch section for each.
Function/S ZGamry_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for
	
	//this instrument's name
	string sInstrument = "ZGamry"
	
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring =""
	//strswitch section builds the define panel for each instrument global
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "No"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	//puts value into 0th row and 0th column of globals wave for other functions to access
	twGlobals[0][0] = sReturnstring 
	return sReturnstring
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Creates a new project from a coordinate file selected by the user
//Contains the option to load a temperature calibration file
Function ZGamry_NewProject()
	//Load coordinate file; direct toward import path if import folder has been selected.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		doAlert/T="File opening", 0, "Select a .txt file for positions measured."
		if(!V_flag)
			return -1
		endif 
		LoadWave/J/Q/M/O/P=pUserPath/N=ZGamryCoordinates 
	else
		doAlert/T="File opening", 0, "Select a .txt file for positions measured."
		if(!V_flag)
			return -1
		endif 
		LoadWave/J/Q/M/O/N=ZGamryCoordinates 
	endif

	wave wZPositions = root:ZGamryCoordinates0
	//Get number of contacts from length of wave
	int vTotalContacts = dimSize(wZPositions, 0)	
	
	//Prompt for x,y offsets
	variable vXoffset = 5.4, vYoffset = 4.4
	prompt vXoffset, "x-coordinate of contact 1:" 
	prompt vYoffset, "y-coordinate of contact 1:"
	doPrompt/HELP="Set x,y offset from the library origin." "Define coordinates of contact 1" vXoffset, vYoffset 
	if (V_Flag)
		return -1
	endif
	
	//Make project
	// Defines Library space as the orthogonal grid
	string sProject = COMBI_StringPrompt("ZMap_"+num2str(vTotalContacts)+"contacts", "New project name", "", "", "Name new project")
	if(stringmatch(sProject,"Cancel"))
		return -1
	endif
	
	sProject = CleanupName(sProject, 0)
	
	SetDataFolder COMBIgor
	
	//Exit if wave exists, return -1
	if(DataFolderExists("root:COMBIgor:"+sProject))
		DoAlert/T="COMBIgor error." 0,"That project already exists."
		setdatafolder root:
		return -1
	endif
	
	//Make folder 
	NewDataFolder/O/S $sProject
	Make/N=(vTotalContacts,5)/O MappingGrid
	NewDataFolder/O/S Data
	
	//Make master 0D,1D, and 2D main waves
	Combi_NewMetaTable("Meta")
	Redimension/N=(-1,vTotalContacts,-1) $COMBI_DataPath(sProject,-1)
	Make/N=(1,1)/O Library
	SetDimLabel 0, -1, Samples, $COMBI_DataPath(sProject, 0)
	SetDimLabel 1, -1, DataType, $COMBI_DataPath(sProject, 0)
	Combi_NewDataLog("LogBook")
	
	//Return to the root folder to finish
	setdatafolder root:
	
	//Get library space wave
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	SetDimLabel 1, 0, Sample, wMappingGrid
	SetDimLabel 1, 1, x_mm, wMappingGrid
	SetDimLabel 1, 2, y_mm, wMappingGrid
	SetDimLabel 1, 3, Row, wMappingGrid
	SetDimLabel 1, 4, Column, wMappingGrid

	//Find number of rows/columns and row/column spacing
	variable vRows, vColumnSpacing, vColumns, vRowSpacing, i
	
	for(i = 0; i < dimSize(wZPositions, 0); i += 1)
		if((wZPositions[i][0] - wZPositions[0][0])!=0)
			vRowSpacing = Abs(wZPositions[i][0] - wZPositions[0][0])
			break 
		endif
	endfor
	
	for(i = 0; i < dimSize(wZPositions, 0); i += 1)
		if((wZPositions[i][1] - wZPositions[0][1])!=0)
			vColumnSpacing = Abs(wZPositions[i][1] - wZPositions[0][1])
			break 
		endif
	endfor
	
	//Guess number of rows and columns
	string sAllX = "", sAllY = ""
	for(i = 0; i < dimSize(wZPositions, 0); i += 1)
		if(whichListItem(num2str(wZPositions[i][0]), sAllX) == -1)
			sAllX += num2str(wZPositions[i][0]) + ";"
		endif
		if(whichListItem(num2str(wZPositions[i][1]), sAllY) == -1)
			sAllY += num2str(wZPositions[i][1]) + ";"
		endif
	endfor
	
	vRows = ItemsinList(sAllY)
	vColumns = ItemsinList(sAllX)
	
	//Set sub categories
	SetDimLabel 1, 3, Row, wMappingGrid
	SetDimLabel 1, 4, Column, wMappingGrid 
	
	//Prompt values
	variable vLibraryWidth = 50.8// width of Library in mm
	variable vLibraryHeight = 50.8// height of Library
	string sOrigin = "Top Left" // origin location
	
	//User prompts
	prompt vRows, "Number of Rows"
	prompt vColumns, "Number of Columns"
	prompt vLibraryWidth, "Library Width (mm)"
	prompt vLibraryHeight, "Library Height (mm)"
	prompt vRowSpacing, "Row Spacing (mm)"
	prompt vColumnSpacing, "Column Spacing (mm)"
	prompt sOrigin, "Origin", POPUP, "Top Left;Top Right;Bottom Left;Bottom Right;Center"
	
	//Prompt user
	DoPrompt "Define the Library space?",vLibraryWidth,vLibraryHeight,vRows,vColumns,vRowSpacing,vColumnSpacing,sOrigin
	if (V_Flag)
		return -1// User canceled
	endif
	
	//Store as globals
	COMBI_GiveGlobal("vTotalRows",num2str(vRows),sProject)
	COMBI_GiveGlobal("vTotalColumns",num2str(vColumns),sProject)
	COMBI_GiveGlobal("vLibraryWidth",num2str(vLibraryWidth),sProject)
	COMBI_GiveGlobal("vLibraryHeight",num2str(vLibraryHeight),sProject)
	COMBI_GiveGlobal("vRowSpacing",num2str(vRowSpacing),sProject)
	COMBI_GiveGlobal("vColumnSpacing",num2str(vColumnSpacing),sProject)
	COMBI_GiveGlobal("sOrigin",sOrigin,sProject)
	COMBI_GiveGlobal("vXOffset", num2str(vXoffset),sProject)
	COMBI_GiveGlobal("vYOffset", num2str(vYoffset),sProject)
	
	//Offset from origin
	variable vXMapOffset
	variable vYMapOffset
	variable bYAxisFlip, bXAxisFlip
	strswitch(sOrigin)
		case "Top Left":
			vXMapOffset = 0
			vYMapOffset = 0
			bYAxisFlip = 1
			bXAxisFlip = 0
			break
		case "Top Right":
			vXMapOffset = 0
			vYMapOffset = 0
			bYAxisFlip = 1
			bXAxisFlip	= 1
			break
		case "Bottom Left":
			vXMapOffset = 0
			vYMapOffset = 0
			bYAxisFlip = 0
			bXAxisFlip	= 0
			break
		case "Bottom Right":
			vXMapOffset = 0
			vYMapOffset = 0
			bYAxisFlip = 0
			bXAxisFlip	= 1
			break
		case "Center":
			vXMapOffset = -vLibraryHeight/2
			vYMapOffset = -vLibraryHeight/2
			bYAxisFlip = 0
			bXAxisFlip	= 0
			break
		default:
			break
	endswitch
	
	//Store axis flip status
	COMBI_GiveGlobal("bXAxisFlip",num2str(bXAxisFlip),sProject)
	COMBI_GiveGlobal("bYAxisFlip",num2str(bYAxisFlip),sProject)
	
	//Store total samples
	COMBI_GiveGlobal("vTotalSamples", num2str(vTotalContacts), sProject)
	variable vTotalSamples = vTotalContacts
	
	//Write to library space
	variable iRow,iColumn,iSample
	for(iRow=0;iRow<vRows;iRow+=1)
		for(iColumn=0;iColumn<vColumns;iColumn+=1)
			iSample = iColumn+iRow*vColumns
			wMappingGrid[iSample][0] = iSample+1
			wMappingGrid[iSample][1] = - wZPositions[iSample][0] + vXoffset
			wMappingGrid[iSample][2] = wZPositions[iSample][1] + vYoffset
			wMappingGrid[iSample][3] = iRow+1
			wMappingGrid[iSample][4] = iColumn+1
		endfor
	endfor
	
	//Add to scalar wave
	COMBI_AddLibraryToScalar(sProject,"AllLibraries")
	
	//Add Sample labels
	for(iSample=0; iSample < vTotalSamples; iSample+=1)
		setdimlabel 0, iSample, $"P"+num2str(1+iSample), wMappingGrid
		//setdimlabel 1, iSample, $"P"+num2str(1+iSample), wMeta
	endfor
	
	//Navigate to Gamry folder, creating folders as needed
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S $sProject
	NewDataFolder/O/S ZGamry
	
	string sFolder = "ZGamry"
	
	//Return to root folder
	setDataFolder root: 
	
	//Ask user whether to load a temperature calibration wave
	string sLoadTempCal
	prompt sLoadTempCal, "Load temperature calibration wave?", POPUP "Yes;No"
	doPrompt "File loading", sLoadTempCal
	if (V_Flag)
		return -1
	endif

	//Load temperature calibration wave
	if(stringmatch(sLoadTempCal,"yes"))	
		doAlert/T="File opening", 0, "Select a .txt temperature calibration file."
		if(!V_flag)
			return -1
		endif 
		ZGamry_LoadTCalP(sProject)
	endif	
	
	//Move coordinate wave to ZGamry folder 
	string sZCoordinatePath = "root:COMBIgor:" + sProject + ":" + sFolder + ":ZCoordinates0" 
	MoveWave wZPositions, $sZCoordinatePath
	
	//Store coordinate wave path as global
	string sZGamryCoordinates = "ZCoordinatesPath"
	Combi_GiveInstrumentGlobal("ZGamry", sZGamryCoordinates, sZCoordinatePath, sProject)
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Loads a fit data file, getting information from file name strings and loading the waves accordingly
Function ZGamry_LoadECMFitData()
	//Get global import folder
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder", sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif

	//Load the ECM data
	string sZDataWave = "ZFitData0" 
	
	//Load fit wave
	LoadWave/J/Q/K=0/O/M/N=ZFitData 
	wave/T wZDataWave=$sZDataWave
	
	//Get model name from data wave
	string sModelName = StringByKey("Model", wZDataWave[0], ": ")
	
	//Create relevant strings
	string sFilePath, sFileName
	string sLibrary, sContactNumber, sTempList, sMeasTemp, sSetpointTemp
	variable j, vNumSetpoints
	
	//Define string model for parsing file name
	string expr="([[:ascii:]]*)_Contact([[:digit:]]*)_([[:ascii:]]*)"
	string sAllSetpoints = ""
	//Analyze file names for library name and number of unique setpoints
	for(j = 2; j < DimSize(wZDataWave, 0); j += 1)
		//Take data file path from fit wave
		sFilePath = wZDataWave[j][0]
		//Take file name only
		sFileName = RemoveEnding(sFilePath[strsearch(sFilePath, "\\", strlen(sFilePath), 1) + 1, strlen(sFilePath)], ".txt")
		//Apply split model
		SplitString/E=(expr) sFileName, sLibrary, sContactNumber, sTempList
		//Identify unique setpoint values and make a list of them
		if(ItemsinList(sTempList, "_") == 1)
			sSetpointTemp = RemoveEnding(sTempList,"C")
			sMeasTemp = ""
		elseif(ItemsinList(sTempList, "_") == 2)
			sMeasTemp = RemoveEnding(StringFromList(0, sTempList, "_"),"C")
			sSetpointTemp = RemoveEnding(StringFromList(1, sTempList, "_"),"C")
		endif
		if(WhichListItem(sSetpointTemp, sAllSetpoints) == -1)
			sAllSetpoints += sSetpointTemp + ";"
		endif
	endfor
	
	//Create variable for number of setpoints to define length of vector waves
	vNumSetpoints = ItemsinList(sAllSetpoints)
	
	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//If filename contains actual temperature, make wave to store values
	string sActualTWave = "MeasTemp"
	variable k
	sActualTWave = CleanupName(sActualTWave, 0)
	Combi_AddDataType(sProject, sLibrary, sActualTWave, 2, iVDim = vNumSetpoints)
	wave wMeasTemp = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sActualTWave
	//Set dimension labels of columns 
	for(k = 0; k < DimSize(wMeasTemp, 1); k += 1)
		SetDimLabel 1, k, $StringFromList(k, sAllSetpoints), wMeasTemp
	endfor
	
	//Prompt user for library and air condition (wet/dry)
	string sAirCond, sLoadTCalWave, sLoadCoorWave
	prompt sLibrary, "Which library?"  
	prompt sAirCond, "Wet or dry?", POPUP "Dry;Wet"
	prompt sLoadTCalWave, "Load new temperature calibration wave?", POPUP "No;Yes"
	prompt sLoadCoorWave, "Load a new coordinate wave or use the one that is currently loaded?", POPUP "Load new;Keep current"
	doPrompt "Select library and ambient condition.", sLibrary, sAirCond, sLoadTCalWave, sLoadCoorWave
	if(V_Flag)
		return -1
	endif
		
	//Load new temperature calibration wave, if directed by user
	if(stringmatch(sLoadTCalWave, "Yes"))
		ZGamry_LoadTCalP(sProject)
	endif
	if(V_Flag)
		return - 1
	endif
	
	//Add library name to Library wave and library folder to Data folder
	Combi_NewLibrary(sProject, sLibrary)
	
	//Create paths to necessary waves and folders
	string sZCoordinatesPath = Combi_GetInstrumentString("ZGamry", "ZCoordinatesPath", sProject)
	wave wZPositions = $sZCoordinatesPath
	string sZLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":"
	wave wZSample = $sZLibraryPath + "Sample"
	
	//Load new coordinate wave, if directed by user
	//Make SampleNumber wave, which aligns contact numbers with sample numbers defined on the project
	//by correlating matching x,y pairs
	//If no new coordinate file is being loaded, SampleNew is a duplicate of the Sample wave
	variable i
	if(stringmatch(sLoadCoorWave, "Load new"))
		
		//Get total number of samples from globals wave
		string sTotalSamples = Combi_GetGlobalString("vTotalSamples", sProject)
		string sFirstContact = "1"
		
		//Directs user to select the number of the first contact measured as defined by the project's mapping grid 
		prompt sFirstContact, "First contact measured of "  + sTotalSamples + " point grid:"
		doPrompt "Which contact was measured first?" sFirstContact
		
		//Load new coordinate file, creating x and y waves in the library folder
		ZGamry_LoadNewCoordToLibrary(sProject, sLibrary)
		wave wMeasX = $sZLibraryPath + "xMeas_mm"
		wave wMeasY = $sZLibraryPath + "yMeas_mm"
		SetDataFolder $sZLibraryPath
		
		//Make and create access to the SampleNumber wave
		Make/O/N=(DimSize(wZPositions, 0)) SampleNumber
		wave wSampleNumber = $sZLibraryPath + "SampleNumber"
		SetDataFolder root:
		
		//Converts user input to index variable
		variable vFirstContactIndex = str2num(sFirstContact) - 1
		
		//Find x,y offsets of contact 1 of this sample compared to contact 1 of the project mapping grid
		variable vXOffsetAdd = wZPositions[vFirstContactIndex][0]
		variable vYOffsetAdd = wZPositions[vFirstContactIndex][1]
		
		//Find matching x,y coordinates in existing coordinate wave and set measured sample number equal to corresponding 
		//mapping grid sample number 
		for(i = 0; i < DimSize(wMeasX, 0); i += 1)
			for(j = 0; j < DimSize(wZPositions, 0); j += 1)
				if(wMeasX[i] + vXOffsetAdd == wZPositions[j][0] && wMeasY[i] + vYOffsetAdd ==wZPositions[j][1])
					wSampleNumber[i] = wZSample[j]
					break
				endif				
			endfor	
		endfor	
		
	elseif(stringmatch(sLoadCoorWave, "Keep current"))
		
		//Get access to loaded coordinate wave
		string sZGamryPath = "root:COMBIgor:" + sProject + ":ZGamry:"
		wave wZPositionsNew = $sZGamryPath + "ZGamryCoordinatesNew"
		
		//Duplicate wave in ZGamry folder and move it to the library folder
		Duplicate/O wZPositions, wZPositionsNew
		MoveWave wZPositionsNew, $sZLibraryPath + "ZMeasCoordinates"
		
		//Create  x and y component waves from coordinate wave
		SetDataFolder $sZLibraryPath
		Make/O/N=(DimSize(wZPositionsNew, 0)) xMeas_mm
		Make/O/N=(DimSize(wZPositionsNew, 0)) yMeas_mm
		wave wMeasX = $sZLibraryPath + "xMeas_mm"
		wave wMeasY = $sZLibraryPath + "yMeas_mm"
		wMeasX[] = wZPositionsNew[p][0]
		wMeasY[] = wZPositionsNew[p][1]
		
		//Kill positions waves
		killWaves wZPositionsNew
		
		//Duplicate Sample wave for use during loading
		Make/O/N=(DimSize(wZPositions, 0)) SampleNumber
		wave wSampleNumber = $sZLibraryPath + "SampleNumber"
		Duplicate/O $sZLibraryPath + "Sample", wSampleNumber
		SetDataFolder root:
	endif
	if(V_Flag)
		return - 1
	endif	
		
	//Determine number of fit parameters from data wave
	variable vNumFitParams = 0
	for(i = 1; i < DimSize(wZDataWave, 1); i += 1)
		if(strlen(wZDataWave[0][i])!=0)
			vNumFitParams = vNumFitParams + 1
		endif
	endfor
		
	//Make new vector data type wave for each fit parameter
	string sFitParam, sSampleName

	//Loops through columns
	for(i = 1; i < vNumFitParams + 1; i += 1)	
		//Create and access a vector wave for the data type
		sFitParam = wZDataWave[0][i] + "_" + sAirCond + "_" + sModelName
		sFitParam = CleanupName(sFitParam, 0)
		Combi_AddDataType(sProject, sLibrary, sFitParam, 2, iVDim = vNumSetpoints)
		wave wFitParam = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sFitParam
		
		//Set dimension labels of vector wave
		for(k = 0; k < DimSize(wFitParam, 1); k += 1)
			SetDimLabel 1, k, $StringFromList(k, sAllSetpoints), wFitParam
		endfor
		
		//Use file name to sort data
		variable vSampleNumber 
		//Loops through rows
		for(j = 2; j < DimSize(wZDataWave, 0); j += 1)
			//Take data file path from fit wave
			sFilePath = wZDataWave[j][0]
			//Takes file name only
			sFileName = RemoveEnding(sFilePath[strsearch(sFilePath, "\\", strlen(sFilePath), 1) + 1, strlen(sFilePath)], ".txt")
			//Apply split model
			SplitString/E=(expr) sFileName, sSampleName, sContactNumber, sTempList
			vSampleNumber = wSampleNumber[str2num(sContactNumber) - 1]
			//Determines whether actual temperature reading is present in filename
			if(ItemsinList(sTempList, "_") == 1)
				sSetpointTemp = RemoveEnding(sTempList,"C")
				sMeasTemp = ""
			elseif(ItemsinList(sTempList, "_") == 2)
				sMeasTemp = RemoveEnding(StringFromList(0, sTempList, "_"),"C")
				sSetpointTemp = RemoveEnding(StringFromList(1, sTempList, "_"),"C")
				//Populate actual temperature wave
				wMeasTemp[vSampleNumber - 1][%$sSetpointTemp] = str2num(sMeasTemp)
			endif
			//Populate fit parameter wave
			wFitParam[vSampleNumber - 1][%$sSetpointTemp] = str2num(wZDataWave[j][i])
		endfor
	endfor
	KillWaves root:ZFitData0
	//COMBI_GiveInstrumentGlobal("ZGamry",sGlobal,sValue,sFolder)()
	//COMBI_Add2Log(sProject,sLibraries,sDataType,vLogEntryType,sLogText)
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Standalone temperature calibration wave loading
function ZGamry_LoadTCal()
	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//Name calibration wave
	string sTCalZ = "ZTempCal", sTCalCoef = "TCalCoef"
	
	//Navigate to Gamry folder, creating folders as needed
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S $sProject
	NewDataFolder/O/S ZGamry
	
	//Load temperature calibration wave
	LoadWave/J/N=$sTCalZ/O/K=1/Q
	
	//Define path to calibration wave
	wave wTCalZx = $sTCalZ + "0"
	wave wTCalZy = $sTCalZ + "1"
	
	//Define path to coefficient wave
	string sFolder = "ZGamry"
	string sTCalCoefPath = "root:COMBIgor:"+sProject+":" + sFolder + ":" + sTCalCoef
	Make/O/N=3 $sTCalCoef
	wave wTCalCoefZ = $sTCalCoefPath
	
	//Fit calibration wave to find coefficients and make coefficients a string list
	CurveFit poly 3, kwCWave=wTCalCoefZ, wTCalZy /X=wTCalZx 
	string sTCalCoefList = num2str(wTCalCoefZ[0]) + ";" + num2str(wTCalCoefZ[1]) + ";" + num2str(wTCalCoefZ[2])
	
	//Store coefficient list as a global
	Combi_GiveInstrumentGlobal(sFolder, sTCalCoef, sTCalCoefList, sProject)
	
	//Kill calibration waves
	KillWaves wTCalZx, wTCalZy
	
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Programmatic temperature calibration wave loading
function ZGamry_LoadTCalP(sProject)
	
	//Declare parameter
	string sProject 
		
	//Name calibration wave
	string sTCalZ = "ZTempCal", sTCalCoef = "TCalCoef"
	
	//Navigate to Gamry folder, creating folders as needed
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S $sProject
	NewDataFolder/O/S ZGamry
	
	//Load temperature calibration wave
	LoadWave/J/N=$sTCalZ/O/K=1/Q
	
	//Define path to calibration wave
	wave wTCalZx = $sTCalZ + "0"
	wave wTCalZy = $sTCalZ + "1"
	
	//Define path to coefficient wave
	string sFolder = "ZGamry"
	string sTCalCoefPath = "root:COMBIgor:" + sProject + ":" + sFolder + ":" + sTCalCoef
	Make/O/N=3 $sTCalCoef
	wave wTCalCoefZ = $sTCalCoefPath
	
	//Fit calibration wave to find coefficients and make coefficients a string list
	CurveFit poly 3, kwCWave=wTCalCoefZ, wTCalZy /X=wTCalZx 
	string sTCalCoefList = num2str(wTCalCoefZ[0]) + ";" + num2str(wTCalCoefZ[1])
	
	//Store coefficient list as a global
	Combi_GiveInstrumentGlobal(sFolder, sTCalCoef, sTCalCoefList, sProject)
	
	//Kill calibration waves
	KillWaves wTCalZx, wTCalZy
	
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Standalone coordinate file loading 
function ZGamry_LoadCoordinates()
	
	doAlert/T="Coordinate file opening", 0, "WARNING: loading a new coordinate file will reconfigure the mapping grid."
		if(!V_flag)
			return -1
		endif 
	
	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//Name wave
	string sZGamryCoordinates = "ZCoordinates"
	
	//Navigate to Gamry folder, creating folders as needed
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S $sProject
	NewDataFolder/O/S ZGamry
	
	//Load coordinate wave
	LoadWave/J/Q/M/O/N=ZGamryCoordinates 
	SetDataFolder root:
	
	//Define path to wave
	string sZCoordinatePath = "root:COMBIgor:"+sProject+":ZGamry:"+sZGamryCoordinates+"0"
	
	//Store path as global
	Combi_GiveInstrumentGlobal("ZGamry", sZGamryCoordinates, sZCoordinatePath, sProject)
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
////Programmatic coordinate file loading 
//function ZGamry_LoadCoordinatesP(sProject)
//	
//	//Declare parameter
//	string sProject
//	
//	//Name wave
//	string sZGamryCoordinates = "ZCoordinates"
//	
//	//Navigate to Gamry folder, creating folders as needed
//	NewDataFolder/O/S COMBIgor
//	NewDataFolder/O/S $sProject
//	NewDataFolder/O/S ZGamry
//	
//	//Load coordinate wave
//	LoadWave/J/Q/M/O/N=ZGamryCoordinates 
//	SetDataFolder root:
//	
//	//Define path to wave
//	string sZCoordinatePath = "root:COMBIgor:"+sProject+":AllLibraries:"+sZGamryCoordinates+"0"
//	
//	//Store path as global
//	Combi_GiveInstrumentGlobal("ZGamry", sZGamryCoordinates, sZCoordinatePath, sProject)
//end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Load a new coordinate file to a library folder
function ZGamry_LoadNewCoordToLibrary(sProject, sLibrary)

	//Declare parameters
	string sProject, sLibrary
	
	//Name wave
	string sZGamryCoordinates = "ZCoordinates"
	
	//Navigate to library folder
	string sZLibraryPath =  "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":"
	SetDataFolder $sZLibraryPath
	
	//Load coordinate wave and make x and y component waves
	LoadWave/J/Q/M/O/N=$sZGamryCoordinates 
	string sCoordWavePath = sZLibraryPath + sZGamryCoordinates + "0"
	wave wZGamryCoordinates = $sCoordWavePath
	Make/O/N=(DimSize(wZGamryCoordinates, 0)) xMeas_mm
	Make/O/N=(DimSize(wZGamryCoordinates, 0)) yMeas_mm
	wave wMeasX = $sZLibraryPath + "xMeas_mm"
	wave wMeasY = $sZLibraryPath + "yMeas_mm"
	
	//Split coordinates wave into x and y components and kill positions wave
	wMeasX[] = wZGamryCoordinates[p][0]
	wMeasY[] = wZGamryCoordinates[p][1]
	killWaves wZGamryCoordinates
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Calculate Rp (vector wave)
function ZGamry_CalculateRp()

	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//Choose library
	string sLibrary
	//Remove allLibraries from list
	string sAllLibraries = RemoveFromList("AllLibraries", COMBI_TableList(sProject, 2, "All", "Libraries"))
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	doPrompt "Choose library to calculate polarization resistance", sLibrary
	if (V_Flag)
		return -1
	endif	
	
	//Select data types to use for calculation
	string sWave1, sWave2
	string sAllDataTypes = COMBI_TableList(sProject, 2, sLibrary, "DataTypes")
	prompt sWave1, "Select first wave:" POPUP sAllDataTypes
	prompt sWave2, "Select second wave:" POPUP sAllDataTypes
	doPrompt "Choose waves to calculate polarization resistance", sWave1, sWave2
	if (V_Flag)
		return -1
	endif	
	
	//Retrieve waves
	wave wWave1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave1
	wave wWave2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave2

	//Make polarization resistance wave 
	string expr="([[:alpha:]]*)([[:digit:]]*)_([[:ascii:]]*)"
	string sToDrop1, sToDrop2, sDescriptor
	SplitString/E=(expr) sWave1, sToDrop1, sToDrop2, sDescriptor
	string sRpWave = "Rp_" + sDescriptor
	SetDataFolder $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":"
	variable vNumRows =  str2num(Combi_GetGlobalString("vTotalSamples", sProject))
	variable vNumCols = dimSize(wWave1, 1)
	Make/O/N=(vNumRows, vNumCols) $sRpWave 
	wave wRpWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sRpWave
	
	//Set dimension labels of columns of new wave equal to dimension labels of one of the source waves
	CopyDimLabels/Cols = 1 wWave1, wRpWave
	
	//Do math
	wRpWave[][] = wWave1[p][q] + wWave2[p][q]
	
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Calculate Ea (scalar wave)  
function ZGamry_CalculateEa()
	
	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//Select resistance value to use for Ea fit 
	string sAllDataTypes = "", sLibrary, sActualTWave = "MeasTemp", sRValue, sTCalCoef = "TCalCoef"
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	doPrompt "Which library to calculate activation energy?", sLibrary
	if (V_Flag)
		return -1
	endif	
	sAllDataTypes = COMBI_TableList(sProject, 2, sLibrary, "DataTypes")	
	prompt sRValue "Select resistance label:" POPUP sAllDataTypes
	doPrompt "Which resistance value to calculate activation energy?", sRValue
	if (V_Flag)
		return -1
	endif
	
	//Retrieve resistance value wave for fit
	wave wRWavetoFit = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sRValue
	
	//Retrieve temperature wave for fit
	wave wMeasTemp = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sActualTWave
	
	//Retrieve temperature calibration coefficient wave
	wave wTCalCoefZ = $"root:COMBIgor:" + sProject + ":ZGamry:"+ sTCalCoef
	
	//Retrieve temperature calibration coefficient values
	string sTCalCoefList = "TCalCoef"
	string sTCalCoefValues = Combi_GetInstrumentString("ZGamry", sTCalCoefList, sProject)
	variable vCoef0, vCoef1
	vCoef0 = str2num(StringFromList(0, sTCalCoefValues, ";"))
	vCoef1 = str2num(StringFromList(1, sTCalCoefValues, ";"))
	
	//Make wave to store calibrated temperature values
	variable i, j
	variable vNumSetpoints = dimSize(wRWavetoFit, 1), vTActual
	string sCalTWave = "CalibratedTemp"
	sCalTWave = CleanupName(sCalTWave, 0)
	KillWaves/Z $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sCalTWave
	Combi_AddDataType(sProject, sLibrary, sCalTWave, 2, iVDim = vNumSetpoints)
	wave wCalTemp = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sCalTWave
	
	//Set dimension labels of columns equal to dimension labels of resistance wave columns
	CopyDimLabels/Cols = 1 wRWavetoFit, wCalTemp
	
	//Loop through rows
	for(i = 0; i < DimSize(wRWavetoFit, 0); i += 1)
		//Loop through columns
		for(j = 0; j < vNumSetpoints; j += 1)
			//Calculate the calibrated value from the actual temperature
			vTActual = wMeasTemp[i][j]
			wCalTemp[i][j] = poly(wTCalCoefZ, vTActual)
		endfor
	endfor

	//Do fit 
	
	//Make Ea fit wave (inverse temp, resistance)
	string sEaFitWave = "EaFitWave", vTotalSamples
	variable vInvTemp, vCalTemp, vNumTemps = dimSize(wRWavetoFit, 1)
	string sDataPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary +":"
	SetDataFolder sDataPath
	Make/N=(str2num(Combi_GetGlobalString("vTotalSamples", sProject)), dimSize(wRWavetoFit, 1))/O EaFitWave 
	wave wEaFitWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sEaFitWave
	SetDataFolder root:
	
	//Make Ea wave to store Ea values
	string sEaWaveName = ReplaceString(StringFromList(0, sRValue, "_"), sRValue, "Ea")
	Combi_AddDataType(sProject, sLibrary, sEaWaveName, 2, iVDim = 2)
	wave wEaWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sEaWaveName
	SetDimLabel 1, 0, EaPreExp, wEaWave
	SetDimLabel 1, 1, Ea, wEaWave
	
	//Fit data from each row of resistance wave
	variable vEa, vEaPreExp, vGasConstant = .08617330350
	//Make list of temperatures in wave
	string sMeasTemps = "", sCheckOptions = "", sFitTemps
	for(i = 0; i < dimSize(wRWavetoFit, 1); i += 1)
		sMeasTemps = sMeasTemps + "T" + GetDimLabel(wRWavetoFit, 1, i) + ";"
		sCheckOptions = sCheckOptions + "1;"
	endfor
	//Create checkbox for user input
	sFitTemps = COMBI_UserOptionSelect(sMeasTemps, sCheckOptions)
	//Loop through rows
	for(i = 0; i < dimSize(wRWavetoFit, 0); i += 1)
		//Clear fit wave
		wEaFitWave[][] = Nan
		//Loop through columns
		for(j = 0; j < dimSize(wRWavetoFit, 1); j += 1)
			//Include value in fit if user has selected this measurement temp and the resistance value exists.
			if(WhichListItem("T" + GetDimLabel(wRWavetoFit, 1, j), sFitTemps)!= -1 && numtype(wRWavetoFit[i][j])==0)
				//Get calibrated temperature and invert
				vCalTemp = wCalTemp[i][j]
				vInvTemp = 1000/(vCalTemp + 273.15)
				wEaFitWave[j][0] = vInvTemp
				//wEaFitWave[j][1] = wRWavetoFit[i][j]
				wEaFitWave[j][1] = Ln(1/wRWavetoFit[i][j])
			endif
		endfor
		
		//Linear curve fit of Arrhenius data
		//Define path to coefficient wave
		string sEaCoef = "EaCoef"
		string sEaCoefPath = sDataPath + sEaCoef
		SetDataFolder sDataPath
		Make/O/N=2 $sEaCoef
		wave wEaCoefZ = $sEaCoefPath
		SetDataFolder root:
		
		//Fit calibration wave to find coefficients and make coefficients a string list
		CurveFit /Q line, kwCWave=wEaCoefZ, wEaFitWave[][1] /X=wEaFitWave[][0] /D 
		vEa = - wEaCoefZ[1]*vGasConstant
		vEaPreExp = wEaCoefZ[0]
		wEaWave[i][0] = vEaPreExp
		wEaWave[i][1] = vEa
	endfor
	
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Use calibration fit to calibrate actual temperature wave
//Creates new calibrated temperature wave
function ZGamry_CalibrateTemp()
	
	//Choose project
	string sProject = Combi_ChooseInstrumentProject()
	
	//Select library to calibrate temperature for
	string sLibrary, sActualTWave = "MeasTemp", sTCalCoef = "TCalCoef"
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	doPrompt "Select the library for which to calibrate temperature.", sLibrary
	if (V_Flag)
		return -1
	endif	
	
	//Retrieve resistance value and temperature waves for fit
	string sZLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" 
	wave wMeasTemp = $sZLibraryPath + sActualTWave
	
	//Retrieve temperature calibration coefficient wave
	wave wTCalCoefZ = $"root:COMBIgor:" + sProject + ":ZGamry:"+ sTCalCoef
	
	//Make wave to store calibrated temperature values
	variable i, j
	variable vNumSetpoints = dimSize(wMeasTemp, 1), vTActual
	string sCalTWave = "CalibratedTemp"
	sCalTWave = CleanupName(sCalTWave, 0)
	//Kill calibrated temp wave, in case it already exists
	KillWaves/Z $sZLibraryPath + sCalTWave
	Combi_AddDataType(sProject, sLibrary, sCalTWave, 2, iVDim = vNumSetpoints)
	wave wCalTemp = $sZLibraryPath + sCalTWave
	
	//Set dimension labels of columns equal to dimension labels of resistance wave columns
	CopyDimLabels/Cols = 1 wMeasTemp, wCalTemp
	
	//Loop through rows
	for(i = 0; i < DimSize(wMeasTemp, 0); i += 1)
		//Loop through columns
		for(j = 0; j < vNumSetpoints; j += 1)
			//Calculate the calibrated value from the actual temperature
			vTActual = wMeasTemp[i][j]
			wCalTemp[i][j] = poly(wTCalCoefZ, vTActual)
		endfor
	endfor
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------