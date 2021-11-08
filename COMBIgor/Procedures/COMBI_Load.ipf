#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
	// V1:	Sage Bauers _ 20180520 : New
	// V1.01	Sage Bauers _ 20180525 : Added multiple Library capability
	// V1.02: Karen Heinselman _ Oct 2018 : Polishing and debugging
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//function to prompt for and return a Library name
//returns "CANCEL" if user canceled 
//returns a list of Libraries if more than 1
function/S COMBI_LibraryPrompt(sProject,sStartLibraries,sLibraryDescription,vNumberOption,vAddOption,vSkipOption,iDimension)
	string sProject //COMBIgor project to operate within
	string sStartLibraries // starting value in prompt, list for mulitples, "New" for new or "Skip" for skip to start
	string sLibraryDescription //optional descritive text to user prompt, List for multiple that matches length of sStartLibraries 
	variable vNumberOption // 1 for set number of Libraries (determined by length of sStartLibraries), 0 for option
	variable vAddOption // 1 to enable Library adding, 0 for existing only
	variable vSkipOption // 1 to enalbe Library skipping, 0 to disable 
	variable iDimension // 0 for Library, 1 for scalar, and 2 for vector, 3 for matrix, -1 for all
	
	//variables to use
	string sLibrariesList = ""//to return
	string sExistingLibraries //options for prompt
	string sLibraryInput //choosen Library
	string sNewLibraryInput = "Input New Library Name Here!" //typed in if new
	variable vNumberofLibraries = itemsinlist(sStartLibraries) //number of Libraries to prompt for.
	string sNewString = ""
	string sSkipString = ""
	string sDecriptionToUse = ""
	
	//get existing Libraries in COMBIgor
	if(!stringmatch(sStartLibraries,"New"))
		if(!stringmatch(sStartLibraries,"Skip"))
			sExistingLibraries = sStartLibraries+";"+COMBI_TableList(sProject,iDimension,"All","Libraries")
		else
			sExistingLibraries = " ;"+COMBI_TableList(sProject,iDimension,"All","Libraries")
		endif
	else
		sExistingLibraries = " ;"+COMBI_TableList(sProject,iDimension,"All","Libraries")
	endif
	
	//get number of Libraries
	prompt vNumberofLibraries, "Number of Libraries:"
	if(vNumberOption==1)
		DoPrompt/HELP="Please enter the number of libraries." "How many libraries?", vNumberofLibraries
		if (V_Flag)
			return "CANCEL"
		endif
	else
		vNumberofLibraries = itemsinlist(sStartLibraries)
	endif
	
	//for each Library
	variable iLibrary
	for(iLibrary=0;iLibrary<vNumberofLibraries;iLibrary+=1)
		//start value
		if((itemsinlist(sStartLibraries))>iLibrary)
			sLibraryInput = stringfromlist(iLibrary,sStartLibraries)
		else
			sLibraryInput = stringfromlist(0,sStartLibraries)
		endif
		if(stringmatch(sLibraryInput,"New"))
			sLibraryInput = "New Library"
		elseif(stringmatch(sLibraryInput,"Skip"))
			sLibraryInput = "Skip Library"
		endif
		sExistingLibraries = sStartLibraries+";"+COMBI_TableList(sProject,iDimension,"All","Libraries")
		//build drop down
		if(vSkipOption==1||stringmatch(sStartLibraries,"Skip"))
			sExistingLibraries = "Skip Library;"+sExistingLibraries
		endif
		if(vAddOption==1||stringmatch(sStartLibraries,"New"))
			sExistingLibraries = "New Library;"+sExistingLibraries
		endif
		sNewLibraryInput = sLibraryInput
		// make prompts
		prompt sLibraryInput, sLibraryDescription, Popup, sExistingLibraries
		prompt sNewLibraryInput, "Name if \"New Library\" above:"
		//prompt for Library name
		if(vAddOption==1)
			DoPrompt/HELP="This specifies the name of this library." "Library Input", sLibraryInput, sNewLibraryInput
		else
			DoPrompt/HELP="This specifies the name of this library." "Library Input", sLibraryInput
		endif
		
		if (V_Flag)
			return "CANCEL"
		endif
		//if new
		if(stringmatch(sLibraryInput,"New Library"))
			sLibraryInput = cleanupname(sNewLibraryInput,0)
		endif
		//if Skip
		if(stringmatch(sLibraryInput,"Skip Library"))
			sLibraryInput = "Skip"
		endif
		//add to Library list
		if(iLibrary==0)
			sLibrariesList = sLibraryInput
		else
			sLibrariesList = sLibrariesList+";"+sLibraryInput
		endif
		//add to table
		if(!stringmatch("Skip",sLibraryInput))
			COMBI_AddLibrary(sProject,sLibraryInput,iDimension)
		endif	
	
	endfor
	
	//return Library names 
	return sLibrariesList
	
end

//function to prompt for and return a data type
//returns "CANCEL" if user canceled 
//returns a list of data types if more than 1
function/S COMBI_DataTypePrompt(sProject,sStartDataTypes,sDataTypeDescription,vNumberOption,vAddOption,vSkipOption,iDimension,[sLibraries])
	string sProject //COMBIgor project to operate within
	string sStartDataTypes // starting value in prompt, list for mulitples, "New" for new or "Skip" for skip to start
	string sDataTypeDescription //optional descritive text to user prompt, List for multiple that matches length of sStartDataTypes
	variable vNumberOption // 1 for set number of DataTypes (determined by length of sStartDataTypes), 0 for option
	variable vAddOption // 1 to enable DataType adding, 0 for existing only
	variable vSkipOption // 1 to enalbe DataType skipping, 0 to disable 
	variable iDimension // dimensionality of data set, -3 for all, -2 for all numeric, -1 for meta, 0 for Library, 1 for scalar, 2 for vector, 3 for matrix
	string sLibraries //a list of libraries to find data types when looking for iDimension = 1 or 2
	
	//variables to use
	string sDataTypesList = ""//to return
	string sExistingDataTypes //options for prompt
	string sDataTypeInput //choosen DataType
	string sNewDataTypeInput = "Input New Data Type Name Here!" //typed in if new
	variable vNumberofDataTypes = itemsinlist(sStartDataTypes) //number of DataTypes to prompt for.
	string sNewString = ""
	string sSkipString = ""
	string sDecriptionToUse = ""
	
	//get existing DataTypes in COMBIgor
	sExistingDataTypes = sStartDataTypes+";"+COMBI_TableList(sProject,iDimension,"All","DataTypes")
	
	//get number of DataTypes
	prompt vNumberofDataTypes, "Number of Data Types:"
	if(vNumberOption==1)
		DoPrompt/HELP="Please enter the number of data types" "How many data types?", vNumberofDataTypes
		if (V_Flag)
			return "CANCEL"
		endif
	else
		vNumberofDataTypes = itemsinlist(sStartDataTypes)
	endif
	
	//if library given
	string sLibraries2Include = "All"
	if(!paramIsDefault(sLibraries))
		sLibraries2Include = sLibraries
	endif
	
	
	//for each DataType
	variable iDataType
	for(iDataType=0;iDataType<vNumberofDataTypes;iDataType+=1)
		//start value
		if((itemsinlist(sStartDataTypes))>iDataType)
			sDataTypeInput = stringfromlist(iDataType,sStartDataTypes)
			if(itemsinlist(sDataTypeDescription)>iDataType)
				sDecriptionToUse = stringfromlist(iDataType,sDataTypeDescription)
			else
				sDecriptionToUse = "Data Type"
			endif
		else
			sDataTypeInput = stringfromlist(0,sStartDataTypes)
			sDecriptionToUse = "Data Type"
		endif
		sExistingDataTypes = sStartDataTypes+";"+COMBI_TableList(sProject,iDimension,stringfromlist(iDataType,sLibraries2Include),"DataTypes")
		if(stringmatch(sDataTypeInput,"New"))
			sDataTypeInput = "New Data"
		elseif(stringmatch(sDataTypeInput,"Skip"))
			sDataTypeInput = "Skip Data"
		endif
		//build drop down
		if(vSkipOption==1||stringmatch(sStartDataTypes,"Skip"))
			sExistingDataTypes = "Skip Data;"+sExistingDataTypes
		endif
		if(vAddOption==1||stringmatch(sStartDataTypes,"New"))
			sExistingDataTypes = "New Data;"+sExistingDataTypes
		endif
		sNewDataTypeInput = sDataTypeInput
		// make prompts
		prompt sDataTypeInput, sDecriptionToUse, Popup, sExistingDataTypes
		prompt sNewDataTypeInput, "Name if \"New Data\" above:"
		//prompt for DataType name
		if(vAddOption==1)
			DoPrompt/HELP="This tells COMBIgor what to call this "+sDecriptionToUse+"." sDecriptionToUse+" Input", sDataTypeInput, sNewDataTypeInput
		else
			DoPrompt/HELP="This tells COMBIgor what to call this "+sDecriptionToUse+"." sDecriptionToUse+" Input", sDataTypeInput
		endif
		if (V_Flag)
			return "CANCEL"
		endif
		//if new
		if(stringmatch(sDataTypeInput,"New Data"))
			sDataTypeInput = cleanupname(sNewDataTypeInput,0)
		endif
		//if Skip
		if(stringmatch(sDataTypeInput,"Skip Data"))
			sDataTypeInput = "Skip"
		endif
		//add to DataType list
		if(iDataType==0)
			sDataTypesList = sDataTypeInput
		else
			sDataTypesList = sDataTypesList+";"+sDataTypeInput
		endif
	
	endfor
	
	//return DataType names 
	return sDataTypesList
	
