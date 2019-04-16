#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ September 2018 : Original
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function/S BrukerXRD_LoadFile()


	// get import path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	variable vRefNum
	
	
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Open/D/R/P=pUserPath/T=".raw" vRefNum as ""
	else
		Open/D/R/T=".raw" vRefNum as ""
	endif
	string sThisLoadFile = S_fileName //for storing source folder in data log
	if(strlen(sThisLoadFile)==0)
		//no file selected
		return ""
	endif
	
	variable vPathLength = itemsinlist(sThisLoadFile,":")
	String sFileName = stringfromlist(vPathLength-1,sThisLoadFile,":")
	string sFilePath = removeending(sThisLoadFile,sFileName)
	
	string sLoadedWaveName=BrukerXRD_DiffracPlusLoad(sFileName,sFilePath,1,"")
	
	return sLoadedWaveName

end

function BrukerXRD_LoadFolder(sProject,sIntensity,sDegree)
	string sProject,sIntensity,sDegree

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:

	string sThisInstrumentName = "BrukerXRD"
	
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
	string sAllFiles = IndexedFile(pLoadPath,-1,".raw")
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	string sFirstFile = removeending(IndexedFile(pLoadPath,0,".raw"),".raw")
	string sLastFile = removeending(IndexedFile(pLoadPath,vNumberOfFiles-1,".raw"),".raw")
	variable vFirstFileNameLength = strlen(sFirstFile)
	variable vLastFileNameLength = strlen(sLastFile)
	
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
	prompt sDegree, "Degree Label:"
	prompt sIntensity, "Intensity Label:"
	string sThisHelp
	sThisHelp = "This helps me find all the files to load. The file name is constructed from the Prefix + (Index of set # of digits) + Suffix"
	DoPrompt/HELP=sThisHelp "XRD Files", sFilePrefix, sFileSufix, vFirstFileNum, vLastFileNum,vIndexDigits
	if (V_Flag)
		return -1// User canceled
	endif
	
	//number of Libraries
	variable vNumberOfLibraries = floor((vLastFileNum-vFirstFileNum+1)/vTotalSamples)
	vNumberOfLibraries = Combi_NumberPrompt(vNumberOfLibraries,"Number of Libraries in this folder","How many libraries are in this folder? Not all of them must be loaded (there will be an option to skip) but please enter the total number.","Libraries in Folder?")
	if(numtype(vNumberOfLibraries)==2)
		return-1
	endif	
	if(vNumberOfLibraries<1||vNumberOfLibraries>4)//too many or too few Libraries
		DoAlert/T="COMBIgor error." 0,"COMBIgor can only load 1-4 Libraries for the Bruker XRD."
		return -1
	endif

	//Get Library Names
	variable iLibrary, vIndex, vAngleMax, vAngleMin
	string sLibraries="", sFirstSamples="",sLastSamples="",sFirstIndexs="",sLastIndexs="", sThisLibrary, sThisFileName
	for(iLibrary=0;iLibrary<vNumberOfLibraries;iLibrary+=1)
		string sLibraryDestinations = Combi_LibraryLoadingPrompt(sProject,"New","Library "+num2str(iLibrary+1)+" Name:",1,1,-3,iLibrary)
		if(stringmatch(sLibraryDestinations,"CANCEL"))
			return -1
		endif
		sLibraries = AddListItem(cleanupname(stringfromlist(0,sLibraryDestinations),0),sLibraries,";",inf)
		sFirstSamples = AddListItem(stringfromlist(1,sLibraryDestinations),sFirstSamples,";",inf)
		sLastSamples = AddListItem(stringfromlist(2,sLibraryDestinations),sLastSamples,";",inf)
		sFirstIndexs = AddListItem(stringfromlist(3,sLibraryDestinations),sFirstIndexs,";",inf)
		sLastIndexs = AddListItem(stringfromlist(4,sLibraryDestinations),sLastIndexs,";",inf)
		//log parsing values
		
		//Load files to root:
		for(vIndex=str2num(stringfromlist(3,sLibraryDestinations));vIndex<=str2num(stringfromlist(4,sLibraryDestinations));vIndex+=1)
			sThisFileName = sFilePrefix+Combi_PadIndex(vIndex+1,vIndexDigits)+sFileSufix+".raw"
			NewDataFolder/O/S BrukerFolderOScans
			string sThisWave = BrukerXRD_DiffracPlusLoad(sThisFileName,sThisLoadFolder,0,Combi_PadIndex(vIndex+1,vIndexDigits))
			SetDataFolder root:
			wave wWaveIn = $"root:BrukerFolderOScans:"+RemoveEnding(sThisWave,";")
			//Add Q if Degree is XRD_TwoTheta
			if(stringmatch(sDegree,"XRD_TwoTheta"))
				redimension/N=(-1,3) wWaveIn
				wWaveIn[][2]= 4*pi*Sin(wWaveIn[p][0]*pi/360)/vWavelength
				vAngleMax = wWaveIn[dimSize(wWaveIn,0)-1][2]
				vAngleMin =  wWaveIn[0][2]
			endif
			vAngleMax = wWaveIn[dimSize(wWaveIn,0)-1][0]
			vAngleMin =  wWaveIn[0][0]
		endfor
	endfor
	
	//sort loaded files
	if(stringmatch(sDegree,"XRD_TwoTheta"))
		Combi_SortNewVectors(sProject,"root:BrukerFolderOScans:","XRD_","",3,sLibraries,sDegree+";"+sIntensity+";XRD_Q_2PiPerAng",sFirstSamples,sLastSamples,sFirstIndexs,sLastIndexs,1,sScaleDataType=sDegree)
		COMBIDisplay_Global("XRD_Q_2PiPerAng","Scattering Vector Magnitude (2π/Å)","Label")
	else
		Combi_SortNewVectors(sProject,"root:BrukerFolderOScans:","XRD_","",3,sLibraries,sDegree+";"+sIntensity,sFirstSamples,sLastSamples,sFirstIndexs,sLastIndexs,1,sScaleDataType=sDegree)
	endif
	
	//add to data log
	variable iDataType
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File Folder: "+sThisLoadFolder
	sLogEntry2 = "Library Samples: "+Replacestring(";",sFirstSamples,",")+" to "+Replacestring(";",sLastSamples,",")
	sLogEntry3 = "From File Indexes: "+Replacestring(";",sFirstIndexs,",")+" to "+Replacestring(";",sLastIndexs,",")
	sLogEntry4 = "Data Types: "+sDegree+","+sIntensity
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sLibraries,"BrukerXRD",1,sLogText)		
	
	//kill paths
	Killpath/A
	KillDataFolder/Z root:BrukerFolderOScans
	
	//if plot on loading
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		//get data path to Intensity and set scale in column dim
		for(iLibrary=0;iLibrary<vNumberOfLibraries;iLibrary+=1)
			if(!stringmatch(stringfromlist(iLibrary,sLibraries),"Skip"))
				wave wIntensity = $Combi_DataPath(sProject,2)+stringfromlist(iLibrary,sLibraries)+":"+sIntensity
				string sGizName = stringfromlist(iLibrary,sLibraries)+"_"+sIntensity
				string sGizTitle = stringfromlist(iLibrary,sLibraries)+" "+sIntensity
				SetScale/I y, vAngleMin, vAngleMax,wIntensity
				SetScale/I x,1,dimsize(wIntensity,0),wIntensity
				string sZLabel = replacestring("XRD_",sIntensity,"")
				string sDegLabel = replacestring("XRD_",sDegree,"")
				BrukerXRD_MakeA3DXRDPlotFromScaledWave(sProject,stringfromlist(iLibrary,sLibraries),sIntensity,sDegLabel,sZLabel)
			endif	
		endfor
	endif
	
	SetDataFolder $sTheCurrentUserFolder
	
