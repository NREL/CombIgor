#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
	// V1: Kevin Talley _ May 2018 : Adapted from V1
	// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

//Description of functions within:
	//Combi_DialogBox : Dialog box for informing user
	//Combi_CloseCDB : Close the Combi Dialog Box

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





//Function to make a new empty Data Text Table 
//returns 0 if already exists, 1 if successful
function Combi_NewTextTable(sWaveName)
	string sWaveName // name of wave
	
	//exit if wave exists, return 0
	if(WaveExists($GetDataFolder(0)+sWaveName))
		return 0
	endif
	
	//make wave
	Make/T/N=(1,1) $sWaveName
	DFREF pThisFolder = GetDataFolderDFR()	
	wave/T wNewScalarWave = pThisFolder:$sWaveName
	
	//set dimension labels in general
	SetDimLabel 0,-1,DataType,wNewScalarWave
	SetDimLabel 1,-1,Libraries,wNewScalarWave

	
	//return success indicator
	return 1
	
end

//Function to make a new empty Meta Data Table 
//returns 0 if already exists, 1 if successful
function Combi_NewMetaTable(sWaveName)
	string sWaveName // name of wave
	
	//exit if wave exists, return 0
	if(WaveExists($GetDataFolder(0)+sWaveName))
		return 0
	endif
	
	//make wave
	Make/T/N=(1,1,1) $sWaveName
	DFREF pThisFolder = GetDataFolderDFR()	
	wave/T wNewScalarWave = pThisFolder:$sWaveName
	
	//set dimension labels in general
	SetDimLabel 0,-1,DataType,wNewScalarWave
	SetDimLabel 1,-1,Sample,wNewScalarWave
	SetDimLabel 2,-1,Libraries,wNewScalarWave
	
	//return success indicator
	return 1
	
end

//Function to make a new empty Data Text Table 
//returns 0 if already exists, 1 if successful
function Combi_NewDataLog(sWaveName)
	string sWaveName // name of wave
	
	//exit if wave exists, return 0
	if(WaveExists($GetDataFolder(0)+sWaveName))
		return 0
	endif
	
	//make wave
	Make/T/N=(1,10) $sWaveName
	DFREF pThisFolder = GetDataFolderDFR()	
	wave/T wNewWave = pThisFolder:$sWaveName
	wNewWave[][] = ""
	
	//set dimension labels in general
	SetDimLabel 0,-1,Entry,wNewWave
	SetDimLabel 1,-1,Values,wNewWave
	SetDimLabel 0,0,Blank,wNewWave
	SetDimLabel 1,0,EntryNumber,wNewWave
	SetDimLabel 1,1,EntryTime,wNewWave
	SetDimLabel 1,2,Library,wNewWave
	SetDimLabel 1,3,DataType,wNewWave
	SetDimLabel 1,4,LogType,wNewWave
	SetDimLabel 1,5,LogEntry1,wNewWave
	SetDimLabel 1,6,LogEntry2,wNewWave
	SetDimLabel 1,7,LogEntry3,wNewWave
	SetDimLabel 1,8,LogEntry4,wNewWave
	SetDimLabel 1,9,LogEntry5,wNewWave
	
	//return success indicator
	return 1
	
end






