#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Meagan Papac _ Dec 2018

//Description of procedure purpose:
//Load, fit, and plot impedance data collected from a Gamry potentiostat.
//
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Builds the drop-down menu for this instrument
Menu "COMBIgor"
	SubMenu "Instruments"
		 SubMenu "ZGamry"
		 	SubMenu "Set up"
		 		"Make new project from coordinate file", ZGamry_NewProject()
		 		"Load new temperature calibration file", ZGamry_LoadTCal()
		 		"Load new coordinate file", ZGamry_LoadCoordinates()
		 		"Define ECM fit model", ZGamry_DefineECMFitModel()
		 	end
		 	SubMenu "Load data"
		 		"Load fit file", ZGamry_LoadECMFitData()
		 		"Load raw data from folder", ZGamry_LoadRawZData()
		 		"Load raw spectrum from file", ZGamry_LoadRawZSpectrum()
		 		"Interpolate scalar from another project", ZGamry_Interpolate()
		 	end
		 	SubMenu "Process data"
		 		"Calculate data from fit", ZGamry_CalculateECMFitData()
		 		"Calibrate temperature", ZGamry_CalibrateTemp()
		 		"Calculate Rp", ZGamry_CalculateRp()
		 		"Sort fit parameters by time constant", ZGamry_SortbyTimeConstant()
		 		"Calculate Ea", ZGamry_CalculateEa()
		 		"Calculate ASR", ZGamry_ASRsetup()
		 		"Sift Z data", ZGamry_SiftFitData()
		 		"Sift by chi squared", ZGamry_SiftByChiSquared()
		 	end
		 	SubMenu "Display data"
		 		"Display or append Nyquist plot", ZGamry_PlotNyquistwPrompts()
		 		"Plot and save all Nyquist plots", ZGamry_PlotAndSaveAllNyquist()
		 		"Display or append Bode plot", ZGamry_PlotBodewPrompts()
		 		"Plot and save all Bode plots", ZGamry_PlotAndSaveAllBode()
		 	end
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
		NewPath/Z/Q/O pUserPath, COMBI_GetGlobalString("sImportPath","COMBIgor")
		Pathinfo/S pUserPath //direct to user folder
		doAlert/T="File opening", 0, "Select a .txt file for positions measured."
		if(!V_flag)
			return -1
		endif 
		LoadWave/J/Q/M/O/P=pUserPath/N=ZCoordinates 
	else
		doAlert/T="File opening", 0, "Select a .txt file for positions measured."
		if(!V_flag)
			return -1
		endif 
		LoadWave/J/Q/M/O/N=ZCoordinates 
	endif

	wave wZPositions = root:ZCoordinates0
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
	COMBI_AddLibraryToScalar(sProject,"FromMappingGrid")
	
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
	
//	//Ask user whether to load a temperature calibration wave
//	string sLoadTempCal
//	prompt sLoadTempCal, "Load temperature calibration wave?", POPUP "Yes;No"
//	doPrompt "File loading", sLoadTempCal
//	if (V_Flag)
//		return -1
//	endif
//
//	//Load temperature calibration wave
//	if(stringmatch(sLoadTempCal,"yes"))	
//		doAlert/T="File opening", 0, "Select a .txt temperature calibration file."
//		if(!V_flag)
//			return -1
//		endif 
//		ZGamry_LoadTCalP(sProject)
//	endif	
//	
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
	if(V_Flag==0)
		return -1
	endif
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
	
	//Prompt user for library and air condition (wet/dry)
	string sAirCond, sLoadTCalWave, sLoadCoorWave
	prompt sLibrary, "Which library?"  
	prompt sAirCond, "Gas flow?", POPUP "Dry;Wet;NoFlow"
	prompt sLoadTCalWave, "Load new temperature calibration wave?", POPUP "No;Yes"
	prompt sLoadCoorWave, "Would you like to load a new coordinate wave or use the one that is currently loaded?", POPUP "Keep current;Load new"
	doPrompt "Select library and ambient condition.", sLibrary, sAirCond, sLoadTCalWave, sLoadCoorWave
	if(V_Flag)
		return -1
	endif
	
	//get list of all currently loaded data types
	string sAllDataTypes = COMBI_TableList(sProject, 2, sLibrary, "DataTypes")
	//if wave does not exist, make it and get access
	if(findListItem(sActualTWave, sAllDataTypes)==-1)
		Combi_AddDataType(sProject, sLibrary, sActualTWave, 2, iVDim = vNumSetpoints)
		wave wMeasTemp = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sActualTWave
	endif
	//if wave does exist, get access and add new setpoints
	if(findListItem(sActualTWave, sAllDataTypes)!=-1)
		wave wMeasTemp = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sActualTWave
		Redimension/N=(dimSize(wMeasTemp, 0), dimSize(wMeasTemp, 1) + vNumSetpoints) wMeasTemp
		variable m
		
		//go through new setpoints
		//if setpoint does not already exist, redimension wave and add label
		variable vColsMeas = dimSize(wMeasTemp, 1)
		//get all current setpoints
		string sOldSetpoints = ""
		for(m = 0; m < vColsMeas; m += 1)
			if(!stringmatch(getDimLabel(wMeasTemp, 1, m), ""))		
				sOldSetpoints = sOldSetpoints + getDimLabel(wMeasTemp, 1, m) + ";"
			elseif(stringmatch(getDimLabel(wMeasTemp, 1, m), ""))		
				deletePoints/M=1 m, 1, wMeasTemp
				vColsMeas = vColsMeas - 1
				m = m - 1
			endif
		endfor	
		
		//Redimension and set dimension labels of new columns
		for(m = 0; m < itemsInList(sAllSetpoints); m += 1)
			if(findListItem(stringFromList(m, sAllSetPoints), sOldSetpoints)==-1)
				Redimension/N=(-1, dimSize(wMeasTemp, 1) + 1) wMeasTemp
				SetDimLabel 1, dimSize(wMeasTemp, 1) - 1, $StringFromList(m, sAllSetpoints), wMeasTemp
			endif
		endfor			
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
	string sZLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":"
	wave wZSample = $sZLibraryPath + "Sample"
	
	//Load new coordinate wave, if directed by user
	//Make SampleNumber wave, which aligns contact numbers with sample numbers defined on the project
	//by correlating matching x,y pairs
	//If no new coordinate file is being loaded, SampleNumber is a duplicate of the Sample wave
	variable i
	if(stringMatch(sZCoordinatesPath, "!NAG"))
	
		wave wZPositions = $sZCoordinatesPath
	
		if(stringmatch(sLoadCoorWave, "Load new"))
			
			//Get total number of samples from globals wave
			string sTotalSamples = Combi_GetGlobalString("vTotalSamples", sProject)
			string sFirstContact = "1"
			
			//Directs user to select the number of the first contact measured as defined by the project's mapping grid 
			prompt sFirstContact, "First contact measured of "  + sTotalSamples + " point grid:"
			doPrompt "Which contact was measured first?" sFirstContact
			
			//Load new coordinate file, creating x and y waves in the library folder
			ZGamry_LoadNewCoordToLibrary(sProject, sLibrary)
			//sZCoordinatesPath = Combi_GetInstrumentString("ZGamry", "ZCoordinatesPath", sProject)
			//wave wZPositions = $sZCoordinatesPath
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
			
	elseif(stringmatch(sZCoordinatesPath, "NAG"))	
		
		doAlert/T="Coordinate file path not found.", 0, "A new coordinate file must be selected."
		if(!V_flag)
			return -1
		endif 
	
		//Name wave
		string sZGamryCoordinates = "ZCoordinates"
	
		//Create Gamry folder, if needed
		SetDataFolder $"root:COMBIgor:" + sProject
		NewDataFolder/O/S ZGamry
	
		//Load coordinate wave
		LoadWave/J/Q/M/O/N=ZCoordinates 
		SetDataFolder root:
	
		//Define path to wave
		string sZCoordinatePath = "root:COMBIgor:"+sProject+":ZGamry:"+sZGamryCoordinates+"0"
	
		//Store path as global
		Combi_GiveInstrumentGlobal("ZGamry", "ZCoordinatesPath", sZCoordinatePath, sProject)	
		
		//Duplicate wave in ZGamry folder and move it to the library folder
		wave wZPositions = $sZCoordinatePath
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

		if(V_Flag)
			return - 1
		endif		
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
		
		//if wave does not exist, make it and get access
		if(findListItem(sFitParam, sAllDataTypes)==-1)
			Combi_AddDataType(sProject, sLibrary, sFitParam, 2, iVDim = vNumSetpoints)
			wave wFitParam = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sFitParam
			variable kStart = 0
			for(m = 0; m < itemsInList(sAllSetpoints); m += 1)
				SetDimLabel 1, kStart + m, $StringFromList(m, sAllSetpoints), wFitParam
			endfor
			
		//if wave does exist, get access and add new setpoints
		elseif(findListItem(sFitParam, sAllDataTypes)!=-1)
			wave wFitParam = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sFitParam
			variable vCols = dimSize(wFitParam, 1)
			//get all current setpoints
			sOldSetpoints = ""
			for(m = 0; m < vCols; m += 1)
				if(!stringmatch(getDimLabel(wFitParam, 1, m), ""))		
					sOldSetpoints = sOldSetpoints + getDimLabel(wFitParam, 1, m) + ";"
				elseif(stringmatch(getDimLabel(wFitParam, 1, m), ""))		
					deletePoints/M=1 m, 1, wFitParam
					vCols = vCols - 1
					m = m - 1
				endif
			endfor
			
			//go through new setpoints
			//if setpoint does not already exist, redimension wave and add label
			for(m = 0; m < itemsInList(sAllSetpoints); m += 1)
				if(findListItem(stringFromList(m, sAllSetPoints), sOldSetpoints)==-1)
					Redimension/N=(-1, dimSize(wFitParam, 1) + 1) wFitParam
					SetDimLabel 1, dimSize(wFitParam, 1) - 1, $StringFromList(m, sAllSetpoints), wFitParam
				endif
			endfor
		endif
			
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
			if(str2num(sContactNumber)>dimSize(wSampleNumber, 0))
				doAlert/T="Contact number out of range.", 0, "Fit file has more samples than the project does. File cannot be loaded into this project."
				return -1
			endif
			vSampleNumber = wSampleNumber[str2num(sContactNumber) - 1]
			//Determines whether actual temperature reading is present in filename
			if(ItemsinList(sTempList, "_") == 1)
				sSetpointTemp = RemoveEnding(sTempList,"C")
				sMeasTemp = ""
			elseif(ItemsinList(sTempList, "_") == 2)
				sMeasTemp = RemoveEnding(StringFromList(0, sTempList, "_"),"C")
				sSetpointTemp = RemoveEnding(StringFromList(1, sTempList, "_"),"C")
				//Populate actual temperature wave
				//wMeasTemp[vSampleNumber - 1][%$sSetpointTemp] = str2num(sMeasTemp)
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

