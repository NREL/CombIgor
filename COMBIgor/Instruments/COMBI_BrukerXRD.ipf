#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ September 2018 : Original
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging
// V2.01: KEvin Talley _ Dec 2109 : Added Frame loading handeling and transforamtion capabilities. 

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Instruments"
		SubMenu "Bruker x-ray diffraction"
			submenu "2D - diffracplus (.raw)"
				"(Loading"
				"Folder",/Q, COMBI_BrukerXRDAccess()
				"Single",/Q, BrukerXRD_LoadFile()
				"-"
				"(Process"
				"Normalize",/Q, BrukerXRD_Normalize()
				"-"
				"(Plots"
				"3D Sample Gizmo",/Q, BrukerXRD_3DXRDPlot()
				"3D Sample Heat Map",/Q, BrukerXRD_HeatMapXRDPlot()
				"Traditional 2D",/Q,BrukerXRD_TraditionalXRDPlot()	
				"-"
			end
			submenu "3D - frames (.gfrm)"
				"(Loading"
				"Folder",/Q, BrukerXRD_LoadAllFrames()
				"Single",/Q, BrukerXRD_LoadAFrame()
				"-"
				"(Plots"
				"A Sample",/Q, BrukerXRD_PlotAFrame()
				"A Library",/Q, BrukerXRD_PlotAllFrames()
				"-"
				"(Frame Plot additions"
				"Add Grid",/Q, BrukerXRD_AddGridToFrame()
				"Make 0 into NAN",/Q, BrukerXRD_ZeroToNan()
				"-"
				"(Transformation"
				"A Single Frame",/Q, BrukerXRD_TransformAFrame()
				"A Library",/Q, BrukerXRD_TransformFrames()
				"Plot Transforms",/Q, BrukerXRD_PlotTransformations()
				"-"
				"(Integration"
				"Integrate Library of Frames",/Q,BrukerXRD_IntegrateAllFrames()
			end
		end
	end
end

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
	sAllFiles = sortlist(sAllFiles,";",16)
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	string sFirstFile = removeending(stringfromlist(0,sAllFiles),".raw")
	string sLastFile = removeending(stringfromlist(vNumberOfFiles-1,sAllFiles),".raw")
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

function COMBI_BrukerXRDAccess()
	COMBI_GiveGlobal("sInstrumentName","BrukerXRD","COMBIgor")
	COMBI_InstrumentDefinition()
end

