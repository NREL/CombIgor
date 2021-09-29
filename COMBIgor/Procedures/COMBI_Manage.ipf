#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ June 2018 : Original


//Description of functions within:


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//function to call a load, then import a V1 combigor to V2
function COMBI_GetV1Data()

	//get project 
	string sProject = COMBI_ChooseProject()
	
	//direct loading if wanted
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	
	//load experiment as folder and analyze which one is new
	string sRootFoldersBefore = stringbyKey("FOLDERS",DataFolderDir(-1))
	LoadData/O/L=7/Q/R/T
	string sRootFoldersAfter = stringbyKey("FOLDERS",DataFolderDir(-1))
	variable vTotalFolders = itemsinlist(sRootFoldersAfter,","), iFolder
	string sNewFolder = ""
	for(iFolder=0;iFolder<vTotalFolders;iFolder+=1)
		string sThisFolder = stringfromList(iFolder,sRootFoldersAfter,",")
		variable vMatching = itemsinlist(Listmatch(sRootFoldersBefore,sThisFolder,","))
		if(vMatching==0)
			sNewFolder = sThisFolder
		endif
	endfor
	sNewFolder = "'"+sNewFolder+"'"
	
	
	
	//get projects, and ask user which one
	setdatafolder $"root:"+sNewFolder+":"
	string sExpProjects = ReplaceString(",", stringbyKey("FOLDERS",DataFolderDir(-1)),";")
	SetDataFolder $sTheCurrentUserFolder 
	
	//loop for multiple projects
	do
		
		string sV1Project2Load = COMBI_StringPrompt(stringfromlist(0,sExpProjects),"V1 Project folder to import:",sExpProjects,"This is the project that in V1 COMBIgor","V1 Project Import")
		string sWaveSourceText = "V1 Experiment: "+sNewFolder+";Project:"+sV1Project2Load
		
		//get the globals needed to compare
		variable bLoadMapping = 0, bLoadXRD = 0
		//sMappingDataG
		SVAR/Z sMappingDataG = $"root:"+sNewFolder+":"+sV1Project2Load+":sMappingDataG"
		if(SVAR_Exists(sMappingDataG))
			//get Mapping wave
			wave wV1Mapping = $"root:"+sNewFolder+":"+sV1Project2Load+":"+sMappingDataG
			bLoadMapping = 1
		endif
		//vNumColumnssG
		NVAR/Z vNumColumnssG = $"root:"+sNewFolder+":"+sV1Project2Load+":vNumColumnssG"
		if(NVAR_Exists(vNumColumnssG))
			if(vNumColumnssG!=COMBI_GetGlobalNumber("vTotalColumns", sProject))
				DoAlert/T="COMBIgor error" 0,"This project was a different number of columns than the one selected to load."
				Return -1
			endif
		endif
		//vNumRowsG
		NVAR/Z vNumRowsG = $"root:"+sNewFolder+":"+sV1Project2Load+":vNumRowsG"
		if(NVAR_Exists(vNumRowsG))
			if(vNumRowsG!=COMBI_GetGlobalNumber("vTotalRows", sProject))
				DoAlert/T="COMBIgor error" 0,"This project was a different number of rows than the one selected to load."
				Return -1
			endif
		endif
		if(NVAR_Exists(vNumRowsG)&&NVAR_Exists(vNumColumnssG))
			if(vNumRowsG*vNumColumnssG!=COMBI_GetGlobalNumber("vTotalSamples", sProject))
				DoAlert/T="COMBIgor error" 0,"This project was a different number of samples than the one selected to load."
				Return -1
			endif
		endif
		//sXRDBrukerDataG
		SVAR/Z sXRDBrukerDataG = $"root:"+sNewFolder+":"+sV1Project2Load+":sXRDBrukerDataG"
		if(SVAR_Exists(sXRDBrukerDataG))
			//get XRD wave
			wave wV1XRD = $"root:"+sNewFolder+":"+sV1Project2Load+":"+sXRDBrukerDataG
			bLoadXRD = 1
		endif
		
		//Load Mapping?
		if(bLoadMapping==1)
			string sLoadMapping = COMBI_StringPrompt("YES","Import Mapping wave: "+sMappingDataG+"?","YES;NO","Do you want to import this data table from V1 COMBIgor?","Mapping V1 Data Import")
			if(stringmatch(sLoadMapping,"YES"))
				COMBI_GiveV1Data(sProject,1,wV1Mapping,sWaveSourceText+";Wave:"+sMappingDataG)
			endif
		endif
		
		//Load XRD?
		if(bLoadXRD==1)
			string sLoadXRD = COMBI_StringPrompt("YES","Import XRD wave: "+sXRDBrukerDataG+"?","YES;NO","Do you want to import this data table from V1 COMBIgor?","XRD V1 Data Import")
			if(stringmatch(sLoadXRD,"YES"))
				COMBI_GiveV1Data(sProject,2,wV1XRD,sWaveSourceText+";Wave:"+sXRDBrukerDataG)
			endif
		endif
		
		//Load other?
		string sLoadOther = COMBI_StringPrompt("NO","Load other waves?","YES;NO","Do you want to import other data tables from V1 COMBIgor?","Other V1 Data Import")
		if(stringmatch(sLoadOther,"YES"))
			setdatafolder $"root:"+sNewFolder+":"+sV1Project2Load+":"
			string sAllWaves = ReplaceString(",", stringbyKey("WAVES",DataFolderDir(2)),";")
			SetDataFolder $sTheCurrentUserFolder 
			variable vOthers2Add = COMBI_NumberPrompt(1,"How many more?","Please enter the number of other data tables to load.","Other Data Import")
			variable iOther2Add
			for(iOther2Add=0;iOther2Add<vOthers2Add;iOther2Add+=1)
				string sThisOtherWave = COMBI_StringPrompt(stringfromlist(0,sAllWaves),"Which Wave?",sAllWaves,"Choose which wave you want imported","Other V1 Wave Import")
				if(stringmatch(sThisOtherWave,"CANCEL"))
					continue
				endif
				string sThisOtherWaveDim = COMBI_StringPrompt("Scalar","What is the data dimensionality?","Scalar;Vector","Choose the data dimensionality","Other V1 Wave Import")
				if(stringmatch(sThisOtherWaveDim,"CANCEL"))
					continue
				endif
				variable iOtherDataDim
				if(stringmatch(sThisOtherWaveDim,"Scalar"))
					iOtherDataDim =1
				elseif(stringmatch(sThisOtherWaveDim,"Vector"))
					iOtherDataDim=2
				endif
				wave wOtherWave = $"root:"+sNewFolder+":"+sV1Project2Load+":"+sThisOtherWave
				COMBI_GiveV1Data(sProject,iOtherDataDim,wOtherWave,sWaveSourceText+";Wave:"+sThisOtherWave)
			endfor
		endif
		DoAlert/T="More?",1,"Should COMBIgor load another project while you have this V1 file loaded?"
	while(V_Flag==1)
	
	//kill imported experiment
	killDataFolder/Z $"root:"+sNewFolder+":"
	
	killpath/A
	
end