//Add data to a wave
// sLibrary - can be list of Libraries, data goes to all
// sDataType - Can be a list of data types, corresponding to the dimension size of wDataWaveIn
// Library Data (iDimension = 0) with wDataWaveIn[LibraryTypes]
// Scalar Data (iDimension = 1) with wDataWaveIn[# of pts][ScalarTypes]
// Vector Data (iDimension = 2) with wDataWaveIn[# of pts][VectorTypes][VectorLength]
// Returns -1 if iDimension and dimensions do not match
// Returns -2 if no Main wave
function Combi_GiveData(wDataWaveIn,sProject,sLibraries,sDataTypes,iSample,iDimensions,[sScaleDataType])
	wave wDataWaveIn // data wave for incoming
	string sProject // project to operate within
	string sLibraries // Library names, "All" for all Libraries
	string sDataTypes // Data Type Labels
	variable iSample // Library Sample number, if all Samples then iSample = -1
	variable iDimensions // dimensionality of data set, 0=Library, 1 = scalar, 2 = vector
	string sScaleDataType // for setting scale on vector waves only.'
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//general variables
	variable iRow, iColumn, iLayer, iChunk, iIndex, iLibrary, iDataType
	string sThisDataType, sThisLibrary
	
	//LibraryWave
	wave sLibraryData = $"root:COMBIgor:"+sProject+":Data:"+"Library"
	
	//control Samples transferred
	int iSampleStart
	int iSampleEnd
	int bSingSample
	if(iSample==-1)
		iSampleStart = 0
		iSampleEnd = Combi_GetGlobalNumber("vTotalSamples",sProject)-1
		bSingSample = 0
	else
		iSampleStart = iSample
		iSampleEnd = iSample
		bSingSample = 1
	endif
	
	//get number of data types passed
	variable vDataTypesIn = itemsinlist(sDataTypes)
	variable vLibrariesIn = itemsinlist(sLibraries)
	
	//control Libraries transferred to
	variable iLibrarystart
	variable iLibraryEnd
	string sLoopLibraries
	if(StringMatch(sLibraries,"All"))
		iLibrarystart = 0
		iLibraryEnd = dimsize(sLibraryData,0)-1
		sLoopLibraries = Combi_TableList(sProject,iDimensions,"All","Libraries")
	else
		iLibrarystart = 0
		iLibraryEnd = Itemsinlist(sLibraries)-1
		sLoopLibraries = sLibraries
	endif
	
	//check for Libraries, add if not
	for(iLibrary=iLibrarystart;iLibrary<=iLibraryEnd;iLibrary+=1)
		sThisLibrary = stringfromlist(iLibrary,sLoopLibraries) 
		if(Finddimlabel(sLibraryData,0,sThisLibrary)==-2)
			Combi_NewLibrary(sProject,sThisLibrary)
		endif
		//check for data types, add if not
		for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sDataTypes) 
			Combi_AddDataType(sProject,sThisLibrary,sThisDataType,iDimensions)
		endfor
	endfor
	
	//Do checks
	int vInRows = dimsize(wDataWaveIn,0)
	int vInColumns = dimsize(wDataWaveIn,1)
	int vInLayers = dimsize(wDataWaveIn,2)
	int vInChunks = dimsize(wDataWaveIn,3)

	
	//Move Data
	//for Library data
	if(iDimensions==0)
		for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sDataTypes)
			for(iLibrary=iLibrarystart;iLibrary<=iLibraryEnd;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sLoopLibraries) 
				sLibraryData[iLibrary][][%$sThisDataType][] = nan
				sLibraryData[iLibrary][][%$sThisDataType][] = wDataWaveIn[iDataType]
			endfor			
		endfor
	//for scalar data
	elseif(iDimensions==1)
		for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sDataTypes)
			if(stringmatch(sThisDataType,""))
				continue
			endif
			for(iLibrary=iLibrarystart;iLibrary<=iLibraryEnd;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sLoopLibraries)
				setdatafolder root: 
				NewDataFolder/O/S COMBIgor
				NewDataFolder/O/S $sProject
				NewDataFolder/O/S Data
				NewDataFolder/O/S $sThisLibrary
				Make/O/N=(Combi_GetGlobalNumber("vTotalSamples",sProject)) $sThisDataType
				SetDataFolder $sTheCurrentUserFolder
				wave wThisData = $"root:COMBIgor:"+sProject+":Data:"+sThisLibrary+":"+sThisDataType
				wThisData[]=nan
				for(iSample=0;iSample<Combi_GetGlobalNumber("vTotalSamples",sProject);iSample+=1)
					setdimLabel 0, iSample, $"Sample_"+num2str(iSample+1), wThisData
				endfor
				setdimLabel 0, -1, $"Samples", wThisData
				for(iSample=iSampleStart;iSample<=iSampleEnd;iSample+=1) 
					wThisData[iSample] = wDataWaveIn[iSample][iDataType]
				endfor
			endfor
		endfor
	//for vector data
	elseif(iDimensions==2)
		for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sDataTypes)
			if(stringmatch(sThisDataType,""))
				continue
			endif
			for(iLibrary=iLibrarystart;iLibrary<=iLibraryEnd;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sLoopLibraries)  
				
				variable vScaleStart, vScaleEnd
				if(!paramIsDefault(sScaleDataType))
					wave/Z wScaleWave = $Combi_DataPath(sProject,2)+sThisLibrary+":"+sScaleDataType
				endif
				if(waveexists(wScaleWave))//scale wave exist
					if(dimsize(wScaleWave,1)==dimsize(wDataWaveIn,2))//right dim size to be a scale wave
						if(!stringmatch(sScaleDataType,sThisDataType))//not the same type
							vScaleStart = wScaleWave[0][0]
							vScaleEnd = wScaleWave[0][dimsize(wScaleWave,1)-1]
						endif
					endif
				else
					vScaleStart = 0
					vScaleEnd = dimsize(wDataWaveIn,2)-1
				endif
				setdatafolder root: 
				NewDataFolder/O/S COMBIgor 
				NewDataFolder/O/S $sProject
				NewDataFolder/O/S Data
				NewDataFolder/O/S $sThisLibrary
				Make/O/N=(Combi_GetGlobalNumber("vTotalSamples",sProject),vInLayers) $sThisDataType
				SetDataFolder $sTheCurrentUserFolder
				wave wThisData = $"root:COMBIgor:"+sProject+":Data:"+sThisLibrary+":"+sThisDataType
				setScale/I y, vScaleStart,vScaleEnd, wThisData
				for(iSample=0;iSample<Combi_GetGlobalNumber("vTotalSamples",sProject);iSample+=1)
					setdimLabel 0, iSample, $"Sample_"+num2str(iSample+1), wThisData
				endfor
				setdimLabel 0, -1, $"Samples", wThisData
				setdimLabel 1, -1, $sThisDataType, wThisData
				
				for(iSample=iSampleStart;iSample<=iSampleEnd;iSample+=1) 
					for(iIndex=0;iIndex<vInLayers;iIndex+=1)
						wThisData[iSample][iIndex] = nan
						if(bSingSample==1)
							wThisData[iSample][iIndex] = wDataWaveIn[0][iDataType][iIndex]
						elseif(bSingSample==0)
							wThisData[iSample][iIndex] = wDataWaveIn[iSample][iDataType][iIndex]
						endif
					endfor 
				endfor	
			endfor
		endfor
	endif
