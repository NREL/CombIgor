#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ May 2018 : Original
// V1.1 Sage Bauers _ 20180513 : Modified names, added initialization options, additional cleanup
// V1.11: Karen Heinselman _ Oct 2018 : Polishing and debugging
// V1.12: KEvin Talley - Added Make text file from mapping grid

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
			 "Voltage > E feild",/Q, COMBI_NREL_IV_Electricfield()
			 "Amps > Current Density",/Q, COMBI_NREL_IV_CurrentDensity()
		end
	end
end

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
		case "sResistanceGOF":
			sReturnstring =  "Resistance R^2 Label:"
			break
		case "sTEMPS":
			sReturnstring =  "Hotstage?"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

function NREL_IV_Define()
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	string sVoltage,sCurrent, bFitResistance, sResistance, sResistanceGOF, sTEMPS
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)))//if project is defined previously, start with those values
		sVoltage = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)
		sCurrent = COMBI_GetInstrumentString(sThisInstrumentName,"sCurrent",sProject)
		bFitResistance = COMBI_GetInstrumentString(sThisInstrumentName,"bFitResistance",sProject)
		sResistance = COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject)
		sResistanceGOF = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOF",sProject)
		sTEMPS = COMBI_GetInstrumentString(sThisInstrumentName,"sTEMPS",sProject)
	else //not previously defined, start with default values 
		sVoltage = "IV_Volts"
		sCurrent = "IV_Amps"
		bFitResistance = "Yes"
		sResistance = "IV_Resistance_Ohm"
		sResistanceGOF = "IV_Resistance_GOF"
		sTEMPS = "No"
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
	
	//sTEMPS
	string sHelp = "Do the files have a temperature at the end? Like \"_200C\""
	sTEMPS = COMBI_StringPrompt(sTEMPS,NREL_IV_Descriptions("sTEMPS"),"No;Yes",sHelp,"Hot Stage?")
	if(stringmatch(sTEMPS,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sTEMPS",sTEMPS,sProject)// store global
	
	//fit resistance?
	bFitResistance = COMBI_StringPrompt(bFitResistance,NREL_IV_Descriptions("bFitResistance"),"Yes;No","Select yes to fit resistance lines to the data and return scalar values","Fit Resistance?")
	if(stringmatch(bFitResistance,"CANCEL"))
		COMBI_InstrumentDefinition()
		return -1 
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bFitResistance",bFitResistance,sProject)// store global
	
	if(stringmatch("Yes",bFitResistance))
		//resistance
		sResistance = COMBI_DataTypePrompt(sProject,sResistance,NREL_IV_Descriptions("sResistance"),0,1,0,2)
		if(stringmatch(sResistance,"CANCEL"))
			COMBI_InstrumentDefinition()
			return -1 
		endif
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistance",sResistance,sProject)// store global
		//resistanceGOF
		sResistanceGOF = COMBI_DataTypePrompt(sProject,sResistanceGOF,NREL_IV_Descriptions("sResistanceGOF"),0,1,0,2)
		if(stringmatch(sResistanceGOF,"CANCEL"))
			COMBI_InstrumentDefinition()
			return -1 
		endif
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOF",sResistanceGOF,sProject)// store global
	else
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistance","",sProject)// store global
		COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sResistanceGOF","",sProject)// store global
	endif
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
	
end

function NREL_IV_Load()
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 

	//get globals
	string sThisInstrumentName = "NREL_IV"
	string sCurrent = COMBI_GetInstrumentString(sThisInstrumentName,"sCurrent",sProject)
	string sVoltage = COMBI_GetInstrumentString(sThisInstrumentName,"sVoltage",sProject)
	string bFitResistance = COMBI_GetInstrumentString(sThisInstrumentName,"bFitResistance",sProject)
	string sResistance = COMBI_GetInstrumentString(sThisInstrumentName,"sResistance",sProject)
	string sResistanceGOF = COMBI_GetInstrumentString(sThisInstrumentName,"sResistanceGOF",sProject)
	string sTEMPS = COMBI_GetInstrumentString(sThisInstrumentName,"sTEMPS",sProject)
	
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
						Print sFIleName+" was expected but not found during load."
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
					endfor
					
					//move positive values
					for(iPos=0;iPos<vPosLength;iPos+=1)
						wCurrent[vContact-1][iPos+vNegLength] = wPosWave[iPos][0]
						wVoltage[vContact-1][iPos+vNegLength] = wPosWave[iPos][1]
					endfor
					
					//kill loaded waves
					killwaves/Z wNegWave, wPosWave
					
				endfor	
			elseif(itemsinlist(sPolaritySettings)==1)//Single Polarity 
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
					endfor
					
					//kill loaded waves
					killwaves/Z wIVWave
				endfor	
			endif	
		endfor
	endfor
	
	//resistance values
	int iSample
	if(stringmatch(bFitResistance,"Yes"))
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
				for(iSample=vFirstSample;iSample<vFirstSample+vTotalContacts-1;iSample+=1)
					CurveFit/Q/W=2 line, kwCWave=wCoefs, wVoltage[iSample][]/X=wCurrent[iSample][]
					wResistance[iSample] = wCoefs[1]
					wResistanceGOF[iSample] = V_r2
				endfor
				
			endfor
			killwaves/Z wCoefs, root:W_sigma
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