//function to import V1 table to V2 combIgor
function COMBI_GiveV1Data(sProject,iDim,wV1DataTable,sWaveSourceText)
	string sProject //project
	variable iDim //dim of data table coming in
	wave wV1DataTable //data table coming in
	string sWaveSourceText //source text for logging

	
	//number of Samples
	variable vTotalSamplesIn, vVectorLength, vDataDim
	variable vTotalLibraries = dimsize(wV1DataTable,3)-2
	variable vTotalRows = dimsize(wV1DataTable,0)
	variable vTotalColumns = dimsize(wV1DataTable,1)
	if(iDim==1)
		vTotalSamplesIn = dimsize(wV1DataTable,0)*dimSize(wV1DataTable,1)
		vVectorLength = 0
		vDataDim = 2
	elseif(iDim==2)
		vTotalSamplesIn = dimsize(wV1DataTable,0)
		vVectorLength = dimsize(wV1DataTable,2)
		vDataDim = 1
	endif
	if(vTotalSamplesIn!=COMBI_GetGlobalNumber("vTotalSamples",sProject))
		DoAlert/T="COMBIgor error" 0,"Number of samples in does not match the number in this project. Process aborted."
		return -1
	endif
	
	//get list of all data types
	variable vTotalDataTypes = dimsize(wV1DataTable,vDataDim)-2
	string sDataTypes =""
	variable iDataType
	for(iDataType=2;iDataType<(vTotalDataTypes+2);iDataType+=1)
		if(!stringmatch(GetDimLabel(wV1DataTable,vDataDim,iDataType),""))
			sDataTypes = AddListItem(GetDimLabel(wV1DataTable,vDataDim,iDataType),sDataTypes,";",inf)
		endif
	endfor
	vTotalDataTypes = itemsinList(sDataTypes)
	
	//get list of all Libraries
	string sFromMappingGrid =""
	variable iLibrary
	for(iLibrary=2;iLibrary<dimsize(wV1DataTable,3);iLibrary+=1)
		if(!stringmatch(GetDimLabel(wV1DataTable,3,iLibrary),""))
			sFromMappingGrid = AddListItem(GetDimLabel(wV1DataTable,3,iLibrary),sFromMappingGrid,";",inf)
		endif
	endfor
	vTotalLibraries = itemsinList(sFromMappingGrid)
	
	//get giving wave
	if(iDim==1)
		make/O/N=(vTotalSamplesIn,1) wV1Giver
		wave wGiving = root:wV1Giver
	elseif(iDim==2)
		make/O/N=(vTotalSamplesIn,1,vVectorLength) wV1Giver
		wave wGiving = root:wV1Giver
	endif
	
	//make progress window in middle of screen
	int iProgressTrack = 0
	int iTotalToImport = vTotalLibraries*vTotalDataTypes
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
	DrawText 100,20,"Importing V1 now"
	ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
	ValDisplay valdispProgress limits={0,iTotalToImport,0},barmisc={0,1},bodyWidth= 180
	Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iProgressTrack)
	DoUpdate/W=ImportProgress
	
	//loop all Libraries coming in cause there are multiple chunk
	string sLibrary, sDataType
	int iRow, iColumn, iSample, iVector
	if(vTotalLibraries>0)
		for(iDataType=0;iDataType<(vTotalDataTypes);iDataType+=1)
			sDataType = stringfromlist(iDataType,sDataTypes)
			for(iLibrary=0;iLibrary<(vTotalLibraries);iLibrary+=1)
				sLibrary = stringfromlist(iLibrary,sFromMappingGrid)
				//Transfer Data To Giving Wave
				int bThereIsData = 0
				if(iDim==1)
					wGiving[][]=nan
					for(iRow=0;iRow<vTotalRows;iRow+=1)
						for(iColumn=0;iColumn<vTotalColumns;iColumn+=1)
							iSample = iColumn+iRow*vTotalColumns
							if(numtype(wV1DataTable[iRow][iColumn][%$sDataType][%$sLibrary])==0)
								bThereIsData = 1
								wGiving[iSample][0] = wV1DataTable[iRow][iColumn][%$sDataType][%$sLibrary]
							endif
						endfor
					endfor
				elseif(iDim==2)
					wGiving[][][]=nan
					for(iSample=0;iSample<vTotalSamplesIn;iSample+=1)
						for(iVector=0;iVector<vVectorLength;iVector+=1)
							if(numtype(wV1DataTable[iSample][%$sDataType][iVector][%$sLibrary])==0)
								bThereIsData = 1
								wGiving[iSample][0][iVector] = wV1DataTable[iSample][%$sDataType][iVector][%$sLibrary]
							endif
						endfor
					endfor
				endif
				if(bThereIsData==1)
					//Give Data to COMBIgor V2
					COMBI_GiveData(wGiving,sProject,sLibrary,sDataType,-1,iDim)
					iProgressTrack+=1
					Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iProgressTrack)
					DoUpdate/W=ImportProgress
				endif
			endfor
		endfor
	endif
	
	//kill giving waves
	killwaves wGiving
	killwindow ImportProgress

	//add to data log
	COMBI_Add2Log(sProject,replaceString(";",sFromMappingGrid,","),replaceString(";",sDataTypes,","),1,"Data Imported from a V1 COMBIgor experiment;"+sWaveSourceText)	

end


function COMBI_Add2Log(sProject,sLibraries,sDataType,vLogEntryType,sLogText)
	string sProject // project in COMBIgor
	string sLibraries // for these Libraries
	string sDataType //The associated data lable
	variable vLogEntryType // (0=user note,1=data loaded,2=data processed)
	string sLogText //text to add to log	, a list of up to 5 is accepted
	
	//log book, Column layout
	// 0 = EntryNumber
	// 1 = EntryTime
	// 2 = Library
	// 3 = DataType
	// 4 = LogType (0=user note,1=data loaded,2=data processed)
	// 5 = LogEntry1
	// 6 = LogEntry2
	// 7 = LogEntry3
	// 8 = LogEntry4
	// 9 = LogEntry5
	
	wave/T wLogBook = $"root:COMBIgor:"+sProject+":Data:"+"LogBook"
	variable vCurrentEntries = dimsize(wLogBook,0)
	
	//for each Library to add log notes
	variable vNumberofLogEntrys = itemsinlist(sLogText)
	int iNote
	//add row to log book
	redimension/N=(vCurrentEntries+1,-1) wLogBook
	wLogBook[vCurrentEntries][0] = num2str(vCurrentEntries)
	wLogBook[vCurrentEntries][1] = Time() +" on "+Date()
	wLogBook[vCurrentEntries][2] = sLibraries
	wLogBook[vCurrentEntries][3] = sDataType
	wLogBook[vCurrentEntries][4] = num2str(vLogEntryType)
	for(iNote=0;iNote<vNumberofLogEntrys;iNote+=1)
		wLogBook[vCurrentEntries][5+iNote] = stringFromList(iNote,sLogText)
	endfor
end

function COMBI_SearchLogBook()
	//for what project
	string sProject = COMBI_ChooseProject()
	wave/T wLogBook = $"root:COMBIgor:"+sProject+":Data:"+"LogBook"
	variable vLogEntries = dimsize(wLogBook,0)
	//prompt user for Library filters
	string sLibraryOptions = "Any;"+COMBI_TableList(sProject,-3,"All","Libraries")
	string sLibraryFilter = COMBI_StringPrompt("Any","Library for filter for:",sLibraryOptions,"We will only find entries in the log book for this library.","Log Book Library Filter")
	if(stringmatch(sLibraryFilter,"CANCEL"))
		return -1
	endif
	//prompt user for Data Type filter
	string sDataTypeOptions = "Any;"+COMBI_ActivePluginList("Plugins")+COMBI_ActiveInstrumentList("Instruments")+COMBI_TableList(sProject,-3,"All","DataTypes")
	string sDataTypeFilter = COMBI_StringPrompt("Any","Data Type for filter for:",sDataTypeOptions,"We will only find entries in the log book for this data type.","Log Book Data Type Filter")
	if(stringmatch(sDataTypeFilter,"CANCEL"))
		return -1
	endif
	//prompt user for entry type
	string sEntryTypeOptions = "Any;User notes;Loading;Processing"
	string sEntryTypeFilter = COMBI_StringPrompt("Any","Entry Type for filter for:",sEntryTypeOptions,"We will only find entries in the log book for this entry type.","Log Book Entry Type Filter")
	if(stringmatch(sEntryTypeFilter,"CANCEL"))
		return -1
	endif
	variable vEntryTypeFilter = WhichListItem(sEntryTypeFilter, sEntryTypeOptions)-1
	//make destination notebook
	string sLogBookName = "LogResults"
	string sWindowTitle = sProject+ " Log Results for: Library-"+sLibraryFilter+", Data Type-"+sDataTypeFilter+", Entry Type-"+sEntryTypeFilter
	killwindow/Z $sLogBookName
	newnotebook/O/Z/F=0/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sLogBookName/W=(10,10,610,810) as sWindowTitle
	
	//search log book entries 
	variable iEntry, iEntryNote
	string sEntryNumber, sEntryTime, sEntryLibrary, sEntryDataType, sEntryType
	string sTab = "\t"
	string sReturn = "\r"
	for(iEntry=1;iEntry<vLogEntries;iEntry+=1)
		sEntryNumber = wLogBook[iEntry][0] // 0 = EntryNumber
		sEntryTime = wLogBook[iEntry][1] // 1 = EntryTime
		sEntryLibrary = wLogBook[iEntry][2] // 2 = Library
		sEntryDataType = wLogBook[iEntry][3] // 3 = DataType
		sEntryType = wLogBook[iEntry][4] // 4 = LogType (0=user note,1=data loaded,2=data processed)
		int bIncludeS = 0
		int bIncludeD = 0
		int bIncludeT = 0
		int iLibrary
		int iLibrariesInEntry = itemsinlist(sEntryLibrary)
		for(iLibrary=0;iLibrary<iLibrariesInEntry;iLibrary+=1)
			string sThisLibrary = stringFromList(iLibrary,sEntryLibrary)
			if(stringmatch(sLibraryFilter,"Any"))//Library filter
				bIncludeS = 1
			endif
			if(stringmatch(sLibraryFilter,sThisLibrary))
				bIncludeS = 1
			endif
			if(stringmatch("All",sEntryLibrary))
				bIncludeS = 1
			endif
		endfor
		int iDataType
		int iDataTypesInEntry = itemsinlist(sEntryDataType)
		for(iDataType=0;iDataType<iLibrariesInEntry;iDataType+=1)
			string sDataType = stringFromList(iDataType,sEntryDataType)
			if(stringmatch(sDataTypeFilter,"Any"))//data type filter
				bIncludeD = 1
			endif
			if(stringmatch(sDataTypeFilter,sDataType))
				bIncludeD = 1
			endif
			if(stringmatch("All",sEntryDataType))
				bIncludeD = 1
			endif
		endfor
		if(stringmatch(sEntryTypeFilter,"Any"))//Entry type filter
			bIncludeT = 1
		endif
		if(vEntryTypeFilter==str2num(sEntryType))
			bIncludeT = 1
		endif
		//write to log book
		if(bIncludeS==1&&bIncludeD==1&&bIncludeT==1)
			notebook $sLogBookName text="Entry # "+sEntryNumber+" at "+sEntryTime+sReturn
			notebook $sLogBookName text=sTab+"Library: "+sEntryLibrary+sReturn
			notebook $sLogBookName text=sTab+"Data Type: "+sEntryDataType+sReturn
			for(iEntryNote=5;iEntryNote<=9;iEntryNote+=1)
				if(strlen(wLogBook[iEntry][iEntryNote])>0)
					notebook $sLogBookName text=sTab+sTab+wLogBook[iEntry][iEntryNote]+sReturn
				endif
			endfor
			notebook $sLogBookName text=sReturn+sReturn
		endif
	endfor