end


//Adding a Library to any COMBIgorWave, returns label used
function/S Combi_AddLibrary(sProject,sLibrary,iDim)
	string sProject // the COMBIgor project add to
	string sLibrary // Library to add
	int iDim// makes folder for values more than 0
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	if(stringmatch(sLibrary,"NAG")||stringmatch(sLibrary,"CANCEL"))
		return ""
	endif
	
	sLibrary = cleanupname(sLibrary,0)
	wave wLibraryData = $"root:COMBIgor:"+sProject+":Data:"+"Library"
	wave/T wMetaData = $"root:COMBIgor:"+sProject+":Data:"+"Meta"
	if(finddimlabel(wLibraryData,0,sLibrary)!=-2)
		return sLibrary
	endif
	
	//add dim and label to rows
	redimension/N=((dimsize(wLibraryData,0)+1),-1,-1,-1) wLibraryData
	redimension/N=((dimsize(wMetaData,0)+1),-1,-1,-1) wMetaData
	wLibraryData[dimsize(wLibraryData,0)-1][][][]=nan
	wMetaData[dimsize(wMetaData,0)-1][][][]=""
	setdimlabel 0,(dimsize(wLibraryData,0)-1),$sLibrary,wLibraryData
	setdimlabel 0,(dimsize(wMetaData,0)-1),$sLibrary,wMetaData
	
	if(iDim>0)
		SetDataFolder $Combi_IntoDataFolder(sProject,iDim)
		NewDataFolder/O/S $sLibrary
		SetDataFolder $sTheCurrentUserFolder 
	endif
	
	//return name of Library used
	COMBI_AddSampleID2Library(sProject,sLibrary)
	return sLibrary
	