//Loads raw data from a folder, getting information from file name strings and loading all into a 4D wave
Function ZGamry_LoadRawZData()
	//Get global import folder
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder", sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//Choose project
	string sProject = Combi_ChooseInstrumentProject()
	variable vTotalSamples = str2num(COMBI_GetGlobalString("vTotalSamples",sProject))

	if(stringMatch(sProject,""))
		return -1
	endif

	NewPath/Z/Q/O pLoadPath
	Pathinfo pLoadPath
	string sPath = S_path
	if(stringMatch(sPath,""))
		return -1
	endif
	//sAllFiles is a list of all file names
	string sAllFiles = IndexedFile(pLoadPath,-1,".txt")	

	
	//Get number of setpoints
	//Create relevant strings
	string sFilePath, sFileName
	string sLibrary, sContactNumber, sTempList, sMeasTemp, sSetpointTemp
	variable j, vNumSetpoints
	
	//Define string model for parsing file name
	string expr="([[:ascii:]]*)_Contact([[:digit:]]*)_([[:ascii:]]*)"
	string sAllSetpoints = ""
	//Analyze file names for library name and number of unique setpoints
	for(j = 2; j < itemsinlist(sAllFiles); j += 1)
		//Get file name from list
		sFileName = RemoveEnding(StringFromList(j, sAllFiles), ".txt")
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
	
	//Prompt user for library and air condition (wet/dry)
	string sAirCond
	prompt sLibrary, "Which library?"  
	prompt sAirCond, "Gas flow?", POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and ambient condition.", sLibrary, sAirCond
	if(V_Flag)
		return -1
	endif
	
	//Add library name to Library wave and library folder to Data folder
	Combi_NewLibrary(sProject, sLibrary)
	
	//Create paths to necessary waves and folders
	string sZCoordinatesPath = Combi_GetInstrumentString("ZGamry", "ZCoordinatesPath", sProject)
	wave wZPositions = $sZCoordinatesPath
	string sZLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":"
	wave wZSample = $sZLibraryPath + "Sample"
	
	//Move into library folder
	SetDataFolder $sZLibraryPath
	
	//Make wave to hold impedance data if it doesn't already exist
	string sZDataWave = "ImpedanceData_" + sAirCond, sThisFile, sDimLabel 
	//Initialize wave with rows = number of samples retrieved from list of file names
	//columns = 1, layers = 11, and chunks = number of setpoints retrieved from file names
	wave wZDataWave=$sZDataWave
	//if the impedance data wave does not yet exist
	if(waveExists(wZDataWave)==0)
		variable vNewWave = 1
		Make/O/N=(vTotalSamples, 1, 11, vNumSetpoints) $sZDataWave
		wave wZDataWave=$sZDataWave
		string sUniqueNewSetpoints = sAllSetpoints
		variable vExistingSetpoints = 0
	
	//if the impedance data wave already exists
	elseif(waveExists(wZDataWave)==1)
		//redimension to hold all new setpoints
		vNewWave = 0
		variable iChunk = 0
		string sOldTempList = getDimLabel(wZDataWave, 3, iChunk)
		for(iChunk = 1; iChunk < dimSize(wZDataWave, 3); iChunk ++)
			if(!stringMatch(getDimLabel(wZDataWave, 3, iChunk),""))
				sOldTempList = sOldTempList + ";" + getDimLabel(wZDataWave, 3, iChunk)
			endif
		endfor
		variable i
		sUniqueNewSetpoints = ""
		for(i = 0; i < itemsInList(sAllSetpoints); i += 1)
			if(whichListItem(stringFromList(i, sAllSetpoints), sOldTempList) == -1)
				sUniqueNewSetpoints = sUniqueNewSetpoints + stringFromList(i, sAllSetpoints) + ";"
			endif
		endfor		
		//get number of original setpoints
		vExistingSetpoints = itemsInList(sOldTempList)
	endif
	
	Redimension/N=(-1, -1, -1, vExistingSetpoints + itemsInList(sUniqueNewSetpoints)) wZDataWave

	//wave wZDataWave=$sZDataWave
	//Set dimension labels
	for(i = vExistingSetpoints; i < ItemsinList(sUniqueNewSetpoints) + vExistingSetpoints; i += 1)
		sDimLabel = StringFromList(i - vExistingSetpoints, sUniqueNewSetpoints)
		SetDimLabel 3, i, $sDimLabel, wZDataWave 
	endfor
	
	//Return to root folder
	SetDataFolder root:
	
	//Loop through all files; get info from filename; add data to data wave
	variable iFile, iVar, jFreq, vContactNumber
	for(iFile=0; iFile<itemsinlist(sAllFiles); iFile+=1)
		//sTheFile is the name of a single file
		sThisFile = stringfromList(iFile, sAllFiles)
		//On first pass, make headers in data wave from imported data file
		if(iFile==0 && vNewWave == 1)
			//Make header wave
			LoadWave/J/Q/P=pLoadPath/K=0/L={0, 20, 2, 1, 0}/O/M/N=ZDataHeaders sThisFile
			wave/T wHeaderWave = $"ZDataHeaders0"
			for(i = 0; i < DimSize(wHeaderWave, 1); i += 1)
				sDimLabel = wHeaderWave[0][i] + "_" + wHeaderWave[1][i]
				SetDimLabel 2, i, $sDimLabel, wZDataWave
			endfor
		endif		
		//Load this file
		LoadWave/G/D/N=ZData/M/K=1/O/Q/P=pLoadPath sThisFile
		wave wLoadedWave = root:ZData0
		sFileName = RemoveEnding(StringFromList(iFile, sAllFiles), ".txt")
		//Use file name to get info on contact, setpoint, actual T
		SplitString/E=(expr) sFileName, sLibrary, sContactNumber, sTempList
		vContactNumber = str2num(sContactNumber) - 1
		if(ItemsinList(sTempList, "_") == 1)
			sSetpointTemp = RemoveEnding(sTempList,"C")
			sMeasTemp = ""
		elseif(ItemsinList(sTempList, "_") == 2)
			sMeasTemp = RemoveEnding(StringFromList(0, sTempList, "_"),"C")
			sSetpointTemp = RemoveEnding(StringFromList(1, sTempList, "_"),"C")
		endif
		//Add data to 4D wave
		for(iVar = 0; iVar < DimSize(wLoadedWave, 1); iVar += 1)
			for(jFreq = 0; jFreq < DimSize(wLoadedWave, 0); jFreq += 1)
				variable vNumFreqs = DimSize(wLoadedWave, 0)
				if(jFreq >= DimSize(wZDataWave, 1))
					Redimension/N=(-1, jFreq+1, -1, -1) wZDataWave
				endif
				wZDataWave[vContactNumber][jFreq][iVar][%$sSetpointTemp]=wLoadedWave[jFreq][iVar]
			endfor
		endfor
		//KillWaves root:ZData0
		COMBI_ProgressWindow("COMBIgorFileImport","Loading Folder","Importing Progress",iFile+1,itemsinlist(sAllFiles))
	endfor
	
	//COMBI_Add2Log(sProject,sLibraries,sDataType,vLogEntryType,sLogText)
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Loads raw data from a file, getting information from file name string and loading into a 4D wave
Function ZGamry_LoadRawZSpectrum()
	
	//Choose project
	string sProject = Combi_ChooseInstrumentProject()
	variable vTotalSamples = str2num(COMBI_GetGlobalString("vTotalSamples",sProject))
	if(stringMatch(sProject,""))
		return -1
	endif
	
	//Prompt user for library and air condition (wet/dry)
	string sAirCond, sLibrary
	prompt sLibrary, "Which library?"  
	prompt sAirCond, "Gas flow?", POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and ambient condition.", sLibrary, sAirCond
	if(V_Flag)
		return -1
	endif
	
	//Add library name to Library wave and library folder to Data folder
	Combi_NewLibrary(sProject, sLibrary)
	
	//Create paths to necessary waves and folders
	string sZCoordinatesPath = Combi_GetInstrumentString("ZGamry", "ZCoordinatesPath", sProject)
	wave wZPositions = $sZCoordinatesPath
	string sZLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":"
	wave wZSample = $sZLibraryPath + "Sample"

	//Get number of setpoints
	//Create relevant strings
	string sFilePath, sFileName
	string sContactNumber, sTempList, sMeasTemp, sSetpointTemp
	
	//Define string model for parsing file name
	string expr="([[:ascii:]]*)_Contact([[:digit:]]*)_([[:ascii:]]*)"
	
	variable iVar, jFreq, vContactNumber
	//Make header wave
	string sThisFile, sDimLabel
	variable i
	LoadWave/J/Q/K=0/L={0, 20, 2, 1, 0}/O/M/N=ZDataHeaders //sThisFile /P=pUserPath
	wave/T wHeaderWave = $"ZDataHeaders0"
	sFileName = RemoveEnding(S_filename, ".txt")
	NewPath/Z/Q/O pUserPath, S_Path
	SplitString/E=(expr) sFileName, sLibrary, sContactNumber, sTempList

	//Load this file
	LoadWave/G/D/N=ZData/M/K=1/O/Q/P=pUserPath S_filename//sThisFile 
	wave wLoadedWave = root:ZData0
	sFileName = RemoveEnding(S_filename, ".txt")
	//Use file name to get info on contact, setpoint, actual T
	SplitString/E=(expr) sFileName, sLibrary, sContactNumber, sTempList
	vContactNumber = 0
	if(ItemsinList(sTempList, "_") == 1)
		sSetpointTemp = RemoveEnding(sTempList,"C")
		sMeasTemp = ""
	elseif(ItemsinList(sTempList, "_") == 2)
		sMeasTemp = RemoveEnding(StringFromList(0, sTempList, "_"),"C")
		sSetpointTemp = RemoveEnding(StringFromList(1, sTempList, "_"),"C")
	endif
	string sAllSetpoints = sSetpointTemp
	//Move into library folder
	SetDataFolder $sZLibraryPath
	
	//Make wave to hold impedance data if it doesn't already exist
	string sZDataWave = "ImpedanceData_" + sAirCond 
	//Initialize wave with rows = number of samples retrieved from list of file names
	//columns = 1, layers = 11, and chunks = number of setpoints retrieved from file names
	wave wZDataWave=$sZDataWave
	
	//if the impedance data wave does not yet exist
	if(waveExists(wZDataWave)==0)
		variable vNumSetpoints = 1
		variable vNewWave = 1
		Make/O/N=(vTotalSamples, 1, 11, vNumSetpoints) $sZDataWave
		wave wZDataWave=$sZDataWave
		string sUniqueNewSetpoints = sAllSetpoints
		variable vExistingSetpoints = 0
		//set dimension labels
		for(i = 0; i < DimSize(wHeaderWave, 1); i += 1)
			sDimLabel = wHeaderWave[0][i] + "_" + wHeaderWave[1][i]
			SetDimLabel 2, i, $sDimLabel, wZDataWave
		endfor
	
	//if the impedance data wave already exists
	elseif(waveExists(wZDataWave)==1)
		//redimension to hold all new setpoints
		vNewWave = 0
		variable iChunk = 0
		string sOldTempList = getDimLabel(wZDataWave, 3, iChunk)
		for(iChunk = 1; iChunk < dimSize(wZDataWave, 3); iChunk ++)
			if(!stringMatch(getDimLabel(wZDataWave, 3, iChunk),""))
				sOldTempList = sOldTempList + ";" + getDimLabel(wZDataWave, 3, iChunk)
			endif
		endfor
		sUniqueNewSetpoints = ""
		for(i = 0; i < itemsInList(sAllSetpoints); i += 1)
			if(whichListItem(stringFromList(i, sAllSetpoints), sOldTempList) == -1)
				sUniqueNewSetpoints = sUniqueNewSetpoints + stringFromList(i, sAllSetpoints) + ";"
			endif
		endfor		
		//get number of original setpoints
		vExistingSetpoints = itemsInList(sOldTempList)
	endif
	
	Redimension/N=(-1, -1, -1, vExistingSetpoints + itemsInList(sUniqueNewSetpoints)) wZDataWave

	//wave wZDataWave=$sZDataWave
	//Set dimension labels
	for(i = vExistingSetpoints; i < ItemsinList(sUniqueNewSetpoints) + vExistingSetpoints; i += 1)
		sDimLabel = StringFromList(i - vExistingSetpoints, sUniqueNewSetpoints)
		SetDimLabel 3, i, $sDimLabel, wZDataWave 
	endfor

	//Add data to 4D wave
	for(iVar = 0; iVar < DimSize(wLoadedWave, 1); iVar += 1)
		for(jFreq = 0; jFreq < DimSize(wLoadedWave, 0); jFreq += 1)
			variable vNumFreqs = DimSize(wLoadedWave, 0)
			if(jFreq >= DimSize(wZDataWave, 1))
				Redimension/N=(-1, jFreq+1, -1, -1) wZDataWave
			endif
			wZDataWave[vContactNumber][jFreq][iVar][%$sSetpointTemp]=wLoadedWave[jFreq][iVar]
		endfor
	endfor
	
	//Return to root folder
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Define fit model equation
function ZGamry_DefineECMFitModel()

	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	string sFolder = "ZGamry"
	
	//Get global import folder
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder", sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//Notify user what type of file to select
	doAlert/T="Find model name and fit parameters", 0, "Select a representative equivalent circuit model fits results file."
	if(!V_flag)
		return -1
	endif 
	
	//Load the ECM data
	string sZDataWave = "ZFitData0" 
	
	//Load fit wave
	LoadWave/J/Q/K=0/O/M/L={0, 0, 1, 0, 0}/N=ZFitData 
	wave/T wModelParamWave=$sZDataWave
	
	//Get model name from data wave
	string sModelName = StringByKey("Model", wModelParamWave[0], ": ")

	string sParamList = ""
	string sDisplayParamList = ""
	variable i
	for(i = 1; i < DimSize(wModelParamWave, 1); i += 1)
		if(stringmatch(wModelParamWave[0][i], "!") && stringmatch(wModelParamWave[0][i], "!Goodness of Fit"))
			sParamList = sParamList + wModelParamWave[0][i] + ";"
			sDisplayParamList = sDisplayParamList + wModelParamWave[0][i] + ", "
		endif
	endfor
	variable vNumParams = itemsInList(sParamList, ", ")
	
	//Prompt user to define model
	string sECMModel
	//Make string prompt
	prompt sECMModel, "Enter model equation for model " + sModelName + ", including the following variables: "+ sDisplayParamList + "and spelling out Greek letters, such as omega and pi. Enter ii for the imaginary number i."
	doPrompt "Define equivalent circuit model ", sECMModel
	
	//replaces input of user to something Igor can recognize
	sECMModel = replaceString("ii", sECMModel, "sqrt(-1)")
	
	//Store model as an instrument global
	Combi_GiveInstrumentGlobal(sFolder, sModelName + "_Model", sECMModel, "COMBIgor")
	Combi_GiveInstrumentGlobal(sFolder, sModelName + "_Parameters", sParamList,  "COMBIgor")
	
	//Add model name to the instrument global string
	string sModelList 
	if(stringMatch(Combi_GetInstrumentString(sFolder, "ECMFitModels", "COMBIgor"), "NAG"))
		//add model name to model list global 				
		sModelList= addListItem(sModelName, Combi_GetInstrumentString(sFolder, "ECMFitModels", "COMBIgor"))
		//remove NAG value from list
		sModelList = removefromlist("NAG", sModelList)
		//give new list as a global
		COMBI_GiveInstrumentGlobal(sfolder, "ECMFitModels", sModelList, "COMBIgor")
	endif
	sModelList = Combi_GetInstrumentString(sFolder, "ECMFitModels", "COMBIgor")
	if(findListItem(sModelName, sModelList) == -1)
		//if model name is not yet on list, add to list
		sModelList = addListItem(sModelName, sModelList)
		//give updated list as global
		COMBI_GiveInstrumentGlobal(sfolder, "ECMFitModels", sModelList, "COMBIgor")
	endif
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
	LoadWave/J/Q/M/O/N=ZCoordinates 
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
//	string sZCoordinatePath = "root:COMBIgor:"+sProject+":FromMappingGrid:"+sZGamryCoordinates+"0"
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
	//Remove FromMappingGrid from list
	string sAllLibraries = RemoveFromList("FromMappingGrid", COMBI_TableList(sProject, 2, "All", "Libraries"))
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	doPrompt "Choose library to calculate polarization resistance", sLibrary
	if (V_Flag)
		return -1
	endif	
	
	//Get number of resistances
	string sNumRes
	prompt sNumRes, "How many resistances?"
	doPrompt "Select number of resistances to sum", sNumRes
	if (V_Flag)
		return -1
	endif	
	
	variable vNumRes = str2num(sNumRes)
	if(vNumRes > 4)
		doAlert 0, "Sorry! Cannot handle more than 4 resistance right now..."
	endif
	
	//Select data types to use for calculation
	string sWave1, sWave2, sWave3, sWave4
	string sAllDataTypes = COMBI_TableList(sProject,2, sLibrary, "DataTypes")
	prompt sWave1, "Select first wave:" POPUP sAllDataTypes
	prompt sWave2, "Select second wave:" POPUP sAllDataTypes
	prompt sWave3, "Select third wave:" POPUP sAllDataTypes
	prompt sWave4, "Select fourth wave:" POPUP sAllDataTypes
	if(vNumRes == 2)
		doPrompt "Choose waves to calculate polarization resistance", sWave1, sWave2
		if (V_Flag)
			return -1
		endif	
	endif
	if(vNumRes == 3)
		doPrompt "Choose waves to calculate polarization resistance", sWave1, sWave2, sWave3
		if (V_Flag)
			return -1
		endif	
	endif
	if(vNumRes == 4)
		doPrompt "Choose waves to calculate polarization resistance", sWave1, sWave2, sWave3, sWave4
		if (V_Flag)
			return -1
		endif	
	endif
	
	//Retrieve waves
	wave wWave1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave1
	wave wWave2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave2
	if(vNumRes > 2)
		wave wWave3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave3
	endif
	if(vNumRes > 3)
		wave wWave4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave4
	endif

	//Make polarization resistance wave 
	string expr="([[:alpha:]]*)([[:digit:]]*)_([[:ascii:]]*)"
	string sToDrop1, sToDrop2, sDescriptor
	SplitString/E=(expr) sWave1, sToDrop1, sToDrop2, sDescriptor
	string sRpWave = "Rp_" + sDescriptor
	string sTempRpWave = "TempRpWave"
	SetDataFolder $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":"
	variable vNumRows =  str2num(Combi_GetGlobalString("vTotalSamples", sProject))
	variable vNumCols = dimSize(wWave1, 1)
	wave wRpWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sRpWave
	//if the Rp wave already exists, a new temporary wave will be made for transferring data
	//this is useful if a wave is being added to Rp
	if(waveExists(wRpWave)==1)
		duplicate/O wRpWave, $"TempRpWave"
		wave wTempRpWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + "TempRpWave"
		wTempRpWave[][]=nan
		variable iRow, iCol
		for(iCol = 0; iCol < vNumCols; iCol +=1)
			string sColLabel = getDimLabel(wTempRpWave, 1, iCol)
			for(iRow = 0; iRow < vNumRows; iRow +=1)
				string sRowLabel = getDimLabel(wTempRpWave, 0, iRow)
				//transfer data
				if(vNumRes == 2)
					wTempRpWave[%$sRowLabel][%$sColLabel] = wWave1[%$sRowLabel][%$sColLabel] + wWave2[%$sRowLabel][%$sColLabel]
				elseif(vNumRes == 3)
					wTempRpWave[%$sRowLabel][%$sColLabel] = wWave1[%$sRowLabel][%$sColLabel] + wWave2[%$sRowLabel][%$sColLabel] + wWave3[%$sRowLabel][%$sColLabel]
				elseif(vNumRes == 4)
					wTempRpWave[%$sRowLabel][%$sColLabel] = wWave1[%$sRowLabel][%$sColLabel] + wWave2[%$sRowLabel][%$sColLabel] + wWave3[%$sRowLabel][%$sColLabel] + wWave4[%$sRowLabel][%$sColLabel]
				endif
			endfor
		endfor
		killWaves wRpWave
		duplicate wTempRpWave, $sRpWave
		killWaves wTempRpWave
	//if the Rp wave does not exist, it will be made
	elseif(waveExists(wRpWave)==0)
		Make/O/N=(vNumRows, vNumCols) $sRpWave
		wave wRpWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sRpWave
		//copy dimension labels to Rp wave
		CopyDimLabels/Cols = 1/Rows = 0 wWave1, wRpWave
		//transfer data
		for(iCol = 0; iCol < vNumCols; iCol +=1)
			sColLabel = getDimLabel(wRpWave, 1, iCol)
			for(iRow = 0; iRow < vNumRows; iRow +=1)
				sRowLabel = getDimLabel(wRpWave, 0, iRow)
				if(vNumRes == 2)
					wRpWave[%$sRowLabel][%$sColLabel] = wWave1[%$sRowLabel][%$sColLabel] + wWave2[%$sRowLabel][%$sColLabel]
				elseif(vNumRes == 3)
					wRpWave[%$sRowLabel][%$sColLabel] = wWave1[%$sRowLabel][%$sColLabel] + wWave2[%$sRowLabel][%$sColLabel] + wWave3[%$sRowLabel][%$sColLabel]
				elseif(vNumRes == 4)
					wRpWave[%$sRowLabel][%$sColLabel] = wWave1[%$sRowLabel][%$sColLabel] + wWave2[%$sRowLabel][%$sColLabel] + wWave3[%$sRowLabel][%$sColLabel] + wWave4[%$sRowLabel][%$sColLabel]
				endif
			endfor
		endfor
	endif
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
	//string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	string sAllLibraries = RemoveFromList("FromMappingGrid", COMBI_TableList(sProject, 2, "All", "Libraries"))
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
	
	//Check for calibrated temperature wave	
	wave wCalTemp = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":CalibratedTemp"
	if(waveExists(wCalTemp)==0)
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
		if(waveExists(wCalTemp)==0)
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
		endif
	endif
		
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
	doPrompt "Which library would you like to calibrate temperature for?", sLibrary
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