end

//for loading a single Bruker .raw file, returns name of wave data is in
Function/S BrukerXRD_DiffracPlusLoad(sFileName,sFilePath,bKeepName,sIndex)
	String sFileName //name of file to open
	string sFilePath //path to file 
	variable bKeepName //1 to keep name intact, 0 "XRD_"+sIndex
	string sIndex
	
	//define structures for loading
	Struct DiffracPlus_RawHdr RH //  RH = Raw Header
	Struct DiffracPlus_RawRngHdr RRH //  RRH  = Raw Range Header
	Struct DiffracPlus_SupRngHdr SRH // SRH = Supplementary Range Header
	Struct DiffracPlus_SupRngHdr200 SRH200 // SRH200 = Supplementary Range Header for Area detector
	Struct DiffracPlusWaveNoteHeader WNH // WNH = Wave Note Header (to store attached to wave as string)
	
	//make string to return
	string sReturnString =""
	
	//make path
	NewPath/O/Q pBrukerFilePath, sFilePath
	
	//open file
	variable vThisFileRef
	Open /R/T=".raw"/P=pBrukerFilePath vThisFileRef as sFileName
	
	//getfilename, no extension for logging
	string sFileNameRoot = RemoveEnding(sFileName,".raw")
	
	//get file info
	FStatus vThisFileRef
	if (!V_flag)
		DoAlert/T="COMBIgor error!" 0,"Bruker XRD File Did Not Open Correctly."
		return ""
	endif
	
	//read raw header parts
	FBinRead/B=3 vThisFileRef, RH
	
	//get number or ranges to read
	variable vTotalRanges =  RH.NumMeasuredRanges
	variable vWavelength = RH.PrimaryWavelength_A
	
	//load each range 
	variable iRange, vSuppHeaderSize, vNumOfSamples, vStartDeg, vScanDegStep
	string sThisWaveName, sWaveNoteHeader
	for (iRange=1;iRange<=vTotalRanges;iRange+=1)
		
		//Read Raw Range Header
		FBinRead/B=3 vThisFileRef, RRH
		
		//check that raw data is in 4 bytes
		if (RRH.LengthOfDataRecord_bytes != 4)
			DoAlert/T="COMBIgor error!" 0,"Data Record Bytes > 4. Not Supported."
			return(sReturnString)
		endif
		
		//give unique name if more than 1 range
		variable vNameLength = strlen(sFileNameRoot)
		if(bKeepName==0)//dont preseve name, use the 3 digit index at file end
			if(vTotalRanges>1)
				sThisWaveName = "XRD_"+sIndex+"_"+num2str(iRange)
			else
				sThisWaveName = "XRD_"+sIndex
			endif
		elseif(bKeepName==1)//keep wave name the file name
			if(vTotalRanges>1)
				sThisWaveName = UniqueName(Cleanupname(sFileNameRoot,0)+"_"+num2str(iRange),1,0)
			else
				sThisWaveName = Cleanupname(sFileNameRoot,0)
			endif
		endif
	
		
		//get supplementary raw headers if any
		vSuppHeaderSize = RRH.TotalSizeSuppHeaders_bytes 
		if (RRH.TotalSizeSuppHeaders_bytes>0)
			if (DiffracPlus_GetSupRngHdr(vThisFileRef, SRH)== -1)
				return(sReturnString)
			else
				//binary wave to hold Supp Range Header
				make/B/U/N=(SRH.RecordLength_bytes) wtemp
				//get binary data from Supp range header, then kill wave
				wave wtemp = wtemp
				wtemp = SRH.RecordWave[p]
				StructGet SRH200, wtemp
				Killwaves wtemp
				//store supp range header in wave note header
				WNH.SRH1 = SRH
				//check for more supp range headers
				if (WNH.SRH1.RecordLength_bytes < RRH.TotalSizeSuppHeaders_bytes)
					DoAlert/T="COMBIgor error!" 0,"More Than One Supplementary Range Header.  Not Supported Yet"
					return(sReturnString)
				endif
			endif
		endif
		
		//get data info
		vNumOfSamples = RRH.NumDataSamples
		vStartDeg = DiffracPlus_ScanStart(RRH)
		vScanDegStep = RRH.StepSize1
		
		//Make wave to hold data
		make/O/n=(vNumOfSamples) $sThisWaveName
		Wave wThisData = $sThisWaveName
		SetScale /P x, vStartDeg, vScanDegStep, wThisData
		
		//read in data to wave
		FBinRead/B=3 vThisFileRef, wThisData
		
		//append wave name to output string
		sReturnString = AddListItem(sThisWaveName,sReturnString,";",Inf)
		
		//populate degree
		redimension/N=(-1,2) wThisData
		wThisData[][1] = wThisData[p][0]
		wThisData[][0] = vStartDeg+p*vScanDegStep
		
		//make wave note header and store as note on wave
		WNH.DataRangeNumber = iRange
		WNH.RH = RH
		WNH.RRH = RRH
		StructPut/S WNH, sWaveNoteHeader
		Note/K wThisData
		//Note wThisData, sWaveNoteHeader
		
	endfor

	//close the opened file
	Close vThisFileRef
	
	//kill the folder path
	killpath pBrukerFilePath
	
	//return load status
	return(sReturnString)
