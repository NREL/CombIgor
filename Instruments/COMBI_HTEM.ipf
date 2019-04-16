#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma IgorVersion = 8.00
#pragma version = 0.1
#pragma ModuleName = COMBIToolsHTEM

#include <Strings as Lists> menus=0
#include <String Substitution> menus=0
#include <File Name Utilities> menus=0


// Development Notes:
// Nov. 13, 2018:
// 1. fixed infinite loop issue if final sample level token is for simple numerical data and not array
// 2. fixed issue that changing API Root only updated active pkg struct def and not project specific version
// 3. Fixed load problem for PDAC_COM1_01740 (Lib ID 7455) which is only available on internal API.  Some tokens mixture of null and actual data.

// Package constants
Static Constant kMaxStructStr = 400
Static Constant kVersionNumber = 0.2
Static StrConstant ksModuleName = "COMBIToolsHTEM"
Static StrConstant ksInstrumentDF = "root:Packages:COMBIgor:Instruments:"
Static StrConstant ksPkgDF = "root:Packages:COMBIgor:Instruments:HTEM:"
Static StrConstant ksInstrumentName = "HTEM"

// Standard Data Fields To Load
Static StrConstant ksVectorNumericalDataKeys = "xrd_angle;xrd_background;xrd_intensity;xrf_concentration;fpm_voltage_volts;fpm_current_amps;xyz_mm;"
Static StrConstant ksVectorTextDataKeys = "xrf_elements;xrf_compounds;"
Static StrConstant ksScalarNumericalDataKeys = "id;sample_id;position;thickness;fpm_sheet_resistance;fpm_standard_deviation;fpm_resistivity;fpm_conductivity;peak_count;opt_average_vis_trans;opt_direct_bandgap;"
Static StrConstant ksPossibleOpticalDataKeys = "uvir;uvit;nirr;nirt;"
Static StrConstant ksOpticalSpectraComponents = "wavelength;response;"
Static StrConstant ksLibLevelNumDataStoredAsString = "deposition_sample_time_min;deposition_initial_temp_c;deposition_growth_pressure_mtorr;"

Static Strconstant ksAPIRoot_Public = "https://htem-api.nrel.gov/api"
Static Strconstant ksAPIRoot_NREL = "https://app-test.hpc.nrel.gov:8095/api"

// for COMBIgor operation
function/S HTEM_Descriptions(sGlobalName)
	string sGlobalName
	string sInstrumentName = "HTEM"
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrumentName+"_Globals"
	string sReturnstring = ""
	strswitch(sGlobalName)
		case "InInstrumentMenu":
			twGlobals[1][0] = "No"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "HTEM":
			sReturnstring = "HTEM Database"
			break
		case "bHTEMKeys":
			sReturnstring = "Load HTEM ID Keys?"
			break
		case "b4PointProbe":
			sReturnstring = "Load 4 Point Probe Data?"
			break
		case "bUVVisNIRData":
			sReturnstring = "Load UV Vis NIR Data?"
			break
		case "bXRDData":
			sReturnstring = "Load XRD Data?"
			break
		case "bXRFData":
			sReturnstring = "Load XRF Data?"
			break
		case "bMetaData":
			sReturnstring = "Load Meta Data?"
			break
		case "bLibraryData":
			sReturnstring = "Load Library Data?"
			break
		case "sDataBase2Use":
			sreturnString = "HTEM version:"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end


// Commands to be re-worked into standard COMBIgor Interface
Menu "COMBIgor"
	SubMenu "Instruments"
		SubMenu "HTEM"
			"Fetch Library",/Q, COMBIToolsHTEM#HTEMInstrumentAccess()
			SubMenu "Find Libraries"
//				"Select HTEM Database",/Q, COMBIToolsHTEM#ChoseHTEMDB()
				"Select HTEM Database",/Q, COMBIToolsHTEM#ChoseHTEMDBForCurrentProject()
				SubMenu "Select Libraries"
					"1. Get Info for All Libraries",/Q, COMBIToolsHTEM#BuildAllLibsTable()
					"2. Down Select Using Filter Function",/Q, COMBIToolsHTEM#DownSelectUsingFilterFunction()
					"3. Further Refine Using Focus Table",/Q, COMBIToolsHTEM#DownSelectUsingFocusTable()
					"-"
					"Print Lib Info Wave Column Dimension Labels",/Q, COMBIToolsHTEM#PrintLibInfoTableColumnDimLabels()
					"Print Example Filter Function",/Q, COMBIToolsHTEM#PrintExampleFilterFunction()
				End
				SubMenu "Get Data From HTEM"
					"Fetch Data for List of Library ID's",/Q, COMBIToolsHTEM#MenuGetDataForLibList()
				End
//				SubMenu "HTEM Dev Tools"
//					"Init HTEM Tool", COMBIToolsHTEM#Init4COMBIgor()		// Now uses special init version for COMBIgor environment
//					"Check Init", COMBIToolsHTEM#CheckInit()
//					"-"
//			 		"Set DF to HTEM", COMBIToolsHTEM#SetDFToPkgDF()
//			 		"Bounce DF", COMBIToolsHTEM#BounceDF()
//					"Set DF to Root", COMBIToolsHTEM#SetDFToRoot()
//					"-"						
//					"Print Pkg Struct", COMBIToolsHTEM#PrintPkgStruct()	
//					"Update Active Pkg Struct from Current Project", COMBIToolsHTEM#UpdateActivePkgStructFromProjectDef()
				End
			end
		End
	End
End

// Put Package Structure Def Here
Static Structure HTEMPkgStruct
	variable	Version
	char savDF[kMaxStructStr]
	char sAPIRoot[kMaxStructStr]
	char sNameLibInfoWave[kMaxStructStr]
	char sNameFilterFcn[kMaxStructStr]
	char sNameVarParmWave[kMaxStructStr]
	char sNameTxtParmWave[kMaxStructStr]
	char sNameLibFocusInfoWave[kMaxStructStr]
	char sSelectedLibsList[kMaxStructStr]
	char sNameSelectedLibsList[kMaxStructStr]
	char sVectorNumericalDataKeys[kMaxStructStr]
	char sVectorTextDataKeys[kMaxStructStr]
	char sScalarNumericalDataKeys[kMaxStructStr]
	char sPossibleOpticalDataKeys[kMaxStructStr]
	char sOpticalSpectraComponents[kMaxStructStr]
	char sLibLevelNumDataStoredAsString[kMaxStructStr]
EndStructure

// Updated for use in COMBIgor environement
Static Function CheckInit()
	string savDF, sPkgStruct
	variable version
	STRUCT HTEMPkgStruct Pkg
	
	savDF = GetDataFolder(1)
	if (!(DataFolderExists(ksPkgDF)))
		Init4COMBIgor()
		return(1)
	endif
	
	sPkgStruct = COMBI_GetInstrumentString(ksInstrumentName,"sPkgStruct", "COMBIgor")
	if (!cmpstr(sPkgStruct, ""))
		Init4COMBIgor()
		return(2)
	endif
	
	StructGet/S Pkg, sPkgStruct
	version = Pkg.version
	if (version < kVersionNumber)
		Init4COMBIgor()
		return(3)
	endif
	return(0)
end


Static Function [DFREF dfrSave, DFREF dfrPkgDF, DFREF dfrLibInfo, DFREF dfrDataTmp] GetHTEMDFRefs()
	DFREF dfrSave = GetDataFolderDFR()
	SetDataFolder ksPkgDF; 
		DFREF dfrPkgDF = GetDataFolderDFR()
		SetDataFolder LibInfo
		DFREF dfrLibInfo = GetDataFolderDFR()

	SetDataFolder dfrPkgDF; SetDataFolder DataTmp
		DFREF dfrDataTmp = GetDataFolderDFR()
	SetDataFolder dfrSave
	
	return [dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp]
End

Static Function [STRUCT HTEMPkgStruct Pkg] BuildPkgStruct()
	string sPkgStruct
	sPkgStruct = COMBI_GetInstrumentString(ksInstrumentName,"sPkgStruct", "COMBIgor")
	StructGet/S Pkg, sPkgStruct
end

Static Function [STRUCT HTEMPkgStruct Pkg] BuildPkgStructForProject(String sProject)
	string sPkgStruct

//	sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")

//	sPkgStruct = COMBI_GetInstrumentString(ksInstrumentName,"sPkgStruct", "COMBIgor")
	sPkgStruct = COMBI_GetInstrumentString(ksInstrumentName,"sPkgStruct", sProject )
	StructGet/S Pkg, sPkgStruct
//	print Pkg
end

Function TestBuildPkgStructForProject(sProject)
	string sProject
	
	STRUCT HTEMPkgStruct Pkg
	
	[Pkg] = BuildPkgStructForProject(sProject)
	Print Pkg
	
end


Static Function SavePkgStructure(Pkg)
	Struct HTEMPkgStruct &Pkg
	string sPkgStruct
	StructPut/S Pkg, sPkgStruct
	COMBI_GiveInstrumentGlobal(ksInstrumentName,"sPkgStruct",sPkgStruct, "COMBIgor")
End

Static Function SavePkgStructureToProject(Pkg, sProject)
	Struct HTEMPkgStruct &Pkg
	String sProject
	string sPkgStruct
	StructPut/S Pkg, sPkgStruct
	COMBI_GiveInstrumentGlobal(ksInstrumentName,"sPkgStruct",sPkgStruct, sProject)
End


Static Function BounceDF()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	string savDF, priorDF
	priorDF = Pkg.savDF
	savDF = GetDataFolder(1)
	SetDataFolder priorDF
	Pkg.savDF = savDF

	SavePkgStructure(Pkg)
End

Static Function SetDFToRoot()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	string savDF = GetDataFolder(1)
	Pkg.savDF = savDF
	SetDataFolder "root:"
	
	SavePkgStructure(Pkg)
End


Function PrintPkgStruct()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	Print Pkg
End


Function PrintPkgStructForProject(sProject)
	string sProject
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStructForProject(sProject)

	Print Pkg
End


Static Function SetDFToPkgDF()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	string savDF = GetDataFolder(1)
	SetDataFolder ksPkgDF
	Pkg.savDF = savDF

	SavePkgStructure(Pkg)
End

// Example Filter Function
Function Contains_ZnSnTi_Filter(pSampleLib, wSampleLibsTable, wVarParms, wTxtParms)
	variable pSampleLib
	wave/T wSampleLibsTable
	wave 	wVarParms
	wave/T wTxtParms
	
	variable ContainsZn, ContainsSn, ContainsTi, val
	string sElementsInLib
	
	sElementsInLib = wSampleLibsTable[pSampleLib][%Elements]
	
	ContainsZn = WhichListItem("Zn", sElementsInLib) >= 0
	ContainsSn = WhichListItem("Sn", sElementsInLib) >= 0
	ContainsTi = WhichListItem("Ti", sElementsInLib) >= 0
	
	val = ContainsZn && ContainsSn && ContainsTi
	
	return (val)
end


//	sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")

// Put Menu Access Routines Here

Static Function ChoseHTEMDB()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	string sAPIRoot
	sAPIRoot = Pkg.sAPIRoot
	
	Prompt sAPIRoot, "Select HTEM DB: ", popup, "Public;NREL Internal"
	DoPrompt "Chose API To Use", sAPIRoot
	
	strswitch(sAPIRoot)	
		case "Public":
			Pkg.sAPIRoot = ksAPIRoot_Public
			break	
		case "NREL Internal":	
			Pkg.sAPIRoot = ksAPIRoot_NREL
			break
	endswitch
	
	print "HTEM API Root set to :",Pkg.sAPIRoot
	SavePkgStructure(Pkg)
End

Static Function ChoseHTEMDBForCurrentProject()
	string sProject
	
	sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	ChoseHTEMDBForProject(sProject)
	UpdateActivePkgStructFromProjectDef()
End

Static Function ChoseHTEMDBForProject(sProject)
	String sProject
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStructForProject(sProject)

	string sAPIRoot
	sAPIRoot = Pkg.sAPIRoot
	
	Prompt sAPIRoot, "Select HTEM DB: ", popup, "Public;NREL Internal"
	DoPrompt "Chose API To Use", sAPIRoot
	
	strswitch(sAPIRoot)	
		case "Public":
			Pkg.sAPIRoot = ksAPIRoot_Public
			break	
		case "NREL Internal":	
			Pkg.sAPIRoot = ksAPIRoot_NREL
			break
	endswitch
	
	print "HTEM API Root set to :",Pkg.sAPIRoot
	SavePkgStructureToProject(Pkg, sProject)
