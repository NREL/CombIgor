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


// creates Plugin booleans when boxes are checked and updates menu
function COMBI_UpdatePluginList(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	//define if checked, clear if unchecked
	string sPluginFileList, sInstrumentFileList, sThisPluginName,sThisInstrumentName
	int vTotalPlugins, vTotalInstruments, vTotal, iIndex
	string sCOMBIgorFolderPath = COMBI_GetGlobalString("sCOMBIgorFolderPath","COMBIgor")
	if(stringmatch(ctrlName,"bAllAddOns"))
		newpath/Q/O/Z pPluginPath sCOMBIgorFolderPath+"Plugins:"
		newpath/Q/O/Z pInstrumentPath sCOMBIgorFolderPath+"Instruments:"
		sPluginFileList= indexedfile(pPluginPath,-1,".ipf")
		sInstrumentFileList= indexedfile(pInstrumentPath,-1,".ipf")
		vTotalPlugins = itemsinlist(sPluginFileList)
		vTotalInstruments = itemsinlist(sInstrumentFileList)
		vTotal = (vTotalPlugins+vTotalInstruments)
		for(iIndex=0;iIndex<vTotalPlugins;iIndex+=1)
			sThisPluginName = removeending(stringfromlist(iIndex,sPluginFileList),".ipf")[6,inf]
			if(stringmatch(sThisPluginName,"*Example*"))
				continue
			endif
			if(checked==1)
				COMBI_InitializePlugin(sThisPluginName)
			elseif(checked==0)
				COMBI_KillPlugin(sThisPluginName)
			endif
		endfor
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
		COMBI_GiveGlobal("bAllAddOns",num2str(checked),"COMBIgor")
		COMBI_GiveGlobal("bAllPlugins",num2str(checked),"COMBIgor")
		COMBI_GiveGlobal("bAllInstruments",num2str(checked),"COMBIgor")
		Killwindow/Z PickLoaders
		killpath/A
		COMBI_ActivateAddon()
		return -1
	elseif(stringmatch(ctrlName,"bAllPlugins"))
		newpath/Q/O/Z pPluginPath sCOMBIgorFolderPath+"Plugins:"
		sPluginFileList= indexedfile(pPluginPath,-1,".ipf")
		vTotalPlugins = itemsinlist(sPluginFileList)
		for(iIndex=0;iIndex<vTotalPlugins;iIndex+=1)
			sThisPluginName = removeending(stringfromlist(iIndex,sPluginFileList),".ipf")[6,inf]
			if(stringmatch(sThisPluginName,"*Example*"))
				continue
			endif
			if(checked==1)
				COMBI_InitializePlugin(sThisPluginName)
			elseif(checked==0)
				COMBI_KillPlugin(sThisPluginName)
			endif
		endfor
		COMBI_GiveGlobal("bAllPlugins",num2str(checked),"COMBIgor")
		if(COMBI_GetGlobalNumber("bAllInstruments","COMBIgor")==checked)
			COMBI_GiveGlobal("bAllAddOns",num2str(checked),"COMBIgor")
		endif
		Killwindow/Z PickLoaders
		killpath/A
		COMBI_ActivateAddon()
		return -1
		
	endif
	if(checked==1)
		COMBI_InitializePlugin(ctrlName)
	elseif(checked==0)
		COMBI_KillPlugin(ctrlName)
	endif
	
end

// returns string list of active Plugin loaders or import setups
// sOption default: Return default and initialized Plugin loaders ("1" or "2" in combigor global)
// sOption "Plugins": Return initialized Plugin loaders ("1" in combigor global)
//sOption "Access" Return Plugins that need to be defined via the access panel (exclude some Plugins)
function/S COMBI_ActivePluginList(sOption)
	string sOption
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root: 
	//get list of Plugin waves
	if(!DataFolderExists("root:Packages:COMBIgor:Plugins:"))
		return ""
	endif
	setdatafolder root:Packages:COMBIgor:Plugins:
	string sAllPluginWaves =Wavelist("COMBI_*",";","")
	SetDataFolder $sTheCurrentUserFolder 
	variable sTotalPlugins = itemsinlist(sAllPluginWaves)
	
	// build list
	string sPluginList = ""
	string sThisPlugin
	int iIndex
	for(iIndex=0;iIndex<sTotalPlugins;iIndex++)
		sThisPlugin = Removeending(stringfromlist(iIndex,sAllPluginWaves)[6,inf],"_Globals")
		wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sThisPlugin+"_Globals"
		strswitch(sOption)
			case "Plugins":
				sPluginList += sThisPlugin+";"
				break
			default:
				break
		endswitch
	endfor
	return sPluginList
end

//Functions to add to the wave twCOMBI_FischerXRFGlobals, returns a 0 for new variable, or 1 for same as previous, or 2 for value change
//user passes the name and value of the Global
function COMBI_GivePluginGlobal(sThisPluginName,sGlobal,sValue,sFolder)
	string sGlobal // global variable name
	string sValue // global variable value
	string sFolder // name of folder, "COMBIgor" for main globals
	string sThisPluginName // name of Plugin to operate on
	
	//get globals from COMBIgor Plugins folder
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sThisPluginName+"_Globals"
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
function/S COMBI_GetPluginString(sThisPluginName,sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	string sThisPluginName // name of Plugin to operate on
	
	//get globals from COMBIgor Plugins folder
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sThisPluginName+"_Globals"
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
function COMBI_GetPluginNumber(sThisPluginName, sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	string sThisPluginName // name of Plugin to operate on

	//get globals from COMBIgor Plugins folder
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sThisPluginName+"_Globals"
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

function COMBI_PluginReady(sThisPluginName)
	string sThisPluginName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	// name of Plugin to operate on
	setdatafolder root:Packages:COMBIgor:Plugins:
	if(itemsinlist(Wavelist("COMBI_"+sThisPluginName+"_Globals",";",""))==0)
		COMBI_InitializePlugin(sThisPluginName)
	endif
	SetDataFolder $sTheCurrentUserFolder 
end

//returns 1 if Plugin is activated, 0 if not activate 
function COMBI_CheckForPlugin(sThisPluginName)
	string sThisPluginName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	// name of Plugin to operate on
	setdatafolder root:Packages:COMBIgor:Plugins:
	if(itemsinlist(Wavelist("COMBI_"+sThisPluginName+"_Globals",";",""))==0)
		SetDataFolder $sTheCurrentUserFolder 
		return 0
	else
		SetDataFolder $sTheCurrentUserFolder 
		return 1
	endif
	
end

function COMBI_InitializePlugin(sPluginName)
	string sPluginName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//include .ipf
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_"+sPluginName+"\""
	Execute/P/Q "COMPILEPROCEDURES "
	//Make folders for storage and globals wave
	setdatafolder root: 
	NewDataFolder/O/S Packages
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S Plugins
	//Check if existed previously
	string sWaveName = "COMBI_"+sPluginName+"_Globals"
	if(itemsinlist(Wavelist(sWaveName,";",""))==0)
		Make/T/N=(1,2) $sWaveName
		wave twPluginGlobals = $"root:Packages:COMBIgor:Plugins:"+sWaveName
		setdimlabel 0,-1,Globals,twPluginGlobals
		setdimlabel 1,-1,Folder,twPluginGlobals
		setdimlabel 1,1,COMBIgor,twPluginGlobals
	else
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder 
	// print initialized project name
	Print sPluginName+" initialized."
	//include .ipf
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_"+sPluginName+"\""
	Execute/P/Q "COMPILEPROCEDURES "
	
end

//this function kills the globals wave for this Plugin
function/s COMBI_KillPlugin(sPluginName)
	string sPluginName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//Make folders for storage and globals wave
	setdatafolder root: 
	NewDataFolder/O/S Packages
	NewDataFolder/O/S COMBIgor
	NewDataFolder/O/S Plugins
	//Check if existed previously
	string sWaveName = "COMBI_"+sPluginName+"_Globals"
	if(itemsinlist(Wavelist(sWaveName,";",""))==1)
		SetDataFolder $sTheCurrentUserFolder 
		wave twPluginGlobals = $"root:Packages:COMBIgor:Plugins:"+sWaveName
		killwaves twPluginGlobals
	else
		SetDataFolder $sTheCurrentUserFolder 
		return ""
	endif
	//return to root
	
	// print initialized project name
	Print sPluginName+" killed."
	//uninclude .ipf
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_"+sPluginName+"\""
	Execute/P/Q "COMPILEPROCEDURES "
	SetDataFolder $sTheCurrentUserFolder 
end

//function to make Plugin panel
function COMBI_PluginDefinition()
	
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	//get project if one exists, make if not
	string sProject, sPluginName
	if(Stringmatch(COMBI_GetGlobalString("sPluginProject", "COMBIgor"),"")||Stringmatch(COMBI_GetGlobalString("sPluginProject", "COMBIgor"),"NAG"))//sProject for this project doesn't exist (new project to intialize)
		COMBI_GiveGlobal("sPluginProject",COMBI_ChoosePluginProject(),"COMBIgor") 
		sProject = COMBI_GetGlobalString("sPluginProject", "COMBIgor")//get new project
		if(Stringmatch(sProject,""))//user cancelled choosing project
			Return -1
		endif
	else
		sProject = COMBI_GetGlobalString("sPluginProject", "COMBIgor")//get stored value
	endif
	//get Plugin name if one exist, make if not
	if(Stringmatch(COMBI_GetGlobalString("sPluginName", "COMBIgor"),"")||Stringmatch(COMBI_GetGlobalString("sPluginName", "COMBIgor"),"NAG"))//sProject for this project doesn't exist (new project to intialize)
		COMBI_GiveGlobal("sPluginName",COMBI_ChoosePluginName(),"COMBIgor") 
		sPluginName = COMBI_GetGlobalString("sPluginName", "COMBIgor")//get new Plugin name
		if(Stringmatch(sPluginName,""))//user cancelled choosing project
			Return -1
		endif
	else
		sPluginName = COMBI_GetGlobalString("sPluginName", "COMBIgor")//get stored value
	endif

	//make panel name
	string sPanelName="PluginDefPanel"
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z $sPanelName wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z $sPanelName
	
	//Check if initialized, do if not
	COMBI_PluginReady(sPluginName)
	//get global wave
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sPluginName+"_Globals"
	//panel building options
	
	//# to add to definition display
	variable vTotalDefinitions = dimsize(twGlobals,0)
	
	//size of panel
	variable vPanelHeight
	variable bDefined
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sProject)))//not defined yet
		vPanelHeight = 140
		bDefined = 0
	else
		vPanelHeight = 170+40*(vTotalDefinitions-2)//defined
		bDefined = 1
	endif	
	
	variable vYValue = 15
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+300,vWinTop+vPanelHeight)/N=$sPanelName as "Plugin Access"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 1,textyjust = 1, fsize = 12, save
	
	//Project Row
	DrawText 150,vYValue, "COMBIgor project:"
	vYValue+=20
	PopupMenu sPluginProject,pos={225,vYValue-8},mode=1,bodyWidth=250,value=COMBI_Projects(),proc=COMBI_WritePluginGlobal,popvalue=sProject
	vYValue+=20
	DrawText 150,vYValue, "Plugin:"
	vYValue+=20
	PopupMenu sPluginName,pos={225,vYValue-8},mode=1,bodyWidth=250,value=COMBI_ActivePluginList("Access"),proc=COMBI_WritePluginGlobal,popvalue=sPluginName
	vYValue+=20
	//Buttons
	button btDefinePlugin,title="Define",appearance={native,All},pos={25,vYValue},size={250,25},proc=COMBI_DefinePluginButton,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=40
	
	//Add Text for Definition
	variable iDefinition
	string sThisValue
	string sThisDefinition
	if(bDefined==1)
		for(iDefinition=2;iDefinition<vTotalDefinitions;iDefinition+=1)
			Execute sPluginName+"_Descriptions(\""+getdimlabel(twGlobals,0,iDefinition)+"\")"
			sThisDefinition = twGlobals[0][0]//get from passing cell
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
		endfor
		button btLoadFile,title="Load",appearance={native,All},pos={25,vYValue},size={250,25},proc=COMBI_LoadPluginButton,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	endif