end

//function to sort a folder of waves, all on index 0 and up!
function COMBI_SortNewVectors(sProject,sFolderPath,sWavePrefix,sWaveSuffix,vIndexDigits,sLibraries,sDataTypes,sFirstSample,sLastSample,sFirstWave,sLastWave,bKillWaves,[sScaleDataType])
	string sProject //COMBIgor Project
	string sFolderPath //Path to foler where index waves exist
	string sWavePrefix //wave name prefix
	string sWaveSuffix //wave name suffix
	variable vIndexDigits //number of digits in the index string
	string sLibraries//Libraries to load to (List for multiples)
	string sDataTypes//data types to load to (matching number of columns of incoming waves)
	string sFirstSample//list of first Samples on Libraries
	string sLastSample//list of last Samples on Libraries
	string sFirstWave//first file index for vFirstSample
	string sLastWave//last file index for vLastPont
	int bKillWaves//1 to kill waves, 0 to keep waves
	string sScaleDataType // scale data type for vector waves
	
	//variables 
	int iLibrary, iFWave, iLWave, iWave, iFSample, iLSample, iSample, iDataType
	string sThisLibrary
	
	//get list of waves in folder
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder $sFolderPath
	string sWaveList = Wavelist("*",";","")
	SetDataFolder $sTheCurrentUserFolder 
	
	//how many?
	int vLibraries = itemsinList(sLibraries)
	int vDataTypes = itemsInList(sDataTypes)
	if(vLibraries!=itemsinList(sFirstSample)||vLibraries!=itemsinList(sLastSample)||vLibraries!=itemsinList(sFirstWave)||vLibraries!=itemsinList(sLastWave))
		DoAlert/T="COMBIgor error" 0,"Inputs have unequal lengths."
		return -1
	endif
	
	//enough waves
	variable vTotalWaves = itemsInList(sWaveList)
	
	for(iLibrary=0;iLibrary<vLibraries;iLibrary+=1)
		iWave = str2num(stringfromlist(iLibrary,sLastWave))
		if(iWave>=vTotalWaves)
			DoAlert/T="COMBIgor error" 0,"Not enough waves in the folder to make that happen."
		endif
	endfor

	//for each Library
	for(iLibrary=0;iLibrary<vLibraries;iLibrary+=1)
		sThisLibrary = stringFromList(iLibrary,sLibraries)
		iFWave = str2num(stringFromList(iLibrary,sFirstWave))
		iLWave = str2num(stringFromList(iLibrary,sLastWave))
		iFSample = str2num(stringFromList(iLibrary,sFirstSample))
		iLSample = str2num(stringFromList(iLibrary,sLastSample))
		
		//for Library Samples within Sample range
		for(iSample=iFSample;iSample<=iLSample;iSample+=1)
			iWave = iFWave+(iSample-iFSample)
			//get wave
			wave wWaveIn = $sFolderPath+sWavePrefix+COMBI_PadIndex(iWave+1,vIndexDigits)+sWaveSuffix
			//
			if(!stringmatch(sThisLibrary,"SKIP"))
				
				if(dimsize(wWaveIn,1)==0)
					redimension/N=(-1,1) wWaveIn
				endif
				if(dimsize(wWaveIn,1)!=itemsInList(sDataTypes))
					DoAlert/T="COMBIgor error" 0,"The number of columns in these vectors doesn't the match number of defined data types! This process will continue without loading "+sFolderPath+sWavePrefix+COMBI_PadIndex(iWave+1,vIndexDigits)+sWaveSuffix
				endif
				//get single Sample giving wave for vector data
				Make/N=(1,dimsize(wWaveIn,1),dimsize(wWaveIn,0))/O wGivingWave
				wave wGiver = root:wGivingWave
				//transfer data
				wGiver[0][][] = wWaveIn[r][q]
				//give wave
				if(!paramIsDefault(sScaleDataType))
					COMBI_GiveData(wGiver,sProject,sThisLibrary,sDataTypes,iSample,2,sScaleDataType=sScaleDataType)
				else
					COMBI_GiveData(wGiver,sProject,sThisLibrary,sDataTypes,iSample,2)
				endif
				
			endif
			//kill wave
			if(bKillWaves==1)
				killwaves wWaveIn
			endif
			
		endfor	
	endfor
	killwaves wGiver
end

//function to sort a wave of scalar data, all on index 0 and up!
function COMBI_SortNewScalarData(sProject,wWaveIn,sLibraries,sFirstSample,sLastSample,sFirstRow,sLastRow,sDataTypes,sDataColumnNumbers)
	string sProject //COMBIgor Project
	wave wWaveIn //wave to sort from
	string sLibraries//Libraries to load to (List for multiples)
	string sFirstSample//list of first Samples on Libraries
	string sLastSample//list of last Samples on Libraries
	string sFirstRow//first file index for vFirstSample
	string sLastRow//last file index for vLastPont
	string sDataTypes//data types to load to (matching number of columns of incoming Rows)
	string sDataColumnNumbers//i'th column for each of the data types. 
	
	//variable
	int iLibrary, iFRow, iLRow, iRow, iFSample, iLSample, iSample, iDataType, iCol
	string sThisLibrary, sThisDataType
	
	//how many?
	int vLibraries = itemsinList(sLibraries)
	int vDataTypes = itemsInList(sDataTypes)
	if(itemsinList(sLibraries)!=itemsinList(sFirstSample)||itemsinList(sLibraries)!=itemsinList(sLastSample)||itemsinList(sLibraries)!=itemsinList(sFirstRow)||itemsinList(sLibraries)!=itemsinList(sLastRow))
		DoAlert/T="COMBIgor error" 0,"Inputs of unequal lengths"
		return -1
	endif
	if(itemsinList(sDataTypes)!=itemsinList(sDataColumnNumbers))
		DoAlert/T="COMBIgor error" 0,"Inputs of unequal lengths"
		return -1
	endif
	
	//wave match?
	for(iLibrary=0;iLibrary<vLibraries;iLibrary+=1)
		for(iSample=iFSample;iSample<=iLSample;iSample+=1)
			iRow = iFRow+(iSample-iFSample)
			if(iRow>=dimsize(wWaveIn,0))
				DoAlert/T="COMBIgor error" 0,"Not enough rows in the wave to make that happen."
			endif
		endfor
	endfor
	
	
	//for each Library
	
	for(iLibrary=0;iLibrary<vLibraries;iLibrary+=1)
		sThisLibrary = stringFromList(iLibrary,sLibraries)
		if(StringMatch(sThisLibrary,"Skip"))
			Continue//not this Library
		endif
		iFRow = str2num(stringFromList(iLibrary,sFirstRow))
		iLRow = str2num(stringFromList(iLibrary,sLastRow))
		iFSample = str2num(stringFromList(iLibrary,sFirstSample))
		iLSample = str2num(stringFromList(iLibrary,sLastSample))
		
		//for Library Samples within range
		for(iSample=iFSample;iSample<=iLSample;iSample+=1)
			iRow = iFRow+(iSample-iFSample)
			for(iDataType=0;iDataType<vDataTypes;iDataType+=1)
				sThisDataType = stringFromList(iDataType,sDataTypes)
				if(stringmatch(sThisDataType,"Skip"))
					continue
				endif
				iCol = str2num(stringFromList(iDataType,sDataColumnNumbers))
				COMBI_GiveScalar(wWaveIn[iRow][iCol],sProject,sThisLibrary,sThisDataType,iSample)
			endfor
		endfor	
	endfor
	
