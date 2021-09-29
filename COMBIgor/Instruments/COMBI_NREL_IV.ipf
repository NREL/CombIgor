#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ May 2018 : Original
// V1.1 Sage Bauers _ 20180513 : Modified names, added initialization options, additional cleanup
// V1.11: Karen Heinselman _ Oct 2018 : Polishing and debugging
// V1.12: Kevin Talley - Added Make text file from mapping grid
// V1.13: Meagan Papac_2019_09_20: Added options to limit voltage ranges for resistance fits, to fit resistance of loaded data, and to calculate conductivity

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Menu "COMBIgor"
	SubMenu "Instruments"
		SubMenu "NREL IV Mapping"
			 "(Loading Measurement Data"
			 "Load Data",/Q, COMBI_NREL_IV()
			 "-"
			 "(Making Measurements"
			 "Make Mapping Coordinates",/Q, COMBI_NREL_IV_MappingCords()
			 "-"
			 "(Process"
			 "Voltage > E field",/Q, COMBI_NREL_IV_Electricfield()
			 "Amps > Current Density",/Q, COMBI_NREL_IV_CurrentDensity()
			 "IV > R", COMBI_NREL_IV_Resistance()
			 "R > Conductivity", COMBI_NREL_IV_ConductivitySetup()
		end
	end
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
//returns a list of descriptors for each of the globals used to define loading
Function/S NREL_IV_Descriptions(sGlobalName)
	string sGlobalName
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_NREL_IV_Globals"
	string sReturnstring =""
	strswitch(sGlobalName)
		case "NREL_IV":
			sReturnstring = "NREL IV Mapping Tool"
			break
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "sVoltage":
			sReturnstring =  "Voltage Label (Volts):"
			break
		case "sCurrent":
			sReturnstring =  "Current Label (Amps):"
			break
		case "bFitResistance":
			sReturnstring =  "Fit for resistance values?"
			break
		case "sResistance":
			sReturnstring =  "Resistance Label (Ohm):"
			break
		case "sResistancePos":
			sReturnstring =  "Positive Resistance Label (Ohm):"
			break
		case "sResistanceNeg":
			sReturnstring =  "Negative Resistance Label (Ohm):"
			break
		case "sResistanceGOF":
			sReturnstring =  "Resistance R^2 Label:"
			break
		case "sResistanceGOFPos":
			sReturnstring =  "Positive Resistance R^2 Label:"
			break
		case "sResistanceGOFNeg":
			sReturnstring =  "Negative Resistance R^2 Label:"
			break
		case "bSeparatePosNeg":
			sReturnstring =  "Fit positive and negative polarity separately?"
			break
		case "bKeepAllRValues":
			sReturnstring =  "Keep resistance values from both polarities?"
			break
		case "sVoltageMin":
			sReturnstring =  "Min voltage for fit:"
			break
		case "sVoltageMinPos":
			sReturnstring =  "Min voltage for positive polarity fit:"
			break
		case "sVoltageMinNeg":
			sReturnstring =  "Min voltage for negative polarity fit:"
			break
		case "sVoltageMaxPos":
			sReturnstring =  "Max voltage for positive polarity fit:"
			break
		case "sVoltageMaxNeg":
			sReturnstring =  "Max voltage for negative polarity fit:"
			break	
		case "sTemps":
			sReturnstring =  "Hot Stage?"
			break
		case "sPlotAll":
			sReturnstring =  "Plot and save all data?"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