End


Static Function BuildAllLibsTable()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	
	string sAPIRoot, s1, sURL, sLibWaveName
	variable nLibs
	
	sAPIRoot = Pkg.sAPIRoot
	sLibWaveName = Pkg.sNameLibInfoWave
	sURL = sAPIRoot + "/sample_library"
	
	Prompt sLibWaveName, "LibInfo Wave Name for Sample Library Table: "
	DoPrompt "", sLibWaveName
	Pkg.sNameLibInfoWave = sLibWaveName

	s1 = fetchurl(sURL)
	nLibs = MakeHTEMSampleTable(s1, sLibWaveName)

	SavePkgStructure(Pkg)
End

Static Function DownSelectUsingFilterFunction()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	DFREF dfrSave = GetDataFolderDFR()
	DFREF dfrTmpDF = NewFreeDataFolder()
	SetDataFolder ksPkgDF; 
		DFREF dfrPkgDF = GetDataFolderDFR()
		SetDataFolder LibInfo
		DFREF dfrLibInfo = GetDataFolderDFR()
	SetDataFolder dfrPkgDF; SetDataFolder DataTmp
		DFREF dfrDataTmp = GetDataFolderDFR()
	SetDataFolder dfrSave
	
	string sNameLibInfoWave, sNameFilterFcn, sNameVarParmsWave, sNameTxtParmsWave, sNameSampleList, sNameLibFocusInfoWave
	string sFilterFcnList, sLibInfoWaveList
	
	SetDataFolder dfrLibInfo
		sLibInfoWaveList = wavelist("*", ";", "DIMS:2,TEXT:1")
	SetDataFolder dfrSave

	sNameLibInfoWave = Pkg.sNameLibInfoWave
	sNameFilterFcn = Pkg.sNameFilterFcn
	sNameVarParmsWave = Pkg.sNameVarParmWave
	sNameTxtParmsWave = Pkg.sNameTxtParmWave
	sNameLibFocusInfoWave= sNameLibInfoWave + "_Focus"
	sFilterFcnList = FunctionList("*filter*", ";", "KIND:2,NPARAMS:4")
	sNameSampleList = Pkg.sNameSelectedLibsList

	Prompt sNameSampleList, "Name of String for Filtered Sample List :"
	Prompt sNameLibInfoWave, "Wave Name for Sample Library Table: ", popup, sLibInfoWaveList
	Prompt sNameFilterFcn, "Select Filter Function: ", popup, sFilterFcnList
	Prompt sNameVarParmsWave, "Wave Name for Optional Variable Parameters: "
	Prompt sNameTxtParmsWave, "Wave Name for Optional Text Parameters: "
	Prompt sNameLibFocusInfoWave, "Wave Name for Filter Focused Sample Library Table: "
	
	DoPrompt "Setup Down Selection using Filter Function", sNameSampleList, sNameLibInfoWave, sNameLibFocusInfoWave, sNameFilterFcn, sNameVarParmsWave, sNameTxtParmsWave
	
	Pkg.sNameLibInfoWave = sNameLibInfoWave
	Pkg.sNameFilterFcn = sNameFilterFcn
	Pkg.sNameVarParmWave = sNameVarParmsWave
	Pkg.sNameTxtParmWave = sNameTxtParmsWave
	Pkg.sNameLibFocusInfoWave = sNameLibFocusInfoWave
	Pkg.sNameSelectedLibsList = sNameSampleList
	
	SetDataFolder dfrLibInfo
		Wave/Z/T wLibInfo = $sNameLibInfoWave
		if (!WaveExists(wLibInfo))
			Print "Library Info Wave Does Not Exist"
			return(0)
		endif
	SetDataFolder dfrSave

	SVAR/Z sSampleList = $sNameSampleList
	if (!SVAR_Exists(sSampleList))
		String/G $sNameSampleList
		SVAR sSampleList = $sNameSampleList
	endif	

	if (!cmpstr(sNameVarParmsWave, ""))
		SetDataFolder dfrTmpDF
			Make/O/n=0 VarParmsDummy
			Wave wVarParms = VarParmsDummy
		SetDataFolder dfrSave
	else
		Wave/Z wVarParms = $sNameVarParmsWave
		if (!WaveExists(wVarParms))
			Print "Variable Parameter Wave Does Not Exist"
			return(0)
		endif
	endif
	
	if (!cmpstr(sNameTxtParmsWave, ""))
		SetDataFolder dfrTmpDF
			Make/O/T/n=0 TxtParmsDummy
			Wave/T wTxtParms = TxtParmsDummy
		SetDataFolder dfrSave
	else
		Wave/Z/T wTxtParms = $sNameTxtParmsWave
		if (!WaveExists(wTxtParms))
			Print "Text Parameter Wave Does Not Exist"
			return(0)
		endif
	endif
	
	sSampleList = SelectSamples2(wLibInfo, $sNameFilterFcn, wVarParms, wTxtParms)
	Pkg.sSelectedLibsList = sSampleList
	KillDataFolder dfrTmpDF
	CreateFocusedSelectionTable(sSampleList, wLibInfo, sNameLibFocusInfoWave)

	SavePkgStructure(Pkg)
	Print "Selected Libraries = ", sSampleList
	Print "Type any charactier in Select column to further refine list"
End


Static Function DownSelectUsingFocusTable()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()

	DFREF dfrSave = GetDataFolderDFR()
	SetDataFolder ksPkgDF; 
		DFREF dfrPkgDF = GetDataFolderDFR()
		SetDataFolder LibInfo
		DFREF dfrLibInfo = GetDataFolderDFR()
	SetDataFolder dfrSave

	string sNameLibFocusInfoWave, sNameSelectedLibsList, sListLibFocusInfoWaves
	
	sNameLibFocusInfoWave = Pkg.sNameLibFocusInfoWave
	sNameSelectedLibsList = Pkg.sNameSelectedLibsList
	
	SetDataFolder dfrLibInfo
		sListLibFocusInfoWaves = wavelist("*", ";", "DIMS:2,TEXT:1")
	SetDataFolder dfrSave

	Prompt sNameLibFocusInfoWave, "Name of Library Info Focus Table Wave: ",popup, sListLibFocusInfoWaves
	Prompt sNameSelectedLibsList, "Name of String for Focused Library List: "
	
	DoPrompt "Setup Down Selection Using Focus Table Wave", sNameLibFocusInfoWave, sNameSelectedLibsList
	
	SVAR/Z sSelectedLibs = $sNameSelectedLibsList
	if (!SVAR_Exists(sSelectedLibs))
		String/G $sNameSelectedLibsList
		SVAR sSelectedLibs = $sNameSelectedLibsList
	endif	

	SetDataFolder dfrLibInfo
		Wave/Z/T wLibFocusTable = $sNameLibFocusInfoWave
		if (!WaveExists(wLibFocusTable))
			Print "Library Focus Talbe  Wave Does Not Exist"
			return(0)
		endif
	SetDataFolder dfrSave
	
	sSelectedLibs = SelectionListFromTable(wLibFocusTable)
	
	Pkg.sNameLibFocusInfoWave = sNameLibFocusInfoWave
	Pkg.sNameSelectedLibsList = sNameSelectedLibsList
	Pkg.sSelectedLibsList = sSelectedLibs
	SavePkgStructure(Pkg)
	Print "Selected Libraries: ", sSelectedLibs
	Print "Name of Selected Libraries List String: ", sNameSelectedLibsList
End


Static Function PrintLibInfoTableColumnDimLabels()
	CheckInit(); STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	
	DFREF dfrSave = GetDataFolderDFR()
	SetDataFolder ksPkgDF; 
		DFREF dfrPkgDF = GetDataFolderDFR()
		SetDataFolder LibInfo
		DFREF dfrLibInfo = GetDataFolderDFR()
	SetDataFolder dfrSave


	string sNameLibInfoWave, sColDimLabel
	variable nCols, iCol
	
	sNameLibInfoWave = Pkg.sNameLibInfoWave
	SetDataFolder dfrLibInfo
		Wave/Z/T wLibInfoWave = $sNameLibInfoWave
		if (!WaveExists(wLibInfoWave))
			Print "Library Info Table Wave Does Not Exist"
			return(0)
		endif
	SetDataFolder dfrSave

	nCols = DimSize(wLibInfoWave, 1)
	Print "Library Info Table Wave = ", sNameLibInfoWave
	Print "Column Dimension Labels:"
	for (iCol = 0; iCol < nCols; iCol += 1)
		sColDimLabel = GetDimLabel(wLibInfoWave, 1, iCol)
		Print " ", iCol, ":", sColDimLabel
	Endfor
End

Static Function PrintExampleFilterFunction()

Print "Copy and Paste Template Function into Procedure Window then Rename"
Print "	"
	Print "Function Example_HTEMFilter(pSampleLib, wSampleLibsTable, wVarParms, wTxtParms)"
	Print "	variable pSampleLib"
	Print"	wave/T wSampleLibsTable"
	Print"	wave 	wVarParms"
	Print"	wave/T wTxtParms"
	Print"	"
	Print"	variable ContainsZn, ContainsSn, ContainsTi, val"
	Print"	string sElementsInLib"
	Print"	"
	Print"	sElementsInLib = wSampleLibsTable[pSampleLib][%Elements]"
	Print"	"
	Print"	ContainsZn = WhichListItem(\"Zn\", sElementsInLib) >= 0"
	Print"	ContainsSn = WhichListItem(\"Sn\", sElementsInLib) >= 0"
	Print"	ContainsTi = WhichListItem(\"Ti\", sElementsInLib) >= 0"
	Print"	"
	Print"	val = ContainsZn && ContainsSn && ContainsTi"
	Print"	"
	Print"	return (val)"
	Print"end"
End

// Regular Routines Below

Static Function MenuGetDataForLibList()
	STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	
	string sListLibListStrings, sLibListName
	
	sLibListName = Pkg.sNameSelectedLibsList
	
	Prompt sLibListName, "Select Library List: "
	DoPrompt "Get Data From HTEM", sLibListName
	
	SVAR sLibList = $sLibListName
	GetDataForLibList(sLibList)
	
	Pkg.sNameSelectedLibsList = sLibListName
	SavePkgStructure(Pkg)
end

Static Function GetDataForLibList(sLibList)
	String sLibList
	
	Variable nLibs, iLib
	String sLibID
	
	nLibs = ItemsInList(sLibList)
	for (iLib = 0; iLib < nLibs; iLib += 1)
		sLibID = StringFromList(iLib, sLibList)
		GetDataForLib(sLibID)
	endfor
end

Static Function GetDataForLib(sLibID)
	String sLibID
	STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	
	string sSamplesList, sXRFElementsList

	sSamplesList = AddLibInfoToLibDF2(sLibID)
	GetDataSaveToLibDF(sLibID)
End

Static Function/DF CheckCreateChildDF(sDFName)
	string sDFName
	
	DFREF dfrSave = GetDataFolderDFR()
	if (!DataFolderExists(sDFName))
		NewDataFolder/O $sDFName
	endif
	SetDataFolder $sDFName
		DFREF dfrChildDF = GetDataFolderDFR()
	SetDataFolder dfrSave
	return dfrChildDF
end

