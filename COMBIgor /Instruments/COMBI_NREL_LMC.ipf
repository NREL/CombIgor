#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original Example 
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

//Description of procedure purpose:
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Instruments"
		 "Lab MetaData Collector",/Q, COMBI_NREL_LMC()
	end
end

//returns a list of descriptors for each of the globals used to define file loading. There can be as many Instrument globals as needed, please specify a new "case" in the strswitch for each.
Function/S NREL_LMC_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for
	
	//this instruments name
	string sInstrument = "NREL_LMC"
	
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring=""
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "NREL_LMC":
			sReturnstring = "NREL Lab MetaData Collector"
			break
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "sChamber":
			sReturnstring =  "COMBI growth chamber:"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	//puts value into 0th row and 0th column of globals wave for other functions to access
	twGlobals[0][0] = sReturnstring 
	return sReturnstring
end

//this function will be executed when the user selects to define the Instrument in the Instrument definition panel
function NREL_LMC_Define()

	//get Instrument name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	string sChamber
	
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		sChamber = COMBI_GetInstrumentString(sThisInstrumentName,"sChamber",sProject)
	else 
		//not previously defined, start with default values 
		sChamber = "COMBI5"
	endif
	
	// get info for definition values, these values can change between Library prompts to tailor the specifics.
	string sPopUpOptions = "COMBI1;COMBI3;COMBI4;COMBI5;COMBI6;COMBI7;COMBI8;COMBI9"//list of options for a popup prompt, if "" then blank field with any entry accepted
	string sHelp = "This specifies what type of LMC data is being loaded." //This is the help string, it is only seen when someone clicks "Help" on the prompt window
	string sWindowTop = "NREL Chamber?" //This is displayed at the top of the prompt window
		
	//sSomeString
	sChamber = COMBI_StringPrompt(sChamber,NREL_LMC_Descriptions("sChamber"),sPopUpOptions,sHelp,sWindowTop)
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sChamber",sChamber,sProject)// store Instrument global 
			
	//reload definition panel
	COMBI_InstrumentDefinition()
	
end

