#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ May 2018 : Original
// V1.1 Sage Bauers _ 20180513 : Modified names, added initialization options, additional cleanup
// V1.11: Karen Heinselman _ Oct 2018 : Polishing and debugging

//Description of functions within:
//C_Example
//P_Example

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Instruments"
		 "NREL UV-Vis-NIR",/Q, COMBI_NREL_UVVisNIR()
	end
end


//	prompt sCondLayer, "Conductivity Layer (Siemen/cm)", popup, sLayerList
//	prompt sNewCond, "New Layer Name:"	


//returns a list of descriptors for each of the globals used to define loading
Function/S NREL_UVVisNIR_Descriptions(sGlobalName)
	string sGlobalName
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_NREL_UVVisNIR_Globals"
	string sReturnstring =""
	strswitch(sGlobalName)
		case "NREL_UVVisNIR":
			sReturnstring = "NREL UV Vis"
			break
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "sThicknessLayer":
			sReturnstring =  "Thickness label:"
			break
		case "vThicknessUnits":
			sReturnstring =  "Thickness units (m):"
			break
		case "sTran":
			sReturnstring = "Transmission Tag:"
			break
		case "sRef":
			sReturnstring = "Reflected Tag:"
			break
		case "sWavelength":
			sReturnstring = "Wavelength Tag (nm):"
			break
		case "sCorrectionWave":
			sReturnstring = "Substrate Correction:"
			break
		case "sAbsorptionCoef":
			sReturnstring = "Absorption coefficient (cm\S-1\M):"
			break
		case "sAbsorbance":
			sReturnstring = "Absorbance:"
			break
		case "sRefCorTrans":
			sReturnstring = "Reflection-corrected Transmission:"
			break
		case "sEnergy":
			sReturnstring = "Energy Tag (eV):"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

