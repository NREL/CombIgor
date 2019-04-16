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
		 "Fischer XRF",/Q, COMBI_FischerXRF()
	end
end


//returns a list of descriptors for each of the globals used to define loading
Function/S FischerXRF_Descriptions(sGlobalName)
	string sGlobalName
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_FischerXRF_Globals"
	string sReturnstring =""
	strswitch(sGlobalName)
		case "FischerXRF":
			sReturnstring = "Fischer XRF"
			break
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "sXDest":
			sReturnstring =  "X stage position (mm) label:"
			break
		case "sYDest":
			sReturnstring = "Y stage position (mm) label:"
			break
		case "sThicknessDest":
			sReturnstring = "Layer thickness label:"
			break
		case "sMQDest":
			sReturnstring = "Measurement quality label:"
			break
		case "vXCol":
			sReturnstring = "Column of X stage position in file:"
			break
		case "vYCol":
			sReturnstring = "Column of Y stage position in file:"
			break
		case "vThicknessCol":
			sReturnstring = "Column of thickness in file:"
			break
		case "vMQCol":
			sReturnstring = "Column of measurement quality in file:"
			break
		case "vNumberofElements":
			sReturnstring = "Number of elements in file:"
			break
		case "sElements":
			sReturnstring = "List of Element labels:"
			break
		case "sElementColumns":
			sReturnstring = "Column of elements in file:"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end