end

function COMBI_UserLogEntry()

	string sProject = COMBI_ChooseProject()
	wave/T wLogBook = $"root:COMBIgor:"+sProject+":"+"LogBook"
	//prompt user for Library entry
	string sLibraryOptions = "All;"+COMBI_TableList(sProject,-3,"All","Libraries")
	string sLibraryChoice = COMBI_StringPrompt("All","Associated Library:",sLibraryOptions,"Choose library with which to associate this log entry.","Log Book - Library Entry")
	if(stringmatch(sLibraryChoice,"CANCEL"))
		return -1
	endif
	//prompt user for Data Type entry
	string sDataTypeOptions = "All;"+COMBI_ActivePluginList("Plugins")+COMBI_TableList(sProject,-3,"All","DataTypes")
	string sDataTypeChoice = COMBI_StringPrompt("All","For Data Type:",sDataTypeOptions,"Choose data type with which to associate this log entry.","Log Book - Data Type Entry")
	if(stringmatch(sDataTypeChoice,"CANCEL"))
		return -1
	endif
	//how many notes 1-5
	variable vTotalNewNotes = str2num(COMBI_StringPrompt("1","Number of notes:","1;2;3;4;5","How many notes to want to add to to this entry?","Log Book - Note Entry"))
	//get user note
	variable iNote
	string sAllNotes =""
	for(iNote=0;iNote<vTotalNewNotes;iNote+=1)
		string sLogText = COMBI_StringPrompt("","Note "+num2str(iNote+1)+":","","This is the note that will be saved.","Log Book Note Entry")
		if(iNote==0)
			sAllNotes = sLogText
		else
			sAllNotes = sAllNotes+";"+sLogText
		endif
		if(stringmatch(sLogText,"CANCEL"))
			return -1
		endif
	endfor
	
	//add to log
	COMBI_Add2Log(sProject,sLibraryChoice,sDataTypeChoice,0,sAllNotes)
	
end

function COMBI_Project2ProjectScalarInterp()
	//get all projects
	string sProjectList = COMBI_Projects()
	
	//get source project
	string sProjectSource
	prompt sProjectSource, "From Project:",popup,sProjectList
	//get destination project 
	string sProjectDestination
	prompt sProjectDestination, "To Project:",popup,sProjectList
	DoPrompt "From Project to Project?",sProjectSource, sProjectDestination
	if(V_flag)
		return 0//user cancel
	endif
	
	//get source library
	string sSourceLibrary = COMBI_LibraryPrompt(sProjectSource,"Select Source Library!!!","Source Library",0,0,0,1)
	if(stringmatch(sSourceLibrary,"CANCEL"))
		return 0//user cancel
	endif
	
	string sDataTypeSource = COMBI_DataTypePrompt(sProjectSource,"Select Data Type!!!","Data Type to Interpolate",0,0,0,1,sLibraries=sSourceLibrary)
	if(stringmatch(sDataTypeSource,"CANCEL"))
		return 0//user cancel
	endif
	
	string sHelp = "PolyFit fits a 2Dpoly function, PlaneFit fits a flat plane, Voronoi does a classic interpolation"
	string sStyle = COMBI_StringPrompt("PolyFit","Interpolation Type","PolyFit;PlaneFit;Voronoi",sHelp,"Choose Type")
	if(stringmatch(sStyle,"CANCEL"))
		return 0//user cancel
	endif
	
	COMBI_ScalarInterpolation(sProjectSource,sProjectDestination,sSourceLibrary,sDataTypeSource,sStyle,1)
end


