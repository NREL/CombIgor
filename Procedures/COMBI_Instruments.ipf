#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// This file contains the include statements for all Plugin loaders and the functions necessary to define loading options
// Version History
// V1: Kevin Talley _ May 2018 : Original (COMBI_PluginGlobal, COMBI_GetPluginString)
// V1.1: Sage Bauers _ 20180514 : initializePluginLoaders, updatePluginList, getPluginList
// V1.2: Kevin Talley _ Sept 2018 : Reworked to distribute with stream lined Plugins
// V1.21: Karen Heinselman _ Oct 2018 : Polishing and debugging

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


// functions to define the drop down options
// creates panel with checkboxes for each Instrument in Instrument directory to include in experiment

// creates Instrument booleans when boxes are checked and updates menu
function COMBI_UpdateInstrumentList(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	if(stringmatch(ctrlName,"bAllInstruments"))
		string sCOMBIgorFolderPath = COMBI_GetGlobalString("sCOMBIgorFolderPath","COMBIgor")
		newpath/Q/O/Z pInstrumentPath sCOMBIgorFolderPath+"Instruments:"
		string sInstrumentFileList= indexedfile(pInstrumentPath,-1,".ipf")
		int vTotalInstruments = itemsinlist(sInstrumentFileList)
		int iIndex
		string sThisPluginName,sThisInstrumentName
		for(iIndex=0;iIndex<vTotalInstruments;iIndex+=1)
			sThisInstrumentName = removeending(stringfromlist(iIndex,sInstrumentFileList),".ipf")[6,inf]
			if(stringmatch(sThisInstrumentName,"*Example*"))
				continue
			endif
			if(checked==1)
				COMBI_InitializeInstrument(sThisInstrumentName)
			elseif(checked==0)
				COMBI_KillInstrument(sThisInstrumentName)
			endif
		endfor
		COMBI_GiveGlobal("bAllInstruments",num2str(checked),"COMBIgor")
		if(COMBI_GetGlobalNumber("bAllPlugins","COMBIgor")==checked)
			COMBI_GiveGlobal("bAllAddOns",num2str(checked),"COMBIgor")
		endif
		Killwindow/Z PickLoaders
		killpath/A
		COMBI_ActivateAddon()
		return -1	
	endif
	//define if checked, clear if unchecked
	if(checked==1)
		COMBI_InitializeInstrument(ctrlName)
	elseif(checked==0)
		COMBI_KillInstrument(ctrlName)
	endif
	
end

// returns string list of active Instrument loaders or import setups
// sOption default: Return default and initialized Instrument loaders ("1" or "2" in combigor global)
// sOption "Instruments": Return initialized Instrument loaders ("1" in combigor global)
// sOption "Included": Return default loaders (preferred vector, scalar, etc...) ("2" in combigor global)
// sOption "Generic": Return default loader saved setups ("3" in combigor global)
function/S COMBI_ActiveInstrumentList(sOption)
	string sOption
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//get list of Instrument waves
	if(!DataFolderExists("root:Packages:COMBIgor:Instruments:"))
		return ""
	endif
	setdatafolder root:Packages:COMBIgor:Instruments:
	string sAllInstrumentWaves =Wavelist("COMBI_*",";","")
	SetDataFolder $sTheCurrentUserFolder 
	variable sTotalInstruments = itemsinlist(sAllInstrumentWaves)
	
	// build list
	string sInstrumentList = ""
	string sThisInstrument
	int iIndex
	for(iIndex=0;iIndex<sTotalInstruments;iIndex++)
		sThisInstrument = Removeending(stringfromlist(iIndex,sAllInstrumentWaves)[6,inf],"_Globals")
		wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sThisInstrument+"_Globals"
		strswitch(sOption)
			case "Instruments":
				Execute sThisInstrument+"_Descriptions(\"InInstrumentMenu\")"
				if(!stringmatch(twGlobals[1][0],"No"))
					sInstrumentList += sThisInstrument+";"
				endif
				break
			case "Access":
				Execute sThisInstrument+"_Descriptions(\"OnAccessPanel\")"
				if(!stringmatch(twGlobals[2][0],"No"))
					sInstrumentList += sThisInstrument+";"
				endif
				break
			default:
				break
		endswitch
	endfor
	return sInstrumentList
end


//Functions to add to the wave twCOMBI_FischerXRFGlobals, returns a 0 for new variable, or 1 for same as previous, or 2 for value change
//user passes the name and value of the Global
function COMBI_GiveInstrumentGlobal(sThisInstrumentName,sGlobal,sValue,sFolder)
	string sGlobal // global variable name
	string sValue // global variable value
	string sFolder // name of folder, "COMBIgor" for main globals
	string sThisInstrumentName // name of Instrument to operate on
	
	//get globals from COMBIgor Instruments folder
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sThisInstrumentName+"_Globals"
	//if new folder
	if(Finddimlabel(twGlobals,1,sFolder)==-2)
		variable vPreviousFolders = dimsize(twGlobals,1)
		redimension/N=(-1,(vPreviousFolders+1)) twGlobals
		twGlobals[][vPreviousFolders]=""
		setdimlabel 1,vPreviousFolders,$sFolder,twGlobals
	endif
	//if it existed previously
	if(Finddimlabel(twGlobals,0,sGlobal)>0)
		string sOldValue = twGlobals[%$sGlobal][%$sFolder]
		twGlobals[%$sGlobal][%$sFolder] = sValue
		//returns a 1 or 2 depending on previous value 
		if(stringmatch(sValue,sOldValue))
			return 1
		else
			return 2
		endif
	endif
	//if it is new
	if(Finddimlabel(twGlobals,0,sGlobal)==-2)
		//increase number or rows
		variable vPreviousSize = dimsize(twGlobals,0)
		redimension/N=(vPreviousSize+1,-1) twGlobals
		//label dimension
		setdimlabel 0,vPreviousSize,$sGlobal,twGlobals
		twGlobals[vPreviousSize][%$sFolder] = sValue
		//return a zero
		return 0
	endif
end

//Functions to read global in twCOMBI_XRDBrukerGlobals, returns the value  "NAG" if Not A Global
function/S COMBI_GetInstrumentString(sThisInstrumentName,sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	string sThisInstrumentName // name of Instrument to operate on
	
	//get globals from COMBIgor Instruments folder
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sThisInstrumentName+"_Globals"
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return "NAG"
	endif
	if(finddimlabel(twGlobals,1,sFolder)==-2)
		return "NAG"
	endif
	//return value
	return twGlobals[%$sGlobal2Read][%$sFolder]
end

//Functions to read global in twCOMBI_XRDBrukerGlobals, returns the value  "nan" if Not A Global
function COMBI_GetInstrumentNumber(sThisInstrumentName, sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	string sThisInstrumentName // name of Instrument to operate on

	//get globals from COMBIgor Instruments folder
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sThisInstrumentName+"_Globals"
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return nan
	endif
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,1,sFolder)==-2)
		return nan
	endif
	//return value
	return str2num(twGlobals[%$sGlobal2Read][%$sFolder])
end

function COMBI_InstrumentReady(sThisInstrumentName)
	string sThisInstrumentName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	// name of Instrument to operate on
	setdatafolder root:Packages:COMBIgor:Instruments:
	if(itemsinlist(Wavelist("COMBI_"+sThisInstrumentName+"_Globals",";",""))==0)
		SetDataFolder $sTheCurrentUserFolder 
		COMBI_InitializeInstrument(sThisInstrumentName)
	endif
	SetDataFolder $sTheCurrentUserFolder 
end

//returns 1 if Instrument is activated, 0 if not active 
function COMBI_CheckForInstrument(sThisInstrumentName)
	string sThisInstrumentName
	// name of Instrument to operate on
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:Packages:COMBIgor:Instruments:
	if(stringmatch(sThisInstrumentName,"All"))
		variable bAll = COMBI_GetGlobalNumber("bAllAddOns","COMBIgor")
		return bAll
	endif
	if(itemsinlist(Wavelist("COMBI_"+sThisInstrumentName+"_Globals",";",""))==0)
		SetDataFolder $sTheCurrentUserFolder 
		return 0
	else
		SetDataFolder $sTheCurrentUserFolder 
		return 1
	endif
	
end

function COMBI_InitializeInstrument(sInstrumentName)
	string sInstrumentName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root: 
	//Make folders for storage and globals wave
	NewDataFolder/O/S Packages
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S Instruments
	//Check if existed previously
	string sWaveName = "COMBI_"+sInstrumentName+"_Globals"
	if(itemsinlist(Wavelist(sWaveName,";",""))==0)
		Make/T/N=(3,2) $sWaveName
		wave twInstrumentGlobals = $"root:Packages:COMBIgor:Instruments:"+sWaveName
		setdimlabel 0,0,DescriptionPass,twInstrumentGlobals
		setdimlabel 0,1,InMenu,twInstrumentGlobals
		setdimlabel 0,2,OnAccessPanel,twInstrumentGlobals
		setdimlabel 0,-1,Globals,twInstrumentGlobals
		setdimlabel 1,-1,Folder,twInstrumentGlobals
		setdimlabel 1,1,COMBIgor,twInstrumentGlobals
	else
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	//return to root
	SetDataFolder $sTheCurrentUserFolder 
	// print initialized project name
	Print sInstrumentName+" initialized."
	//include .ipf
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_"+sInstrumentName+"\""
	Execute/P/Q "COMPILEPROCEDURES "
	
end

//this function kills the globals wave for this Instrument
function/s COMBI_KillInstrument(sInstrumentName)
	string sInstrumentName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//Make folders for storage and globals wave
	NewDataFolder/O/S Packages
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S Instruments
	//Check if existed previously
	string sWaveName = "COMBI_"+sInstrumentName+"_Globals"
	if(itemsinlist(Wavelist(sWaveName,";",""))==1)
		SetDataFolder $sTheCurrentUserFolder 
		wave twInstrumentGlobals = $"root:Packages:COMBIgor:Instruments:"+sWaveName
		killwaves twInstrumentGlobals
	else
		SetDataFolder $sTheCurrentUserFolder 
		return ""
	endif
	// print initialized project name
	Print sInstrumentName+" killed."
	//uninclude .ipf
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_"+sInstrumentName+"\""
	Execute/P/Q "COMPILEPROCEDURES "
end

//function to make Instrument panel
function COMBI_InstrumentDefinition()
	
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	//get project if one exist, make if not
	string sProject, sInstrumentName
	if(Stringmatch(COMBI_GetGlobalString("sInstrumentProject", "COMBIgor"),"")||Stringmatch(COMBI_GetGlobalString("sInstrumentProject", "COMBIgor"),"NAG"))//sProject for this project doesn't exist (new project to intialize)
		COMBI_GiveGlobal("sInstrumentProject",COMBI_ChooseInstrumentProject(),"COMBIgor") 
		sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")//get new project
		if(Stringmatch(sProject,""))//user cancelled choosing project
			Return -1
		endif
	else
		sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")//get stored value
	endif
	//get Instrument name if one exist, make if not
	if(Stringmatch(COMBI_GetGlobalString("sInstrumentName", "COMBIgor"),"")||Stringmatch(COMBI_GetGlobalString("sInstrumentName", "COMBIgor"),"NAG"))//sProject for this project doesn't exist (new project to intialize)
		COMBI_GiveGlobal("sInstrumentName",COMBI_ChooseInstrumentName(),"COMBIgor") 
		sInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")//get new Instrument name
		if(Stringmatch(sInstrumentName,""))//user cancelled choosing project
			Return -1
		endif
	else
		sInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")//get stored value
	endif

	//make panel name
	string sPanelName="InstrumentDefPanel"
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z $sPanelName wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z $sPanelName
	
	//Check if initialized, do if not
	COMBI_InstrumentReady(sInstrumentName)
	//get global wave
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrumentName+"_Globals"
	//panel building options
	
	//# to add to definiton display
	variable vTotalDefinitions = dimsize(twGlobals,0)
	
	//size of panel
	variable vPanelHeight
	variable bDefined
	if(stringmatch("NAG",COMBI_GetInstrumentString(sInstrumentName,"sProject",sProject)))//not defined yet
		vPanelHeight = 140
		bDefined = 0
	else
		if(stringmatch(sInstrumentName,"Dektak8"))
			bDefined = 0
			vPanelHeight = 140
		else
			bDefined = 1
			vPanelHeight = 140
		endif
	endif	
	
	variable vYValue = 15
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+300,vWinTop+vPanelHeight)/N=$sPanelName as "Instrument Access"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 1,textyjust = 1, fsize = 12, save
	
	//Project Row
	DrawText 150,vYValue, "COMBIgor project:"
	vYValue+=20
	PopupMenu sInstrumentProject,pos={225,vYValue-8},mode=1,bodyWidth=250,value=COMBI_Projects(),proc=COMBI_WriteInstrumentGlobal,popvalue=sProject
	vYValue+=20
	DrawText 150,vYValue, "Instrument:"
	vYValue+=20
	PopupMenu sInstrumentName,pos={225,vYValue-8},mode=1,bodyWidth=250,value=COMBI_ActiveInstrumentList("Access"),proc=COMBI_WriteInstrumentGlobal,popvalue=sInstrumentName
	vYValue+=20
	//Buttons
	button btDefineInstrument,title="Define",appearance={native,All},pos={25,vYValue},size={250,25},proc=COMBI_DefineInstrumentButton,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=40
	
	//Add Text for Definition
	variable iDefinition
	string sThisValue
	string sThisDefinition
	int iDefTrack = 0
	if(bDefined==1)
		vPanelHeight+=30
		for(iDefinition=4;iDefinition<vTotalDefinitions;iDefinition+=1)
			Execute sInstrumentName+"_Descriptions(\""+getdimlabel(twGlobals,0,iDefinition)+"\")"
			sThisDefinition = twGlobals[0][0]//get from passing cell
			if(strlen(sThisDefinition)>0)
				sThisValue = twGlobals[iDefinition][%$sProject]
				DrawLine 10,vYValue-10,290,vYValue-10//draw top line
				DrawLine 10,vYValue+30,290,vYValue+30//draw bottom line
				DrawLine 10,vYValue-10,10,vYValue+30//draw left line
				DrawLine 290,vYValue-10,290,vYValue+30//draw right line
				SetDrawEnv fstyle=1, Save 	//bold
				DrawText 150,vYValue, sThisDefinition
				SetDrawEnv fstyle=0, Save  //not bold
				DrawText 150,vYValue+20, sThisValue
				vYValue+=40
				twGlobals[0][0] = ""//erase passing cell
				iDefTrack+=1
				vPanelHeight+=40
			endif
		endfor
		button btLoadFile,title="Load",appearance={native,All},pos={25,vYValue},size={250,25},proc=COMBI_LoadInstrumentButton,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	endif
	MoveWindow/W=$sPanelName  vWinLeft,vWinTop,vWinLeft+300,vWinTop+vPanelHeight
	