Static Function/S AddLibInfoToLibDF2(strLibID)
 	string strLibID
	STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	DFREF dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp; [dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp] = GetHTEMDFRefs()
 	
	DFREF dfrTmpDF = NewFreeDataFolder()
 		
	String sLibDF, sAPI_URL, sAPI_Return, sSampleID, sElement, sElementList, sTokenKey, sLibDataName, StrVal, sSampleInfo
	Variable pSampleIDToken, iSample, nElements, iElement, nTokens, iToken, pToken, vTokenType, nArraySize, vArrayType, NumVal
	
	sLibDF = "LK_"+strLibID
	SetDataFolder dfrDataTmp
		DFREF dfrLibDF = CheckCreateChildDF(sLibDF)
		SetDataFolder dfrLibDF
			SVAR/Z SamplesList = SamplesList
				if (!SVAR_Exists(SamplesList))
					String/G SamplesList = ""	
				endif
			SVAR /Z XRF_ElementsList = XRF_ElementsList
				if (!SVAR_Exists(XRF_ElementsList))
					String/G XRF_ElementsList = ""	
				endif
			SVAR /Z sLibID = sLibID
				if (!SVAR_Exists(sLibID))
					String/G sLibID = strLibID	
				endif
			SVAR /Z sPDAC = sPDAC
				if (!SVAR_Exists(sPDAC))
					String/G sPDAC = ""	
				endif
			SVAR /Z sLibraryLevelTokens = sLibraryLevelTokens
				if (!SVAR_Exists(sLibraryLevelTokens))
					String/G sLibraryLevelTokens = ""	
				endif
			SVAR /Z sAvailableLibraryLevelTokens = sAvailableLibraryLevelTokens
				if (!SVAR_Exists(sAvailableLibraryLevelTokens))
					String/G sAvailableLibraryLevelTokens = ""	
				endif
			SVAR /Z sSampleLevelTokens = sSampleLevelTokens
				if (!SVAR_Exists(sSampleLevelTokens))
					String/G sSampleLevelTokens = ""	
				endif
			
				
			NVAR /Z NumSamples = NumSamples
				if (!NVAR_Exists(NumSamples))
					Variable/G NumSamples = nan
				endif
			NVAR /Z LibNum = LibNum
				if (!NVAR_Exists(LibNum))
					Variable/G LibNum = nan
				endif
			NVAR /Z NumXRF_Elements = NumXRF_Elements
				if (!NVAR_Exists(NumXRF_Elements))
					Variable/G NumXRF_Elements = nan
				endif
			DFREF dfrLibDataDF = CheckCreateChildDF("LibData")
	SetDataFolder dfrSave

	sAPI_URL = Pkg.sAPIRoot + "/sample_library/" + sLibID
	sAPI_Return = fetchurl(sAPI_URL)

	SetDataFolder dfrTmpDF
		JSONSimple /Q /Z /MAXT=100 sAPI_Return
		Wave wTokenType = W_TokenType
		Wave wTokenSize = W_TokenSize
		Wave wTokenParent = W_TokenParent
		Wave/T wTokenText= T_TokenText
	SetDataFolder dfrSave

	// Get List of TokenKeys
	sLibraryLevelTokens = GetTokenKeyList(wTokenParent, wTokenText)

	// Get List of Samples
	pSampleIDToken = PointForKey("sample_ids", wTokenText)
	NumSamples = wTokenSize[pSampleIDToken+1]
	
	SamplesList = ""
	for (iSample = 0 ; iSample < NumSamples; iSample += 1)
		sSampleID = wTokenText[pSampleIDToken + 2 + iSample]
		SamplesList = AddListItem(sSampleID, SamplesList, ";", inf)
	endfor
	
	// Get PDAC String
	pSampleIDToken = PointForKey("pdac", wTokenText)
	sPDAC = wTokenText[pSampleIDToken+1]

	// Get Library Number
	pSampleIDToken = PointForKey("num", wTokenText)
	LibNum = str2num(wTokenText[pSampleIDToken+1])
	
	// Get XRF Elements List
	sElementList = ""
	pSampleIDToken = PointForKey("xrf_elements", wTokenText)
	nElements = wTokenSize[pSampleIDToken+1]
	for (iElement = 0; iElement < nElements; iElement += 1)
		sElement = wTokenText[pSampleIDToken + 2 + iElement]
		sElementList = AddListItem(sElement, sElementList, ";", inf)
	endfor
	XRF_ElementsList = sElementList
	NumXRF_Elements = nElements
	sAvailableLibraryLevelTokens = ""
	SetDataFolder dfrLibDataDF
		nTokens = ItemsInList(sLibraryLevelTokens)
		for (iToken = 0; iToken < nTokens; iToken += 1)
			sTokenKey = StringFromList(iToken, sLibraryLevelTokens)
			sLibDataName = "HTEM_" + sTokenKey
			pToken = PointForKey(sTokenKey, wTokenText)
			vTokenType = wTokenType[pToken+1]
//print "itoken = ",itoken, "ntokens = ",ntokens, "ptoken = ", ptoken, "vtokentype = ", vtokentype
			switch(vTokenType)	
				case 0: // number data
					NumVal = str2num(wTokenText[pToken+1])	
					variable/G $sLibDataName = NumVal
					if (NumDataExists(sTokenKey, NumVal))
						sAvailableLibraryLevelTokens = AddListItem(sTokenKey, sAvailableLibraryLevelTokens, ";", inf)
					endif					
					break
				case 3:	// string data
					StrVal =  wTokenText[pToken+1]
					if (WhichListItem(sTokenKey, Pkg.sLibLevelNumDataStoredAsString) == -1)	// normal case
						string/G $sLibDataName = StrVal
						if (StringDataExists(StrVal))
							sAvailableLibraryLevelTokens = AddListItem(sTokenKey, sAvailableLibraryLevelTokens, ";", inf)
						endif						
					else
						NumVal = str2num(StrVal)
						variable/G $sLibDataName = NumVal					
						if (NumDataExists(sTokenKey, NumVal))
							sAvailableLibraryLevelTokens = AddListItem(sTokenKey, sAvailableLibraryLevelTokens, ";", inf)
						endif					
					endif
					break
			case 2:	// array data (number vs. string tbd)
					// Call make array(wave) routine
					nArraySize = wTokenSize[pToken+1]
					vArrayType = wTokenType[pToken+2]
					if (vArrayType == 0) // numerical data
						Make/O/n=(nArraySize) $sLibDataName
						Wave wData = $sLibDataName
						wData[] = str2num(wTokenText[pToken+2+p])
						if (ArrayNumDataExists(wData))
							sAvailableLibraryLevelTokens = AddListItem(sTokenKey, sAvailableLibraryLevelTokens, ";", inf)
						endif
					elseif (vArrayType == 3) // string data
						Make/O/T/n=(nArraySize) $sLibDataName
						Wave/T wTextData = $sLibDataName
						wTextData[] = ReplaceNull(wTokenText[pToken+2+p])
						if (ArrayStringDataExists(wTextData))
							sAvailableLibraryLevelTokens = AddListItem(sTokenKey, sAvailableLibraryLevelTokens, ";", inf)
						endif
					endif
					break
			endswitch
		endfor
	SetDataFolder dfrSave
	
	sSampleID = StringFromList(0, SamplesList)
	sAPI_URL = Pkg.sAPIRoot + "/sample/" + sSampleID
	sAPI_Return = fetchurl(sAPI_URL)
	SetDataFolder dfrLibInfo
		sSampleLevelTokens = BuildTokenKeyList(sAPI_Return)
	SetDataFolder dfrSave

	KillDataFolder dfrTmpDF
	SavePkgStructure(Pkg)

	return(SamplesList)
End

Static Function ArrayNumDataExists(wData)
	Wave wData
	
	variable nPnts, iPnt
	
	nPnts = DimSize(wData,0)
	for (iPnt = 0; iPnt < nPnts; iPnt += 1)
		if (NumType(wData[iPnt]) != 2)	// an entry exitsts that is not a Nan
			return(1)
		endif	
	endfor
	return(0)
end

Static Function NumDataExists(sKey, NumVal)
	string sKey
	variable NumVal
	
	variable val
	
	if (!cmpstr(sKey[0,2],"has"))	// TokenKey starts with "has"
		val = (NumVal > 0)
	else
		val = (numtype(NumVal) != 2)
	endif
	return(val)
end

Static Function ArrayStringDataExists(wData)
	Wave/T wData
	
	variable nPnts, iPnt
	
	nPnts = DimSize(wData,0)
	for (iPnt = 0; iPnt < nPnts; iPnt += 1)
		if (StringDataExists(wData[iPnt]))	
			return(1)
		endif	
	endfor
	return(0)
end


Static Function StringDataExists(sStrVal)
	string sStrVal
	
	variable val
	
	if (!cmpstr(sStrVal,""))	// String is null string
		val = 0
	elseif (!cmpstr(sStrVal,"null"))
		val = 0
	else
		val = 1
	endif
	return(val)
end


Static Function/S ReplaceNull(sStringIn)
	string sStringIn
	
	if (!cmpstr(sStringIn,"null"))
		return("")
	else
		return(sStringIn)
	endif
end


Static Function PointForKey(sKey, wTokenText)
	string sKey
	wave/T wTokenText
	
	variable pKey, nTokens, iToken
	string sToken
	
	
	nTokens = DimSize(wTokenText, 0 )
	pKey = nTokens
	
	for (iToken = 0; iToken < nTokens; iToken += 1)
		sToken = wTokenText[iToken]
		if (!cmpstr(sToken, sKey))
			return(iToken)
		endif
	endfor
	return(-1)
	
end

Static Function/S GetTokenKeyList(wTokenParent, wTokenText)
	Wave wTokenParent
	Wave/T wTokenText
	
	variable nTokens, iToken
	string sTokenList
	
	sTokenList = ""
	nTokens = Dimsize(wTokenParent,0)
	for (iToken = 0; iToken < nTokens; iToken += 1)
		if (wTokenParent[iToken] == 0)
			sTokenList = AddListItem(wTokenText[iToken], sTokenList, ";", inf)
		endif
	endfor
	return(sTokenList)	
end

// Presumes appropriate LK_1234 DF alreaady exists in project and has been loaded with Lib level data
Static Function/S GetXRFandXRDtoLibDF(strLibID)
 	string strLibID

	STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	DFREF dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp; [dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp] = GetHTEMDFRefs()
 	
	DFREF dfrTmpDF = NewFreeDataFolder()
	
	String sLibDF, sAPI_URL, sAPI_Return, sSampleID, sElement, sElementList, sListTMP, sSampleDimLabel, sListTmp2
	Variable pSampleIDToken, iSample, nElements, iElement, nPntsXRD, iElemXRF, iPntXRD, PercentXRF
	
	sLibDF = "LK_"+strLibID
	SetDataFolder dfrDataTmp
		DFREF dfrLibDF = CheckCreateChildDF(sLibDF)
		SetDataFolder dfrLibDF
			SVAR SamplesList = SamplesList
			SVAR XRF_ElementsList = XRF_ElementsList
			NVAR NumSamples = NumSamples
			NVAR NumXRF_Elements = NumXRF_Elements
			
			sSampleID = StringFromList(0, SamplesList)
			sAPI_URL = Pkg.sAPIRoot + "/sample/" + sSampleID
			sAPI_Return = fetchurl(sAPI_URL)

			sListTmp = GetDataListFromSampleInfoString(sAPI_Return, "xrd_angle")
			nPntsXRD = itemsinlist(sListTmp, ",")
			
			make/O/n=(nPntsXRD, 4, NumSamples) LibXRD
				LibXRD = nan			
				SetDimLabel 1,0,Angle,LibXRD
				SetDimLabel 1,1,Bkg,LibXRD
				SetDimLabel 1,2,Inten,LibXRD
				SetDimLabel 1,3,IntenBkgSub,LibXRD
			
			make/O/n=(NumXRF_Elements, 2, NumSamples) LibXRF
				LibXRF = nan			
				SetDimLabel 1,0,Percent,LibXRF
				SetDimLabel 1,1,Norm1,LibXRF
				for (iElemXRF = 0; iElemXRF < NumXRF_Elements; iElemXRF += 1)
						sElement = StringFromList(iElemXRF, XRF_ElementsList)
						SetDimLabel 0,iElemXRF,$sElement,LibXRF
				endfor

			for (iSample = 0; iSample < NumSamples; iSample += 1)
				sSampleID = StringFromList(iSample, SamplesList)
				sSampleDimLabel = "SK_" + sSampleID
				SetDimLabel 2, iSample, $sSampleDimLabel, LibXRD, LibXRF
			endfor
			
			// assign the 2-theta values.  same for all samples in lib
			for (iPntXRD = 0; iPntXRD < nPntsXRD; iPntXRD += 1)
				LibXRD[iPntXRD][%Angle][] = str2num(StringFromList(iPntXRD, sListTmp, ","))
			endfor
						
			// get the measured and bkg data
			for (iSample = 0; iSample < NumSamples; iSample +=1)
				sSampleID = StringFromList(iSample, SamplesList)
				sAPI_URL = Pkg.sAPIRoot + "/sample/" + sSampleID
				sAPI_Return = fetchurl(sAPI_URL)
				
				sListTmp = GetDataListFromSampleInfoString(sAPI_Return, "xrd_background")
				for (iPntXRD = 0; iPntXRD < nPntsXRD; iPntXRD += 1)
					LibXRD[iPntXRD][%Bkg][iSample] = str2num(StringFromList(iPntXRD, sListTmp, ","))
				endfor

				sListTmp = GetDataListFromSampleInfoString(sAPI_Return, "xrd_intensity")
				for (iPntXRD = 0; iPntXRD < nPntsXRD; iPntXRD += 1)
					LibXRD[iPntXRD][%Inten][iSample] = str2num(StringFromList(iPntXRD, sListTmp, ","))
				endfor

				sListTmp = GetDataListFromSampleInfoString(sAPI_Return, "xrf_elements")
				sListTmp2 = GetDataListFromSampleInfoString(sAPI_Return, "xrf_concentration")
				
				for (iElemXRF = 0; iElemXRF < NumXRF_Elements; iElemXRF += 1)
					sElement = RemovePossibleQuotes(StringFromList(iElemXRF, sListTmp, ","))
					PercentXRF = str2num(StringFromList(iElemXRF, sListTmp2, ","))
					LibXRF[%$sElement][%Percent][iSample] = str2num(StringFromList(iElemXRF, sListTmp2, ","))
				endfor
			endfor
			
			LibXRD[][%IntenBkgSub][] = 	LibXRD[p][%Inten][r] - LibXRD[p][%Bkg][r] 
			LibXRF[][%Norm1][] = 	LibXRF[p][%Percent][r]/100
	SetDataFolder dfrSave

	SavePkgStructure(Pkg)
	return(sListTmp)