End

//structures needed to import Bruker diffractplus .raw files are below here
Structure DiffracPlus_RawHdr
	char cRawVersion[8]
	int32 CurrentFileStatus
	int32 NumMeasuredRanges
	char cDate[10]
	char cTime[10]
	char cUserName[72]
	char cCompanyName1[100]
	char cCompanyName2[100]
	char cCompanyName3[18]
	char cLibraryName[60]
	char cComment1[100]
	char cComment2[60]
	char cPadding1[2]
	int32 GoniometerModel
	int32 GoniometerStage
	int32 SampleChangeer
	int32 GoniometerController
	float GoniometerRadius_mm
	float DivergSlitFixInc_deg
	float SampleSlitFixInc_deg
	int32 PrimarySollerSlit
	int32 PrimaryMonochrometer
	float AntiSlitDiffracSide_deg
	float DetectorSlitDiffracSide_deg
	int32 SecondarySollerSlit
	int32 ThinFilm
	int32 BetaFilter
	int32 SecondaryMonochromator
	char cAnode[4]
	char cPadding2[4]
	double AverageWavelength_A
	double PrimaryWavelength_A
	double SeondaryWavelength_A
	double TertiaryWavelength_A
	double IntRatioSecondToPrime
	char cWavelenthUnits[4]
	float IntRatioTertToPrime
	float TotalSampleRunTime
	char cForExpansion[44]
EndStructure