end

function/S COMBI_StringPrompt(sStart,sDescription,sPopUpOptions,sHelp,sWindowTop)
	string sStart//starting value
	string sDescription//Decription Text
	string sPopUpOptions//list of popup options, no popup if ""
	string sHelp// help text
	string sWindowTop//text at top of window
	string sReturnString//"CANCEL" if user canceled
	
	if(itemsInList(sPopUpOptions)>0)
		prompt sStart, sDescription, popup,sPopUpOptions
	else
		prompt sStart, sDescription
	endif
	
	//prompt for string
	DoPrompt/HELP=sHelp sWindowTop sStart
	if (V_Flag)
		return "CANCEL"
	endif
	
	sReturnString = sStart
	return sReturnString
	
end

function COMBI_NumberPrompt(vStart,sDescription,sHelp,sWindowTop)
	variable vStart//starting value
	string sDescription//Decription Text
	string sHelp// help text
	string sWindowTop//text at top of window
	variable vReturnVariable=nan //nan if user canceled 
	
	prompt vStart, sDescription

	//prompt for string
	DoPrompt/HELP=sHelp sWindowTop vStart
	if (V_Flag)
		return  nan
	endif
	return vStart
	
end

//outputs a string as such: "sLibraryName;iFirstSample;iLastSample;iFirstInex;iLastIndex"
function/S COMBI_LibraryLoadingPrompt(sProject,sStartLibrary,sLibraryDescription,vAddOption,vSkipOption,iDimension,iLibrary)
	string sProject //COMBIgor project to operate within
	string sStartLibrary // starting Library value in prompt
	string sLibraryDescription //optional descritive text to user prompt, List for multiple that matches length of sStartLibraries 
	variable vAddOption // 1 to enable Library adding, 0 for existing only
	variable vSkipOption // 1 to enalbe Library skipping, 0 to disable 
	variable iDimension // 0 for Library, 1 for scalar, and 2 for vector, -1 for all
	variable iLibrary // Library number (indexed to zero) in this Library list
	
	//variables to use
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	string sLibrariesList = ""//to return
	string sExistingLibraries //options for prompt
	string sLibraryInput //choosen Library
	string sNewLibraryInput = "Input New Library Name Here!" //typed in if new
	string sNewString = ""
	string sSkipString = ""
	string sDecriptionToUse = ""
	variable vFirstSample = 1
	variable vLastSample = vTotalSamples
	variable vFirstIndex = 1+vTotalSamples*iLibrary
	variable vLastIndex = vTotalSamples*(iLibrary+1)
	
	//get existing Libraries in COMBIgor
	sExistingLibraries = COMBI_TableList(sProject,iDimension,"All","Libraries")

	//start value
	if(stringmatch(sStartLibrary,"New"))
		sLibraryInput = "New Library"
	elseif(stringmatch(sStartLibrary,"Skip"))
		sLibraryInput = "Skip Library"
	else 
		sLibraryInput = sStartLibrary
	endif
	sNewLibraryInput = sLibraryInput
	//build drop down values
	if(vSkipOption==1||stringmatch(sStartLibrary,"Skip"))
		sExistingLibraries = "Skip Library;"+sExistingLibraries
	endif
	if(vAddOption==1||stringmatch(sStartLibrary,"New"))
		sExistingLibraries = "New Library;"+sExistingLibraries
	endif
	if(!stringmatch(sStartLibrary,"New")&&!stringmatch(sStartLibrary,"Skip"))
		sExistingLibraries = sLibraryInput+";"+sExistingLibraries
	endif
	// make prompts
	prompt sLibraryInput, sLibraryDescription, Popup, sExistingLibraries
	prompt sNewLibraryInput, "Name if \"New Library\" selected:"
	prompt vFirstSample, "First Library Sample:"
	prompt vLastSample, "Last Library Sample:"
	prompt vFirstIndex, "First File Index:"
	prompt vLastIndex, "Last File Index:"
		
	//prompt for Library name
	DoPrompt/HELP="This indicates what to call this library." "Library Input", sLibraryInput, sNewLibraryInput,vFirstSample,vLastSample,vFirstIndex,vLastIndex
	if (V_Flag)
		return "CANCEL"
	endif
	
	//check for errors in Sample numbers
	if(vFirstSample<1)
		DoAlert/T="COMBIgor error" 0,"The first library sample must be at least 1."
		return "CANCEL"
	endif
	if(vLastSample>vTotalSamples)
		DoAlert/T="COMBIgor error" 0,"The last library sample must be at at most "+num2str(vTotalSamples)+"."
		return "CANCEL"
	endif
	if((vLastSample-vFirstSample)!=(vLastIndex-vFirstIndex))
		DoAlert/T="COMBIgor error" 0,"The number of library samples ("+num2str(vLastSample-vFirstSample)+") must match the number of file index("+num2str(vLastIndex-vFirstIndex)+") "+num2str(vTotalSamples)+"."
		return "CANCEL"
	endif

	//if new
	if(stringmatch(sLibraryInput,"New Library"))
		sLibraryInput = cleanupname(sNewLibraryInput,0)
	endif
	//if Skip
	if(stringmatch(sLibraryInput,"Skip Library"))
		sLibraryInput = "Skip"
	endif
	//if given as input
	if(!stringmatch(sLibraryInput,"Skip Library"))
		if(!stringmatch(sLibraryInput,"New Library"))
			sLibraryInput = cleanupname(sLibraryInput,0)
		endif
	endif
		
	//add to table
	if(!stringmatch("Skip",sLibraryInput))
		COMBI_AddLibrary(sProject,sLibraryInput,iDimension)
	endif	
	
	//return Library names 
	return sLibraryInput+";"+num2str(vFirstSample-1)+";"+num2str(vLastSample-1)+";"+num2str(vFirstIndex-1)+";"+num2str(vLastIndex-1)
	
end

function/S COMBI_PadIndex(vScanNumber,vDigits)
	variable vScanNumber, vDigits
	if(vDigits<0||vDigits>5)
		DoAlert/T="COMBIgor error" 0,"COMBIgor can only pad indexes to 1 to 5 digits in length"
		return num2str(vScanNumber)
	endif
	if(vDigits==5)
		if(vScanNumber>0&&vScanNumber<10)
			return "0000"+num2str(vScanNumber)
		elseif(vScanNumber>9&&vScanNumber<100)
			return "000"+num2str(vScanNumber)
		elseif(vScanNumber>99&&vScanNumber<1000)
			return "00"+num2str(vScanNumber)
		elseif(vScanNumber>999&&vScanNumber<10000)
			return "0"+num2str(vScanNumber)
		elseif(vScanNumber>9999&&vScanNumber<100000)
			return num2str(vScanNumber)
		endif
	elseif(vDigits==4)
		if(vScanNumber>0&&vScanNumber<10)
			return "000"+num2str(vScanNumber)
		elseif(vScanNumber>9&&vScanNumber<100)
			return "00"+num2str(vScanNumber)
		elseif(vScanNumber>99&&vScanNumber<1000)
			return "0"+num2str(vScanNumber)
		elseif(vScanNumber>999&&vScanNumber<10000)
			return num2str(vScanNumber)
		endif
	elseif(vDigits==3)
		if(vScanNumber>0&&vScanNumber<10)
			return "00"+num2str(vScanNumber)
		elseif(vScanNumber>9&&vScanNumber<100)
			return "0"+num2str(vScanNumber)
		elseif(vScanNumber>99&&vScanNumber<1000)
			return num2str(vScanNumber)
		endif	
	elseif(vDigits==2)
		if(vScanNumber>0&&vScanNumber<10)
			return "0"+num2str(vScanNumber)
		elseif(vScanNumber>9&&vScanNumber<100)
			return num2str(vScanNumber)
		endif	
	elseif(vDigits==1)
		return num2str(vScanNumber)	
	elseif(vDigits==0)
		return num2str(vScanNumber)	
	endif
end