function BrukerXRD_MakeA3DXRDPlotFromScaledWave(sProject,sLibrary,sVectorData,sScaleLabel,sZLabel)
	string sProject,sLibrary,sVectorData,sScaleLabel,sZLabel
	Killwindow/Z $sProject+sLibrary+sVectorData+"Gizmo"
	NewGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo"
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" stopUpdates
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" opName=rotatation, operation=rotate,data={190,0,0,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" opName=rotatation2, operation=rotate,data={5,0,1,0}
	AppendToGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" DefaultSurface=$"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sVectorData,name=Data
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=Data,objectType=surface,property={surfaceCTab,VioletOrangeYellow}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 2,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 1,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 0,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 4,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 6,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 7,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 10,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 11,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelText,COMBIDisplay_GetAxisLabel("Sample")}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelText,sScaleLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelText,sZLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelText,sZLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={8,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={9,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={9,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={8,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelFont,"default"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelFlip,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,axisLabelFlip,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,labelBillboarding,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 8,labelBillboarding,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 3,labelBillboarding,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 5,labelBillboarding,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={ 9,axisColor,0.533333,0.533333,0.533333,1}
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

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Frame Handeling Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function BrukerXRD_LoadAFrame()
	//select frame file
	variable vRefNum
	Open/D/R/F="Frame Files (*.gfrm):.gfrm;" vRefNum as ""
	string sThisFrameFile = S_fileName
	int iDepth = itemsInList(sThisFrameFile,":")
	string sThisFileName  = stringfromList((iDepth-1),sThisFrameFile,":")
	string sThisFilePath = removeEnding(sThisFrameFile,sThisFileName)
	//call real load function
	string sFrameWave = BrukerXRD_LoadFrame(sThisFileName,sThisFilePath)
	string sCleanname = CleanupName(sFrameWave[5,strlen(sFrameWave)],0) 
	wave wFrameWave = $sFrameWave
	//plot the frame wave
	BrukerXRD_PlotFrame(wFrameWave,sCleanName)
end

function BrukerXRD_LoadAllFrames()
	string sThisInstrumentName = "BrukerXRD"
	
	// get project to load to
	string sProject, sFrameDataName="Bruker2DFrames"
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sFrameDataName, "Data Name:"
	string sThisHelp
	sThisHelp = "This is the project the matrix data will be stored in and the name it will be stored under."
	DoPrompt/HELP=sThisHelp "XRD Frame Files", sProject, sFrameDataName
	if (V_Flag)
		return -1// User canceled
	endif
	
	//wavelength for transform?
	//variable vWavelength = Combi_GetInstrumentNumber("BrukerXRD","vWavelength",sProject)
	//prompt vWavelength, "Radiation Wavelength (Angstroms):"
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	
	// get globals
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
		
	// get import folder path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O/M="Folder of *.gfrm files" pLoadPath
	else
		NewPath/Z/Q/O/M="Folder of *.gfrm files" pLoadPath
	endif
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	//get number of Libraries
	string sAllFiles = IndexedFile(pLoadPath,-1,".gfrm")
	sAllFiles = sortlist(sAllFiles,";",16)
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	string sFirstFile = removeending(stringfromlist(0,sAllFiles),".gfrm")
	string sLastFile = removeending(stringfromlist(vNumberOfFiles-1,sAllFiles),".gfrm")
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
	variable vNumberOfLibraries = 1
	prompt vNumberOfLibraries, "Number of libraries:"

	sThisHelp = "This helps me find all the files to load. The file name is constructed from the Prefix + (Index of set # of digits) + Suffix"
	DoPrompt/HELP=sThisHelp "XRD Files", sFilePrefix, sFileSufix, vIndexDigits, vNumberOfLibraries
	if (V_Flag)
		return -1// User canceled
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
		//initialize library
		COMBI_NewLibrary(sProject,cleanupname(stringfromlist(0,sLibraryDestinations),0))
		//for storing in data log
		sLibraries = AddListItem(cleanupname(stringfromlist(0,sLibraryDestinations),0),sLibraries,";",inf)
		sFirstSamples = AddListItem(stringfromlist(1,sLibraryDestinations),sFirstSamples,";",inf)
		sLastSamples = AddListItem(stringfromlist(2,sLibraryDestinations),sLastSamples,";",inf)
		sFirstIndexs = AddListItem(stringfromlist(3,sLibraryDestinations),sFirstIndexs,";",inf)
		sLastIndexs = AddListItem(stringfromlist(4,sLibraryDestinations),sLastIndexs,";",inf)
		
		//Load files to root:
		for(vIndex=str2num(stringfromlist(3,sLibraryDestinations));vIndex<=str2num(stringfromlist(4,sLibraryDestinations));vIndex+=1)
			int iCurrentSample = str2num(stringfromlist(1,sLibraryDestinations)) + (vIndex-str2num(stringfromlist(3,sLibraryDestinations)))//firstsample-(index-firstindex)
			COMBI_ProgressWindow("XRDFRAMELOADER","Library: "+cleanupname(stringfromlist(0,sLibraryDestinations),0),"Loading Frames",iCurrentSample+1,str2num(stringfromlist(2,sLibraryDestinations))+1)
			sThisFileName = sFilePrefix+Combi_PadIndex(vIndex+1,vIndexDigits)+sFileSufix+".gfrm"
			string sThisLoadedFrameWave = BrukerXRD_LoadFrame(sThisFileName,sThisLoadFolder)
			wave wFrameWave = $sThisLoadedFrameWave
			//make matrix wave of correct dimension
			if(vIndex==str2num(stringfromlist(3,sLibraryDestinations)))//first one loaded, make wave to hold all
				string sTheMatrixName = COMBI_AddDataType(sProject,cleanupname(stringfromlist(0,sLibraryDestinations),0),sFrameDataName,3) 
				wave wFrameMatrixData = $"root:COMBIgor:"+sProject+":Data:"+cleanupname(stringfromlist(0,sLibraryDestinations),0)+":"+sTheMatrixName
				redimension/N=(dimSize(wFrameWave,0),dimsize(wFrameWave,1),-1) wFrameMatrixData
				wFrameMatrixData = nan
				//add note
				Note/K wFrameMatrixData, Note(wFrameWave)
			endif
			//move to matrix wave
			wFrameMatrixData[][][iCurrentSample] = wFrameWave[p][q]
			killwaves wFrameWave
		endfor
	endfor
	
	//	//if plot on loading
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		//get data path to Intensity and set scale in column dim
		for(iLibrary=0;iLibrary<vNumberOfLibraries;iLibrary+=1)
			if(!stringmatch(stringfromlist(iLibrary,sLibraries),"Skip"))
				//plot
				BrukerXRD_PlotAllFrames(sProject=sProject,sLibrary=stringfromlist(iLibrary,sLibraries),sDataType=sTheMatrixName)
			endif	
		endfor
	endif
	
	//add to data log
	variable iDataType
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File Folder: "+sThisLoadFolder
	sLogEntry2 = "Library Samples: "+Replacestring(";",sFirstSamples,",")+" to "+Replacestring(";",sLastSamples,",")
	sLogEntry3 = "From File Indexes: "+Replacestring(";",sFirstIndexs,",")+" to "+Replacestring(";",sLastIndexs,",")
	sLogEntry4 = "Data Types: "+sTheMatrixName
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sLibraries,"BrukerXRD",1,sLogText)		
	
	//kill paths
	Killpath/A
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
end

function BrukerXRD_PlotAFrame([sProject,sLibrary,sDataType,iSample])
	string sProject,sLibrary,sDataType
	int iSample
	if(ParamIsDefault(sProject))
		sProject = COMBI_ChooseProject()
		if(stringmatch(sProject,""))
			return -1
		endif
	endif
	if(ParamIsDefault(sLibrary))
		sLibrary = COMBI_LibraryPrompt(sProject,";","Library to plot:",0,0,0,3)
		if(stringmatch(sLibrary,"CANCEL"))
			return -1
		endif
	endif
	if(ParamIsDefault(sDataType))
		sDataType = COMBI_DataTypePrompt(sProject,";","Frame data to plot:",0,0,0,3,sLibraries=sLibrary)
		if(stringmatch(sDataType,"CANCEL"))
			return -1
		endif
	endif
	if(ParamIsDefault(iSample))
		variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
		iSample = COMBI_NumberPrompt(1,"Sample to plot (1-"+num2str(vTotalSamples)+"):","Sample number (indexed to 1) from 1 to "+num2str(vTotalSamples),"Select a sample number")
		if(iSample<1||iSample>vTotalSamples)
			Doalert/T="Sample # out of range.", 0, "Sample number out of range, must be between 1 and "+num2str(vTotalSamples)+"!"
			return -1
		endif
		iSample=iSample-1
	endif
	//get wave
	wave wData2Plot = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType
	//check if transformed data
	string sTheWavesNote = note(wData2Plot)
	int bTransformed = 0;
	if(stringmatch("1",stringfromlist(0,sTheWavesNote)))
		bTransformed = 1
	endif
	
	//find the non-zero min
	variable vMinCount = inf
	int iRow,iCol
	for(iRow=0;iRow<dimsize(wData2Plot,0);iRow+=1)
		for(iCol=0;iCol<dimsize(wData2Plot,1);iCol+=1)
			if(wData2Plot[iRow][iCol][iSample]!=0&&numtype(wData2Plot[iRow][iCol][iSample])==0)
				vMinCount = min(vMinCount,wData2Plot[iRow][iCol][iSample])
			endif
		endfor
	endfor
	//plot
	string sFontChoice = COMBI_GetGlobalString("sFontOption","COMBIgor")
	string sCleanName = sProject+"_"+sLibrary+"_"+sDataType+"_S"+num2str(iSample+1)
	NewImage/K=1/N=$sCleanName wData2Plot
	string sGraphName = S_name
	string sImageName=stringfromlist(0,ImageNameList(sGraphName,";"))
	ModifyGraph/W=$sGraphName margin=30,width=300,height=300
	ModifyImage/W=$sGraphName $sImageName plane=iSample
	ModifyImage/W=$sGraphName $sImageName ctab= {vMinCount,*,YellowHot,0},log=1
	ModifyGraph/W=$sGraphName mirror=3,nticks=20,minor=0,fSize=12,noLabel=1,tkLblRot=0,tlOffset=0,font=sFontChoice
	ModifyGraph/W=$sGraphName margin(right)=100
	ColorScale/C/N=ScaleBar/F=0/B=3/M/A=RC/X=2.00/Y=0.00/E width=15,height=200,image=$sImageName,log=1,lblMargin=10,minor=1
	ModifyGraph axRGB=(65535,65535,65535,328),tlblRGB=(65535,65535,65535,328),alblRGB=(65535,65535,65535,328)
	ColorScale/C/N=ScaleBar "Intensity (counts/second)"
	
	//grid labels
	if(bTransformed==1)
		ModifyGraph grid=2,mirror(left)=1,noLabel=0,tkLblRot(left)=90,tlOffset(left)=-2,tlOffset(top)=-1,gridHair=0,axRGB=(0,0,0),tlblRGB=(0,0,0),alblRGB=(0,0,0),gridRGB=(1,12815,52428)
		ModifyGraph margin(left)=40,margin(top)=40
		Label left "χ (\\U)";DelayUpdate
		if(stringmatch("Q",stringfromlist(1,sTheWavesNote)))
			Label top "Scattering Vector Magnitude (\\U)"
		elseif(stringmatch("2Theta",stringfromlist(1,sTheWavesNote)))
			Label top "Diffraction Angle (\\U)"
		endif
	endif
	
end

//Large form figure of sample space (mm vs mm) with each sample as a 100pt by 100 pt XRD frame
function BrukerXRD_PlotAllFrames([sProject,sLibrary,sDataType])
	string sProject,sLibrary,sDataType
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	if(ParamIsDefault(sProject))
		sProject = COMBI_ChooseProject()
		if(stringmatch(sProject,""))
			return -1
		endif
	endif
	if(ParamIsDefault(sLibrary))
		sLibrary = COMBI_LibraryPrompt(sProject,";","Library to plot",0,0,0,3)
		if(stringmatch(sLibrary,"CANCEL"))
			return -1
		endif
	endif
	if(ParamIsDefault(sDataType))
		sDataType = COMBI_DataTypePrompt(sProject,";","Frame data to plot",0,0,0,3,sLibraries=sLibrary)
		if(stringmatch(sDataType,"CANCEL"))
			return -1
		endif
	endif
	
	//get waves
	wave wData2Plot = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	
	//get variables 
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	variable vLibraryWidth = Combi_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = Combi_GetGlobalNumber("vLibraryHeight",sProject)
	int bXAxisFlip = Combi_GetGlobalNumber("bXAxisFlip",sProject)
	int bYAxisFlip = Combi_GetGlobalNumber("bYAxisFlip",sProject)
	variable vMinX=0, vMinY=0, vMaxX=vLibraryWidth, vMaxY=vLibraryHeight
	if(bXAxisFlip)
		vMinX=vLibraryWidth
		vMaxX=0
	endif
	if(bYAxisFlip)
		vMinY=vLibraryHeight
		vMaxY=0
	endif
	//data info
	variable vMaxInt = wavemax(wData2Plot)
	variable vMinInt = inf
	//find the non-zero min
	int iRow,iCol,iSample
	for(iSample=0;iSample<dimsize(wData2Plot,2);iSample+=1)
		COMBI_ProgressWindow("XRDFramePlotAll","Working to plot","Plotting Frames",iSample+1,dimsize(wData2Plot,2))
		for(iCol=0;iCol<dimsize(wData2Plot,1);iCol+=1)
			for(iRow=0;iRow<dimsize(wData2Plot,0);iRow+=1)
				if(wData2Plot[iRow][iCol][iSample]!=0&&numtype(wData2Plot[iRow][iCol][iSample])==0)
					vMinInt = min(vMinInt,wData2Plot[iRow][iCol][iSample])
				endif
			endfor
		endfor
	endfor
	
	//make figure of sample space
	string sFontChoice = COMBI_GetGlobalString("sFontOption","COMBIgor")
	string sWinName = COMBI_NewPlot(sProject+"_"+sLibrary+"_"+sDataType+"_All")
	ModifyGraph/W=$sWinName margin=50,width=15*vLibraryWidth,height=15*vLibraryHeight
	AppendToGraph/W=$sWinName wMappingGrid[][2] vs wMappingGrid[][1]
	SetAxis/W=$sWinName left vMinY,vMaxY
	SetAxis/W=$sWinName bottom vMinX,vMaxX
	ModifyGraph/W=$sWinName mirror=3,nticks=10,minor=1
	Label/W=$sWinName left "Library dimension (mm)"
	Label/W=$sWinName bottom "Library dimension (mm)"
	ModifyGraph/W=$sWinName hideTrace=1
	//for hooknig to kill scale waves
	SetWindow $sWinName userdata(ScaleSource)= "root:Packages:COMBIgor:DisplayWaves:BrukerXRDFrames:"+sLibrary+":"+sDataType
	SetWindow $sWinName hook(kill)=BrukerXRD_KillScaleWaves
	
	//make X and y plotting waves
	variable vRowSpacing = Combi_GetGlobalNumber("vRowSpacing",sProject)
	variable vColumnSpacing = Combi_GetGlobalNumber("vColumnSpacing",sProject)
	if(numtype(vRowSpacing)==2)
		vRowSpacing = 2
	endif
	if(numtype(vColumnSpacing)==2)
		vColumnSpacing = 2
	endif
	variable vFrameSize = Min(vColumnSpacing,vRowSpacing)
	int XframeDim = dimsize(wData2Plot,0)
	int YframeDim = dimsize(wData2Plot,1)
	setdatafolder "root:Packages:COMBIgor:"
	newdatafolder/O/S DisplayWaves
	newdatafolder/O/S BrukerXRDFrames
	newdatafolder/O/S $sLibrary
	newdatafolder/O/S $sDataType
	setdatafolder root:
	
	variable vFrameLeft
	variable vFrameRight
	variable vFrameTop
	variable vFrameBottom
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		//new x and y wave
		Make/O/N=(XframeDim+1) $"root:Packages:COMBIgor:DisplayWaves:BrukerXRDFrames:"+sLibrary+":"+sDataType+":XScale_S"+num2str(iSample+1)
		Make/O/N=(YframeDim+1) $"root:Packages:COMBIgor:DisplayWaves:BrukerXRDFrames:"+sLibrary+":"+sDataType+":YScale_S"+num2str(iSample+1)
		wave wXScale = $"root:Packages:COMBIgor:DisplayWaves:BrukerXRDFrames:"+sLibrary+":"+sDataType+":XScale_S"+num2str(iSample+1)
		wave wYScale = $"root:Packages:COMBIgor:DisplayWaves:BrukerXRDFrames:"+sLibrary+":"+sDataType+":YScale_S"+num2str(iSample+1)
		//calc frame position
		variable vFrameCenterX = wMappingGrid[iSample][1]
		variable vFrameCenterY = wMappingGrid[iSample][2]
		if(bXAxisFlip) //0 on right
			vFrameLeft = vFrameCenterX+vFrameSize/2
			vFrameRight = vFrameCenterX-vFrameSize/2
			wXScale[] = vFrameLeft-(p*vFrameSize/XframeDim)
		else //0 on left
			vFrameLeft = vFrameCenterX-vFrameSize/2
			vFrameRight = vFrameCenterX+vFrameSize/2
			wXScale[] = vFrameLeft+(p*vFrameSize/XframeDim)
		endif
		if(bYAxisFlip) //0 on top
			vFrameTop = vFrameCenterY-vFrameSize/2
			vFrameBottom = vFrameCenterY+vFrameSize/2
			wYScale[] = vFrameTop+(p*vFrameSize/YframeDim)
		else //0 on bottom
			vFrameTop = vFrameCenterY+vFrameSize/2
			vFrameBottom = vFrameCenterY-vFrameSize/2
			wYScale[] = vFrameTop-(p*vFrameSize/YframeDim)
		endif
		
		AppendImage/G=1/W=$sWinName wData2Plot vs {wXScale,wYScale}
		string sImageName=stringfromlist(iSample,ImageNameList(sWinName,";"))
		ModifyImage $sImageName plane=iSample,ctab= {vMinInt,vMaxInt,YellowHot256,0},log=1
	endfor
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
end

function BrukerXRD_PlotFrame(wFrameWave,sCleanName)
	wave wFrameWave
	string sCleanName
	//find the non-zero min
	variable vMinCount = inf
	int iRow,iCol
	for(iRow=0;iRow<dimsize(wFrameWave,0);iRow+=1)
		for(iCol=0;iCol<dimsize(wFrameWave,1);iCol+=1)
			if(wFrameWave[iRow][iCol]!=0&&numtype(wFrameWave[iRow][iCol])==0)
				vMinCount = min(vMinCount,wFrameWave[iRow][iCol])
			endif
		endfor
	endfor
	string sFontChoice = COMBI_GetGlobalString("sFontOption","COMBIgor")
	NewImage/K=1/N=$sCleanName wFrameWave
	string sGraphName = S_name
	string sImageName=stringfromlist(0,ImageNameList(sGraphName,";"))
	ModifyGraph/W=$sGraphName margin=30,width=300,height=300
	ModifyImage/W=$sGraphName $sImageName ctab= {vMinCount,*,YellowHot,0},log=1
	ModifyGraph/W=$sGraphName mirror=3,nticks=20,minor=0,fSize=12,noLabel=1,tkLblRot=0,tlOffset=0,font=sFontChoice
	ModifyGraph/W=$sGraphName margin(right)=100
	ColorScale/C/N=ScaleBar/F=0/B=3/M/A=RC/X=2.00/Y=0.00/E width=15,height=200,image=$sImageName,log=1,lblMargin=10,minor=1
	ModifyGraph axRGB=(65535,65535,65535,328),tlblRGB=(65535,65535,65535,328),alblRGB=(65535,65535,65535,328)
	ColorScale/C/N=ScaleBar "Intensity (counts/second)"
end

//for killing scale waves upon closing
Function BrukerXRD_KillScaleWaves(s)
	STRUCT WMWinHookStruct &s
	if(s.eventCode==2)//window being killed
		string sWindowName = s.winName
		string sDataWaveName = GetUserData(sWindowName, "", "ScaleSource")
		int iAllImages = itemsinlist(ImageNameList(sWindowName,";"))
		int iImage
		For(iImage=0;iImage<iAllImages;iImage+=1)
			string sThisImage = stringFromList(0,ImageNameList(sWindowName,";"))
			RemoveImage/W=$sWindowName $sThisImage
		endfor
		KillDataFolder/Z $sDataWaveName
	endif
End

Function/S BrukerXRD_LoadFrame(sFrameFileName,sFrameFilePath)
	string sFrameFileName,sFrameFilePath
	
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//needed strucutres 
	STRUCT BrukerXRD_GFRMHeader sGFRM
	STRUCT BrukerXRD_OverFlowEntry	sOvrFlow
	//needed variables
	Variable vBrukerRows, vBrukerCols, vBytesPerPix, vFrameStartByte, vOverFlows, vOverFlowVal, vOffset, vCheckOverFlow
	//needed strings 
	String sOverFlowTest, nRealXRD_Wave, sFileName, sWaveName, sFrameHeaderStruct, gName
	
	//problem free name
	string sCleanName = cleanupName(removeending(sFrameFileName,".gfrm"),0)
	
	//open frame file to read 
	variable vRefNum
	string sFile = sFrameFilePath+sFrameFileName
	open/R vRefNum as sFile
	if(strlen(S_fileName)==0)//file and path are no good and user cancled rather than picing the file
		return ""
	endif
	BrukerXRD_BuildGFRMHeaderStruct(vRefNum,sGFRM)//build structure
	
	//read from structure
	vBrukerRows = sGFRM.NumRows
	vBrukerCols = sGFRM.NumCols
	vBytesPerPix = sGFRM.BytesPerPixel
	
	//set path for new waves
	string sDestinationWavePath = "root:"
	
	//make wave to hold frame data
	string sNewWave = sDestinationWavePath+sCleanName
	switch(vBytesPerPix)	// numeric switch
		case 1:		
			Make/B/U/O/N=(vBrukerCols,vBrukerRows) $sNewWave+"_Temp"
			vOverFlowVal = 255
			break
		case 2:		
			Make/W/U/O/N=(vBrukerCols,vBrukerRows) $sNewWave+"_Temp"
			vOverFlowVal = 65535
			break
		case 4:		
			Make/I/U/O/N=(vBrukerCols,vBrukerRows) $sNewWave+"_Temp"
		default:		
			Print "Unexpected BytesPerPix setting.  Expect 1,2 or 4"
	endswitch
	Wave wXRDTempFrame = $sNewWave+"_Temp"

	//read frame data
	vFrameStartByte = 512*sGFRM.HeaderBlocks
	BrukerXRD_SetFrameFileByte(vRefNum,vFrameStartByte)
	FBinRead/B=3 vRefNum, wXRDTempFrame
	
	//deal with overflow pixels and populate wave to keep
	vOverFlows = sGFRM.NumOverFlow
	make/N=(vOverFlows,2)/O $sNewWave+"_Overflow"
	make/N=(vBrukerCols,vBrukerRows)/O $sNewWave
	Wave wXRDFrameOverflow = $sNewWave+"_Overflow"
	Wave wXRDFrame = $sNewWave
	wXRDFrame = wXRDTempFrame
	int iOver
	for(iOver=0;iOver<vOverFlows;iOver+=1)
		FBinRead/B=3 vRefNum, sOvrFlow
		wXRDFrameOverflow[iOver][0] = round(str2num(sOvrFlow.Offset))
		wXRDFrameOverflow[iOver][1] = str2num(sOvrFlow.Value)
	endfor
	int iRow=0,iCol=0
	for(iRow=0;iRow<vBrukerRows;iRow+=1)// Bruker Rows
		for (iCol=0;iCol<vBrukerCols;iCol+=1)//Bruker Cols
			if (wXRDTempFrame[iRow][iCol]==vOverFlowVal)
				vOffset = iCol*vBrukerCols+iCol
				vCheckOverFlow = BrukerXRD_CheckOverFlowTable(vOffset,vOverFlows,wXRDFrameOverflow)
				if(vCheckOverFlow!=-1)
					wXRDFrame[iRow][iCol] = wXRDFrameOverflow[vCheckOverFlow][1]
				Endif
			EndIf
		EndFor
	EndFor
	
	//normalize by collection time
	int iMEasureTime = sGFRM.Cumulat
	//print "Frame collected for "+num2str(iMEasureTime)+" seconds."
	wXRDFrame[][] = wXRDFrame[p][q]/iMEasureTime
	
	//close file
	close vRefNum
	
	//kill temp waves
	killwaves wXRDFrameOverflow,wXRDTempFrame
	
	//remove 0 int values from around dectector image, but not from inside the cicle
	int iPixRadius = max(vBrukerCols,vBrukerRows)/2
	for(iRow=0;iRow<vBrukerRows;iRow+=1)// Bruker Rows
		for (iCol=0;iCol<vBrukerCols;iCol+=1)//Bruker Cols
			if(sqrt((vBrukerRows/2-iRow)^2+(vBrukerCols/2-iCol)^2)<iPixRadius)
				continue
			endif
			if(wXRDFrame[iRow][iCol]==0)
				wXRDFrame[iRow][iCol] = nan
			endif
		EndFor
	EndFor
	
	//add frame header strucutre to the wave note
	StructPut/S sGFRM, sFrameHeaderStruct
	Note wXRDFrame, sFrameHeaderStruct
	
	setdatafolder $sTheCurrentUserFolder 
	
	return sNewWave
	
end


function BrukerXRD_IntegrateAllFrames([sProject,sLibrary,sDataType,vHStart,vHEnd,vVStart,vVEnd])
	string sProject,sLibrary,sDataType
	variable vHStart,vHEnd,vVStart,vVEnd
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	if(ParamIsDefault(sProject))
		sProject = COMBI_ChooseProject()
		if(stringmatch(sProject,""))
			return -1
		endif
	endif
	if(ParamIsDefault(sLibrary))
		sLibrary = COMBI_LibraryPrompt(sProject,";","Library to plot",0,0,0,3)
		if(stringmatch(sLibrary,"CANCEL"))
			return -1
		endif
	endif
	if(ParamIsDefault(sDataType))
		sDataType = COMBI_DataTypePrompt(sProject,";","Frame data to plot",0,0,0,3,sLibraries=sLibrary)
		if(stringmatch(sDataType,"CANCEL"))
			return -1
		endif
	endif
	//get waves
	wave wData2Plot = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType
	string sWaveNote = note(wData2Plot)
	if(!stringmatch(stringfromlist(0,sWaveNote),"1"))
		DoAlert/T="Not Transformed Data", 0, "Please select transformed data! This data is not transformed matrix data."
		return -1
	endif
	//axis name and integration choice	
	string sAxisType = stringfromlist(1,sWaveNote)
	string sHorizontalTag = ""
	if(stringmatch("2Theta",sAxisType))
		sHorizontalTag = "Diffraction Angle (2Theta)"
	elseif(stringmatch("Q",sAxisType))
		sHorizontalTag = "Scattering Vector Magnitude (Q)"
	endif
	//get integration limits	
	if(ParamIsDefault(vHStart)||ParamIsDefault(vHEnd)||ParamIsDefault(vVStart)||ParamIsDefault(vVEnd))
		BrukerXRD_SelectIntegrationRegion(sProject,sLibrary,sDataType)
	else
		SVAR/Z sVDataName=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:sVDataName
		SVAR/Z sHDataName=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:sHDataName
		NVAR/Z bIntVert=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:bIntVert
		NVAR/Z bIntHor=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:bIntHor
		wave/Z wIntLimits = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:IntegrationLimits
		if(NVAR_Exists(bIntHor)&&NVAR_Exists(bIntVert)&&SVAR_Exists(sVDataName)&&SVAR_Exists(sHDataName)&&WaveExists(wIntLimits))
			BrukerXRD_SelectIntegrationRegion(sProject,sLibrary,sDataType)
		else
			int bDoHor = bIntHor
			int bDoVert = bIntVert
			string sVertName = sVDataName
			string sHorName = sHDataName
			BrukerXRD_DoIntegration(sProject,sLibrary,sDataType,vHStart,vHEnd,vVStart,vVEnd,bDoHor,bDoVert,sVertName,sHorName)
			Print "BrukerXRD_DoIntegration(\""+sProject+"\",\""+sLibrary+"\",\""+sDataType+"\","+Num2str(vHStart)+","+Num2str(vHEnd)+","+Num2str(vVStart)+","+Num2str(vVEnd)+","+Num2str(bDoHor)+","+Num2str(bDoVert)+",\""+sVertName+"\",\""+sHorName+")"
		endif
	endif

	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
end

//functions for making integration sleection window
function/S BrukerXRD_SelectIntegrationRegion(sProject,sLibrary,sDataType)
	string sProject,sLibrary,sDataType
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	string sFont = Combi_GetGlobalString("sFontOption","COMBIgor")
	wave wFrames2Plot = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType
	int iSample2Use = COMBI_NumberPrompt(1,"Sample to see:(1-"+num2str(vTotalSamples)+")","This sample will be plotted so you can select integration limits on it.","Select sample:")-1
	if(numtype(iSample2Use)==2)
		return ""
	endif
	//plot the transformed frame
	BrukerXRD_PlotAFrame(sProject=sProject,sLibrary=sLibrary,sDataType=sDataType,iSample=iSample2Use)
	ModifyGraph grid=0
	string sPlotName = stringfromlist(0,WinList("*",";","WIN:1"))
	//axis name and integration choice
	string sWaveNote = note(wFrames2Plot)	
	string sAxisType = stringfromlist(1,sWaveNote)
	string sHorizontalTag = ""
	if(stringmatch("2Theta",sAxisType))
		sHorizontalTag = "Diffraction Angle (2Theta)"
	elseif(stringmatch("Q",sAxisType))
		sHorizontalTag = "Scattering Vector Magnitude (Q)"
	endif 
	//wave limits
	variable vHMin = indexToScale(wFrames2Plot,0,0)
	variable vHMax= indexToScale(wFrames2Plot,(dimsize(wFrames2Plot,0)-1),0)
	variable vVMin = indexToScale(wFrames2Plot,0,1)
	variable vVMax = indexToScale(wFrames2Plot,(dimsize(wFrames2Plot,1)-1),1)
	//data transferwave
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root:Packages:COMBIgor:Instruments:
	newdatafolder/O/S BrukerXRDFrames
	if(!waveExists(root:Packages:COMBIgor:Instruments:BrukerXRDFrames:IntegrationLimits))
		Make/N=(4,2)/O IntegrationLimits
		wave wIntLimits = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:IntegrationLimits
		wIntLimits[0][0] = ceil(vVMin)
		wIntLimits[1][0] = floor(vVMax)
		wIntLimits[2][0] = ceil(vHMin)
		wIntLimits[3][0] = floor(vHMax)
	else
		wave wIntLimits = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:IntegrationLimits
	endif
	note/K wIntLimits, sPlotName+";"+"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType+";"+sProject+";"+sLibrary+";"+sDataType
	NVAR/Z bIntHor
	NVAR/Z bIntVert
	if(!NVAR_Exists(bIntHor))
		variable/G bIntHor = 0
		variable/G bIntVert = 0
		NVAR/Z bIntHor
		NVAR/Z bIntVert
	endif
	SVAR/Z sVDataName
	SVAR/Z sHDataName
	if(!SVAR_Exists(sVDataName))
		string/G sVDataName = sDataType+"_ChiSum"
		string/G sHDataName = sDataType+"_"+sAxisType+"Sum"
		SVAR/Z sVDataName
		SVAR/Z sHDataName
	endif
	SetDataFolder $sTheCurrentUserFolder
	//add to graph
	SetDrawEnv/W=$sPlotName xcoord= top,ycoord= left,linefgc= (0,0,65535),dash= 2,fillpat= 0,linethick= 2.00, save
	SetDrawEnv/W=$sPlotName gname=IntRegion,gstart
	DrawRect/W=$sPlotName wIntLimits[2][0],wIntLimits[1][0],wIntLimits[3][0],wIntLimits[0][0]
	SetDrawEnv/W=$sPlotName gstop
	//append a panel
	variable vPanelWidth = 300
	variable vPanelHeight = 280
	variable vCurrentY = 0
	string sWindowName = "LimitsSelector"
	NewPanel/K=(1)/W=(5,5,5+vPanelWidth,5+vPanelHeight)/HOST=$sPlotName/EXT=0/N=$sWindowName as "Integration Limit Selector"
	//draw int region on plot
	SetDrawLayer/W=$sWindowName UserBack
	SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 1,textyjust = 1, fsize = 12, save
	SetDrawEnv/W=$sWindowName fstyle=1
	DrawText/W=$sWindowName vPanelWidth/2,vCurrentY+10, "Integration Limits:"
	vCurrentY+=20
	SetVariable SetVMin title="Chi Min:",pos={10,vCurrentY},size={280,20},styledText=1,value=wIntLimits[0][0],limits={vVMin,vVMax,1},font=sFont,fSize=12,proc=BrukerXRD_UpdateIntWindow
	vCurrentY+=20
	SetVariable SetVMax title="Chi Max:",pos={10,vCurrentY},size={280,20},styledText=1,value=wIntLimits[1][0],limits={vVMin,vVMax,1},font=sFont,fSize=12,proc=BrukerXRD_UpdateIntWindow
	vCurrentY+=20
	SetVariable SetHMin title=sAxisType+" Min:",pos={10,vCurrentY},size={280,20},styledText=1,value=wIntLimits[2][0],limits={vHMin,vHMax,1},font=sFont,fSize=12,proc=BrukerXRD_UpdateIntWindow
	vCurrentY+=20
	SetVariable SetHMax title=sAxisType+" Max:",pos={10,vCurrentY},size={280,20},styledText=1,value=wIntLimits[3][0],limits={vHMin,vHMax,1},font=sFont,fSize=12,proc=BrukerXRD_UpdateIntWindow
	vCurrentY+=30
	//integration controls
	SetDrawEnv/W=$sWindowName fstyle=1
	DrawText/W=$sWindowName vPanelWidth/2,vCurrentY+10, "Desired Integrations:"
	vCurrentY+=20
	CheckBox IntH title="Do "+sAxisType+" Integration",pos={10,vCurrentY},font=sFont,fSize=12,variable=bIntHor
	vCurrentY+=20
	SetVariable SetHDataName title="Name:",pos={10,vCurrentY},size={280,20},styledText=1,value=sHDataName,font=sFont,fSize=12
	vCurrentY+=20
	CheckBox IntV title="Do Chi Integration",pos={10,vCurrentY},font=sFont,fSize=12,variable=bIntVert
	vCurrentY+=20
	SetVariable SetVDataName title="Name:",pos={10,vCurrentY},size={280,20},styledText=1,value=sVDataName,font=sFont,fSize=12
	vCurrentY+=30
	//perform integration
	SetDrawEnv/W=$sWindowName fstyle=1
	DrawText/W=$sWindowName vPanelWidth/2,vCurrentY+10, "Perform Integration"
	vCurrentY+=20
	Button DoIntegrations title="Integrate Data",pos={60,vCurrentY},size={200,40},fSize=12,font=sFont,fColor=(0,65535,0),proc=BrukerXRD_DoIntegrationButton
 
end

function BrukerXRD_DoIntegration(sProject,sLibrary,sDataType,vHStart,vHEnd,vVStart,vVEnd,bDoHor,bDoVert,sVertName,sHorName)
	string sProject,sLibrary,sDataType,sVertName,sHorName
	variable vHStart,vHEnd,vVStart,vVEnd,bDoHor,bDoVert
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	wave wTransformedData = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType
	variable vHorStep = DimDelta(wTransformedData,0)
	variable vVertStep = DimDelta(wTransformedData,1)
	int iRMin = ScaleToIndex(wTransformedData,vHStart,0)
	int iRMax = ScaleToIndex(wTransformedData,vHEnd,0)
	int iCMin = ScaleToIndex(wTransformedData,vVStart,1)
	int iCMax = ScaleToIndex(wTransformedData,vVEnd,1)
	int iR,iC, iThisH, iThisV, iP
	//Horizontal int (Chi)
	if(bDoHor==1)
		string sHorDataType = Combi_AddDataType(sProject,sLibrary,sHorName+"_Intensity",2)
		string sHorDataTypeDeg = Combi_AddDataType(sProject,sLibrary,sHorName+"_Chi",2)
		wave wHorIntData = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sHorDataType
		wave wHorIntDataDeg = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sHorDataTypeDeg
		redimension/N=(-1,((vVEnd-vVStart)/vVertStep+1)) wHorIntData
		redimension/N=(-1,((vVEnd-vVStart)/vVertStep+1)) wHorIntDataDeg
		setscale/I y,vVStart,vVEnd,wHorIntData
		setscale/I y,vVStart,vVEnd,wHorIntDataDeg
		wHorIntData[][] = nan
		wHorIntDataDeg[][] = vVStart+(q*vVertStep)
		for(iR=iRMin;iR<=iRMax;iR+=1)
			for(iC=iCMin;iC<=iCMax;iC+=1)
				for(iP=0;iP<vTotalSamples;iP+=1)
					iThisV = ScaleToIndex(wHorIntData,IndexToScale(wTransformedData,iC,1),1)
					if(numtype(wTransformedData[iR][iC][iP])==0)
						if(numtype(wHorIntData[iP][iThisV])==2)
							wHorIntData[iP][iThisV] = 0
						endif
						wHorIntData[iP][iThisV]+=wTransformedData[iR][iC][iP]
					endif
				endfor
			endfor
		endfor
	endif
	//Vertical in (2Theta)
	if(bDoVert==1)
		string sVertDataType = Combi_AddDataType(sProject,sLibrary,sVertName+"_Intensity",2)
		string sVertDataTypeDeg = Combi_AddDataType(sProject,sLibrary,sVertName+"_Degree",2)
		wave wVertIntData = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sVertDataType
		wave wVertIntDataDeg = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sVertDataTypeDeg
		redimension/N=(-1,((vHEnd-vHStart)/vHorStep+1)) wVertIntData
		setscale/I y,vHStart,vHEnd,wVertIntData
		redimension/N=(-1,((vHEnd-vHStart)/vHorStep+1)) wVertIntDataDeg
		setscale/I y,vHStart,vHEnd,wVertIntDataDeg
		wVertIntData[][]=nan
		wVertIntDataDeg[][] = vHStart+(q*vHorStep)
		for(iR=iRMin;iR<=iRMax;iR+=1)
			for(iC=iCMin;iC<=iCMax;iC+=1)
				for(iP=0;iP<vTotalSamples;iP+=1)
					iThisH = ScaleToIndex(wVertIntData,IndexToScale(wTransformedData,iR,0),1)
					if(numtype(wTransformedData[iR][iC][iP])==0)
						if(numtype(wVertIntData[iP][iThisH])==2)
							wVertIntData[iP][iThisH] = 0
						endif
						wVertIntData[iP][iThisH]+=wTransformedData[iR][iC][iP]
					endif
				endfor
			endfor
		endfor
	endif
end

Function BrukerXRD_DoIntegrationButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//do the wave integrations
			wave wIntLimits = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:IntegrationLimits
			string sPlotName = stringfromlist(0,note(wIntLimits))
			wave wFrameWave = $stringfromlist(1,note(wIntLimits))
			SVAR sVDataName=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:sVDataName
			SVAR sHDataName=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:sHDataName
			NVAR bIntVert=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:bIntVert
			NVAR bIntHor=root:Packages:COMBIgor:Instruments:BrukerXRDFrames:bIntHor
			//pass integrations
			variable vHStart = wIntLimits[2][0]
			variable vHEnd = wIntLimits[3][0]
			variable vVStart = wIntLimits[0][0]
			variable vVEnd = wIntLimits[1][0]
			variable bDoHor = bIntHor
			variable bDoVert = bIntVert
			string sVertName = sVDataName
			string sHorName = sHDataName
			string sProject = stringfromlist(2,note(wIntLimits))
			string sLibrary = stringfromlist(3,note(wIntLimits))
			string sDataType = stringfromlist(4,note(wIntLimits))
			BrukerXRD_DoIntegration(sProject,sLibrary,sDataType,vHStart,vHEnd,vVStart,vVEnd,bDoHor,bDoVert,sVertName,sHorName)
			//kill integration definition window
			killwindow $sPlotName
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function BrukerXRD_UpdateIntWindow(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			wave wIntLimits = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:IntegrationLimits
			string sWaveNote = stringfromlist(0,note(wIntLimits))
			//delete old
			SetDrawEnv/W=$sWaveNote xcoord= top,ycoord= left,linefgc= (0,0,65535),dash= 2,fillpat= 0,linethick= 2.00, save
			DrawAction/W=$sWaveNote getgroup=IntRegion,delete
			//add new
			SetDrawEnv/W=$sWaveNote gname=IntRegion,gstart
			DrawRect/W=$sWaveNote wIntLimits[2][0],wIntLimits[1][0],wIntLimits[3][0],wIntLimits[0][0]
			SetDrawEnv/W=$sWaveNote gstop
			//update index vlaues
			wave wFrameWave = $stringfromlist(1,note(wIntLimits))
			wIntLimits[0][1] = scaletoindex(wFrameWave,wIntLimits[0][0],1)
			wIntLimits[1][1] = scaletoindex(wFrameWave,wIntLimits[1][0],1)
			wIntLimits[2][1] = scaletoindex(wFrameWave,wIntLimits[2][0],0)
			wIntLimits[3][1] = scaletoindex(wFrameWave,wIntLimits[3][0],0)
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//for checking the overflow wave
Function BrukerXRD_CheckOverFlowTable( Offset, nOverFlows, wOverFlowTable)
	Variable Offset
	Variable nOverFlows
	Wave wOverFlowTable
	Variable  ii
	for (ii = 0 ; ii < nOverFlows; ii  += 1)
		if (Offset == wOverFlowTable[ii][0])
	 		return(ii)
	 	endif
	 EndFor
	return(-1)
End

//set the destination byte for frame data loading
Function BrukerXRD_SetFrameFileByte(vFileRef,vDestByte)
	variable vFileRef,vDestByte
	FSetPos vFileRef,vDestByte
end

//for data strings in structures
Function/S BrukerXRD_DataStr2List(DataStr)
	String DataStr
	String , liststring, itemstring
	variable p1, p2, ii, nchar
	liststring = ""
	p1 = 0
	ii = 0
	nchar = strlen(DataStr)
	do
		p1 = BrukerXRD_NextNonWhiteSpace(p1, datastr)
		if (p1 == nchar)
			return(liststring)
		else
			p2 = BrukerXRD_NextWhiteSpace(p1, DataStr) - 1
			itemstring = DataStr[p1,p2]
			liststring = AddListItem(itemstring, liststring, ";", inf)
			p1 = p2+1
		endif
	while(1)
End

//for data strings in structures
Function/S BrukerXRD_Get80CharLine(gBrukerFrameFile)
	Variable gBrukerFrameFile
	string string80
	FReadLine /N=80 gBrukerFrameFile, string80
	return(string80)
End

//for data strings in structures
function BrukerXRD_IsWhiteSpace( TestChar )
	string TestChar
	variable SearchResult
	string WhiteSpace = " \t:"
	TestChar = TestChar[0]
	SearchResult = strsearch(WhiteSpace,TestChar,0)
	If (SearchResult == -1)
		return (0)
	else
		return(1)
	endif
end

//for data strings in structures
function BrukerXRD_NullString( TestString )
	string TestString
	return ( abs(!cmpstr(TestString, "")) )
end

//for data strings in structures
function/S BrukerXRD_ReverseString( InputString )
	string InputString
	string OutputString = ""
	variable LastChar, ii
	LastChar = strlen(InputString) - 1
	ii = 0
	do 
		OutputString[ii] = InputString[LastChar-ii]
		ii += 1
	while( ii <= LastChar )
	return(OutputString)
end

//for data strings in structures
function BrukerXRD_NextNonWhiteSpace(StartPtr, InputString)
	variable StartPtr
	string InputString
	variable ii
	ii = StartPtr
	if  (!BrukerXRD_IsWhiteSpace(InputString[ii]))
		return(ii)
	endif
	do
		ii +=1
		if (BrukerXRD_NullString(InputString[ii]))
			return(ii)
		endif
	while (BrukerXRD_IsWhiteSpace(InputString[ii]))
	return(ii)
end

//for data strings in structures
function BrukerXRD_NextWhiteSpace(StartPtr, InputString)
	variable StartPtr
	string InputString
	variable ii
	ii = StartPtr
	if (BrukerXRD_NullString(InputString[ii]))
		return(ii)
	endif
	if  (BrukerXRD_IsWhiteSpace(InputString[ii]))
		return(ii)
	endif
	do
		ii +=1
		if (BrukerXRD_NullString(InputString[ii]))
			return(ii)
		endif
	while (!BrukerXRD_IsWhiteSpace(InputString[ii]))
	return(ii)
end

// Extracting integers from the structure list
Function BrukerXRD_IntegerFromList(index, list)
	variable index
	string list
	variable value
	value = str2num(StringFromList(index, list))
	value = round(value)
	return(value)
end

// Strips white space from start and end of the string (dealing with the structures)
function/S BrukerXRD_StripLeadingTrailingWhiteSpace(inputstring)
	string inputstring
	variable p1, p2, nchar
	nchar = strlen(inputstring)
	p1 = BrukerXRD_NextNonWhiteSpace(0, InputString)
	if (p1 == nchar)
		return("")
	endif
	inputstring = inputstring[p1,inf]
	inputstring = BrukerXRD_ReverseString( InputString )
	p1 = BrukerXRD_NextNonWhiteSpace(0, InputString)
	inputstring = inputstring[p1,inf]
	inputstring = BrukerXRD_ReverseString( InputString )
	return(inputstring)	
end

// Extracting doubles from the structure list
Function BrukerXRD_DoubleFromList(index, list)
	variable index
	string list
	return(str2num(StringFromList(index, list)))
End

//checking for correct tag
Function BrukerXRD_TagCorrect(Tagstr, LS)
	String TagStr
	STRUCT BrukerXRD_FrameHeaderLine &LS
	variable value
	value = !cmpstr(UpperStr(Tagstr),UpperStr(LS.LineTag))
	if (!value)
		Print "Field Tag for Frame File Not As Expected."
		Print "Expected: ", Tagstr
		Print "Read: ", LS.LineTag
	endif
	return(value)
End

// For handling the structure of the frame files
Function BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LineStruct)
	variable gBrukerFrameFile
	STRUCT BrukerXRD_FrameHeaderLine &LineStruct
	String string80, tagstr, datastr
	FStatus gBrukerFrameFile
	LineStruct.Offset = V_FilePos
	string80 =  BrukerXRD_Get80CharLine(gBrukerFrameFile)
	tagstr = BrukerXRD_StripLeadingTrailingWhiteSpace(string80[0,7])
	datastr = string80[8,inf]
	LineStruct.LineTag = tagstr
	LineStruct.DataStr = datastr
	LineStruct.DataList = BrukerXRD_DataStr2List(datastr)
	LineStruct.FullLine = string80
	return(LineStruct.Offset)
End

// Building the header structure from the structures defined previously
Function BrukerXRD_BuildGFRMHeaderStruct(gBrukerFrameFile, sGFRM)
	variable gBrukerFrameFile
	STRUCT BrukerXRD_GFRMHeader &sGFRM
	STRUCT BrukerXRD_FrameHeaderLine LS
	
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Format", LS))
	 	sGFRM.Format = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Version", LS))
	 	sGFRM.Version = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "HDRBLKS", LS))
	 	sGFRM.HeaderBlocks = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "TYPE", LS))
	 	sGFRM.Type = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Site", LS))
	 	sGFRM.Site = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Model", LS))
	 	sGFRM.Model = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "User", LS))
	 	sGFRM.User = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Sample", LS))
	 	sGFRM.Sample = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "SetName", LS))
	 	sGFRM.SetName = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Run", LS))
	 	sGFRM.Run = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "SAMPNUM", LS))
	 	sGFRM.SampleNumber = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title1 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title2 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title3 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title4 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title5 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title6 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title7 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "Title", LS))
	 	sGFRM.Title8 = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NCOUNTS", LS))
	 	sGFRM.NumCounts = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NOVERFL", LS))
	 	sGFRM.NumOverFlow = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "MINIMUM", LS))
	 	sGFRM.Minimum = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "MAXIMUM", LS))
	 	sGFRM.Maximum = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NONTIME", LS))
	 	sGFRM.NumOnTime = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NLATE", LS))
	 	sGFRM.NumLate = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "FILENAM", LS))
	 	sGFRM.FileName = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CREATED", LS))
	 	sGFRM.DateTimeStr = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CUMULAT", LS))
	 	sGFRM.CUMULAT = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ELAPSDR", LS))
	 	sGFRM.ELAPSDR = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ELAPSDA", LS))
	 	sGFRM.ELAPSDA = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "OSCILLA", LS))
	 	sGFRM.Oscillation = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NSTEPS", LS))
	 	sGFRM.NumSteps = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "RANGE", LS))
	 	sGFRM.Range = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "START", LS))
	 	sGFRM.Start = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "INCREME", LS))
	 	sGFRM.ScanIncrement = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NUMBER", LS))
	 	sGFRM.SeqNumber = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NFRAMES", LS))
	 	sGFRM.NumFrames = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ANGLES", LS))
	 	sGFRM.TwoTheta= BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Omega= BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Phi= BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Chi= BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NOVER64", LS))
	 	sGFRM.NumPixOver64K = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NPIXELB", LS))
	 	sGFRM.BytesPerPixel = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NROWS", LS))
	 	sGFRM.NumRows = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NCOLS", LS))
	 	sGFRM.NumCols = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "WORDORD", LS))
	 	sGFRM.ByteOrderinWord = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "LONGORD", LS))
	 	sGFRM.WordOrderinLong = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "TARGET", LS))
	 	sGFRM.Target = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "SOURCEK", LS))
	 	sGFRM.SourceKV = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "SOURCEM", LS))
	 	sGFRM.SourcemA = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "FILTER", LS))
	 	sGFRM.Filter = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CELL", LS))
	 	sGFRM.Cell_A = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Cell_B = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Cell_C = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Cell_Alpha = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.Cell_Beta = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CELL", LS))
	 	sGFRM.Cell_Gamma = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "MATRIX", LS))
	 	sGFRM.Matrix_C1 = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Matrix_C2 = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Matrix_C3 = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Matrix_C4 = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.Matrix_C5 = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "MATRIX", LS))
	 	sGFRM.Matrix_C6 = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Matrix_C7 = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Matrix_C8 = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Matrix_C9 = BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "LOWTEMP", LS))
	 	sGFRM.LowTemp = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ZOOM", LS))
	 	sGFRM.Zoom_Xc = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Zoom_Yc = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Zoom_Mag = BrukerXRD_DoubleFromList(2,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CENTER", LS))
	 	sGFRM.Center_X = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Center_Y = BrukerXRD_DoubleFromList(1,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DISTANC", LS))
	 	sGFRM.Distance_cm = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "TRAILER", LS))
	 	sGFRM.TrailerBytePointer = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "COMPRES", LS))
	 	sGFRM.Compression = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "LINEAR", LS))
	 	sGFRM.PixOffset_1 = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.PixOffset_2 = BrukerXRD_DoubleFromList(1,LS.DataList)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "PHD", LS))
	 	sGFRM.PulseHD_1 = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.PulseHD_2 = BrukerXRD_DoubleFromList(1,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "PreAmp", LS))
	 	sGFRM.PreAmp = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CORRECT", LS))
	 	sGFRM.Flood_File = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "WARPFIL", LS))
	 	sGFRM.Warp_File = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "WAVELEN", LS))
	 	sGFRM.Wavelength_Avg = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Wavelength_A1 = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Wavelength_A2 = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Wavelength_B = BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "MAXXY", LS))
	 	sGFRM.MaxPix_X = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.MaxPix_Y = BrukerXRD_DoubleFromList(1,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "AXIS", LS))
	 	sGFRM.ScanAxis = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ENDING", LS))
	 	sGFRM.End_2Theta = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.End_Omega = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.End_Phi = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.End_Chi = BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DETPAR", LS))
	 	sGFRM.Detector_dX = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Detector_dY = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Detector_dDist = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Detector_Pitch = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.Detector_Roll = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DETPAR", LS))
	 	sGFRM.Detector_Yaw = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "LUT", LS))
	 	sGFRM.Display_LUT = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DISPLIM", LS))
	 	sGFRM.Display_Lim1 = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Display_Lim2 = BrukerXRD_DoubleFromList(1,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "PROGRAM", LS))
	 	sGFRM.ProgramName = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ROTATE", LS))
	 	sGFRM.RotatePhi = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "BITMASK", LS))
	 	sGFRM.BitMaskFile = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "OCTMASK", LS))
	 	sGFRM.OctagonMask_1 = BrukerXRD_IntegerFromList(0,LS.DataList)
	 	sGFRM.OctagonMask_2 = BrukerXRD_IntegerFromList(1,LS.DataList)
	 	sGFRM.OctagonMask_3 = BrukerXRD_IntegerFromList(2,LS.DataList)
	 	sGFRM.OctagonMask_4 = BrukerXRD_IntegerFromList(3,LS.DataList)
	 	sGFRM.OctagonMask_5 = BrukerXRD_IntegerFromList(4,LS.DataList)
	 	sGFRM.OctagonMask_5 = BrukerXRD_IntegerFromList(4,LS.DataList)
	 	sGFRM.OctagonMask_6 = BrukerXRD_IntegerFromList(5,LS.DataList)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "OCTMASK", LS))
	 	sGFRM.OctagonMask_7 = BrukerXRD_IntegerFromList(0,LS.DataList)
	 	sGFRM.OctagonMask_8 = BrukerXRD_IntegerFromList(1,LS.DataList)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ESDCELL", LS))
	 	sGFRM.Cell_dA = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Cell_dB = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Cell_dC = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Cell_dAlpha = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.Cell_dBeta = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ESDCELL", LS))
	 	sGFRM.Cell_dGamma = BrukerXRD_DoubleFromList(0,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DETTYPE", LS))
	 	sGFRM.DetectorType = StringFromList(0,LS.DataList)
	 	if (!cmpstr("CMTOGRID", UpperStr(StringFromList(1,LS.DataList))))
		 	sGFRM.CmToGrid = BrukerXRD_DoubleFromList(2,LS.DataList)
		 else
		 	Print "Unexpected Sub-mnemonic in DETTYPE"
		 endif

	 	if (!cmpstr("PIXPERCM", UpperStr(StringFromList(3,LS.DataList))))
		 	sGFRM.PixPerCm = BrukerXRD_DoubleFromList(4,LS.DataList)
		 else
		 	Print "Unexpected Sub-mnemonic in DETTYPE"
		 endif
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "NEXP", LS))
	 	sGFRM.Num_Exposures = BrukerXRD_IntegerFromList(0,LS.DataList)
	 endif
	 
	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CCDPARM", LS))
	 	sGFRM.CCD_ReadNoise = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.CCD_e_ADU = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.CCD_e_Photon = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.CCD_Bias = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.CCD_FullScale = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CHEM", LS))
	 	sGFRM.ChemFormula = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "MORPH", LS))
	 	sGFRM.Morphology = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CCOLOR", LS))
	 	sGFRM.CrystColor = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "CSIZE", LS))
	 	sGFRM.CrystSize = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DNSMET", LS))
	 	sGFRM.DensityMethod = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "DARK", LS))
	 	sGFRM.DarkCurName = BrukerXRD_StripLeadingTrailingWhiteSpace(LS.DataStr)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "AUTORNG", LS))
	 	sGFRM.Auto_Gain = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.Auto_HSTime = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.Auto_Scale = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.Auto_Offset = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.Auto_FullScale = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ZEROADJ", LS))
	 	sGFRM.dZero_2Theta = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.dZero_Omega = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.dZero_Phi = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.dZero_Chi = BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "XTRANS", LS))
	 	sGFRM.XTrans_X = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.XTrans_Y = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.XTrans_Z = BrukerXRD_DoubleFromList(2,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "HKL&XY", LS))
	 	sGFRM.RecipSpac_H = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.RecipSpac_K = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.RecipSpac_L = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.RecipSpac_pixX = BrukerXRD_DoubleFromList(3,LS.DataList)
	 	sGFRM.RecipSpac_pixY = BrukerXRD_DoubleFromList(4,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "AXES2", LS))
	 	sGFRM.DiffracAxes_X = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.DiffracAxes_Y = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.DiffracAxes_Z = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.DiffracAxes_Aux = BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif

	 BrukerXRD_GetFrameLineStruct(gBrukerFrameFile, LS)
	 if (BrukerXRD_TagCorrect( "ENDING2", LS))
	 	sGFRM.GonEndAxes_X = BrukerXRD_DoubleFromList(0,LS.DataList)
	 	sGFRM.GonEndAxes_Y = BrukerXRD_DoubleFromList(1,LS.DataList)
	 	sGFRM.GonEndAxes_Z = BrukerXRD_DoubleFromList(2,LS.DataList)
	 	sGFRM.GonEndAxes_Aux = BrukerXRD_DoubleFromList(3,LS.DataList)
	 endif
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Strucutrs Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Structure BrukerXRD_OverFlowEntry
	char	Value[9]
	char	Offset[7]