Structure DiffracPlus_RawRngHdr
	int32 RangeHeaderBytes
	int32 NumDataSamples
	double ThetaStart_deg
	double TwoThetaStart_deg
	double ChiStart_deg
	double PhiStart_deg
	double XStart_mm
	double YStart_mm
	double ZStart_mm
	double DivSlitStart_deg
	char DivSlitCode[8]
	double AntiSlitStart_deg
	char AntiSlitCode[8]
	int32 DetectorUsedThisRange
	float HighVoltageForDetector
	float AmplifierGain
	float LowerLevelUsedinV
	float UpperLevelUsedinV
	int32 MeasuringChannel
	float UnusedField
	float UnusedField2
	float AltLLD
	float AltULD
	char InOrOut[8]
	double StartAuxAxis1_h
	double StartAuxAxis2_k
	double StartAuxAxis3_l
	int32 ScanMode
	char cPadding[4]
	double StepSize1
	double StepSize2
	float StepTime_sec
	int32 ScanType
	float DelayTimeBeforeStart_s
	float TimeRangeStartedRelToSample_s
	float RotationSpeed_rps
	float Temperature_k
	float HeatingCoolingRate_k_s
	float DelayBeforeTC_s
	int32 GeneratorVoltage_kV
	int32 GeneratorCurrent_mA
	int32 DisplayPlaneNumber
	char cPadding2[4]
	double ActualSelectedWavelength_A
	int32 ReservedForFutureMultiScan
	int32 LengthOfDataRecord_bytes
	int32 TotalSizeSuppHeaders_bytes
	float SmoothingWidth_deg
	int32 FlagWordForSimMeas
	char cPadding3[4]
	float StepSize3
	char ForExpansion[28] // Note:  In doc it is 24 but tests show it is 28
EndStructure

Structure DiffracPlus_SupRngHdr200 // Description for Area Detector Parameters Record
	int32 RecordType // 200 for this one
	int32 RecordLength_bytes
	char Reserved[8]
	float  Int2TStart_deg
	float  Int2TEnd_deg
	float  IntChiStartorChiAngle_deg
	float IntChiEndOrHeight_deg // Height -> Height + 1000.0 
	int32 NormMethod // 1 = avg, 2 = arclength, 3=solid angle, 4 = bin
	char ProgramName[20]
	float Goniometer2T
	float GoniometerOmega
	float GoniometerPhi
	float GoniometerChi
EndStructure

Structure DiffracPlus_SupRngHdr
	int32 RecordType
	int32 RecordLength_bytes
	uchar RecordWave[100]
EndStructure

Structure DiffracPlusWaveNoteHeader
	char SourceFileName[64]
	int32 DataRangeNumber
	Struct DiffracPlus_RawHdr RH
	Struct DiffracPlus_RawRngHdr RRH
	int32 NumDiffracPlus_SupRngHdrs
	Struct DiffracPlus_SupRngHdr SRH1
	Struct DiffracPlus_SupRngHdr SRH2
	Struct DiffracPlus_SupRngHdr SRH3
EndStructure

//function to interpret the supp range header of a diffactplus raw file
Function DiffracPlus_GetSupRngHdr(vThisFileRef,SRH)
	variable vThisFileRef
	STRUCT DiffracPlus_SupRngHdr &SRH

	//Read Supp Header Type
	variable DiffracPlus_SupRngHdrType
	FBinRead/B=3/F=3 vThisFileRef, DiffracPlus_SupRngHdrType
	
	//Rewind to start of supp range header
	FStatus vThisFileRef
	FSetPos vThisFileRef, (V_FilePos - 4)
	
	//depending on type of supp header
	variable iRecord
	switch(DiffracPlus_SupRngHdrType) 
		case 100:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for Oscillation Parameters Not Supported Yet."
			return(-1)
			break
		case 110:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for PSD Not Supported Yet."
			return(-1)
			break
		case 120:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for OQM Not Supported Yet."
			return(-1)
			break
		case 130:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for QCI Not Supported Yet."
			return(-1)
			break
		case 140:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for Comment Record Not Supported Yet."
			return(-1)
			break
		case 150:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for Removed Data Record Not Supported Yet."
			return(-1)
			break
		case 190:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header for Offset Aligned by EVA Not Supported Yet."
			return(-1)
			break
		case 200:
			//area detector
			STRUCT DiffracPlus_SupRngHdr200 SRH200  // SRH200 = Area Detector Parameters Record
			//read this supp header for area detector
			FBinRead/B=3 vThisFileRef,  SRH200
			//store record length in supp range header
			SRH.RecordLength_bytes = SRH200.RecordLength_Bytes
			//make temp wave to hold record
			make/B/U/N=(SRH200.RecordLength_Bytes) wSRH200temp
			//put area detector supp header  into temp wave 
			StructPut SRH200, wSRH200temp
			//move from temp wave to the supp raw header structure, then kill the wave 
			for (iRecord=0;iRecord<SRH.RecordLength_bytes;iRecord+=1)
				SRH.RecordWave[iRecord] = wSRH200temp[iRecord]
			endfor
			killwaves wSRH200temp
			//store that it was a area detector type supp header
			SRH.RecordType = DiffracPlus_SupRngHdrType
			return(0)
			break
		default:
			DoAlert/T="COMBIgor error!" 0,"Supplementary Range Header Type Not Recognized"
			return(-1)
			break
	endswitch		
End