function NREL_IV_Define()
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	string sVoltage,sCurrent, bFitResistance, bSeparatePosNeg, sVoltageMin, sVoltageMinPos, sVoltageMinNeg, sVoltageMaxPos, sVoltageMaxNeg
	string sResistance, sResistancePos, sResistanceNeg, sResistanceGOF, sResistanceGOFPos, sResistanceGOFNeg, sTemps, sPlotAll, bKeepAllRValues
	variable vVoltageMin, vVoltageMinPos, vVoltageMinNeg, vVoltageMax, vVoltageMaxPos, vVoltageMaxNeg  
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)))//if project is defined previously, start with those values
		sVoltage = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)
		sCurrent = COMBI_GetInstrumentString(sThisInstrumentName,"sCurrent",sProject)
		bFitResistance = COMBI_GetInstrumentString(sThisInstrumentName,"bFitResistance",sProject)
		bSeparatePosNeg = COMBI_GetInstrumentString(sThisInstrumentName,"bSeparatePosNeg",sProject)
		sVoltageMinPos = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinPos",sProject)
		sVoltageMinNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinNeg",sProject)
		sVoltageMaxPos = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMaxPos",sProject)
		sVoltageMaxNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMaxNeg",sProject)
		sResistance = COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject)
		sResistancePos = COMBI_GetInstrumentString(sThisInstrumentName,"sResistancePos",sProject)
		sResistanceNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceNeg",sProject)
		sResistanceGOF = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOF",sProject)
		sResistanceGOFPos = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOFPos",sProject)
		sResistanceGOFNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOFNeg",sProject)
		sTemps = COMBI_GetInstrumentString(sThisInstrumentName,"sTemps",sProject)
		sPlotAll = COMBI_GetInstrumentString(sThisInstrumentName,"sPlotAll",sProject)
		bKeepAllRValues = COMBI_GetInstrumentString(sThisInstrumentName,"bKeepAllRValues",sProject)
	else //not previously defined, start with default values 
		sVoltage = "IV_Volts"
		sCurrent = "IV_Amps"
		bFitResistance = "Yes"
		bSeparatePosNeg = "Yes"
		sVoltageMinPos = "5"
		sVoltageMinNeg = "5"
		sVoltageMaxPos = "10"
		sVoltageMaxNeg = "10"
		sResistance = "IV_Resistance_Ohm"
		sResistancePos = "IV_ResistancePos_Ohm"
		sResistanceNeg = "IV_ResistanceNeg_Ohm"
		sResistanceGOF = "IV_Resistance_GOF"
		sResistanceGOFPos = "IV_ResistancePos_GOF"
		sResistanceGOFNeg = "IV_ResistanceNeg_GOF"
		sTEMPS = "No"
		sPlotAll = "Yes"
		bKeepAllRValues = "No"
	endif
	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject","",sProject)
	
	// get info for standard file values
	//sVoltage
	sVoltage = COMBI_DataTypePrompt(sProject,sVoltage,NREL_IV_Descriptions("sVoltage"),0,1,0,2)
	if(stringmatch(sVoltage,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltage",sVoltage,sProject)// store global
	
	//sCurrent
	sCurrent = COMBI_DataTypePrompt(sProject,sCurrent,NREL_IV_Descriptions("sCurrent"),0,1,0,2)
	if(stringmatch(sCurrent,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCurrent",sCurrent,sProject)// store global
	
	//sTemps
	string sHelp = "Do the files have a temperature at the end? Like \"_200C\""
	sTemps = COMBI_StringPrompt(sTemps,NREL_IV_Descriptions("sTemps"),"No;Yes",sHelp,"Hot Stage?")
	if(stringmatch(sTemps,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sTEMPS",sTEMPS,sProject)// store global
	
	//sPlotAll
	sPlotAll = COMBI_StringPrompt(sPlotAll,NREL_IV_Descriptions("sPlotAll"),"No;Yes", "Automatically plot and save all data with associated fits.","Plot and save all data and fits?")
	if(stringmatch(sPlotAll,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sPlotAll",sPlotAll,sProject)// store global
	
	//fit resistance?
	bFitResistance = COMBI_StringPrompt(bFitResistance,NREL_IV_Descriptions("bFitResistance"),"Yes;No","Select yes to fit resistance lines to the data and return scalar values","Fit Resistance?")
	if(stringmatch(bFitResistance,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bFitResistance",bFitResistance,sProject)// store global
	
	if(stringmatch("Yes",bFitResistance))
	
		//fit positive and negative separately?
		bSeparatePosNeg = COMBI_StringPrompt(bSeparatePosNeg,NREL_IV_Descriptions("bSeparatePosNeg"),"Yes;No","Separate positive and negative polarity.","Fit positive and negative separately?")
		if(stringmatch(bSeparatePosNeg,"CANCEL"))
			COMBI_InstrumentDefinition()
			return -1 
		endif
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bSeparatePosNeg",bSeparatePosNeg,sProject)// store global

		if(stringmatch("Yes",bSeparatePosNeg))	
			//if globals do not yet exist, set to default values before prompting	
			if(stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinPos",sProject), "NAG") || stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinPos",sProject), ""))		
				sVoltageMinPos = "5"
				sVoltageMaxPos = "10"
				sVoltageMinNeg = "5"
				sVoltageMaxNeg = "10"
			endif
			
			//keep both R values?
			bKeepAllRValues = COMBI_StringPrompt(bKeepAllRValues,NREL_IV_Descriptions("bKeepAllRValues"),"Yes;No","Select yes to keep resistance values calculated from both the positive and negative polarities","Keep resistance values from both polarities?")
			if(stringmatch(bKeepAllRValues,"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bKeepAllRValues",bKeepAllRValues,sProject)// store global
		
			//voltage minimum for positive fit
			vVoltageMinPos = COMBI_NumberPrompt(str2num(sVoltageMinPos),NREL_IV_Descriptions("sVoltageMinPos"),"Enter minimum voltage value for positive polarity fit. Absolute value of voltage will be compared to this value.","Voltage minimum (positive).")
			if(stringmatch(num2str(vVoltageMinPos),"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltageMinPos",num2str(vVoltageMinPos),sProject)// store global
			
			//voltage minimum for negative fit
			vVoltageMinNeg = COMBI_NumberPrompt(str2num(sVoltageMinNeg),NREL_IV_Descriptions("sVoltageMinNeg"),"Enter minimum voltage value for negative polarity fit. Absolute value of voltage will be compared to this value.","Voltage minimum (negative).")
			if(stringmatch(num2str(vVoltageMinNeg),"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltageMinNeg",num2str(vVoltageMinNeg),sProject)// store global		
			
			//voltage maximum for positive fit
			vVoltageMaxPos = COMBI_NumberPrompt(str2num(sVoltageMaxPos),NREL_IV_Descriptions("sVoltageMaxPos"),"Enter maximum voltage value for positive polarity fit. Absolute value of voltage will be compared to this value.","Voltage maximum (positive).")
			if(stringmatch(num2str(vVoltageMaxPos),"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltageMaxPos",num2str(vVoltageMaxPos),sProject)// store global
			
			//voltage maximum for negative fit
			vVoltageMaxNeg = COMBI_NumberPrompt(str2num(sVoltageMaxNeg),NREL_IV_Descriptions("sVoltageMaxNeg"),"Enter maximum voltage value for negative polarity fit. Absolute value of voltage will be compared to this value.","Voltage maximum (negative).")
			if(stringmatch(num2str(vVoltageMaxNeg),"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltageMaxNeg",num2str(vVoltageMaxNeg),sProject)// store global		
			
			if(stringmatch("Yes", bKeepAllRValues))		
			
				//if globals do not exist, set to default values
				if(stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sResistancePos",sProject), "NAG"))		
					sResistancePos = "IV_ResistancePos_Ohm"
					sResistanceNeg = "IV_ResistanceNeg_Ohm"
					sResistanceGOFPos = "IV_ResistancePos_GOF"
					sResistanceGOFNeg = "IV_ResistanceNeg_GOF"
				endif
			
				//resistance (positive polarity)
				sResistancePos = COMBI_DataTypePrompt(sProject,sResistancePos,NREL_IV_Descriptions("sResistancePos"),0,1,0,1)
				if(stringmatch(sResistancePos,"CANCEL"))
					COMBI_InstrumentDefinition()
					return -1 
				endif
				COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistancePos",sResistancePos,sProject)// store global
				
				//resistance (negative polarity)
				sResistanceNeg = COMBI_DataTypePrompt(sProject,sResistanceNeg,NREL_IV_Descriptions("sResistanceNeg"),0,1,0,1)
				if(stringmatch(sResistanceNeg,"CANCEL"))
					COMBI_InstrumentDefinition()
					return -1 
				endif
				COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceNeg",sResistanceNeg,sProject)// store global
				
				//resistanceGOF (positive polarity)
				sResistanceGOFPos = COMBI_DataTypePrompt(sProject,sResistanceGOFPos,NREL_IV_Descriptions("sResistanceGOFPos"),0,1,0,1)
				if(stringmatch(sResistanceGOFPos,"CANCEL"))
					COMBI_InstrumentDefinition()
					return -1 
				endif
				COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOFPos",sResistanceGOFPos,sProject)// store global
				
				//resistanceGOF (negative polarity)
				sResistanceGOFNeg = COMBI_DataTypePrompt(sProject,sResistanceGOFNeg,NREL_IV_Descriptions("sResistanceGOFNeg"),0,1,0,1)
				if(stringmatch(sResistanceGOFNeg,"CANCEL"))
					COMBI_InstrumentDefinition()
					return -1 
				endif
				COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOFNeg",sResistanceGOFNeg,sProject)// store global
			
			//fitting polarities separately, but only keeping one resistance value
			elseif(stringmatch("No", bKeepAllRValues))	
				
				//if globals do not exist, set to default values
				if(stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject), "NAG") || stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject), ""))		
					sResistance = "IV_Resistance_Ohm"
					sResistanceGOF = "IV_Resistance_GOF"
				endif
				
				//resistance
				sResistance = COMBI_DataTypePrompt(sProject,sResistance,NREL_IV_Descriptions("sResistance"),0,1,0,1)
				if(stringmatch(sResistance,"CANCEL"))
					COMBI_InstrumentDefinition()
					return -1 
				endif
				COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistance",sResistance,sProject)// store global
				
				//resistanceGOF
				sResistanceGOF = COMBI_DataTypePrompt(sProject,sResistanceGOF,NREL_IV_Descriptions("sResistanceGOF"),0,1,0,1)
				if(stringmatch(sResistanceGOF,"CANCEL"))
					COMBI_InstrumentDefinition()
					return -1 
				endif
				COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOF",sResistanceGOF,sProject)// store global
			endif
			
		endif 
		//one fit applied across entire spectrum (excluding voltages indicated by min and max values)
		if(stringmatch("No",bSeparatePosNeg))	
			
			//if globals do not exist, set to default values
			if(stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject), "NAG")||stringmatch(COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject), ""))		
				sVoltageMaxNeg = "10"
				sVoltageMaxPos = "10"
				sResistance = "IV_Resistance_Ohm"
				sResistanceGOF = "IV_Resistance_GOF"
			endif
			
			//positive voltage maximum for fit
			vVoltageMaxPos = COMBI_NumberPrompt(str2num(sVoltageMaxPos),NREL_IV_Descriptions("sVoltageMaxPos"),"Enter maximum positive voltage value for fit.","Positive voltage limit:")
			if(stringmatch(num2str(vVoltageMaxPos),"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltageMaxPos",num2str(vVoltageMaxPos),sProject)// store global
			
			//negative voltage maximum for fit
			vVoltageMaxNeg = COMBI_NumberPrompt(str2num(sVoltageMaxNeg),NREL_IV_Descriptions("sVoltageMaxNeg"),"Enter maximum positive voltage value for fit.","Positive voltage limit:")
			if(stringmatch(num2str(vVoltageMaxNeg),"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sVoltageMaxNeg",num2str(vVoltageMaxNeg),sProject)// store global
			
			//resistance
			sResistance = COMBI_DataTypePrompt(sProject,sResistance,NREL_IV_Descriptions("sResistance"),0,1,0,1)
			if(stringmatch(sResistance,"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistance",sResistance,sProject)// store global
			
			//resistanceGOF
			sResistanceGOF = COMBI_DataTypePrompt(sProject,sResistanceGOF,NREL_IV_Descriptions("sResistanceGOF"),0,1,0,1)
			if(stringmatch(sResistanceGOF,"CANCEL"))
				COMBI_InstrumentDefinition()
				return -1 
			endif
			COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOF",sResistanceGOF,sProject)// store global
		endif
	
	//else if resistance is not to be fit
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistance","",sProject)// store global
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOF","",sProject)// store global
	endif
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
function NREL_IV_Load()
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 

	//get globals
	string sThisInstrumentName = "NREL_IV"
	string sCurrent = COMBI_GetInstrumentString(sThisInstrumentName,"sCurrent",sProject)
	string sVoltage = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)
	string bFitResistance = COMBI_GetInstrumentString(sThisInstrumentName,"bFitResistance",sProject)
	string bSeparatePosNeg = COMBI_GetInstrumentString(sThisInstrumentName,"bSeparatePosNeg",sProject)
//	string sVoltageMin = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMin",sProject)
	string sVoltageMinPos = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinPos",sProject)
	string sVoltageMinNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinNeg",sProject)
	//string sVoltageMax = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMax",sProject)
	string sVoltageMaxPos = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMaxPos",sProject)
	string sVoltageMaxNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMaxNeg",sProject)
	string sResistance = COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject)
	string sResistancePos = COMBI_GetInstrumentString(sThisInstrumentName,"sResistancePos",sProject)
	string sResistanceNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceNeg",sProject)
	string sResistanceGOF = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOF",sProject)
	string sResistanceGOFPos = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOFPos",sProject)
	string sResistanceGOFNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOFNeg",sProject)
	string sTemps = COMBI_GetInstrumentString(sThisInstrumentName,"sTemps",sProject)
	string sPlotAll = COMBI_GetInstrumentString(sThisInstrumentName,"sPlotAll",sProject)
	string bKeepAllRValues = COMBI_GetInstrumentString(sThisInstrumentName,"bKeepAllRValues",sProject)
	
	//get project globals
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)

	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O pLoadPath
	else
		NewPath/Z/Q/O pLoadPath
	endif
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	string sAllFiles = IndexedFile(pLoadPath,-1,".csv")
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	string sFirstFile = removeending(IndexedFile(pLoadPath,0,".csv"),".csv")
	variable vFirstFileNameLength = strlen(sFirstFile)
	
	String expr
	string sSampleNamePart, sContactNumber, sPolarity, sMeasure, sThisTemp
	if(stringmatch(sTEMPs,"Yes"))//with temps
		expr="([[:ascii:]]*)_Contact([[:digit:]]*)_High([[:alpha:]]*)_M([[:digit:]]*)_([[:digit:]]*)C"
		SplitString/E=(expr) sFirstFile, sSampleNamePart, sContactNumber, sPolarity, sMeasure, sThisTemp
	else //without temps
		expr="([[:ascii:]]*)_Contact([[:digit:]]*)_High([[:alpha:]]*)_M([[:digit:]]*)"
		SplitString/E=(expr) sFirstFile, sSampleNamePart, sContactNumber, sPolarity, sMeasure
	endif
	
	//Get Library Name
	string sLibraryName = COMBI_LibraryPrompt(sProject,sSampleNamePart,"Library Name",0,1,0,1)
	if(stringMatch(sLibraryName, "CANCEL"))
		return -1
	endif
	
	//check for both things
	string sPolaritySettings =""
	int iFile, vMeasurement, vContact, vTotalMeasurements = 0, vTotalContacts = 0
	string sThisFile
	string sAllTemps =""
	for(iFile=0;iFile<vNumberOfFiles;iFile+=1)
		sThisFile = removeending(IndexedFile(pLoadPath,iFile,".csv"),".csv")
		if(stringmatch(sTEMPs,"Yes"))//with temps
			SplitString/E=(expr) sThisFile, sSampleNamePart, sContactNumber, sPolarity, sMeasure, sThisTemp
		else //without temps
			SplitString/E=(expr) sThisFile, sSampleNamePart, sContactNumber, sPolarity, sMeasure
		endif
		//polarity settings
		if(stringmatch(sPolarity,"Neg"))
			if(WhichListItem(sPolarity,sPolaritySettings)<0)
				sPolaritySettings = AddListItem(sPolarity,sPolaritySettings)
			endif
		elseif(stringmatch(sPolarity,"Pos"))
			if(WhichListItem(sPolarity,sPolaritySettings)<0)
				sPolaritySettings = AddListItem(sPolarity,sPolaritySettings)
			endif
		endif
		//number of measurements
		vMeasurement = str2num(sMeasure)
		if(vMeasurement>vTotalMeasurements)
			vTotalMeasurements = vMeasurement
		endif
		//number of contacts
		vContact = str2num(sContactNumber)
		if(vContact>vTotalContacts)
			vTotalContacts = vContact
		endif
		//temp list
		if(stringmatch(sTEMPs,"Yes"))//with temps
			if(WhichListItem(sThisTemp,sAllTemps)==-1)//	new temp
				sAllTemps = AddListItem(sThisTemp,sAllTemps,";",inf)
			endif
		else
			sAllTemps =";"//list with one blank item
		endif
	endfor
	
	//contacts match sample number??
	variable vFirstSample = 1
	if(vTotalSamples!=vTotalContacts)
		DoAlert/T="Mismatched number of samples",0,"COMBIgor expects the same number of contacts as samples. For this folder, COMBIgor has found "+num2str(vTotalContacts)+" contacts measured but "+num2str(vTotalSamples)+" samples in the mapping grid for this project."
		if(vTotalSamples>vTotalContacts)
			DoAlert/T="Is this a subset of samples?",1,"Are you trying to load a partial measurement?"
			if(V_flag==1)
				vFirstSample = COMBI_NumberPrompt(vFirstSample,"What was the first sample number measured?","This will shift Contact #1 to this contact number and proceed with loading","Define sampling offset")
			else
				return -1
			endif
		else
			return-1
		endif
	endif
	
	string sFileName
	string sDataTypes = "NREL_IV;"
	string sPosWaves, sNegWaves, sIVWaves, sMeasureTag ="", sTempTag
	int vPosLength, vNegLength, vPosTypes, vNegTypes, vIVLength, vIVTypes, vAmpLength, vVoltLength, itemp
		
	for(itemp=0;itemp<itemsInList(sAllTemps);itemp+=1)
		for(vMeasurement=1;vMeasurement<=vTotalMeasurements;vMeasurement+=1)
			if(vTotalMeasurements>1)
				sMeasureTag = "_M"+num2str(vMeasurement)
			endif
			if(stringmatch(sTEMPs,"Yes"))//with temps
				sTempTag = "_"+stringfromlist(itemp,sAllTemps)+"C"
			else //without temps
				sTempTag = ""
			endif
			
			//final storage waves
			COMBI_IntoDataFolder(sProject,2)
			SetDataFolder $sLibraryName
			Make/O/N=(vTotalSamples,1) $sCurrent+sMeasureTag+sTempTag
			Make/O/N=(vTotalSamples,1) $sVoltage+sMeasureTag+sTempTag
			setdatafolder root:
			wave wCurrent = $Combi_DataPath(sProject,2)+sLibraryName+":"+sCurrent+sMeasureTag+sTempTag
			wave wVoltage = $Combi_DataPath(sProject,2)+sLibraryName+":"+sVoltage+sMeasureTag+sTempTag
			int iNeg, iPos, iIV
			sDataTypes = sDataTypes+";"+sCurrent+sMeasureTag+sTempTag+";"+sVoltage+sMeasureTag+sTempTag+";"
			
			if(itemsinlist(sPolaritySettings)==2)//both polarity 
				
				//initialize loaded min and max values of voltage
				variable vMinLoadVPos = inf
				variable vMinLoadVNeg = inf
				variable vMaxLoadVPos = 0
				variable vMaxLoadVNeg = 0
				
				for(vContact=vFirstSample;vContact<=vFirstSample+vTotalContacts-1;vContact+=1)
					sFileName = sSampleNamePart+"_Contact"+num2str(vContact-vFirstSample+1)+"_HighPos_M"+num2str(vMeasurement)+sTempTag+".csv"
					LoadWave/Q/N=PosIVLoaded/J/O/L={11,12,0,0,0}/P=pLoadPath/M sFIleName
					sPosWaves = S_waveNames
					if(V_flag==0)
						Print sFIleName+" was expected but not found during load."
					else
						wave wPosWave = $"root:"+stringfromlist(0,sPosWaves)
						vPosLength = dimsize(wPosWave,0)
						vPosTypes = dimsize(wPosWave,1)
					endif
		
					sFileName = sSampleNamePart+"_Contact"+num2str(vContact-vFirstSample+1)+"_HighNeg_M"+num2str(vMeasurement)+sTempTag+".csv"
					LoadWave/Q/N=NegIVLoaded/J/O/L={11,12,0,0,0}/P=pLoadPath/M sFIleName
					sNegWaves = S_waveNames
					if(V_flag==0)
						Print sFileName+" was expected but not found during load."
					else
						wave wNegWave = $"root:"+stringfromlist(0,sNegWaves)
						vNegLength = dimsize(wNegWave,0)
						vNegTypes = dimsize(wNegWave,1)
					endif
					
					//redim				
					vAmpLength = dimsize(wCurrent,1)
					vVoltLength = dimsize(wVoltage,1)
					if(vAmpLength<vNegLength+vPosLength)
						redimension/N=(-1,vNegLength+vPosLength) wCurrent
						wCurrent[][(vAmpLength-1),(vNegLength+vPosLength-1)] = nan
					endif
					if(vVoltLength<vNegLength+vPosLength)
						redimension/N=(-1,vNegLength+vPosLength) wVoltage
						wVoltage[][(vVoltLength-1),(vNegLength+vPosLength-1)] = nan
					endif
					
					//move negative values
					for(iNeg=0;iNeg<vNegLength;iNeg+=1)
						wCurrent[vContact-1][iNeg] = wNegWave[vNegLength-iNeg-1][0]
						wVoltage[vContact-1][iNeg] = wNegWave[vNegLength-iNeg-1][1]
						//on first pass, find min and max negative voltage
						if(vContact==vFirstSample)
							if(wNegWave[vNegLength-iNeg-1][1] < vMinLoadVNeg)
								vMinLoadVNeg = wNegWave[vNegLength-iNeg-1][1]
							endif
							if(wNegWave[vNegLength-iNeg-1][1] > vMaxLoadVNeg)
								vMaxLoadVNeg = wNegWave[vNegLength-iNeg-1][1]
							endif
						endif
					endfor
					
					//move positive values
					for(iPos=0;iPos<vPosLength;iPos+=1)
						wCurrent[vContact-1][iPos+vNegLength] = wPosWave[iPos][0]
						wVoltage[vContact-1][iPos+vNegLength] = wPosWave[iPos][1]
						//on first pass, find min and max positive voltage 
						if(vContact==vFirstSample)
							if(wPosWave[iPos][1] < vMinLoadVPos)
								vMinLoadVPos = wPosWave[iPos][1]
							endif
							if(wPosWave[iPos][1] > vMaxLoadVPos)	
								vMaxLoadVPos = wPosWave[iPos][1]
							endif
						endif	
					endfor
					
					//kill loaded waves
					killwaves/Z wNegWave, wPosWave			
				endfor	
				
			elseif(itemsinlist(sPolaritySettings)==1)//Single Polarity 
			
				//initialize min and max voltage values
				vMaxLoadVPos = 0
				vMinLoadVNeg = inf
			
				for(vContact=vFirstSample;vContact<=vTotalSamples-1;vContact+=1)
					//get file
					sFileName = sSampleNamePart+"_Contact"+num2str(vContact-vFirstSample+1)+"_High"+stringFromList(0,sPolaritySettings)+"_M"+num2str(vMeasurement)+sTempTag+".csv"
					LoadWave/Q/N=IVLoaded/J/O/L={11,12,0,0,0}/P=pLoadPath sFIleName
					sIVWaves = S_waveNames
					if(V_flag==0)
						Print sFileName+" was expected but not found during load."
					else
						wave wIVWave = $"root:"+stringfromlist(0,sIVWaves)
						vIVLength = dimsize(wIVWave,0)
						vIVTypes = dimsize(wIVWave,1)
					endif
					
					//redim				
					vAmpLength = dimsize(wCurrent,1)
					vVoltLength = dimsize(wVoltage,1)
					if(vAmpLength<vIVLength)
						redimension/N=(-1,vIVLength) wCurrent
						wCurrent[][(vAmpLength-1),(vIVLength-1)] = nan
					endif
					if(vVoltLength<vIVLength)
						redimension/N=(-1,vIVLength) wVoltage
						wVoltage[][(vVoltLength-1),(vIVLength-1)] = nan
					endif
					
					//move values
					for(iIV=0;iIV<vIVLength;iIV+=1)
						wCurrent[vContact-1][iIV] = wIVWave[iIV][0]
						wVoltage[vContact-1][iIV] = wIVWave[iIV][1]
						if(wIVWave[iIV][1] > vMaxLoadVPos)
							vMaxLoadVPos = wIVWave[iIV][1]
						endif
						if(wIVWave[iIV][1] < vMinLoadVNeg)
							vMinLoadVNeg = wIVWave[iIV][1]
						endif
					endfor
					
					//kill loaded waves
					killwaves/Z wIVWave
				endfor	
			endif	
		endfor
	endfor
	
	//resistance values - curve through the origin
	int iSample
	
	if(stringMatch(sPlotAll, "Yes"))
		DoAlert 0,"Select a path to save plots." 
		NewPath pPathToSave
		//get sample wave
		wave wSampleWave = $"root:COMBIgor:" + sProject + ":Data:FromMappingGrid:Sample"
		//make library path for creating waves
		string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibraryName + ":" 
	endif
	
	if(stringmatch(bFitResistance,"Yes"))
		if(vMaxLoadVPos < str2num(sVoltageMaxPos))
			DoAlert 2,"Maximum loaded positive voltage is less than user-defined value. Would you like to define a different value for these fits?"
			if(V_Flag == 1) 
				prompt sVoltageMaxPos, "Redefine voltage limit"
				doPrompt "New maximum positive voltage value:", sVoltageMaxPos
			endif
			if(V_Flag == 2)
				sVoltageMaxPos = num2str(vMaxLoadVPos)
			endif 
			if(V_Flag == 3)
				return -1
			endif 
		endif
		if(vMaxLoadVNeg < str2num(sVoltageMaxNeg))
			DoAlert 2,"Maximum loaded negative voltage is less than user-defined value. Would you like to define a different value for these fits?"
			if(V_Flag == 1) 
				prompt sVoltageMaxNeg, "Redefine voltage limit"
				doPrompt "New maximum negative voltage value:", sVoltageMaxNeg
			endif
			if(V_Flag == 2)
				sVoltageMaxNeg = num2str(vMaxLoadVNeg)
			endif
			if(V_Flag == 3)
				return -1
			endif 
		endif
		if(stringmatch(bSeparatePosNeg,"Yes"))	
			if(vMinLoadVPos > str2num(sVoltageMinPos))
				DoAlert 2,"Minimum loaded positive voltage is greater than user-defined value. Would you like to define a different value for these fits?"
				if(V_Flag == 1) 
					prompt sVoltageMinPos, "Redefine voltage limit"
					doPrompt "New minimum positive voltage value:", sVoltageMinPos
				endif
				if(V_Flag == 2)
					sVoltageMinPos = num2str(vMinLoadVPos)
				endif 
				if(V_Flag == 3)
					return -1
				endif 
			endif
			if(vMinLoadVNeg > str2num(sVoltageMinNeg))
				DoAlert 2,"Minimum loaded negative voltage is greater than user-defined value. Would you like to define a different value for these fits?"
				if(V_Flag == 1) 
					prompt sVoltageMinNeg, "Redefine voltage limit"
					doPrompt "New minimum negative voltage value:", sVoltageMinNeg
				endif
				if(V_Flag == 2)
					sVoltageMinNeg = num2str(vMinLoadVNeg)
				endif 
				if(V_Flag == 3)
					return -1
				endif 
			endif
		endif
	endif
	
	if(stringmatch(bFitResistance,"Yes") && stringMatch(bSeparatePosNeg,"No"))
		for(itemp=0;itemp<itemsInList(sAllTemps);itemp+=1)
			for(vMeasurement=1;vMeasurement<=vTotalMeasurements;vMeasurement+=1)
				if(vTotalMeasurements>1)
					sMeasureTag = "_M"+num2str(vMeasurement)
				else
					sMeasureTag = ""
				endif
				if(stringmatch(sTEMPs,"Yes"))//with temps
					sTempTag = "_"+stringfromlist(itemp,sAllTemps)+"C"
				else //without temps
					sTempTag = ""
				endif
				wave wCurrent = $Combi_DataPath(sProject,2)+sLibraryName+":"+sCurrent+sMeasureTag+sTempTag
				wave wVoltage = $Combi_DataPath(sProject,2)+sLibraryName+":"+sVoltage+sMeasureTag+sTempTag
				COMBI_IntoDataFolder(sProject,1)
				SetDataFolder $sLibraryName
				Make/O/N=(vTotalSamples) $sResistance+sMeasureTag+sTempTag
				Make/O/N=(vTotalSamples) $sResistanceGOF+sMeasureTag+sTempTag
				SetDataFolder root: 
				wave wResistance = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistance+sMeasureTag+sTempTag
				wave wResistanceGOF = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOF+sMeasureTag+sTempTag
				sDataTypes = sDataTypes+";"+sResistance+sMeasureTag+sTempTag+";"+sResistanceGOF+sMeasureTag+sTempTag+";"
				Make/O/N=(2) wCoefs
				wave wCoefs = root:wCoefs
				for(iSample=vFirstSample-1;iSample<vFirstSample+vTotalContacts-1;iSample+=1)
					variable iPosMax, iNegMax
					variable i = 0
					do
						iPosMax = i
						i += 1
					while(wVoltage[0][i] < str2num(sVoltageMaxPos))
					i = 0
					do
						iNegMax = i
						i += 1
					while(Abs(wVoltage[0][i]) > str2num(sVoltageMaxNeg))
					CurveFit/Q/W=2 line, kwCWave=wCoefs, wVoltage[iSample][iNegMax, iPosMax]/X=wCurrent[iSample][iNegMax, iPosMax]
					wResistance[iSample] = wCoefs[1]
					wResistanceGOF[iSample] = V_r2
				
					//Plots all IV data and fits and saves them automatically to the folder the user selects
					if(stringMatch(sPlotAll, "Yes"))
						string sSampleName = getDimLabel(wSampleWave, 0, iSample)
						string sSample = num2str(iSample + 1)
						
						//make and populate plotting wave for data and fits
						string sPlottingWaveName = "PlotWave"
						Make/N=(dimSize(wVoltage, 1), 4)/O wPlottingWave
						wave wPlottingWave = $sLibraryPath + sPlottingWaveName
						//Column 0 is voltage
						wPlottingWave[][0] = wVoltage[iSample][p]
						//Column 1 is measured current
						wPlottingWave[][1] = wCurrent[iSample][p] 
						//Column 2 is calculated current from fit
						wPlottingWave[][2] = (wPlottingWave[p][0] - wCoefs[0])/wCoefs[1]
					
						//make plot
						Display/N=IVPlot wPlottingWave[][0] vs wPlottingWave[][1]
						ModifyGraph mode=3,marker=19
						ModifyGraph rgb(wPlottingWave)=(0,0,0)
						Label left "Potential (V)"
						Label bottom "Current (A)"
						Legend/C/N=text0/J/F=0/A=RC "\\s(wPlottingWave) Data\r\\s(FitTrace0) Fit"		
						
						//append pos fit
						AppendToGraph/W=IVPlot wPlottingWave[][0]/TN=FitTrace0 vs wPlottingWave[][2]
						ModifyGraph rgb(FitTrace0)=(3,52428,1)
						ModifyGraph lsize(FitTrace0)=2
	
						SavePICT/O/P=pPathToSave as "IVPlot_" + sSampleName + "_" + sLibraryName + sMeasureTag + sTempTag
						killWindow IVPlot
					endif
				
				endfor
			endfor
			killwaves/Z wCoefs, root:W_sigma
			Killvariables/Z root:V_chisq,root:V_endChunk,root:V_endCol,root:V_endLayer,root:V_endRow,root:V_nheld,root:V_npnts,root:V_nterms,root:V_numINFs,root:V_numNaNs,root:V_Pr,root:V_q,root:V_Rab,root:V_r2,root:V_siga,root:V_sigb,root:V_startChunk,root:V_startCol,root:V_startLayer,root:V_startRow
		endfor
	endif
	
	//resistance values - separate positive and negative for fit
	if(stringmatch(bFitResistance,"Yes") && stringMatch(bSeparatePosNeg,"Yes"))
		for(itemp=0;itemp<itemsInList(sAllTemps);itemp+=1)
			for(vMeasurement=1;vMeasurement<=vTotalMeasurements;vMeasurement+=1)
				if(vTotalMeasurements>1)
					sMeasureTag = "_M"+num2str(vMeasurement)
				else
					sMeasureTag = ""
				endif
				if(stringmatch(sTEMPs,"Yes"))//with temps
					sTempTag = "_"+stringfromlist(itemp,sAllTemps)+"C"
				else //without temps
					sTempTag = ""
				endif
				wave wCurrent = $Combi_DataPath(sProject,2)+sLibraryName+":"+sCurrent+sMeasureTag+sTempTag
				wave wVoltage = $Combi_DataPath(sProject,2)+sLibraryName+":"+sVoltage+sMeasureTag+sTempTag
				if(stringMatch(bKeepAllRValues, "No"))
					COMBI_IntoDataFolder(sProject,1)
					SetDataFolder $sLibraryName
					Make/O/N=(vTotalSamples) $sResistance+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceGOF+sMeasureTag+sTempTag
					wave wResistance = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistance+sMeasureTag+sTempTag
					wave wResistanceGOF = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOF+sMeasureTag+sTempTag
					sDataTypes = sDataTypes+";"+sResistance+sMeasureTag+sTempTag+";"+sResistanceGOF+sMeasureTag+sTempTag+";"
					SetDataFolder root: 
				elseif(stringMatch(bKeepAllRValues, "Yes"))
					COMBI_IntoDataFolder(sProject,1)
					SetDataFolder $sLibraryName
					//positive polarity
					Make/O/N=(vTotalSamples) $sResistancePos+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceGOFPos+sMeasureTag+sTempTag
					wave wResistancePos = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistancePos+sMeasureTag+sTempTag
					wave wResistanceGOFPos = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOFPos+sMeasureTag+sTempTag
					sDataTypes = sDataTypes+";"+sResistancePos+sMeasureTag+sTempTag+";"+sResistanceGOFPos+sMeasureTag+sTempTag+";"
					//negative polarity
					Make/O/N=(vTotalSamples) $sResistanceNeg+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceGOFNeg+sMeasureTag+sTempTag
					wave wResistanceNeg = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceNeg+sMeasureTag+sTempTag
					wave wResistanceGOFNeg = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOFNeg+sMeasureTag+sTempTag
					sDataTypes = sDataTypes+";"+sResistanceNeg+sMeasureTag+sTempTag+";"+sResistanceGOFNeg+sMeasureTag+sTempTag+";"
					SetDataFolder root: 
				endif
				
				Make/O/N=(2) wCoefsPos
				Make/O/N=(2) wCoefsNeg
				//MP are these necessary?
				wave wCoefsPos = root:wCoefsPos		
				wave wCoefsNeg = root:wCoefsNeg
				//find columns of min voltage (neg and pos)
				variable iPosMin, iNegMin
				variable vR2Neg, vR2Pos
				i = 0
				
				do
					iPosMin = i
					i += 1
				while(wVoltage[0][i] < str2num(sVoltageMinPos))
				i = 0
				
				do
					iPosMax = i
					i += 1
				while(wVoltage[0][i] < str2num(sVoltageMaxPos))
				i = 0
				
				do
					iNegMin = i
					i += 1 
				while(Abs(wVoltage[0][i]) > str2num(sVoltageMinNeg))
				i = 0
				
				do
					iNegMax = i
					i += 1
				while(Abs(wVoltage[0][i]) > str2num(sVoltageMaxNeg))
				
				for(iSample=vFirstSample-1;iSample<vFirstSample+vTotalContacts-1;iSample+=1)
					CurveFit/Q/W=2 line, kwCWave=wCoefsPos, wVoltage[iSample][iPosMin, iPosMax]/X=wCurrent[iSample][iPosMin, iPosMax]
					VR2Pos = V_r2
					CurveFit/Q/W=2 line, kwCWave=wCoefsNeg, wVoltage[iSample][iNegMax, iNegMin]/X=wCurrent[iSample][iNegMax, iNegMin]
					VR2Neg = V_r2
					
					if(stringMatch(bKeepAllRValues, "No"))
						if(VR2Pos >= VR2Neg)
							wResistance[iSample] = wCoefsPos[1]
							wResistanceGOF[iSample] = VR2Pos
						elseif(VR2Pos < VR2Neg)
							wResistance[iSample] = wCoefsNeg[1]
							wResistanceGOF[iSample] = VR2Neg
						endif
					elseif(stringMatch(bKeepAllRValues, "Yes"))
						wResistancePos[iSample] = wCoefsPos[1]
						wResistanceGOFPos[iSample] = VR2Pos
						wResistanceNeg[iSample] = wCoefsNeg[1]
						wResistanceGOFNeg[iSample] = VR2Neg
					endif
					
					//Plots all IV data and fits and saves them automatically to the folder the user selects
					if(stringMatch(sPlotAll, "Yes"))

						//select path for saving
					 	//string sPathToSave = Combi_ExportPath("New")
						sSampleName = getDimLabel(wSampleWave, 0, iSample)
						sSample = num2str(iSample + 1)
						
						//make and populate plotting wave for data and fits
						sPlottingWaveName = "PlotWave"
						Make/N=(dimSize(wVoltage, 1), 4)/O wPlottingWave
						wave wPlottingWave = $sLibraryPath + sPlottingWaveName
						//Column 0 is voltage
						wPlottingWave[][0] = wVoltage[iSample][p]
						//Column 1 is measured current
						wPlottingWave[][1] = wCurrent[iSample][p] 
						//Column 2 is calculated current from positive fit
						wPlottingWave[][2] = (wPlottingWave[p][0] - wCoefsPos[0])/wCoefsPos[1]
						//Column 3 is calculated current from negative fit
						wPlottingWave[][3] = (wPlottingWave[p][0] - wCoefsNeg[0])/wCoefsNeg[1]
					
						//make plot
						Display/N=IVPlot wPlottingWave[][0] vs wPlottingWave[][1]
						ModifyGraph mode=3,marker=19
						ModifyGraph rgb(wPlottingWave)=(0,0,0)
						Label left "Potential (V)"
						Label bottom "Current (A)"
						Legend/C/N=text0/J/F=0/A=RC "\\s(wPlottingWave) Data\r\\s(FitTrace0) Fit"
						
						//append pos fit
						AppendToGraph/W=IVPlot wPlottingWave[][0]/TN=FitTrace0 vs wPlottingWave[][2]
						ModifyGraph rgb(FitTrace0)=(3,52428,1)
						ModifyGraph lsize(FitTrace0)=2
						
						//append neg fit
						AppendToGraph/W=IVPlot wPlottingWave[][0]/TN=FitTrace1 vs wPlottingWave[][3]
						ModifyGraph rgb(FitTrace1)=(65535,0,0)
						ModifyGraph lsize(FitTrace1)=2
	
						SavePICT/O/P=pPathToSave as "IVPlot_" + sSampleName + "_" + sLibraryName + sMeasureTag + sTempTag
						killWindow IVPlot
					endif
				endfor
			endfor
			killwaves/Z wCoefsPos, wCoefsNeg, root:W_sigma
			Killvariables/Z root:V_chisq,root:V_endChunk,root:V_endCol,root:V_endLayer,root:V_endRow,root:V_nheld,root:V_npnts,root:V_nterms,root:V_numINFs,root:V_numNaNs,root:V_Pr,root:V_q,root:V_Rab,root:V_r2,root:V_siga,root:V_sigb,root:V_startChunk,root:V_startCol,root:V_startLayer,root:V_startRow
		endfor
	endif
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "NREL IV mapping data loaded."
	sLogEntry2 = "Source Folder: "+sThisLoadFolder
	sLogEntry3 = "Polarity Types: "+ replaceString(";",sPolaritySettings,"")
	sLogEntry4 = "Samples: "+num2str(vFirstSample)+" to "+num2str(vTotalContacts)
	sLogEntry5 = "Total Measurements: "+num2str(vTotalMeasurements)
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	COMBI_Add2Log(sProject,sLibraryName,sDataTypes,1,sLogText)		
	
	SetDataFolder $sTheCurrentUserFolder 
end

function COMBI_NREL_IV()
	COMBI_GiveGlobal("sInstrumentName","NREL_IV","COMBIgor")
	COMBI_InstrumentDefinition()
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
function COMBI_NREL_IV_MappingCords()
	COMBI_SaveUsersDataFolder()//save user folder
	setdatafolder root:// go to root folder
	string sProject = COMBI_ChooseProject()//choose project
	if(strlen(sProject)==0)
		return -1
	endif
	//get mapping grid
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	//make temp wave
	make/O/N=(dimsize(wMappingGrid,0)) Worker
	wave wWorker = root:Worker
	//find min x
	wWorker[] = wMappingGrid[p][1]
	variable vMinX = wavemin(wWorker)
	//find min y
	wWorker[] = wMappingGrid[p][2]
	variable vMinY = wavemin(wWorker)
	//make mapping cord wave
	make/O/N=(dimsize(wMappingGrid,0),2) MappingCords 
	wave wMappingCords = root:MappingCords
	//populate wave
	wMappingCords[][0] = -(wMappingGrid[p][1]-vMinX)//negative shifted X
	wMappingCords[][1] = (wMappingGrid[p][2]-vMinY)//shifted Y
	//save the mapping cords
	save/DLIM=","/J wMappingCords as sProject+".txt"
	//clean up
	Killwaves wWorker//,wMappingCords
	COMBI_Return2UsersDataFolder()//return to user folder
end



function COMBI_NREL_IV_Electricfield()
	//choose Project
	string sProject = COMBI_ChooseProject()//choose project
	if(strlen(sProject)==0)
		return -1
	endif
	//choose sample
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//choose thickness
	string sThickness = COMBI_DataTypePrompt(sProject,"Select Thickness Data Type!","Thickness Data:",0,0,0,1,sLibraries=sLibrary)
	if(stringmatch(sThickness,"CANCEL"))
		return -1
	endif
	wave wThickness = $COMBI_DataPath(sProject,1)+sLibrary+":"+sThickness
	//choose thickness units
	string sUnits = COMBI_StringPrompt("1E-6","Thickness Units (m)","1E1;1E-1;1E-2;1E-3;1E-4;1E-5;1E-6;1E-7;1E-8;1E-9;1E-10","","Thickness units")
	if(stringmatch(sUnits,"CANCEL"))
		return -1
	endif
	//get the name of the voltage wave
	string sVoltage = COMBI_DataTypePrompt(sProject,"Select Voltage Data Type!","Voltage Data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sVoltage,"CANCEL"))
		return -1
	endif
	wave wVoltage = $COMBI_DataPath(sProject,1)+sLibrary+":"+sVoltage
	//storage wave
	string sEfeildWaveName = Combi_AddDataType(sProject,sLibrary,"IV_Volts_per_cm",2,iVDim=dimsize(wVoltage,1))
	wave wEfeildWave = $COMBI_DataPath(sProject,1)+sLibrary+":IV_Volts_per_cm"
	//calc and store
	wEfeildWave[][] = wVoltage[p][q]/wThickness[p]/str2num(sUnits)/100
	//label
	COMBIDisplay_Global("IV_Volts_per_cm","Electric Feild (\u V/cm)","Label")
	//log
	string sLogText = "Voltage Data: "+sVoltage
	sLogText+= ";Thickness Data: "+sThickness
	sLogText+= ";Thickness Units: "+sUnits
	COMBI_Add2Log(sProject,sLibrary,"IV_Volts_per_cm",2,sLogText)
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
function COMBI_NREL_IV_CurrentDensity()
	//choose Project
	string sProject = COMBI_ChooseProject()//choose project
	if(strlen(sProject)==0)
		return -1
	endif
	//choose sample
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//choose Amps
	string sAmps = COMBI_DataTypePrompt(sProject,"Select Current Data Type!","Current Data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sAmps,"CANCEL"))
		return -1
	endif
	wave wAmps = $COMBI_DataPath(sProject,1)+sLibrary+":"+sAmps
	//choose thickness
	variable vArea = COMBI_NumberPrompt(0,"Contact Area (cm^2)","This is the area of a single contact","Contact Area?")
	if(numtype(vArea)!=0)
		DoAlert 0,"Bad Input, try again"
		return -1
	endif
	//storage wave
	string sAmpDenWave = Combi_AddDataType(sProject,sLibrary,"IV_Amps_per_cm2",2,iVDim=dimsize(wAmps,1))
	wave wAmpDen = $COMBI_DataPath(sProject,1)+sLibrary+":IV_Amps_per_cm2"
	//calc and store
	wAmpDen[][] = wAmps[p][q]/vArea
	//label
	COMBIDisplay_Global("IV_Amps_per_cm2","Current Density (\u Amps/cm\S2\M)","Label")
	//log
	string sLogText = "Current Data: "+sAmps
	sLogText+= ";Area (cm^2): "+num2str(vArea)
	COMBI_Add2Log(sProject,sLibrary,"IV_Amps_per_cm2",2,sLogText)
end

//--------------------------------------------------------------------------------------------------------------------
//Calculate conductivity wth prompts
Function COMBI_NREL_IV_ConductivitySetup()
	
	//choose Project
	string sProject = COMBI_ChooseProject()//choose project
	if(strlen(sProject)==0)
		return -1
	endif
	
	//choose sample
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Resistance Data Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	
	//choose resistance
	string sTemps = COMBI_StringPrompt(sTemps,NREL_IV_Descriptions("sTemps"),"Yes;No","Is this a temperature-dependent measurement?","Hot Stage?")
	if(stringMatch(sTemps, "Yes"))
		string expr, sDataType, sResDataType, sThisTemp, sAllTemps = ""
		string sAllDataTypes = Combi_TableList(sProject, 1, sLibrary, "DataTypes")
		string sRes = COMBI_DataTypePrompt(sProject,"Select A Resistance Data Type!","Resistance Data:",0,0,0,1,sLibraries=sLibrary)
		expr = "([[:ascii:]]*)_([[:digit:]]*)C"
		SplitString/E=(expr) sRes, sDataType, sThisTemp
		sResDataType = sDataType 
		if(stringmatch(sRes,"CANCEL"))
			return -1
		endif
		variable i
		for(i = 0; i <= itemsInList(sAllDataTypes); i += 1)
			sRes = stringFromList(i, sAllDataTypes)
			SplitString/E=(expr) sRes, sDataType, sThisTemp
			if(stringMatch(sDataType, sResDataType))
				sAllTemps = sAllTemps + sThisTemp + ";"
			endif
		endfor
	else
		sAllTemps = ""
		sResDataType = COMBI_DataTypePrompt(sProject,"Select A Resistance Data Type!","Resistance Data:",0,0,0,1,sLibraries=sLibrary)
	endif
	
	//choose area
	variable vArea = COMBI_NumberPrompt(0,"Contact Area (cm^2)","What is the area of a single contact?","Contact Area?")
	if(numtype(vArea)!=0)
		DoAlert 0,"Bad Input. Try again"
		return -1
	endif

	//string sCondWave = Combi_AddDataType(sProject,sLibrary,"IV_S_per_cm"+sTempTag,1,iVDim=dimsize(wRes,1))
	string sConductivity = "IV_S_per_cm"
	prompt sConductivity, "Enter conductivity label:"
	doPrompt sConductivity
	
	//get thickness library and multiplier prompt
	string sThickLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Thickness Data Library:",0,0,0,1)
	variable vThickMultiplier
	vThickMultiplier = COMBI_NumberPrompt(vThickMultiplier,"Thickness multiplier:","This will multiply the thickness values by the user input value, in case the values from the thickness and IV samples are not the same.","Scale thickness")
	
	//select thickness variable
	string sThickLabel = COMBI_DataTypePrompt(sProject,"Select thickness label","Thickness Data (in um):",0,0,0,1,sLibraries=sThickLibrary)
	if(stringmatch(sThickLabel,"CANCEL"))
		return -1
	endif
	
	//choose thickness units
	string sUnits = COMBI_StringPrompt("1E-6","Thickness Units (m)","1E1;1E-1;1E-2;1E-3;1E-4;1E-5;1E-6;1E-7;1E-8;1E-9;1E-10","","Thickness units")
	if(stringmatch(sUnits,"CANCEL"))
		return -1
	endif
	COMBI_NREL_IV_Conductivity(sProject, sLibrary, sAllTemps, sResDataType, sThickLibrary, sThickLabel, sUnits, sConductivity, num2str(vThickMultiplier), num2str(vArea))	
	Print ("COMBI_NREL_IV_Conductivity(\""+sProject+"\",\""+ sLibrary+"\",\""+sAllTemps+"\",\""+sResDataType+"\",\""+sThickLibrary+"\",\""+sThickLabel+"\",\""+sUnits+"\",\""+sConductivity+"\",\""+num2str(vThickMultiplier)+"\",\""+num2str(vArea)+"\")")	
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
//Calculate conductivity programmatically	
Function COMBI_NREL_IV_Conductivity(sProject, sLibrary, sAllTemps, sResDataType, sThickLibrary, sThickLabel, sUnits, sConductivity, sThickMultiplier, sArea)
	string sProject, sLibrary, sAllTemps	, sResDataType, sThickLibrary, sThickLabel, sUnits, sConductivity, sThickMultiplier, sArea
	variable vThickMultiplier = str2num(sThickMultiplier), vArea = str2num(sArea)
	COMBI_IntoDataFolder(sProject,1)
	if(itemsInList(sAllTemps)>0)
		variable i
		for(i = 0; i <= itemsInList(sAllTemps); i += 1)
			string sThisTemp = stringFromList(i, sAllTemps)
			string sTempTag = "_"+sThisTemp + "C"
			wave wRes = $COMBI_DataPath(sProject,1)+sLibrary+":"+sResDataType + sTempTag
			if(i == 0)
				SetDataFolder $sLibrary
			endif
			Make/O/N=(dimSize(wRes, 0)) $sConductivity+sTempTag
			//SetDataFolder root: 
			wave wCond = $COMBI_DataPath(sProject,1)+sLibrary+":" + sConductivity + sTempTag
			variable iSample, vThickness
			string sThickWave = COMBI_DataPath(sProject,1)+sThickLibrary+":" + sThickLabel
			wave wThickWave = $sThickWave
			for(iSample=0;iSample<dimSize(wRes, 0);iSample+=1)
				vThickness = wThickWave[iSample] * vThickMultiplier*str2num(sUnits)*10^2
				wCond[iSample] = (wRes[iSample]*vArea/(vThickness))^-1	
			endfor
		endfor
	elseif(itemsInList(sAllTemps) == 0)
		wave wRes = $COMBI_DataPath(sProject,1)+sLibrary+":"+sResDataType
		SetDataFolder $sLibrary
		Make/O/N=(dimSize(wRes, 0)) $sConductivity
		//SetDataFolder root: 
		wave wCond = $COMBI_DataPath(sProject,1)+sLibrary+":" + sConductivity
		sThickWave = COMBI_DataPath(sProject,1)+sThickLibrary+":" + sThickLabel
		wave wThickWave = $sThickWave
		for(iSample=0;iSample<dimSize(wRes, 0);iSample+=1)
			vThickness = wThickWave[iSample] * vThickMultiplier*str2num(sUnits)*10^2
			wCond[iSample] = (wRes[iSample]*vArea/(vThickness))^-1	
		endfor
	endif	
	Killvariables/Z root:V_chisq,root:V_endChunk,root:V_endCol,root:V_endLayer,root:V_endRow,root:V_nheld,root:V_npnts,root:V_nterms,root:V_numINFs,root:V_numNaNs,root:V_Pr,root:V_q,root:V_Rab,root:V_r2,root:V_siga,root:V_sigb,root:V_startChunk,root:V_startCol,root:V_startLayer,root:V_startRow
	SetDataFolder root:
	
	//label
	COMBIDisplay_Global(sConductivity,"Conductivity (\u S/cm)","Label")
	
	//log
	string sLogText = "Conductivity Data: "+sConductivity
	sLogText+= ";Area (cm^2): "+num2str(vArea)
	COMBI_Add2Log(sProject,sLibrary,"IV_S_per_cm",2,sLogText)
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
//Calculate resistance of data that has already been loaded
Function COMBI_NREL_IV_Resistance()
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//get globals
	string sThisInstrumentName = "NREL_IV"
	string sCurrent = COMBI_GetInstrumentString(sThisInstrumentName,"sCurrent",sProject)
	string sVoltage = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)
	string bFitResistance = "Yes"
	string bSeparatePosNeg = COMBI_GetInstrumentString(sThisInstrumentName,"bSeparatePosNeg",sProject)
	string sVoltageMinPos = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinPos",sProject)
	string sVoltageMinNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMinNeg",sProject)
	string sVoltageMaxPos = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMaxPos",sProject)
	string sVoltageMaxNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltageMaxNeg",sProject)
	string sResistance = COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject)
	string sResistancePos = COMBI_GetInstrumentString(sThisInstrumentName,"sResistancePos",sProject)
	string sResistanceNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceNeg",sProject)
	string sResistanceGOF = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOF",sProject)
	string sResistanceGOFPos = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOFPos",sProject)
	string sResistanceGOFNeg = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOFNeg",sProject)
	string sTemps = COMBI_GetInstrumentString(sThisInstrumentName,"sTemps",sProject)
	string sPlotAll = COMBI_GetInstrumentString(sThisInstrumentName,"sPlotAll",sProject)
	string bKeepAllRValues = COMBI_GetInstrumentString(sThisInstrumentName,"bKeepAllRValues",sProject)
	
	//choose project
	sProject = COMBI_ChooseProject()
	
	//get project globals
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	//choose sample
	string sLibraryName = COMBI_LibraryPrompt(sProject,"Select Library!","IV Data Library:",0,0,0,1)
	if(stringmatch(sLibraryName,"CANCEL"))
		return -1
	endif

	variable vTotalMeasurements = COMBI_NumberPrompt(0, "Number of measurements", "How many measurements were taken per sample?", "Total measurements")
	variable vFirstSample = COMBI_NumberPrompt(0, "First sample to fit", "", "Starting point")
	sTemps = COMBI_StringPrompt(sTemps,NREL_IV_Descriptions("sTemps"), "Yes;No", "Is this a temperature-dependent measurement?", "Hot Stage?")

	prompt bSeparatePosNeg, "Separate positive and negative polarity?", popup "Yes;No"
	prompt bKeepAllRValues, "Keep both resistance values?", popup "Yes;No"
	prompt sVoltageMaxNeg, "Max negative voltage"
	prompt sVoltageMaxPos, "Max positive voltage"
	prompt sVoltageMinNeg, "Min negative voltage"
	prompt sVoltageMinPos, "Min positive voltage"
		
	doPrompt "Separate polarities", bSeparatePosNeg
	
	if(stringMatch(bSeparatePosNeg, "Yes"))
		if(stringMatch(sVoltageMaxNeg, "NAG") || stringMatch(sVoltageMaxPos, "NAG") || stringMatch(sVoltageMaxNeg, "NAG") || stringMatch(sVoltageMaxPos, "NAG"))
			sVoltageMaxPos = "10"
			sVoltageMaxNeg = "10"
			sVoltageMinPos = "5"
			sVoltageMinNeg = "5"
			doPrompt "Set voltage limits", sVoltageMinNeg, sVoltageMinPos, sVoltageMaxNeg, sVoltageMaxPos, bKeepAllRValues	
		endif
		
	elseif(stringMatch(bSeparatePosNeg, "No"))
		if(stringMatch(sVoltageMaxNeg, "NAG") || stringMatch(sVoltageMaxPos, "NAG"))
			sVoltageMaxPos = "10"
			sVoltageMaxNeg = "10"
			doPrompt "Set voltage limits", sVoltageMaxNeg, sVoltageMaxPos
		endif
		
	endif
	
	string sTotalMeasurements = num2str(vTotalMeasurements)
	string sTotalSamples = num2str(vTotalSamples)
	string sFirstSample = num2str(vFirstSample)
	
	COMBI_NREL_IV_ResistanceP(sProject, sLibraryName, bSeparatePosNeg, sVoltage, sVoltageMaxNeg, sVoltageMaxPos, sVoltageMinPos, sVoltageMinNeg, sTemps, sPlotAll, bFitResistance, sTotalMeasurements, sCurrent, sTotalSamples, sResistance, sResistanceGOF, sFirstSample, bKeepAllRValues, sResistancePos, sResistanceGOFPos, sResistanceNeg, sResistanceGOFNeg)
	Print ("COMBI_NREL_IV_ResistanceP(\"" + sProject +"\",\""+ sLibraryName +"\",\""+ bSeparatePosNeg +"\",\""+ sVoltage +"\",\""+ sVoltageMaxNeg +"\",\""+ sVoltageMaxPos +"\",\""+ sVoltageMinPos +"\",\""+ sVoltageMinNeg +"\",\""+ sTemps +"\",\""+ sPlotAll +"\",\""+ bFitResistance +"\",\""+ sTotalMeasurements +"\",\""+ sCurrent +"\",\""+ sTotalSamples +"\",\""+ sResistance +"\",\""+ sResistanceGOF +"\",\""+ sFirstSample +"\",\""+ bKeepAllRValues +"\",\""+ sResistancePos +"\",\""+ sResistanceGOFPos +"\",\""+ sResistanceNeg +"\",\""+ sResistanceGOFNeg+"\")")	
end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
//Calculate resistance of data programmatically
Function COMBI_NREL_IV_ResistanceP(sProject, sLibraryName, bSeparatePosNeg, sVoltage, sVoltageMaxNeg, sVoltageMaxPos, sVoltageMinPos, sVoltageMinNeg, sTemps, sPlotAll, bFitResistance, sTotalMeasurements, sCurrent, sTotalSamples, sResistance, sResistanceGOF, sFirstSample, bKeepAllRValues, sResistancePos, sResistanceGOFPos, sResistanceNeg, sResistanceGOFNeg)
	
	//declare parameters
	string sProject, sLibraryName, bSeparatePosNeg, sVoltage, sVoltageMaxNeg, sVoltageMaxPos, sVoltageMinPos, sVoltageMinNeg
	string sTemps, sPlotAll, bFitResistance, sTotalMeasurements, sCurrent, sTotalSamples, sResistance, sResistanceGOF, sFirstSample
	string bKeepAllRValues, sResistancePos, sResistanceGOFPos, sResistanceNeg, sResistanceGOFNeg
	
	//convert strings to variables
	variable vTotalMeasurements = str2num(sTotalMeasurements)
	variable vTotalSamples = str2num(sTotalSamples)
	variable vFirstSample = str2num(sFirstSample)
	
	//get global strings
	sVoltage = COMBI_GetInstrumentString("NREL_IV","sVoltage",sProject)
	sCurrent = COMBI_GetInstrumentString("NREL_IV","sCurrent",sProject)
	sResistance = COMBI_GetInstrumentString("NREL_IV","sResistance",sProject)
	sResistanceGOF = COMBI_GetInstrumentString("NREL_IV","sResistanceGOF",sProject)
	sResistancePos = COMBI_GetInstrumentString("NREL_IV","sResistancePos",sProject)
	sResistanceGOFPos = COMBI_GetInstrumentString("NREL_IV","sResistanceGOFPos",sProject)
	sResistanceNeg = COMBI_GetInstrumentString("NREL_IV","sResistanceNeg",sProject)
	sResistanceGOFNeg = COMBI_GetInstrumentString("NREL_IV","sResistanceGOFNeg",sProject)
	
	//do stuff
	if(stringMatch(sTemps, "Yes"))
		string expr, sDataType, sVoltDataType, sThisTemp, sAllTemps = ""
		string sAllDataTypes = Combi_TableList(sProject, 2, sLibraryName, "DataTypes")
		expr = "([[:ascii:]]*)_([[:digit:]]*)C"
		
		variable i
		for(i = 0; i <= itemsInList(sAllDataTypes); i += 1)
			string sDataTypeLabel = stringFromList(i, sAllDataTypes)
			SplitString/E=(expr) sDataTypeLabel, sDataType, sThisTemp
			if(stringMatch(sDataType, sVoltage))
				sAllTemps = sAllTemps + sThisTemp + ";"
			endif
		endfor
	else
		sAllTemps = ""
		sVoltDataType = sVoltage
	endif

	//resistance values - curve through the origin
	int iSample
	variable iTemp, vMeasurement
	string sMeasureTag, sTempTag
	
	if(stringMatch(sPlotAll, "Yes"))
		DoAlert 0,"Select a path to save plots." 
		NewPath pPathToSave
		//get sample wave
		wave wSampleWave = $"root:COMBIgor:" + sProject + ":Data:FromMappingGrid:Sample"
		//make library path for creating waves
		string sLibraryPath = "root:COMBIgor:" + sProject + ":Data:" + sLibraryName + ":" 
	endif
	
	if(stringmatch(bFitResistance,"Yes") && stringMatch(bSeparatePosNeg,"No"))
		if(stringmatch(sResistance, "NAG"))	
			sResistance = "IV_Resistance_Ohm"
			sResistanceGOF = "IV_Resistance_GOF"
			prompt sResistance, "Resistance variable"
			prompt sResistanceGOF, "Goodness of fit variable"
			doPrompt "Set resistance variable names", sResistance, sResistanceGOF	
		endif
			
		if(stringMatch(sVoltageMaxNeg, "NAG") || stringMatch(sVoltageMaxPos, "NAG"))
			sVoltageMaxPos = "10"
			sVoltageMaxNeg = "10"
			prompt sVoltageMaxPos, "Max positive voltage"
			prompt sVoltageMaxNeg, "Max negative voltage"
			doPrompt "Set voltage limits", sVoltageMaxNeg, sVoltageMaxPos	
		endif
		
		for(itemp=0;itemp<itemsInList(sAllTemps);itemp+=1)
			for(vMeasurement=1;vMeasurement<=vTotalMeasurements;vMeasurement+=1)
				if(vTotalMeasurements>1)
					sMeasureTag = "_M"+num2str(vMeasurement)
				else
					sMeasureTag = ""
				endif
				if(stringmatch(sTEMPs,"Yes"))//with temps
					sTempTag = "_"+stringfromlist(itemp,sAllTemps)+"C"
				else //without temps
					sTempTag = ""
				endif
				wave wCurrent = $Combi_DataPath(sProject,2)+sLibraryName+":"+sCurrent+sMeasureTag+sTempTag
				wave wVoltage = $Combi_DataPath(sProject,2)+sLibraryName+":"+sVoltage+sMeasureTag+sTempTag
				COMBI_IntoDataFolder(sProject,1)
				SetDataFolder $sLibraryName
				Make/O/N=(vTotalSamples) $sResistance+sMeasureTag+sTempTag
				Make/O/N=(vTotalSamples) $sResistanceGOF+sMeasureTag+sTempTag
				SetDataFolder root: 
				wave wResistance = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistance+sMeasureTag+sTempTag
				wave wResistanceGOF = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOF+sMeasureTag+sTempTag
				//sDataTypes = sDataTypes+";"+sResistance+sMeasureTag+sTempTag+";"+sResistanceGOF+sMeasureTag+sTempTag+";"
				Make/O/N=(2) wCoefs
				wave wCoefs = root:wCoefs
				for(iSample=vFirstSample-1;iSample<vFirstSample+vTotalSamples-1;iSample+=1)
					variable iPosMax, iNegMax
					i = 0
					do
						iPosMax = i
						i += 1
					while(wVoltage[0][i] < str2num(sVoltageMaxPos))
					i = 0
					do
						iNegMax = i
						i += 1
					while(Abs(wVoltage[0][i]) > str2num(sVoltageMaxNeg))
					CurveFit/Q/W=2 line, kwCWave=wCoefs, wVoltage[iSample][iNegMax, iPosMax]/X=wCurrent[iSample][iNegMax, iPosMax]
					wResistance[iSample] = wCoefs[1]
					wResistanceGOF[iSample] = V_r2
				
					//Plots all IV data and fits and saves them automatically to the folder the user selects
					if(stringMatch(sPlotAll, "Yes"))
						string sSampleName = getDimLabel(wSampleWave, 0, iSample)
						string sSample = num2str(iSample + 1)
						
						//make and populate plotting wave for data and fits
						string sPlottingWaveName = "PlotWave"
						Make/N=(dimSize(wVoltage, 1), 4)/O wPlottingWave
						wave wPlottingWave = $sLibraryPath + sPlottingWaveName
						//Column 0 is voltage
						wPlottingWave[][0] = wVoltage[iSample][p]
						//Column 1 is measured current
						wPlottingWave[][1] = wCurrent[iSample][p] 
						//Column 2 is calculated current from fit
						wPlottingWave[][2] = (wPlottingWave[p][0] - wCoefs[0])/wCoefs[1]
					
						//make plot
						Display/N=IVPlot wPlottingWave[][0] vs wPlottingWave[][1]
						ModifyGraph mode=3,marker=19
						ModifyGraph rgb(wPlottingWave)=(0,0,0)
						Label left "Potential (V)"
						Label bottom "Current (A)"
						Legend/C/N=text0/J/F=0/A=RC "\\s(wPlottingWave) Data\r\\s(FitTrace0) Fit"
						
						//append pos fit
						AppendToGraph/W=IVPlot wPlottingWave[][0]/TN=FitTrace0 vs wPlottingWave[][2]
						ModifyGraph rgb(FitTrace0)=(1,52428,52428)
						ModifyGraph lsize(FitTrace0)=2
	
						SavePICT/O/P=pPathToSave as "IVPlot_" + sSampleName + "_" + sLibraryName + sMeasureTag + sTempTag
						killWindow IVPlot
					endif
				
				endfor
			endfor
			killwaves/Z wCoefs, root:W_sigma
			Killvariables/Z root:V_chisq,root:V_endChunk,root:V_endCol,root:V_endLayer,root:V_endRow,root:V_nheld,root:V_npnts,root:V_nterms,root:V_numINFs,root:V_numNaNs,root:V_Pr,root:V_q,root:V_Rab,root:V_r2,root:V_siga,root:V_sigb,root:V_startChunk,root:V_startCol,root:V_startLayer,root:V_startRow
		endfor
	endif
	
	//resistance values - separate positive and negative for fit
	if(stringmatch(bFitResistance,"Yes") && stringMatch(bSeparatePosNeg,"Yes"))
		if(stringmatch(sResistancePos, "NAG") || stringmatch(sResistanceNeg, "NAG") || stringmatch(sResistanceGOFPos, "NAG") || stringmatch(sResistanceGOFNeg, "NAG"))	
			sResistancePos = "IV_ResistancePos_Ohm"
			sResistanceNeg = "IV_ResistanceNeg_Ohm"
			sResistanceGOFPos = "IV_ResistancePos_GOF"
			sResistanceGOFNeg = "IV_ResistanceNeg_GOF"
			prompt sResistancePos, "Positive resistance variable"
			prompt sResistanceGOFPos, "Positive polarity goodness of fit variable"
			prompt sResistanceNeg, "Negative resistance variable"
			prompt sResistanceGOFNeg, "Negative polarity goodness of fit variable"
			doPrompt "Set resistance variable names", sResistancePos, sResistanceGOFPos, sResistanceNeg, sResistanceGOFNeg
		endif	
			
		if(stringMatch(sVoltageMaxNeg, "NAG") || stringMatch(sVoltageMaxPos, "NAG") || stringMatch(sVoltageMinNeg, "NAG") || stringMatch(sVoltageMinPos, "NAG"))
			sVoltageMaxPos = "10"
			sVoltageMinPos = "5"
			sVoltageMaxNeg = "10"
			sVoltageMinNeg = "5"
			prompt sVoltageMaxPos, "Max positive voltage"
			prompt sVoltageMinPos, "Min positive voltage"
			prompt sVoltageMaxNeg, "Max negative voltage"
			prompt sVoltageMinNeg, "Min negative voltage"
			doPrompt "Set voltage limits", sVoltageMaxPos, sVoltageMinPos, sVoltageMaxNeg, sVoltageMinNeg	
		endif
		
		for(itemp=0;itemp<itemsInList(sAllTemps);itemp+=1)
			for(vMeasurement=1;vMeasurement<=vTotalMeasurements;vMeasurement+=1)
				if(vTotalMeasurements>1)
					sMeasureTag = "_M"+num2str(vMeasurement)
				else
					sMeasureTag = ""
				endif
				if(stringmatch(sTEMPs,"Yes"))//with temps
					sTempTag = "_"+stringfromlist(itemp,sAllTemps)+"C"
				else //without temps
					sTempTag = ""
				endif
				wave wCurrent = $Combi_DataPath(sProject,2)+sLibraryName+":"+sCurrent+sMeasureTag+sTempTag
				wave wVoltage = $Combi_DataPath(sProject,2)+sLibraryName+":"+sVoltage+sMeasureTag+sTempTag
				COMBI_IntoDataFolder(sProject,1)
				if(stringMatch(bKeepAllRValues, "No"))
					SetDataFolder $sLibraryName
					Make/O/N=(vTotalSamples) $sResistance+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceGOF+sMeasureTag+sTempTag
					SetDataFolder root: 
					wave wResistance = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistance+sMeasureTag+sTempTag
					wave wResistanceGOF = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOF+sMeasureTag+sTempTag
					//sDataTypes = sDataTypes+";"+sResistance+sMeasureTag+sTempTag+";"+sResistanceGOF+sMeasureTag+sTempTag+";"
				elseif(stringMatch(bKeepAllRValues, "Yes"))
					SetDataFolder $sLibraryName
					Make/O/N=(vTotalSamples) $sResistancePos+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceGOFPos+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceNeg+sMeasureTag+sTempTag
					Make/O/N=(vTotalSamples) $sResistanceGOFNeg+sMeasureTag+sTempTag
					SetDataFolder root: 
					//positive polarity
					wave wResistancePos = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistancePos+sMeasureTag+sTempTag
					wave wResistanceGOFPos = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOFPos+sMeasureTag+sTempTag
					//sDataTypes = sDataTypes+";"+sResistancePos+sMeasureTag+sTempTag+";"+sResistanceGOFPos+sMeasureTag+sTempTag+";"
					//negative polarity
					wave wResistanceNeg = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceNeg+sMeasureTag+sTempTag
					wave wResistanceGOFNeg = $Combi_DataPath(sProject,1)+sLibraryName+":"+sResistanceGOFNeg+sMeasureTag+sTempTag
					//sDataTypes = sDataTypes+";"+sResistanceNeg+sMeasureTag+sTempTag+";"+sResistanceGOFNeg+sMeasureTag+sTempTag+";"
				endif
				
				Make/O/N=(2) wCoefsPos
				Make/O/N=(2) wCoefsNeg
				wave wCoefsPos = root:wCoefsPos		
				wave wCoefsNeg = root:wCoefsNeg
				//find columns of min voltage (neg and pos)
				variable iPosMin, iNegMin
				variable vR2Neg, vR2Pos
				i = 0
				do
					iPosMin = i
					i += 1
				while(wVoltage[0][i] < str2num(sVoltageMinPos))
				i = 0
				do
					iPosMax = i
					i += 1
				while(wVoltage[0][i] < str2num(sVoltageMaxPos))
				i = 0
				do
					iNegMin = i
					i += 1 
				while(Abs(wVoltage[0][i]) > str2num(sVoltageMinNeg))
				i = 0
				do
					iNegMax = i
					i += 1
				while(Abs(wVoltage[0][i]) > str2num(sVoltageMaxNeg))
				
				for(iSample=vFirstSample-1;iSample<vFirstSample+vTotalSamples-1;iSample+=1)
					CurveFit/Q/W=2 line, kwCWave=wCoefsPos, wVoltage[iSample][iPosMin, iPosMax]/X=wCurrent[iSample][iPosMin, iPosMax]
					VR2Pos = V_r2
					CurveFit/Q/W=2 line, kwCWave=wCoefsNeg, wVoltage[iSample][iNegMax, iNegMin]/X=wCurrent[iSample][iNegMax, iNegMin]
					VR2Neg = V_r2
					
					if(stringMatch(bKeepAllRValues, "No"))
						if(VR2Pos >= VR2Neg)
							wResistance[iSample] = wCoefsPos[1]
							wResistanceGOF[iSample] = VR2Pos
						elseif(VR2Pos < VR2Neg)
							wResistance[iSample] = wCoefsNeg[1]
							wResistanceGOF[iSample] = VR2Neg
						endif
					elseif(stringMatch(bKeepAllRValues, "Yes"))
						wResistancePos[iSample] = wCoefsPos[1]
						wResistanceGOFPos[iSample] = VR2Pos
						wResistanceNeg[iSample] = wCoefsNeg[1]
						wResistanceGOFNeg[iSample] = VR2Neg
					endif
					
					//Plots all IV data and fits and saves them automatically to the folder the user selects
					if(stringMatch(sPlotAll, "Yes"))

						//select path for saving
					 	//string sPathToSave = Combi_ExportPath("New")
						sSampleName = getDimLabel(wSampleWave, 0, iSample)
						sSample = num2str(iSample + 1)
						
						//make and populate plotting wave for data and fits
						sPlottingWaveName = "PlotWave"
						Make/N=(dimSize(wVoltage, 1), 4)/O wPlottingWave
						wave wPlottingWave = $sLibraryPath + sPlottingWaveName
						//Column 0 is voltage
						wPlottingWave[][0] = wVoltage[iSample][p]
						//Column 1 is measured current
						wPlottingWave[][1] = wCurrent[iSample][p] 
						//Column 2 is calculated current from positive fit
						wPlottingWave[][2] = (wPlottingWave[p][0] - wCoefsPos[0])/wCoefsPos[1]
						//Column 3 is calculated current from negative fit
						wPlottingWave[][3] = (wPlottingWave[p][0] - wCoefsNeg[0])/wCoefsNeg[1]
					
						//make plot
						Display/N=IVPlot wPlottingWave[][0] vs wPlottingWave[][1]
						ModifyGraph mode=3,marker=19
						ModifyGraph rgb(wPlottingWave)=(0,0,0)
						Label left "Potential (V)"
						Label bottom "Current (A)"
						Legend/C/N=text0/J/F=0/A=RC "\\s(wPlottingWave) Data\r\\s(FitTrace0) Positive fit\r\\s(FitTrace1) Negative fit"
						
						
						//append pos fit
						AppendToGraph/W=IVPlot wPlottingWave[][0]/TN=FitTrace0 vs wPlottingWave[][2]
						ModifyGraph rgb(FitTrace0)=(3,52428,1)
						ModifyGraph lsize(FitTrace0)=2
						
						//append neg fit
						AppendToGraph/W=IVPlot wPlottingWave[][0]/TN=FitTrace1 vs wPlottingWave[][3]
						ModifyGraph rgb(FitTrace1)=(65535,0,0)
						ModifyGraph lsize(FitTrace1)=2
	
						SavePICT/O/P=pPathToSave as "IVPlot_" + sSampleName + "_" + sLibraryName + sMeasureTag + sTempTag
						killWindow IVPlot
					endif
				endfor
			endfor
			killwaves/Z wCoefsPos, wCoefsNeg, root:W_sigma
			Killvariables/Z root:V_chisq,root:V_endChunk,root:V_endCol,root:V_endLayer,root:V_endRow,root:V_nheld,root:V_npnts,root:V_nterms,root:V_numINFs,root:V_numNaNs,root:V_Pr,root:V_q,root:V_Rab,root:V_r2,root:V_siga,root:V_sigb,root:V_startChunk,root:V_startCol,root:V_startLayer,root:V_startRow
		endfor
	endif
end