EndStructure

Structure BrukerXRD_FrameHeaderLine
	int32	Offset
	char	LineTag[8]
	char	DataStr[72]
	char	DataList[100]
	char	FullLine[80]
EndStructure

Structure BrukerXRD_GFRMHeader
	int32	Format
	int32	Version
	int32	HeaderBlocks
	char 	Type[72]
	char	Site[72]
	char	Model[72]
	char	User[72]
	char	Sample[72]
	char	SetName[72]
	int32	Run
	int32	SampleNumber
	char	Title1[72]
	char	Title2[72]
	char	Title3[72]
	char	Title4[72]
	char	Title5[72]
	char	Title6[72]
	char	Title7[72]
	char	Title8[72]
	int32	NumCounts
	int32	NumOverFlow
	int32	Minimum
	int32	Maximum
	int32	NumOnTime
	int32	NumLate
	char	FileName[72]		//FILENAM
	char	DateTimeStr[72]	//CREATED
	double	Cumulat			//CUMULAT
	double	Elapsdr				//ELAPSDR
	double	Elapsda				//ELAPSDA
	int32	Oscillation			//OSCILLA
	int32	NumSteps			//NSTEPS
	double	Range				//RANGE
	double	Start				//START
	double	ScanIncrement		//INCREME
	int32	SeqNumber			//NUMBER
	int32	NumFrames			//NFRAMES
	double	TwoTheta			//ANGLES
	double	Omega				//ANGLES
	double	Phi					//ANGLES
	double	Chi					//ANGLES
	int32	NumPixOver64K	//NOVER64
	int32	BytesPerPixel		//NPIXELB
	int32	NumRows			//NROWS
	int32	NumCols			//NCOLS
	int32	ByteOrderinWord	//WORDORD
	int32	WordOrderinLong	//LONGORD
	char	Target[72]			//TARGET
	double	SourceKV			//SOURCEK
	double	SourcemA			//SOURCEM
	char	Filter[72]			//FILTER
	double	Cell_A				//CELL
	double	Cell_B				//CELL
	double	Cell_C				//CELL
	double	Cell_Alpha			//CELL
	double 	Cell_Beta			//CELL
	double	Cell_Gamma		//CELL
	double	Matrix_C1			//MATRIX
	double	Matrix_C2			//MATRIX
	double	Matrix_C3			//MATRIX
	double	Matrix_C4			//MATRIX
	double	Matrix_C5			//MATRIX
	double	Matrix_C6			//MATRIX
	double	Matrix_C7			//MATRIX
	double	Matrix_C8			//MATRIX
	double	Matrix_C9			//MATRIX
	int32	LowTemp			//LOWTEMP
	double	Zoom_Xc			//ZOOM
	double	Zoom_Yc			//ZOOM
	double	Zoom_Mag			//ZOOM
	double	Center_X			//CENTER
	double	Center_Y			//CENTER
	double	Distance_cm		//DISTANC
	int32	TrailerBytePointer	//TRAILER
	char	Compression[72]	//COMPRES
	double	PixOffset_1			//LINEAR
	double	PixOffset_2			//LINEAR
	double	PulseHD_1			//PHD
	double	PulseHD_2			//PHD
	double	PreAmp				//PREAMP
	char	Flood_File[72]		//CORRECT
	char	Warp_File[72]		//WARPFIL
	double	Wavelength_Avg	//WAVELEN	
	double	Wavelength_A1		//WAVELEN
	double	Wavelength_A2		//WAVELEN
	double	Wavelength_B		//WAVELEN
	double	MaxPix_X			//MAXXY
	double	MaxPix_Y			//MAXXY
	int32	ScanAxis			//AXIS
	double	End_2Theta			//ENDING
	double	End_Omega			//ENDING
	double	End_Phi			//ENDING
	double	End_Chi			//ENDING
	double	Detector_dX			//DETPAR
	double	Detector_dY			//DETPAR
	double	Detector_dDist		//DETPAR
	double	Detector_Pitch		//DETPAR
	double	Detector_Roll		//DETPAR
	double	Detector_Yaw		//DETPAR
	char	Display_LUT[72]	//LUT
	double	Display_Lim1		//DISPLIM
	double	Display_Lim2		//DISPLIM
	char	ProgramName[72]	//PROGRAM
	int32	RotatePhi			//ROTATE
	char	BitMaskFile[72]	//BITMASK
	int32	OctagonMask_1		//OCTMASK
	int32	OctagonMask_2		//OCTMASK
	int32	OctagonMask_3		//OCTMASK
	int32	OctagonMask_4		//OCTMASK
	int32	OctagonMask_5		//OCTMASK
	int32	OctagonMask_6		//OCTMASK
	int32	OctagonMask_7		//OCTMASK
	int32	OctagonMask_8		//OCTMASK
	double	Cell_dA				//ESDCELL
	double	Cell_dB				//ESDCELL
	double	Cell_dC				//ESDCELL
	double	Cell_dAlpha			//ESDCELL
	double	Cell_dBeta			//ESDCELL
	double	Cell_dGamma		//ESDCELL
	char	DetectorType[72]	//DETTYPE
	double	CmToGrid			//DETTYPE: Sub-mnemonic
	double	PixPerCm			//DETTYPE: Sub-mnemonic
	int32	Num_Exposures		//NEXP
	double	CCD_ReadNoise		//CCDPARM
	double	CCD_e_ADU			//CCDPARM
	double	CCD_e_Photon		//CCDPARM
	double	CCD_Bias			//CCDPARM
	double	CCD_FullScale		//CCDPARM
	char	ChemFormula[72]	//CHEM
	char	Morphology[72]	//MORPH
	char	CrystColor[72]		//CCOLOR
	char	CrystSize[72]		//CSIZE
	char	DensityMethod[72]	//DNSMET
	char	DarkCurName[72]	//DARK
	double	Auto_Gain			//AUTORNG
	double	Auto_HSTime		//AUTORNG
	double	Auto_Scale			//AUTORNG
	double	Auto_Offset			//AUTORNG
	double	Auto_FullScale		//AUTORNG
	double	dZero_2Theta		//ZEROADJ
	double	dZero_Omega		//ZEROADJ
	double	dZero_Phi			//ZEROADJ
	double	dZero_Chi			//ZEROADJ
	double	XTrans_X			//XTRANS
	double	XTrans_Y			//XTRANS
	double	XTrans_Z			//XTRANS
	double	RecipSpac_H		//HKL&XY
	double	RecipSpac_K		//HKL&XY
	double	RecipSpac_L		//HKL&XY
	double	RecipSpac_pixX		//HKL&XY
	double	RecipSpac_pixY		//HKL&XY
	double	DiffracAxes_X		//AXES2
	double	DiffracAxes_Y		//AXES2
	double	DiffracAxes_Z		//AXES2
	double	DiffracAxes_Aux	//AXES2
	double	GonEndAxes_X		//ENDING2	
	double	GonEndAxes_Y		//ENDING2	
	double	GonEndAxes_Z		//ENDING2	
	double	GonEndAxes_Aux	//ENDING2	