//function to find the scan start position of a diffract plus raw file
Function DiffracPlus_ScanStart(RRH)
	Struct DiffracPlus_RawRngHdr &RRH

	switch(RRH.ScanType)// numeric switch
		case 0:		// Locked Coupled Mode
			DoAlert/T="COMBIgor error!" 0,"Locked Coupled Mode Not Supported Yet"
			return(-1)
			break
		case 1: 		// Unlocked Coupled Mode
			DoAlert/T="COMBIgor error!" 0,"Unlocked Coupled Mode Not Supported Yet"
			return(-1)
			break
		case 2:		// 2Theta Scan
			return(RRH.TwoThetaStart_deg)
			break
		case 3: 		// Omega Scan
			return(RRH.ThetaStart_deg)
			break
		case 4: 		// Chi Scan
			return(RRH.ChiStart_deg)
			break
		case 5:		// Phi Scan
			return(RRH.PhiStart_deg)
			break
		default:
			DoAlert/T="COMBIgor error!" 0,"Scan Type Not Recognized or Supported"
			return(-1)
			break
	endswitch		
End

//function to make panel
function Combi_BrukerXRD()
	Combi_GiveGlobal("sInstrumentName","BrukerXRD","COMBIgor")
	Combi_InstrumentDefinition()	
end

Function BrukerXRD_LoadBKG(ctrlName) : ButtonControl
	String ctrlName
	
	string sThisInstrumentName = "BrukerXRD"
	// get import path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	variable vRefNum
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Open/D/R/P=pUserPath/T=".raw" vRefNum as ""
	else
		Open/D/R/T=".raw" vRefNum as ""
	endif
	string sThisLoadFile = S_fileName //for storing source folder in data log
	if(strlen(sThisLoadFile)==0)
		//no file selected
		return -1
	endif
	variable vPathLength = itemsinlist(sThisLoadFile,":")
	String sFileName = stringfromlist(vPathLength-1,sThisLoadFile,":")
	string sFilePath = removeending(sThisLoadFile,sFileName)
	string sProject = Combi_GetInstrumentString(sThisInstrumentName,"sProject","COMBIgor")
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	string sLoadedWaveName=stringfromlist(0,BrukerXRD_DiffracPlusLoad(sFileName,sFilePath,1,""))
	wave wLoadedNew = $"root:"+sLoadedWaveName
	redimension/N=(-1,vTotalSamples) wLoadedNew
	wLoadedNew[][] = wLoadedNew[p][0]
	string sBackgroundsFolder = "root:COMBIgor:"+sProject+":BrukerXRD:Backgrounds:"
	string sWaveName
	prompt sWaveName, "Name for Background:"
	DoPrompt/HELP="This is the name assigned to this background scan." "What to call this?", sWaveName
	if (V_Flag)
		return -1// User canceled
	endif
	Rename wLoadedNew, $Cleanupname(sWaveName,0)
	MoveWave wLoadedNew,$sBackgroundsFolder
End

function BrukerXRD_Define()
	//get Instrument name
	string sThisInstrumentName = Combi_GetGlobalString("sInstrumentName", "COMBIgor")
	//get project to define
	string sProject = Combi_GetGlobalString("sInstrumentProject", "COMBIgor")
	//declare variables for each of the definition values
	string sIntensity
	string sDegree
	variable vWavelength
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",Combi_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		sIntensity = Combi_GetInstrumentString(sThisInstrumentName,"sIntensity",sProject)
		sDegree = Combi_GetInstrumentString(sThisInstrumentName,"sDegree",sProject)
		vWavelength = Combi_GetInstrumentNumber(sThisInstrumentName,"vWavelength",sProject)
	else 
		//not previously defined, start with default values 
		sIntensity = "XRD_RawIntensity"
		sDegree = "XRD_TwoTheta"
		vWavelength = 1.54
		Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)
	endif
	//sSignal
	sIntensity = cleanupname(Combi_DataTypePrompt(sProject,sIntensity,BrukerXRD_Descriptions("sIntensity"),0,1,0,2),0)
	if(stringmatch(sIntensity,"CANCEL"))
		return -1
	endif
	//sSignal
	sDegree = cleanupname(Combi_DataTypePrompt(sProject,sDegree,BrukerXRD_Descriptions("sDegree"),0,1,0,2),0)
	if(stringmatch(sDegree,"CANCEL"))
		return -1
	endif
	if(stringmatch(sDegree,"XRD_TwoTheta"))
		vWavelength = COMBI_NumberPrompt(vWavelength,"Radation Wavelength (Ang)","This will be used to calculate a Q vector","Radaiation wavelength:")
	endif
	if(numtype(vWavelength)!=0)
		return -1
	endif
	
	//store plot labels
	COMBIDisplay_Global(sDegree,"Diffraction Angle (degree)","Label")
	COMBIDisplay_Global(sIntensity,"Diffraction Intensity","Label")
	
	//store globals
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sIntensity",sIntensity,sProject)// store Instrument global 
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sDegree",sDegree,sProject)// store Instrument global 
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"vWavelength",num2str(vWavelength),sProject)
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,"COMBIgor")
	//reload definition panel and removal panel
	Combi_InstrumentDefinition()
	
end