function/S COMBI_ScalarInterpolation(sProjectSource,sProjectDestination,sSourceLibrary,sDataTypeSource,sStyle,bDisplay)
	string sProjectSource
	string sProjectDestination
	string sSourceLibrary
	string sDataTypeSource
	string sStyle// "PolyFit", "PlaneFit", "Voronoi", 
	int bDisplay// 1 for yes, 0 for no
	//get source library map
	if(waveexists($"root:COMBIgor:"+sProjectSource+":MappingGrid"))
		wave wSourceMap = $"root:COMBIgor:"+sProjectSource+":MappingGrid"
		variable vSourceSamples = COMBI_GetGlobalNumber("vTotalSamples",sProjectSource)
	else
		DoAlert/T="Missing Library Map",0,"No Library map for "+sProjectSource+" project."
		return ""
	endif
	//get destination library map
	if(waveexists($"root:COMBIgor:"+sProjectDestination+":MappingGrid"))
		wave wDestinationMap = $"root:COMBIgor:"+sProjectDestination+":MappingGrid"
		variable vDestinationSamples = COMBI_GetGlobalNumber("vTotalSamples",sProjectDestination)
	else
		DoAlert/T="Missing Library Map",0,"No Library map for "+sProjectDestination+" project."
		return ""
	endif
	//check for source data
	if(COMBI_CheckForDataType(sProjectSource,sSourceLibrary,sDataTypeSource,1)==1)
		wave wSourceScalar = $COMBI_DataPath(sProjectSource,1)+sSourceLibrary+":"+sDataTypeSource
	else
		DoAlert/T="Missing Source Data",0,"No "+sDataTypeSource+" data for "+sSourceLibrary+" in the "+sProjectSource+" project."
		return ""
	endif
	//Make destination
	COMBI_AddDataType(sProjectDestination,sSourceLibrary,sDataTypeSource+"_"+sStyle,1)
	wave wDestinationScalar = $COMBI_DataPath(sProjectDestination,1)+sSourceLibrary+":"+sDataTypeSource+"_"+sStyle
	//get ranges
	make/O/N=(vSourceSamples) wSourceTemp
	wave wSourceTemp = root:wSourceTemp
	make/O/N=(vDestinationSamples) wDestinationTemp
	wave wDestinationTemp = root:wDestinationTemp
	wSourceTemp[] = wSourceMap[p][1]; wDestinationTemp[] = wDestinationMap[p][1]
	variable vMaxX = max(wavemax(wSourceTemp),wavemax(wDestinationTemp)) 
	variable vMinX = min(wavemin(wSourceTemp),wavemin(wDestinationTemp)) 
	wSourceTemp[] = wSourceMap[p][2]; wDestinationTemp[] = wDestinationMap[p][2]
	variable vMaxY = max(wavemax(wSourceTemp),wavemax(wDestinationTemp))  
	variable vMinY = min(wavemin(wSourceTemp),wavemin(wDestinationTemp)) 
	
	variable vLibrayHeight = COMBI_GetGlobalNumber("vLibraryHeight",sProjectDestination)
	variable vLibrayWidth = COMBI_GetGlobalNumber("vLibraryWidth",sProjectDestination)
	
	//do specifics
	int iSourceSample, iDestinationSample, iThisX, iThisY
	int bFinished = 0
	if(stringmatch("PolyFit",sStyle))	
		//fit waves
		Make/O/N=(6) wFitCoefsPlane
		wave wFitCoefsPlane = root:wFitCoefsPlane
		Make/O/T/N=0 twConstraints
		wave/T twConstraints = root:twConstraints
		make/O/N=(vSourceSamples) wXFitData, wYFitData, wZFitData
		wave wXFitData=root:wXFitData
		wave wYFitData=root:wYFitData
		wave wZFitData=root:wZFitData
		//source data
		wXFitData[]=wSourceMap[p][1]
		wYFitData[]=wSourceMap[p][2]
		wZFitData[]=wSourceScalar[p]
		//do fit
		FuncFit/Q/W=2 COMBI_PolyFit2D, wFitCoefsPlane, wZFitData[]/X={wXFitData[],wYFitData[]}/C=twConstraints
		//destination data
		wDestinationScalar[] = poly2d(wFitCoefsPlane,wDestinationMap[p][1],wDestinationMap[p][2])
		//store fit coefficients
		Note/K wDestinationScalar
		Note wDestinationScalar "Data From a poly2D fit of Data: "+sDataTypeSource+" for Library: "+sSourceLibrary
		Note wDestinationScalar "K0="+num2str(wFitCoefsPlane[0])	
		Note wDestinationScalar "K1="+num2str(wFitCoefsPlane[1])	
		Note wDestinationScalar "K2="+num2str(wFitCoefsPlane[2])	
		Note wDestinationScalar "K3="+num2str(wFitCoefsPlane[3])	
		Note wDestinationScalar "K4="+num2str(wFitCoefsPlane[4])	
		Note wDestinationScalar "K5="+num2str(wFitCoefsPlane[5])		
		bFinished=1
		
	elseif(stringmatch("PlaneFit",sStyle))
		//fit waves
		Make/O/N=(6) wFitCoefsPlane
		wave wFitCoefsPlane = root:wFitCoefsPlane
		Make/O/T/N=4 twConstraints
		wave/T twConstraints = root:twConstraints
		twConstraints[0] = "K3 < 0"
		twConstraints[1] = "K3 > 0"
		twConstraints[2] = "K5 < 0"
		twConstraints[3] = "K5 > 0"
		make/O/N=(vSourceSamples) wXFitData, wYFitData, wZFitData
		wave wXFitData=root:wXFitData
		wave wYFitData=root:wYFitData
		wave wZFitData=root:wZFitData
		//source data
		wXFitData[]=wSourceMap[p][1]
		wYFitData[]=wSourceMap[p][2]
		wZFitData[]=wSourceScalar[p]
		//do fit
		FuncFit/Q/W=2 COMBI_PolyFit2D, wFitCoefsPlane, wZFitData[]/X={wXFitData[],wYFitData[]}/C=twConstraints
		//destination data
		wDestinationScalar[] = poly2d(wFitCoefsPlane,wDestinationMap[p][1],wDestinationMap[p][2])
		//store fit coefficients
		Note/K wDestinationScalar
		Note wDestinationScalar "Data From a contstrained poly2D fit of Data: "+sDataTypeSource+" for Library: "+sSourceLibrary
		Note wDestinationScalar "K0="+num2str(wFitCoefsPlane[0])	
		Note wDestinationScalar "K1="+num2str(wFitCoefsPlane[1])	
		Note wDestinationScalar "K2="+num2str(wFitCoefsPlane[2])	
		Note wDestinationScalar "K3="+num2str(wFitCoefsPlane[3])	
		Note wDestinationScalar "K4="+num2str(wFitCoefsPlane[4])	
		Note wDestinationScalar "K5="+num2str(wFitCoefsPlane[5])		
		bFinished=1
		
	elseif(stringmatch("Voronoi",sStyle))
		//make sourcewave
		make/O/N=(vSourceSamples,3) wVoronoiIn
		wave wVoronoiIn=root:wVoronoiIn
		wVoronoiIn = nan
		//source data
		wVoronoiIn[][0]=wSourceMap[p][1]
		wVoronoiIn[][1]=wSourceMap[p][2]
		wVoronoiIn[][2]=wSourceScalar[p]
		//make image wave and populate with source data
		imageinterpolate/S={vMinX-1,.01,vMaxX+1,vMinY-1,.01,vMaxY+1} Voronoi wVoronoiIn
		wave wVoronoiOut = root:M_InterpolatedImage
		for(iDestinationSample=0;iDestinationSample<vDestinationSamples;iDestinationSample+=1)
			iThisX = ScaleToIndex(wVoronoiOut, wDestinationMap[iDestinationSample][1],0)
			iThisY = ScaleToIndex(wVoronoiOut, wDestinationMap[iDestinationSample][2],1)
			wDestinationScalar[iDestinationSample] = wVoronoiOut[iThisX][iThisY]
		endfor
		//store fit coefficients
		Note/K wDestinationScalar
		Note wDestinationScalar "Data From a Voronoi interpolation of Data: "+sDataTypeSource+" for Library: "+sSourceLibrary
		bFinished=1
	endif
	
	//make plot of what it did
	if(bDisplay==1&&bFinished==1)
		variable vPlotMin = min(wavemin(wSourceScalar),wavemin(wDestinationScalar))
		variable vPlotMax = max(wavemax(wSourceScalar),wavemax(wDestinationScalar))
		//Map
		killwindow/Z ScalarInterpFeedback
		string sWindow=COMBI_NewPlot("ScalarInterpFeedback")
		AppendToGraph/W=$sWindow wSourceMap[][2]/TN=$sDataTypeSource vs wSourceMap[][1]
		AppendToGraph/W=$sWindow wDestinationMap[][2]/TN=$sDataTypeSource+"_"+sStyle vs wDestinationMap[][1]
		ModifyGraph mode=3,msize=5
		ModifyGraph marker($sDataTypeSource)=16,zColor($sDataTypeSource)={wSourceScalar[],vPlotMin,vPlotMax,Rainbow,0}
		ModifyGraph marker($sDataTypeSource+"_"+sStyle)=16,zColor($sDataTypeSource+"_"+sStyle)={wDestinationScalar[],vPlotMin,vPlotMax,Rainbow,0}
		ModifyGraph mrkThick($sDataTypeSource+"_"+sStyle)=1
		TextBox/C/N=text1/F=0/A=MT/E/X=-2.00/Y=5.00 "\\Z30\\k(0,0,0)\\W5005\\Z14 Source\t\t\\Z30\\W5008\\Z14"+sStyle
		ModifyGraph tick=3,mirror=3
		ModifyGraph gfSize=14
		Label left "y(mm)"
		Label bottom "x(mm)"
		ModifyGraph margin(right)=150,width=250,height=250
		SetAxis left 0,vLibrayHeight
		SetAxis bottom 0,vLibrayWidth
		ModifyGraph useMrkStrokeRGB($sDataTypeSource)=1
		ModifyGraph marker($sDataTypeSource+"_"+sStyle)=19
		ColorScale/C/N=ColorBar/F=0/A=MT/E  ctab={vPlotMin,vPlotMax,Rainbow,0},axisRange={vPlotMin,vPlotMax},minor=1,tickLen=2.00,lowTrip=1,highTrip=1
		ColorScale/C/N=ColorBar sDataTypeSource+" (\\e)"
		ColorScale/C/N=ColorBar/A=RC
		ColorScale/C/N=ColorBar heightPct=100
		ColorScale/C/N=ColorBar/X=8.00/Y=-3/E=2
		
	endif
	//cleanup
	killwaves/Z wFitCoefsPlane,twConstraints,wXFitData,wYFitData,wZFitData, wDestinationTemp, wSourceTemp, wVoronoiIn, wVoronoiOut, wKrigingIn, wKrigingOut
	
	//log
	string sLog1 = "This data was produced from a "+sStyle+" interpolation of "+sDataTypeSource+" in the "+sProjectSource+" project"
	string sLog2 = "This was done by the function: COMBI_ScalarInterpolation()"
	COMBI_Add2Log(sProjectDestination,sSourceLibrary,sDataTypeSource+"_"+sStyle,2,sLog1+";"+sLog2)
	
end

Function COMBI_PolyFit2D(wCoef,x,y) : FitFunc
	Wave wCoef//C,X,Y,X^2,XY,Y^2
	Variable x,y
	return wCoef[0]+(x*wCoef[1])+(y*wCoef[2])+(x*x*wCoef[3])+(x*y*wCoef[4])+(y*y*wCoef[5])
End