//Plot raw impedance data (Nyquist or Bode)
function ZGamry_Plotter()
	
	//Choose project
	string sProject = Combi_ChooseInstrumentProject()
	
	//Select library 
	string sLibrary, sAirCond 
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Which library would you like to plot?", sLibrary, sAirCond
	if (V_Flag)
		return -1
	endif	 
	
	//Access ZData wave for this library
	wave wZDataWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":ImpedanceData_" + sAirCond
 
	//Select temperature/s 
	string sTempList 
	string sAllTemps = GetDimLabel(wZDataWave, 3, -1)
	prompt sTempList, "Select temperature/s:" POPUP sAllTemps
	doPrompt "Which temperature would you like to plot?", sTempList
	if (V_Flag)
		return -1
	endif		
 end
//Add option to add the fit for the data

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function ZGamry_Interpolate()
	string sProjectSource = COMBI_StringPrompt("","Project to get from:",COMBI_Projects(),"","")
	string sProjectDestination = COMBI_StringPrompt("","Project to add to:",COMBI_Projects(),"","")
	string sSourceLibrary = COMBI_LibraryPrompt(sProjectSource, ";", "Library to get from:", 0, 0, 0, 1)
	string sLibraryDataTypes = Combi_TableList(sProjectSource, 1, sSourceLibrary, "DataTypes")
	string sSelectedDataTypes = COMBI_UserOptionSelect(sLibraryDataTypes, "", sTitle="Select data types", sDescription="Select data types to interpolate")
	int i
	for(i = 0; i < itemsInList(sSelectedDataTypes); i += 1)
		COMBI_ScalarInterpolation(sProjectSource,sProjectDestination,sSourceLibrary,stringFromList(i, sSelectedDataTypes),"PolyFit", 0)
	endfor
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Calculates values indicated by model for each sample, temperature, and frequency
//Adds calculated values to the impedance data wave
Function ZGamry_CalculateECMFitData()
	
	//instrument name
	string sInstrument = "ZGamry"
	
	//Choose project
	string sProject = Combi_ChooseInstrumentProject()
	
	//Select library 
	string sLibrary, sAirCond 
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Which library would you like to plot?", sLibrary, sAirCond
	if (V_Flag)
		return -1
	endif	 
	
	//Access ZData wave for this library
	wave wZDataWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":ImpedanceData_" + sAirCond
	
	//get model name
	string sModelName
	prompt sModelName, "Select model:" POPUP Combi_GetInstrumentString(sInstrument, "ECMFitModels", "COMBIgor")
	doPrompt "Get model", sModelName	
	if (V_Flag)
		return -1
	endif	 
		
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	
	//add dimensions to hold fit data and add labels
	if(FindDimLabel(wImpedanceData, 2, "Zreal_" + sModelName)==-2)
		redimension/N=(-1, -1, dimSize(wImpedanceData, 2) + 1,-1) wImpedanceData
		SetDimLabel 2, dimSize(wImpedanceData, 2) - 1, $"Zreal_"+sModelName, wImpedanceData
	endif
	if(FindDimLabel(wImpedanceData, 2, "MinusZimag_" + sModelName)==-2)
		redimension/N=(-1, -1, dimSize(wImpedanceData, 2) + 1,-1) wImpedanceData
		SetDimLabel 2, dimSize(wImpedanceData, 2) - 1, $"MinusZimag_"+sModelName, wImpedanceData
	endif	
	if(FindDimLabel(wImpedanceData, 2, "ZModFit_" + sModelName)==-2)
		redimension/N=(-1, -1, dimSize(wImpedanceData, 2) + 1,-1) wImpedanceData
		SetDimLabel 2, dimSize(wImpedanceData, 2) - 1, $"ZModFit_"+sModelName, wImpedanceData
	endif	
	if(FindDimLabel(wImpedanceData, 2, "ZPhzFit_" + sModelName)==-2)
		redimension/N=(-1, -1, dimSize(wImpedanceData, 2) + 1,-1) wImpedanceData
		SetDimLabel 2, dimSize(wImpedanceData, 2) - 1, $"ZPhzFit_"+sModelName, wImpedanceData
	endif	
	
	//define suffix of fit parameter waves and create a list of all 
	string sFitSuffix = "_" + sAirCond + "_" + sModelName
	setDataFolder $sLibraryPath
	string sFitWaveList = WaveList("*"+sFitSuffix, ";","")
	
	//create wave to hold fit parameters for each spectrum 
	string sFitParamsWaveName = "wThisFitParams"
	string sFitParamsPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sFitParamsWaveName
	Make/O/N=(itemsInList(sFitWaveList) - 1) $sFitParamsWaveName 
	wave wThisFitParams = $sFitParamsPath
	
	//get list of fit parameters
	string sParamList = COMBI_GetInstrumentString("ZGamry", sModelName + "_Parameters", "COMBIgor")
	
	//assign fit parameters as dimension labels on parameter wave
	variable i
	string sParam
	for(i = 0; i < itemsInList(sParamList); i += 1)
		setDimLabel 0, i, $stringFromList(i, sParamList), wThisFitParams
	endfor
		
	//define loop variables
	variable iSample, iTemp, iFreq
		
	//loop through all samples
	for(iSample = 0; iSample < DimSize(wImpedanceData, 0); iSample +=1)
		
		//loop through temperatures 
		for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp +=1)
			
			//get fit model 
			string sFitModel = Combi_GetInstrumentString("ZGamry", sModelName + "_Model", "COMBIgor")
			
			//reset fit parameters
			wThisFitParams[]=0
			string sTemp = getDimLabel(wImpedanceData, 3, iTemp) 			
			variable iParam, iParamToCheck
			string sThisParam, sParamToCheck, sThisParamWavePath
			
			//string model for extracting variable names from fit wave names
			string expr="([[:ascii:]]*)" + sFitSuffix
			//clear wThisFitParams wave
			//wThisFitParams[]=""
			//wave wThisParamWave
			
			//find parameters and add to parameter wave
			for(iParam = 0; iParam < itemsInList(sParamList); iParam += 1)
				sThisParam = stringFromList(iParam, sParamList)
				for(iParamToCheck = 0; iParamToCheck < itemsInList(sFitWaveList); iParamToCheck += 1)
					SplitString/E=(expr) stringFromList(iParamToCheck, sFitWaveList), sParamToCheck
					if(stringMatch(sParamToCheck, sThisParam) && stringMatch(sParamToCheck, "!Goodness_of_Fit"))
						sThisParamWavePath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+stringFromList(iParamToCheck, sFitWaveList)
						wave wThisParamWave = $sThisParamWavePath
						variable vThisDimIndex = findDimLabel(wThisParamWave, 1, sTemp)
						if(findDimLabel(wThisParamWave, 1, sTemp) != -2)
							wThisFitParams[%$sThisParam] = wThisParamWave[iSample][%$sTemp]
						endif
					elseif(stringMatch(sParamToCheck, "Goodness_of_Fit"))
						iParamToCheck = iParamToCheck + 1
					endif
				endfor
			endfor
			
			//update fit model with values from this fit
			for(iParam = itemsInList(sParamList) - 1; iParam >= 0 ; iParam -= 1)
				sThisParam = stringFromList(iParam, sParamList)
				sFitModel = replaceString(sThisParam, sFitModel, num2str(wThisFitParams[%$sThisParam]))
			endfor
			
			variable/C vZ
			string sThisFitModel
			
			//loop through all frequencies
			variable vRow = 0
			for(iFreq = 0; iFreq < DimSize(wImpedanceData, 1); iFreq += 1)
				//calculate model value at each frequency
				if(wImpedanceData[iSample][iFreq][%Freq_Hz][%$sTemp] !=0)
					sThisFitModel = replaceString("omega", sFitModel, num2str(wImpedanceData[iSample][iFreq][%Freq_Hz][%$sTemp]))
					Execute "Variable/G/C V_Z="+sThisFitModel
					NVAR V_Z
					vZ=V_Z
					killvariables V_Z
					//add calculated values to data wave
					wImpedanceData[iSample][iFreq][%$"Zreal_"+sModelName][%$sTemp] = real(vZ)
					wImpedanceData[iSample][iFreq][%$"MinusZimag_"+sModelName][%$sTemp] = -1*imag(vZ)
					wImpedanceData[iSample][iFreq][%$"ZModFit_"+sModelName][%$sTemp] = ((real(vZ))^2+(-1*imag(vZ))^2)^0.5				
					wImpedanceData[iSample][iFreq][%$"ZPhzFit_"+sModelName][%$sTemp] = atan2(imag(vZ), real(vZ))*180/PI
				endif
			endfor
		endfor
	endfor
	SetDataFolder root:	
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//Makes a Nyquist plot from the impedance data wave
//Shows fit, if directed by user
//This function uses the Sample wave to correlate the sample number entered by the user to the appropriate data
//If a sample has been rotated during characterization, ensure that the Sample wave matches the standard grid
Function ZGamry_PlotNyquist(sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend)
	
	//declare function parameters
	string sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend
		
	//get data wave and sample wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	wave wSampleWave = $sLibraryPath + "Sample"
	string sSampleName = getDimLabel(wSampleWave, 0, str2num(sSample) - 1)
	//string sSampleIndex = num2str(wSampleWave[str2num(sSample) - 1])
	variable vSampleIndex = wSampleWave[%$sSampleName] - 1
	
	//if fit is required, check that the dimension labels exist and that there is data
	if(stringMatch(bShowFit, "Yes"))
		if(FindDimLabel(wImpedanceData, 2, "Zreal_" + sModelName)==-2)
			DoAlert/T="COMBIgor error." 0,"Zreal_" + sModelName + " data has not been defined for this sample."
			setdatafolder root:
			return -1
		endif
	
		if(FindDimLabel(wImpedanceData, 2, "MinusZimag_" + sModelName) == -2)
			DoAlert/T="COMBIgor error." 0,"MinusZimag_" + sModelName + " data has not been defined for this sample."
			setdatafolder root:
			return -1
		endif
	endif
	
	//make sure the data exists
	if(FindDimLabel(wImpedanceData, 3, sTemp) == -2)
		DoAlert/T="COMBIgor error." 0,"Data for this temperature does not exist for this sample."
		setdatafolder root:
		return -1
	endif
	
	//make trace name roots
	string sDataTraceName = "NyData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	string sFitTraceName = "NyFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	
	//create display path
	string sDisplayPath = "root:Packages:COMBIgor:DisplayWaves:"
	
	//DISPLAY CASE
	if(stringMatch(sDisplayAppend, "Display"))
		string sDataWave = "NyData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		string sFitWave = "NyFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	
		SetDataFolder root:Packages:COMBIgor:
		NewDataFolder/O/S DisplayWaves
		variable vOGDimSize = 1
		
		//make data and fit wave, as required
		if(waveExists($sDisplayPath + sDataWave)==0)
			Make/N=(1, 2)/O $sDataWave		
		endif
		wave wDataPlottingWave = $sDisplayPath + sDataWave
		if(stringMatch(bShowFit, "Yes"))
			if(waveExists($sDisplayPath + sFitWave)==0)
				Make/N=(1, 2)/O $sFitWave		
			endif	
			wave wFitPlottingWave = $sDisplayPath + sFitWave
		endif
		wave wDataPlottingWave = $sDisplayPath + sDataWave
		
		//make window name
		string sWindowName = "NyData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		GetWindow/Z $sWindowName active
		if(V_Flag==0)//no error because plot existed, try again with incremented plot number
			int iPlotNum = 0
			do
				sWindowName = "NyData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond + num2str(iPlotNum)
				GetWindow/Z $sWindowName active 
				iPlotNum+=1
			while(V_Flag==0)//no error because plot existed, try again with increased plot number
		endif
		
	//APPEND CASE
	elseif(stringMatch(sDisplayAppend, "Append"))
		
		//get window name
		sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
		
		//get trace names from window
		string sTraceNames = TraceNameList(sWindowName, ";", 3)
		int iTraceNum = 0
		int i
		for(i = 0; i < itemsInLIst(sTraceNames); i += 1)	
			if(stringMatch(stringFromList(i, sTraceNames), sDataTraceName))
				sDataTraceName = sDataTraceName + num2str(iTraceNum)
				iTraceNum += 1
			endif
		endfor
		
		//find names of data and fit traces
		wave wDataPlottingWave = waveRefIndexed(sWindowName, 0, 2)
		wave wFitPlottingWave = waveRefIndexed(sWindowName, 1, 2)
	endif
	
	for(i = 0; i < dimSize(wDataPlottingWave, 0); i += 1)
		if(numType(wDataPlottingWave[i][0]) != 2)
			vOGDimSize = i + 1
		endif
	endfor
	
	for(i = 0; i < dimSize(wImpedanceData, 1); i += 1)
		if(wImpedanceData[str2num(sSample)-1][i][%$"Zimag_ohm"][%$sTemp] != 0)
			variable vNewRows = i + 1
		endif
	endfor
	
	//Redimension data wave to create rows for new data and populate
	//Fix this to use sample wave, rather than sSample to find index of data wave
	Redimension/N=(vOGDimSize + vNewRows, -1) wDataPlottingWave	
	
	for(i = vOGDimSize; i < dimSize(wDataPlottingWave, 0); i += 1)
		wDataPlottingWave[i][1]=-1*wImpedanceData[vSampleIndex][i - vOGDimSize][%$"Zimag_ohm"][%$sTemp]
		wDataPlottingWave[i][0]=wImpedanceData[vSampleIndex][i - vOGDimSize][%$"Zreal_ohm"][%$sTemp]	
		//wDataPlottingWave[i][1]=-1*wImpedanceData[str2num(sSample)-1][i - vOGDimSize][%$"Zimag_ohm"][%$sTemp]
		//wDataPlottingWave[i][0]=wImpedanceData[str2num(sSample)-1][i - vOGDimSize][%$"Zreal_ohm"][%$sTemp]	
	endfor	
			
	//why would it ever be = 0?! Fix this, if needed...especially for fit data case.
	for(i=0; i < dimSize(wDataPlottingWave, 0); i += 1)
		if(wDataPlottingWave[i][0] == 0)
			wDataPlottingWave[i][0] = nan
			wDataPlottingWave[i][1] = nan
		endif
	endfor

	//if fit is requested, make and populate fit wave
	if(stringMatch(bShowFit, "Yes"))
	
		Redimension/N=(vOGDimSize + vNewRows, -1) wFitPlottingWave	
	
		for(i = vOGDimSize; i < dimSize(wFitPlottingWave, 0); i += 1)
			wFitPlottingWave[i][1]=wImpedanceData[vSampleIndex][i - vOGDimSize][%$"MinusZimag_" + sModelName][%$sTemp]
			wFitPlottingWave[i][0]=wImpedanceData[vSampleIndex][i - vOGDimSize][%$"Zreal_" + sModelName][%$sTemp]	
			//wFitPlottingWave[i][1]=wImpedanceData[str2num(sSample)-1][i - vOGDimSize][%$"MinusZimag_" + sModelName][%$sTemp]
			//wFitPlottingWave[i][0]=wImpedanceData[str2num(sSample)-1][i - vOGDimSize][%$"Zreal_" + sModelName][%$sTemp]	
		endfor
	
		//eliminate 0 values
		for(i=0; i < dimSize(wFitPlottingWave, 0); i += 1)
			if(wFitPlottingWave[i][0] == 0)
				wFitPlottingWave[i][0] = nan
				wFitPlottingWave[i][1] = nan
			endif
		endfor
	endif

	//make plot
	if(stringMatch(sDisplayAppend, "Display"))
		Display wDataPlottingWave[vOGDimSize, DimSize(wDataPlottingWave, 0) - 1][1]/TN=$sDataTraceName vs wDataPlottingWave[vOGDimSize, DimSize(wDataPlottingWave, 0) - 1][0] as sWindowName
	elseif(stringMatch(sDisplayAppend, "Append"))
		AppendToGraph wDataPlottingWave[vOGDimSize, DimSize(wDataPlottingWave, 0) - 1][1]/TN=$sDataTraceName vs wDataPlottingWave[vOGDimSize, DimSize(wDataPlottingWave, 0) - 1][0]
	endif
	//AppendToGraph wFitPlottingWave[vOGDimSize, DimSize(wFitPlottingWave, 0) - 1][1]/TN=$sFitTraceName vs wFitPlottingWave[vOGDimSize, DimSize(wFitPlottingWave, 0) - 1][0]
	ModifyGraph mode($sDataTraceName)=3, marker($sDataTraceName)=19
	ModifyGraph rgb($sDataTraceName)=(1,39321,39321)
	
	//append Nyquist fit
	if(stringMatch(bShowFit, "Yes"))
		//sWindowName = "FitTrace__Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		AppendToGraph wFitPlottingWave[vOGDimSize, DimSize(wFitPlottingWave, 0) - 1][1]/TN=$sFitTraceName vs wFitPlottingWave[vOGDimSize, DimSize(wFitPlottingWave, 0) - 1][0]
		ModifyGraph rgb($sFitTraceName)=(0,0,0)
		ModifyGraph lsize($sFitTraceName)=3
	endif
	
	//SetWindow sWindowName hook(kill)=COMBIDispaly_KillPlotData
	
	setDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ZGamry_PlotNyquistwPrompts()
	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string bShowFit 
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt bShowFit, "Show fits?" POPUP "Yes;No"
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond, bShowFit
	if (V_Flag)
		return -1
	endif	
	
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	
	//get sample wave
	wave wSampleWave = $sLibraryPath + "Sample"
	if(stringMatch(bShowFit, "Yes"))
		//make list of possible fit models
		string sModelList="", sFitSuffix, sDataType
		variable iThisDataType
		string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
		for(iThisDataType = 0; iThisDataType < dimSize(wImpedanceData, 2); iThisDataType += 1)
			splitString/E=expr getDimLabel(wImpedanceData, 2, iThisDataType), sDataType, sFitSuffix 
			if(stringMatch(sDataType, "MinusZimag"))
				sModelList = addListItem(sFitSuffix, sModelList)
			endif
		endfor
		
		if(stringMatch(sModelList, ""))
			DoAlert/T="COMBIgor error." 0,"No fit data available! Calculate fit data and try again."
			return -1
		endif
			
		//choose fit model to display
		string sModelName
		prompt sModelName, "Select model:" POPUP sModelList
		doPrompt "Model to display (only models with calculated data will be shown):", sModelName
		if (V_Flag)
			return -1
		endif	 	
	else
		sModelName = ""
	endif	
	
	string sSample
	prompt sSample, "Input contact number (indexed from 1):" 
	doPrompt "Contact number", sSample
	if (V_Flag)
		return -1
	endif	
		
	//make temp list
	string sTempList = ""
	
	variable iTemp
	for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
		string sThisTemp = getDimLabel(wImpedanceData, 3, iTemp)
		sTempList = sTempList + ";"+sThisTemp
	endfor
	
	string sTemp
	prompt sTemp, "Select measurement temperature:" POPUP sTempList
	doPrompt "Temperature", sTemp
	if (V_Flag)
		return -1
	endif	 	 	
	
	string sDisplayAppend
	prompt sDisplayAppend, "Display new plot or append to existing?" POPUP "Display;Append"
	doPrompt "Display/Append", sDisplayAppend
	if (V_Flag)
		return -1
	endif	 
	
	ZGamry_PlotNyquist(sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend)
	Print "ZGamry_PlotNyquist(\"" + sProject +"\",\""+ sLibrary +"\",\""+ sAirCond +"\",\""+ sModelName +"\",\""+ bShowFit +"\",\""+ sSample +"\",\""+ sTemp +"\",\""+ sDisplayAppend + "\")"
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Plots all Nyquist plots and fits and saves them automatically to the folder the user selects
Function ZGamry_PlotAndSaveAllNyquist()
		
	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string bShowFit 
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt bShowFit, "Show fits?" POPUP "Yes;No"
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond, bShowFit
	if (V_Flag)
		return -1
	endif	
	
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	
	//get sample wave
	wave wSampleWave = $sLibraryPath + "Sample"
	if(stringMatch(bShowFit, "Yes"))
		//make list of possible fit models
		string sModelList="", sFitSuffix, sDataType
		variable iThisDataType
		string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
		for(iThisDataType = 0; iThisDataType < dimSize(wImpedanceData, 2); iThisDataType += 1)
			splitString/E=expr getDimLabel(wImpedanceData, 2, iThisDataType), sDataType, sFitSuffix 
			if(stringMatch(sDataType, "MinusZimag"))
				sModelList = addListItem(sFitSuffix, sModelList)
			endif
		endfor
		
		if(stringMatch(sModelList, ""))
			DoAlert/T="COMBIgor error." 0,"No fit data available! Calculate fit data and try again."
			return -1
		endif
			
		//choose fit model to display
		string sModelName
		prompt sModelName, "Select model:" POPUP sModelList
		doPrompt "Model to display", sModelName
		if (V_Flag)
			return -1
		endif	 	
	else
		sModelName = ""
	endif	
	
	//select path for saving
 	string sPathToSave = Combi_ExportPath("New")
 	NewPath/O/Q pPathToSave, sPathToSave 
	
	variable iSample, iTemp
	string sTemp
	//for all samples
	for(iSample = 0; iSample < dimSize(wImpedanceData, 0); iSample += 1)
		string sSampleName = getDimLabel(wSampleWave, 0, iSample)
		string sSample = num2str(iSample + 1)
		//for all temps
		for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
			sTemp = getDimLabel(wImpedanceData, 3, iTemp)
			string sDisplayAppend = "Display"
			ZGamry_PlotNyquist(sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend)
			string sDataWave = "NyData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			string sFitWave = "NyFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			string sDisplayPath = "root:Packages:COMBIgor:DisplayWaves:"
			wave wDataPlottingWave = $sDisplayPath + sDataWave	
			wave wFitPlottingWave = $sDisplayPath + sFitWave
			SavePICT/O/P=pPathToSave as "Nyquist_" + sModelName + "_" + sSampleName + "_" + sLibrary + "_" + sTemp
			string sWindowName = "NyData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			doWindow/K kwTopWin
			killWaves/Z wDataPlottingWave
			killWaves/Z wFitPlottingWave
			//SetWindow $sWindowName hook(kill)=COMBIDispaly_KillPlotData
		endfor
	endfor
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Calculate Rp (vector wave)
function ZGamry_ASRsetup()

	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//Choose library
	string sLibrary
	//Remove FromMappingGrid from list
	string sAllLibraries = RemoveFromList("FromMappingGrid", COMBI_TableList(sProject, 2, "All", "Libraries"))
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	doPrompt "Choose library to calculate ASR", sLibrary
	if (V_Flag)
		return -1
	endif	
	
	//Select data types to use for calculation
	string sWave1//, sWave2
	variable vArea
	string sAllDataTypes = COMBI_TableList(sProject, 2, sLibrary, "DataTypes")
	prompt sWave1, "Select resistance data type:" POPUP sAllDataTypes
	prompt vArea, "Enter contact area:" 
	//prompt sWave2, "Select second wave:" POPUP sAllDataTypes
	
	doPrompt "Choose waves to calculate polarization resistance", sWave1, vArea
	if (V_Flag)
		return -1
	endif	
	
	ZGamry_CalculateASR(sProject, sLibrary, sWave1, num2str(vArea))	
	Print ("ZGamry_CalculateASR(\""+sProject+"\",\""+ sLibrary+"\",\""+sWave1+"\",\""+num2str(vArea)+"\")")	
	
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function ZGamry_CalculateASR(sProject, sLibrary, sWave1, sArea)	
	
	//declare parameters 
	string sProject, sLibrary, sWave1, sArea
	variable vArea = str2num(sArea)

	//Retrieve waves
	wave wWave1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave1
	//wave wWave2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWave2

	//Make polarization resistance wave 
	string expr="([[:alpha:]]*)([[:digit:]]*)_([[:ascii:]]*)"
	string sToDrop1, sToDrop2, sDescriptor
	SplitString/E=(expr) sWave1, sToDrop1, sToDrop2, sDescriptor
	string sASRWave = "ASR_" + sDescriptor
	SetDataFolder $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":"
	variable vNumRows =  str2num(Combi_GetGlobalString("vTotalSamples", sProject))
	variable vNumCols = dimSize(wWave1, 1)
	Make/O/N=(vNumRows, vNumCols) $sASRWave 
	wave wASRWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sASRWave
	
	//Set dimension labels of columns of new wave equal to dimension labels of one of the source waves
	CopyDimLabels/Cols = 1 wWave1, wASRWave
	
	//Do math
	wASRWave[][] = wWave1[p][q] * vArea
	SetDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ZGamry_SiftFitData()
	
	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string bShowFit 
	string sAllLibraries = "All;" + COMBI_TableList(sProject, 0, "All", "Libraries")
	//prompt bShowFit, "Show fits?" POPUP "Yes;No"
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond
	if (V_Flag)
		return -1
	endif	
	
	//select tolerance for fit
	variable vPercentTolerance
	prompt vPercentTolerance, "Enter tolerance (as a decimal):"
	doPrompt "Tolerance value", vPercentTolerance
	if (V_Flag)
		return -1
	endif	
	
	//select fraction of points within tolerance
	variable vGoodFitThreshold
	prompt vGoodFitThreshold, "Enter fraction of points (as a decimal) that must fall within tolerance:"
	doPrompt "Fraction within tolerance:", vGoodFitThreshold
	if (V_Flag)
		return -1
	endif
	
	variable iSample, iTemp
	string sTemp
	
	string sModelList = Combi_GetInstrumentString("ZGamry", "ECMFitModels", "COMBIgor")
		
	//choose fit model to display
	string sModelName
	prompt sModelName, "Select model:" POPUP sModelList
	doPrompt "Model to display", sModelName
	if (V_Flag)
		return -1
	endif	 

	//choose fit model to display
	//variable vMaxRp
	//prompt vMaxRp, "Enter max polarization resistance:"
	//doPrompt "Rp", vMaxRp
	//if (V_Flag)
	//	return -1
	//endif	
	
	//choose variable to sift
	string sAllDataTypes = COMBI_TableList(sProject, -3, sLibrary, "DataTypes")
	string sSelectedDataType, sFitSuffix
	prompt sSelectedDataType, "Select data type:" POPUP sAllDataTypes
	doPrompt "Data type to sift", sSelectedDataType
	if (V_Flag)
		return -1
	endif
	string sVarAbb
	string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
	splitString/E=expr sSelectedDataType, sVarAbb, sFitSuffix
	
	//make list of libraries to sift
	int i
	string sLibraryList = "", sDataType
	
	//make list of libraries with impedance data sets
	if(stringMatch(sLibrary, "All"))
		for(i = 2; i < ItemsinList(sAllLibraries)+ 1; i += 1)
			//get data wave
			string sThisLibrary = stringFromList(i, sAllLibraries)
			string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sThisLibrary + ":" 
			wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
			if(waveExists(wImpedanceData)==0)
				doAlert/T="Data has not been loaded." 1, "Load raw impedance data?"
				if(V_flag == 1)
					ZGamry_LoadRawZData()
				else
					return -1
				endif
			endif
			//if(stringMatch(bShowFit, "Yes"))
			variable iThisDataType
			for(iThisDataType = 0; iThisDataType < dimSize(wImpedanceData, 2); iThisDataType += 1)
				splitString/E=expr getDimLabel(wImpedanceData, 2, iThisDataType), sDataType, sFitSuffix 
				if(stringMatch(sDataType, "MinusZimag"))
				//get sample wave
				wave wSampleWave = $sLibraryPath + "Sample"
				//for all temps
				for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
					sTemp = getDimLabel(wImpedanceData, 3, iTemp)
					string sGoodFits = "ZFits_" + sTemp + "C_T" + num2str(vPercentTolerance * 100) + "_F" + num2str(vGoodFitThreshold * 100)
					//make wave
					SetDataFolder $sLibraryPath
					Make/T/O/N=(dimSize(wImpedanceData, 0)) $sGoodFits
					wave/T wGoodFits = $sLibraryPath + sGoodFits
					//wGoodFits[0] = "nan"
					SetDataFolder root:
					//for all samples
					for(iSample = 0; iSample < dimSize(wImpedanceData, 0); iSample += 1)
						string sSampleName = getDimLabel(wSampleWave, 0, iSample)
						string sSample = num2str(iSample + 1)

						//sift data
						variable vCounter = 0
							for(i = 0; i < dimSize(wImpedanceData, 1); i += 1)
								variable vMinusImagTolerance = vPercentTolerance * wImpedanceData[str2num(sSample)-1][i][%$"Zimag_ohm"][%$sTemp]
								variable vMinusImagValue = -1*wImpedanceData[str2num(sSample)-1][i][%$"Zimag_ohm"][%$sTemp]
								variable vRealTolerance = vPercentTolerance * wImpedanceData[str2num(sSample)-1][i][%$"Zreal_ohm"][%$sTemp]
								variable vRealValue = wImpedanceData[str2num(sSample)-1][i][%$"Zreal_ohm"][%$sTemp]
								variable vMinusImagFitValue = wImpedanceData[str2num(sSample)-1][i][%$"MinusZimag_" + sModelName][%$sTemp]
								variable vRealFitValue = wImpedanceData[str2num(sSample)-1][i][%$"Zreal_" + sModelName][%$sTemp]
								if(wImpedanceData[str2num(sSample)-1][i][%$"MinusZimag_" + sModelName][%$sTemp] > vMinusImagValue - vMinusImagTolerance && wImpedanceData[str2num(sSample)-1][i][%$"MinusZimag_" + sModelName][%$sTemp] < vMinusImagValue + vMinusImagTolerance&& wImpedanceData[str2num(sSample)-1][i][%$"Zreal_" + sModelName][%$sTemp] > vRealValue - vrealTolerance && wImpedanceData[str2num(sSample)-1][i][%$"Zreal_" + sModelName][%$sTemp] < vRealValue + vrealTolerance)
									//wSiftedFitPlottingWave[][1]=wImpedanceData[str2num(sSample)-1][i][%$"MinusZimag_" + sModelName][%$sTemp]
									//wSiftedFitPlottingWave[][0]=wImpedanceData[str2num(sSample)-1][i][%$"Zreal_" + sModelName][%$sTemp]	
									vCounter = vCounter + 1
								endif
							endfor
							if(vCounter > vGoodFitThreshold*dimSize(wImpedanceData, 1))
								wGoodFits[dimSize(wGoodFits, 0) - 1] = sSampleName
							endif
						endfor
						string sSiftedVar = sVarAbb + "_" + sTemp +"_Sifted_" + sAirCond
						string sOGVar = sVarAbb + "_" + sAirCond + "_"+ sModelName
						SetDataFolder $sLibraryPath
						Make/O/N=(dimSize(wGoodFits, 0)) $sSiftedVar
						wave wSiftedVar = $sLibraryPath + sSiftedVar
						wave wOGVar = $sLibraryPath + sOGVar
						SetDataFolder root:
						int j
						for(i = 0; i < dimSize(wGoodFits, 0); i += 1)
							for(j = 0; j < dimSize(wImpedanceData, 0); j += 1)
								if(stringMatch(GetDimLabel(wImpedanceData, 0, j), wGoodFits[i]))
									wSiftedVar[i] = wOGVar[j][%$sTemp]
								endif
							endfor
						endfor
					endfor
				endif
			endfor
		endfor
	else
		//if only one library is selected
		sThisLibrary = sLibrary
		
		//get data wave
		sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sThisLibrary + ":" 
		wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
		if(waveExists(wImpedanceData)==0)
			doAlert/T="Data has not been loaded." 1, "Load raw impedance data?"
			if(V_flag == 1)
				ZGamry_LoadRawZData()
				wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
			else
				return -1
			endif
		endif
		//wave wRpWave = $sLibraryPath + "Rp_" + sAirCond + "_" + sModelName 
		//loop through data
		expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
		for(iThisDataType = 0; iThisDataType < dimSize(wImpedanceData, 2); iThisDataType += 1)
			splitString/E=expr getDimLabel(wImpedanceData, 2, iThisDataType), sDataType, sFitSuffix 
			if(stringMatch(sDataType, "MinusZimag"))
				//get sample wave
				wave wSampleWave = $sLibraryPath + "Sample"
				//for all temps
				for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
					sTemp = getDimLabel(wImpedanceData, 3, iTemp)
					sGoodFits = "ZFits_" + sTemp + "C_T" + num2str(vPercentTolerance * 100) + "_F" + num2str(vGoodFitThreshold * 100)
					//make wave
					SetDataFolder $sLibraryPath
					Make/T/O/N=(dimSize(wImpedanceData, 0)) $sGoodFits
					wave/T wGoodFits = $sLibraryPath + sGoodFits
					//wGoodFits[0] = "nan"
					SetDataFolder root:
					//for all samples
					for(iSample = 0; iSample < dimSize(wImpedanceData, 0); iSample += 1)
						sSampleName = getDimLabel(wSampleWave, 0, iSample)
						sSample = num2str(iSample + 1)

						//sift data
						vCounter = 0
						
						//loops through frequencies
						for(i = 0; i < dimSize(wImpedanceData, 1); i += 1)
							vMinusImagTolerance = -1*vPercentTolerance * wImpedanceData[str2num(sSample)-1][i][%$"Zimag_ohm"][%$sTemp]
							vMinusImagValue = -1*wImpedanceData[str2num(sSample)-1][i][%$"Zimag_ohm"][%$sTemp]
							vRealTolerance = vPercentTolerance * wImpedanceData[str2num(sSample)-1][i][%$"Zreal_ohm"][%$sTemp]
							vRealValue = wImpedanceData[str2num(sSample)-1][i][%$"Zreal_ohm"][%$sTemp]
							vMinusImagFitValue = wImpedanceData[str2num(sSample)-1][i][%$"MinusZimag_" + sModelName][%$sTemp]
							vRealFitValue = wImpedanceData[str2num(sSample)-1][i][%$"Zreal_" + sModelName][%$sTemp]
							
							if(vMinusImagFitValue/vMinusImagValue < vPercentTolerance && vMinusImagFitValue/vMinusImagValue > 1/vPercentTolerance && vRealFitValue/vRealValue < vPercentTolerance && vRealFitValue/vRealValue > 1/vPercentTolerance)
								vCounter = vCounter + 1
							endif
						endfor
						
						if(vCounter > vGoodFitThreshold*dimSize(wImpedanceData, 1))
							wGoodFits[iSample] = sSampleName
						else
							wGoodFits[iSample] = " "
						endif
					endfor
					sSiftedVar = sVarAbb + "_" + sTemp +"_Sifted_" + sAirCond
				 	sOGVar = sVarAbb + "_" + sAirCond + "_"+ sModelName
					SetDataFolder $sLibraryPath
					Make/O/N=(dimSize(wGoodFits, 0)) $sSiftedVar
					wave wSiftedVar = $sLibraryPath + sSiftedVar
					wave wOGVar = $sLibraryPath + sOGVar
					SetDataFolder root:
					//if(dimSize(wGoodFits, 0) > 1 && stringMatch(wGoodFits[0], "!nan"))
						for(i = 0; i < dimSize(wGoodFits, 0); i += 1)
							string sContactNumber
							expr="Sample_([[:digit:]]*)"
							SplitString/E=(expr) wGoodFits[i], sContactNumber
							if(!stringMatch(wGoodFits[i], " "))
								wSiftedVar[i] = wOGVar[str2num(sContactNumber)-1][%$sTemp]
								setDimLabel 0, i, $wGoodFits[i], wSiftedVar
							else 
								wSiftedVar[i] = nan
							endif
						endfor
					//endif
				endfor				
			endif
		endfor
	endif
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ZGamry_SiftByChiSquared()
	
	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string sAllLibraries = "All;" + COMBI_TableList(sProject, 0, "All", "Libraries")
	//prompt bShowFit, "Show fits?" POPUP "Yes;No"
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond
	if (V_Flag)
		return -1
	endif	
	
	variable iSample, iTemp
	string sTemp
	
	string sModelList = Combi_GetInstrumentString("ZGamry", "ECMFitModels", "COMBIgor")
		
	//choose fit model to display
	string sModelName
	prompt sModelName, "Select model:" POPUP sModelList
	doPrompt "Model to display", sModelName
	if (V_Flag)
		return -1
	endif	 
	
	//choose variable to sift
	string sAllDataTypes = COMBI_TableList(sProject, -3, sLibrary, "DataTypes")
	string sSelectedDataType, sFitSuffix
	prompt sSelectedDataType, "Select data type:" POPUP sAllDataTypes
	doPrompt "Data type to sift", sSelectedDataType
	if (V_Flag)
		return -1
	endif
	
	//choose sifting variable
	string sSiftDataType
	prompt sSiftDataType, "Select sift data type:" POPUP sAllDataTypes
	doPrompt "Data type for conditional", sSiftDataType
	if (V_Flag)
		return -1
	endif
	
	//select tolerance for fit
	variable vMinChiSquared
	prompt vMinChiSquared, "Minimum value of sifting variable:"
	doPrompt "Goodness of fit", vMinChiSquared
	if (V_Flag)
		return -1
	endif	
	
	//string sVarAbb
	//string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
	//splitString/E=expr sSelectedDataType, sVarAbb, sFitSuffix
	
	//make list of libraries to sift
	int i
	string sLibraryList = "", sDataType
	
	string sThisLibrary = sLibrary		
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sThisLibrary + ":" 
	
	wave wSelectedData = $sLibraryPath + sSelectedDataType
	wave wSampleWave = $sLibraryPath + "Sample"
	SetDataFolder $sLibraryPath
	string sSiftData = sSelectedDataType + sTemp + "C_ChiSquared"//_"+num2str(vMinChiSquared)
	Make/O/N=(dimSize(wSelectedData, 0),dimSize(wSelectedData, 1)) $sSiftData
	wave wSiftData = $sLibraryPath + sSiftData
	//for all temps
	for(iTemp = 0; iTemp < dimSize(wSelectedData, 1); iTemp += 1)
		sTemp = getDimLabel(wSelectedData, 1, iTemp)
		for(i = 0; i < dimSize(wSelectedData, 1); i += 1)
			string sLabel = getDimLabel(wSelectedData, 1, i)
			setDimLabel 1, i, $sLabel, wSiftData
		endfor
		SetDataFolder root:
		
		//for all samples
		for(iSample = 0; iSample < dimSize(wSelectedData, 0); iSample += 1)
			string sSampleName = getDimLabel(wSampleWave, 0, iSample)
			string sSample = num2str(iSample + 1)
			
			int j
			//sift data
			//variable vCounter = 0
			for(i = 0; i < dimSize(wSelectedData, 1); i += 1)
				for(j = 0; j < dimSize(wSelectedData, 0); j += 1)
					if(wSelectedData[str2num(sSample)-1][%$sTemp] > vMinChiSquared)						
						wSiftData[j][%$sTemp] = wSelectedData[i][%$sTemp]
					endif
				endfor
			endfor
		endfor
	endfor
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ZGamry_CalculateChiSquared()
	
	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string sAllLibraries = "All;" + COMBI_TableList(sProject, 0, "All", "Libraries")
	//prompt bShowFit, "Show fits?" POPUP "Yes;No"
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond
	if (V_Flag)
		return -1
	endif	
	
	variable iSample, iTemp, i
	string sTemp
	
	string sModelList = Combi_GetInstrumentString("ZGamry", "ECMFitModels", "COMBIgor")
		
	//choose fit model to display
	string sModelName
	prompt sModelName, "Select model:" POPUP sModelList
	doPrompt "Model to display", sModelName
	if (V_Flag)
		return -1
	endif	 
	