End

Static Function/S GetDataSaveToLibDF(strLibID)
 	string strLibID

	STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	DFREF dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp; [dfrSave, dfrPkgDF, dfrLibInfo, dfrDataTmp] = GetHTEMDFRefs()
	
	String sLibDF, sAPI_URL, sAPI_Return, sSampleID, sElement, sElementList, sListTMP, sSampleDimLabel, sListTmp2, sMessage, sSpectraKey
	Variable pSampleIDToken, iSample, nElements, iElement, nPntsXRD, iElemXRF, iPntXRD, PercentXRF, nDataItems, iDataItem, nPossibleSpectra, iSpectra
	
	sLibDF = "LK_"+strLibID
	SetDataFolder dfrDataTmp
		DFREF dfrLibDF = CheckCreateChildDF(sLibDF)
		SetDataFolder dfrLibDF
			SVAR SamplesList = SamplesList
			SVAR XRF_ElementsList = XRF_ElementsList
			NVAR NumSamples = NumSamples
			NVAR NumXRF_Elements = NumXRF_Elements
			DFREF dfrLibVectorDF = CheckCreateChildDF("Vector")
			DFREF dfrLibScalarDF = CheckCreateChildDF("Scalar")
			
			//make progress window in middle of screen
			string sIgorEnviromentInfo = IgorInfo(0)
			string sScreenInfo = StringByKey("SCREEN1", sIgorEnviromentInfo)
			int vWinLeft = str2num(stringfromlist(3,sScreenInfo,","))/2-100
			int vWinTop = str2num(stringfromlist(4,sScreenInfo,","))/2-30
			int vWinRight = str2num(stringfromlist(3,sScreenInfo,","))/2+100
			int vWinBottom = str2num(stringfromlist(4,sScreenInfo,","))/2+30
			NewPanel/N=FetchProgress/W=(vWinLeft,vWinTop,vWinRight,vWinBottom) as "Fetch Progress"
			SetDrawLayer UserBack
			SetDrawEnv fsize= 14
			SetDrawEnv textxjust= 1,textyjust= 1
			SetDrawEnv save
			DrawText 100,20,"Fetching Libray # "+strLibID
			ValDisplay valdispProgress pos={10,30},size={180,40},frame=4,appearance={native}
			ValDisplay valdispProgress limits={0,44,0},barmisc={0,1},bodyWidth= 180
			int iSamplesLoadedNow = 0
			Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSamplesLoadedNow)
			DoUpdate/W=FetchProgress

			// Get Info for 1st Sample (index = 0)
			sSampleID = StringFromList(0, SamplesList)
			sAPI_URL = Pkg.sAPIRoot + "/sample/" + sSampleID
			sAPI_Return = fetchurl(sAPI_URL)
			
			// Get Vector Numerical Data.  Since iSample = 0 will build waves.
			nDataItems = ItemsInList(Pkg.sVectorNumericalDataKeys)
			for (iDataItem = 0; iDataItem < nDataItems; iDataItem += 1)
				GetVectorNumericalData(sAPI_Return, StringFromList(iDataItem,Pkg.sVectorNumericalDataKeys), NumSamples, 0, dfrLibVectorDF)			
			endfor

			// Get Vector Text Data.  Since iSample = 0 will build waves.
			nDataItems = ItemsInList(Pkg.sVectorTextDataKeys)
			for (iDataItem = 0; iDataItem < nDataItems; iDataItem += 1)
				GetVectorTextData(sAPI_Return, StringFromList(iDataItem,Pkg.sVectorTextDataKeys), NumSamples, 0, dfrLibVectorDF)			
			endfor
			
			// Get Scalar Numerical Data.  Since iSample = 0 will build waves.
			nDataItems = ItemsInList(Pkg.sScalarNumericalDataKeys)
			for (iDataItem = 0; iDataItem < nDataItems; iDataItem += 1)
				GetScalarNumericalData(sAPI_Return, StringFromList(iDataItem,Pkg.sScalarNumericalDataKeys), NumSamples, 0, dfrLibScalarDF)			
			endfor
			
			// Get Optical Spectra if Availble"
			nPossibleSpectra = ItemsInList(Pkg.sPossibleOpticalDataKeys)
			for (iSpectra = 0; iSpectra < nPossibleSpectra; iSpectra += 1)
				sSpectraKey = StringFromList(iSpectra, Pkg.sPossibleOpticalDataKeys)
				if (OpticalSpectraAvailable(sAPI_Return, sSpectraKey))
					GetOpticalSpectra(sAPI_Return, sSpectraKey, NumSamples, 0, dfrLibVectorDF)		
				endif			
			endfor
			
			iSamplesLoadedNow+=1
			Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSamplesLoadedNow)
			DoUpdate/W=FetchProgress
			
			if (NumSamples > 1)	// Get the rest of the data
				for (iSample = 1; iSample < NumSamples; iSample += 1)
					sSampleID = StringFromList(iSample, SamplesList)
					sAPI_URL = Pkg.sAPIRoot + "/sample/" + sSampleID
					sAPI_Return = fetchurl(sAPI_URL)
		
					nDataItems = ItemsInList(Pkg.sVectorNumericalDataKeys)
					for (iDataItem = 0; iDataItem < nDataItems; iDataItem += 1)
						GetVectorNumericalData(sAPI_Return, StringFromList(iDataItem,Pkg.sVectorNumericalDataKeys), NumSamples, iSample, dfrLibVectorDF)			
					endfor
		
					nDataItems = ItemsInList(Pkg.sVectorTextDataKeys)
					for (iDataItem = 0; iDataItem < nDataItems; iDataItem += 1)
						GetVectorTextData(sAPI_Return, StringFromList(iDataItem,Pkg.sVectorTextDataKeys), NumSamples, iSample, dfrLibVectorDF)			
					endfor
					
					nDataItems = ItemsInList(Pkg.sScalarNumericalDataKeys)
					for (iDataItem = 0; iDataItem < nDataItems; iDataItem += 1)
						GetScalarNumericalData(sAPI_Return, StringFromList(iDataItem,Pkg.sScalarNumericalDataKeys), NumSamples, iSample, dfrLibScalarDF)			
					endfor
					
					for (iSpectra = 0; iSpectra < nPossibleSpectra; iSpectra += 1)
						sSpectraKey = StringFromList(iSpectra, Pkg.sPossibleOpticalDataKeys)
						if (OpticalSpectraAvailable(sAPI_Return, sSpectraKey))
							GetOpticalSpectra(sAPI_Return, sSpectraKey, NumSamples, iSample, dfrLibVectorDF)		
						endif			
					endfor
										
					iSamplesLoadedNow+=1
					Execute "ValDisplay valdispProgress value=_NUM:"+num2str(iSamplesLoadedNow)
					DoUpdate/W=FetchProgress
				endfor
			endif
	SetDataFolder dfrSave
			
	// Calculate xrd background subtracted data
	SetDataFolder dfrLibVectorDF
		Wave/Z HTEM_xrd_intensity = HTEM_xrd_intensity
		Wave/Z HTEM_xrd_background = HTEM_xrd_background
		if (WaveExists(HTEM_xrd_intensity) && WaveExists(HTEM_xrd_background))
			duplicate/O HTEM_xrd_intensity HTEM_xrd_intensity_minus_bkg
			HTEM_xrd_intensity_minus_bkg += -HTEM_xrd_background
		endif
	SetDataFolder dfrSave

	SavePkgStructure(Pkg)
	KillWindow FetchProgress
End


// Routines to get vector data from HTEM.nrel.gov
Static Function/S GetDataListFromSampleInfoString(sSampleInfo, sKey)
	String sSampleInfo
	String sKey
	
	variable p1, p2, pNull
	String sListTmp
	
	p1 = strsearch(sSampleInfo, sKey,0,2)
	pNull = strsearch(sSampleInfo, "null",p1,2)	// find next null
	p1 = strsearch(sSampleInfo, "[",p1,2) + 1
	if (p1 == -1) 	// did not find start of vector data field
		return("")
	elseif ((pNull != -1) && (pNull < p1))	// found Null before [.  Null data field.
		return("")
	else
		p2 = strsearch(sSampleInfo, "]",p1,2) - 1
		sListTmp = sSampleInfo[p1,p2]
		return(sListTmp)
	endif
end

Static Function/S BuildTokenKeyList(sSampleInfo)
	string sSampleInfo
	
	String sReturnList, sTokenKey, sSubTokenList, sSubTokenKey, sTokenToAdd
	Variable pTokenKey2, nChar, pDataStart, pTokenKey1, pChar, pDataEnd, nSubTokens, iSubToken
	
	sReturnList = ""
	pChar = 0
	nChar = Strlen(sSampleInfo)
	do
		// find the next key
		pTokenKey2 = strsearch(sSampleInfo, "\":",pChar,2)
		if (pTokenKey2 == -1) 	// No more token keys. Termination condition
			break
		endif
		
		pDataStart = pTokenKey2 + 2
		pTokenKey2 += -1
		pTokenKey1 = strsearch(sSampleInfo, "\"",pTokenKey2,3)
		pTokenKey1 += 1
		sTokenKey = sSampleInfo[pTokenKey1,pTokenKey2]
		
		if (!cmpstr(sSampleInfo[pDataStart],"{"))	// its a master key
			pDataEnd = pDataStart + FindMatchingCurlyBrackt(sSampleInfo[pDataStart,inf])
			sSubTokenList = BuildTokenKeyList(sSampleInfo[pDataStart, pDataEnd])
			nSubTokens = ItemsInList(sSubTokenList)
			for (iSubToken = 0; iSubToken < nSubTokens; iSubToken += 1)
				sSubTokenKey = StringFromList(iSubToken, sSubTokenList)
				sTokenToAdd = sTokenKey + "_" + sSubTokenKey
				sReturnList = AddListItem(sTokenToAdd, sReturnList, ";", inf)
			endfor
			pChar = pDataEnd + 1
		elseif (!cmpstr(sSampleInfo[pDataStart],"[")) //its an array
			pDataEnd = strsearch(sSampleInfo, "]",pDataStart,2)
			sReturnList = AddListItem(sTokenKey, sReturnList, ";", inf)
			pChar = pDataEnd + 1
		else	// its regular data
//			pDataEnd = strsearch(sSampleInfo, ",",pDataStart,2) - 1	// commented out Nov.13
			pDataEnd = PointEndData(sSampleInfo, pDataStart)
			sReturnList = AddListItem(sTokenKey, sReturnList, ";", inf)
			if (pDataEnd == -2)	// Did not find end of data key.  ? Last point has null data ?
				Print "Debug: Should not be able to get here.  In Combi_HTEM/BuildTokenKeyList()."
				Print "Please let john.perkins@nrel.gov know what Library/Sample was being loaded."
				break	// to avoid infinite loop upon reset of pChar to beginning
			endif
			pChar = pDataEnd + 1
		endif
	while (pChar < (nChar-1))
	return(sReturnList)