function COMBI_CleanUpEmptyDims(sProject)
	string sProject
	
	string sAllLibrarys, sThisLibrary, sAllDataTypes, sThisDataType
	int iLibrary, iSample, iDataType, iVector, iFirstNull, iLastNull, iFirstColumn2Remove, iLastColumn2Remove
	int bVectorDimChanges, bSampleDimChanges
	string sAllMappingGridTypes = COMBI_LibraryQualifiers(sProject,-1)
	variable vFirstSample, vFirstVector
	
	//all vector libraries
	sAllLibrarys = COMBI_TableList(sProject,2,"All","Libraries")
	for(iLibrary=0;iLibrary<itemsinlist(sAllLibrarys);iLibrary+=1)
		sThisLibrary = stringfromlist(iLibrary,sAllLibrarys)
		//get all vector types for this library
		sAllDataTypes = COMBI_TableList(sProject,2,sThisLibrary,"DataTypes")
		for(iDataType=0;iDataType<itemsinlist(sAllDataTypes);iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sAllDataTypes)
			
			//delete if actually Library Mapping grid stuff
			if(whichlistItem(sThisDataType,sAllMappingGridTypes)!=-1)
				Killwaves $Combi_DataPath(sProject,2)+sThisLibrary+":"+sThisDataType
				Continue
			else
				wave wThisVectorData = $Combi_DataPath(sProject,2)+sThisLibrary+":"+sThisDataType
			endif
			
			//search for nulls and shorten wave in nulls at end
			iFirstNull = 0
			iLastNull = dimsize(wThisVectorData,1)-1
			for(iVector=0;iVector<dimsize(wThisVectorData,1);iVector+=1)
				for(iSample=0;iSample<dimsize(wThisVectorData,0);iSample+=1)
					if(numtype(wThisVectorData[iSample][iVector])==0)//number
						iFirstNull = iVector+1
					endif
				endfor
			endfor
			if(iFirstNull<iLastNull)
				Redimension/N=(-1,iFirstNull) wThisVectorData
			endif
			
			//check for unchanging vector dim
			bVectorDimChanges = 0
			bSampleDimChanges = 0
			vFirstSample = wThisVectorData[0][0]
			for(iSample=0;iSample<dimsize(wThisVectorData,0);iSample+=1)
				vFirstVector = wThisVectorData[iSample][0]
				if(vFirstSample!=wThisVectorData[iSample][0])//sample changes
					bSampleDimChanges = 1
				endif
				for(iVector=0;iVector<dimsize(wThisVectorData,1);iVector+=1)
					if(vFirstVector!=wThisVectorData[iSample][iVector])//vector changes
						bVectorDimChanges = 1
					endif
				endfor
			endfor
			if(bSampleDimChanges==0&&bVectorDimChanges==0)
				Killwaves $Combi_DataPath(sProject,2)+sThisLibrary+":"+sThisDataType
			endif
						
		endfor
	endfor
	
	int bDataIsNull
	//all scalar libraries
	sAllLibrarys = COMBI_TableList(sProject,1,"All","Libraries")
	for(iLibrary=0;iLibrary<itemsinlist(sAllLibrarys);iLibrary+=1)
		sThisLibrary = stringfromlist(iLibrary,sAllLibrarys)
		//get all scalar types for this library
		sAllDataTypes = COMBI_TableList(sProject,1,sThisLibrary,"DataTypes")
		for(iDataType=0;iDataType<itemsinlist(sAllDataTypes);iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sAllDataTypes)
			wave wThisScalarData = $Combi_DataPath(sProject,1)+sThisLibrary+":"+sThisDataType
			//check for empty	
			bDataIsNull = 1
			for(iSample=0;iSample<dimsize(wThisScalarData,0);iSample+=1)
				if(numtype(wThisScalarData[iSample])==0)//not null data
					bDataIsNull = 0
				endif
			endfor
			//check for unchanging data
			bSampleDimChanges = 0
			vFirstSample = wThisScalarData[0]
			for(iSample=0;iSample<dimsize(wThisScalarData,0);iSample+=1)
				if(vFirstSample!=wThisScalarData[iSample])//sample changes
					bSampleDimChanges = 1
				endif
			endfor
			if(bSampleDimChanges==0)
				Killwaves/Z $Combi_DataPath(sProject,2)+sThisLibrary+":"+sThisDataType
			endif
			if(bDataIsNull==1)
				Killwaves/Z $Combi_DataPath(sProject,2)+sThisLibrary+":"+sThisDataType
			endif
		endfor
	endfor
	
end

function COMBI_UserLoop([sUserLibrary])

	string sUserLibrary //optional
	string sProject = COMBI_ChooseProject()
	string sFromMappingGrid = Combi_TableList(sProject,-2,"All","Libraries")//Library,Scalar,Vector
	string sAllMetaLibraries = Combi_TableList(sProject,-1,"All","Libraries")
	string sAllLibraryLibraries = Combi_TableList(sProject,0,"All","Libraries")
	string sAllFolderLibraries = Combi_TableList(sProject,1,"All","Libraries")
	variable vLibraryHeight = COMBI_GetGlobalNumber("vLibraryHeight",sProject)
	variable vLibraryWidth = COMBI_GetGlobalNumber("vLibraryWidth",sProject)
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	int iLibrary, iSample
	string sThisLibrary
	
	//every library
	for(iLibrary=0;iLibrary<itemsinlist(sFromMappingGrid);iLibrary+=1)
		 sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
		 for(iSample=0;iSample<vTotalSamples;iSample+=1)
		 endfor
	endfor
	
	//all libraries in meta table
	for(iLibrary=0;iLibrary<itemsinlist(sAllMetaLibraries);iLibrary+=1)
		 sThisLibrary = stringfromlist(iLibrary,sAllMetaLibraries)
		 for(iSample=0;iSample<vTotalSamples;iSample+=1)
		 endfor
	endfor
	
	//all libraries in library data
	for(iLibrary=0;iLibrary<itemsinlist(sAllLibraryLibraries);iLibrary+=1)
		 sThisLibrary = stringfromlist(iLibrary,sAllLibraryLibraries)
		 for(iSample=0;iSample<vTotalSamples;iSample+=1)
		 endfor
	endfor
	
	//all libraries as folders
	for(iLibrary=0;iLibrary<itemsinlist(sAllFolderLibraries);iLibrary+=1)
		 sThisLibrary = stringfromlist(iLibrary,sAllFolderLibraries)
		 for(iSample=0;iSample<vTotalSamples;iSample+=1)
		 endfor
	endfor
	
end

function Combi_CheckDataLocation(sProject,sLibrary,sDataType,iDim)
	string sProject
	string sLibrary
	string sDataType
	int iDim
	int bReturn = 0
	
	if(iDim==-1)
		if(waveexists($Combi_DataPath(sProject,-1)))
			wave wMeta = $Combi_DataPath(sProject,-1)
			if(FindDimLabel(wMeta,1,sDataType)>=0)
				if(FindDimLabel(wMeta,0,sLibrary)>=0)
					bReturn = 1
				endif
			endif
		endif
	elseif(iDim==0)
		if(waveexists($Combi_DataPath(sProject,0)))
			wave wLibrary = $Combi_DataPath(sProject,0)
			if(FindDimLabel(wLibrary,1,sDataType)>=0)
				if(FindDimLabel(wLibrary,0,sLibrary)>=0)
					bReturn = 1
				endif
			endif
		endif
	elseif(iDim==1)
		if(waveexists($Combi_DataPath(sProject,1)+sLibrary+":"+sDataType))
			bReturn = 1
		endif
	elseif(iDim==2)
		if(waveexists($Combi_DataPath(sProject,2)+sLibrary+":"+sDataType))
			bReturn = 1
		endif
	elseif(iDim==3)
		if(waveexists($Combi_DataPath(sProject,3)+sLibrary+":"+sDataType))
			bReturn = 1
		endif
	endif
	return bReturn
end

function Combi_CheckForLibrary(sProject,sLibrary,iDim)
	string sProject
	string sLibrary
	int iDim //-3 for any, -2 for all, -1 for meta, 0 for library, 1 for scalar, 2 for vector, 3 for matrix
	int bReturn = 0
	int bMeta=0, bLibrary=0, bScalar=0, bVector=0, bMatrix=0
	if(waveexists($Combi_DataPath(sProject,-1)))
		wave wMeta = $Combi_DataPath(sProject,-1)
		if(FindDimLabel(wMeta,0,sLibrary)>=0)
			bMeta = 1
		endif
	endif
	if(waveexists($Combi_DataPath(sProject,0)))
		wave wLibrary = $Combi_DataPath(sProject,0)
		if(FindDimLabel(wLibrary,0,sLibrary)>=0)
			bLibrary = 1
		endif
	endif

	if(DataFolderExists(Combi_DataPath(sProject,1)+sLibrary))
		bScalar = 1
	endif
	if(DataFolderExists(Combi_DataPath(sProject,2)+sLibrary))
		bVector = 1
	endif
	if(DataFolderExists(Combi_DataPath(sProject,3)+sLibrary))
		bMatrix = 1
	endif
	
	if(iDim==-3)
	 	return bMeta||bLibrary||bVector||bScalar||bMatrix
	elseif(iDim==-2)
		return bMeta&&bLibrary&&bVector&&bScalar&&bMatrix
	elseif(iDim==-1)
		return bMeta
	elseif(iDim==0)
		return bLibrary
	elseif(iDim==2)
		return bVector
	elseif(iDim==1)
		return bScalar
	elseif(iDim==2)
		return bMatrix
	endif
	
	return 0
end