EndStructure

function BrukerXRD_FrameAngles(wFrame)
	wave wFrame
	//get frame header
	STRUCT BrukerXRD_GFRMHeader sGFRM
	structget/S sGFRM,note(wFrame)
	//get needed values
	variable vSamp2DetDistance = sGFRM.Distance_cm*10//mm
	variable vDetCenterX = sGFRM.Center_X
	variable vDetCenterY = sGFRM.Center_Y
	variable vDet2Theta = sGFRM.TwoTheta//deg
	variable vChi = sGFRM.Chi//deg
	variable vPhi = sGFRM.Phi//deg
	variable vOmega = sGFRM.Omega//deg
	variable vWavelength = sGFRM.Wavelength_A1//Ang
	variable vPixPermm = 0.95*(sGFRM.PixPerCm)	//pixels per mm (not cm), correction based on Al2O3 comparison
	string sDetType = sGFRM.DetectorType
	int iScanAxis = sGFRM.ScanAxis
	
	//check if currnet waves have the right info, abort if so
	string sNoteString = "Det="+sDetType+",2T="+num2str(vDet2Theta)+",PixPermm="+num2str(vPixPermm)+",Det-Sample-mm="+num2str(vSamp2DetDistance)
	wave/Z w2Theta = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta
	wave/Z wChi = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi
	if(waveExists(w2Theta)&&stringmatch(sNoteString,note(w2Theta)))
		if(waveExists(wChi)&&stringmatch(sNoteString,note(wChi)))
			return -1
		endif
	endif
	
	//check this should work
	if(!stringmatch("PXC-V500",sDetType))
		DoAlert/T="Can't do it!",0,"This transform procedure works for the PXC-V500 detector only."
		return -1
	endif
	if(iScanAxis!=2)
		DoAlert/T="Can't do it!",0,"This transform procedure works omega scan axis frames only."
		return -1
	endif
	if(!vDet2Theta>0&&vDet2Theta<180)
		DoAlert/T="Can't do it!",0,"This transform procedure works for 2Theta of the detector between 0 and 180 degrees."
		return -1
	endif
	if(vChi!=90)
		DoAlert/T="Can't do it!",0,"This transform procedure works for Chi of the detector at 90 degrees only."
		return -1
	endif
	//calculate the 2T range across rows from sample-detector distance (from fit of information in detector spec sheet)
	
	//duplicate frame to hold 2Theta and Omega Values
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder "root:Packages:COMBIgor:"
	newdatafolder/O/S Instruments
	newdatafolder/O/S BrukerXRDFrames
	Make/O/N=(dimsize(wFrame,0),dimsize(wFrame,1)) TwoTheta
	Make/O/N=(dimsize(wFrame,0),dimsize(wFrame,1)) Q_ScatteringVector
	Make/O/N=(dimsize(wFrame,0),dimsize(wFrame,1)) Chi
	Make/O/N=(dimsize(wFrame,0),dimsize(wFrame,1)) TwoTheta_grid
	Make/O/N=(dimsize(wFrame,0),dimsize(wFrame,1)) Chi_grid
	Make/O/N=(dimsize(wFrame,0),dimsize(wFrame,1)) Q_ScatteringVector_grid
	setdatafolder root: 
	wave w2Theta = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta
	wave wQ = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector
	Note/K w2Theta, sNoteString
	Note/K wQ, sNoteString
	wave wChi = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi
	Note/K wChi, sNoteString
	wave w2Theta_grid = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta_grid
	wave wChi_grid = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi_grid
	wave wQ_grid = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector_grid

	//Convert pixels to 2T and Chi values
	w2Theta_grid = nan
	wChi_grid = nan
	wQ_grid = nan
	w2Theta = nan
	wChi = nan
	int iRow, iCol
	variable vX, vY, vThis2T, vThisChi, vThisQ
	for(iRow=0;iRow<dimsize(wFrame,0);iRow+=1)//x
		COMBI_ProgressWindow("FRAMEANGLECALC","Calculating Frame Angles","Calculation Running",iRow+1,dimsize(wFrame,0))
		for(iCol=0;iCol<dimsize(wFrame,1);iCol+=1)//y
			//get pix location in mm
			vX = (iRow-vDetCenterX)/vPixPermm
			vY = (iCol-vDetCenterY)/vPixPermm
			vThis2T = 2*BrukerXRD_FrameAngle_2theta(vX,vY,vDet2Theta/2,vSamp2DetDistance)
			vThisQ = 4*Pi*Sin(vThis2T/2*pi/180)/vWavelength
			vThisChi = 180+BrukerXRD_FrameAngle_Chi(vX,vY,vDet2Theta/2,vSamp2DetDistance)
			//Store angles
			w2Theta[iRow][iCol] = vThis2T
			wChi[iRow][iCol] = vThisChi
			wQ[iRow][iCol] = vThisQ
			//gridlines
			if(numtype(wFrame[iRow][iCol])==0)
				if(mod(vThis2T,5)<0.1||mod(vThis2T,5)>4.9)
					w2Theta_grid[iRow][iCol] = 1
				else
					w2Theta_grid[iRow][iCol] = 0
				endif
				if(mod(abs(vThisChi),5)<0.1||mod(abs(vThisChi),5)>4.9)
					wChi_grid[iRow][iCol] = 1
				else
					wChi_grid[iRow][iCol] = 0
				endif
				if(mod(vThisQ,0.5)<0.01||mod(vThisQ,0.5)>0.49)
					wQ_grid[iRow][iCol] = 1
				else
					wQ_grid[iRow][iCol] = 0
				endif
			endif
		endfor
	endfor
	
	
	//store grid info
	Note/K wChi_grid, "MaxChi="+num2str(wavemax(wChi))+";MinChi="+num2str(wavemin(wChi))
	Note/K w2Theta_grid, "Max2T="+num2str(wavemax(w2Theta))+";Min2T="+num2str(wavemin(w2Theta))
	Note/K wQ_grid, "Max2T="+num2str(wavemax(wQ))+";Min2T="+num2str(wavemin(wQ))
	
	//return to user folder 
	setdatafolder $sTheCurrentUserFolder
	
	//plot transformation values
	BrukerXRD_PlotTransformations()
	
	//plot frame with lines
	BrukerXRD_PlotFrame(wFrame,"FrameTransform_Chi_2T")
	BrukerXRD_AddGridToFrame(sAxisOption="2Theta")
	
	BrukerXRD_PlotFrame(wFrame,"FrameTransform_Chi_Q")
	BrukerXRD_AddGridToFrame(sAxisOption="Q")
	
