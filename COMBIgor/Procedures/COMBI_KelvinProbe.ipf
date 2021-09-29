#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Andrea Crovetto _ March 2020 : based on Kevin Talley's Fisher XRF procedure file

//Description of functions within:
//C_Example
//P_Example

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Instruments"
		 "Kelvin Probe",/Q, COMBI_KelvinProbe()
	end
end


//returns a list of descriptors for each of the globals used to define loading
Function/S KelvinProbe_Descriptions(sGlobalName)
	string sGlobalName
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_KelvinProbe_Globals"
	string sReturnstring =""
	strswitch(sGlobalName)
		case "KelvinProbe":
			sReturnstring = "Kelvin Probe"
			break
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "vGoldBefore":
			sReturnstring =  "Au-tip CPD (before map):"
			break
		case "vGoldAfter":
			sReturnstring =  "Au-tip CPD (before map):"
			break
		case "vGoldReference":
			sReturnstring =  "Au work function"
			break
		case "sCPDDest":
			sReturnstring =  "Contact potential difference column header:"
			break
		case "sWFDest":
			sReturnstring = "Work function column header:"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

function KelvinProbe_Define()
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	variable vGoldBefore, vGoldAfter, vGoldReference
	string sCPDDest, sWFDest
	
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"vGoldBefore",sProject)))//if project is defined previously, start with those values
		vGoldBefore = COMBI_GetInstrumentNumber(sThisInstrumentName,"vGoldBefore",sProject)
		vGoldAfter = COMBI_GetInstrumentNumber(sThisInstrumentName,"vGoldAfter",sProject)
		vGoldReference = COMBI_GetInstrumentNumber(sThisInstrumentName,"vGoldReference",sProject)
		sCPDDest = COMBI_GetInstrumentString(sThisInstrumentName,"sCPDDest",sProject)
		sWFDest = COMBI_GetInstrumentString(sThisInstrumentName,"sWFDest",sProject)
	else //not previously defined, start with default values 
		vGoldBefore = 200
		vGoldAfter = 200
		vGoldReference = 5.1
		sCPDDest = "CPD"
		sWFDest = "Work_Function"
	endif
	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject","",sProject)
	
	// get info for standard file values
	//x position
	vGoldBefore = COMBI_NumberPrompt(vGoldBefore,"Contact potential difference between gold reference and tip (in mV), as measured before the map. Sign is important!","What was the contact potential difference between the gold reference and the tip before measuring the library?","Au-tip CPD before map")
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vGoldBefore",num2str(vGoldBefore),sProject)// store global
	
	vGoldAfter = COMBI_NumberPrompt(vGoldAfter,"Contact potential difference between gold reference and tip (in mV), as measured after the map. Sign is important!","What was the contact potential difference between the gold reference and the tip after measuring the library?","Au-tip CPD after map")
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vGoldAfter",num2str(vGoldAfter),sProject)// store global
	
	//if the measurement on the gold reference drifts by more than 100mV before an after the map, give a warning
	if (vGoldAfter -vGoldBefore > 100 || vGoldAfter -vGoldBefore < -100 )
		DoAlert/T="Unstable tip work function" 0,"Contact potential difference between gold reference and tip changed by more than 100 mV after the map. The measurement may be inaccurate"
	endif	
	
	vGoldReference = COMBI_NumberPrompt(vGoldReference,"Known work function of the gold reference sample (in eV)","What is the known work function of the gold reference sample? (5.1 eV if undamaged)","Au standard work function")
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vGoldReference",num2str(vGoldReference),sProject)// store global
	
	string sCPD = COMBI_DataTypePrompt(sProject,sCPDDest,"Contact potential difference column header",0,1,1,1)	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sCPDDest",sCPD,sProject)// store global	
	
	string sWF = COMBI_DataTypePrompt(sProject,sWFDest,"Work function column header",0,1,1,1)	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sWFDest",sWF,sProject)// store global	
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
	
end