function Combi_CheckForDataType(sProject,sLibrary,sDataType,iDim)
	string sProject
	string sLibrary
	string sDataType
	int iDim //-3 for any, -2 for all, -1 for meta, 0 for library, 1 for scalar, 2 for vector, 3 for matrix
	int bReturn = 0
	int bMeta=0, bLibrary=0, bScalar=0, bVector=0, bMatrix=0
	if(waveexists($Combi_DataPath(sProject,-1)))
		wave wMeta = $Combi_DataPath(sProject,-1)
		if(FindDimLabel(wMeta,0,sLibrary)>=0)
			if(FindDimLabel(wMeta,2,sDataType)>=0)
				bMeta = 1
			endif
		endif
	endif
	if(waveexists($Combi_DataPath(sProject,0)))
		wave wLibrary = $Combi_DataPath(sProject,0)
		if(FindDimLabel(wLibrary,0,sLibrary)>=0)
			if(FindDimLabel(wLibrary,1,sDataType)>=0)
				bLibrary = 1
			endif
		endif
	endif
	if(waveexists($Combi_DataPath(sProject,1)+sLibrary+":"+sDataType))
		wave wThisScalarWave = $Combi_DataPath(sProject,1)+sLibrary+":"+sDataType
		if(dimsize(wThisScalarWave,0)==Combi_GetGlobalNumber("vTotalSamples",sProject))
			if(dimsize(wThisScalarWave,1)==0)
				bScalar = 1
			endif
		endif
	endif
	if(waveexists($Combi_DataPath(sProject,2)+sLibrary+":"+sDataType))	
		wave wThisVectorWave = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataType
		if(dimsize(wThisVectorWave,0)==Combi_GetGlobalNumber("vTotalSamples",sProject))
			if(dimsize(wThisVectorWave,1)>1)
				bVector = 1
			endif
		endif
	endif
	if(waveexists($Combi_DataPath(sProject,3)+sLibrary+":"+sDataType))	
		wave wThisMatrixWave = $Combi_DataPath(sProject,3)+sLibrary+":"+sDataType
		if(dimsize(wThisMatrixWave,2)==Combi_GetGlobalNumber("vTotalSamples",sProject))
			if(dimsize(wThisMatrixWave,1)>1)
				if(dimsize(wThisMatrixWave,2)>1)
					bMatrix = 1
				endif
			endif
		endif
	endif
	
	if(iDim==-3)
	 	return bMeta||bLibrary||bVector||bScalar||bMatrix
	elseif(iDim==-2)
		return bMeta&&bLibrary&&bVector&&bScalar&&bMatrix
	elseif(iDim==-1)
		return bMeta
	elseif(iDim==0)
		return bLibrary
	elseif(iDim==2)
		return bVector
	elseif(iDim==1)
		return bScalar
	elseif(iDim==3)
		return bMatrix
	endif
	return 0
end

function Combi_CheckForData(sProject,sLibrary,sDataType,iDim,iSample)
	string sProject
	string sLibrary
	string sDataType
	int iDim
	int iSample // for iDim = 1,2,3 only, otherwise ignored, -1 for all samples
	int bReturn = 0
	int iFirstSample = iSample
	int iLastSample = iSample
	int iThisSample
	if(iSample==-1)
		iFirstSample = 0
		iLastSample = COMBI_GetGlobalNumber("vTotalSamples",sProject)-1
	endif
	if(iDim==-1)
		if(waveexists($Combi_DataPath(sProject,-1)))
			wave/T wMeta = $Combi_DataPath(sProject,-1)
			if(FindDimLabel(wMeta,1,sDataType)>=0)
				if(FindDimLabel(wMeta,0,sLibrary)>=0)
					if(strlen(wMeta[%$sLibrary][%$sDataType])>0)
						bReturn = 1
					endif
				endif
			endif
		endif
	elseif(iDim==0)
		if(waveexists($Combi_DataPath(sProject,0)))
			wave wLibrary = $Combi_DataPath(sProject,0)
			if(FindDimLabel(wLibrary,1,sDataType)>=0)
				if(FindDimLabel(wLibrary,0,sLibrary)>=0)
					if(numtype(wLibrary[%$sLibrary][%$sDataType])==0)
						bReturn = 1
					endif
				endif
			endif
		endif
	elseif(iDim==1)
		if(waveexists($Combi_DataPath(sProject,1)+sLibrary+":"+sDataType))
			wave wScalarData = $Combi_DataPath(sProject,1)+sLibrary+":"+sDataType
			for(iThisSample=iFirstSample;iThisSample<=iLastSample;iThisSample+=1)
				if(numtype(wScalarData[iThisSample])==0)
					bReturn = 1
				endif
			endfor
		endif
	elseif(iDim==2)
		if(waveexists($Combi_DataPath(sProject,2)+sLibrary+":"+sDataType))
			wave wVectorData = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataType
			for(iThisSample=iFirstSample;iThisSample<=iLastSample;iThisSample+=1)
				if(numtype(wVectorData[iThisSample][0])==0)
					bReturn = 1
				endif
			endfor
		endif
	elseif(iDim==3)
		if(waveexists($Combi_DataPath(sProject,3)+sLibrary+":"+sDataType))
			wave wMatrixData = $Combi_DataPath(sProject,3)+sLibrary+":"+sDataType
			for(iThisSample=iFirstSample;iThisSample<=iLastSample;iThisSample+=1)
				if(numtype(wMatrixData[0][0][iThisSample])==0)
					bReturn = 1
				endif
			endfor
		endif
	endif
	return bReturn
end

function/S Combi_IntoDataFolder(sProject,iDim)
	string sProject // for this project
	Int iDim// 1 for Scalar, 2 for Vector, 3 for matrix
	if(iDim<1)
		return "root:"
	endif
	string sDataType
	setdatafolder root:
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S $sProject
	NewDataFolder/O/S Data
	Return Combi_DataPath(sProject,iDim)
end

//to see Meta wave
function/S Combi_SeeMetaTable(sProject)
	string sProject // for this project
	//get wave to view
	wave wMeta = $Combi_DataPath(sProject,-1)
	edit/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/N=$"Meta" wMeta.ld as sProject+" Meta Data in COMBIgor"
	ModifyTable elements=(-3,0,-2),alignment=1		
	ModifyTable width=100
	return WinName(0,2)
end

//to see scalar wave, returns name of table
function/S Combi_SeeLibraryTable(sProject)
	string sProject // for this project
	//get wave to view
	wave wLibrary = $Combi_DataPath(sProject,0)
	edit/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/N=$"Library" wLibrary.ld as sProject+" Library Data in COMBIgor"
	ModifyTable elements=(-3,-2),alignment=1		
	ModifyTable width=100
	return WinName(0,2)
end

//return combi project folder names
function/S Combi_Projects()
	//get Combi_Globals from COMBIgor folder
	wave/T/Z twGlobals = root:Packages:COMBIgor:Combi_Globals
	if(!waveExists(twGlobals))
		return ""
	endif
	//make list of labels
	variable iIndex
	string sThisList=""
	For(iIndex=2;iIndex<DimSize(twGlobals,1);iIndex+=1)
		sThisList=AddListItem(GetDimLabel(twGlobals,1,iIndex),sThisList,";",Inf) 
	endfor 	
	// return string list of projects
	return sThisList
end

//Export Path managing function
//sets new path if sAction = "New" then returns string of path
//returns previous path if sAction = "Read"
//returns a new path but doesn't update value of sExportOption global if sAction = "Temp"
//returns "NO PATH" path if user has defined "None" for sExportOption global
function/T Combi_ExportPath(sAction)
	string sAction // defines the action desired
		
	//if sAction = "New"
	if(stringmatch(sAction,"New"))
		DoAlert/T="COMBIgor Setup" 0, "Choose an Export Path. This will be a folder where things are automatically exported to when export functions are executed."
		NewPath/C/M="New Graphics Export Path:"/O/Q/Z pNewPath
		PathInfo pNewPath
		string sThisNewPath = S_path
		killpath pNewPath
		Combi_GiveGlobal("sExportPath",sThisNewPath,"COMBIgor")
		return sThisNewPath
	endif
	
	//if sAction = "Read"
	if(stringmatch(sAction,"Read"))
		//if sExportOption Global = "None"
		if(stringmatch(Combi_GetGlobalString("sExportOption","COMBIgor"),"None"))
			return "NO PATH"
		else
			return Combi_GetGlobalString("sExportPath","COMBIgor")
		endif
	endif
	
	//if sAction = "Temp"
	if(stringmatch(sAction,"Temp"))
		DoAlert/T="COMBIgor Setup" 0, "Choose an Export Path. This will be a folder where things are automatically exported to when export functions are executed."
		NewPath/C/M="New Graphics Export Path:"/O/Q/Z pNewPath
		PathInfo pNewPath
		string sThisNewTempPath = S_path
		killpath pNewPath
		return sThisNewTempPath
	endif

end

//Import Path managing function
//sets new path if sAction = "New" then returns string of path
//returns previous path if sAction = "Read"
//returns a new path but doesn't update value of sImportOption global if sAction = "Temp"
//returns "NO PATH" path if user has defined "None" for sImportOption global
function/S Combi_ImportPath(sAction)
	string sAction // defines the action desired
	
	//if sExportOption Global = "None"
	if(stringmatch(Combi_GetGlobalString("sImportOption","COMBIgor"),"None"))
		return "NO PATH"
	endif
	
	//if sAction = "New"
	if(stringmatch(sAction,"New"))
		DoAlert/T="COMBIgor Setup" 0, "Choose an Import Path. This will be a folder where open dialog boxes default to in COMBIgor."
		NewPath/C/M="New Graphics Import Path:"/O/Q/Z pNewPath
		PathInfo pNewPath
		string sThisNewPath = S_path
		killpath pNewPath
		Combi_GiveGlobal("sImportPath",sThisNewPath,"COMBIgor")
		return sThisNewPath
	endif
	
	//if sAction = "Read"
	if(stringmatch(sAction,"Read"))
		return Combi_GetGlobalString("sImportPath","COMBIgor")
	endif
	
	//if sAction = "Temp"
	if(stringmatch(sAction,"Temp"))
		DoAlert/T="COMBIgor Setup" 0, "Choose an Import Path. This will be a folder where open dialog boxes default to in COMBIgor."
		NewPath/C/M="New Graphics Import Path:"/O/Q/Z pNewPath
		PathInfo pNewPath
		string sThisNewTempPath = S_path
		killpath pNewPath
		return sThisNewTempPath
	endif