function/S COMBI_UserOptionSelect(sOptions,sStartOptions, [sTitle,sDescription])
	string sOptions
	string sStartOptions
	string sTitle
	string sDescription
	
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	
	//clear any blank options
	sOptions = RemoveFromList("; ",sOptions)
	int iOption
	int vTotalOptions = itemsinlist(sOptions)
	
	
	if(ParamIsDefault(sTitle))
		sTitle = "Options"
	endif
	
	Make/O/N=(vTotalOptions) SelectedOptions
	wave wOptionWave = root:SelectedOptions
	if(itemsInList(sStartOptions)==vTotalOptions)
		for(iOption=0;iOption<vTotalOptions;iOption+=1)
			wOptionWave[iOption] = str2num(stringfromlist(iOption,sStartOptions))
		endfor
	else
		wOptionWave[] = 0
	endif
	
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	string sIgorEnviromentInfo = IgorInfo(0)
	string sScreenInfo = StringByKey("SCREEN1", sIgorEnviromentInfo)
	int vScreenTop = str2num(stringfromlist(4,sScreenInfo,","))
	int vScreenBottom = str2num(stringfromlist(4,sScreenInfo,","))
	int vScreenRight = str2num(stringfromlist(3,sScreenInfo,","))
	int vScreenLeft = str2num(stringfromlist(3,sScreenInfo,","))
	
	int vMaxRows = Floor(max(vScreenBottom,vScreenTop)/80)
	int vTotalColumns = Ceil(vTotalOptions/vMaxRows)
	int vTotalRows
	if(vTotalColumns==1)
		vTotalRows = vTotalOptions
	else
		vTotalRows = vMaxRows
	endif

	int vTotalHeight2Add = 70+20*vTotalRows
	int vTotalWidth2Add = vTotalColumns*200
	
	if(!ParamIsDefault(sDescription))
	 	vTotalHeight2Add+=20
	endif
	
	int vWinLeft = vScreenLeft/2-vTotalWidth2Add/2
	int vWinTop = vScreenTop/2-vTotalHeight2Add/2
	int vWinRight = vScreenRight/2+vTotalWidth2Add/2
	int vWinBottom = vScreenBottom/2+vTotalHeight2Add/2
	
	int vYValue = 10
	NewPanel/K=2/W=(vWinLeft,vWinTop,vWinRight,vWinBottom)/N=COMBIOptionSelect as sTitle
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 1,textyjust = 1, fsize = 12, save
	if(!ParamIsDefault(sDescription))
	 	DrawText 100,vYValue+5, sDescription
	 	vYValue+=20
	endif
	int iColumn,iRow
	for(iColumn=0;iColumn<vTotalColumns;iColumn+=1)
		for(iRow=0;iRow<vTotalRows;iRow+=1)
			iOption = iColumn*vTotalRows+iRow
			if(iOption<vTotalOptions)
				string sThisOption = stringfromlist(iOption,sOptions)
				string sName = replaceString(" ",sThisOption,"")
				setdimlabel 0,iOption,$sName,wOptionWave
				CheckBox $sName,pos={20+200*iColumn,vYValue+20*iRow},size={61,14},title=sThisOption,value=str2num(stringfromlist(iOption,sStartOptions)),proc=COMBI_UpdateOption
			endif
		endfor
	endfor
	vYValue=vYValue+20*vTotalRows
	
	button Everything ,title="EVERYTHING",appearance={native,All},pos={vTotalWidth2Add/2-90,vYValue},size={180,25},proc=COMBI_SelectOptionsDone,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue=vYValue+30
	button DoneSelecting ,title="DONE",appearance={native,All},pos={vTotalWidth2Add/2-90,vYValue},size={80,25},proc=COMBI_SelectOptionsDone,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button CancelSelecting ,title="CANCEL",appearance={native,All},pos={vTotalWidth2Add/2+10,vYValue},size={80,25},proc=COMBI_SelectOptionsDone,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14

	
	PauseForUser COMBIOptionSelect
	
	string sSelections2Return = ""
	NVAR bSelected = root:bSelection
	if(bSelected==1)//Done
		for(iOption=0;iOption<vTotalOptions;iOption+=1)
			if(wOptionWave[iOption]==1)
				sSelections2Return = AddlistItem(stringfromlist(iOption,sOptions),sSelections2Return,";",inf)
			endif
		endfor
	elseif(bSelected==-1)//Everything
		sSelections2Return = sOptions
	elseif(bSelected==0)//Canceled
		sSelections2Return = "CANCEL"
	endif
	
	
	Killwaves wOptionWave
	setdatafolder $sTheCurrentUserFolder
	return sSelections2Return
end

function COMBI_SelectOptionsDone(sControl): ButtonControl
	string sControl
	Killwindow/Z COMBIOptionSelect
	if(stringmatch(sControl,"DoneSelecting"))
		variable/G bSelection = 1
	elseif(stringmatch(sControl,"CancelSelecting"))
		variable/G bSelection = 0
	elseif(stringmatch(sControl,"Everything"))
		variable/G bSelection = -1
	endif
end