//	//choose variable to sift
//	string sAllDataTypes = COMBI_TableList(sProject, -3, sLibrary, "DataTypes")
//	string sSelectedDataType, sFitSuffix
//	prompt sSelectedDataType, "Select data type:" POPUP sAllDataTypes
//	doPrompt "Data type to sift", sSelectedDataType
//	if (V_Flag)
//		return -1
//	endif
	
//	//choose sifting variable
//	string sSiftDataType
//	prompt sSiftDataType, "Select sift data type:" POPUP sAllDataTypes
//	doPrompt "Data type for conditional", sSiftDataType
//	if (V_Flag)
//		return -1
//	endif
	
//	//select tolerance for fit
//	variable vMinChiSquared
//	prompt vMinChiSquared, "Minimum value of sifting variable:"
//	doPrompt "Goodness of fit", vMinChiSquared
//	if (V_Flag)
//		return -1
//	endif	
	
	//string sVarAbb
	//string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
	//splitString/E=expr sSelectedDataType, sVarAbb, sFitSuffix
	
	//make list of libraries to sift
//	string sLibraryList = "", sDataType
	
	string sThisLibrary = sLibrary		
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sThisLibrary + ":" 
	
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_" + sAirCond
	wave wSampleWave = $sLibraryPath + "Sample"
	SetDataFolder $sLibraryPath
	
	//check to see that data has been calculated
	string sZmodMeas = "Zmod_ohm"
	string sZmodFit = "ZModFit_"+sModelName
	
	if(findDimLabel(wImpedanceData, 2, sZmodFit) == -2)
		doAlert/T="Need fit data.", 1, "Fit data has not been calculated. Calculate now?"
		if(V_flag == 1)
			ZGamry_CalculateECMFitData()
		else
			return -1
		endif
	endif
	
	//make wave to hold chi squared values
	string sChiSquaredData = sModelName + "_ChiSquared"//_"+num2str(vMinChiSquared)
	Make/O/N=(dimSize(wImpedanceData, 0),dimSize(wImpedanceData, 3)) $sChiSquaredData
	wave wChiSquaredData = $sLibraryPath + sChiSquaredData

	//for all temps
	for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
		sTemp = getDimLabel(wImpedanceData, 3, iTemp)
		
		//make temporary waves to hold data to calculate chi squared from
		string sMeasWave = sModelName + "_" + sTemp + "C_ZModMeas"//_"+num2str(vMinChiSquared)
		string sFitWave = sModelName + "_" + sTemp + "C_ZModFit"//_"+num2str(vMinChiSquared)
		Make/O/N=(dimSize(wImpedanceData, 0)) $sMeasWave
		Make/O/N=(dimSize(wImpedanceData, 0)) $sFitWave
		wave wMeasWave = $sLibraryPath + sMeasWave
		wave wFitWave = $sLibraryPath + sFitWave
		
		for(i = 0; i < dimSize(wImpedanceData, 3); i += 1)
			string sLabel = getDimLabel(wImpedanceData, 3, i)
			setDimLabel 1, i, $sLabel, wChiSquaredData
		endfor
		SetDataFolder root:
		
		//for all samples
		//for(iSample = 0; iSample < dimSize(wImpedanceData, 0); iSample += 1)
		for(iSample = 0; iSample < 3; iSample += 1)
			string sSampleName = getDimLabel(wSampleWave, 0, iSample)
			string sSample = num2str(iSample + 1)
			
			int j
			//sift data
			//variable vCounter = 0
			
			//clear temp waves
			wMeasWave[] = Nan
			wFitWave[] = Nan
			for(j = 0; j < dimSize(wImpedanceData, 1); j += 1)
				wMeasWave[j] = wImpedanceData[iSample][j][%$sZmodMeas][%$sTemp]
				wFitWave[j] = wImpedanceData[iSample][j][%$sZmodFit][%$sTemp]
			endfor
			statsChiTest wMeasWave, wFitWave
			
			//for all frequencies
			//for(i = 0; i < dimSize(wImpedanceData, 1); i += 1)
				//for all samples
				//for(j = 0; j < dimSize(wImpedanceData, 0); j += 1)
					//if(wImpedanceData[str2num(sSample)-1][%$sTemp] > vMinChiSquared)						
					//	wChiSquaredData[j][%$sTemp] = wImpedanceData[i][][][%$sTemp]
					//endif
			//	endfor
			//endfor
		endfor
	endfor
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//Makes a Bode plot from the impedance data wave
Function ZGamry_PlotBode(sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend, bPlotMod, bPlotPhase, bPlotTogether)
	
	//declare function parameters
	string sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend, bPlotMod, bPlotPhase, bPlotTogether
		
	//get data wave and sample wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	wave wSampleWave = $sLibraryPath + "Sample"
	string sSampleName = getDimLabel(wSampleWave, 0, str2num(sSample) - 1)
	
	//if fit is required, check that the dimension labels exist and that there is data
	if(stringMatch(bShowFit, "Yes"))
		if(FindDimLabel(wImpedanceData, 2, "ZModFit_" + sModelName)==-2)
			DoAlert/T="COMBIgor error." 0,"ZModFit_" + sModelName + " data has not been defined for this sample."
			setdatafolder root:
			return -1
		endif
	
		if(FindDimLabel(wImpedanceData, 2, "ZPhzFit_" + sModelName)==-2)
			DoAlert/T="COMBIgor error." 0,"ZPhzFit_" + sModelName + " data has not been defined for this sample."
			setdatafolder root:
			return -1
		endif
	endif