end

//function to have user choose the project of interest
function/S Combi_ChooseProject()
	
	//ActiveFolder global
	string sActiveFolder = Combi_GetGlobalString("sActiveFolder", "COMBIgor")
	
	//if global doesn't exist?
	string sProjectOfInterst
	if(stringmatch(sActiveFolder,"NAG"))
		sProjectOfInterst=""
	else
		sProjectOfInterst= sActiveFolder
	endif
	
	//get all folders
	string sAllProjects=Combi_Projects()
	
	//get folder if more than 1
	string sProject
	if(itemsinlist(sAllProjects)==0)
		Combi_StartNewProject()
		sProject = stringfromlist(0,Combi_Projects())
	elseif(itemsinlist(sAllProjects)==1)
		sProject = stringfromlist(0,sAllProjects)
	else
		prompt sProject, "Project:",Popup,sProjectOfInterst+";"+sAllProjects
		doprompt "Which Project?", sProject
		if(V_Flag)
			return ""
		endif
	endif
	
	//write global
	Combi_GiveGlobal("sActiveFolder",sProject,"COMBIgor")
	
	//return project
	return sProject
end

function/S Combi_DataPath(sProject,iDim)
	string sProject // for this project
	Int iDim////-2 for mapping grid,-1 for meta, 0 for Library, 1 for Scalar, 2 for Vector, 3 for Matrix
	if(iDim==-2)
		Return "root:COMBIgor:"+sProject+":MappingGrid"
	elseif(iDim==-1)
		Return "root:COMBIgor:"+sProject+":Data:Meta"
	elseif(iDim==0)
		Return "root:COMBIgor:"+sProject+":Data:Library"
	elseif(iDim==1)
		Return "root:COMBIgor:"+sProject+":Data:"
	elseif(iDim==2)
		Return "root:COMBIgor:"+sProject+":Data:"
	elseif(iDim==3)
		Return "root:COMBIgor:"+sProject+":Data:"
	endif
end

//saves the users current data folder to return to after a function executes, sets curernt data folder to root
//care needs to be taken such that the value of the data folder is not written over before returning to the data folder
function COMBI_SaveUsersDataFolder()
	Combi_GiveGlobal("sUsersCurrentFolder",GetDataFolder(1),"COMBIgor")
end

//returns to the saved user data folder after completing function execution
//care needs to be taken such that the value of the data folder was not re-written between the last intentional save
function COMBI_Return2UsersDataFolder()
	setdatafolder $Combi_GetGlobalString("sUsersCurrentFolder","COMBIgor")
end

function Combi_Save(sProject,sWindow,sSubFolderList,sFilename,sOption)
	string sProject//COMBIgor Project
	string sWindow//Name of window to save
	string sSubFolderList//list of folders to nest into
	string sFilename//name of file
	string sOption //"PDF", or "Notebook""
	
	//get save path
	string sExportOption = Combi_GetGlobalString("sExportOption","COMBIgor")
	if(stringmatch(sExportOption,"None"))
		NewPath/O/Q/M="Where to save?" pExportPath
		PathInfo pExportPath
		if(V_flag==0)
			return -1
		endif
		sExportOption = S_path
		killvariables/Z root:V_flag, root:S_path
	else
		sExportOption = Combi_GetGlobalString("sExportPath", "COMBIgor")
		NewPath/O/Q pExportPath, sExportOption
	endif
	
	//make folders if needed
	int iSubFolder
	for(iSubFolder=0;iSubFolder<itemsinlist(sSubFolderList);iSubFolder+=1)
		sExportOption = sExportOption+stringfromList(iSubFolder,sSubFolderList)+":"
		NewPath/O/Q/C pExportPath, sExportOption 
	endfor
	
	//save graphic PDF
	if(stringmatch(sOption,"PDF"))
		SavePICT/EF=2/M/O/P=pExportPath/WIN=$sWindow/Z/E=-8 as sFilename+".pdf"
	endif
	
	//save notebook
	if(stringmatch(sOption,"Notebook"))
		string sNBName = stringfromlist(0,WinList("*", ";", "WIN:16" ))
		SaveNotebook/O/P=pExportPath/S=8 $sNBName as sFilename+".txt"
	endif
	
	//clean up
	killpath/Z pExportPath
end

function/S Combi_AllDataTypes(sProject, sLibrary, sWaveFilter, bRecursive)
	string sProject, sLibrary, sWaveFilter
	int bRecursive
	//variables
	string sSub1FolderList, sSub2FolderList, sSub3FolderList
	string sSub1FolderDataTypes, sSub2FolderDataTypes, sSub3FolderDataTypes
	int iSub1Folder,iSub2Folder, iSub3Folder
	int iSub1DataType, iSub2DataType, iSub3DataType
	string sCurrentFolder, sToReturn
	//into library folder
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder $"root:COMBIgor:"+sProject+":Data:"+sLibrary
	//main level
	string sAllDataTypes = WaveList("*", ";",sWaveFilter)
	//below main level
	if(bRecursive==1)
		//sub1folder
		sSub1FolderList = ReplaceString(",",StringByKey("FOLDERS", DataFolderDir(1)),";")
		for(iSub1Folder=0; iSub1Folder<itemsInList(sSub1FolderList); iSub1Folder+=1)
			sCurrentFolder = stringFromList(iSub1Folder, sSub1FolderList)
			SetDataFolder $sCurrentFolder 
			//pull data types from sub1folder
			sSub1FolderDataTypes = WaveList("*",";",sWaveFilter)
			// append subfolder name to data types, add to data type list
			for(iSub1DataType=0; iSub1DataType<itemsInList(sSub1FolderDataTypes); iSub1DataType+=1)
				sAllDataTypes = addListItem(sCurrentFolder+":"+stringFromList(iSub1DataType, sSub1FolderDataTypes), sAllDataTypes)
			endFor
			//sub2folder
			sSub2FolderList = ReplaceString(",",StringByKey("FOLDERS", DataFolderDir(1)),";")
			for(iSub2Folder=0; iSub2Folder<itemsInList(sSub2FolderList); iSub2Folder+=1)
				sCurrentFolder = stringFromList(iSub1Folder, sSub1FolderList)+":"+stringFromList(iSub2Folder, sSub2FolderList)
				SetDataFolder $stringFromList(iSub2Folder, sSub2FolderList) 
				//pull data types from sub1folder
				sSub2FolderDataTypes = WaveList("*",";",sWaveFilter)
				// append subfolder name to data types, add to data type list
				for(iSub2DataType=0; iSub2DataType<itemsInList(sSub2FolderDataTypes); iSub2DataType+=1)
					sAllDataTypes = addListItem(sCurrentFolder+":"+stringFromList(iSub2DataType, sSub2FolderDataTypes), sAllDataTypes)
				endFor
				//sub3folder
				sSub3FolderList = ReplaceString(",",StringByKey("FOLDERS", DataFolderDir(1)),";")
				for(iSub3Folder=0; iSub3Folder<itemsInList(sSub3FolderList); iSub3Folder+=1)
					sCurrentFolder = stringFromList(iSub1Folder, sSub1FolderList)+":"+stringFromList(iSub2Folder, sSub2FolderList)+":"+stringFromList(iSub3Folder, sSub3FolderList)
					SetDataFolder $stringFromList(iSub3Folder, sSub3FolderList) 
					//pull data types from sub1folder
					sSub3FolderDataTypes = WaveList("*",";",sWaveFilter)
					// append subfolder name to data types, add to data type list
					for(iSub3DataType=0; iSub3DataType<itemsInList(sSub3FolderDataTypes); iSub3DataType+=1)
						sAllDataTypes = addListItem(sCurrentFolder+":"+stringFromList(iSub3DataType, sSub3FolderDataTypes), sAllDataTypes)
					endFor
					//back to main folder
					SetDataFolder $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+stringFromList(iSub1Folder, sSub1FolderList)+":"+stringFromList(iSub2Folder, sSub2FolderList)
				endFor
				//back to main folder
				SetDataFolder $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+stringFromList(iSub1Folder, sSub1FolderList)
			endFor
			//back to main folder
			SetDataFolder $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"
		endFor
	endif
	setdatafolder $sTheCurrentUserFolder
	return sAllDataTypes
	
end