end

function COMBI_WriteInstrumentGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	if(stringmatch("_none_",popStr))
		popStr = ""
	endif
	COMBI_GiveGlobal(ctrlName,popStr,"COMBIgor")
	COMBI_InstrumentDefinition()	
end

function COMBI_LoadInstrumentButton(sControl): ButtonControl
	string sControl//window name (to get Instrument name)
	string sInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sInstrumentProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	execute sInstrumentName+"_Load()"
end

function COMBI_DefineInstrumentButton(sControl): ButtonControl
	string sControl//window name (to get Instrument name)
	string sInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sInstrumentProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	execute sInstrumentName+"_Define()"
end

function/S COMBI_ChooseInstrumentName()
	string sActiveInstruments = COMBI_ActiveInstrumentList("Instruments")
	string sTheChoosenOne = COMBI_StringPrompt("","Choose Instrument",sActiveInstruments,"Please select an instrument.","Select Instrument")
	COMBI_GiveGlobal("sInstrumentName",sTheChoosenOne,"COMBIgor")
	return sTheChoosenOne
end

function/S COMBI_ChooseInstrumentProject()
	string sTheChoosenOne = COMBI_ChooseProject()
	COMBI_GiveGlobal("sInstrumentProject",sTheChoosenOne,"COMBIgor")
	return sTheChoosenOne
end