end

function BrukerXRD_PlotTransformations()
	//check if currnet waves exist
	wave/Z wQ = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector
	wave/Z w2Theta = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta
	wave/Z wChi = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi
	if(!waveExists(w2Theta))
		DoAlert/T="Wave missing!",0,"Please perform frame transformations first."
		return -1
	endif
	if(!waveExists(wChi))
		DoAlert/T="Wave missing!",0,"Please perform frame transformations first."
		return -1
	endif
	if(!waveExists(wQ))
		DoAlert/T="Wave missing!",0,"Please perform frame transformations first."
		return -1
	endif
	
	//plot the angle waves
	NewImage/K=1 root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta
	ModifyGraph margin=30,width=300,height=300
	ModifyGraph margin(right)=130
	ModifyGraph tick=1,mirror=3,fSize=12,tlOffset=0,font="System Font"
	Label left "pixel # (x)"
	Label top "pixel # (y)"
	ColorScale/C/N=cscale/F=0/M/A=RC/X=5.00/Y=0.00/E image=TwoTheta
	ColorScale/C/N=cscale "2Theta (degree)"
	ModifyImage TwoTheta ctab= {*,*,BlueRedGreen,0}
	
	NewImage/K=1 root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector
	ModifyGraph margin=30,width=300,height=300
	ModifyGraph margin(right)=130
	ModifyGraph tick=1,mirror=3,fSize=12,tlOffset=0,font="System Font"
	Label left "pixel # (x)"
	Label top "pixel # (y)"
	ColorScale/C/N=cscale/F=0/M/A=RC/X=5.00/Y=0.00/E image=Q_ScatteringVector
	ColorScale/C/N=cscale "Scattering Vector Magnitude-Q (2π/Å)"
	ModifyImage Q_ScatteringVector ctab= {*,*,BlueRedGreen,0}
	
	NewImage/K=1 root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi
	ModifyGraph margin=30,width=300,height=300
	ModifyGraph margin(right)=130
	ModifyGraph tick=1,mirror=3,fSize=12,tlOffset=0,font="System Font"
	Label left "pixel # (x)"
	Label top "pixel # (y)"
	ColorScale/C/N=cscale/F=0/M/A=RC/X=5.00/Y=0.00/E image=Chi
	ColorScale/C/N=cscale "Chi (degree)"
	ModifyImage Chi ctab= {*,*,BlueRedGreen,0}