function COMBI_UpdateOption(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	wave wOptionWave = root:SelectedOptions
	wOptionWave[%$ctrlName] = checked
end

function COMBI_ExportCOMBIgorData()
	//select the data to output
	int bAllProjects = 0
	string sProjectOptions = "All Projects;"+COMBI_Projects()
	string sProject = COMBI_StringPrompt("All Projects","Project to export from:",sProjectOptions,"","Export Control")
	if(stringmatch(sProject,"CANCEL"))
		return -1
	elseif(stringmatch(sProject,"All Projects"))
		sProject = COMBI_Projects()
		bAllProjects = 1
	endif
	
	//projectLoop

	int iProject, iSample, iLibrary
	for(iProject=0;iProject<itemsinlist(sProject);iProject+=1)
		string sTheProject = stringFromList(iProject,sProject)
		//All data types
		string sAllMetaTypes = replaceString(";;",replaceString("; ;",Combi_TableList(sTheProject,-1,"All","DataTypes"),";"),";")
		string sAllLibraryTypes = replaceString(";;",replaceString("; ;",Combi_TableList(sTheProject,0,"All","DataTypes"),";"),";")
		string sAllScalarTypes = replaceString(";;",replaceString("; ;",Combi_TableList(sTheProject,1,"All","DataTypes"),";"),";")
		string sAllVectorTypes = replaceString(";;",replaceString("; ;",Combi_TableList(sTheProject,2,"All","DataTypes"),";"),";")
		string sFromMappingGrid = replaceString(";;",replaceString("; ;",Combi_TableList(sTheProject,-3,"All","Libraries"),";"),";")
		
		
		//libraries?
		string sSavePath = COMBI_ExportPath("Read")
		int iType
		if(stringmatch(sSavePath,"NO PATH"))
			sSavePath = COMBI_ExportPath("Temp")
		endif
		if(itemsInList(sFromMappingGrid)>0)
			sFromMappingGrid = COMBI_UserOptionSelect(sFromMappingGrid,"", sTitle="Libraries",sDescription="Select to Export")
			COMBI_ExportOtherData(sTheProject,"LibraryData",sSavePath)
		endif
		//data types
		if(itemsInList(sAllMetaTypes)>0)
			sAllMetaTypes = COMBI_UserOptionSelect(sAllMetaTypes,"", sTitle="Meta Data Types",sDescription="Meta to Export")
		endif
		if(itemsInList(sAllScalarTypes)>0)
			sAllScalarTypes = COMBI_UserOptionSelect(sAllScalarTypes,"", sTitle="Scalar Data Types",sDescription="Scalar to Export")
		endif
		if(itemsInList(sAllVectorTypes)>0)
			sAllVectorTypes = COMBI_UserOptionSelect(sAllVectorTypes,"", sTitle="Vector Data Types",sDescription="Vector to Export")
		endif
		//Library Loop
		int iTotalLibrary = itemsinlist(sFromMappingGrid)
		for(iLibrary=0;iLibrary<iTotalLibrary;iLibrary+=1)
			string sTheLibrary = stringfromList(iLibrary,sFromMappingGrid)
			int iTotalDataTypes = 1+itemsinList(sAllMetaTypes)+itemsinlist(sAllScalarTypes)+itemsinlist(sAllVectorTypes)
			int iTracker = 1
			COMBI_ProgressWindow(sTheLibrary+"Export","Exporting:"+sTheLibrary,"Export Progress",iTracker,iTotalDataTypes)
			
			//meta data export
			if(itemsinlist(sAllMetaTypes)>0)
				COMBI_ExportMetaData(sTheProject,sTheLibrary,sAllMetaTypes,sSavePath)
				iTracker+=itemsinList(sAllMetaTypes)
				COMBI_ProgressWindow(sTheLibrary+"Export","Exporting:"+sTheLibrary,"Export Progress",iTracker,iTotalDataTypes)
			endif
			//Scalar data export
			if(itemsinlist(sAllScalarTypes)>0)
				for(iType=0;iType<itemsInList(sAllScalarTypes);iType+=1)
					COMBI_ExportScalarData(sTheProject,sTheLibrary,stringfromlist(iType,sAllScalarTypes),sSavePath)
					iTracker+=1
					COMBI_ProgressWindow(sTheLibrary+"Export","Exporting:"+sTheLibrary,"Export Progress",iTracker,iTotalDataTypes)
				endfor
			endif
			//vector data export
			if(itemsinlist(sAllVectorTypes)>0)
				COMBI_ExportVectorData(sTheProject,sTheLibrary,sAllVectorTypes,sSavePath,1)
				iTracker+=itemsinlist(sAllVectorTypes)
				COMBI_ProgressWindow(sTheLibrary+"Export","Exporting:"+sTheLibrary,"Export Progress",iTracker,iTotalDataTypes)
			endif
			COMBI_ProgressWindow(sTheLibrary+"Export","Exporting:"+sTheLibrary,"Export Progress",iTotalDataTypes,iTotalDataTypes)
		endfor
	endfor
	
end

function COMBI_ExportMetaData(sProject,sLibrary,sDataTypes,sOption)
	string sProject//
	string sLibrary// library
	string sDataTypes// COMMA (,) seperated list of data types
	string sOption// "COMBIgor" for prefernece, string of path if known, or "" to choose one.
	COMBI_AddSampleID2Library(sProject,"")
	sDataTypes = replacestring(",",sDataTypes,";")
	
	//get save path
	if(stringmatch(sOption,"COMBIgor"))//preference
		string sExportOption = Combi_GetGlobalString("sExportOption","COMBIgor")
		if(stringmatch(sExportOption,"None"))//choose
			NewPath/O/Q/M="Where to save?" pExportPath
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		else //use stored
			sExportOption = Combi_GetGlobalString("sExportPath", "COMBIgor")
			NewPath/O/Q pExportPath, sExportOption
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		endif
	elseif(strlen(sOption)==0)//choose path
		NewPath/O/Q/M="Where to save?" pExportPath
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	else
		NewPath/O/Q pExportPath, sOption
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	endif
	NewPath/O/Q/C pExportPath, sExportOption+sProject//make folder for project
	NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary//make folder for library
	
	//meta wave
	wave/T wMetaData = $COMBI_DataPath(sProject,-1)
	
	//out going wave
	int vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	killwaves/Z root:OutgoingCOMBIData
	Make/O/T/N=(vTotalSamples,(1+itemsinList(sDataTypes))) OutgoingCOMBIData
	wave/T wDataOut = root:OutgoingCOMBIData
	int iSample
	SetDimLabel 1,0,SampleID,wDataOut
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		wDataOut[iSample][0] = wMetaData[%$sLibrary][iSample][%SampleID]
	endfor
	int iDataType
	for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)
		string sTheDataType = stringfromlist(iDataType-1,sDataTypes)
		SetDimLabel 1,iDataType,$sTheDataType,wDataOut
	endfor
	
	//move data
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)
			sTheDataType = stringfromlist(iDataType-1,sDataTypes)
			if(FindDimLabel(wMetaData,2,sTheDataType)!=-2)
				if(FindDimLabel(wMetaData,0,sLibrary)!=-2)
					wDataOut[iSample][iDataType] = replacestring(",",wMetaData[%$sLibrary][iSample][%$sTheDataType],"")
				endif
			endif
		endfor
	endfor
	
	//save
	//filename
	string sFilename = sLibrary+" - "+replacestring(";",sDataTypes," ")+".txt"
	Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
	
	killvariables/Z root:V_flag, root:S_path
	killpath pExportPath
	killwaves/Z root:OutgoingCOMBIData
	
end


function COMBI_ExportScalarData(sProject,sLibrary,sDataTypes,sOption)
	string sProject//
	string sLibrary// library
	string sDataTypes// COMMA (,) seperated list of data types
	string sOption// "COMBIgor" for prefernece, string of path if known, or "" to choose one.
	COMBI_AddSampleID2Library(sProject,"")
	sDataTypes = replacestring(",",sDataTypes,";")
	
	//get save path
	if(stringmatch(sOption,"COMBIgor"))//preference
		string sExportOption = Combi_GetGlobalString("sExportOption","COMBIgor")
		if(stringmatch(sExportOption,"None"))//choose
			NewPath/O/Q/M="Where to save?" pExportPath
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		else //use stored
			sExportOption = Combi_GetGlobalString("sExportPath", "COMBIgor")
			NewPath/O/Q pExportPath, sExportOption
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		endif
	elseif(strlen(sOption)==0)//choose path
		NewPath/O/Q/M="Where to save?" pExportPath
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	else
		NewPath/O/Q pExportPath, sOption
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	endif
	NewPath/O/Q/C pExportPath, sExportOption+sProject//make folder for project
	NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary//make folder for library
	
	//out going wave
	wave/T wMeta = $COMBI_DataPath(sProject,-1)
	int vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	killwaves/Z root:OutgoingCOMBIData
	Make/O/T/N=(vTotalSamples,(1+itemsinList(sDataTypes))) OutgoingCOMBIData
	wave/T wDataOut = root:OutgoingCOMBIData
	int iSample
	SetDimLabel 1,0,SampleID,wDataOut
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		wDataOut[iSample][0] = wMeta[%$sLibrary][iSample][%SampleID]
	endfor
	int iDataType
	for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)
		string sTheDataType = stringfromlist(iDataType-1,sDataTypes)
		SetDimLabel 1,iDataType,$sTheDataType,wDataOut
	endfor
	
	//move data
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)
			sTheDataType = stringfromlist(iDataType-1,sDataTypes)
			wave/Z wScalarData = $COMBI_DataPath(sProject,1)+sLibrary+":"+sTheDataType
			if(waveexists(wScalarData))
				wDataOut[iSample][iDataType] = num2str(wScalarData[iSample])
			endif
		endfor
	endfor
	
	//save
	//filename
	string sFilenameRoot = replacestring(";",sDataTypes," ")
	if(strlen(sFilenameRoot)>100)
		sFilenameRoot = "Scalar Data"
	endif
	string sFilename = sLibrary+" - "+sFilenameRoot+".txt"
	Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
	
	killvariables/Z root:V_flag, root:S_path
	killpath pExportPath
	killwaves/Z root:OutgoingCOMBIData
	
end

function COMBI_ExportOtherData(sProject,sDataOption,sOption)
	string sProject// project
	string sDataOption// "Globals" or "LibraryData"
	string sOption// "COMBIgor" for prefernece, string of path if known, or "" to choose one.
	COMBI_AddSampleID2Library(sProject,"")
		
	//get save path
	if(stringmatch(sOption,"COMBIgor"))//preference
		string sExportOption = Combi_GetGlobalString("sExportOption","COMBIgor")
		if(stringmatch(sExportOption,"None"))//choose
			NewPath/O/Q/M="Where to save?" pExportPath
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		else //use stored
			sExportOption = Combi_GetGlobalString("sExportPath", "COMBIgor")
			NewPath/O/Q pExportPath, sExportOption
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		endif
	elseif(strlen(sOption)==0)//choose path
		NewPath/O/Q/M="Where to save?" pExportPath
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	else
		NewPath/O/Q pExportPath, sOption
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	endif
	NewPath/O/Q/C pExportPath, sExportOption+sProject//make folder for project
	
	string sRowLabel
	int iRow, iColumn
	if(stringmatch(sDataOption,"Globals"))
		wave/Z/T wTextDataLeaving = root:Packages:COMBIgor:COMBI_Globals
		killwaves/Z root:OutgoingCOMBIData
		Make/O/T/N=(dimsize(wTextDataLeaving,0),(1+dimsize(wTextDataLeaving,1))) OutgoingCOMBIData	
		wave/T wDataOut = root:OutgoingCOMBIData
		SetDimLabel 1,0,Global,wDataOut
		for(iRow=0;iRow<dimsize(wDataOut,0);iRow+=1)
			wDataOut[iRow][0] = getdimlabel(wTextDataLeaving,0,iRow)
			for(iColumn=0;iColumn<dimsize(wTextDataLeaving,1);iColumn+=1)
				SetDimLabel 1,(1+iColumn),$getdimlabel(wTextDataLeaving,1,iColumn),wDataOut
	 			wDataOut[iRow][1+iColumn] = wTextDataLeaving[iRow][iColumn]
			endfor
		endfor
		
	elseif(stringmatch(sDataOption,"LibraryData"))
		wave/Z wDataLeaving = $COMBI_DataPath(sProject,0)
		killwaves/Z root:OutgoingCOMBIData
		Make/O/T/N=(dimsize(wDataLeaving,0)-1,(1+dimsize(wDataLeaving,1))) OutgoingCOMBIData	
		wave/T wDataOut = root:OutgoingCOMBIData
		SetDimLabel 1,0,LibraryData,wDataOut
		for(iRow=1;iRow<dimsize(wDataOut,0)+1;iRow+=1)
			 wDataOut[iRow-1][0] = getdimlabel(wDataLeaving,0,iRow)
			 for(iColumn=0;iColumn<dimsize(wDataLeaving,1);iColumn+=1)
			 	SetDimLabel 1,(iColumn+1),$getdimlabel(wDataLeaving,1,iColumn+1),wDataOut
			 	if(!stringmatch("NaN",num2str(wDataLeaving[iRow][iColumn])))
			 		wDataOut[iRow-1][iColumn] = num2str(wDataLeaving[iRow][iColumn])
			 	endif
			endfor
		endfor
	endif
	
	
	//save
	//filename
	string sFilename = sProject+" - "+sDataOption+".txt"
	Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
	
	killvariables/Z root:V_flag, root:S_path
	killpath pExportPath
	killwaves/Z root:OutgoingCOMBIData
	