function BrukerXRD_Load()
	Combi_InstrumentReady("BrukerXRD")
	string sProject = Combi_GetGlobalString("sInstrumentProject", "COMBIgor")
	Combi_GiveInstrumentGlobal("BrukerXRD","sProject",sProject,"COMBIgor")
	string sLoadType
	variable vWavelength = Combi_GetInstrumentNumber("BrukerXRD","vWavelength",sProject)
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sLoadType, "Load Type:", popup, "Folder;File"
	prompt vWavelength, "Radiation Wavelength (Angstroms):"
	DoPrompt/HELP="Select how to load data." "Loading Input", sLoadType, vWavelength
	if (V_Flag)
		return -1
	endif
	Combi_GiveInstrumentGlobal("BrukerXRD","vWavelength",num2str(vWavelength),sProject)
	if(stringmatch(sLoadType,"Folder"))
		// get globals
		string sDegree = Combi_GetInstrumentString("BrukerXRD","sDegree",sProject)
		string sIntensity = Combi_GetInstrumentString("BrukerXRD","sIntensity",sProject)		
		//call line
		if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
			Print "BrukerXRD_LoadFolder(\""+sProject+"\",\""+sIntensity+"\",\""+sDegree+"\")"
		endif
		BrukerXRD_LoadFolder(sProject,sIntensity,sDegree)
	elseif(stringmatch(sLoadType,"File"))
		BrukerXRD_LoadFile()
	endif
end

function/S BrukerXRD_Descriptions(sGlobalName)
	string sGlobalName
	string sInstrumentName = "BrukerXRD"
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:Combi_"+sInstrumentName+"_Globals"
	string sReturnstring = ""
	strswitch(sGlobalName)
		case "InInstrumentMenu":
			twGlobals[1][0] = "No"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "BrukerXRD":
			sReturnstring = "Bruker XRD"
			break
		case "sIntensity":
			sReturnstring = "Intensity data:"
			break
		case "sDegree":
			sReturnstring = "Angle data:"
			break
		case "vWavelength":
			sReturnstring = "Radiation Wavelength (Å):"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

Menu "COMBIgor"
	SubMenu "Instruments"
		SubMenu "Bruker x-ray diffraction"
			"(Loading diffracplus (.raw) files"
			"Load Folder",/Q, COMBI_BrukerXRDAccess()
			"Load Single",/Q, BrukerXRD_LoadFile()
			"-"
			"(Process"
			"Normalize",/Q, BrukerXRD_Normalize()
			"-"
			"(Plots"
			"Sample Gizmo",/Q, BrukerXRD_3DXRDPlot()
			"Sample Heat Map",/Q, BrukerXRD_HeatMapXRDPlot()
			"Traditional 2D",/Q,BrukerXRD_TraditionalXRDPlot()		
		end
	end
end

function COMBI_BrukerXRDAccess()
	COMBI_GiveGlobal("sInstrumentName","BrukerXRD","COMBIgor")
	COMBI_InstrumentDefinition()
end




function BrukerXRD_MakeA3DXRDPlotFromScaledWave(sProject,sLibrary,sVectorData,sScaleLabel,sZLabel)
	string sProject,sLibrary,sVectorData,sScaleLabel,sZLabel
	Killwindow/Z $sProject+sLibrary+sVectorData+"Gizmo"
	NewGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo"
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" stopUpdates
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" opName=rotatation, operation=rotate,data={40,0,0,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" opName=rotatation2, operation=rotate,data={-30,0,1,0}
	AppendToGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" DefaultSurface=$"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sVectorData,name=Data
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=Data,objectType=surface,property={surfaceCTab,VioletOrangeYellow}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 2,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 4,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 6,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 7,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 10,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 11,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 2,ticks,2}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelText,COMBIDisplay_GetAxisLabel("Sample")}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelText,sScaleLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelText,sZLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelText,sZLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" resumeUpdates
end

function BrukerXRD_3DXRDPlot()

	string sProject = COMBI_ChooseProject()
	if(stringmatch(sProject,""))
		return -1
	endif
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library of interest:",0,0,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	string sVectorData = COMBI_DataTypePrompt(sProject,"Select XRD Data","XRD Intensity data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sVectorData,"CANCEL"))
		return -1
	endif
	string sScaleLabel = COMBI_StringPrompt(COMBIDisplay_GetAxisLabel(Combi_GetInstrumentString("BrukerXRD","sDegree",sProject)),"Angle axis label:","","","Degree Axis Label")
	if(stringmatch(sScaleLabel,"CANCEL"))
		return -1
	endif
	string sZLabel = COMBI_StringPrompt(COMBIDisplay_GetAxisLabel(sVectorData),"Intensity axis label:","","","Plot Axis Label")
	if(stringmatch(sZLabel,"CANCEL"))
		return -1
	endif
	if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
		Print "BrukerXRD_MakeA3DXRDPlotFromScaledWave(\""+sProject+"\",\""+sLibrary+"\",\""+sVectorData+"\",\""+sScaleLabel+"\",\""+sZLabel+"\")"
	endif
	BrukerXRD_MakeA3DXRDPlotFromScaledWave(sProject,sLibrary,sVectorData,sScaleLabel,sZLabel)
end