//this function will be executed when the user selects to load data button in the Instrument definition panel
function NREL_LMC_Load()
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root:
	//get Instrument name and project name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//get specific globals
	string sChamber = COMBI_GetInstrumentString(sThisInstrumentName,"sChamber",sProject)
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//Folder or single file
	string sLoadType = COMBI_StringPrompt("File","Load Type","File;Folder","Select whether to load one file or a folder of files","Select load type")
	if(stringmatch(sLoadType,"CANCEL"))
		return -1
	endif
	
	//loop control
	int vTotalFiles = 1, iFile
	string sAllFiles
	variable vFileRef
	string sOpened
	if(stringmatch(sLoadType,"Folder"))
		NewPath/Z/Q/O pLoadPath
		Pathinfo pLoadPath
		string sThisLoadFolder = S_path
		sAllFiles = IndexedFile(pLoadPath,-1,".json")
		vTotalFiles = Itemsinlist(sAllFiles)
	elseif(stringmatch(sLoadType,"File"))
		vTotalFiles = 1
		Open/R/F="*.json"/M="Select LMC .json" vFileRef
		sOpened=S_fileName
	endif
	
	for(iFile=0;iFile<vTotalFiles;iFile+=1)
		
		//get file to read
		if(stringmatch(sLoadType,"Folder"))
			string sThisFile = stringfromList(iFile,sAllFiles)
			Open/R/F="*.json" vFileRef as sThisLoadFolder+sThisFile
			sOpened=S_fileName
		endif

		if(strlen(sOpened)==0)
			return -1
		endif
		
		variable vFolderInPath = itemsinlist(sOpened,":")
		string sFullname = stringfromlist(vFolderInPath-1,sOpened,":")
		
		//Read to string
		string sThisLine = PadString("",inf,4)
		FReadLine/T="" vFileRef, sThisLine
		Close vFileRef
	
		JSONSimple/Q/Z sThisLine
		wave/T wJSONText = root:T_TokenText
		
		//for reading
		string sThisResult
		int iThisIndex
		
		//MetaData
		
		//Library number
		string sLibraryNumber = ""
		sThisResult = NREL_LMC_FindEntry(wJSONText,"number")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			sLibraryNumber = wJSONText[iThisIndex+1]
			sLibraryNumber = COMBI_PadIndex(str2num(sLibraryNumber),5)
		endif
		
		//chamber
		string sGrowChamber = ""
		sThisResult = NREL_LMC_FindEntry(wJSONText,"instrument")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			sGrowChamber = wJSONText[iThisIndex+1]
		endif
		
		//prompt for Library name
		string sLibraryName = UpperStr(sGrowChamber+"_"+sLibraryNumber)
		sLibraryName = COMBI_LibraryPrompt(sProject,sLibraryName,"Name of Library from "+sFullname+" :",0,1,0,-1)
		if(stringmatch("CANCEL",sLibraryName))
			return -1
		endif
		COMBI_GiveMeta(sProject,"LibraryNumber",sLibraryName,sLibraryNumber,-1)
		COMBI_GiveMeta(sProject,"LibraryPrefix",sLibraryName,UpperStr(sGrowChamber)+"_",-1)
		
		//usernamne
		sThisResult = NREL_LMC_FindEntry(wJSONText,"username")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveMeta(sProject,"GrownBy",sLibraryName,wJSONText[iThisIndex+1],-1)
		endif
		
		//date
		sThisResult = NREL_LMC_FindEntry(wJSONText,"date")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveMeta(sProject,"GrowthDate",sLibraryName,wJSONText[iThisIndex+1],-1)
		endif
		
		//notes
		sThisResult = NREL_LMC_FindEntry(wJSONText,"notes")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveMeta(sProject,"DepNotes",sLibraryName,wJSONText[iThisIndex+1],-1)
		endif
		
		//cracker
		sThisResult = NREL_LMC_FindEntry(wJSONText,"cracker")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			if(stringmatch("true",wJSONText[iThisIndex+3]))
				COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+5]),sProject,sLibraryName,"Cracker_FP")
				COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+7]),sProject,sLibraryName,"Cracker_RP")
				COMBI_GiveLibraryData(1,sProject,sLibraryName,"Cracker")
				COMBI_GiveMeta(sProject,"Cracker",sLibraryName,"True",-1)
			else
				if(!stringmatch("COMBI3",sChamber))
					COMBI_GiveLibraryData(0,sProject,sLibraryName,"Cracker")
				endif
			endif
		endif
		
		//cryoshroud
		sThisResult = NREL_LMC_FindEntry(wJSONText,"cryoshroud")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			if(stringmatch("true",wJSONText[iThisIndex+1]))
				COMBI_GiveMeta(sProject,"Cryoshroud",sLibraryName,"True",-1)
				COMBI_GiveLibraryData(1,sProject,sLibraryName,"Cryoshroud")
			else
				if(stringmatch("COMBI5",sChamber))
					COMBI_GiveLibraryData(0,sProject,sLibraryName,"Cryoshroud")
				endif
			endif
		endif
		
		//base press
		sThisResult = NREL_LMC_FindEntry(wJSONText,"base_torr")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"BasePressure_torr")
		endif
		
		//dep press
		sThisResult = NREL_LMC_FindEntry(wJSONText,"dep_torr")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"DepPressure_torr")
		endif
		
		// times
		sThisResult = NREL_LMC_FindEntry(wJSONText,"sputter_time")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"DepTime_min")
		endif
		sThisResult = NREL_LMC_FindEntry(wJSONText,"presputter_time")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"PreSputterTime_min")
		endif
		
		//gasses
		sThisResult = NREL_LMC_FindEntry(wJSONText,"gas")
		int iGas
		if(itemsinList(sThisResult)>1)
			for(iGas=1;iGas<itemsinList(sThisResult);iGas+=1)
				iThisIndex = str2num(stringfromlist(iGas,sThisResult))
				COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+3]),sProject,sLibraryName,wJSONText[iThisIndex+1]+"_sccm")
			endfor
		endif
		
		//targets and substrates
		sThisResult = NREL_LMC_FindEntry(wJSONText,"targets")
		variable iTargets = 0
		if(itemsinList(sThisResult)==1)
			iTargets = str2num(stringfromlist(0,sThisResult))
		endif
		sThisResult = NREL_LMC_FindEntry(wJSONText,"substrates")
		variable iSubstrates = 0
		if(itemsinList(sThisResult)==1)
			iSubstrates = str2num(stringfromlist(0,sThisResult))
		endif 
		sThisResult = NREL_LMC_FindEntry(wJSONText,"bias")
		variable iBias = 0
		if(itemsinList(sThisResult)==1)
			iBias = str2num(stringfromlist(0,sThisResult))
		endif
		
		sThisResult = NREL_LMC_FindEntry(wJSONText,"material")
		int iMaterial
		int iSubstrateCount
		if(itemsinList(sThisResult)>1)
			for(iMaterial=0;iMaterial<itemsinList(sThisResult);iMaterial+=1)
				iThisIndex = str2num(stringfromlist(iMaterial,sThisResult))
				if(iThisIndex<iSubstrates&&iThisIndex>iTargets)//targets
					if(stringmatch("COMBI3",sChamber))
						COMBI_GiveMeta(sProject,"Target_"+wJSONText[iThisIndex+3],sLibraryName,wJSONText[iThisIndex+1],-1)
					else
						COMBI_GiveMeta(sProject,"Target_"+wJSONText[iThisIndex+3],sLibraryName,wJSONText[iThisIndex+1],-1)
						COMBI_GiveMeta(sProject,"Target_"+wJSONText[iThisIndex+3]+"_SN",sLibraryName,wJSONText[iThisIndex+5],-1)
						COMBI_GiveMeta(sProject,"Target_"+wJSONText[iThisIndex+3]+"_Power",sLibraryName,wJSONText[iThisIndex+7],-1)
						COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+9]),sProject,sLibraryName,wJSONText[iThisIndex+1]+"_FP")
						COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+11]),sProject,sLibraryName,wJSONText[iThisIndex+1]+"_RP")
						COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+13]),sProject,sLibraryName,wJSONText[iThisIndex+1]+"_Volts")
					endif
				elseif(iThisIndex>iSubstrates&&iThisIndex<iBias) //single sustrates
					COMBI_GiveMeta(sProject,"Substrate",sLibraryName,wJSONText[iThisIndex+1],-1)					
				endif
			endfor
		endif
		
		//substrate bias
		sThisResult = NREL_LMC_FindEntry(wJSONText,"bias")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			if(stringmatch("true",wJSONText[iThisIndex+3]))
				COMBI_GiveMeta(sProject,"SubBias",sLibraryName,"True",-1)
			endif
		endif
		
		//substrate temp SP
		sThisResult = NREL_LMC_FindEntry(wJSONText,"setpoint")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"Heater_SP")
		endif
	
		//substrate temp RT
		sThisResult = NREL_LMC_FindEntry(wJSONText,"ideal")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"DepTemp_C")
		endif
		
		//anneal
		sThisResult = NREL_LMC_FindEntry(wJSONText,"anneal")
		if(itemsinList(sThisResult)==1)
			iThisIndex = str2num(stringfromlist(0,sThisResult))
			if(stringmatch("true",wJSONText[iThisIndex+3]))
				COMBI_GiveMeta(sProject,"Anneal",sLibraryName,"True",-1)
			endif
		endif
		
		if(stringmatch("COMBI3",sChamber))
			//usernamne
			sThisResult = NREL_LMC_FindEntry(wJSONText,"energy")
			if(itemsinList(sThisResult)==1)
				iThisIndex = str2num(stringfromlist(0,sThisResult))
				COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+1]),sProject,sLibraryName,"Laser_mJ")
				COMBI_GiveLibraryData(str2num(wJSONText[iThisIndex+3]),sProject,sLibraryName,"Laser_kV")
			endif
		endif
		
		//log
		COMBI_Add2Log(sProject,sLibraryName,"NREL_LMC",1,"Processing Meta & Library Data loaded from LMC File;FILE:  "+sOpened+";Entry ID:"+wJSONText[2])
		
		killwaves/Z root:T_TokenText, root:W_TokenSize, root:W_TokenType, root:W_TokenParent	
	endfor
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

//this function is ran when the user selects the Instrument from the COMBIgor drop down menu once activated
function COMBI_NREL_LMC()
	COMBI_GiveGlobal("sInstrumentName","NREL_LMC","COMBIgor")
	COMBI_InstrumentDefinition()
end

function/S NREL_LMC_FindEntry(wTextWave,sSearchString)
	wave/T wTextWave 
	string sSearchString
	int iString
	string sHits = ""
	for(iString=0;iString<dimsize(wTextWave,0);iString+=1)
		if(stringmatch(wTextWave[iString],sSearchString))
			sHits = sHits+num2str(iString)+";"
		endif
	endfor
	return sHits
end