end

function BrukerXRD_AddGridToFrame([sWindow,sAxisOption])
	string sWindow,sAxisOption
	if(ParamIsDefault(sWindow))
		sWindow = stringfromlist(0,winList("*",";","WIN:1"))
		if(strlen(sWindow)==0)//no window found
			return -1
		endif
	endif
	if(ParamIsDefault(sAxisOption))
		sAxisOption = COMBI_StringPrompt("Q","Angle axis:","Q;2Theta","","What type of Axis?")
		if(stringmatch("CANCEL",sAxisOption))//no window found
			return -1
		endif
	endif
	
	//check for grid waves
	//check if currnet waves exist
	wave/Z wQ = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector_grid
	wave/Z w2Theta = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta_grid
	wave/Z wChi = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi_grid
	if(!waveExists(w2Theta))
		DoAlert/T="Wave missing!",0,"Please perform frame transformations first."
		return -1
	endif
	if(!waveExists(wChi))
		DoAlert/T="Wave missing!",0,"Please perform frame transformations first."
		return -1
	endif
	if(!waveExists(wQ))
		DoAlert/T="Wave missing!",0,"Please perform frame transformations first."
		return -1
	endif
	
	if(stringmatch(sAxisOption,"Q"))
		AppendImage/W=$sWindow root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi_grid
		ModifyImage/W=$sWindow Chi_grid ctab= {0.9,1.1,Green,0},minRGB=NaN,maxRGB=NaN
		ModifyGraph/W=$sWindow mirror=0,noLabel=2,axRGB=(0,0,0,328)
		AppendImage/W=$sWindow root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector_grid
		ModifyImage/W=$sWindow Q_ScatteringVector_grid ctab= {0.9,1.1,Blue,0},minRGB=NaN,maxRGB=NaN
		ModifyGraph/W=$sWindow mirror=0,noLabel=2,axRGB=(0,0,0,328)
		TextBox/W=$sWindow/C/N=LineTag/F=0/M/A=MT/X=0.00/Y=1.00/E "\\Z12\\F'System Font'\\K(1,12815,52428)Constant Q    \\K(3,52428,1)Constant χ"
	elseif(stringmatch(sAxisOption,"2Theta"))
		AppendImage/W=$sWindow root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi_grid
		ModifyImage/W=$sWindow Chi_grid ctab= {0.9,1.1,Green,0},minRGB=NaN,maxRGB=NaN
		ModifyGraph/W=$sWindow mirror=0,noLabel=2,axRGB=(0,0,0,328)
		AppendImage/W=$sWindow root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta_grid
		ModifyImage/W=$sWindow TwoTheta_grid ctab= {0.9,1.1,Blue,0},minRGB=NaN,maxRGB=NaN
		ModifyGraph/W=$sWindow mirror=0,noLabel=2,axRGB=(0,0,0,328)
		TextBox/W=$sWindow/C/N=LineTag/F=0/M/A=MT/X=0.00/Y=1.00/E "\\Z12\\F'System Font'\\K(1,12815,52428)Constant 2θ    \\K(3,52428,1)Constant χ"
	endif
	
	