end

Static Function PointEndData(sSampleInfo, pStart)
	string sSampleInfo
	variable pStart
	
	variable pComma, pRightCurlyB
	
	pComma = strsearch(sSampleInfo, ",",pStart,2)
	pRightCurlyB = strsearch(sSampleInfo, "}",pStart,2)
	
	if (pComma == -1) // it did not find it
		return(pRightCurlyB-1)	 // must be at end of JSON string
	elseif (pComma < pRightCurlyB)
		return(pComma -1)
	else
		return(pRightCurlyB -1)
	endif
End

Static Function FindMatchingCurlyBrackt(sStringIn)
	string sStringIn
	
	variable p1, nNumChar,nOpenCurlyB, pLeftCurlyB, pRightCurlyB
	
	p1 = 1
	nNumChar = strlen(sStringIn)
	nOpenCurlyB = 1
	do
		pLeftCurlyB = strsearch(sStringIn, "{",p1,2)
		if (pLeftCurlyB == -1) // reached the end of string without finding one
			pLeftCurlyB = strlen(sStringIn)-1
		endif
		pRightCurlyB = strsearch(sStringIn, "}",p1,2)
		if (pLeftCurlyB < pRightCurlyB)	// opened another level
			nOpenCurlyB += 1
			p1 = pLeftCurlyB + 1
		else
			nOpenCurlyB += -1
			p1 = pRightCurlyB + 1
		endif			
	while (nOpenCurlyB > 0)
	return(pRightCurlyB)
end

// Working HERE
Static Function GetVectorNumericalData(sSampleInfo, sKey, nSamples, iSample, dfrVector)
	String sSampleInfo
	String sKey
	Variable nSamples
	Variable iSample
	DFREF dfrVector
	
	string sDataList, sDataWaveName
	variable nPoints, iPoint, nPointsInDataWave, nPointsToAdd
	
	sDataWaveName = "HTEM_" + sKey
	DFREF dfrSave = GetDataFolderDFR()
	SetDataFolder dfrVector
		sDataList = GetDataListFromSampleInfoString(sSampleInfo, sKey)
		nPoints = ItemsInList(sDataList, ",")
		if (iSample == 0) 	// First Call, Make the Wave
			make/O/n=(nSamples, nPoints) $sDataWaveName	// what if first Sample has null data for actual array?
			Wave wData = $sDataWaveName
			wData = nan 	// init with Nan's
		endif
		Wave wData = $sDataWaveName
		nPointsInDataWave = dimsize(wData, 1) 	// how many data points are in data wave
		if (nPoints > nPointsInDataWave)	// new data has more points than original data. This could happen if initial SampleID has null in vector
			if (nPointsInDataWave == 0)
				nPointsToAdd = nPoints - nPointsInDataWave - 1
			else
				nPointsToAdd = nPoints - nPointsInDataWave
			endif
			InsertPoints /M=1 /V=(nan) nPointsInDataWave, nPointsToAdd, wData
		endif
		for (iPoint = 0; iPoint < nPoints; iPoint += 1)
			wData[iSample][iPoint] = str2num(StringFromList(iPoint, sDataList, ","))
		endfor
	SetDataFolder dfrSave
end

Static Function GetVectorTextData(sSampleInfo, sKey, nSamples, iSample, dfrVector)
	String sSampleInfo
	String sKey
	Variable nSamples
	Variable iSample
	DFREF dfrVector
	
	string sDataList, sDataWaveName
	variable nPoints, iPoint, nPointsInDataWave, nPointsToAdd
	
	sDataWaveName = "HTEM_" + sKey
	DFREF dfrSave = GetDataFolderDFR()
	SetDataFolder dfrVector
		sDataList = GetDataListFromSampleInfoString(sSampleInfo, sKey)
		nPoints = ItemsInList(sDataList, ",")
		
		if (iSample == 0) 	// First Call, Make the Wave
			make/O/T/n=(nSamples, nPoints) $sDataWaveName
		endif
		Wave/T wData = $sDataWaveName
		nPointsInDataWave = dimsize(wData, 1) 	// how many data points are in data wave
		if (nPoints > nPointsInDataWave)	// new data has more points than original data. This could happen if initial SampleID has null in vector
			if (nPointsInDataWave == 0)
				nPointsToAdd = nPoints - nPointsInDataWave - 1
			else
				nPointsToAdd = nPoints - nPointsInDataWave
			endif
			
			InsertPoints /M=1 nPointsInDataWave, nPointsToAdd, wData
		endif
		for (iPoint = 0; iPoint < nPoints; iPoint += 1)
			wData[iSample][iPoint] = RemovePossibleQuotes(StringFromList(iPoint, sDataList, ","))
		endfor
	SetDataFolder dfrSave
end

// Routines to GetScalarNumericalData
Static Function GetScalarNumericalData(sSampleInfo, sKey, nSamples, iSample, dfrScalar)
	String sSampleInfo
	String sKey
	Variable nSamples
	Variable iSample
	DFREF dfrScalar
	
	string sDataList, sDataWaveName
	variable nPoints, iPoint
	
	sDataWaveName = "HTEM_" + sKey
	DFREF dfrSave = GetDataFolderDFR()
	SetDataFolder dfrScalar
		if (iSample == 0) 	// First Call, Make the Wave
			make/O/n=(nSamples) $sDataWaveName
		endif
		Wave wData = $sDataWaveName
		wData[iSample] = GetScalarValueFromSampleInfoString(sSampleInfo, sKey)
	SetDataFolder dfrSave
end

Static Function GetScalarValueFromSampleInfoString(sSampleInfo, sKey)
	String sSampleInfo
	String sKey
	
	variable p1, p2, val
	String sValueAsString
	
	p1 = strsearch(sSampleInfo, sKey,0,2)
	p1 = strsearch(sSampleInfo, ":",p1,2) + 1

// 	Need fix incase last item in JSON string is a simple variable and not a vector
//	p2 = strsearch(sSampleInfo, ",",p1,2) - 1
	p2 = PointEndData(sSampleInfo, p1)	// added more general check Nov. 13, 2018
	sValueAsString = RemovePossibleQuotes(sSampleInfo[p1,p2])
	val = str2num(sValueAsString)

	return(val)
end

Static Function/S RemovePossibleQuotes(StrIn)
	String StrIn
	
	String s1
	Variable p1
	
	s1 = TrimString(StrIn)
	if (!cmpstr(s1[0], "\""))
		s1 = s1[1,inf]
	endif
	
	p1 = strlen(s1) - 1
	if (!cmpstr(s1[p1], "\""))
		s1 = s1[0,(p1-1)]
	endif

	return(s1)
end

Static Function OpticalSpectraAvailable(sSampleInfo,  sSpectraKey)
	string sSampleInfo
	string  sSpectraKey
	
	variable vKeyExists
	string sKey
	
	skey = "\""+sSpectraKey+"\":"
	vKeyExists = (strsearch(sSampleInfo, skey,0,2) != -1)
	return (vKeyExists)
end


Static Function GetOpticalSpectra(sSampleInfo, sSpectraKey, nSamples, iSample, dfrVector)
	String sSampleInfo
	String sSpectraKey
	Variable nSamples
	Variable iSample
	DFREF dfrVector

	STRUCT HTEMPkgStruct Pkg; [Pkg] = BuildPkgStruct()
	
	string sDataList, sDataWaveName, skey, sComponentName
	variable nPoints, iPoint, nComponents, iComponent
		
	nComponents = ItemsInList(Pkg.sOpticalSpectraComponents)
	for (iComponent = 0; iComponent < nComponents; iComponent += 1)	
		sComponentName = StringFromList(iComponent, Pkg.sOpticalSpectraComponents)

		sDataWaveName = "HTEM_" + sSpectraKey +"_" + sComponentName
		DFREF dfrSave = GetDataFolderDFR()
		SetDataFolder dfrVector
			sDataList = GetOpticalSpectraDataList(sSampleInfo, sSpectraKey, sComponentName)
			nPoints = ItemsInList(sDataList, ",")
//			if (iSample == 0) 	// First Call, Make the Wave
//				make/O/n=(nSamples, nPoints) $sDataWaveName
//			endif
			Wave/Z wData = $sDataWaveName
			if (!WaveExists(wData))	// then need to make it
				make/O/n=(nSamples, nPoints) $sDataWaveName
				Wave wData = $sDataWaveName
				wData = nan
			endif
			
			for (iPoint = 0; iPoint < nPoints; iPoint += 1)
				wData[iSample][iPoint] = str2num(StringFromList(iPoint, sDataList, ","))
			endfor
		SetDataFolder dfrSave
	endfor	
end



Static Function/S GetOpticalSpectraDataList(sSampleInfo, sSpectraKey, sComponentName)
	string sSampleInfo
	string sSpectraKey
	string sComponentName
	
	variable p1, p2
	string sKey, sListTmp
	
	skey = "\""+sSpectraKey+"\":"
	p1 = strsearch(sSampleInfo, sKey,0,2)
	p1 = strsearch(sSampleInfo, sComponentName,p1,2)
	p1 = strsearch(sSampleInfo, "[",p1,2) + 1
	p2 = strsearch(sSampleInfo, "]",p1,2) - 1
	sListTmp = sSampleInfo[p1,p2]
	
	return(sListTmp)
End

Static function AddXRDColLabels(wSampleXRD, wXRDIn, PointsPerPattern, StartCol, NumCols)
	wave wSampleXRD
	wave wXRDIn
	variable PointsPerPattern
	variable StartCol
	variable NumCols
	
	variable iCol, LastCol, vSampleID
	string sColLabel
	
	LastCol = StartCol + NumCols - 1
	
	for (iCol = StartCol; iCol <= LastCol; iCol+=1)
		vSampleID = wXRDIN[(iCol-StartCol)*PointsPerPattern][%sample_id]
		print iCol, vSampleID
		
		sColLabel = num2istr(vSampleID)
		
		SetDimLabel 1,iCol,$sColLabel,wSampleXRD
	endfor
end

Static function PrefixRowDimLabels(w1)
	wave w1
	
	variable nRows, iRow
	string sRowLabel

	nRows = DimSize(w1, 0)
	
	for (iRow = 0; iRow < nRows; iRow += 1)
		sRowLabel = GetDimLabel(w1,0,iRow)
		sRowLabel = "s"+sRowLabel
		
		SetDimLabel 0,iRow,$sRowLabel,w1
	endfor	
end

Static function PrefixColDimLabels(w1)
	wave w1
	
	variable nCols, iCol
	string sColLabel

	nCols = DimSize(w1, 1)
	
	for (iCol = 1; iCol < nCols; iCol += 1)
		sColLabel = GetDimLabel(w1,1,iCol)
		sColLabel = "s"+sColLabel
		
		SetDimLabel 1,iCol,$sColLabel,w1
	endfor	
end

Static function CountSampleIDs(sAPIReturn)
	string sAPIReturn
	
	variable p1, nIDs
	
	p1 = -1
	nIDS = 0
	do
		p1 = strsearch(sAPIReturn, "\"id\"", (p1+1))
		nIDS += 1
		print nIDS
	while (p1 >=0)	// as long as expression is TRUE
	
	return(nIDS-1)
	
end

Static function/S GetListOfSampleLIbIDs(sAPIReturn)
	string sAPIReturn
	
	variable p1, nIDs, p2, p3
	string sLibList, sLibID
	
	sLibList = ""
	
	p1 = -1
	nIDS = 0
	do
		p1 = strsearch(sAPIReturn, "\"id\"", (p1+1))
		if (p1 < 0)
			break
		endif
		p2= strsearch(sAPIReturn, ":", p1)
		p3= strsearch(sAPIReturn, ",", p2)
		sLibID = sAPIReturn[(p2+1), (p3-1)]
		sLibID = TrimString(sLibID)
		sLibList = AddListItem(sLibID, sLibList)
		nIDS += 1
	while (p1 >=0)	// as long as expression is TRUE
Print nIDS	
	return(sLibList)
	
end

Static Function/S SampleLibAPIStringToList(sAPIString)
	string sAPIString
	
	variable lastpt = strlen(sAPIString) - 1
	
	sAPIString[lastpt, lastpt] = ";"
	sAPIString[0,0] = ""
	sAPIString = ReplaceString( "},{", sAPIString, "};{")
	return(sAPIString)