end

//Adding a DataType to any COMBIgorWave, returns label used
function/S Combi_AddDataType(sProject,sLibrary,sDataType,iDim,[iVDim])
	string sProject // the COMBIgor wave to add to
	string sLibrary // Library for adding to (iDIm =1 or 2 only)
	string sDataType // Data Type to add
	int iDim //-1 for meta, 0 for Library, 1 for scalar, 2 for vector
	int iVDim //vector dimension
	if(ParamIsDefault(iVDim))
		iVDim =1
	endif
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 

	sDataType = cleanupname(sDataType,0)
	string sFolder, sAllDataTypes
	int iSample
	int vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	if(iDim==-1)
		//add dim and label to Layers
		wave/T wWave = $"root:COMBIgor:"+sProject+":Data:"+"Meta"
		if(FindDimLabel(wWave,2,sDataType)==-2)
			redimension/N=(-1,-1,(dimsize(wWave,2)+1)) wWave
			wWave[][][dimsize(wWave,2)-1]=""
			setdimlabel 2,(dimsize(wWave,2)-1),$sDataType,wWave
		endif
	elseif(iDim==0)
		//add dim and label to Layers
		wave wDataWave = $"root:COMBIgor:"+sProject+":Data:"+"Library"
		if(FindDimLabel(wDataWave,1,sDataType)==-2)
			redimension/N=(-1,(dimsize(wDataWave,1)+1)) wDataWave
			wDataWave[][dimsize(wDataWave,1)-1]=nan
			setdimlabel 1,(dimsize(wDataWave,1)-1),$sDataType,wDataWave
		endif
	elseif(iDim==1)
		Combi_IntoDataFolder(sProject,iDim)
		NewDataFolder/O/S $sLibrary
		sAllDataTypes =ReplaceString(",",StringByKey("WAVES", DataFolderDir(2)),";")
		setdatafolder root:
		if(whichlistItem(sDataType,sAllDataTypes)==-1)
			sFolder = Combi_IntoDataFolder(sProject,iDim)
			NewDataFolder/O/S $sLibrary
			Make/O/N=(vTotalSamples) $sDataType
			SetDataFolder $sTheCurrentUserFolder 
			wave wThisNew = $sFolder+sLibrary+":"+sDataType
			wThisNew[]=nan
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				SetDimLabel 0,iSample,$"Sample_"+num2str(iSample+1),wThisNew
			endfor
			setdimLabel 0, -1, $"Samples", wThisNew
		endif	
	elseif(iDim==2)
		Combi_IntoDataFolder(sProject,iDim)
		NewDataFolder/O/S $sLibrary
		sAllDataTypes =ReplaceString(",",StringByKey("WAVES", DataFolderDir(2)),";")
		setdatafolder root:
		if(whichlistItem(sDataType,sAllDataTypes)==-1)//not made
			sFolder = Combi_IntoDataFolder(sProject,iDim)
			//how long of vectors?
			NewDataFolder/O/S $sLibrary
			Make/N=(vTotalSamples,iVDim) $sDataType
			SetDataFolder $sTheCurrentUserFolder 
			wave wThisNew = $sFolder+sLibrary+":"+sDataType
			wThisNew[][]=nan
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				SetDimLabel 0,iSample,$"Sample_"+num2str(iSample+1),wThisNew
			endfor
			SetDimLabel 1,-1,$sDataType,wThisNew
		else //already exist
			wave wThisOld = $Combi_DataPath(sProject,iDim)+sLibrary+":"+sDataType
			int vOldSize = dimsize(wThisOld,1)
			if(vOldSize<iVDim)
				redimension/N=(-1,iVDim) wThisOld
				wThisOld[][vOldSize,(iVDim-1)] = nan
			endif
		endif	
	endif
	return sDataType