end

function COMBI_WritePluginGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	if(stringmatch("_none_",popStr))
		popStr = ""
	endif
	COMBI_GiveGlobal(ctrlName,popStr,"COMBIgor")
	COMBI_PluginDefinition()	
end

function COMBI_LoadPluginButton(sControl): ButtonControl
	string sControl//window name (to get Plugin name)
	string sPluginName = COMBI_GetGlobalString("sPluginName", "COMBIgor")
	string sPluginProject = COMBI_GetGlobalString("sPluginProject", "COMBIgor")
	execute sPluginName+"_Load()"
end

function COMBI_DefinePluginButton(sControl): ButtonControl
	string sControl//window name (to get Plugin name)
	string sPluginName = COMBI_GetGlobalString("sPluginName", "COMBIgor")
	string sPluginProject = COMBI_GetGlobalString("sPluginProject", "COMBIgor")
	execute sPluginName+"_Define()"
end

function/S COMBI_ChoosePluginName()
	string sActivePlugins = COMBI_ActivePluginList("Plugins")
	string sTheChoosenOne = COMBI_StringPrompt("","Choose Plugin",sActivePlugins,"Select which Plugin to use","Select Instrument")
	COMBI_GiveGlobal("sPluginName",sTheChoosenOne,"COMBIgor")
	return sTheChoosenOne
end

function/S COMBI_ChoosePluginProject()
	string sTheChoosenOne = COMBI_ChooseProject()
	COMBI_GiveGlobal("sPluginProject",sTheChoosenOne,"COMBIgor")
	return sTheChoosenOne
end