end

Static Function JSONSimpleSampleLibList(index, s1)
	variable index
	string s1
	JSONSimple /MAXT=100 stringfromlist(index,s1)
end

Static Function/S CleanTokenText(s1)
	string s1
	
	if (!cmpstr(s1[0],"["))		// it is a list
		s1 = ReplaceString(",", s1, ";")
		s1 = ReplaceString("\"",s1, "")
		s1 = ReplaceString("[",s1,"")
		s1 = ReplaceString("]",s1,";")
		s1 = ReplaceString("null", s1, "")
	endif
	s1 = ReplaceString("null", s1, "")

	return(s1)
end


Static Function/S GetDimLabelFromKey(sKey)  
	string sKey
	
	strswitch(skey)	
		case "deposition_compounds":	
			skey = "dep_compounds"
			break
		case "deposition_power":
			skey = "dep_power"
			break
		case "deposition_gases":
			skey = "dep_gases"
			break
		case "deposition_gas_flow_sccm":
			skey = "dep_gas_Flow"
			break
		case "deposition_sample_time_min":
			skey = "dep_time"
			break
		case "deposition_cycles":
			skey = "dep_cycles"
			break
		case "deposition_substrate_material":
			skey = "substrate"
			break
		case "deposition_base_pressure_mtorr":
			skey = "base_pressure_mtorr"
			break
		case "deposition_initial_temp_c":
			skey = "dep_init_temp_c"
			break
		case "deposition_growth_pressure_mtorr":
			skey = "dep_pressure_mtorr"
			break
	endswitch
	return(sKey)
end

Static Function CountKeys(wTokenParent)
	wave wTokenParent
	
	variable nPoints, NumKeys, iPoint
	
	NumKeys = 0
	nPoints = DimSize(wTokenParent, 0 )
	for (iPoint = 0; iPoint < nPoints; iPoint += 1)
		if (wTokenParent[iPoint] == 0)
//			print iPoint
			NumKeys += 1
		endif
	endfor
	return(NumKeys)
end

Static Function MakeHTEMSampleTable(sHTEMin, sWaveName)	// v2 (Adapting to COMBIgor environment)
	string sHTEMin
	string sWaveName

	string sHTEMList, sLibInfo, sDimLabel, sKeyValue
	variable nLibs, nKeys, iLib, iPoint, nPoints, iKey
	
	sHTEMList = SampleLibAPIStringToList(sHTEMin)
	nLibs = ItemsInList(sHTEMList)
	sLibInfo = StringFromList(0, sHTEMList)
	
	DFREF dfrSave = GetDataFolderDFR()	
	DFREF dfrTmpDF = NewFreeDataFolder()	
	SetDataFolder dfrTmpDF
		JSONSimple /Q /Z /MAXT=100 sLibInfo
		Wave wTokenType = W_TokenType
		Wave wTokenSize = W_TokenSize
		Wave wTokenParent = W_TokenParent
		Wave/T wTokenText= T_TokenText
	SetDataFolder dfrSave
	
	nKeys = CountKeys(wTokenParent)
	print "Total Libraries = ", nLibs
	print "Column Keys = ", nKeys

	SetDataFolder ksPkgDF; SetDataFolder LibInfo
		make/n=(nLibs, nKeys)/T/O $sWaveName
		wave/T wLibInfo = $sWaveName
	SetDataFolder dfrSave
	

	// add loop to get keys
//	iPoint = 0
	nPoints = Dimsize(wTokenParent,0)
	iKey = 0
	for (iPoint = 0; iPoint < nPoints; iPoint += 1)
		if (wTokenParent[iPoint] == 0)	// then it is a key
			sDimLabel = GetDimLabelFromKey(wTokenText[iPoint])
			SetDimLabel 1,iKey,$sDimLabel,wLibInfo
			iKey += 1
		endif
	endfor
		
	for (iLib=0; iLib < nLibs; iLib += 1)
	
		sLibInfo = StringFromList(iLib, sHTEMList)
		SetDataFolder dfrTmpDF
			JSONSimple /Q /Z /MAXT=100 sLibInfo
			Wave wTokenType = W_TokenType
			Wave wTokenSize = W_TokenSize
			Wave wTokenParent = W_TokenParent
			Wave/T wTokenText= T_TokenText
		SetDataFolder dfrSave
		
		iPoint = 0
		nPoints = Dimsize(wTokenParent,0)	// nPoints may vary by lib so need to recalc here
		do
			if (wTokenParent[iPoint] == 0)	// then it is a key
				sDimLabel = GetDimLabelFromKey(wTokenText[iPoint])
				iPoint += 1
				sKeyValue = CleanTokenText(wTokenText[iPoint])
				if (!cmpstr(sDimLabel, "id"))
					SetDimLabel 0,iLib,$sKeyValue,wLibInfo	// label the row
				endif
				wLibInfo[iLib][%$sDimLabel] = sKeyValue
			endif
			iPoint += 1
			
		while (iPoint < nPoints)

	endfor

	edit wLibInfo.ld
	killdatafolder dfrTmpDF
	return(nLibs)
end


Function jdpProtoFcnTest2(pSampleLib,wSampleLibsTable, wVarParms, wTxtParms)
	variable pSampleLib
	wave/T wSampleLibsTable
	wave 	wVarParms
	wave/T wTxtParms

end

Static Function/S SelectSamples(pLib, wSampleLibsTable, FilterFcn, wVarParms, wTxtParms)
	variable pLib
	wave/T wSampleLibsTable
	FUNCREF jdpProtoFcnTest2 FilterFcn
	wave 	wVarParms
	wave/T wTxtParms
	
	print FilterFcn(pLib, wSampleLibsTable, wVarParms, wTxtParms)
end

Static Function/S SelectSamples2(wSampleLibsTable, FilterFcn, wVarParms, wTxtParms)
	wave/T wSampleLibsTable
	FUNCREF jdpProtoFcnTest2 FilterFcn
	wave 	wVarParms
	wave/T wTxtParms
	
	variable nLibs, iLib
	string sSampleList
	
	sSampleList = ""
	
	nLibs = DimSize(wSampleLibsTable, 0 )
	for (iLib = 0; iLib < nLibs; iLib += 1)
		if (FilterFcn(iLib , wSampleLibsTable, wVarParms, wTxtParms))
					sSampleList = AddListItem(GetDimLabel(wSampleLibsTable, 0, iLib), sSampleList, ";", inf)
		endif
	endfor
	return(sSampleList)
end

Static Function CreateFocusedSelectionTable(sFocusList, wTableIn, sNameFocusLibsTable)
	string sFocusList
	wave/T wTableIn
	string sNameFocusLibsTable
	
	DFREF dfrSave = GetDataFolderDFR()
	DFREF dfrTmpDF = NewFreeDataFolder()
	SetDataFolder ksPkgDF; 
		DFREF dfrPkgDF = GetDataFolderDFR()
		SetDataFolder LibInfo
		DFREF dfrLibInfo = GetDataFolderDFR()
	SetDataFolder dfrPkgDF; SetDataFolder DataTmp
		DFREF dfrDataTmp = GetDataFolderDFR()
	SetDataFolder dfrSave

	variable nFocusLibs, nPropKeys, iPropKey, iFocusLib
	string sDimLabel, sFocusLibID
	
	nFocusLibs = ItemsInList(sFocusList)
	nPropKeys = DimSize(wTableIn, 1)
	
	SetDataFolder dfrLibInfo
		make/T/O/n=(nFocusLibs, (nPropKeys+1)) $sNameFocusLibsTable
		Wave/T wFocusLibs = $sNameFocusLibsTable
	SetDataFolder dfrSave

	SetDimLabel 1,0,Select,wFocusLibs
	for (iPropKey=0; iPropKey < nPropKeys; iPropKey += 1)
		sDimLabel = GetDimLabel(wTableIn, 1, iPropKey )
		SetDimLabel 1,(iPropKey+1),$sDimLabel,wFocusLibs
	endfor
	wFocusLibs[][%Select] = ""
	
	for (iFocusLib = 0; iFocusLib < nFocusLibs; iFocusLib += 1)
		sFocusLibID = StringFromList(iFocusLib, sFocusList)
		SetDimLabel 0,iFocusLib,$sFocusLibID,wFocusLibs
		wFocusLibs[iFocusLib][1,inf] = wTableIn[%$sFocusLibID][q-1]
	endfor
	
	edit wFocusLibs.ld
end

Static Function/S SelectionListFromTable(wFocusTableIn)
	wave/T wFocusTableIn
	
	variable nLibs,iLib
	string sSelectedLibsList
	
	sSelectedLibsList = ""
	nLibs = DimSize(wFocusTableIn, 0)
	for (iLib = 0; iLib < nLibs; iLib +=1)
		if (cmpstr(wFocusTableIn[iLib][%Select], "" ))
			sSelectedLibsList = AddListItem(wFocusTableIn[iLib][%id], sSelectedLibsList, ";", inf)
		endif
	endfor
	return(sSelectedLibsList)
end

//ADDED BY KEVIN TALLEY FOR COMBIGOR INTEGRATION _____________________________________

// Put Non-Static COMBIgor Interfacing Routines Here