function NREL_UVVisNIR_Define()

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:

	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	string sThicknessLayer, sTran, sRef, sWavelength,sCorrectionWave,sAbsorptionCoef,sAbsorbance,sRefCorTrans, sEnergy
	variable vThicknessUnits
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sRSLayer",sProject)))//if project is defined previously, start with those values
		sTran = COMBI_GetInstrumentString(sThisInstrumentName,"sTran",sProject)
		sRef = COMBI_GetInstrumentString(sThisInstrumentName,"sRef",sProject)
		sWavelength = COMBI_GetInstrumentString(sThisInstrumentName,"sWavelength",sProject)
		sThicknessLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sThicknessLayer",sProject)
		sAbsorptionCoef = COMBI_GetInstrumentString(sThisInstrumentName,"sAbsorptionCoef",sProject)
		sCorrectionWave = COMBI_GetInstrumentString(sThisInstrumentName,"sCorrectionWave",sProject)
		sAbsorbance= COMBI_GetInstrumentString(sThisInstrumentName,"sAbsorbance",sProject)
		sRefCorTrans= COMBI_GetInstrumentString(sThisInstrumentName,"sRefCorTrans",sProject)
		sEnergy= COMBI_GetInstrumentString(sThisInstrumentName,"sEnergy",sProject)
		vThicknessUnits = COMBI_GetInstrumentNumber(sThisInstrumentName,"vThicknessUnits",sProject)
	else //not previously defined, start with default values 
		sTran = "T"
		sRef = "R" 
		sThicknessLayer = "Skip"
		sAbsorptionCoef = "Alpha"
		sAbsorbance = "A"
		sRefCorTrans = "RCT"
		sWavelength = "nm"
		sEnergy = "eV"
		sCorrectionWave = ""
		vThicknessUnits = 1E-6
	endif
	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject","",sProject)
	
	// get info for standard file values
	//sTran
	sTran=COMBI_StringPrompt(sTran,NREL_UVVisNIR_Descriptions("sTran"),"","This marks data types as transmitted" ,"Define Data Tag Element")
	if(stringmatch(sTran,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sTran",sTran,sProject)// store global
	
	//sRef
	sRef = COMBI_StringPrompt(sRef,NREL_UVVisNIR_Descriptions("sRef"),"","This marks data types as reflected" ,"Define Data Tag Element")
	if(stringmatch(sRef,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRef",sRef,sProject)// store global
	
	//sThicknessLayer
	sThicknessLayer = COMBI_DataTypePrompt(sProject,sThicknessLayer,NREL_UVVisNIR_Descriptions("sThicknessLayer"),0,0,1,1)
	if(stringmatch(sThicknessLayer,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sThicknessLayer",sThicknessLayer,sProject)// store global
	
	// (if not skipping thickness) thickness units
	if(!stringmatch(sThicknessLayer,"Skip"))
		vThicknessUnits = COMBI_NumberPrompt(vThicknessUnits,"Thickness units in meters:","This helps produce accurate calculations","Thickness units definition")
		if(numtype(vThicknessUnits)==2)
			COMBI_InstrumentDefinition()
			SetDataFolder $sTheCurrentUserFolder 
			return -1 
		endif
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vThicknessUnits",num2str(vThicknessUnits),sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vThicknessUnits","",sProject)// store global
	endif
	
	if(!stringmatch(sThicknessLayer,"Skip"))
		sAbsorptionCoef=COMBI_StringPrompt(sAbsorptionCoef,NREL_UVVisNIR_Descriptions("sAbsorptionCoef"),"","This marks data types as absorption" ,"Define Data Tag Element")
		if(stringmatch(sAbsorptionCoef,"CANCEL"))
			COMBI_InstrumentDefinition()
			SetDataFolder $sTheCurrentUserFolder 
			return -1 
		endif
	else
		sAbsorptionCoef = ""
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sAbsorptionCoef",sAbsorptionCoef,sProject)// store global
	
	//sAbsorbance
	sAbsorbance=COMBI_StringPrompt(sAbsorbance,NREL_UVVisNIR_Descriptions("sAbsorbance"),"","This marks data types as absorbance" ,"Define Data Tag Element")
	if(stringmatch(sAbsorbance,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	if(stringmatch(sAbsorbance,"")||stringmatch(sAbsorbance," ")||stringmatch(sAbsorbance,"None")||stringmatch(sAbsorbance,"No"))
		sAbsorbance = "Skip"
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sAbsorbance",sAbsorbance,sProject)// store global
	
	//sRefCorTran
	sRefCorTrans=COMBI_StringPrompt(sRefCorTrans,NREL_UVVisNIR_Descriptions("sRefCorTrans"),"","This marks data types as reflection-corrected transmission" ,"Define Data Tag Element")
	if(stringmatch(sRefCorTrans,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	if(stringmatch(sRefCorTrans,"")||stringmatch(sRefCorTrans," ")||stringmatch(sRefCorTrans,"None")||stringmatch(sRefCorTrans,"No"))
		sRefCorTrans = "Skip"
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRefCorTrans",sRefCorTrans,sProject)// store global
	
	//sWavelength
	sWavelength = COMBI_StringPrompt(sWavelength,NREL_UVVisNIR_Descriptions("sWavelength"),"","This marks data types as wavelength" ,"Define Data Tag Element")
	if(stringmatch(sWavelength,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sWavelength",sWavelength,sProject)// store global
	
	//sEnergy
	sEnergy = COMBI_StringPrompt(sEnergy,NREL_UVVisNIR_Descriptions("sEnergy"),"","This marks data types as energy" ,"Define Data Tag Element")
	if(stringmatch(sEnergy,"CANCEL"))
		COMBI_InstrumentDefinition()
		SetDataFolder $sTheCurrentUserFolder 
		return -1 
	endif
	if(stringmatch(sEnergy,"")||stringmatch(sEnergy," ")||stringmatch(sEnergy,"None")||stringmatch(sEnergy,"No"))
		sEnergy = "Skip"
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sEnergy",sEnergy,sProject)// store global
	
	//sCorrectionWave
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	DoAlert/T="Option for corrections?", 1, "Would you like to load/change the correction wave for the mirror and the substrate? (Igor Text)?"
	if(V_flag==1)
		setdatafolder root: 
		NewDataFolder/O/S COMBIgor
		NewDataFolder/O/S $sProject
		NewDataFolder/O/S Corrections
		NewDataFolder/O/S NREL_UVVisNIR
		if(stringmatch("Import Folder",sLoadPath))
			sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
			NewPath/Z/Q/O pUserPath, sLoadPath
			Pathinfo/S pUserPath //direct to user folder
		endif
		LoadWave/T/Q/O
		string sLoadedWaves = S_waveNames
		string sLoadedFile = S_path+S_fileName
		SetDataFolder $sTheCurrentUserFolder 
		if(V_flag!=4)
			DoAlert/T="Corrections Loader?", 0, "Something went wrong, that should have loaded 4 Igor text waves, but it didn't"
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCorrectionWave","No",sProject)// store global
		else
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCorrectionWave","Yes",sProject)// store global
		endif
	elseif(V_flag==2)
		setdatafolder root: 
		NewDataFolder/O/S COMBIgor
		NewDataFolder/O/S $sProject
		NewDataFolder/O/S Corrections
		NewDataFolder/O/S NREL_UVVisNIR
		string sAllCorrectionWaves = wavelist("*",";","")
		SetDataFolder $sTheCurrentUserFolder 
		if(itemsinlist(sAllCorrectionWaves)==4)
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCorrectionWave","Yes",sProject)// store global
		else
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCorrectionWave","No",sProject)// store global
		endif
	elseif(V_flag==3)
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif	
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
	
	SetDataFolder $sTheCurrentUserFolder 
	
end

function NREL_UVVisNIR_Load()

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 

	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	//get 4PP globals
	string sThisInstrumentName = "NREL_UVVisNIR"
	string sThicknessLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sThicknessLayer",sProject)
	string sTran = COMBI_GetInstrumentString(sThisInstrumentName,"sTran",sProject)
	string sRef = COMBI_GetInstrumentString(sThisInstrumentName,"sRef",sProject)
	string sWavelength = COMBI_GetInstrumentString(sThisInstrumentName,"sWavelength",sProject)
	string sAbsorptionCoef =COMBI_GetInstrumentString(sThisInstrumentName,"sAbsorptionCoef",sProject)
	string sAbsorbance = COMBI_GetInstrumentString(sThisInstrumentName,"sAbsorbance",sProject)
	string sRefCorTrans = COMBI_GetInstrumentString(sThisInstrumentName,"sRefCorTrans",sProject)
	string sCorrectionWave = COMBI_GetInstrumentString(sThisInstrumentName,"sCorrectionWave",sProject)
	string sEnergy = COMBI_GetInstrumentString(sThisInstrumentName,"sEnergy",sProject)
	variable vThicknessUnits = COMBI_GetInstrumentNumber(sThisInstrumentName,"vThicknessUnits",sProject)
	
	//get project globals
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	variable vTotalColumns = COMBI_GetGlobalNumber("vTotalColumns",sProject)
	variable vTotalRows = COMBI_GetGlobalNumber("vTotalRows",sProject)
	variable iTotalSamples = vTotalSamples-1
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O pLoadPath
		if(V_flag)
			return -1
		endif
	else
		NewPath/Z/Q/O pLoadPath
		if(V_flag)
			return -1
		endif
	endif
	Pathinfo pLoadPath
	
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	//get each of 4 needed files and import to waves
	string sAllFiles = IndexedFile(pLoadPath,-1,".h5")
	
	//declarations
	Variable vFileID, vGroupID
	int vTotalSamplesIn = 0
	int vNIRRTotalSamplesIn =0
	int vNIRTTotalSamplesIn =0
	int vUVIRTotalSamplesIn =0
	int vUVITTotalSamplesIn =0
	int bNIRT=0, bNIRR=0, bUVIR=0, bUVIT=0
	string sWaveLengthLabel,sIntensityLabel, sThisLibrary
	variable vThisThickness
	int iSample, iThisSample, iVector
	int vNIRSize, vUVISize
	variable vFirstWL_NIRR = inf
	variable vLastWL_NIRR = -inf
	variable vFirstWL_NIRT = inf
	variable vLastWL_NIRT = -inf
	variable vFirstWL_UVIR = inf
	variable vLastWL_UVIR = -inf
	variable vFirstWL_UVIT = inf
	variable vLastWL_UVIT = -inf
	
	//waves for interps
	Make/O/N=(1,3,1) wInterpedNIRWave//Columns 1:Wavelength 2:Trans 3:Ref
	Make/O/N=(1,3,1) wInterpedUVIWave
	Make/O/N=(1) wTempXWave
	Make/O/N=(1) wTempYWave
	wave wInterpedNIRWave = root:wInterpedNIRWave
	wave wInterpedUVIWave = root:wInterpedUVIWave
	wave wTempXWave = root:wTempXWave
	wave wTempYWave = root:wTempYWave
	
	// import NIRR
	string sNIRR = listmatch(sAllFiles,"*nirr*")
	if(itemsinlist(sNIRR)>1)
		DoAlert/T="Too many files in this folder." 0, "Too many NIRR files in this folder; there should only be one."
		return-1
	elseif(itemsinlist(sNIRR)==1)
		sNIRR = stringfromlist(0,sNIRR)
		HDF5OpenFile /R /Z /P=pLoadPath vFileID as sNIRR
		HDF5OpenGroup vFileID ,  "ProcessedSpectra" , vGroupID
		HDF5LoadData/Z/Q/O vGroupID,"MeasuredData"
		HDF5CloseFile vFileID
		wave wNIRRIn = MeasuredData
		Rename wNIRRIn, MeasuredDataNIRR
		bNIRR = 1
		vNIRRTotalSamplesIn = dimsize(wNIRRIn,0)
		vNIRSize = dimsize(wNIRRIn,2)
		vFirstWL_NIRR = wNIRRIn[0][0][0]
		vLastWL_NIRR = wNIRRIn[0][0][vNIRSize-1]
	endif
	
	// import NIRT
	string sNIRT = listmatch(sAllFiles,"*nirt*")
	if(itemsinlist(sNIRT)>1)
		DoAlert/T="Too many files in this folder," 0, "Too many NIRT files in this folder; there should only be one."
		return-1
	elseif(itemsinlist(sNIRT)==1)
		sNIRT = stringfromlist(0,sNIRT)
		HDF5OpenFile /R /Z /P=pLoadPath vFileID as sNIRT
		HDF5OpenGroup vFileID ,  "ProcessedSpectra" , vGroupID
		HDF5LoadData/Z/Q/O vGroupID,"MeasuredData"
		HDF5CloseFile vFileID
		wave wNIRTIn = MeasuredData
		Rename wNIRTIn, MeasuredDataNIRT
		bNIRT = 1
		vNIRTTotalSamplesIn = dimsize(wNIRTIn,0)
		vNIRSize = dimsize(wNIRTIn,2)
		vFirstWL_NIRT = wNIRTIn[0][0][0]
		vLastWL_NIRT = wNIRTIn[0][0][vNIRSize-1]
	endif
	
	// import UVIR
	string sUVIR = listmatch(sAllFiles,"*uvir*")
	if(itemsinlist(sUVIR)>1)
		DoAlert/T="Too many files in this folder!" 0, "Too many UVIR files in this folder, should only be one!"
		return-1
	elseif(itemsinlist(sUVIR)==1)
		sUVIR = stringfromlist(0,sUVIR)
		HDF5OpenFile /R /Z /P=pLoadPath vFileID as sUVIR
		HDF5OpenGroup vFileID ,  "ProcessedSpectra" , vGroupID
		HDF5LoadData/Z/Q/O vGroupID,"MeasuredData"
		HDF5CloseFile vFileID
		wave wUVIRIn = MeasuredData
		Rename wUVIRIn, MeasuredDataUVIR
		bUVIR = 1
		vUVIRTotalSamplesIn = dimsize(wUVIRIn,0)
		vUVISize = dimsize(wUVIRIn,2)
		vFirstWL_UVIR = wUVIRIn[0][0][0]
		vLastWL_UVIR = wUVIRIn[0][0][vUVISize-1]
	endif
	
	// import UVIT
	string sUVIT = listmatch(sAllFiles,"*uvit*")
	if(itemsinlist(sUVIT)>1)
		DoAlert/T="Too many files in this folder!" 0, "Too many UVIT files in this folder, should only be one!"
		return-1
	elseif(itemsinlist(sUVIT)==1)
		sUVIT = stringfromlist(0,sUVIT)
		HDF5OpenFile /R /Z /P=pLoadPath vFileID as sUVIT
		HDF5OpenGroup vFileID ,  "ProcessedSpectra" , vGroupID
		HDF5LoadData/Z/Q/O vGroupID,"MeasuredData"
		HDF5CloseFile vFileID
		wave wUVITIn = MeasuredData
		Rename wUVITIn, MeasuredDataUVIT
		bUVIT = 1
		vUVITTotalSamplesIn = dimsize(wUVITIn,0)
		vUVISize = dimsize(wUVITIn,2)
		vFirstWL_UVIT = wUVITIn[0][0][0]
		vLastWL_UVIT = wUVITIn[0][0][vUVISize-1]
	endif
	
	//number of Samples
	vTotalSamplesIn = max(vUVITTotalSamplesIn,vUVIRTotalSamplesIn,vNIRTTotalSamplesIn,vNIRRTotalSamplesIn)
	if(bUVIT==1)
		if(vTotalSamplesIn != vUVITTotalSamplesIn)
			DoAlert/T="Inconsistent number of Samples" 0, "Not all these files have the same number of Samples, check the UVIT wave."
			return-1
		endif
	endif
	if(bUVIR==1)
		if(vTotalSamplesIn != vUVIRTotalSamplesIn)
			DoAlert/T="Inconsistent number of Samples" 0, "Not all these files have the same number of Samples, check the UVIR wave."
			return-1
		endif
	endif
	if(bNIRT==1)
		if(vTotalSamplesIn != vNIRTTotalSamplesIn)
			DoAlert/T="Inconsistent number of Samples" 0, "Not all these files have the same number of Samples, check the NIRT wave."
			return-1
		endif
	endif
	if(bNIRR==1)
		if(vTotalSamplesIn != vNIRRTotalSamplesIn)
			DoAlert/T="Inconsistent number of Samples" 0, "Not all these files have the same number of Samples, check the NIRR wave."
			return-1
		endif
	endif
	
	//Get Ranges
	variable vFirstWL_NIR = ceil(min(vFirstWL_NIRT,vFirstWL_NIRR))
	variable vLastWL_NIR = floor(max(vLastWL_NIRT,vLastWL_NIRR))
	variable vFirstWL_UVI = ceil(min(vFirstWL_UVIT,vFirstWL_UVIR))
	variable vLastWL_UVI = floor(max(vLastWL_UVIT,vLastWL_UVIR))
	if(bNIRT==1||bNIRR==1)
		redimension/N=(vTotalSamplesIn,-1,vLastWL_NIR-vFirstWL_NIR) wInterpedNIRWave
		wInterpedNIRWave[][][] = nan
		wInterpedNIRWave[][0][] = vFirstWL_NIR+r
	endif
	
	if(bUVIT==1||bUVIR==1)
		redimension/N=(vTotalSamplesIn,-1,vLastWL_UVI-vFirstWL_UVI) wInterpedUVIWave
		wInterpedUVIWave[][][] = nan
		wInterpedUVIWave[][0][] = vFirstWL_UVI+r
	endif
	
	//get Library names
	if(mod(vTotalSamplesIn,vTotalSamples)!=0)
		DoAlert/T="Incorrect number of samples" 0, "The number of Samples should be a multiple of "+num2str(vTotalSamples)+"."
		return-1
	else
		int vTotalLibraries = vTotalSamplesIn/vTotalSamples
		int iLibrary
		string sFromMappingGrid=""
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			string sThisLibraryToUse = COMBI_LibraryPrompt(sProject,"New","Name for Library "+num2str(iLibrary+1)+":",0,1,1,2)
			if(stringmatch(sThisLibraryToUse,"CANCEL"))
				return-1
			endif
			sFromMappingGrid = AddListItem(sThisLibraryToUse, sFromMappingGrid,";",inf)
		endfor
	endif	
	
	//wave for transfering
	Make/O/N=(vTotalSamples,2,1) wTransferWave
	wave wTransferWave = root:wTransferWave
	
	//correction?
	int bCorrection=0
	if(stringmatch("Yes",sCorrectionWave))
		setdatafolder root: 
		NewDataFolder/O/S COMBIgor
		NewDataFolder/O/S $sProject
		NewDataFolder/O/S Corrections
		NewDataFolder/O/S NREL_UVVisNIR
		string sAllCorrectionWaves = wavelist("*",";","")
		SetDataFolder $sTheCurrentUserFolder 
		if(itemsinlist(sAllCorrectionWaves)==4)
			bCorrection = 1
			string sCorrectFolderPath ="root:COMBIgor:"+sProject+":Corrections:NREL_UVVisNIR:"
			wave wNIRTCor = $sCorrectFolderPath+stringfromlist(0,listMatch(sAllCorrectionWaves,"T*nir"))
			wave wNIRRCor = $sCorrectFolderPath+stringfromlist(0,listMatch(sAllCorrectionWaves,"R*nir"))
			wave wUVITCor = $sCorrectFolderPath+stringfromlist(0,listMatch(sAllCorrectionWaves,"T*uvi"))
			wave wUVIRCor = $sCorrectFolderPath+stringfromlist(0,listMatch(sAllCorrectionWaves,"R*uvi"))
			if(!waveexists(wNIRTCor))
				bCorrection = 0
				DoAlert/T="Correction fail" 0, "The NIRT correction wave couldn't be found; no correction applied. Please check for a wave with the name T....nir in the COMBIgor:"+sProject+":Corrections:NREL_UVVisNIR folder."
			endif
			if(!waveexists(wNIRRCor))
				bCorrection = 0
				DoAlert/T="Correction fail" 0, "The NIRR correction wave couldn't be found; no correction applied. Please check for a wave with the name R....nir in the COMBIgor:"+sProject+":Corrections:NREL_UVVisNIR folder."
			endif
			if(!waveexists(wUVITCor))
				bCorrection = 0
				DoAlert/T="Correction fail" 0, "The UVIT correction wave couldn't be found; no correction applied. Please check for a wave with the name T....uvi in the COMBIgor:"+sProject+":Corrections:NREL_UVVisNIR folder."
			endif
			if(!waveexists(wUVIRCor))
				bCorrection = 0
				DoAlert/T="Correction fail" 0, "The UVIR correction wave couldn't be found; no correction applied. Please check for a wave with the name R....uvi in the COMBIgor:"+sProject+":Corrections:NREL_UVVisNIR folder."
			endif
		endif
	endif
	
	//store raw data, UVIT
	if(bUVIT==1)
		redimension/N=(-1,2,dimsize(wInterpedUVIWave,2)) wTransferWave
		redimension/N=(dimsize(wUVITIn,2)) wTempXWave, wTempYWave
		wTempXWave[]=nan
		wTempYWave[]=nan
		wTransferWave[][][]=nan
		sWaveLengthLabel = "UVI_"+sWavelength
		sIntensityLabel = "UVI_"+sTran
		if(bCorrection==1)
			wUVITIn[][1][] = wUVITIn[p][1][r]*(wUVITCor[r]/100)
		endif
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				iThisSample = iSample+iLibrary*vTotalSamples
				wTempXWave[] = wUVITIn[iThisSample][0][p]
				wTempYWave[] = wUVITIn[iThisSample][1][p]
				wTransferWave[iSample][0][] = vFirstWL_UVI+r
				wTransferWave[iSample][1][] = nan
				wInterpedUVIWave[iThisSample][1][] = nan
				for(iVector=vFirstWL_UVI;iVector<vLastWL_UVI;iVector+=1)
					if(iVector>=vFirstWL_UVIT&&iVector<=vLastWL_UVIT)
						wInterpedUVIWave[iThisSample][1][iVector-vFirstWL_UVI] = interp(iVector,wTempXWave,wTempYWave)
						wTransferWave[iSample][1][iVector-vFirstWL_UVI] =interp(iVector,wTempXWave,wTempYWave)
					endif
				endfor
			endfor
			COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sWaveLengthLabel+";"+sIntensityLabel,-1,2,sScaleDataType=sWaveLengthLabel)
		endfor
	endif
	
	//store raw data, UVIR
	if(bUVIR==1)
		redimension/N=(-1,2,dimsize(wInterpedUVIWave,2)) wTransferWave
		redimension/N=(dimsize(wUVIRIn,2)) wTempXWave, wTempYWave
		wTempXWave[]=nan
		wTempYWave[]=nan
		wTransferWave[][][]=nan
		sWaveLengthLabel = "UVI_"+sWavelength
		sIntensityLabel = "UVI_"+sRef
		if(bCorrection==1)
			wUVIRIn[][1][] = wUVIRIn[p][1][r]*(wUVIRCor[r]/100)
		endif
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				iThisSample = iSample+iLibrary*vTotalSamples
				wTempXWave[] = wUVIRIn[iThisSample][0][p]
				wTempYWave[] = wUVIRIn[iThisSample][1][p]
				wTransferWave[iSample][0][] = vFirstWL_UVI+r
				wTransferWave[iSample][1][] = nan
				wInterpedUVIWave[iThisSample][2][] = nan
				for(iVector=vFirstWL_UVI;iVector<vLastWL_UVI;iVector+=1)
					if(iVector>=vFirstWL_UVIR&&iVector<=vLastWL_UVIR)
						wInterpedUVIWave[iThisSample][2][iVector-vFirstWL_UVI] = interp(iVector,wTempXWave,wTempYWave)
						wTransferWave[iSample][1][iVector-vFirstWL_UVI] =interp(iVector,wTempXWave,wTempYWave)
					endif
				endfor
			endfor
			COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sWaveLengthLabel+";"+sIntensityLabel,-1,2,sScaleDataType=sWaveLengthLabel)
		endfor
	endif
	
	//alpha and A if both R and T in UVI
	if(bUVIR==1&&1==bUVIT)
		redimension/N=(-1,2,dimsize(wInterpedUVIWave,2)) wTransferWave
		if(!stringmatch(sAbsorbance,"Skip"))//not skipping sAbsorbance
			sIntensityLabel = "UVI_"+sAbsorbance
			sWaveLengthLabel = "UVI_"+sWavelength
			wTransferWave[][][]=nan
			for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
				wTransferWave[][0][] = -ln(wInterpedUVIWave[(p+iLibrary*vTotalSamples)][1][r]/(1-wInterpedUVIWave[(p+iLibrary*vTotalSamples)][2][r]))
				wTransferWave[][1][] = wInterpedUVIWave[(p+iLibrary*vTotalSamples)][0][r]
				COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sIntensityLabel+";"+sWaveLengthLabel,-1,2,sScaleDataType=sWaveLengthLabel)
			endfor
		endif
		if(!stringmatch(sRefCorTrans,"Skip"))//not skipping sRefCorTrans
			wTransferWave[][][]=nan
			sIntensityLabel = "UVI_"+sRefCorTrans
			sWaveLengthLabel = "UVI_"+sWavelength
			for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
				wTransferWave[][0][] = (wInterpedUVIWave[(p+iLibrary*vTotalSamples)][1][r]/(1-wInterpedUVIWave[(p+iLibrary*vTotalSamples)][2][r]))
				wTransferWave[][1][] = wInterpedUVIWave[(p+iLibrary*vTotalSamples)][0][r]
				COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sIntensityLabel+";"+sWaveLengthLabel,-1,2,sScaleDataType=sWaveLengthLabel)
			endfor
		endif
		if(!stringmatch(sThicknessLayer,"Skip"))// not skipping thickness
			if(numtype(vThicknessUnits)==0)
				sIntensityLabel = "UVI_"+sAbsorptionCoef
				sWaveLengthLabel = "UVI_"+sWavelength
				for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
					sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
					wTransferWave[][][]=nan
					for(iSample=0;iSample<vTotalSamples;iSample+=1)
						iThisSample = iSample+iLibrary*vTotalSamples
						if(1==COMBI_CheckForData(sProject,sThisLibrary,sThicknessLayer,1,iSample))//non-zero number
							wave wThickness = $COMBI_DataPath(sProject,1)+sThisLibrary+":"+sThicknessLayer
							vThisThickness = wThickness[iSample]*vThicknessUnits*(1E2)//cm
							wTransferWave[iSample][1][] = -ln(wInterpedUVIWave[iThisSample][1][r]/(1-wInterpedUVIWave[iThisSample][2][r]))/vThisThickness
							wTransferWave[iSample][0][] = wInterpedUVIWave[iThisSample][0][r]
						else
							wTransferWave[iSample][][] = nan
						endif
					endfor
					COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sWaveLengthLabel+";"+sIntensityLabel,-1,2,sScaleDataType=sWaveLengthLabel)
				endfor
			endif
		endif
	endif
	
	//store raw data, NIRT
	if(bNIRT==1)
		redimension/N=(-1,2,dimsize(wInterpedNIRWave,2)) wTransferWave
		redimension/N=(dimsize(wNIRTIn,2)) wTempXWave, wTempYWave
		wTempXWave[]=nan
		wTempYWave[]=nan
		wTransferWave[][][]=nan
		sWaveLengthLabel ="NIR_"+sWavelength
		sIntensityLabel = "NIR_"+sTran
		if(bCorrection==1)
			wNIRTIn[][1][] = wNIRTIn[p][1][r]*(wNIRTCor[r]/100)
		endif
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				iThisSample = iSample+iLibrary*vTotalSamples
				wTempXWave[] = wNIRTIn[iThisSample][0][p]
				wTempYWave[] = wNIRTIn[iThisSample][1][p]
				wTransferWave[iSample][0][] = vFirstWL_NIR+r
				wTransferWave[iSample][1][] = nan
				wInterpedNIRWave[iThisSample][1][] = nan
				for(iVector=vFirstWL_NIR;iVector<vLastWL_NIR;iVector+=1)
					if(iVector>=vFirstWL_NIRT&&iVector<=vLastWL_NIRT)
						wInterpedNIRWave[iThisSample][1][iVector-vFirstWL_NIR] = interp(iVector,wTempXWave,wTempYWave)
						wTransferWave[iSample][1][iVector-vFirstWL_NIR] =interp(iVector,wTempXWave,wTempYWave)
					endif
				endfor
			endfor
			COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sWaveLengthLabel+";"+sIntensityLabel,-1,2,sScaleDataType=sWaveLengthLabel)
		endfor
	endif
	
	//store raw data, NIRR
	if(bNIRR==1)
		redimension/N=(-1,2,dimsize(wInterpedNIRWave,2)) wTransferWave
		redimension/N=(dimsize(wNIRRIn,2)) wTempXWave, wTempYWave
		wTempXWave[]=nan
		wTempYWave[]=nan
		wTransferWave[][][]=nan
		sWaveLengthLabel = "NIR_"+sWavelength
		sIntensityLabel = "NIR_"+sRef
		if(bCorrection==1)
			wNIRRIn[][1][] = wNIRRIn[p][1][r]*(wNIRRCor[r]/100)
		endif
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				iThisSample = iSample+iLibrary*vTotalSamples
				wTempXWave[] = wNIRRIn[iThisSample][0][p]
				wTempYWave[] = wNIRRIn[iThisSample][1][p]
				wTransferWave[iSample][0][] = vFirstWL_NIR+r
				wTransferWave[iSample][1][] = nan
				wInterpedNIRWave[iThisSample][2][] = nan
				for(iVector=vFirstWL_NIR;iVector<vLastWL_NIR;iVector+=1)
					if(iVector>=vFirstWL_NIRR&&iVector<=vLastWL_NIRR)
						wInterpedNIRWave[iThisSample][2][iVector-vFirstWL_NIR] = interp(iVector,wTempXWave,wTempYWave)
						wTransferWave[iSample][1][iVector-vFirstWL_NIR] =interp(iVector,wTempXWave,wTempYWave)
					endif
				endfor
			endfor
			COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sWaveLengthLabel+";"+sIntensityLabel,-1,2,sScaleDataType=sWaveLengthLabel)
		endfor
	endif
	
	//alpha and A if both R and T in NIR
	if(bNIRR==1&&1==bNIRT)
		redimension/N=(-1,2,dimsize(wInterpedNIRWave,2)) wTransferWave
		if(!stringmatch(sRefCorTrans,"Skip"))//not skipping sRefCorTrans
			wTransferWave[][][]=nan
			sIntensityLabel = "NIR_"+sRefCorTrans
			sWaveLengthLabel = "NIR_"+sWavelength
			for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
				wTransferWave[][0][] = ((wInterpedNIRWave[(p+iLibrary*vTotalSamples)][1][r])/(1-wInterpedNIRWave[(p+iLibrary*vTotalSamples)][2][r]))
				wTransferWave[][1][] = wInterpedNIRWave[(p+iLibrary*vTotalSamples)][0][r]
				COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sIntensityLabel+";"+sWaveLengthLabel,-1,2,sScaleDataType=sWaveLengthLabel)
			endfor
		endif
		if(!stringmatch(sAbsorbance,"Skip"))//not skipping sAbsorbance
			wTransferWave[][][]=nan
			sIntensityLabel = "NIR_"+sAbsorbance
			sWaveLengthLabel = "NIR_"+sWavelength
			for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
				sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
				wTransferWave[][0][] = -ln((wInterpedNIRWave[(p+iLibrary*vTotalSamples)][1][r])/(1-wInterpedNIRWave[(p+iLibrary*vTotalSamples)][2][r]))
				wTransferWave[][1][] = wInterpedNIRWave[(p+iLibrary*vTotalSamples)][0][r]
				COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sIntensityLabel+";"+sWaveLengthLabel,-1,2,sScaleDataType=sWaveLengthLabel)
			endfor
		endif
		if(!stringmatch(sThicknessLayer,"Skip"))// not skipping
			if(numtype(vThicknessUnits)==0)
				sIntensityLabel = "NIR_"+sAbsorptionCoef
				sWaveLengthLabel = "NIR_"+sWavelength
				for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
					sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
					wTransferWave[][][]=nan
					for(iSample=0;iSample<vTotalSamples;iSample+=1)
						iThisSample = iSample+iLibrary*vTotalSamples
						if(1==COMBI_CheckForData(sProject,sThisLibrary,sThicknessLayer,1,iSample))//non-zero number
							wave wThickness = $COMBI_DataPath(sProject,1)+sThisLibrary+":"+sThicknessLayer
							vThisThickness = wThickness[iSample]*vThicknessUnits*(1E2)//cm
							wTransferWave[iSample][1][] = -ln(abs(wInterpedNIRWave[iThisSample][1][r])/(1-wInterpedNIRWave[iThisSample][2][r]))/vThisThickness
							wTransferWave[iSample][0][] = wInterpedNIRWave[iThisSample][0][r]
						else
							wTransferWave[iSample][][] = nan
						endif
					endfor
					COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sWaveLengthLabel+";"+sIntensityLabel,-1,2,sScaleDataType=sWaveLengthLabel)
				endfor
			endif
		endif	
	endif

	//sEnergy
	string sEnergyTag
	if(!stringmatch(sEnergy,"Skip"))//not skipping energy scale
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
			if(bNIRR==1||bNIRT==1)//NIR data
				sEnergyTag = "NIR_"+sEnergy
				redimension/N=(-1,1,dimsize(wInterpedNIRWave,2)) wTransferWave
				wTransferWave[][0][] = nan
				wTransferWave[][0][] = wInterpedNIRWave[(p+iLibrary*vTotalSamples)][0][r]
				//convert nm to eV
				wTransferWave[][0][] = 1.2398/(wTransferWave[p][0][r]*1E-3)
				COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sEnergyTag,-1,2)
			endif
			if(bUVIR==1||bUVIT==1)//UVI data
				sEnergyTag = "UVI_"+sEnergy
				redimension/N=(-1,1,dimsize(wInterpedUVIWave,2)) wTransferWave
				wTransferWave[][][] = nan
				wTransferWave[][0][] = wInterpedUVIWave[(p+iLibrary*vTotalSamples)][0][r]
				//convert nm to eV
				wTransferWave[][0][] = 1.2398/(wTransferWave[p][0][r]*1E-3)
				COMBI_GiveData(wTransferWave,sProject,sThisLibrary,sEnergyTag,-1,2)
			endif
		endfor
	endif
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source Folder: "+sThisLoadFolder
	sLogEntry2 = "Libraries in UVIT File: "+sUVIT
	sLogEntry3 = "Libraries in UVIR File: "+sUVIR
	sLogEntry4 = "Libraries in NIRT File: "+sNIRT
	sLogEntry5 = "Libraries in NIRR File: "+sNIRR
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	COMBI_Add2Log(sProject,sFromMappingGrid,"NREL_UVVisNIR",1,sLogText)
	
	//kill loaded waves
	killwaves/Z wUVITIn, wUVIRIn, wNIRRIn, wNIRTIn, wTransferWave
	killwaves/Z wInterpedNIRWave, wInterpedUVIWave, wTempXWave, wTempYWave

		//if plot on loading
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		for(iLibrary=0;iLibrary<vTotalLibraries;iLibrary+=1)
			sThisLibrary = stringfromlist(iLibrary,sFromMappingGrid)
			if(bNIRR==1)//NIR data
				NREL_UVVisNIR_MakeA3DXRDPlotFromScaledWave(sProject,sThisLibrary,"NIR_"+sRef,"Wavelength (nm)","Fraction Reflected")
			endif
			if(bNIRT==1)//NIR data
				NREL_UVVisNIR_MakeA3DXRDPlotFromScaledWave(sProject,sThisLibrary,"NIR_"+sTran,"Wavelength (nm)","Fraction Reflected")
			endif
			if(bUVIR==1)//UVI data
				NREL_UVVisNIR_MakeA3DXRDPlotFromScaledWave(sProject,sThisLibrary,"UVI_"+sRef,"Wavelength (nm)","Fraction Reflected")
			endif
			if(bUVIT==1)//UVI data
				NREL_UVVisNIR_MakeA3DXRDPlotFromScaledWave(sProject,sThisLibrary,"UVI_"+sTran,"Wavelength (nm)","Fraction Reflected")
			endif
		endfor
	endif
	