end

function COMBI_ExportVectorData(sProject,sLibrary,sDataTypes,sOption,iFormatOption)
	string sProject// project
	string sDataTypes// Data Types
	string sLibrary// library
	string sOption// "COMBIgor" for prefernece, string of path if known, or "" to choose one.
	int iFormatOption// 1 - single data type per file with a file per sample,
	//2 - multiple datatypes per file with a file per sample
	//-1 single data type in one file
	//-2 multiple data types in one file
	COMBI_AddSampleID2Library(sProject,"")
		
	//get save path
	if(stringmatch(sOption,"COMBIgor"))//preference
		string sExportOption = Combi_GetGlobalString("sExportOption","COMBIgor")
		if(stringmatch(sExportOption,"None"))//choose
			NewPath/O/Q/M="Where to save?" pExportPath
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		else //use stored
			sExportOption = Combi_GetGlobalString("sExportPath", "COMBIgor")
			NewPath/O/Q pExportPath, sExportOption
			PathInfo pExportPath
			if(V_flag<=0)//cancelled or failed
				return -1
			endif
			sExportOption = S_path
		endif
	elseif(strlen(sOption)==0)//choose path
		NewPath/O/Q/M="Where to save?" pExportPath
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	else
		NewPath/O/Q pExportPath, sOption
		PathInfo pExportPath
		if(V_flag<=0)//cancelled or failed
			return -1
		endif
		sExportOption = S_path
	endif
	NewPath/O/Q/C pExportPath, sExportOption+sProject//make folder for project
	NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary//make folder for library
	
	//loops controls and struff
	sDataTypes = replacestring(",",sDataTypes,";")
	int iDataType, iSample ,vVectorLength, iColumn
	string sTheDataType,sFilename
	int vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	wave/T wMeta = $COMBI_DataPath(sProject,-1)
	if(iFormatOption>0)//sinlge file for each sample
	
		//sinlge file for each sample//single data type per file
		if(abs(iFormatOption)==1)
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)
					sTheDataType = stringfromlist(iDataType-1,sDataTypes)
					NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary+":"+sTheDataType//make folder for data type
					//loop all sample + datatypes
					wave/Z wVectorDataLeaving = $Combi_DataPath(sProject,2)+sLibrary+":"+sTheDataType
					if(waveexists(wVectorDataLeaving))//data type exist
						killwaves/Z root:OutgoingCOMBIData//kill wave
						Make/O/T/N=((dimsize(wVectorDataLeaving,1)+1),2) OutgoingCOMBIData//make wave
						wave/T wDataOut = root:OutgoingCOMBIData
						SetDimLabel 1,0,SampleID,wDataOut
						SetDimLabel 1,1,$wMeta[%$sLibrary][iSample][%SampleID],wDataOut
						wDataOut[][0] = num2str(x) //index
						wDataOut[0][0] = "VectorScale"
						wDataOut[1,dimsize(wVectorDataLeaving,1)][1] = num2str(wVectorDataLeaving[iSample][p-1])
						wDataOut[0][1] = sTheDataType
						sFilename = wMeta[%$sLibrary][iSample][%SampleID]+" - "+sTheDataType+".txt"
						Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
					endif	
				endfor
			endfor
			
		//sinlge file for each sample//multiple data types per file
		elseif(abs(iFormatOption)==2)
			//determine length
			vVectorLength = 0
			for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)//loop all datatypes
				wave/Z wVectorDataLeaving = $Combi_DataPath(sProject,2)+sLibrary+":"+stringfromlist(iDataType-1,sDataTypes)
				if(waveexists(wVectorDataLeaving))//data type exist
					if(dimsize(wVectorDataLeaving,1)>vVectorLength)//longer?
						vVectorLength = dimsize(wVectorDataLeaving,1)
					endif
				endif
			endfor
			NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary+":"+Replacestring(";",sDataTypes," ")//make folder for data type
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				killwaves/Z root:OutgoingCOMBIData//kill wave
				Make/O/T/N=((vVectorLength+1),1+itemsinlist(sDataTypes)) OutgoingCOMBIData//make wave
				wave/T wDataOut = root:OutgoingCOMBIData
				SetDimLabel 1,0,SampleID,wDataOut
				wDataOut[][0] = num2str(p) //index
				wDataOut[0][0] = "VectorIndex"
				for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)//loop all datatypes
					SetDimLabel 1,1+iDataType,$wMeta[%$sLibrary][iSample][%SampleID],wDataOut//sample ID
					sTheDataType = stringfromlist(iDataType,sDataTypes)
					wDataOut[0][1+iDataType] = sTheDataType//data type 					
					wave/Z wVectorDataLeaving = $Combi_DataPath(sProject,2)+sLibrary+":"+sTheDataType
					if(waveexists(wVectorDataLeaving))//data type exist
						wDataOut[1,dimsize(wVectorDataLeaving,1)][1+iDataType] = num2str(wVectorDataLeaving[iSample][p-1])
						wDataOut[0][1+iDataType] = sTheDataType
						sFilename = wMeta[%$sLibrary][iSample][%SampleID]+" - "+Replacestring(";",sDataTypes," ")+".txt"
						Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
					endif	
				endfor
			endfor
		endif
		
	elseif(iFormatOption<0)//one file for all samples
	
		//one file for all samples//single data type per file
		if(abs(iFormatOption)==1)
			NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary//make folder for library
			for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)//loop all datatypes
				sTheDataType = stringfromlist(iDataType,sDataTypes)
				wave/Z wVectorDataLeaving = $Combi_DataPath(sProject,2)+sLibrary+":"+sTheDataType
				if(waveexists(wVectorDataLeaving))//data type exist
					killwaves/Z root:OutgoingCOMBIData//kill wave
					Make/O/T/N=((dimsize(wVectorDataLeaving,1)+1),1+vTotalSamples) OutgoingCOMBIData//make wave
					wave/T wDataOut = root:OutgoingCOMBIData
					SetDimLabel 1,0,SampleID,wDataOut
					wDataOut[][0] = num2str(x) //index
					wDataOut[0][0] = "VectorScale"
					for(iSample=0;iSample<vTotalSamples;iSample+=1)//loop all samples
						iColumn = 1+iSample
						SetDimLabel 1,iColumn,$wMeta[%$sLibrary][iSample][%SampleID],wDataOut//sample ID
						wDataOut[1,dimsize(wVectorDataLeaving,1)][iColumn] = num2str(wVectorDataLeaving[iSample][p-1])
						wDataOut[0][iColumn] = sTheDataType
					endfor
					sFilename = sLibrary+" - "+sTheDataType+".txt"
					Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
				endif		
			endfor
			
		//one file for all samples//multiple data types per file
		elseif(abs(iFormatOption)==2)
			//determine length
			vVectorLength = 0
			for(iDataType=1;iDataType<=itemsinlist(sDataTypes);iDataType+=1)//loop all datatypes
				wave/Z wVectorDataLeaving = $Combi_DataPath(sProject,2)+sLibrary+":"+stringfromlist(iDataType-1,sDataTypes)
				if(waveexists(wVectorDataLeaving))//data type exist
					if(dimsize(wVectorDataLeaving,1)>vVectorLength)//longer?
						vVectorLength = dimsize(wVectorDataLeaving,1)
					endif
				endif
			endfor
			NewPath/O/Q/C pExportPath, sExportOption+sProject+":"+sLibrary//make folder for library
			killwaves/Z root:OutgoingCOMBIData//kill wave
			Make/O/T/N=((vVectorLength+1),1+itemsinlist(sDataTypes)*vTotalSamples) OutgoingCOMBIData//make wave
			wave/T wDataOut = root:OutgoingCOMBIData
			SetDimLabel 1,0,SampleID,wDataOut
			wDataOut[][0] = num2str(p) //index
			wDataOut[0][0] = "VectorIndex"
			
			for(iSample=0;iSample<vTotalSamples;iSample+=1)//loop all samples
				for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)//loop all datatypes
					iColumn = 1+iDataType+iSample*itemsinlist(sDataTypes)
					SetDimLabel 1,iColumn,$wMeta[%$sLibrary][iSample][%SampleID],wDataOut//sample ID
					sTheDataType = stringfromlist(iDataType,sDataTypes)
					wDataOut[0][iColumn] = sTheDataType//data type 					
					wave/Z wVectorDataLeaving = $Combi_DataPath(sProject,2)+sLibrary+":"+sTheDataType
					if(waveexists(wVectorDataLeaving))//data type exist
						wDataOut[1,dimsize(wVectorDataLeaving,1)][iColumn] = num2str(wVectorDataLeaving[iSample][p-1])
						wDataOut[0][iColumn] = sTheDataType
					endif	
				endfor
			endfor
			
			sFilename = sLibrary+" - "+Replacestring(";",sDataTypes," ")+".txt"
			Save/G/M="\n"/DSYM=""/O/U={0,0,1,0}/P=pExportPath wDataOut as sFilename
			
		endif
	endif
	
	killpath pExportPath
	killwaves/Z root:OutgoingCOMBIData
	
