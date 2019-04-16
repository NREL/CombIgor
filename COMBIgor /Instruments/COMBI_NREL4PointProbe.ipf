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
		 Submenu "NREL 4 Point Probe"
		 	"Load Data",/Q, COMBI_NREL4PointPRobe()
		 	"-"
		 	"Find R squared values",/Q,COMBI_NREL4PointProbe_DoIVFits()
		 end
	end
end	


//returns a list of descriptors for each of the globals used to define loading
Function/S NREL4PointProbe_Descriptions(sGlobalName)
	string sGlobalName
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_NREL4PointProbe_Globals"
	string sReturnstring=""
	strswitch(sGlobalName)
		case "NREL4PointProbe":
			sReturnstring = "NREL 4 Point Probe"
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
		case "sRSLayer":
			sReturnstring = "Sheet Resistance label (ohm/◻):"
			break
		case "sRSSigmaLayer":
			sReturnstring = "Sheet Resistance Error label:"
			break
		case "sRhoLayer":
			sReturnstring = "Resistivity label (ohm-cm):"
			break
		case "sCondLayer":
			sReturnstring = "Conductivity label (Siemen/cm):"
			break
		case "bKeepRawData":
			sReturnstring = "Keep Raw IV data?"
			break
		case "sRawVoltageLayer":
			sReturnstring = "Raw Voltage label (Volts):"
			break
		case "sRawCurrentLayer":
			sReturnstring = "Raw Current label (Amps):"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