//make trace name roots
	string sModDataTraceName = "BodeModData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	string sPhaseDataTraceName = "BodePhaseData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	string sModFitTraceName = "BodeModFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	string sPhaseFitTraceName = "BodePhaseFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	
	//create display path
	string sDisplayPath = "root:Packages:COMBIgor:DisplayWaves:"
	
	//DISPLAY CASE
	if(stringMatch(sDisplayAppend, "Display"))
		string sModDataWave = "BodeModData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		string sModFitWave = "BodeModFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		string sPhaseDataWave = "BodePhaseData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		string sPhaseFitWave = "BodePhaseFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
	
		SetDataFolder root:Packages:COMBIgor:
		NewDataFolder/O/S DisplayWaves
		variable vModOGDimSize = 1
		variable vPhaseOGDimSize = 1
		
		//make modulus data wave
		if(stringMatch(bPlotMod, "Yes"))			
			if(waveExists($sDisplayPath + sModDataWave)==0)
				Make/N=(1, 2)/O $sModDataWave		
			elseif(waveExists($sDisplayPath + sModDataWave)==1)
				killWaves $sDisplayPath + sModDataWave
				Make/N=(1, 2)/O $sModDataWave		
			endif
			wave wModDataPlottingWave = $sDisplayPath + sModDataWave
		endif
		
		//make phase data wave
		if(stringMatch(bPlotPhase, "Yes"))		
			if(waveExists($sDisplayPath + sPhaseDataWave)==0)
				Make/N=(1, 2)/O $sPhaseDataWave	
			elseif(waveExists($sDisplayPath + sPhaseDataWave)==1)
				killWaves $sDisplayPath + sPhaseDataWave
				Make/N=(1, 2)/O $sPhaseDataWave	
			endif
			wave wPhaseDataPlottingWave = $sDisplayPath + sPhaseDataWave
		endif
		
		//make fit waves
		if(stringMatch(bShowFit, "Yes"))
			if(stringMatch(bPlotMod, "Yes"))			
				if(waveExists($sDisplayPath + sModFitWave)==0)
					Make/N=(1, 2)/O $sModFitWave		
				endif	
				wave wModFitPlottingWave = $sDisplayPath + sModFitWave
			endif
			if(stringMatch(bPlotPhase, "Yes"))			
				if(waveExists($sDisplayPath + sPhaseFitWave)==0)
					Make/N=(1, 2)/O $sPhaseFitWave		
				endif	
				wave wPhaseFitPlottingWave = $sDisplayPath + sPhaseFitWave
			endif
		endif
		
		int i
		for(i = 0; i < dimSize(wImpedanceData, 1); i += 1)
			if(wImpedanceData[str2num(sSample)-1][i][%$"Zmod_ohm"][%$sTemp] != 0)
				variable vNewRows = i + 1
			endif
		endfor
		
		//make window name
		string sModWindowTitle = "BodeModData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		GetWindow/Z $sModWindowTitle active
		if(V_Flag==0)//no error because plot existed, try again with incremented plot number
			int iModPlotNum = 0
			do
				sModWindowTitle = "BodeModData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond + num2str(iModPlotNum)
				iModPlotNum+=1
			while(V_Flag==0)//no error because plot existed, try again with increased plot number
		endif
		string sModWindowName = "Mod_Con" + sSample + "_" + sTemp + "_" + sAirCond + num2str(iModPlotNum)
		
		//make window name
		string sPhaseWindowTitle = "BodePhaseData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
		//GetWindow/Z $sPhaseWindowTitle active
		if(V_Flag==0)//no error because plot existed, try again with incremented plot number
			int iPhasePlotNum = 0
			do
				sPhaseWindowTitle = "BodePhaseData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond + num2str(iPhasePlotNum)
				iPhasePlotNum+=1
			while(V_Flag==0)//no error because plot existed, try again with increased plot number
		endif
		string sPhaseWindowName = "Phase_Con" + sSample + "_" + sTemp + "_" + sAirCond + num2str(iPhasePlotNum)
		