Function HTEM_Define()	// Called from Instrument Access Panel when push Define Button

	Init4COMBIgor()
	
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	STRUCT HTEMPkgStruct ThisProjectStructure
	
	//get stucture
	string sPackageStructure = COMBI_GetInstrumentString(sThisInstrumentName,"sPkgStruct", "sProject")
	if(stringmatch(sPackageStructure,"NAG")||strlen(sPackageStructure)==0)
		//int structure
		ThisProjectStructure.Version = kVersionNumber
		ThisProjectStructure.savDF = GetdataFolder(1)
		ThisProjectStructure.sAPIRoot = ksAPIRoot_Public
		ThisProjectStructure.sNameLibInfoWave = ""
		ThisProjectStructure.sNameFilterFcn = "Example_HTEMFilter"
		ThisProjectStructure.sNameVarParmWave = ""
		ThisProjectStructure.sNameTxtParmWave = ""
		ThisProjectStructure.sNameLibFocusInfoWave = ""
		ThisProjectStructure.sSelectedLibsList = ""
		ThisProjectStructure.sNameSelectedLibsList = ""
		ThisProjectStructure.sVectorNumericalDataKeys = ksVectorNumericalDataKeys
		ThisProjectStructure.sVectorTextDataKeys = ksVectorTextDataKeys
		ThisProjectStructure.sScalarNumericalDataKeys = ksScalarNumericalDataKeys
		ThisProjectStructure.sPossibleOpticalDataKeys = ksPossibleOpticalDataKeys
		ThisProjectStructure.sOpticalSpectraComponents = ksOpticalSpectraComponents
		ThisProjectStructure.sLibLevelNumDataStoredAsString = ksLibLevelNumDataStoredAsString
	elseif(strlen(sPackageStructure)>0)
		StructGet /S ThisProjectStructure, sPackageStructure
	else
		DoAlert/T="No structure found.",0,"COMBIgor cannot find the package data, try removing the add-on and add it again."
		return -1
	endif
	
	//get data base to use
	string sDataBase2Use = COMBI_StringPrompt("Public","Which HTEM to access?","Public;NREL","This is the database COMBIgor will pull from. NREL database access requires connection to the NREL network.","Choose HTEM version")
	if(stringmatch("CANCEL",sDataBase2Use))
		return -1
	elseif(stringmatch("Public",sDataBase2Use))
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sDataBase2Use","Public",sProject)
		sDataBase2Use = ksAPIRoot_Public
	elseif(stringmatch("NREL",sDataBase2Use))
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sDataBase2Use","NREL Netwrok",sProject)
		sDataBase2Use = ksAPIRoot_NREL
	endif
		
	string sOptions
	variable/g VFlag
	
	 //get previous selections
 	int bHTEMKeys = 0
 	string sHTEMKeys = COMBI_GetInstrumentString(sThisInstrumentName,"bHTEMKeys", sProject)
 	if(stringmatch("Yes",sHTEMKeys))
 		bHTEMKeys = 1
 	elseif(stringmatch("No",sHTEMKeys))
 		bHTEMKeys = 0
 	else
 		bHTEMKeys = 0
 	endif

 	int b4PointProbe = 0
 	string s4PointProbe = COMBI_GetInstrumentString(sThisInstrumentName,"b4PointProbe", sProject)
 	if(stringmatch("Yes",s4PointProbe))
 		b4PointProbe = 1
 	elseif(stringmatch("No",s4PointProbe))
 		b4PointProbe = 0
 	else
 		b4PointProbe = 0
 	endif

 	int bUVVisNIRData = 0
 	string sUVVisNIRData = COMBI_GetInstrumentString(sThisInstrumentName,"bUVVisNIRData", sProject)
 	if(stringmatch("Yes",sUVVisNIRData))
 		bUVVisNIRData = 1
 	elseif(stringmatch("No",sUVVisNIRData))
 		bUVVisNIRData = 0
 	else
 		bUVVisNIRData = 0
 	endif

 	int bXRDData = 0
 	string sXRDData = COMBI_GetInstrumentString(sThisInstrumentName,"bXRDData", sProject)
 	if(stringmatch("Yes",sXRDData))
 		bXRDData = 1
 	elseif(stringmatch("No",sXRDData))
 		bXRDData = 0
 	else
 		bXRDData = 0
 	endif

 	int bXRFData = 0
 	string sXRFData = COMBI_GetInstrumentString(sThisInstrumentName,"bXRFData", sProject)
 	if(stringmatch("Yes",sXRFData))
 		bXRFData = 1
 	elseif(stringmatch("No",sXRFData))
 		bXRFData = 0
 	else
 		bXRFData = 0
 	endif

 	int bLibraryData = 0
 	string sLibraryData = COMBI_GetInstrumentString(sThisInstrumentName,"bLibraryData", sProject)
 	if(stringmatch("Yes",sLibraryData))
 		bLibraryData = 1
 	elseif(stringmatch("No",sLibraryData))
 		bLibraryData = 0
 	else
 		bLibraryData = 0
 	endif
 	
 	 int bMetaData = 0
 	string sMetaData = COMBI_GetInstrumentString(sThisInstrumentName,"bMetaData", sProject)
 	if(stringmatch("Yes",sMetaData))
 		bMetaData = 1
 	elseif(stringmatch("No",sMetaData))
 		bMetaData = 0
 	else
 		bMetaData = 0
 	endif

 	string sStartOptions = num2str(bMetaData)+";"+num2str(bLibraryData)+";"+num2str(bXRFData)+";"+num2str(bXRDData)+";"+num2str(bUVVisNIRData)+";"+num2str(b4PointProbe)+";"+num2str(bHTEMKeys)
	
	//ask catagories
	sOptions  = COMBI_UserOptionSelect("Meta Data;Library Data;XRF;XRD;UV Vis NIR;Four Point Probe;HTEM Keys",sStartOptions,sTitle="HTEM Options",sDescription="Data Types to Fetch:")
	NVAR vSelectionTracker = root:bSelection
	if(vSelectionTracker == 0)
		return -1
	else
		killvariables vSelectionTracker
	endif
	
	string sVectorNumericalDataKeys = ""
 	string sVectorTextDataKeys = ""
 	string sScalarNumericalDataKeys = ""
 	string sPossibleOpticalDataKeys = ""
 	string sOpticalSpectraComponents = ""
 	string sLibLevelNumDataStoredAsString = ""
 	
	
	
	if(whichListItem("Meta Data",sOptions)!=-1)
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bMetaData","Yes",sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bMetaData","No",sProject)// store global
	endif
	
	if(whichListItem("Library Data",sOptions)!=-1)
		sLibLevelNumDataStoredAsString = sLibLevelNumDataStoredAsString+"deposition_sample_time_min;deposition_initial_temp_c;deposition_growth_pressure_mtorr;"
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bLibraryData","Yes",sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bLibraryData","No",sProject)// store global
	endif
	
	if(whichListItem("XRF",sOptions)!=-1)
		sVectorNumericalDataKeys = sVectorNumericalDataKeys+"xrf_concentration;"
		sVectorTextDataKeys = sVectorTextDataKeys+"xrf_elements;xrf_compounds;"
		sScalarNumericalDataKeys = sScalarNumericalDataKeys+"thickness;"
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bXRFData","Yes",sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bXRFData","No",sProject)// store global
	endif
	
	if(whichListItem("XRD",sOptions)!=-1)
		sVectorNumericalDataKeys = sVectorNumericalDataKeys+"xrd_angle;xrd_background;xrd_intensity;"
		sScalarNumericalDataKeys = sScalarNumericalDataKeys+"peak_count;"
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bXRDData","Yes",sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bXRDData","No",sProject)// store global
	endif
	
	if(whichListItem("UV Vis NIR",sOptions)!=-1)
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bUVVisNIRData","Yes",sProject)// store global
		sScalarNumericalDataKeys = sScalarNumericalDataKeys+"opt_average_vis_trans;opt_direct_bandgap;"
		sPossibleOpticalDataKeys = "uvir;uvit;nirr;nirt;"
		sOpticalSpectraComponents = "wavelength;response;"
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bUVVisNIRData","No",sProject)// store global
	endif
	
	if(whichListItem("Four Point Probe",sOptions)!=-1)
		sScalarNumericalDataKeys = sScalarNumericalDataKeys+"fpm_resistivity;fpm_conductivity;fpm_sheet_resistance;fpm_standard_deviation;"
		sVectorNumericalDataKeys = sVectorNumericalDataKeys+"fpm_voltage_volts;fpm_current_amps;"
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"b4PointProbe","Yes",sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"b4PointProbe","No",sProject)// store global
	endif
	
	if(whichListItem("HTEM Keys",sOptions)!=-1)
		sScalarNumericalDataKeys = sScalarNumericalDataKeys+"id;sample_id;position;"
		sVectorNumericalDataKeys = sVectorNumericalDataKeys+"xyz_mm;"
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bHTEMKeys","Yes",sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bHTEMKeys","No",sProject)// store global
	endif

	//store results in strucutre
	ThisProjectStructure.sVectorNumericalDataKeys = sVectorNumericalDataKeys
	ThisProjectStructure.sVectorTextDataKeys = sVectorTextDataKeys
	ThisProjectStructure.sScalarNumericalDataKeys = sScalarNumericalDataKeys
	ThisProjectStructure.sPossibleOpticalDataKeys = sPossibleOpticalDataKeys
	ThisProjectStructure.sOpticalSpectraComponents = sOpticalSpectraComponents
	ThisProjectStructure.sLibLevelNumDataStoredAsString = sLibLevelNumDataStoredAsString
	ThisProjectStructure.sAPIRoot = sDataBase2Use
	
	//store structure in global wave
	StructPut/S ThisProjectStructure, sPackageStructure
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sPkgStruct",sPackageStructure,sProject)
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
	
End


Function HTEM_Load()	// Place Holder Function for loading data from HTEM
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root:
	//get sample name
	string sLibrary2Load = COMBI_LibraryPrompt(sProject,"New","Library to load:",0,1,0,-3)
	if(stringmatch(sLibrary2Load,"CANCEL"))
		return -1
	endif
	//parse the sample name
	String expr="PDAC_COM([[:digit:]]*)_([[:digit:]]*)"
	string sChamberNum, sSampleNum
	SplitString/E=(expr) sLibrary2Load, sChamberNum, sSampleNum
	
	if(strlen(sChamberNum)==0)
		DoAlert/T="Invalid chamber number",0,"Chamber number should be in the format PDAC_COM5_00001."
		return -1
	endif
	if(strlen(sSampleNum)==0)
		DoAlert/T="Invalid library name",0,"Library name should be in the format PDAC_COM5_00001."
		return -1
	endif
	
	int vChamber = str2num(sChamberNum)
	int vLibraryNum = str2num(sSampleNum)
	
	//update the database
	GetAll4COMBIgor(sProject)
	//get newly updated search wave
	wave/T wCOMBIgorSearchWave =  root:Packages:COMBIgor:Instruments:HTEM:LibInfo:COMBIgorSearchWave
	
	int iLibrary
	string LibraryKey = ""
	for(iLibrary=0;iLibrary<dimsize(wCOMBIgorSearchWave,0);iLibrary+=1)
		int vThisChamber = str2num(wCOMBIgorSearchWave[iLibrary][%pdac])
		int vThisLibraryNum = str2num(wCOMBIgorSearchWave[iLibrary][%num])
		if(vThisChamber==vChamber&&vLibraryNum == vThisLibraryNum)
			LibraryKey = wCOMBIgorSearchWave[iLibrary][%id]
		endif
	endfor
	if(strlen(LibraryKey)==0)
		DoAlert/T="Cannot find sample",0,"That sample is not in the HTEM data COMBIgor can access. Sample numbers in the database can be found in the third column of the following table:"
		edit/K=1 root:Packages:COMBIgor:Instruments:HTEM:LibInfo:COMBIgorSearchWave.ld
		return -1
	endif
	
	//move structure to Operational storage in globals wave
	wave/T wtGlobals = root:Packages:COMBIgor:Instruments:COMBI_HTEM_Globals
	wtGlobals[%sPkgStruct][%COMBIgor] = wtGlobals[%sPkgStruct][%$sProject]
	
	GetDataForLib(LibraryKey)
	
	//move data from data folders to COMBIgor data folders
	MoveHTEMData2COMBIGor(sProject,LibraryKey,sLibrary2Load)
	SetDataFolder $sTheCurrentUserFolder 
End

Static Function UpdateActivePkgStructFromProjectDef()
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	//move structure to Operational storage in globals wave
	wave/T wtGlobals = root:Packages:COMBIgor:Instruments:COMBI_HTEM_Globals
	wtGlobals[%sPkgStruct][%COMBIgor] = wtGlobals[%sPkgStruct][%$sProject]
End

static function CheckIfUserWants(sProject,sName2Check)
	string sProject, sName2Check
		
	string bLibraryData = COMBI_GetInstrumentString("HTEM","bLibraryData", sProject)
	string bXRFData = COMBI_GetInstrumentString("HTEM","bXRFData", sProject)
	string bXRDData = COMBI_GetInstrumentString("HTEM","bXRDData", sProject)
	string bUVVisNIRData = COMBI_GetInstrumentString("HTEM","bUVVisNIRData", sProject)
	string b4PointProbe = COMBI_GetInstrumentString("HTEM","b4PointProbe", sProject)
	string bHTEMKeys = COMBI_GetInstrumentString("HTEM","bHTEMKeys", sProject)
	string bMetaData =  COMBI_GetInstrumentString("HTEM","bMetaData", sProject)
	
	int bWants = 1
	
	if(stringmatch("No",bXRFData))
		if(stringmatch(sName2Check,"*xrf*"))
			bWants = 0
		endif
		if(stringmatch(sName2Check,"*thickness*"))
			bWants = 0
		endif
	endif
	
	if(stringmatch("No",bXRDData))
		if(stringmatch(sName2Check,"*xrd*"))
			bWants = 0
		endif
		if(stringmatch(sName2Check,"*peak_count*"))
			bWants = 0
		endif
	endif
	
	if(stringmatch("No",bUVVisNIRData))
		if(stringmatch(sName2Check,"*opt*"))
			bWants = 0
		endif
		if(stringmatch(sName2Check,"*uvi*"))
			bWants = 0
		endif
		if(stringmatch(sName2Check,"*nir*"))
			bWants = 0
		endif
	endif
	
	if(stringmatch("No",bHTEMKeys))
		if(stringmatch(sName2Check,"*id*"))
			bWants = 0
		endif
	endif
	
	if(stringmatch("No",bMetaData))
		if(stringmatch(sName2Check,"*deposition*"))
			bWants = 0
		endif
	endif
	
	if(stringmatch("No",bLibraryData))
		if(stringmatch(sName2Check,"*deposition*"))
			bWants = 0
		endif
	endif
	
	if(stringmatch("No",b4PointProbe))
		if(stringmatch(sName2Check,"*ele*"))
			bWants = 0
		endif
		if(stringmatch(sName2Check,"*fpm*"))
			bWants = 0
		endif
	endif
	
	return bWants
	
end