end

function COMBI_MakeExamplePreferredOUT(sProject)
	string sProject
	string sSavePath = COMBI_ExportPath("Read")
	if(stringmatch(sSavePath,"NO PATH"))
		sSavePath = COMBI_ExportPath("Temp")
	endif
	//Meta
	COMBI_AddSampleID2Library(sProject,"")
	COMBI_ExportMetaData(sProject,"FromMappingGrid","MappingGridPosition,Sample",sSavePath)
	COMBI_ExportMetaData(sProject,"FromMappingGrid","MappingGridPosition",sSavePath)
	//Library
	COMBI_ExportOtherData(sProject,"LibraryData",sSavePath)
	//Scalar 
	COMBI_ExportScalarData(sProject,"FromMappingGrid",replacestring(";",RemoveFromList("Sample",COMBI_LibraryQualifiers(sProject,-1)),","),sSavePath)
	COMBI_ExportScalarData(sProject,"FromMappingGrid","x_mm",sSavePath)
	//Vector
	Combi_AddDataType(sProject,"FromMappingGrid","ExampleVector2",2,iVDim=100)
	Combi_AddDataType(sProject,"FromMappingGrid","ExampleVector1",2,iVDim=100)
	wave wExampleVector1 = $Combi_DataPath(sProject,2)+"FromMappingGrid:ExampleVector1"
	wave wExampleVector2 = $Combi_DataPath(sProject,2)+"FromMappingGrid:ExampleVector2"
	wExampleVector1[][] = p*15+q
	wExampleVector2[][] = P*q
	COMBI_ExportVectorData(sProject,"FromMappingGrid","ExampleVector1,ExampleVector2",sSavePath,-1)
	COMBI_ExportVectorData(sProject,"FromMappingGrid","ExampleVector1,ExampleVector2",sSavePath,-2)
	COMBI_ExportVectorData(sProject,"FromMappingGrid","ExampleVector1,ExampleVector2",sSavePath,1)
	COMBI_ExportVectorData(sProject,"FromMappingGrid","ExampleVector1,ExampleVector2",sSavePath,2)
	
end

function COMBI_LoadCOMBIgorData(sProject,sOption)
	string sProject
	string sOption //"Folder", "Project Folder" or "File"
	
	string sFile,sPath,sTheDataType,sTheSampleID,sTheLibrary,sTheSample
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	int vColumnsIn, vRowsIn, iRow, iColumn, iSample
	
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pLoadPath, sLoadPath
		Pathinfo/S pLoadPath //direct to user folder
	endif
	
	string sAllFiles,sAllFolders,sTheLibraryFolder,sTheProject,sTheFile
	string sTheVectorFolder,sAllLibraryFolders,sAllVectorFolders,sAllLibraryFiles,sAllVectorFiles
	int iFolder,iFile,iLibrary,iVector,iLibraryFile,iVectorFile
	
	if(stringmatch(sOption,"Folder"))
		NewPath/Z/Q/O pLoadPath
		Pathinfo pLoadPath
		Pathinfo pLoadPath
		sPath = S_path
		sAllFiles = IndexedFile(pLoadPath,-1,".txt")
		for(iFile=0;iFile<itemsinlist(sAllFiles);iFile+=1)
			sTheFile = stringfromList(iFile,sAllFiles)
			LoadWave/N=LoadedCOMBIGorFile/M/J/K=2/O/Q/P=pLoadPath sTheFile
			wave/T wLoadedWave = root:LoadedCOMBIGorFile0
			COMBI_LoadACOMBIDataFile(sProject,wLoadedWave,S_path)
			COMBI_ProgressWindow("COMBIgorFileImport","Loading Folder","Importing Progress",iFile+1,itemsinlist(sAllFiles))
		endfor
		
	elseif(stringmatch(sOption,"Project Folder"))
		NewPath/Z/Q/O pLoadPath
		Pathinfo pLoadPath
		sPath = S_path
		sTheProject = stringfromList(itemsinList(sPath,":")-1,sPath,":")
		sAllFiles = IndexedFile(pLoadPath,-1,".txt")
		sAllLibraryFolders = IndexedDir(pLoadPath, -1,0)
		//files in project folder
		for(iFile=0;iFile<itemsinlist(sAllFiles);iFile+=1)
			sTheFile = stringfromList(iFile,sAllFiles)
			LoadWave/N=LoadedCOMBIGorFile/M/J/K=2/O/Q/P=pLoadPath sTheFile
			wave/T wLoadedWave = root:LoadedCOMBIGorFile0
			COMBI_LoadACOMBIDataFile(sProject,wLoadedWave,S_path)
		endfor
		// folders in sub folder
		for(iLibrary=0;iLibrary<itemsinlist(sAllLibraryFolders);iLibrary+=1)
			sTheLibraryFolder = stringfromList(iLibrary,sAllLibraryFolders)
			NewPath/Z/Q/O pLoadPath sPath+sTheLibraryFolder+":"
			sAllVectorFolders = IndexedDir(pLoadPath,-1,0)
			sAllLibraryFiles = IndexedFile(pLoadPath,-1,".txt")
			int iTotal4Library = itemsinlist(sAllLibraryFiles)+itemsinlist(sAllVectorFolders)
			int iTrackProgress = 1
			COMBI_ProgressWindow("COMBIgorFileImport","Loading:"+sTheLibraryFolder,"Importing Progress",iTrackProgress,iTotal4Library)
			//files in sub folers
			for(iLibraryFile=0;iLibraryFile<itemsinlist(sAllLibraryFiles);iLibraryFile+=1)
				sTheFile = stringfromList(iLibraryFile,sAllLibraryFiles)
				LoadWave/N=LoadedCOMBIGorFile/M/J/K=2/O/Q/P=pLoadPath sTheFile
				wave/T wLoadedWave = root:LoadedCOMBIGorFile0
				COMBI_LoadACOMBIDataFile(sProject,wLoadedWave,S_path)
				iTrackProgress+=1
				COMBI_ProgressWindow("COMBIgorFileImport","Loading:"+sTheLibraryFolder,"Importing Progress",iTrackProgress,iTotal4Library)
			endfor
			//sub folders in sub folder
			for(iVector=0;iVector<itemsinlist(sAllVectorFolders);iVector+=1)
				sTheVectorFolder = stringfromList(iVector,sAllVectorFolders)
				NewPath/Z/Q/O pLoadPath sPath+sTheLibraryFolder+":"+sTheVectorFolder+":"
				sAllVectorFiles = IndexedFile(pLoadPath,-1,".txt")
				//files in sub-sub folder
				for(iVectorFile=0;iVectorFile<itemsinlist(sAllVectorFiles);iVectorFile+=1)
					sTheFile = stringfromList(iVectorFile,sAllVectorFiles)
					LoadWave/N=LoadedCOMBIGorFile/M/J/K=2/O/Q/P=pLoadPath sTheFile
					wave/T wLoadedWave = root:LoadedCOMBIGorFile0
					COMBI_LoadACOMBIDataFile(sProject,wLoadedWave,S_path)
				endfor
				iTrackProgress+=1
				COMBI_ProgressWindow("COMBIgorFileImport","Loading:"+sTheLibraryFolder,"Importing Progress",iTrackProgress,iTotal4Library)
			endfor
		endfor
		
	elseif(stringmatch(sOption,"File"))
		LoadWave/N=LoadedCOMBIGorFile/M/J/K=2/O/Q
		wave/T wLoadedWave = root:LoadedCOMBIGorFile0
		COMBI_LoadACOMBIDataFile(sProject,wLoadedWave,S_path)
		
	endif
	Killwaves/Z wLoadedWave
	Killpath/A
	killvariables/Z root:S_fileName,root:S_path,root:S_path,root:V_Flag,root:bSelection