end

function BrukerXRD_TransformFrames([sProject,sLibrary,sDataType])
	//get data to treat
	string sProject,sLibrary,sDataType
	if(ParamIsDefault(sProject))
		sProject = COMBI_ChooseProject()
		if(stringmatch(sProject,""))
			return -1
		endif
	endif
	if(ParamIsDefault(sLibrary))
		sLibrary = COMBI_LibraryPrompt(sProject,";","Library to plot:",0,0,0,3)
		if(stringmatch(sLibrary,"CANCEL"))
			return -1
		endif
	endif
	if(ParamIsDefault(sDataType))
		sDataType = COMBI_DataTypePrompt(sProject,";","Frame data to plot:",0,0,0,3,sLibraries=sLibrary)
		if(stringmatch(sDataType,"CANCEL"))
			return -1
		endif
	endif
	wave/Z wMatrixFrameData = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDataType//matrix data to transform (2Theta,Chi)
	if(!waveExists(wMatrixFrameData))
		return -1
	endif
	string sTransformedName = COMBI_StringPrompt(sDataType+"_Transformed","Name for transformed data type:","","This is what the new matrix data will be called.","What name?")
	if(stringmatch(sTransformedName,"CANCEL"))
		return -1
	endif
	string sXAxisType = COMBI_StringPrompt("Q","Transformed data axis:","Q;2Theta","","What type of Axis?")
	if(stringmatch(sXAxisType,"CANCEL"))
		return -1
	endif
	//get frame header
	STRUCT BrukerXRD_GFRMHeader sGFRM
	structget/S sGFRM,note(wMatrixFrameData)
	//make angle waves
	BrukerXRD_FrameAngles(wMatrixFrameData)
	//get angle waves
	wave w2Theta = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta
	wave wQ = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector
	wave wChi = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi
	//make new matrix data type for transformed data
	string sNewMatrixName = Combi_AddDataType(sProject,sLibrary,sTransformedName,3)
	wave wNewTransformedData = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sNewMatrixName//matrix data to transform to 2Theta vs Chi
	wNewTransformedData[][][] = nan
	Note wNewTransformedData, "1;"+sXAxisType+";Data Transformed from:"+sDataType+""
	
	//redimension for 2Theta range
	variable v2TMin = wavemin(w2Theta)
	variable v2TMax = wavemax(w2Theta)
	variable vQMin = wavemin(wQ)
	variable vQMax = wavemax(wQ)
	variable v2TRange = v2TMax-v2TMin
	int i2TRows = ceil(v2TRange*20)//0.05 2T steps
	if(stringmatch(sXAxisType,"Q"))
		Redimension/N=((i2TRows+2),-1,-1),wNewTransformedData
		Setscale/I x,vQMin-.01,vQMax+.01,"2π/Å",wNewTransformedData
	elseif(stringmatch(sXAxisType,"2Theta"))
		Redimension/N=((i2TRows+2),-1,-1),wNewTransformedData
		Setscale/I x,v2TMin-0.05,v2TMax+0.05,"degree",wNewTransformedData
	endif
	
	//redimension for Chi range
	variable vChiMin = wavemin(wChi)
	variable vChiMax = wavemax(wChi)
	variable vChiRange = vChiMax-vChiMin
	int iChiRows = ceil(vChiRange*10)//0.1 Chi steps
	Redimension/N=(-1,(iChiRows+2),-1),wNewTransformedData
	Setscale/I y,vChiMin-0.1,vChiMax+0.1,"degree",wNewTransformedData
	
	//transform all the data to 2T vs Chi
	int iRow,iCol,iSample,iThis2TRow,iThisCol,iThisQRow
	variable vThis2T,vThisChi,vThisQ
	v2TMin = inf
	v2TMax = -inf
	vChiMin = inf
	vChiMax = -inf
	vQMin = inf
	vQMax = -inf
	if(stringmatch(sXAxisType,"Q"))
		for(iRow=0;iRow<dimsize(wMatrixFrameData,0);iRow+=1)//2T
			COMBI_ProgressWindow("FRAMETRANSFORM","Transforming Frames:","Transformation Running",iRow+1,dimsize(wMatrixFrameData,0))
			for(iCol=0;iCol<dimsize(wMatrixFrameData,1);iCol+=1)//Chi
				vThisChi = wChi[iRow][iCol]
				vThisQ = wQ[iRow][iCol]
				iThisCol = ScaleToIndex(wNewTransformedData,vThisChi,1)
				iThisQRow = ScaleToIndex(wNewTransformedData,vThisQ,0)
				if(numtype(wMatrixFrameData[iRow][iCol][0])==0)//actual data in frame data
					if(numtype(wNewTransformedData[iThisQRow][iThisCol][0])==2)//nan in transformed data, zero it
						wNewTransformedData[iThisQRow][iThisCol][] = 0
					endif
					wNewTransformedData[iThisQRow][iThisCol][] += wMatrixFrameData[iRow][iCol][r]
					vChiMin = min(vChiMin,vThisChi)
					vChiMax = max(vChiMax,vThisChi)
					vQMin = min(vQMin,vThisQ)
					vQMax = max(vQMax,vThisQ)
				endif
			endfor
		endfor
		
	elseif(stringmatch(sXAxisType,"2Theta"))
		for(iRow=0;iRow<dimsize(wMatrixFrameData,0);iRow+=1)//2T
			COMBI_ProgressWindow("FRAMETRANSFORM","Transforming Frames:","Transformation Running",iRow+1,dimsize(wMatrixFrameData,0))
			for(iCol=0;iCol<dimsize(wMatrixFrameData,1);iCol+=1)//Chi
				vThis2T = w2Theta[iRow][iCol]
				vThisChi = wChi[iRow][iCol]
				iThis2TRow = ScaleToIndex(wNewTransformedData,vThis2T,0)
				iThisCol = ScaleToIndex(wNewTransformedData,vThisChi,1)
				if(numtype(wMatrixFrameData[iRow][iCol][0])==0)//actual data in frame data
					if(numtype(wNewTransformedData[iThis2TRow][iThisCol][0])==2)//nan in transformed data, zero it
						wNewTransformedData[iThis2TRow][iThisCol][] = 0
					endif
					wNewTransformedData[iThis2TRow][iThisCol][] += wMatrixFrameData[iRow][iCol][r]
					v2TMin = min(v2TMin,vThis2T)
					v2TMax = max(v2TMax,vThis2T)
					vChiMin = min(vChiMin,vThisChi)
					vChiMax = max(vChiMax,vThisChi)
				endif
			endfor
		endfor
	endif
	
	//trim new data
	int iExtra2T_begin = ScaleToIndex(wNewTransformedData,v2TMin,0)-1
	int iExtra2T_end = dimsize(wNewTransformedData,0)-ScaleToIndex(wNewTransformedData,v2TMax,0)-1
	int iExtraQ_begin = ScaleToIndex(wNewTransformedData,vQMin,0)-1
	int iExtraQ_end = dimsize(wNewTransformedData,0)-ScaleToIndex(wNewTransformedData,vQMax,0)-1
	int iExtraChi_begin = ScaleToIndex(wNewTransformedData,vChiMin,1)-1
	int iExtraChi_end = dimsize(wNewTransformedData,1)-ScaleToIndex(wNewTransformedData,vChiMax,1)-1
	if(stringmatch(sXAxisType,"Q"))
		if(iExtraQ_end>0)
			Deletepoints/M=0 (ScaleToIndex(wNewTransformedData,vQMax,0)+1), iExtraQ_end, wNewTransformedData 
		endif
		if(iExtraQ_begin>0)
			Deletepoints/M=0 0, iExtraQ_begin, wNewTransformedData 
		endif
		Setscale/I x,vQMin,vQMax,"2π/Å",wNewTransformedData
	elseif(stringmatch(sXAxisType,"2Theta"))
		if(iExtra2T_end>0)
			Deletepoints/M=0 (ScaleToIndex(wNewTransformedData,v2TMax,0)+1), iExtra2T_end, wNewTransformedData 
		endif
		if(iExtra2T_begin>0)
			Deletepoints/M=0 0, iExtra2T_begin, wNewTransformedData 
		endif
		Setscale/I x,v2TMin,v2TMax,"degree",wNewTransformedData
	endif
	
	if(iExtraChi_end>0)
		Deletepoints/M=1 (ScaleToIndex(wNewTransformedData,vChiMax,1)+1), iExtraChi_end, wNewTransformedData
	endif
	if(iExtraChi_begin>0)
		Deletepoints/M=1 0, iExtraChi_end, wNewTransformedData
	endif
	Setscale/I y,vChiMin,vChiMax,"degree",wNewTransformedData
	
	//make 0 into nan
	for(iRow=0;iRow<dimsize(wNewTransformedData,0);iRow+=1)//2T
		for(iCol=0;iCol<dimsize(wNewTransformedData,1);iCol+=1)//Chi
			for(iSample=0;iSample<dimsize(wNewTransformedData,2);iSample+=1)//Sample
				if(wNewTransformedData[iRow][iCol][iSample]==0)
					wNewTransformedData[iRow][iCol][iSample]=nan
				endif
			endfor
		endfor
	endfor
	
	//plot all frames
	BrukerXRD_PlotAllFrames(sProject=sProject,sLibrary=sLibrary,sDataType=sNewMatrixName)
		