function FischerXRF_Define()
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	string sXDest, sYDest, sElements, sElementColumns
	variable vPanelHeight, vXCol, vYCol, vThicknessCol, vMQCol, iInput, vElementColumn, vNumberofElements
	string sXNew = "", sYNew = ""
	string sThicknessInput, sNewThicknessInput = ""
	string sMQInput, sNewMQInput = ""
	
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sXDest",sProject)))//if project is defined previously, start with those values
		sXDest = COMBI_GetInstrumentString(sThisInstrumentName,"sXDest",sProject)
		sYDest = COMBI_GetInstrumentString(sThisInstrumentName,"sYDest",sProject)
		sThicknessInput = COMBI_GetInstrumentString(sThisInstrumentName,"sThicknessDest",sProject)
		sMQInput = COMBI_GetInstrumentString(sThisInstrumentName,"sMQDest",sProject)
		vXCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vXCol",sProject)
		vYCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vYCol",sProject)
		vMQCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vMQCol",sProject)
		vThicknessCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vThicknessCol",sProject)
		sElements = COMBI_GetInstrumentString(sThisInstrumentName,"sElements",sProject)
		sElementColumns = COMBI_GetInstrumentString(sThisInstrumentName,"sElementColumns",sProject)
		vNumberofElements = COMBI_GetInstrumentNumber(sThisInstrumentName,"vNumberofElements",sProject)
	else//not previously defined, start with default values 
		sXDest = "Xmm_XRF"
		sYDest = "Ymm_XRF"
		sElements = ""
		sElementColumns = ""
		vNumberofElements = 2
		vXCol = 2
		vYCol = 3
		vThicknessCol = 5
		vMQCol = 0
		sThicknessInput = "Thickness_XRF"
		sMQInput =  "MQ_XRF"
	endif
	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject","",sProject)
	
	// get info for standard file values
	//x position
	string sX = COMBI_DataTypePrompt(sProject,sXDest,"X stage position",0,1,1,1)
	vXCol = COMBI_NumberPrompt(vXCol,"X stage position column in these files:","This indicates where X position is located in files to be loaded.","Location of X stage position data?")
	if(numtype(vXCol)==2)
		return -1
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sXDest",sX,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vXCol",num2str(vXCol),sProject)// store global
	//y position
	string sY = COMBI_DataTypePrompt(sProject,sYDest,"Y stage position",0,1,1,1)
	vYCol = COMBI_NumberPrompt(vYCol,"Y stage position column in file:","This indicates where Y position is located in files to be loaded","Location of Y stage position data?")
	if(numtype(vYCol)==2)
		return -1
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sYDest",sY,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vYCol",num2str(vYCol),sProject)// store global
	//layer thickness
	string sThickness = COMBI_DataTypePrompt(sProject,sThicknessInput,"Thickness",0,1,1,1)
	vThicknessCol = COMBI_NumberPrompt(vThicknessCol,"Thickness column in these files:","This indicates where thickness is located in files to be loaded.","Location of thickness data?")
	if(numtype(vXCol)==2)
		return -1
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sThicknessDest",sThickness,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vThicknessCol",num2str(vThicknessCol),sProject)// store global
	//mesasurement quality
	string sMQ = COMBI_DataTypePrompt(sProject,sMQInput,"Measurement Quality (MQ)",0,1,1,1)
	vMQCol = COMBI_NumberPrompt(vMQCol,"Meaurement Quality (MQ) column in these files:","This indicates where to find measurement quality (MQ) in the files to be loaded.","Location of measurement quality data")
	if(stringmatch(sMQ,"CANCEL"))
		return -1
	endif	
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sMQDest",sMQ,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vMQCol",num2str(vMQCol),sProject)// store global
	// all elements
	vNumberofElements = COMBI_NumberPrompt(vNumberofElements,"Number of Elements in these files:","This indicates how many elements will be in each file","Elements in the measurement?")
	if(numtype(vNumberofElements)==2)
		return -1
	endif
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vNumberofElements",num2str(vNumberofElements),sProject)// store global
	//loop through to define each
	string sAllElements = "",sNewElementInput
	string sAllElementColumns = "", sNewElementColumn
	for(iInput=0;iInput<vNumberofElements;iInput+=1)//each thing added to the MappingGrid table
		if(iInput<itemsinlist(sElements))
			sNewElementInput = stringfromlist(iInput,sElements)
			sNewElementColumn = num2str(str2num(stringfromlist(iInput,sElementColumns)))
		else
			sNewElementInput = "New"
			sNewElementColumn = num2str(7+2*iInput)
		endif
		
		sNewElementInput = COMBI_DataTypePrompt(sProject,sNewElementInput,"Element "+num2str(iInput+1),0,1,0,1)
		if(stringmatch(sNewElementInput,"CANCEL"))
			return -1
		endif	
		sNewElementColumn = num2str(COMBI_NumberPrompt(str2num(sNewElementColumn),sNewElementInput+" concentration column in these files:","This indicates where to find "+sNewElementInput+" concentration in the files to be loaded.","Location of "+sNewElementInput+" concentration data?"))
		if(stringmatch(sNewElementColumn,"CANCEL"))
			return -1
		endif	
		sAllElements=AddListItem(sNewElementInput,sAllElements,";",Inf)
		sAllElementColumns=AddListItem(num2str(str2num(sNewElementColumn)),sAllElementColumns,";",Inf) 
	
	endfor
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sElements",sAllElements,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sElementColumns",sAllElementColumns,sProject)// store global
	
	//mark as defined by storing project name in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	//reload panel
	COMBI_InstrumentDefinition()
	
end