function BrukerXRD_HeatMapXRDPlot()
	string sProject = COMBI_ChooseProject()
	if(stringmatch(sProject,""))
		return -1
	endif
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library of interest:",0,0,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	string sVectorData = COMBI_DataTypePrompt(sProject,"Select XRD Intensity Data","XRD Intensity data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sVectorData,"CANCEL"))
		return -1
	endif
	string sDegreeData = COMBI_DataTypePrompt(sProject,"Select XRD Degree Data","XRD Degree data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sDegreeData,"CANCEL"))
		return -1
	endif
	string sScaleLabel = COMBI_StringPrompt(COMBIDisplay_GetAxisLabel(sDegreeData),"Angle axis label:","","","Q Axis Label")
	if(stringmatch(sScaleLabel,"CANCEL"))
		return -1
	endif
	string sZLabel = COMBI_StringPrompt(COMBIDisplay_GetAxisLabel(sVectorData),"Intensity axis label:","","","Plot Axis Label")
	if(stringmatch(sZLabel,"CANCEL"))
		return -1
	endif
	if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
		Print "BrukerXRD_MakeXRDHeatMap(\""+sProject+"\",\""+sLibrary+"\",\""+sVectorData+"\",\""+sDegreeData+"\",\""+sScaleLabel+"\",\""+sZLabel+"\")"
	endif
	BrukerXRD_MakeXRDHeatMap(sProject,sLibrary,sVectorData,sDegreeData,sScaleLabel,sZLabel)
end

function BrukerXRD_MakeXRDHeatMap(sProject,sLibrary,sVectorData,sDegreeData,sScaleLabel,sZLabel)
	string sProject,sLibrary,sVectorData,sDegreeData,sScaleLabel,sZLabel
	//log?
	string sColorScale
	wave wIntData = $COMBI_DataPath(sProject,2)+sLibrary+":"+sVectorData
	variable vMedianInt = median(wIntData)
	variable vMax = wavemax(wIntData)
	variable vMin = wavemin(wIntData)
	if(vMedianInt<0)
		sColorScale = "Linear"
	else
		sColorScale = "Log"
	endif
	COMBIDisplay_Plot(sProject,"NewPlot","Vector",sLibrary,sDegreeData,"","Linear","Auto","Auto","Bottom","Scalar","FromMappingGrid","Sample","","Linear","Auto","Auto","Left","Vector",sLibrary,sVectorData,sColorScale,num2str(vMedianInt),num2str(vMax),"BlueHot256","","","","Linear","Auto","Auto",3,10,"All","All","All","All","All","All")
	ModifyGraph height={Aspect,1}
	ColorScale/C/N=zScaleLeg lblMargin=0
	ColorScale/C/N=zScaleLeg sZLabel
	ModifyGraph mirror=1,minor=1,btLen=3,stLen=1,gbRGB=(0,0,0)
	ColorScale/C/N=zScaleLeg/X=0.00/Y=5.00/E=2 heightPct=100
end

function BrukerXRD_TraditionalXRDPlot()
	string sProject = COMBI_ChooseProject()
	if(stringmatch(sProject,""))
		return -1
	endif
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library of interest:",0,0,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	string sVectorData = COMBI_DataTypePrompt(sProject,"Select XRD Intensity Data","XRD Intensity data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sVectorData,"CANCEL"))
		return -1
	endif
	string sDegreeData = COMBI_DataTypePrompt(sProject,"Select XRD Degree Data","XRD Degree data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sDegreeData,"CANCEL"))
		return -1
	endif
	string sScaleLabel = COMBI_StringPrompt(COMBIDisplay_GetAxisLabel(sDegreeData),"Angle axis label:","","","Q Axis Label")
	if(stringmatch(sScaleLabel,"CANCEL"))
		return -1
	endif
	string sZLabel = COMBI_StringPrompt(COMBIDisplay_GetAxisLabel(sVectorData),"Intensity axis label:","","","Plot Axis Label")
	if(stringmatch(sZLabel,"CANCEL"))
		return -1
	endif
	if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
		Print "BrukerXRD_MakeXRDTraditional(\""+sProject+"\",\""+sLibrary+"\",\""+sVectorData+"\",\""+sDegreeData+"\",\""+sScaleLabel+"\",\""+sZLabel+"\")"
	endif
	BrukerXRD_MakeXRDTraditional(sProject,sLibrary,sVectorData,sDegreeData,sScaleLabel,sZLabel)
end

function BrukerXRD_MakeXRDTraditional(sProject,sLibrary,sVectorData,sDegreeData,sScaleLabel,sZLabel)
	string sProject,sLibrary,sVectorData,sDegreeData,sScaleLabel,sZLabel
	wave wIntData = $COMBI_DataPath(sProject,2)+sLibrary+":"+sVectorData
	variable vMedianInt = median(wIntData)
	variable vMax = wavemax(wIntData)
	variable vMin = wavemin(wIntData)
	string sVerticalScale
	if(vMedianInt<0)
		sVerticalScale = "Linear"
	else
		sVerticalScale = "Log"
	endif
	COMBIDisplay_Plot(sProject,"NewPlot","Vector",sLibrary,sDegreeData,"","Linear","Auto","Auto","Bottom","Vector",sLibrary,sVectorData,"",sVerticalScale,num2str(vMedianInt),num2str(vMax),"Left","Scalar","FromMappingGrid","Sample","Linear","Auto","Auto","Rainbow","","","","Linear","Auto","Auto",0,10,"All","All","All","All","All","All")
	ModifyGraph mirror=1,minor=1,btLen=4,stLen=2
	Label left sZLabel
	Label bottom sScaleLabel
end

function BrukerXRD_Normalize()

	string sProject = COMBI_ChooseProject()
	if(stringmatch(sProject,""))
		return -1
	endif
	
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library of interest:",0,0,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	
	string sOption = COMBI_StringPrompt("Each Sample","Normalize per:","Library Max;Sample Max;Scalar Data;Library Data","Use the same max and min values for the entire library, or define per sample?","Max and min selection")
	if(stringmatch(sOption,"CANCEL"))
		return -1
	endif
	
	string sIntensityData = COMBI_DataTypePrompt(sProject,"Select XRD Intensity Data","XRD Intensity data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sIntensityData,"CANCEL"))
		return -1
	endif
	
	string sOtherData =""
	string sLabelPart =""
	if(stringmatch(sOption,"Scalar Data"))
		sOtherData = COMBI_DataTypePrompt(sProject,"Select Scalar Data","Normalization by:",0,0,0,1,sLibraries=sLibrary)
		sLabelPart = "per "+sOtherData
	elseif(stringmatch(sOption,"Library Data"))
		sOtherData= COMBI_DataTypePrompt(sProject,"Select Library Data","Normalization by:",0,0,0,0,sLibraries=sLibrary)
		sLabelPart = "per "+sOtherData
	else
		sLabelPart = "per "+sOption
	endif
	
	
	if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
		Print "BrukerXRD_NormalizeIntensity(\""+sProject+"\",\""+sLibrary+"\",\""+sIntensityData+"\",\""+sOtherData+"\",\""+sOption+"\")"
	endif
	BrukerXRD_NormalizeIntensity(sProject,sLibrary,sIntensityData,sOtherData,sOption)
	//if plot on loading
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		string sTheDegree = COMBI_DataTypePrompt(sProject,"Select XRD Degree Data","XRD Degree Data",0,0,0,2,sLibraries=sLibrary)
		if(stringmatch(sTheDegree,"CANCEL"))
			return -1
		endif
		string sNewWave = sIntensityData
		if(stringmatch(sOption,"Scalar Data")||stringmatch(sOption,"Library Data"))
			sNewWave += "_NormPer"+sOtherData
		else
			sNewWave += "_NormPer"+replacestring(" ",sOption,"")
		endif
		string sLable = "Normalized "+sIntensityData+" ["+sLabelPart+"]"
		BrukerXRD_MakeXRDHeatMap(sProject,sLibrary,sNewWave,sTheDegree,sTheDegree,sLable)
	endif	
	
end

function BrukerXRD_NormalizeIntensity(sProject,sLibrary,sVectorData,sOtherData,sOption)
	string sProject,sLibrary,sVectorData,sOtherData,sOption
	wave wVirgin = $COMBI_DataPath(sProject,2)+sLibrary+":"+sVectorData
	
	string sNewWave = sVectorData
	if(stringmatch(sOption,"Scalar Data")||stringmatch(sOption,"Library Data"))
		sNewWave += "_NormPer"+sOtherData
	else
		sNewWave += "_NormPer"+replacestring(" ",sOption,"")
	endif
	sNewWave = Combi_AddDataType(sProject,sLibrary,sNewWave,2,iVDim=dimsize(wVirgin,1))
	wave wNormed = $COMBI_DataPath(sProject,2)+sLibrary+":"+sNewWave
	int iSample
	variable vMin, vMax
	if(stringmatch(sOption,"Sample Max"))
		for(iSample=0;iSample<dimsize(wVirgin,0);iSample+=1)
			vMin = Combi_Extremes(sProject,2,sVectorData,sLibrary,num2str(iSample+1)+";"+num2str(iSample+1)+"; ; ; ; ","Min")
			vMax = Combi_Extremes(sProject,2,sVectorData,sLibrary,num2str(iSample+1)+";"+num2str(iSample+1)+"; ; ; ; ","Max")
			wNormed[iSample][] = (wVirgin[p][q]-vMin)/(vMax-vMin)
		endfor
	elseif(stringmatch(sOption,"Library Max"))
		vMin = Combi_Extremes(sProject,2,sVectorData,sLibrary,"All","Min")
		vMax = Combi_Extremes(sProject,2,sVectorData,sLibrary,"All","Max")
		wNormed[][] = (wVirgin[p][q]-vMin)/(vMax-vMin)
	elseif(stringmatch(sOption,"Scalar Data"))
		wave wOtherData = $COMBI_DataPath(sProject,1)+sLibrary+":"+sOtherData	
		wNormed[][] = wVirgin[p][q]/wOtherData[p]
	elseif(stringmatch(sOption,"Library Data"))
		wave wOtherData = $COMBI_DataPath(sProject,0)
		wNormed[][] = wVirgin[p][q]/wOtherData[%$sLibrary][%$sOtherData]
	endif
	
end