//	APPEND CASE
	elseif(stringMatch(sDisplayAppend, "Append"))
		for(i = 0; i < dimSize(wImpedanceData, 1); i += 1)
			if(wImpedanceData[str2num(sSample)-1][i][%$"Zmod_ohm"][%$sTemp] != 0)
				vNewRows = i + 1
			endif
		endfor		
		//Mod case
		if(stringMatch(bPlotMod, "Yes"))
			string sModWindowList = WinList("*Mod*",";","WIN:1")
			//string sModWindowName
			prompt sModWindowName, "Select modulus plot:" POPUP sModWindowList
			doPrompt "Which modulus plot?" sModWindowName
			if (V_Flag)
				return -1
			endif	
			//get traces
			string sModTraceNames = TraceNameList(sModWindowName, ";", 3)
			int iModTraceNum = 0
			for(i = 0; i < itemsInLIst(sModTraceNames); i += 1)	
				if(stringMatch(stringFromList(i, sModTraceNames), sModDataTraceName))
					sModDataTraceName = sModDataTraceName + num2str(iModTraceNum)
					iModTraceNum += 1
				endif
			endfor 
			wave wModDataPlottingWave = waveRefIndexed(sModWindowName, 0, 2)
			//redimension wave
			for(i = 0; i < dimSize(wModDataPlottingWave, 0); i += 1)
				if(numType(wModDataPlottingWave[i][0]) != 2)
					vModOGDimSize = i + 1
				endif
			endfor
		endif	
		
		//Phase case
		if(stringMatch(bPlotPhase, "Yes"))
			string sPhaseWindowList = WinList("*",";","WIN:1")
			//string sPhaseWindowName
			prompt sPhaseWindowName, "Select phase plot:" POPUP sPhaseWindowList
			doPrompt "Which phase plot?" sPhaseWindowName
			if (V_Flag)
				return -1
			endif	
			//get trace names from window
			//Phase
			string sPhaseTraceNames = TraceNameList(sPhaseWindowName, ";", 3)
			int iPhaseTraceNum = 0
			for(i = 0; i < itemsInLIst(sPhaseTraceNames); i += 1)	
				if(stringMatch(stringFromList(i, sPhaseTraceNames), sPhaseDataTraceName))
					sPhaseDataTraceName = sPhaseDataTraceName + num2str(iPhaseTraceNum)
					iPhaseTraceNum += 1
				endif
			endfor
			wave wPhaseDataPlottingWave = waveRefIndexed(sPhaseWindowName, 0, 2)
			//redimension wave
			for(i = 0; i < dimSize(wPhaseDataPlottingWave, 0); i += 1)
				if(numType(wPhaseDataPlottingWave[i][0]) != 2)
					vPhaseOGDimSize = i + 1
				endif
			endfor
		endif		
	endif



//	//why would it ever be = 0?! Fix this, if needed...especially for fit data case.
//	for(i=0; i < dimSize(wDataPlottingWave, 0); i += 1)
//		if(wDataPlottingWave[i][0] == 0)
//			wDataPlottingWave[i][0] = nan
//			wDataPlottingWave[i][1] = nan
//		endif
//	endfor

	//if fit is requested, make and populate fit wave
	//modulus fit case
	if(stringMatch(bShowFit, "Yes") && stringMatch(bPlotMod, "Yes"))
		Redimension/N=(vModOGDimSize + vNewRows, -1) wModFitPlottingWave		
		for(i = vModOGDimSize; i < dimSize(wModFitPlottingWave, 0); i += 1)
			wModFitPlottingWave[i][1]=wImpedanceData[str2num(sSample)-1][i - vModOGDimSize][%$"ZModFit_" + sModelName][%$sTemp]
			wModFitPlottingWave[i][0]=wImpedanceData[str2num(sSample)-1][i - vModOGDimSize][%$"freq_Hz"][%$sTemp]	
		endfor	
		//eliminate 0 values
		for(i=0; i < dimSize(wModFitPlottingWave, 0); i += 1)
			if(wModFitPlottingWave[i][0] == 0)
				wModFitPlottingWave[i][0] = nan
				wModFitPlottingWave[i][1] = nan
			endif
		endfor
	endif
	
	//phase fit case
	if(stringMatch(bShowFit, "Yes") && stringMatch(bPlotPhase, "Yes"))
		Redimension/N=(vPhaseOGDimSize + vNewRows, -1) wPhaseFitPlottingWave	
		for(i = vPhaseOGDimSize; i < dimSize(wPhaseFitPlottingWave, 0); i += 1)
			wPhaseFitPlottingWave[i][1]=wImpedanceData[str2num(sSample)-1][i - vPhaseOGDimSize][%$"ZPhzFit_" + sModelName][%$sTemp]
			wPhaseFitPlottingWave[i][0]=wImpedanceData[str2num(sSample)-1][i - vPhaseOGDimSize][%$"freq_Hz"][%$sTemp]	
		endfor
		//eliminate 0 values
		for(i=0; i < dimSize(wPhaseFitPlottingWave, 0); i += 1)
			if(wPhaseFitPlottingWave[i][0] == 0)
				wPhaseFitPlottingWave[i][0] = nan
				wPhaseFitPlottingWave[i][1] = nan
			endif
		endfor
	endif

	//redimension waves and add data
	if(stringMatch(bPlotPhase, "Yes"))
		Redimension/N=(vPhaseOGDimSize + vNewRows, -1) wPhaseDataPlottingWave	
		for(i = vPhaseOGDimSize; i < dimSize(wPhaseDataPlottingWave, 0); i += 1)
			wPhaseDataPlottingWave[i][1]=wImpedanceData[str2num(sSample)-1][i - vPhaseOGDimSize][%$"Zphz_∞"][%$sTemp]
			wPhaseDataPlottingWave[i][0]=wImpedanceData[str2num(sSample)-1][i - vPhaseOGDimSize][%$"freq_Hz"][%$sTemp]	
		endfor
	endif
	if(stringMatch(bPlotMod, "Yes"))
		Redimension/N=(vModOGDimSize + vNewRows, -1) wModDataPlottingWave	
		for(i = vModOGDimSize; i < dimSize(wModDataPlottingWave, 0); i += 1)
			wModDataPlottingWave[i][1]=wImpedanceData[str2num(sSample)-1][i - vModOGDimSize][%$"Zmod_ohm"][%$sTemp]
			wModDataPlottingWave[i][0]=wImpedanceData[str2num(sSample)-1][i - vModOGDimSize][%$"freq_Hz"][%$sTemp]	
		endfor	
	endif
	
	//make plot
	if(stringMatch(sDisplayAppend, "Display"))
		if(stringMatch(bPlotMod,"Yes"))
			Display/N=$sModWindowName wModDataPlottingWave[vModOGDimSize, DimSize(wModDataPlottingWave, 0) - 1][1]/TN=$sModDataTraceName vs wModDataPlottingWave[vModOGDimSize, DimSize(wModDataPlottingWave, 0) - 1][0] as sModWindowTitle
			ModifyGraph log(bottom)=1, log(left)=1
			Label left "Zmod (Ohms)"
			Label bottom "Frequency (Hz)"
			ModifyGraph lblMargin(left)=10
			ModifyGraph margin(bottom)=46
			ModifyGraph lblMargin(bottom)=5
			ModifyGraph mode=3,marker=19
		endif
		if(stringMatch(bPlotPhase,"Yes"))
			Display/N=$sPhaseWindowName wPhaseDataPlottingWave[vModOGDimSize, DimSize(wPhaseDataPlottingWave, 0) - 1][1]/TN=$sPhaseDataTraceName vs wPhaseDataPlottingWave[vPhaseOGDimSize, DimSize(wPhaseDataPlottingWave, 0) - 1][0] as sPhaseWindowTitle
			ModifyGraph log(bottom)=1
			Label left "Phase (deg)"
			Label bottom "Frequency (Hz)"
			ModifyGraph lblMargin(left)=10
			ModifyGraph margin(bottom)=46
			ModifyGraph lblMargin(bottom)=5
			ModifyGraph mode=3, marker=19
		endif
	elseif(stringMatch(sDisplayAppend, "Append"))
		if(stringMatch(bPlotMod,"Yes"))
			AppendToGraph/W=$sModWindowName wModDataPlottingWave[vModOGDimSize, DimSize(wModDataPlottingWave, 0) - 1][1]/TN=$sModDataTraceName vs wModDataPlottingWave[vModOGDimSize, DimSize(wModDataPlottingWave, 0) - 1][0]
		endif
		if(stringMatch(bPlotPhase,"Yes"))
			AppendToGraph/W=$sPhaseWindowName wPhaseDataPlottingWave[vPhaseOGDimSize, DimSize(wPhaseDataPlottingWave, 0) - 1][1]/TN=$sPhaseDataTraceName vs wPhaseDataPlottingWave[vPhaseOGDimSize, DimSize(wPhaseDataPlottingWave, 0) - 1][0]
		endif
	endif
	
	if(stringMatch(bShowFit, "Yes"))
		if(stringMatch(bPlotMod,"Yes"))
			AppendToGraph/W=$sModWindowName wModFitPlottingWave[vModOGDimSize, DimSize(wModFitPlottingWave, 0) - 1][1]/TN=$sModFitTraceName vs wModFitPlottingWave[vModOGDimSize, DimSize(wModFitPlottingWave, 0) - 1][0]
			ModifyGraph /W=$sModWindowName rgb($sModFitTraceName)=(0,0,0)
			ModifyGraph /W=$sModWindowName lsize($sModFitTraceName)=3
		endif
		if(stringMatch(bPlotPhase,"Yes"))
			AppendToGraph/W=$sPhaseWindowName wPhaseFitPlottingWave[vPhaseOGDimSize, DimSize(wPhaseFitPlottingWave, 0) - 1][1]/TN=$sPhaseFitTraceName vs wPhaseFitPlottingWave[vPhaseOGDimSize, DimSize(wPhaseFitPlottingWave, 0) - 1][0]
			ModifyGraph /W=$sPhaseWindowName rgb($sPhaseFitTraceName)=(0,0,0)
			ModifyGraph /W=$sPhaseWindowName lsize($sPhaseFitTraceName)=3
		endif
	endif
	
	//for plotting them together