//function to return all label names, if sOption = Libraries or sOption = DataTypes
function/S Combi_TableList(sProject,iDimension,sLibraryOfInterest,sOption,[bRecursive])
    string sProject // project to operate within, "AllCOMBIgor" for all
    variable iDimension // dimensionality of data set, -3 for all, -2 for all numeric, -1 for meta, 0 for Library, 1 for scalar, 2 for vector, 3 for matrix
    string sOption // Libraries, DataTypes, or DataTypeswDim
    string sLibraryOfInterest //Library to return data types for, or "All" for all Libraries
    int bRecursive // Whether to list waves in subfolders: 1 for yes, 0 for no
    if(paramIsDefault(bRecursive))
    	bRecursive = 1
    endif
    
    string sTheCurrentUserFolder = GetDataFolder(1) 
   
    if(strlen(sProject)==0||stringmatch(sProject," "))
       return ""
    endif
    if(strlen(sProject)==0||stringmatch(sProject," "))
       return ""
    endif
   
    string sProjects
    if(stringmatch(sProject,"AllCOMBIgor"))
       sProjects = COMBI_Projects()
    else
       sProjects = sProject
    endif

    string sMeta = ""
    string sLibrary = ""
    string sVector = ""
    string sScalar = ""
    string sMatrix = ""
    int iDataType, iProject
    string sAllDataTypes
    for(iProject=0;iProject<itemsinlist(sProjects);iProject+=1)
      
       sProject = stringFromList(iProject,sProjects)
              
       //get COMBIgor waves
       wave/Z wMeta = $"root:COMBIgor:"+sProject+":Data:"+"Meta"
       wave/Z wLibrary = $"root:COMBIgor:"+sProject+":Data:"+"Library"
      
       //variables for loop control
       variable iLibrary
       //get all from Meta
       if(stringmatch(sOption,"Libraries"))
           for(iLibrary=1;iLibrary<DimSize(wMeta,0);iLibrary+=1)
               sMeta = AddListItem(GetDimLabel(wMeta,0,iLibrary),sMeta,";",Inf)
           endfor
       elseif(stringmatch(sOption,"DataTypes"))
           for(iLibrary=1;iLibrary<DimSize(wMeta,2);iLibrary+=1)
               sMeta = AddListItem(GetDimLabel(wMeta,2,iLibrary),sMeta,";",Inf)
           endfor
       endif
      
      
       //get all from Library
       if(stringmatch(sOption,"Libraries"))
           for(iLibrary=1;iLibrary<DimSize(wLibrary,0);iLibrary+=1)
               sLibrary = AddListItem(GetDimLabel(wLibrary,0,iLibrary),sLibrary,";",Inf)
           endfor
       elseif(stringmatch(sOption,"DataTypes"))
           for(iLibrary=1;iLibrary<DimSize(wLibrary,1);iLibrary+=1)
               sLibrary = AddListItem(GetDimLabel(wLibrary,1,iLibrary),sLibrary,";",Inf)
           endfor
       endif

      
       //get all from scalar
       string sWaveFilter
       setdatafolder root:
       setdataFolder COMBIgor
       setdataFolder $sProject
       setdatafolder Data
       string sAllLibraries = ReplaceString(",",StringByKey("FOLDERS", DataFolderDir(1)),";")
       sAllLibraries = Replacestring(";;",sAllLibraries,";")
       setdatafolder root:
       if(stringmatch(sOption,"Libraries"))
           sScalar += sAllLibraries+";"
       elseif(stringmatch(sOption,"DataTypes"))
           if(!stringmatch(sLibraryOfInterest,"All"))
               sAllLibraries = sLibraryOfInterest
           endif
           for(iLibrary=0;iLibrary<itemsinlist(sAllLibraries);iLibrary+=1)
               sWaveFilter = "DIMS:1,MAXROWS:"+Combi_GetGlobalString("vTotalSamples",sProject)+",MINROWS:"+Combi_GetGlobalString("vTotalSamples",sProject)
               sAllDataTypes = Combi_AllDataTypes(sProject, stringfromlist(iLibrary,sAllLibraries), sWaveFilter, bRecursive)
               for(iDataType=0;iDataType<itemsinlist(sAllDataTypes);iDataType+=1)
                   if(whichlistitem(stringfromlist(iDataType,sAllDataTypes),sScalar)==-1)
                      sScalar = AddListItem(stringfromlist(iDataType,sAllDataTypes),sScalar,";",Inf)
                  endif
               endfor
           endfor
       endif
      
       //get all from vector
       if(stringmatch(sOption,"Libraries"))
           sVector += sAllLibraries+";"
       elseif(stringmatch(sOption,"DataTypes"))
           if(!stringmatch(sLibraryOfInterest,"All"))
               sAllLibraries = sLibraryOfInterest
           endif
           for(iLibrary=0;iLibrary<itemsinlist(sAllLibraries);iLibrary+=1)
           		sWaveFilter = "DIMS:2,MAXROWS:"+Combi_GetGlobalString("vTotalSamples",sProject)+",MINROWS:"+Combi_GetGlobalString("vTotalSamples",sProject)+",MINCOLS:2"
               sAllDataTypes = Combi_AllDataTypes(sProject, stringfromlist(iLibrary,sAllLibraries), sWaveFilter, bRecursive)
               for(iDataType=0;iDataType<itemsinlist(sAllDataTypes);iDataType+=1)
                  if(whichlistitem(stringfromlist(iDataType,sAllDataTypes),sVector)==-1)
                      sVector = AddListItem(stringfromlist(iDataType,sAllDataTypes),sVector,";",Inf)
                  endif
               endfor
           endfor
       elseif(stringmatch(sOption,"DataTypeswDim"))
           if(!stringmatch(sLibraryOfInterest,"All"))
               sAllLibraries = sLibraryOfInterest
           endif
           for(iLibrary=0;iLibrary<itemsinlist(sAllLibraries);iLibrary+=1)
               sWaveFilter = "DIMS:2,MAXROWS:"+Combi_GetGlobalString("vTotalSamples",sProject)+",MINROWS:"+Combi_GetGlobalString("vTotalSamples",sProject)+",MINCOLS:2"
               sAllDataTypes = Combi_AllDataTypes(sProject, stringfromlist(iLibrary,sAllLibraries), sWaveFilter, bRecursive)
               for(iDataType=0;iDataType<itemsinlist(sAllDataTypes);iDataType+=1)
                  wave wVectorTest = $COMBI_DataPath(sProject, 2) + stringfromlist(iLibrary,sAllLibraries) + ":" + stringfromlist(iDataType, sAllDataTypes)
                  if(whichlistitem(stringfromlist(iDataType, sAllDataTypes), sVector)==-1 && strlen(getDimLabel(wVectorTest,1,0)) != 0)
                      sVector = AddListItem(stringfromlist(iDataType,sAllDataTypes),sVector,";",Inf)
                  endif
               endfor
           endfor
       endif
      
       //get all from matrix
       if(stringmatch(sOption,"Libraries"))
           sMatrix += sAllLibraries+";"
       elseif(stringmatch(sOption,"DataTypes"))
               if(!stringmatch(sLibraryOfInterest,"All"))
                   sAllLibraries = sLibraryOfInterest
               endif
           for(iLibrary=0;iLibrary<itemsinlist(sAllLibraries);iLibrary+=1)
           		sWaveFilter = "DIMS:3,MAXLAYERS:"+Combi_GetGlobalString("vTotalSamples",sProject)+",MINLAYERS:"+Combi_GetGlobalString("vTotalSamples",sProject)
               sAllDataTypes = Combi_AllDataTypes(sProject, stringfromlist(iLibrary,sAllLibraries), sWaveFilter, bRecursive)
               for(iDataType=0;iDataType<itemsinlist(sAllDataTypes);iDataType+=1)
                   if(whichlistitem(stringfromlist(iDataType,sAllDataTypes),sMatrix)==-1)
                      sMatrix = AddListItem(stringfromlist(iDataType,sAllDataTypes),sMatrix,";",Inf)
                  endif
               endfor
           endfor
       endif
    endfor
   
    //build list for all
    string sFullList =""
    string sFullListAll = ""
    if(strlen(sMeta)>0)
       sFullListAll += sMeta+";"
    endif
    if(strlen(sLibrary)>0)
       sFullListAll += sLibrary+";"
       sFullList += sLibrary+";"
    endif
    if(strlen(sScalar)>0)
       sFullListAll += sScalar+";"
       sFullList += sScalar+";"
    endif
    if(strlen(sVector)>0)
       sFullListAll += sVector+";"
       sFullList += sVector+";"
    endif
    if(strlen(sMatrix)>0)
       sFullListAll += sMatrix+";"
       sFullList += sMatrix+";"
    endif
   
    sFullList = sortList(sFullList,";",32)
    sFullListAll = sortList(sFullListAll,";",32)
    
    setdatafolder root:
    setdatafolder $sTheCurrentUserFolder
   
    //return proper list
    if(iDimension==-3)
       return sortList(sFullListAll,";",0)
    elseif(iDimension==-2)
       return sortList(sFullList,";",0)
    elseif(iDimension==-1)
       return sortList(sMeta,";",0)
    elseif(iDimension==0)
       return sortList(sLibrary,";",0)
    elseif(iDimension==1)
       return sortList(sScalar,";",0)
    elseif(iDimension==2)
       return sortList(sVector,";",0)
    elseif(iDimension==3)
       return sortList(sMatrix,";",0)
    endif
   
end
 