function NREL4PointProbe_Define()
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	string sThicknessLayer, sRSLayer, sRSSigmaLayer, sRhoLayer, sCondLayer, bKeepRawData, sRawVoltageLayer, sRawCurrentLayer
	variable vThicknessUnits
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sRSLayer",sProject)))//if project is defined previously, start with those values
		sThicknessLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sThicknessLayer",sProject)
		sRSLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRSLayer",sProject)
		sRSSigmaLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRSSigmaLayer",sProject)
		sRhoLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRhoLayer",sProject)
		sCondLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sCondLayer",sProject)
		bKeepRawData = COMBI_GetInstrumentString(sThisInstrumentName,"bKeepRawData",sProject)
		sRawVoltageLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRawVoltageLayer",sProject)
		sRawCurrentLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRawCurrentLayer",sProject)
		vThicknessUnits = COMBI_GetInstrumentNumber(sThisInstrumentName,"vThicknessUnits",sProject)
	else //not previously defined, start with default values 
		sThicknessLayer = "Skip"
		sRSLayer = "Sheet_Resistance"
		sRSSigmaLayer = "Sheet_Resistance_Error" 
		sRhoLayer = "Resistivity"
		sCondLayer = "Conductivity"
		bKeepRawData = "Yes"
		sRawVoltageLayer = "Voltage_4PP"
		sRawCurrentLayer = "Current_4PP"
		vThicknessUnits = 1E-6
	endif

	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject","",sProject)
	
	// get info for standard file values
	//sThicknessLayer
	sThicknessLayer = COMBI_DataTypePrompt(sProject,sThicknessLayer,NREL4PointProbe_Descriptions("sThicknessLayer"),0,0,1,1)
	if(stringmatch(sThicknessLayer,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sThicknessLayer",sThicknessLayer,sProject)// store global
	if(!stringmatch(sThicknessLayer,"Skip"))
		vThicknessUnits = COMBI_NumberPrompt(vThicknessUnits,"Thickness units in meters:","This value assists in making accurate calculations","Thickness units definition")
		if(numtype(vThicknessUnits)==2)
			COMBI_InstrumentDefinition()
			return -1 
		endif
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vThicknessUnits",num2str(vThicknessUnits),sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vThicknessUnits","",sProject)// store global	
	endif
	
	//sRSLayer
	sRSLayer = COMBI_DataTypePrompt(sProject,sRSLayer,NREL4PointProbe_Descriptions("sRSLayer"),0,1,0,1)
	if(stringmatch(sRSLayer,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRSLayer",sRSLayer,sProject)// store global
	
	//sRSSigmaLayer
	sRSSigmaLayer = COMBI_DataTypePrompt(sProject,sRSSigmaLayer,NREL4PointProbe_Descriptions("sRSSigmaLayer"),0,1,0,1)
	if(stringmatch(sRSSigmaLayer,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRSSigmaLayer",sRSSigmaLayer,sProject)// store global
	
	//sRhoLayer (if not skipping thickness)
	if(!stringmatch(sThicknessLayer,"Skip"))
		sRhoLayer = COMBI_DataTypePrompt(sProject,sRhoLayer,NREL4PointProbe_Descriptions("sRhoLayer"),0,1,0,1)
		if(stringmatch(sRhoLayer,"CANCEL"))
			COMBI_InstrumentDefinition()
			return -1 
		endif
	else
		sRhoLayer = "Skip"
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRhoLayer",sRhoLayer,sProject)// store global	
	
	//sCondLayer (if not skipping thickness)
	if(!stringmatch(sThicknessLayer,"Skip"))
		sCondLayer = COMBI_DataTypePrompt(sProject,sCondLayer,NREL4PointProbe_Descriptions("sCondLayer"),0,1,0,1)
		if(stringmatch(sCondLayer,"CANCEL"))
			COMBI_InstrumentDefinition()
			return -1 
		endif
	else
		sCondLayer = "Skip"
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCondLayer",sCondLayer,sProject)// store global	

	//sRSLayer
	bKeepRawData = COMBI_StringPrompt(bKeepRawData,NREL4PointProbe_Descriptions("bKeepRawData"),"Yes;No","If Yes, then raw data goes into the vector table","Raw Data Option?")
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bKeepRawData",bKeepRawData,sProject)// store global
	
	if(stringmatch(bKeepRawData,"Yes"))
		sRawVoltageLayer = COMBI_DataTypePrompt(sProject,sRawVoltageLayer,NREL4PointProbe_Descriptions("sRawVoltageLayer"),0,1,0,2)
		if(stringmatch(sRawVoltageLayer,"CANCEL"))
			COMBI_InstrumentDefinition()
			return -1 
		endif
		sRawCurrentLayer = COMBI_DataTypePrompt(sProject,sRawCurrentLayer,NREL4PointProbe_Descriptions("sRawCurrentLayer"),0,1,0,2)
		if(stringmatch(sRawCurrentLayer,"CANCEL"))
			return -1 
		endif
	else
		sRawVoltageLayer = "Skip"
		sRawCurrentLayer = "Skip"
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRawVoltageLayer",sRawVoltageLayer,sProject)// store global	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sRawCurrentLayer",sRawCurrentLayer,sProject)// store global	

	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
	
end

function NREL4PointProbe_Load()
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	//get 4PP globals
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	string sThisInstrumentName = "NREL4PointProbe"
	string sThicknessLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sThicknessLayer",sProject)
	string sRSLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRSLayer",sProject)
	string sRSSigmaLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRSSigmaLayer",sProject)
	string sRhoLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRhoLayer",sProject)
	string sCondLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sCondLayer",sProject)
	string bKeepRawData = COMBI_GetInstrumentString(sThisInstrumentName,"bKeepRawData",sProject)
	string sRawVoltageLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRawVoltageLayer",sProject)
	string sRawCurrentLayer = COMBI_GetInstrumentString(sThisInstrumentName,"sRawCurrentLayer",sProject)
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
	endif
	
	//import HDF5 data
	Variable vFileID, vGroupID
	string sBinName
	string sFileLoaded =""
	HDF5OpenFile /R /Z vFileID as ""	// Displays a dialog to open file
	if (V_flag == 0)	// User selected a file?
		sFileLoaded = S_path+S_fileName
		HDF5ListGroup/Z/TYPE=1 vFileID , "/"
		string sMainGroup = stringfromlist(0,S_HDF5ListGroup)
		//load scalar data 
		sBinName = sMainGroup+"/Maps"
		HDF5OpenGroup vFileID , sBinName , vGroupID
		HDF5LoadData/Q /O vGroupID,"SheetResistance"
		HDF5OpenGroup vFileID , sBinName , vGroupID
		HDF5LoadData/Q /O vGroupID,"StandardDeviation"
		//load processed data
		sBinName = sMainGroup+"/ProcessedData"
		HDF5OpenGroup vFileID , sBinName , vGroupID
		HDF5LoadData/Q /O vGroupID,"MeanVoltage" //get mean of all voltage measurements at a particular Sample/current
		//load raw data
		sBinName = sMainGroup+"/RawData"
		HDF5OpenGroup vFileID , sBinName , vGroupID
		HDF5LoadData/Q /O vGroupID,"I_a" //get current
		HDF5CloseFile vFileID
	else
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	//Get Library Name
	string sLibraryName = COMBI_LibraryPrompt(sProject,sMainGroup,"Library Name",0,1,0,1)
	
	//get loaded waves
	wave SheetResistance, StandardDeviation, MeanVoltage, I_a
	
	//move data from arrays (grid to Samples conversion)
	int iRow, iColumn, iSample
	variable vThickness
	for(iRow=0;iRow<vTotalRows;iRow+=1)
		for(iColumn=0;iColumn<vTotalColumns;iColumn+=1)
			iSample = iColumn+iRow*vTotalColumns
			COMBI_GiveScalar(SheetResistance[iRow][iColumn],sProject,sLibraryName,sRSLayer,iSample)
			COMBI_GiveScalar(StandardDeviation[iRow][iColumn],sProject,sLibraryName,sRSSigmaLayer,iSample)
			if(!stringmatch(sThicknessLayer,"Skip"))
				if(numtype(vThicknessUnits)==0)
					if(COMBI_CheckForData(sProject,sLibraryName,sThicknessLayer,1,iSample)==1)//data exists
						wave wThickness = $COMBI_DataPath(sProject,1)+sLibraryName+":"+sThicknessLayer
						vThickness = wThickness[iSample]
						COMBI_GiveScalar((SheetResistance[iRow][iColumn]*vThicknessUnits*(1e2)*vThickness),sProject,sLibraryName,sRhoLayer,iSample)
						COMBI_GiveScalar(1/(SheetResistance[iRow][iColumn]*vThicknessUnits*(1e2)*vThickness),sProject,sLibraryName,sCondLayer,iSample)
					endif
				endif
			endif
		endfor
	endfor
	
	if(stringmatch(bKeepRawData,"Yes"))
		int vRawLength = dimsize(MeanVoltage,1), iRaw
		Make/O/N=(1,2,vRawLength) wTransferWave
		wave wTransferWave = root:wTransferWave
		for(iSample=0;iSample<vTotalSamples;iSample+=1)
			wTransferWave[][][]= nan
			for(iRaw=0;iRaw<vRawLength;iRaw+=1)
				wTransferWave[0][0][iRaw] = MeanVoltage[iSample][iRaw]
				wTransferWave[0][1][iRaw] = I_a[iSample][iRaw]
			endfor
			COMBI_GiveData(wTransferWave,sProject,sLibraryName,sRawVoltageLayer+";"+sRawCurrentLayer,iSample,2)
		endfor
		killwaves wTransferWave
	endif

	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File: "+sFileLoaded
	sLogEntry2 = "Sheet Resistance/Sigma Desitnation: "+sRSLayer+"/"+sRSSigmaLayer
	sLogEntry3 = "Thickness: "+sThicknessLayer+" ("+num2str(vThicknessUnits)+" m)"
	sLogEntry4 = "Calculated Values: Resistivity:"+sRhoLayer+", Condictivity:"+sCondLayer
	sLogEntry5 = "Raw Data Kept: "+bKeepRawData+", Voltage:"+sRawVoltageLayer+", Current:"+sRawCurrentLayer
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	COMBI_Add2Log(sProject,sLibraryName,"NREL4PointProbe",1,sLogText)		
	
	//kill loaded waves
	killwaves SheetResistance, StandardDeviation, MeanVoltage, I_a
	SetDataFolder $sTheCurrentUserFolder 
end

function COMBI_NREL4PointProbe()
	COMBI_GiveGlobal("sInstrumentName","NREL4PointProbe","COMBIgor")
	COMBI_InstrumentDefinition()
end

function COMBI_NREL4PointProbe_DoIVFits()
	//choose Project
	string sProject = COMBI_ChooseProject()
	if(strlen(sProject)==0)
		return -1
	endif
	//choose library
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//get data 2 fit
	string sRawVoltageLayer = COMBI_GetInstrumentString("NREL4PointProbe","sRawVoltageLayer",sProject)
	string sRawCurrentLayer = COMBI_GetInstrumentString("NREL4PointProbe","sRawCurrentLayer",sProject)
	wave/Z wVolts = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sRawVoltageLayer
	wave/Z wAmps = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sRawCurrentLayer
	if(!(waveexists(wVolts)&&waveexists(wAmps)))
		DoAlert/T="No Data to fit" 0,"Hey, can't find data called "+sRawVoltageLayer+" and "+sRawCurrentLayer+" to fit!"
		return -1
	endif
	//R2 storage
	Combi_AddDataType(sProject,sLibrary,"R2_FPP",1)
	wave wR2 = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":R2_FPP"

	variable vSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	int iSample
	for(iSample=0;iSample<vSamples;iSample+=1)
		CurveFit/Q line, wVolts[iSample][*]/X=wAmps[iSample][*]
		wR2[iSample] = V_r2
	endfor
	Killwaves/Z root:W_coef,root:W_sigma 
end