end

function BrukerXRD_TransformAFrame([wFrame])
	//get data to treat
	wave wFrame
	string sPath
	string sStart
	if(paramIsDefault(wFrame))
		CreateBrowser prompt = "Select the frame wave",showWaves=1,showVars=0,showStrs=0
		wave wFrame = $stringfromlist(0,S_BrowserList)
		sPath = stringfromlist(0,S_BrowserList)
		sStart = stringfromlist((itemsInList(sPath)),sPath,":")
	else
		sPath = ""
		sStart = ""
	endif
	
	string sTransformedName = COMBI_StringPrompt(sStart+"_Transformed","Name for transformed data type:","","This is what the new matrix data will be called.","What name?")
	if(stringmatch(sTransformedName,"CANCEL"))
		return -1
	endif
	string sXAxisType = COMBI_StringPrompt("Q","Transformed data axis:","Q;2Theta","","What type of Axis?")
	if(stringmatch(sXAxisType,"CANCEL"))
		return -1
	endif
	//get frame header
	STRUCT BrukerXRD_GFRMHeader sGFRM
	structget/S sGFRM,note(wFrame)
	//make angle waves
	BrukerXRD_FrameAngles(wFrame)
	//get angle waves
	wave w2Theta = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:TwoTheta
	wave wQ = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Q_ScatteringVector
	wave wChi = root:Packages:COMBIgor:Instruments:BrukerXRDFrames:Chi
	//make new matrix data type for transformed data
	make/O/N=(1,1) $"root:"+sTransformedName//matrix data to transform to 2Theta vs Chi
	wave wNewTransformedData = $"root:"+sTransformedName//matrix data to transform to 2Theta vs Chi
	wNewTransformedData[][] = nan
	
	//redimension for 2Theta range
	variable v2TMin = wavemin(w2Theta)
	variable v2TMax = wavemax(w2Theta)
	variable vQMin = wavemin(wQ)
	variable vQMax = wavemax(wQ)
	variable v2TRange = v2TMax-v2TMin
	int i2TRows = ceil(v2TRange*20)//0.05 2T steps
	if(stringmatch(sXAxisType,"Q"))
		Redimension/N=((i2TRows+2),-1),wNewTransformedData
		Setscale/I x,vQMin-.01,vQMax+.01,"2π/Å",wNewTransformedData
	elseif(stringmatch(sXAxisType,"2Theta"))
		Redimension/N=((i2TRows+2),-1),wNewTransformedData
		Setscale/I x,v2TMin-0.05,v2TMax+0.05,"degree",wNewTransformedData
	endif
	
	//redimension for Chi range
	variable vChiMin = wavemin(wChi)
	variable vChiMax = wavemax(wChi)
	variable vChiRange = vChiMax-vChiMin
	int iChiRows = ceil(vChiRange*10)//0.1 Chi steps
	Redimension/N=(-1,(iChiRows+2)),wNewTransformedData
	Setscale/I y,vChiMin-0.1,vChiMax+0.1,"degree",wNewTransformedData
	
	//transform all the data to 2T vs Chi
	int iRow,iCol,iSample,iThis2TRow,iThisCol,iThisQRow
	variable vThis2T,vThisChi,vThisQ
	v2TMin = inf
	v2TMax = -inf
	vChiMin = inf
	vChiMax = -inf
	vQMin = inf
	vQMax = -inf
	if(stringmatch(sXAxisType,"Q"))
		for(iRow=0;iRow<dimsize(wFrame,0);iRow+=1)//2T
			COMBI_ProgressWindow("FRAMETRANSFORM","Transforming Frames:","Transformation Running",iRow+1,dimsize(wFrame,0))
			for(iCol=0;iCol<dimsize(wFrame,1);iCol+=1)//Chi
				vThisChi = wChi[iRow][iCol]
				vThisQ = wQ[iRow][iCol]
				iThisCol = ScaleToIndex(wNewTransformedData,vThisChi,1)
				iThisQRow = ScaleToIndex(wNewTransformedData,vThisQ,0)
				if(numtype(wFrame[iRow][iCol])==0)//actual data in frame data
					if(numtype(wNewTransformedData[iThisQRow][iThisCol])==2)//nan in transformed data, zero it
						wNewTransformedData[iThisQRow][iThisCol] = 0
					endif
					wNewTransformedData[iThisQRow][iThisCol] += wFrame[iRow][iCol]
					vChiMin = min(vChiMin,vThisChi)
					vChiMax = max(vChiMax,vThisChi)
					vQMin = min(vQMin,vThisQ)
					vQMax = max(vQMax,vThisQ)
				endif
			endfor
		endfor
		
	elseif(stringmatch(sXAxisType,"2Theta"))
		for(iRow=0;iRow<dimsize(wFrame,0);iRow+=1)//2T
			COMBI_ProgressWindow("FRAMETRANSFORM","Transforming Frames:","Transformation Running",iRow+1,dimsize(wFrame,0))
			for(iCol=0;iCol<dimsize(wFrame,1);iCol+=1)//Chi
				vThis2T = w2Theta[iRow][iCol]
				vThisChi = wChi[iRow][iCol]
				iThis2TRow = ScaleToIndex(wNewTransformedData,vThis2T,0)
				iThisCol = ScaleToIndex(wNewTransformedData,vThisChi,1)
				if(numtype(wFrame[iRow][iCol])==0)//actual data in frame data
					if(numtype(wNewTransformedData[iThis2TRow][iThisCol])==2)//nan in transformed data, zero it
						wNewTransformedData[iThis2TRow][iThisCol] = 0
					endif
					wNewTransformedData[iThis2TRow][iThisCol] += wFrame[iRow][iCol]
					v2TMin = min(v2TMin,vThis2T)
					v2TMax = max(v2TMax,vThis2T)
					vChiMin = min(vChiMin,vThisChi)
					vChiMax = max(vChiMax,vThisChi)
				endif
			endfor
		endfor
	endif
	
	//trim new data
	int iExtra2T_begin = ScaleToIndex(wNewTransformedData,v2TMin,0)-1
	int iExtra2T_end = dimsize(wNewTransformedData,0)-ScaleToIndex(wNewTransformedData,v2TMax,0)-1
	int iExtraQ_begin = ScaleToIndex(wNewTransformedData,vQMin,0)-1
	int iExtraQ_end = dimsize(wNewTransformedData,0)-ScaleToIndex(wNewTransformedData,vQMax,0)-1
	int iExtraChi_begin = ScaleToIndex(wNewTransformedData,vChiMin,1)-1
	int iExtraChi_end = dimsize(wNewTransformedData,1)-ScaleToIndex(wNewTransformedData,vChiMax,1)-1
	if(stringmatch(sXAxisType,"Q"))
		if(iExtraQ_end>0)
			Deletepoints/M=0 (ScaleToIndex(wNewTransformedData,vQMax,0)+1), iExtraQ_end, wNewTransformedData 
		endif
		if(iExtraQ_begin>0)
			Deletepoints/M=0 0, iExtraQ_begin, wNewTransformedData 
		endif
		Setscale/I x,vQMin,vQMax,"2π/Å",wNewTransformedData
	elseif(stringmatch(sXAxisType,"2Theta"))
		if(iExtra2T_end>0)
			Deletepoints/M=0 (ScaleToIndex(wNewTransformedData,v2TMax,0)+1), iExtra2T_end, wNewTransformedData 
		endif
		if(iExtra2T_begin>0)
			Deletepoints/M=0 0, iExtra2T_begin, wNewTransformedData 
		endif
		Setscale/I x,v2TMin,v2TMax,"degree",wNewTransformedData
	endif
	
	if(iExtraChi_end>0)
		Deletepoints/M=1 (ScaleToIndex(wNewTransformedData,vChiMax,1)+1), iExtraChi_end, wNewTransformedData
	endif
	if(iExtraChi_begin>0)
		Deletepoints/M=1 0, iExtraChi_end, wNewTransformedData
	endif
	Setscale/I y,vChiMin,vChiMax,"degree",wNewTransformedData
	
	//make 0 into nan
	for(iRow=0;iRow<dimsize(wNewTransformedData,0);iRow+=1)//2T
		for(iCol=0;iCol<dimsize(wNewTransformedData,1);iCol+=1)//Chi
			if(wNewTransformedData[iRow][iCol]==0)
				wNewTransformedData[iRow][iCol]=nan
			endif
		endfor
	endfor
	
	//plot all frames
	BrukerXRD_PlotFrame(wFrame,"Original")
	BrukerXRD_PlotFrame(wNewTransformedData,"Transformed")
	ModifyGraph axRGB=(0,0,0),tlblRGB=(0,0,0),alblRGB=(0,0,0)
	Label left "Chi (\\U)"
	if(stringmatch(sXAxisType,"Q"))
		Label top "Scattering vector magnitude (\\U)"
	elseif(stringmatch(sXAxisType,"2Theta"))
		Label top "Diffraction angle (\\U)"
	endif
	
	ModifyGraph tick=2,mirror(left)=1,noLabel=0
end  

//from: Two-dimensional x-ray diffraction by Bob B. He, Wiley Press, Eq 2.8
function BrukerXRD_FrameAngle_2theta(x,y,D2T,D2S)
	variable x //pix x from center (mm)
	variable y //pix y from center (mm)
	variable D2T //Detector 2 theta angle (deg)
	variable D2S //Sample-Detector distance (mm)
	variable alpha = D2T*pi/180
	return (aCos((x*sin(alpha)+D2S*cos(alpha))/sqrt(D2S^2+x^2+y^2)))*180/pi
end 

//from: Two-dimensional x-ray diffraction by Bob B. He, Wiley Press, Eq 2.9
function BrukerXRD_FrameAngle_Chi(x,y,D2T,D2S)
	variable x //pix x from center (mm)
	variable y //pix y from center (mm)
	variable D2T //Detector 2 theta angle (deg)
	variable D2S //Sample-Detector distance (mm)
	variable alpha = D2T*pi/180
	return (((x*cos(alpha)-D2S*sin(alpha))/abs(x*cos(alpha)-D2S*sin(alpha)))*aCos(-y/sqrt(y^2+(x*cos(alpha)-D2S*sin(alpha))^2)))*180/pi
end 

function BrukerXRD_ZeroToNan([sWaves])
	string sWaves
	if(paramIsDefault(sWaves))
		CreateBrowser prompt = "Select the frame wave",showWaves=1,showVars=0,showStrs=0
		sWaves = S_BrowserList
	endif
	
	int iW
	for(iW=0;iW<itemsinlist(sWaves);iW+=1)
		wave wFrame = $stringfromlist(iW,sWaves)
		int iR,iC, iL
		int iTR = dimsize(wFrame,0)
		int iTC = dimsize(wFrame,1)
		int iTL = dimsize(wFrame,2)
		
		for(iR=0;iR<iTR;iR+=1)
			for(iC=0;iC<iTC;iC+=1)
			if(iTL==0)
				if(wFrame[iR][iC]==0)
					wFrame[iR][iC]=nan
				endif
			elseif(iTL>0)
				for(iL=0;iL<iTL;iL+=1)
					if(wFrame[iR][iC][iL]==0)
					wFrame[iR][iC][iL]=nan
				endif
				endfor
			endif
			endfor
		endfor
	endfor

end