end

function COMBI_NREL_UVVisNIR()
	COMBI_GiveGlobal("sInstrumentName","NREL_UVVisNIR","COMBIgor")
	COMBI_InstrumentDefinition()
end


function NREL_UVVisNIR_MakeA3DXRDPlotFromScaledWave(sProject,sLibrary,sVectorData,sScaleLabel,sZLabel)
	string sProject,sLibrary,sVectorData,sScaleLabel,sZLabel
	string sFont = Combi_GetGlobalString("sFontOption", "COMBIgor")
	Killwindow/Z $sProject+sLibrary+sVectorData+"Gizmo"
	NewGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo"/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" stopUpdates
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" opName=rotatation, operation=rotate,data={40,0,0,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" opName=rotatation2, operation=rotate,data={-30,0,1,0}
	AppendToGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" DefaultSurface=$"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sVectorData,name=Data
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=Data,objectType=surface,property={surfaceCTab,Rainbow}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={2,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={4,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={6,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={7,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={10,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={11,visible,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={2,ticks,2}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,ticks,3}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabel,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelText,"Sample"}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelText,sScaleLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelText,sZLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelText,sZLabel}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelCenter,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelDistance,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelScale,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelTilt,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelFont,sFont}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelFont,sFont}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelFont,sFont}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelFont,sFont}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,axisLabelFlip,0}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={3,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={5,labelBillboarding,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={0,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={1,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={8,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" ModifyObject=axes0,objectType=Axes,property={9,axisColor,0.533333,0.533333,0.533333,1}
	ModifyGizmo/N=$sProject+sLibrary+sVectorData+"Gizmo" resumeUpdates
	ColorScale/C/N=text0/F=0/A=MT/X=0.00/Y=5.00 vert=0,side=2,width=300,height=10,surfaceFill=Data,font=sFont
	ColorScale/C/N=text0 sScaleLabel
end