function KelvinProbe_Load()
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	//get Kelvin Probe globals
	string sThisInstrumentName = "KelvinProbe"
	string sCPDLabel = COMBI_GetInstrumentString(sThisInstrumentName,"sCPDDest",sProject)
	string sWFLabel = COMBI_GetInstrumentString(sThisInstrumentName,"sWFDest",sProject)
	
	//random variables
	variable iLibrary
	
	//number of Libraries
	int vNumberOfLibraries = COMBI_NumberPrompt(1,"Number of libraries in this file","This is the total number of libraries in the folder. If desired, some samples may be skipped during loading, but please enter the total number of libraries here.","Libraries in File Load")
	if(vNumberOfLibraries<=0)
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	//get project globals
	variable vGoldBefore = COMBI_GetInstrumentNumber(sThisInstrumentName,"vGoldBefore",sProject)
	variable vGoldAfter = COMBI_GetInstrumentNumber(sThisInstrumentName,"vGoldAfter",sProject)
	variable vGoldReference = COMBI_GetInstrumentNumber(sThisInstrumentName,"vGoldReference",sProject)
	
	
	//Get Library Names
	string sLibraries="", sFirstSamples="",sLastSamples="",sFirstIndexs="",sLastIndexs="", sThisLibrary
	for(iLibrary=0;iLibrary<vNumberOfLibraries;iLibrary+=1)
		string sLibraryDestinations = COMBI_LibraryLoadingPrompt(sProject,"New","Library "+num2str(iLibrary+1),1,1,-1,iLibrary)
		if(stringmatch(sLibraryDestinations"CANCEL"))
			SetDataFolder $sTheCurrentUserFolder 
			return -1
		endif
		sLibraries = AddListItem(cleanupname(stringfromlist(0,sLibraryDestinations),0),sLibraries,";",inf)
		sFirstSamples = AddListItem(stringfromlist(1,sLibraryDestinations),sFirstSamples,";",inf)
		sLastSamples = AddListItem(stringfromlist(2,sLibraryDestinations),sLastSamples,";",inf)
		sFirstIndexs = AddListItem(stringfromlist(3,sLibraryDestinations),sFirstIndexs,";",inf)
		sLastIndexs = AddListItem(stringfromlist(4,sLibraryDestinations),sLastIndexs,";",inf)
	endfor
	
	//direct next dialog towards import path if import option is on.
	DoAlert/T="Select measurement file" 0,"Import the .DAT measurement file taken on the combinatorial library. Expected file name: PDAC_COMX_XXXXX.DAT"
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	//the first row ("Work function" header) is ignored by using the command /L{0,1,0,0,0}
	LoadWave/L={0,1,0,0,0}/J/D/K=2/N=XRFLoadedByCOMBIgor/Q/O/M
	string sLoadedFileName = S_fileName
	string sLoadedFilePath = S_path
	//abort if no file selected
	if(V_flag==0)
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	// get some of the columns
	wave/T/Z wLoadedFile = $"root:XRFLoadedByCOMBIgor0"
	variable vRows= dimsize(wLoadedFile,0), vCols = dimsize(wLoadedFile,1)
	//make a 440x2 'processed data' wave for storing CPD and work function
	make/O/N=(440,2) wLoadedNumricWave	
	
	//make processed data wave numeric rather than text	
	wave/Z wLoadedNumricFile = root:wLoadedNumricWave
	wLoadedNumricFile[][]=nan
	variable iRow,iCol
   variable index = 0
	for(iCol=0;iCol<20;iCol+=1)
		for(iRow=0;iRow<22;iRow+=1)
			wLoadedNumricFile[index][0] = str2num(wLoadedFile[iRow][iCol])/1000
			wLoadedNumricFile[index][1] = (wLoadedNumricFile[index][0]*1000 + vGoldReference * 1000 - (vGoldBefore + vGoldAfter)/2)/1000
			index +=1
		endfor
	endfor	
	
	//specify column headers for the CPD and work function columns
	string sDataTypes = sCPDLabel+";"+sWFLabel+";"
	string sDataColumnNumbers = num2str(0)+";"+num2str(1)+";"
		
	//sort the data to make it COMBIgor compatible
	COMBI_SortNewScalarData(sProject,wLoadedNumricFile,sLibraries,sFirstSamples,sLastSamples,sFirstIndexs,sLastIndexs,sDataTypes,sDataColumnNumbers)
	
	//asks the user if they want to interpolate the original data to make it fit into a standard 4x11 grid
	string sInterpolate
	sInterpolate = COMBI_StringPrompt("Yes","Do you want to interpolate the Kelvin probe measurement data into the standard grid now? (it can also be done later)","Yes;No","Do you want to use an interpolation function to make the original data fit into a 4x11 grid? It can also be done later in COMBIgor -> Projects -> Interpolate Project-2-Project","Interpolate into standard grid?")
	if (stringmatch(sInterpolate"Yes"))
		COMBI_Project2ProjectScalarInterp()
	endif
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File: "+sLoadedFilePath+sLoadedFileName
	sLogEntry2 = "Library Samples (First and Last): "+ReplaceString(";", sFirstSamples, ",")+" to "+ReplaceString(";", sLastSamples, ",")
	sLogEntry3 = "From File Rows (First and Last): "+ReplaceString(";", sFirstIndexs, ",") +" to "+ReplaceString(";", sLastIndexs, ",")
	sLogEntry4 = "Data Types: "+ReplaceString(";", sDataTypes, ",") 
	sLogEntry5 = "Data Columns in File: "+ReplaceString(";", sDataColumnNumbers, ",") 
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	COMBI_Add2Log(sProject,sLibraries,"KelvinProbe",1,sLogText)	
	
	// kill waves
	killwaves wLoadedFile, wLoadedNumricFile
	
	//if plot on loading
	int iDataType
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		for(iLibrary=0;iLibrary<itemsinlist(sLibraries);iLibrary+=1)
			string sTheLibrary = stringfromlist(iLibrary,sLibraries)
			for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)
				string sTheDataType = stringfromlist(iDataType,sDataTypes)
				COMBIDisplay_Map(sProject,sTheLibrary,sTheDataType,"Linear","Rainbow","","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",19,"000000")
			endfor
		endfor
	endif
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

function COMBI_KelvinProbe()
	COMBI_GiveGlobal("sInstrumentName","KelvinProbe","COMBIgor")
	COMBI_InstrumentDefinition()
end