//	bPlotTogether = "Yes"
//	if(stringMatch(bPlotTogether, "Yes"))
////		if(stringMatch(bPlotMod,"Yes"))
//			Display wModDataPlottingWave[vModOGDimSize, DimSize(wModDataPlottingWave, 0) - 1][1]/TN=$sModDataTraceName vs wModDataPlottingWave[vModOGDimSize, DimSize(wModDataPlottingWave, 0) - 1][0] as sModWindowTitle
//			ModifyGraph log(bottom)=1, log(left)=1
//			Label left "Zmod (Ohms)"
//			Label bottom "Frequency (Hz)"
//			ModifyGraph lblMargin(left)=10
//			ModifyGraph margin(bottom)=46
//			ModifyGraph lblMargin(bottom)=5
//			ModifyGraph mode=3,marker=19
////		endif
////		if(stringMatch(bPlotPhase,"Yes"))
//			AppendToGraph wPhaseDataPlottingWave[vModOGDimSize, DimSize(wPhaseDataPlottingWave, 0) - 1][1]/TN=$sPhaseDataTraceName vs wPhaseDataPlottingWave[vPhaseOGDimSize, DimSize(wPhaseDataPlottingWave, 0) - 1][0] 
//			//ModifyGraph log(bottom)=1
//			ReorderTraces /R sPhaseDataTraceName
//			Label left "Phase (deg)"
//			Label bottom "Frequency (Hz)"
//			ModifyGraph lblMargin(left)=10
//			ModifyGraph margin(bottom)=46
//			ModifyGraph lblMargin(bottom)=5
//			ModifyGraph mode=3,marker=19
//		endif
////	elseif(stringMatch(sDisplayAppend, "Append"))
////		AppendToGraph wDataPlottingWave[vOGDimSize, DimSize(wDataPlottingWave, 0) - 1][1]/TN=$sDataTraceName vs wDataPlottingWave[vOGDimSize, DimSize(wDataPlottingWave, 0) - 1][0]
	//endif
	
	setDataFolder root:
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function ZGamry_PlotBodewPrompts()

	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string bShowFit 
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt bShowFit, "Show fits?" POPUP "Yes;No" 
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond, bShowFit
	if (V_Flag)
		return -1
	endif	
	
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	
	//get sample wave
	wave wSampleWave = $sLibraryPath + "Sample"
	if(stringMatch(bShowFit, "Yes"))
		//make list of possible fit models
		string sModelList="", sFitSuffix, sDataType
		variable iThisDataType
		string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
		for(iThisDataType = 0; iThisDataType < dimSize(wImpedanceData, 2); iThisDataType += 1)
			splitString/E=expr getDimLabel(wImpedanceData, 2, iThisDataType), sDataType, sFitSuffix 
			if(stringMatch(sDataType, "MinusZimag"))
				sModelList = addListItem(sFitSuffix, sModelList)
			endif
		endfor
		
		if(stringMatch(sModelList, ""))
			DoAlert/T="COMBIgor error." 0,"No fit data available! Calculate fit data and try again."
			return -1
		endif
			
		//choose fit model to display
		string sModelName
		prompt sModelName, "Select model:" POPUP sModelList
		doPrompt "Model to display (only models with calculated data will be shown):", sModelName
		if (V_Flag)
			return -1
		endif	 	
	else
		sModelName = ""
	endif	
	
	string sSample
	prompt sSample, "Input contact number (indexed from 1):" 
	doPrompt "Contact number", sSample
	if (V_Flag)
		return -1
	endif	
		
	//make temp list
	string sTempList = ""
	
	variable iTemp
	for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
		string sThisTemp = getDimLabel(wImpedanceData, 3, iTemp)
		sTempList = sTempList + ";"+sThisTemp
	endfor
	
	string sTemp
	prompt sTemp, "Select measurement temperature:" POPUP sTempList
	doPrompt "Temperature", sTemp
	if (V_Flag)
		return -1
	endif	 	 	
	
	string sDisplayAppend
	prompt sDisplayAppend, "Display new plot or append to existing?" POPUP "Display;Append" 
	doPrompt "Display/Append", sDisplayAppend
	if (V_Flag)
		return -1
	endif	 
	
	string bPlotMod, bPlotPhase, bPlotTogether
	prompt bPlotMod, "Plot modulus vs. frequency?" POPUP "Yes;No" 
	prompt bPlotPhase, "Plot phase vs. frequency?" POPUP "Yes;No"
	prompt bPlotTogether, "Plot these two on same plot?" POPUP "No" //"Yes;No" yes case is not written yet
	doPrompt "Which plots should I make?", bPlotMod, bPlotPhase, bPlotTogether
	if (V_Flag)
		return -1
	endif	

	ZGamry_PlotBode(sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend, bPlotMod, bPlotPhase, bPlotTogether)
	Print "ZGamry_PlotBode(\"" + sProject +"\",\""+ sLibrary +"\",\""+ sAirCond +"\",\""+ sModelName +"\",\""+ bShowFit +"\",\""+ sSample +"\",\""+ sTemp +"\",\""+ sDisplayAppend + "\",\"" + bPlotMod + "\",\"" + bPlotPhase + "\",\"" + bPlotTogether +"\")"
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Plots all Nyquist plots and fits and saves them automatically to the folder the user selects
Function ZGamry_PlotAndSaveAllBode()
	
	//choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
		
	//choose library	
	string sLibrary, sAirCond
	string bShowFit 
	string sAllLibraries = COMBI_TableList(sProject, 0, "All", "Libraries")
	prompt bShowFit, "Show fits?" POPUP "Yes;No" 
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	prompt sAirCond, "Select air condition:" POPUP "Dry;Wet;NoFlow"
	doPrompt "Select library and air condition", sLibrary, sAirCond, bShowFit
	if (V_Flag)
		return -1
	endif	
	
	//get data wave
	string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" 
	wave wImpedanceData = $sLibraryPath + "ImpedanceData_"+sAirCond
	
	//get sample wave
	wave wSampleWave = $sLibraryPath + "Sample"
	if(stringMatch(bShowFit, "Yes"))
		//make list of possible fit models
		string sModelList="", sFitSuffix, sDataType
		variable iThisDataType
		string expr="([[:alpha:]]*)_" + "([[:ascii:]]*)"
		for(iThisDataType = 0; iThisDataType < dimSize(wImpedanceData, 2); iThisDataType += 1)
			splitString/E=expr getDimLabel(wImpedanceData, 2, iThisDataType), sDataType, sFitSuffix 
			if(stringMatch(sDataType, "MinusZimag"))
				sModelList = addListItem(sFitSuffix, sModelList)
			endif
		endfor
		
		if(stringMatch(sModelList, ""))
			DoAlert/T="COMBIgor error." 0,"No fit data available! Calculate fit data and try again."
			return -1
		endif
			
		//choose fit model to display
		string sModelName
		prompt sModelName, "Select model:" POPUP sModelList
		doPrompt "Model to display (only models with calculated data will be shown):", sModelName
		if (V_Flag)
			return -1
		endif	 	
	else
		sModelName = ""
	endif	