end


//add data logging?
function COMBI_LoadACOMBIDataFile(sProject,wLoadedAsTextWave,sStorePath)
	string sProject
	string sStorePath
	wave/T wLoadedAsTextWave
	int vColumnsIn = dimsize(wLoadedAsTextWave,1)
	int vRowsIn = dimsize(wLoadedAsTextWave,0)
	int iColumn,iRow,iSample
	string sTheSampleID,sTheDataType,sTheLibrary,sTheSample
	string sAllSamplesLoaded =""
	string sAllDataTypes =""
	String expr="([[:ascii:]]*)_S([[:digit:]]*)"
	//determine type
	if(stringmatch(wLoadedAsTextWave[0][0],"SampleID"))//COMBIgor, not Library
		if(stringmatch(wLoadedAsTextWave[1][0],"VectorScale"))//vector data (scaled)
			for(iColumn=1;iColumn<vColumnsIn;iColumn+=1)
				sTheSampleID = wLoadedAsTextWave[0][iColumn]
				sTheDataType = wLoadedAsTextWave[1][iColumn]
				sAllSamplesLoaded = sTheSampleID+";"
				sAllDataTypes = sTheDataType+";"
				SplitString/E=(expr) sTheSampleID,sTheLibrary,sTheSample
				iSample = str2num(sTheSample)-1
				Combi_AddDataType(sProject,sTheLibrary,sTheDataType,2,iVDim=(vRowsIn-2))
				wave wVectorWave = $Combi_DataPath(sProject,2)+sTheLibrary+":"+sTheDataType
				wVectorWave[iSample][] = str2num(wLoadedAsTextWave[2+q][iColumn])
				//scale wave
				SetScale/I y, str2num(wLoadedAsTextWave[2][0]), str2num(wLoadedAsTextWave[vRowsIn-1][0]),wVectorWave
			endfor
		elseif(stringmatch(wLoadedAsTextWave[1][0],"VectorIndex"))//vector data (not scaled)
			for(iColumn=1;iColumn<vColumnsIn;iColumn+=1)
				sTheSampleID = wLoadedAsTextWave[0][iColumn]
				sTheDataType = wLoadedAsTextWave[1][iColumn]
				sAllSamplesLoaded = sTheSampleID+";"
				sAllDataTypes = sTheDataType+";"
				SplitString/E=(expr) sTheSampleID,sTheLibrary,sTheSample
				iSample = str2num(sTheSample)-1
				Combi_AddDataType(sProject,sTheLibrary,sTheDataType,2,iVDim=(vRowsIn-2))
				wave wVectorWave = $Combi_DataPath(sProject,2)+sTheLibrary+":"+sTheDataType
				wVectorWave[iSample][] = str2num(wLoadedAsTextWave[2+q][iColumn])
			endfor
		else //meta or scalar
			for(iColumn=1;iColumn<vColumnsIn;iColumn+=1)
				for(iRow=1;iRow<vRowsIn;iRow+=1)
					sTheSampleID = wLoadedAsTextWave[iRow][0]
					sTheDataType = wLoadedAsTextWave[0][iColumn]
					sAllSamplesLoaded = sTheSampleID+";"
					sAllDataTypes = sTheDataType+";"
					SplitString/E=(expr) sTheSampleID,sTheLibrary,sTheSample
					iSample = str2num(sTheSample)-1
					variable vDataIn = str2num(wLoadedAsTextWave[iRow][iColumn])
					int iType = 0 //1 for meta, -1 for scalar, 0 for neither (skip)
					if(numtype(vDataIn)==0)//numric
						if(stringmatch(wLoadedAsTextWave[iRow][iColumn],"*/*")||stringmatch(wLoadedAsTextWave[iRow][iColumn],"*\*"))//date is meta
							iType = 1
						else //scalar
							iType = -1
						endif
					elseif(strlen(wLoadedAsTextWave[iRow][iColumn])>0)//meta
						iType = 1
					endif 
					if(iType==1)
						Combi_GiveMeta(sProject,sTheDataType,sTheLibrary,wLoadedAsTextWave[iRow][iColumn],iSample)
					elseif(iType==-1)
						Combi_GiveScalar(vDataIn,sProject,sTheLibrary,sTheDataType,iSample)
					endif
				endfor
			endfor
		endif
	elseif(stringmatch(wLoadedAsTextWave[0][0],"LibraryData"))//COMBIgor Library data
		//load library data
		for(iRow=1;iRow<vRowsIn;iRow+=1)
			for(iColumn=1;iColumn<vColumnsIn;iColumn+=1)
				Combi_GiveLibraryData(str2num(wLoadedAsTextWave[iRow][iColumn]),sProject,wLoadedAsTextWave[iRow][0],wLoadedAsTextWave[0][iColumn])
				sAllSamplesLoaded = wLoadedAsTextWave[iRow][0]+";"
				sAllDataTypes = wLoadedAsTextWave[0][iColumn]+";"
			endfor
		endfor
	endif
	sAllDataTypes = SortList(sAllDataTypes,";",32)
	sAllSamplesLoaded = SortList(sAllSamplesLoaded,";",32)
	string sLogText="Loaded COMBIgor Data from file:"+";"+sStorePath+";"
	COMBI_Add2Log(sProject,sAllSamplesLoaded,sAllDataTypes,1,sLogText)
end

function COMBI_ProgressWindow(sName,sDescription,sTitle,vPart,vTotal)
	string sName
	string sDescription
	string sTitle
	variable vPart
	variable vTotal
	 
	string sIgorEnviromentInfo = IgorInfo(0)
	string sScreenInfo = StringByKey("SCREEN1", sIgorEnviromentInfo)
	int vWinLeft = str2num(stringfromlist(3,sScreenInfo,","))/2-100
	int vWinTop = str2num(stringfromlist(4,sScreenInfo,","))/2-30
	int vWinRight = str2num(stringfromlist(3,sScreenInfo,","))/2+100
	int vWinBottom = str2num(stringfromlist(4,sScreenInfo,","))/2+30
	
	if(vPart==1)//create
		NewPanel/N=$sName/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as sTitle
		SetDrawLayer/W=$sName UserBack
		SetDrawEnv/W=$sName fsize= 14,textxjust= 1,textyjust= 1,save
		DrawText/W=$sName 100,20,sDescription
		ValDisplay COMBIProgressValue pos={10,30},size={180,40},frame=4,appearance={native}
		ValDisplay COMBIProgressValue limits={0,vTotal,0},barmisc={0,1},bodyWidth= 180
		Execute "ValDisplay COMBIProgressValue value=_NUM:"+num2str(1)
		DoUpdate/W=$sName
	elseif(vPart==vTotal)//kill
		Killwindow/Z $sName
	elseif(vPart<vTotal)//update
		Execute "ValDisplay COMBIProgressValue value=_NUM:"+num2str(vPart)+",win="+sName
		DoUpdate/Z/W=$sName
	else //kill
		Killwindow/Z $sName
	endif
	
end