//for sorting retreived data
static function MoveHTEMData2COMBIGor(sProject,LibraryKey,sLibraryName)
	string LibraryKey, sProject, sLibraryName
	
	string sNewDataFolder = "root:Packages:COMBIgor:Instruments:HTEM:DataTmp:LK_"+LibraryKey+":" 
	
	string bLibraryData = COMBI_GetInstrumentString("HTEM","bLibraryData", sProject)
	string bXRFData = COMBI_GetInstrumentString("HTEM","bXRFData", sProject)
	string bXRDData = COMBI_GetInstrumentString("HTEM","bXRDData", sProject)
	string bUVVisNIRData = COMBI_GetInstrumentString("HTEM","bUVVisNIRData", sProject)
	string b4PointProbe = COMBI_GetInstrumentString("HTEM","b4PointProbe", sProject)
	string bHTEMKeys = COMBI_GetInstrumentString("HTEM","bHTEMKeys", sProject)
	string bMetaData =  COMBI_GetInstrumentString("HTEM","bMetaData", sProject)
	
	NVAR TotalSamples = $sNewDataFolder+"NumSamples"
	NVAR NumOfXRFElements = $sNewDataFolder+"NumXRF_Elements"
	SVAR ListOfXRFElements = $sNewDataFolder+"XRF_ElementsList"

	int iObject, iMeta, iLib,iSample
	string sThisObject
	string sAllDataTypesAdded = ""
	
	string sLibDataFolder = sNewDataFolder+"LibData:"
	//Library and Meta waves
	for(iObject=0;iObject<CountObjects(sLibDataFolder,1);iObject+=1)
		sThisObject = GetIndexedObjName(sLibDataFolder,1,iObject)
		if(CheckIfUserWants(sProject,sThisObject)==0)
			Continue
		endif
		if(stringmatch(sThisObject,"HTEM_sample_ids"))
			if(stringmatch("Yes",bHTEMKeys))
				wave wThisLibData = $sLibDataFolder+sThisObject
				for(iSample=0;iSample<dimsize(wThisLibData,0);iSample+=1)
					Combi_GiveScalar(wThisLibData[iSample],sProject,sLibraryName,sThisObject,iSample)
				endfor
				sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
			endif
		elseif(WaveType($sLibDataFolder+sThisObject,1)==1)//Library
			if(stringmatch("Yes",bLibraryData))
				wave wThisLibData = $sLibDataFolder+sThisObject
				for(iLib=0;iLib<dimsize(wThisLibData,0);iLib+=1)
					if(numtype(wThisLibData[iLib])==0)
						COMBI_GiveLibraryData(wThisLibData[iLib],sProject,sLibraryName,sThisObject+"_"+num2str(iLib+1))
					endif
				endfor
				sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
			endif
		elseif(WaveType($sLibDataFolder+sThisObject,1)==2)//Meta
			if(stringmatch("Yes",bMetaData))
				wave/T wThisMetaData = $sLibDataFolder+sThisObject
				for(iMeta=0;iMeta<dimsize(wThisMetaData,0);iMeta+=1)
					if(strlen(wThisMetaData[iMeta])>0)
						COMBI_GiveMeta(sProject,sThisObject+"_"+num2str(iMeta+1),sLibraryName,wThisMetaData[iMeta],-1)
						sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
					endif
				endfor
			endif
		endif
	endfor
	//Library variables
	if(stringmatch("Yes",bLibraryData))
		for(iObject=0;iObject<CountObjects(sLibDataFolder,2);iObject+=1)
			sThisObject = GetIndexedObjName(sLibDataFolder,2,iObject)
			if(CheckIfUserWants(sProject,sThisObject)==0)
				Continue
			endif
			NVAR vThisIn = $sLibDataFolder+sThisObject
			if(numtype(vThisIn)==0)
				COMBI_GiveLibraryData(vThisIn,sProject,sLibraryName,sThisObject)
				sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
			endif
		endfor
	endif
	//Meta strings
	if(stringmatch("Yes",bMetaData))
		for(iObject=0;iObject<CountObjects(sLibDataFolder,3);iObject+=1)
			sThisObject = GetIndexedObjName(sLibDataFolder,3,iObject)
			if(CheckIfUserWants(sProject,sThisObject)==0)
				Continue
			endif
			SVAR sThisIn = $sLibDataFolder+sThisObject
			if(strlen(sThisIn)>0)
				COMBI_GiveMeta(sProject,sThisObject,sLibraryName,sThisIn,-1)
				sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
			endif
		endfor
	endif
	
	//Scalar waves
	string sScalarDataFolder = sNewDataFolder+"Scalar:"
	for(iObject=0;iObject<CountObjects(sScalarDataFolder,1);iObject+=1)
		sThisObject = GetIndexedObjName(sScalarDataFolder,1,iObject)
		if(CheckIfUserWants(sProject,sThisObject)==0)
			Continue
		endif
		if(WaveType($sScalarDataFolder+sThisObject,1)==1)//Number
			wave wThisScalarData = $sScalarDataFolder+sThisObject
			for(iSample=0;iSample<dimsize(wThisScalarData,0);iSample+=1)
				if(numtype(wThisScalarData[iSample])==0)
					Combi_GiveScalar(wThisScalarData[iSample],sProject,sLibraryName,sThisObject,iSample)
					sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
				endif
			endfor
		endif
	endfor
	
	//Vector waves
	string sThisSampleFolder
	if(!DataFolderExists(COMBI_DataPath(sProject,2)+sLibraryName+":"))
		NewDataFolder $COMBI_DataPath(sProject,2)+sLibraryName+":"
	endif
	string sVectorDataFolder = sNewDataFolder+"Vector:"
	setdatafolder $sVectorDataFolder
	string sAllwaves = WaveList("HTEM*",";", "")
	setdatafolder "root:"
	int vWaves2Check = itemsinlist(sAllwaves)
	for(iObject=0;iObject<vWaves2Check;iObject+=1)
		sThisObject = stringfromlist(iObject,sAllwaves)
		if(CheckIfUserWants(sProject,sThisObject)==0)
			Continue
		endif
		if(WaveType($sVectorDataFolder+sThisObject,1)==1)//Number
			wave wThisVectorData = $sVectorDataFolder+sThisObject
			killwaves/Z $COMBI_DataPath(sProject,2)+sLibraryName+":"+sThisObject
			MoveWave wThisVectorData, $COMBI_DataPath(sProject,2)+sLibraryName+":"
			sAllDataTypesAdded = AddListItem(sThisObject,sAllDataTypesAdded)
		endif
	endfor
	
	//clean out dublicates
	string sListForLog =""
	for(iObject=0;iObject<itemsinlist(sAllDataTypesAdded);iObject+=1)
		sThisObject = stringfromlist(iObject,sAllDataTypesAdded)
		if(whichListItem(sThisObject,sListForLog)==-1)
			sListForLog = AddListItem(sThisObject,sListForLog)
		endif
	endfor
	
	//Add 2 Combvi Data Log
	string sLogText = "Data Loaded from the HTEM data base;"
	sLogText = sLogText+"Library Key "+LibraryKey+";"
	COMBI_Add2Log(sProject,sLibraryName,sListForLog,1,sLogText)
	
	//kill imported folder
	Killdatafolder $sNewDataFolder
end

//for getting to HTEM load through the Instrument Access panel
static function HTEMInstrumentAccess()
	COMBI_GiveGlobal("sInstrumentName","HTEM","COMBIgor")
	COMBI_InstrumentDefinition()
	Init4COMBIgor()
end

Static Function Init4COMBIgor()
	String savDF = GetdataFolder(1)
	String sPkgStruct, sInstrumentName
	sInstrumentName = ksInstrumentName

	// initialize if not already
	if(!datafolderexists("root:Packages:COMBIgor:Instruments:HTEM:"))
	
		NewDataFolder/O/S Packages
		NewDataFolder/O/S COMBIgor
		NewDataFolder/O/S Instruments
		NewDataFolder/O/S HTEM
		NewDataFolder/O DataTmp
		NewDataFolder/O LibInfo
		setdataFolder root:
	
		// Initialize Values in the Pkg Structure
		STRUCT HTEMPkgStruct Pkg
		Pkg.Version = kVersionNumber
		Pkg.savDF = savDF
		Pkg.sAPIRoot = ksAPIRoot_Public
		Pkg.sNameLibInfoWave = ""
		Pkg.sNameFilterFcn = "Example_HTEMFilter"
		Pkg.sNameVarParmWave = ""
		Pkg.sNameTxtParmWave = ""
		Pkg.sNameLibFocusInfoWave = ""
		Pkg.sSelectedLibsList = ""
		Pkg.sNameSelectedLibsList = ""
		Pkg.sVectorNumericalDataKeys = ksVectorNumericalDataKeys
		Pkg.sVectorTextDataKeys = ksVectorTextDataKeys
		Pkg.sScalarNumericalDataKeys = ksScalarNumericalDataKeys
		Pkg.sPossibleOpticalDataKeys = ksPossibleOpticalDataKeys
		Pkg.sOpticalSpectraComponents = ksOpticalSpectraComponents
		Pkg.sLibLevelNumDataStoredAsString = ksLibLevelNumDataStoredAsString
	
		//Print Pkg
		StructPut/S Pkg, sPkgStruct
		COMBI_GiveInstrumentGlobal(sInstrumentName,"sPkgStruct",sPkgStruct, "COMBIgor")
		
	endif
end

Static Function GetAll4COMBIgor(sProject)
	string sProject
	//get structure for project
	STRUCT HTEMPkgStruct Pkg
	string sPkgStruct = COMBI_GetInstrumentString(ksInstrumentName,"sPkgStruct", sProject)
	StructGet/S Pkg, sPkgStruct
	//API URL
	string sAPIRoot = Pkg.sAPIRoot
	string sURL = sAPIRoot + "/sample_library"
	//get all library info
	string s1 = fetchurl(sURL)
	variable nLibs = MakeCOMBIgorSearchWave(s1)
End


Static Function MakeCOMBIgorSearchWave(sHTEMin)
	string sHTEMin
	string sWaveName
	string sHTEMList, sLibInfo, sDimLabel, sKeyValue
	variable nLibs, nKeys, iLib, iPoint, nPoints, iKey
	
	sHTEMList = SampleLibAPIStringToList(sHTEMin)
	nLibs = ItemsInList(sHTEMList)
	sLibInfo = StringFromList(0, sHTEMList)
	
	DFREF dfrSave = GetDataFolderDFR()	
	DFREF dfrTmpDF = NewFreeDataFolder()	
	SetDataFolder dfrTmpDF
		JSONSimple /Q /Z /MAXT=100 sLibInfo
		Wave wTokenType = W_TokenType
		Wave wTokenSize = W_TokenSize
		Wave wTokenParent = W_TokenParent
		Wave/T wTokenText= T_TokenText
	SetDataFolder dfrSave
	
	nKeys = CountKeys(wTokenParent)

	SetDataFolder ksPkgDF; SetDataFolder LibInfo
		make/n=(nLibs, nKeys)/T/O $"COMBIgorSearchWave"
		wave/T wLibInfo = COMBIgorSearchWave
	SetDataFolder dfrSave
	

	// add loop to get keys
	nPoints = Dimsize(wTokenParent,0)
	iKey = 0
	for (iPoint = 0; iPoint < nPoints; iPoint += 1)
		if (wTokenParent[iPoint] == 0)	// then it is a key
			sDimLabel = GetDimLabelFromKey(wTokenText[iPoint])
			SetDimLabel 1,iKey,$sDimLabel,wLibInfo
			iKey += 1
		endif
	endfor
		
	for (iLib=0; iLib < nLibs; iLib += 1)
	
		sLibInfo = StringFromList(iLib, sHTEMList)
		SetDataFolder dfrTmpDF
			JSONSimple /Q /Z /MAXT=100 sLibInfo
			Wave wTokenType = W_TokenType
			Wave wTokenSize = W_TokenSize
			Wave wTokenParent = W_TokenParent
			Wave/T wTokenText= T_TokenText
		SetDataFolder dfrSave
		
		iPoint = 0
		nPoints = Dimsize(wTokenParent,0)	// nPoints may vary by lib so need to recalc here
		do
			if (wTokenParent[iPoint] == 0)	// then it is a key
				sDimLabel = GetDimLabelFromKey(wTokenText[iPoint])
				iPoint += 1
				sKeyValue = CleanTokenText(wTokenText[iPoint])
				if (!cmpstr(sDimLabel, "id"))
					SetDimLabel 0,iLib,$sKeyValue,wLibInfo	// label the row
				endif
				wLibInfo[iLib][%$sDimLabel] = sKeyValue
			endif
			iPoint += 1
			
		while (iPoint < nPoints)

	endfor

	killdatafolder dfrTmpDF
	return(nLibs)
end