function FischerXRF_Load()
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	//get Fischer globals
	string sThisInstrumentName = "FischerXRF"
	string sXLabel = COMBI_GetInstrumentString(sThisInstrumentName,"sXDest",sProject)
	string sYLabel = COMBI_GetInstrumentString(sThisInstrumentName,"sYDest",sProject)
	string sThicknessLabel = COMBI_GetInstrumentString(sThisInstrumentName,"sThicknessDest",sProject)
	variable vXCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vXCol",sProject)
	variable vYCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vYCol",sProject)
	variable vThicknessCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vThicknessCol",sProject)
	string sAllElements = COMBI_GetInstrumentString(sThisInstrumentName,"sElements",sProject)
	string sAllElementColumns = COMBI_GetInstrumentString(sThisInstrumentName,"sElementColumns",sProject)
	variable vNumberofElements = COMBI_GetInstrumentNumber(sThisInstrumentName,"vNumberofElements",sProject)
	variable vMQCol = COMBI_GetInstrumentNumber(sThisInstrumentName,"vMQCol",sProject)
	string sMQDest = COMBI_GetInstrumentString(sThisInstrumentName,"sMQDest",sProject)
	
	//random variables
	variable iLibrary, iThisElement
	string sThisElement
	
	//number of Libraries
	int vNumberOfLibraries = COMBI_NumberPrompt(1,"Number of libraries in this file","This is the total number of libraries in the folder. If desired, some samples may be skipped during loading, but please enter the total number of libraries here.","Libraries in File Load")
	if(vNumberOfLibraries<=0)
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	//get project globals
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	variable iTotalSamples = vTotalSamples-1
	
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
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	LoadWave/J/D/K=2/N=XRFLoadedByCOMBIgor/Q/O/M
	string sLoadedFileName = S_fileName
	string sLoadedFilePath = S_path 
	//abort if no file selected
	if(V_flag==0)
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	// get some of the columns
	wave/T/Z wLoadedFile = $"root:XRFLoadedByCOMBIgor0"
	
	//make wave numeric rather than text
	variable vRows= dimsize(wLoadedFile,0), vCols = dimsize(wLoadedFile,1)
	make/O/N=(vRows,vCols) wLoadedNumricWave
	wave/Z wLoadedNumricFile = root:wLoadedNumricWave
	wLoadedNumricFile[][]=nan
	variable iRow,iCol
	for(iRow=0;iRow<vRows;iRow+=1)
		for(iCol=0;iCol<vCols;iCol+=1)
			wLoadedNumricFile[iRow][iCol] = str2num(wLoadedFile[iRow][iCol])
		endfor
	endfor
	
	
	//always there values
	string sDataTypes = sXLabel+";"+sYLabel+";"+sThicknessLabel+";"+sMQDest
	string sDataColumnNumbers = num2str(vXCol-1)+";"+num2str(vYCol-1)+";"+num2str(vThicknessCol-1)+";"+num2str(vMQCol-1)
	
	//make data type list
	for(iThisElement=0;iThisElement<itemsinlist(sAllElements);iThisElement+=1)
		// get specific element label
		sThisElement = stringfromlist(iThisElement,sAllElements)
		if(!stringmatch("Skip",sThisElement))
			variable vElementCol = str2num(stringfromlist(iThisElement,sAllElementColumns))
			// move comp data
			sDataTypes = sDataTypes+";"+sThisElement
			sDataColumnNumbers = sDataColumnNumbers+";"+num2str(vElementCol-1)
		endif
	endfor
	
	COMBI_SortNewScalarData(sProject,wLoadedNumricFile,sLibraries,sFirstSamples,sLastSamples,sFirstIndexs,sLastIndexs,sDataTypes,sDataColumnNumbers)
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File: "+sLoadedFilePath+sLoadedFileName
	sLogEntry2 = "Library Samples (First and Last): "+ReplaceString(";", sFirstSamples, ",")+" to "+ReplaceString(";", sLastSamples, ",")
	sLogEntry3 = "From File Rows (First and Last): "+ReplaceString(";", sFirstIndexs, ",") +" to "+ReplaceString(";", sLastIndexs, ",")
	sLogEntry4 = "Data Types: "+ReplaceString(";", sDataTypes, ",") 
	sLogEntry5 = "Data Columns in File: "+ReplaceString(";", sDataColumnNumbers, ",") 
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	COMBI_Add2Log(sProject,sLibraries,"FischerXRF",1,sLogText)	
	
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

function COMBI_FischerXRF()
	COMBI_GiveGlobal("sInstrumentName","FischerXRF","COMBIgor")
	COMBI_InstrumentDefinition()
end