end

//function to add Library to all data tables
function Combi_NewLibrary(sProject,sLibrary)
	string sProject //project to add to
	string sLibrary //Library to add
	if(stringmatch(sLibrary,"NAG")||stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//add to waves
	Combi_AddLibrary(sProject,sLibrary,0)
	Combi_AddLibraryToScalar(sProject,sLibrary)
end


// to put text into meta data wave
//returns 2 if had to create the data label
//returns 1 if had to create the Library label
//returns 4 if had to create both
function Combi_GiveMeta(sProject,sDataType,sLibrary,sMeta,iSample)
	string sProject // for this project
	string sDataType // this data label
	string sLibrary // this Library label
	string sMeta// Meta data to store
	int iSample//-1 for all, or 0 through vTotalSamples-1
	
	//get wave
	wave/T twMeta = $Combi_DataPath(sProject,-1)
	variable vOut = -1
	
	//add data type if needed
	if(FindDimLabel(twMeta,2,sDataType)==-2)
		redimension/N=(-1,-1,(dimsize(twMeta,2)+1)) twMeta
		twMeta[][][dimsize(twMeta,2)-1]=""
		setdimlabel 2,(dimsize(twMeta,2)-1),$sDataType,twMeta
		vOut+=3
	endif
	
	//add Library if needed
	if(FindDimLabel(twMeta,0,sLibrary)==-2)
		redimension/N=(dimsize(twMeta,0)+1,-1,-1) twMeta
		twMeta[dimsize(twMeta,0)-1][][]=""
		setdimlabel 0,(dimsize(twMeta,0)-1),$sLibrary,twMeta
		vOut+=2
	endif
	
	//set value 
	if(iSample==-1)
		twMeta[%$sLibrary][][%$sDataType] = sMeta
	elseif(0<=iSample<Combi_GetGlobalNumber("vTotalSamples","COMBIgor"))
		twMeta[%$sLibrary][iSample][%$sDataType] = sMeta
	endif
	
	//return indicator
	return vOut

end


//Add scalar data
// sLibrary - can be list of Libraries, data goes to all
// sDataType - Can be a list of data types, corresponding to the dimension size of wDataWaveIn
// Returns -2 if no Main wave
function Combi_GiveScalar(vDataIn,sProject,sLibraries,sDataTypes,iSample)
	variable vDataIn // data incoming
	string sProject // project to operate within
	string sLibraries // Library names, "All" for all Libraries
	string sDataTypes // Data Type Label
	variable iSample // Library Sample number, if all Samples then iSample = -1
	
	//general variables
	variable iRow, iColumn, iLayer, iChunk, iIndex, iLibrary, iDataType
	string sThisDataType, sThisLibrary
	
	//control Samples transferred
	variable iSampleStart
	variable iSampleEnd
	if(iSample==-1)
		iSampleStart = 0
		iSampleEnd = Combi_GetGlobalNumber("vTotalSamples",sProject)-1
	else
		iSampleStart = iSample
		iSampleEnd = iSample
	endif
	
	variable vLibrariesIn = itemsinlist(sLibraries)
	variable vDataTypesIn = itemsinlist(sDataTypes)
	
	//get all from scalar
	string sAllDataTypes = Combi_TableList(sProject,1,"All","DataTypes")
	string sFromMappingGrid = Combi_TableList(sProject,1,"All","Libraries")
	
	//control Libraries transferred to
	variable iLibraryStart
	variable iLibraryEnd
	string sAllLoopLibraries
	if(StringMatch(sLibraries,"All"))
		iLibraryStart = 0
		iLibraryEnd = itemsInList(sFromMappingGrid)-1
		sAllLoopLibraries = sFromMappingGrid
	else
		iLibraryStart = 0
		iLibraryEnd = 0
		sAllLoopLibraries = sLibraries
	endif
	
	//check for Libraries, add if not
	for(iLibrary=iLibrarystart;iLibrary<=iLibraryEnd;iLibrary+=1)
		sThisLibrary = stringfromlist(iLibrary,sAllLoopLibraries) 
		if(whichListItem(sThisLibrary,sFromMappingGrid)==-1)
			Combi_NewLibrary(sProject,sThisLibrary)
		endif
		//check for data types, add if not
		for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
			sThisDataType = stringfromlist(iDataType,sDataTypes)
			Combi_AddDataType(sProject,sThisLibrary,sThisDataType,1)
		endfor
	endfor
	
	//Move Data
	for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
		sThisDataType = stringfromlist(iDataType,sDataTypes)
		if(stringmatch(sThisDataType,""))
			continue
		endif
		for(iLibrary=iLibraryStart;iLibrary<=iLibraryEnd;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sAllLoopLibraries)
			Wave wScalar = $Combi_DataPath(sProject,1)+sThisLibrary+":"+sThisDataType
			for(iSample=iSampleStart;iSample<=iSampleEnd;iSample+=1) 
				wScalar[iSample] = vDataIn
			endfor	
		endfor
	endfor
	
end

function Combi_GiveLibraryData(vDataIn,sProject,sLibraries,sDataTypes)
	variable vDataIn // data incoming
	string sProject // project to operate within
	string sLibraries // Library names, "All" for all Libraries
	string sDataTypes // Data Type Label
	
	//general variables
	variable iRow, iColumn, iLayer, iChunk, iIndex, iLibrary, iDataType
	string sThisDataType, sThisLibrary
	
	variable vLibrariesIn = itemsinlist(sLibraries)
	variable vDataTypesIn = itemsinlist(sDataTypes)

	wave wMainWave = $Combi_DataPath(sProject,0)
	
	//check that main exists
	if(!waveexists(wMainWave))
		DoAlert/T="COMBIgor error." 0,"No COMBIgor wave to put this data in"
		Return -2
	endif
	
	//control Libraries transferred to
	variable iLibraryStart
	variable iLibraryEnd
	if(StringMatch(sLibraries,"All"))
		iLibraryStart = 1
		iLibraryEnd = dimsize(wMainWave,0)-1
	else
		//check for Libraries, add if not
		for(iLibrary=0;iLibrary<vLibrariesIn;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sLibraries) 
			if(Finddimlabel(wMainWave,0,sThisLibrary)==-2)
				Combi_NewLibrary(sProject,sThisLibrary)
			endif
		endfor
	endif
	
	//check for data types, add if not
	for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
		sThisDataType = stringfromlist(iDataType,sDataTypes) 
		if(Finddimlabel(wMainWave,1,sThisDataType)==-2)
			Combi_AddDataType(sProject,"",sThisDataType,0)
		endif	
	endfor

	//Move Data
	for(iDataType=0;iDataType<vDataTypesIn;iDataType+=1)
		sThisDataType = stringfromlist(iDataType,sDataTypes)
		if(stringmatch(sThisDataType,""))
			continue
		endif
		if(stringmatch("All",sLibraries))
			wMainWave[][%$sThisDataType] = vDataIn
		else
			for(iLibrary=0;iLibrary<vLibrariesIn;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sLibraries) 
					wMainWave[%$sThisLibrary][%$sThisDataType] = vDataIn
			endfor
		endif
	endfor
	
end

//to return min and max values from data tables
function Combi_Extremes(sProject,iDim,sDataType,sLibraries,sSamples,sType)
	string sProject // project in COMBIgor
	variable iDim // data dimensions (0=Library,1=scalar,2=vector)
	string sDataType //name of data type
	string sLibraries // for these Libraries
	string sSamples // for this "All", or "SampleMin;SampleMax;GA1Min;GA1Max;GA2Min;GA2Max" with any equal to " " to include all
	string sType // 
	
	//get COMBIgor waves
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	
	//get min and max ranges
	variable vPtMax,vPtMin,vGA1Min,vGA1Max,vGA2Min,vGA2Max
	if(stringmatch(sSamples,"All"))
		vPtMin = str2num(stringfromlist(0,Combi_LibraryQualifiers(sProject,4)))
		vPtMax = str2num(stringfromlist(itemsinlist(Combi_LibraryQualifiers(sProject,0))-1,Combi_LibraryQualifiers(sProject,0)))
		vGA1Min = str2num(stringfromlist(0,Combi_LibraryQualifiers(sProject,4)))
		vGA1Max = str2num(stringfromlist(itemsinlist(Combi_LibraryQualifiers(sProject,3))-1,Combi_LibraryQualifiers(sProject,3)))
		vGA2Min = str2num(stringfromlist(0,Combi_LibraryQualifiers(sProject,4)))
		vGA2Max = str2num(stringfromlist(itemsinlist(Combi_LibraryQualifiers(sProject,4))-1,Combi_LibraryQualifiers(sProject,4)))
	else
		if(stringmatch(stringfromlist(0,sSamples)," "))
			vPtMin = str2num(stringfromlist(0,Combi_LibraryQualifiers(sProject,0)))
		else
			vPtMin = str2num(stringfromlist(0,sSamples))
		endif
		if(stringmatch(stringfromlist(1,sSamples)," "))
			vPtMax = str2num(stringfromlist(itemsinlist(Combi_LibraryQualifiers(sProject,0))-1,Combi_LibraryQualifiers(sProject,0)))
		else
			vPtMax = str2num(stringfromlist(1,sSamples))
		endif
		if(stringmatch(stringfromlist(2,sSamples)," "))
			vGA1Min = str2num(stringfromlist(0,Combi_LibraryQualifiers(sProject,3)))
		else
			vGA1Min = str2num(stringfromlist(2,sSamples))
		endif
		if(stringmatch(stringfromlist(3,sSamples)," "))
			vGA1Max = str2num(stringfromlist(itemsinlist(Combi_LibraryQualifiers(sProject,3))-1,Combi_LibraryQualifiers(sProject,3)))
		else
			vGA1Max = str2num(stringfromlist(3,sSamples))
		endif
		if(stringmatch(stringfromlist(4,sSamples)," "))
			vGA2Min = str2num(stringfromlist(0,Combi_LibraryQualifiers(sProject,4)))
		else
			vGA2Min = str2num(stringfromlist(4,sSamples))
		endif
		if(stringmatch(stringfromlist(5,sSamples)," "))
			vGA2Max = str2num(stringfromlist(itemsinlist(Combi_LibraryQualifiers(sProject,4))-1,Combi_LibraryQualifiers(sProject,4)))
		else
			vGA2Max = str2num(stringfromlist(5,sSamples))
		endif
	endif
	
	//loop through all Library Samples, Libraries, vector index
	variable vSample, vGA1, vGA2
	variable vMin = inf, vMax = -inf
	int iVector, iLibrary, iSample
	variable vThisValue
	string sThisLibrary
	variable vTotal=0, vTerms=0
	for(iSample=0;iSample<Combi_GetGlobalNumber("vTotalSamples",sProject);iSample+=1)
		vSample = iSample + 1
		vGA1 = wMappingGrid[iSample][3]
		vGA2 = wMappingGrid[iSample][4]
		for(iLibrary=0;iLibrary<itemsinlist(sLibraries);iLibrary+=1)
			sThisLibrary = stringfromList(iLibrary,sLibraries)			
			if(vSample>=vPtMin&&vSample<=vPtMax) // within Sample range
				if(vGA1>=vGA1Min&&vGA1<=vGA1Max) // within GA1 range
					if(vGA2>=vGA2Min&&vGA2<=vGA2Max)// within GA2 range
						if(iDim==0)
							wave wWaveToSearch = $Combi_DataPath(sProject,0) 
							vThisValue = wWaveToSearch[%$sThisLibrary][%$sDataType]
							vTerms+=1
							vTotal+=vThisValue
							if(vThisValue<vMin)
								vMin = vThisValue
							endif
							if(vThisValue>vMax)
								vMax = vThisValue
							endif 
						elseif(iDim==1)
							wave/Z wWaveToSearch = $Combi_DataPath(sProject,1)+sThisLibrary+":"+sDataType
							if(!waveExists(wWaveToSearch))
								Continue
							endif
							vThisValue = wWaveToSearch[iSample][0]
							vTerms+=1
							vTotal+=vThisValue
							if(vThisValue<vMin)
								vMin = vThisValue
							endif
							if(vThisValue>vMax)
								vMax = vThisValue
							endif 
						elseif(iDim==2)
							wave/Z wWaveToSearch = $Combi_DataPath(sProject,2)+sThisLibrary+":"+sDataType
							if(!waveExists(wWaveToSearch))
								Continue
							endif
							for(iVector=0;iVector<dimsize(wWaveToSearch,1);iVector+=1)
								vThisValue = wWaveToSearch[iSample][iVector]
								vTerms+=1
								vTotal+=vThisValue
								if(vThisValue<vMin)
									vMin = vThisValue
								endif
								if(vThisValue>vMax)
									vMax = vThisValue
								endif 	
							endfor
						endif
					endif
				endif
			endif	
		endfor
	endfor
	
	//return needed value
	if(stringmatch(sType,"Min"))
		return vMin
	elseif(stringmatch(sType,"Max"))
		return vMax
	elseif(stringmatch(sType,"Range"))
		return vMax-vMin
	elseif(stringmatch(sType,"Mean"))
		return vTotal/vTerms
	endif
	
end



function Combi_NewEntry(sProject,sType)
	String sType// "Library" or "DataType"
	string sProject
	string sThisLibrary = ""
	int iNewDTDim = WhichListItem(Combi_StringPrompt("Scalar","New Data Type Dimension:","Meta;Library;Scalar;Vector","This is the table the data type will be added to.","New Data Type Dimension?"), "Meta;Library;Scalar;Vector")-1
	if(stringmatch("DataType",sType))
		//make new data type
		string sNewDataType = Combi_StringPrompt("New Data Name","Name for new Data Type:","","This will be cleaned up and added to the table as  a new data type.","A New Data Type!")
		if(stringmatch(sNewDataType,"CANCEL"))
			return -1
		endif
		if(iNewDTDim>=1)
			//which Library?
			sThisLibrary = Combi_LibraryPrompt(sProject,"New","For what Library?",0,1,0,iNewDTDim)
			if(stringmatch(sThisLibrary,"CANCEL"))
				return -1
			endif
		endif
		int iVLength = 1
		string sOptionalPars=""
		if(iNewDTDim==2)
			//length?
			iVLength = COMBI_NumberPrompt(1,"Vector Length","This will be the length of the vector data, and therefore the number of columns in the vector data wave.","How many points long?")
			if(numtype(iVLength)!=0)
				return -1
			endif
			sOptionalPars =",iVDim="+num2str(iVLength)
		endif
		sNewDataType = cleanupName(sNewDataType,0)
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "Combi_AddDataType(\""+sProject+"\",\""+sThisLibrary+"\",\""+sNewDataType+"\","+num2str(iNewDTDim)+sOptionalPars+")"
		endif
		Combi_AddDataType(sProject,sThisLibrary,sNewDataType,iNewDTDim,iVDim=iVLength)
	elseif(stringmatch("Library",sType))
		//make new Library
		string sNewLibrary = Combi_StringPrompt("New Library Name","Name for new Library:","","This will be cleaned up and added to the table as  a new Library.","A New Library!")
		sNewLibrary = cleanupName(sNewLibrary,0)
		Combi_AddLibrary(sProject,sNewLibrary,iNewDTDim)
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "Combi_AddLibrary(\""+sProject+"\",\""+sNewLibrary+"\","+num2str(iNewDTDim)+")"
		endif
	endif
	return -1
end



Function Combi_AddNewEntryFromMenu(sType)
	String sType// "Library" or "DataType"
	string sProject = COMBI_ChooseProject()
	Combi_NewEntry(sProject,sType)
end