//	
//	string sSample
//	prompt sSample, "Input contact number (indexed from 1):" 
//	doPrompt "Contact number", sSample
//	if (V_Flag)
//		return -1
//	endif	

	string sPlotType
	prompt sPlotType, "Plot modulus or phase?" POPUP "Mod;Phase;Both" 
	//prompt bPlotPhase, "Plot phase vs. frequency?" POPUP "Yes;No"
	//prompt bPlotTogether, "Plot these two on same plot?" POPUP "No" //"Yes;No" yes case is not written yet
	doPrompt "Which plot should I make?", sPlotType
	if (V_Flag)
		return -1
	endif	
	
	string bPlotTogether = "No"
	if(stringMatch(sPlotType,"Mod"))
		string bPlotMod = "Yes"
		string bPlotPhase = "No"	
	elseif(stringMatch(sPlotType,"Phase"))
		bPlotMod = "No"
		bPlotPhase = "Yes"
	elseif(stringMatch(sPlotType,"Both"))
		bPlotMod = "Yes"
		bPlotPhase = "Yes"
	endif
	
	//select path for saving
 	string sPathToSave = Combi_ExportPath("New")
 	NewPath/O/Q pPathToSave, sPathToSave 
	
	variable iSample, iTemp
	string sTemp
	//for all samples
	for(iSample = 0; iSample < dimSize(wImpedanceData, 0); iSample += 1)
		string sSampleName = getDimLabel(wSampleWave, 0, iSample)
		string sSample = num2str(iSample + 1)
		//for all temps
		for(iTemp = 0; iTemp < dimSize(wImpedanceData, 3); iTemp += 1)
			sTemp = getDimLabel(wImpedanceData, 3, iTemp)
			string sDisplayAppend = "Display"
			ZGamry_PlotBode(sProject, sLibrary, sAirCond, sModelName, bShowFit, sSample, sTemp, sDisplayAppend, bPlotMod, bPlotPhase, bPlotTogether)
			string sModDataWave = "BodeModData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			string sPhaseDataWave = "BodePhaseData_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			//string sFitWave = "NyFit_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			string sDisplayPath = "root:Packages:COMBIgor:DisplayWaves:"
			wave wModDataPlottingWave = $sDisplayPath + sModDataWave	
			wave wPhasePlottingWave = $sDisplayPath + sPhaseDataWave
			SavePICT/O/P=pPathToSave as "Bode"+ sPlotType + sModelName + "_" + sSampleName + "_" + sLibrary + "_" + sTemp
			string sWindowName = "Bode" + sPlotType + "Data_Con"+ sSample + "_" + sLibrary + "_" + sTemp + "_" + sAirCond
			//killWindow $sWindowName
			doWindow/K kwTopWin
			//this is an inelegant way of killing both the modulus and phase plots, if both exist. It would be better to call the windows by name.
			if(stringMatch(bPlotMod,"Yes") && stringMatch(bPlotPhase,"Yes"))
				doWindow/K kwTopWin
			endif
			killWaves/Z wModDataPlottingWave
			killWaves/Z wModFitPlottingWave
			killWaves/Z wPhasePlottingWave
			killWaves/Z wPhaseFitPlottingWave
			//SetWindow $sWindowName hook(kill)=COMBIDispaly_KillPlotData
		endfor
	endfor
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Calculate characteristice frequency (vector wave)
function ZGamry_SortbyTimeConstant()

	//Choose project
	string sProject
	sProject = Combi_ChooseInstrumentProject()
	
	//Choose library
	string sLibrary
	//Remove FromMappingGrid from list
	string sAllLibraries = RemoveFromList("FromMappingGrid", COMBI_TableList(sProject, 2, "All", "Libraries"))
	prompt sLibrary, "Select library:" POPUP sAllLibraries
	doPrompt "Choose library to calculate characteristic frequency", sLibrary
	if (V_Flag)
		return -1
	endif	
	
	//Get number of resistances
	string sNumElem
	prompt sNumElem, "How many RC elements?"
	doPrompt "Select number of RC elements in equivalent circuit model", sNumElem
	if (V_Flag)
		return -1
	endif	
	
	variable vNumElem = str2num(sNumElem)
	if(vNumElem > 4)
		doAlert 0, "Sorry! Cannot handle more than 4 circuit elements right now..."
	endif
	
	//Select data types to use for calculation
	//MP need a more elegant solution for this
	string sWaveR1, sWaveY1, sWavea1, sWaveR2, sWaveY2, sWavea2, sWaveR3, sWaveY3, sWavea3
	string sWaveR4, sWaveY4, sWavea4
	string sAllDataTypes = COMBI_TableList(sProject,2, sLibrary, "DataTypes")
	prompt sWaveR1, "Select resistance wave:" POPUP sAllDataTypes
	prompt sWaveY1, "Select capacitance wave:" POPUP sAllDataTypes
	prompt sWavea1, "Select alpha wave:" POPUP sAllDataTypes
	prompt sWaveR2, "Select resistance wave:" POPUP sAllDataTypes
	prompt sWaveY2, "Select capacitance wave:" POPUP sAllDataTypes
	prompt sWavea2, "Select alpha wave:" POPUP sAllDataTypes
	prompt sWaveR3, "Select resistance wave:" POPUP sAllDataTypes
	prompt sWaveY3, "Select capacitance wave:" POPUP sAllDataTypes
	prompt sWavea3, "Select alpha wave:" POPUP sAllDataTypes
	prompt sWaveR4, "Select resistance wave:" POPUP sAllDataTypes
	prompt sWaveY4, "Select capacitance wave:" POPUP sAllDataTypes
	prompt sWavea4, "Select alpha wave:" POPUP sAllDataTypes

	doPrompt "Choose R, Y, and a waves for first element", sWaveR1, sWaveY1, sWavea1
	if (V_Flag)
		return -1
	endif	
	string sRList = sWaveR1
	string sYList = sWaveY1
	string saList = sWavea1
	if(vNumElem > 1)
		doPrompt "Choose R, Y, and a waves for second element", sWaveR2, sWaveY2, sWavea2
		if (V_Flag)
			return -1
		endif	
		sRList = addlistItem(sWaveR2, sRList)
		sYList = addlistItem(sWaveY2, sYList)
		saList = addlistItem(sWavea2, saList)
	endif
	if(vNumElem > 2)
		doPrompt "Choose R, Y, and a waves for third element", sWaveR3, sWaveY3, sWavea3
		if (V_Flag)
			return -1
		endif	
		sRList = addlistItem(sWaveR3, sRList)
		sYList = addlistItem(sWaveY3, sYList)
		saList = addlistItem(sWavea3, saList)
	endif
	if(vNumElem > 3)
		doPrompt "Choose R, Y, and a waves for fourth element", sWaveR4, sWaveY4, sWavea4
		if (V_Flag)
			return -1
		endif	
		sRList = addlistItem(sWaveR4, sRList)
		sYList = addlistItem(sWaveY4, sYList)
		saList = addlistItem(sWavea4, saList)
	endif
	
	//Retrieve waves
	wave wR1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR1
	wave wY1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY1
	wave wa1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea1
	if(vNumElem > 1)
		wave wR2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR2
		wave wY2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY2
		wave wa2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea2
	endif
	if(vNumElem > 2)
		wave wR3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR3
		wave wY3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY3
		wave wa3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea3
	endif
	if(vNumElem > 3)
		wave wR4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR4
		wave wY4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY4
		wave wa4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea4
	endif

	SetDataFolder $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":"
	variable vNumRows =  str2num(Combi_GetGlobalString("vTotalSamples", sProject))
	variable vNumCols = dimSize(wR1, 1)

	//Make characteristic frequency waves 
	string expr="([[:alpha:]]*)([[:digit:]]*)_([[:ascii:]]*)"
	string sToDrop1, sToDrop2, sDescriptor
	SplitString/E=(expr) sWaveR1, sToDrop1, sToDrop2, sDescriptor
	string sfC1Wave = "fC1_" + sDescriptor
	Make/O/N=(vNumRows, vNumCols) $sfC1Wave
	wave wfC1Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sfC1Wave
	copyDimLabels wR1, wfC1Wave
	
	//if there are more than 1 circuit element, make a second fC wave
	if(vNumElem > 1)	
		string sfC2Wave = "fC2_" + sDescriptor
		string sTempfC2Wave = "TempfC2Wave"
		Make/O/N=(vNumRows, vNumCols) $sfC2Wave
		wave wfC2Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sfC2Wave
		copyDimLabels wR1, wfC2Wave
	endif
	
	//if there are more than 2 circuit elements, make a third fC wave
	if(vNumElem > 2)
		string sfC3Wave = "fC3_" + sDescriptor
		string sTempfC3Wave = "TempfC3Wave"
		Make/O/N=(vNumRows, vNumCols) $sfC3Wave
		wave wfC3Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sfC3Wave
		copyDimLabels wR1, wfC3Wave
	endif
	
	//if there are more than 3 circuit element, make a fourth fC wave
	if(vNumElem > 3)
		string sfC4Wave = "fC4_" + sDescriptor
		string sTempfC4Wave = "TempfC4Wave"
		Make/O/N=(vNumRows, vNumCols) $sfC4Wave
		wave wfC4Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sfC4Wave
		copyDimLabels wR1, wfC4Wave
	endif
	
	//Make time constant waves 
	string sTao1Wave = "Tao1_" + sDescriptor
	Make/O/N=(vNumRows, vNumCols) $sTao1Wave
	wave wTao1Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sTao1Wave
	copyDimLabels wR1, wTao1Wave
	
	//if there are more than 1 circuit element, make a second Tao wave
	if(vNumElem > 1)	
		string sTao2Wave = "Tao2_" + sDescriptor
		string sTempTao2Wave = "TempTao2Wave"
		Make/O/N=(vNumRows, vNumCols) $sTao2Wave
		wave wTao2Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sTao2Wave
		copyDimLabels wR1, wTao2Wave
	endif
	
	//if there are more than 2 circuit elements, make a third Tao wave
	if(vNumElem > 2)
		string sTao3Wave = "Tao3_" + sDescriptor
		string sTempTao3Wave = "TempTao3Wave"
		Make/O/N=(vNumRows, vNumCols) $sTao3Wave
		wave wTao3Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sTao3Wave
		copyDimLabels wR1, wTao3Wave
	endif
	
	//if there are more than 3 circuit element, make a fourth Tao wave
	if(vNumElem > 3)
		string sTao4Wave = "Tao4_" + sDescriptor
		string sTempTao4Wave = "TempTao4Wave"
		Make/O/N=(vNumRows, vNumCols) $sTao4Wave
		wave wTao4Wave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sTao4Wave
		copyDimLabels wR1, wTao4Wave
	endif

	//make sorting wave
	variable iRow, iCol
	string sSortingWave = "sortingWave"
	Make/O/N=(vNumElem) $sSortingWave 
	wave wSortingWave = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary + ":" + sSortingWave
	
	//make waves for sorted variables
	Make/O/N=(vNumRows, vNumCols) $sWaveR1 + "_Sorted"
	Make/O/N=(vNumRows, vNumCols) $sWaveY1 + "_Sorted"
	Make/O/N=(vNumRows, vNumCols) $sWavea1 + "_Sorted"
	wave wR1Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR1 + "_Sorted"
	wave wY1Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY1 + "_Sorted"
	wave wa1Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea1 + "_Sorted"
	copyDimLabels wR1, wR1Sorted
	copyDimLabels wR1, wY1Sorted
	copyDimLabels wR1, wa1Sorted
	
	if(vNumElem > 1)
		Make/O/N=(vNumRows, vNumCols) $sWaveR2 + "_Sorted"
		Make/O/N=(vNumRows, vNumCols) $sWaveY2 + "_Sorted"
		Make/O/N=(vNumRows, vNumCols) $sWavea2 + "_Sorted"
		wave wR2Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR2 + "_Sorted"
		wave wY2Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY2 + "_Sorted"
		wave wa2Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea2 + "_Sorted"
		copyDimLabels wR2, wR2Sorted
		copyDimLabels wR2, wY2Sorted
		copyDimLabels wR2, wa2Sorted
	endif
	
	if(vNumElem > 2)
		Make/O/N=(vNumRows, vNumCols) $sWaveR3 + "_Sorted"
		Make/O/N=(vNumRows, vNumCols) $sWaveY3 + "_Sorted"
		Make/O/N=(vNumRows, vNumCols) $sWavea3 + "_Sorted"
		wave wR3Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR3 + "_Sorted"
		wave wY3Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY3 + "_Sorted"
		wave wa3Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea3 + "_Sorted"
		copyDimLabels wR3, wR3Sorted
		copyDimLabels wR3, wY3Sorted
		copyDimLabels wR3, wa3Sorted
	endif
	
	if(vNumElem > 3)
		Make/O/N=(vNumRows, vNumCols) $sWaveR4 + "_Sorted"
		Make/O/N=(vNumRows, vNumCols) $sWaveY4 + "_Sorted"
		Make/O/N=(vNumRows, vNumCols) $sWavea4 + "_Sorted"
		wave wR4Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveR4 + "_Sorted"
		wave wY4Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWaveY4 + "_Sorted"
		wave wa4Sorted = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + sWavea4 + "_Sorted"
		copyDimLabels wR4, wR4Sorted
		copyDimLabels wR4, wY4Sorted
		copyDimLabels wR4, wa4Sorted
	endif
	
	//calculate, sort by characteristic frequency, and transfer data
	for(iCol = 0; iCol < vNumCols; iCol +=1)
		
		string sColLabel = getDimLabel(wR1, 1, iCol)
		
		for(iRow = 0; iRow < vNumRows; iRow +=1)
			setDimLabel  0, 0, $sWaveR1, wSortingWave
			string sRowLabel = getDimLabel(wR1, 0, iRow)
			//fC = 1/((2 pi R C)^(1/alpha))
			wSortingWave[0] = 1/((2*pi*wR1[%$sRowLabel][%$sColLabel] * wY1[%$sRowLabel][%$sColLabel])^(1/wa1[%$sRowLabel][%$sColLabel]))
		
			if(vNumElem > 1)
				setDimLabel  0, 1, $sWaveR2, wSortingWave
				wSortingWave[1] = 1/((2*pi*wR2[%$sRowLabel][%$sColLabel] * wY2[%$sRowLabel][%$sColLabel])^(1/wa2[%$sRowLabel][%$sColLabel]))
			endif
		
			if(vNumElem > 2)
				setDimLabel  0, 2, $sWaveR3, wSortingWave
				wSortingWave[2] = 1/((2*pi*wR3[%$sRowLabel][%$sColLabel] * wY3[%$sRowLabel][%$sColLabel])^(1/wa3[%$sRowLabel][%$sColLabel]))
			endif
		
			if(vNumElem > 3)
				setDimLabel  0, 3, $sWaveR4, wSortingWave
				wSortingWave[3] = 1/((2*pi*wR4[%$sRowLabel][%$sColLabel] * wY4[%$sRowLabel][%$sColLabel])^(1/wa4[%$sRowLabel][%$sColLabel]))
			endif		
			
			//sort fC in decreasing order
			Sort/R/DIML wSortingWave, wSortingWave
			
			//move to individual frequency and time constant waves
			wfC1Wave[%$sRowLabel][%$sColLabel] = wSortingWave[0]
			wTao1Wave[%$sRowLabel][%$sColLabel] = 1/wSortingWave[0]
			
			if(vNumElem > 1)
				wfC2Wave[%$sRowLabel][%$sColLabel] = wSortingWave[1]
				wTao2Wave[%$sRowLabel][%$sColLabel] = 1/wSortingWave[1]
			endif
			
			if(vNumElem > 2)
				wfC3Wave[%$sRowLabel][%$sColLabel] = wSortingWave[2]
				wTao3Wave[%$sRowLabel][%$sColLabel] = 1/wSortingWave[2]
			endif
			
			if(vNumElem > 3)
				wfC4Wave[%$sRowLabel][%$sColLabel] = wSortingWave[3]
				wTao4Wave[%$sRowLabel][%$sColLabel] = 1/wSortingWave[3]
			endif			
			
			//	
			variable vIndex
			wave wWaveR1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + getDimLabel(wSortingwave, 0, 0)
			wR1Sorted[%$sRowLabel][%$sColLabel] = wWaveR1[%$sRowLabel][%$sColLabel]
			vIndex = whichListItem(getDimLabel(wSortingwave, 0, 0), sRList)
				wave wWaveY1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, sYList)
				wave wWavea1 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, saList)
				wY1Sorted[%$sRowLabel][%$sColLabel] = wWaveY1[%$sRowLabel][%$sColLabel]
				wa1Sorted[%$sRowLabel][%$sColLabel] = wWavea1[%$sRowLabel][%$sColLabel]

			if(vNumElem > 1)
				wave wWaveR2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + getDimLabel(wSortingwave, 0, 1)
				wR2Sorted[%$sRowLabel][%$sColLabel] = wWaveR2[%$sRowLabel][%$sColLabel]
				vIndex = whichListItem(getDimLabel(wSortingwave, 0, 1), sRList)
					wave wWaveY2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, sYList)
					wave wWavea2 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, saList)
					wY2Sorted[%$sRowLabel][%$sColLabel] = wWaveY2[%$sRowLabel][%$sColLabel]
					wa2Sorted[%$sRowLabel][%$sColLabel] = wWavea2[%$sRowLabel][%$sColLabel]
			endif
			
			if(vNumElem > 2)
				wave wWaveR3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + getDimLabel(wSortingwave, 0, 2)
				wR3Sorted[%$sRowLabel][%$sColLabel] = wWaveR3[%$sRowLabel][%$sColLabel]
				vIndex = whichListItem(getDimLabel(wSortingwave, 0, 2), sRList)
					wave wWaveY3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, sYList)
					wave wWavea3 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, saList)
					wY3Sorted[%$sRowLabel][%$sColLabel] = wWaveY3[%$sRowLabel][%$sColLabel]
					wa3Sorted[%$sRowLabel][%$sColLabel] = wWavea3[%$sRowLabel][%$sColLabel]
			endif
			
			if(vNumElem > 3)
				wave wWaveR4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + getDimLabel(wSortingwave, 0, 3)
				wR4Sorted[%$sRowLabel][%$sColLabel] = wWaveR4[%$sRowLabel][%$sColLabel]
				vIndex = whichListItem(getDimLabel(wSortingwave, 0, 3), sRList)
					wave wWaveY4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, sYList)
					wave wWavea4 = $"root:COMBIgor:" + sProject + ":Data:" + sLibrary +":" + stringFromList(vIndex, saList)
					wY4Sorted[%$sRowLabel][%$sColLabel] = wWaveY4[%$sRowLabel][%$sColLabel]
					wa4Sorted[%$sRowLabel][%$sColLabel] = wWavea4[%$sRowLabel][%$sColLabel]
			endif	
				
			//clear sorting wave
			wSortingWave[][] = nan
		endfor
	endfor
	killWaves wSortingWave

	SetDataFolder root:
end