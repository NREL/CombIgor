#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// This file is designed to initialize COMBIgor in Igor 7
// Version History
// V1: Kevin Talley _ May 2018 : COMBIgor_2.0 Original
// V1: Kevin Talley _ Nov 2018 : COMBIgor_2.0 
// V1: Kevin Talley _ Nov 2018 : COMBIgor_2.1 

// Description of functions within:
// COMBI : Initialize COMBIgor

Static StrConstant ksCOMBIgorVersion = "2"

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below  ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Initialize COMBIgor.
function COMBI()

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//make folder directories
	setdatafolder root: 
	newdatafolder/O COMBIgor
	newdatafolder/S/O Packages
	newdatafolder/S/O COMBIgor
	newdatafolder/O Plugins
	newdatafolder/O Instruments
	
	//Check if existed previously
	if(itemsinlist(Wavelist("twCOMBI_Globals",";",""))>0)
		
		DoAlert/T="COMBIgor error" 0,"COMBIgor already initialized."
		
		//return to user folder
		SetDataFolder $sTheCurrentUserFolder 
		return-1

	endif
	
	//get the operating system
	string sPresetFont
	string sOperatingSystem = IgorInfo(2)
	if(stringmatch(sOperatingSystem,"Windows"))
		sPresetFont = GetDefaultFont("")
	elseif(stringmatch(sOperatingSystem,"Macintosh"))
		sPresetFont = "System Font"
	endif
	
	//make globals text wave twCOMBI_Globals[][] and twCOMBI_PluginGlobals[][]
	if(!waveexists(root:Packages:COMBIgor:COMBI_Globals))
		Make/T/N=(1,2) COMBI_Globals
	endif
	if(!waveexists(root:Packages:COMBIgor:COMBI_DisplayGlobals))
		Make/T/N=(1,2) COMBI_DisplayGlobals
	endif
	wave twGlobals = root:Packages:COMBIgor:COMBI_Globals
	wave twDisplayGlobals = root:Packages:COMBIgor:COMBI_DisplayGlobals
	
	//set general dim labels
	setdimlabel 0,-1,Globals,twGlobals
	setdimlabel 1,-1,Folder,twGlobals
	setdimlabel 0,-1,Globals,twDisplayGlobals
	setdimlabel 1,-1,Folder,twDisplayGlobals
	
	//set layer 1 to the main COMBIgor Label
	setdimlabel 1,1,COMBIgor,twGlobals
	setdimlabel 1,1,COMBIgor,twDisplayGlobals
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder 

	COMBI_GiveGlobal("sActiveFolder","None","COMBIgor")	
	COMBI_GiveGlobal("sExportOption","None","COMBIgor")
	COMBI_GiveGlobal("sDataOption","None","COMBIgor")
	COMBI_GiveGlobal("sImportOption","None","COMBIgor")
	COMBI_GiveGlobal("sFontOption",sPresetFont,"COMBIgor")
	COMBI_GiveGlobal("sBoldOption","No","COMBIgor")
	COMBI_GiveGlobal("sColorOption","Rainbow","COMBIgor")
	COMBI_GiveGlobal("vKillOption","1","COMBIgor")
	COMBI_GiveGlobal("sCommandLines","Yes","COMBIgor")
	COMBI_GiveGlobal("bAllAddOns","0","COMBIgor")
	COMBI_GiveGlobal("bAllPluginss","0","COMBIgor")
	COMBI_GiveGlobal("bAllInstruments","0","COMBIgor")
	COMBI_GiveGlobal("sPlotOnLoad","Yes","COMBIgor")
	COMBI_GiveGlobal("vCOMBIgorVersion",ksCOMBIgorVersion,"COMBIgor")	

	DoAlert/T="COMBIgor Loaded" 0,"COMBIgor initialized! Let's do science!"
	
	//get and store folder path
	string sCombipath =COMBI_GetCOMBIgorFolder()
	
	//open help files
	newpath/Q/O/Z pHelpPath sCombipath+"Help:"
	OpenHelp/P=pHelpPath/V=0 "COMBIgor_Help.ihf"
	OpenHelp/P=pHelpPath/V=0 "COMBIgor_Tutorial.ihf"
	OpenHelp/P=pHelpPath/V=0 "COMBIgor_Developer.ihf"
	
	Killpath pHelpPath
	
	//load logo
	SetDataFolder root:Packages:COMBIgor:
	ImageLoad/T=PNG/Q/N=COMBIgor_Logo sCombipath+"COMBIgor_Logo.png"
	SetDataFolder root:
		
	COMBI_ActivateAddon()
	
	setdatafolder $sTheCurrentUserFolder
	
end


function COMBI_ActivateAddon()

	// check that combigor is initialized
	COMBI_COMBIgorCheck()
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	
 	// select file path containing loader procedures if there is none stored
 	string sCOMBIgorFolderPath = COMBI_GetGlobalString("sCOMBIgorFolderPath","COMBIgor")
 		
	newpath/Q/O/Z pPluginPath sCOMBIgorFolderPath+"Plugins:"
	newpath/Q/O/Z pInstrumentPath sCOMBIgorFolderPath+"Instruments:"
		
	string sPluginFileList= indexedfile(pPluginPath,-1,".ipf")
	string sInstrumentFileList= indexedfile(pInstrumentPath,-1,".ipf")
	int vTotalPlugins = itemsinlist(sPluginFileList)
	int vTotalInstruments = itemsinlist(sInstrumentFileList)
	int vTotal = (vTotalPlugins+vTotalInstruments)
 	int iIndex, iColLen=25
	variable vPanelWidth, vPanelHeight
	
	// get panel dimensions based on string list size
	vPanelWidth = 250
	vPanelHeight = 210+20*vTotal
	
	// make panel
	string sFont = Combi_GetGlobalString("sFontOption", "COMBIgor")
	Killwindow/Z AddonSelector
	NewPanel/K=1/W=(50,50,vPanelWidth,vPanelHeight)/N=AddonSelector as "Add-ons Selector"
	ModifyPanel/W=AddonSelector cbRGB=(50000,50000,50000),fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv textxjust = 0,textyjust= 2
	SetDrawEnv fillpat = 0
	SetDrawEnv fsize = 12
	SetDrawEnv fstyle = 1
	SetDrawEnv fname=sFont
	SetDrawEnv save
	
	//add logo
	wave wLogoWave = root:Packages:COMBIgor:COMBIgor_Logo
	NewImage/HOST=AddonSelector/N=Logo wLogoWave
	ModifyGraph/W=AddonSelector#Logo margin=1,width=250,mirror=0,axRGB=(50000,50000,50000,0),gbRGB=(50000,50000,50000),wbRGB=(50000,50000,50000)
	
	SetActiveSubwindow AddonSelector
	
	variable vYCoord=60, vXCoord=10
	variable vPreviousValue = COMBI_GetGlobalNumber("bAllAddOns","COMBIgor")
	CheckBox bAllAddOns,pos={vXCoord,vYCoord-5},size={61,14},title="All Add-ons",value=vPreviousValue,proc=COMBI_UpdatePluginList,fSize=12,fstyle=2
	vYCoord += 20
	
	SetDrawEnv fstyle = 1; SetDrawEnv save; DrawText vXCoord,vYCoord-4,"Active Plugins:"; SetDrawEnv fstyle = 0; SetDrawEnv save
	vYCoord += 20
	string sThisFileName, sThisPluginName, sThisInstrumentName
	vPreviousValue = COMBI_GetGlobalNumber("bAllPlugins","COMBIgor")
	CheckBox bAllPlugins,pos={vXCoord,vYCoord-5},size={61,14},title="All Plugins",value=vPreviousValue,proc=COMBI_UpdatePluginList,fSize=12,fstyle=2
	vYCoord += 20
	
	for(iIndex=0;iIndex<vTotalPlugins;iIndex+=1)
		sThisPluginName = removeending(stringfromlist(iIndex,sPluginFileList),".ipf")[6,inf]
		// get current status of this Plugin
		vPreviousValue = COMBI_CheckForPlugin(sThisPluginName)
		CheckBox $sThisPluginName,pos={vXCoord,vYCoord-5},size={61,14},title=sThisPluginName,value=vPreviousValue,proc=COMBI_UpdatePluginList,fSize=12
		vYCoord += 20
	endfor
	
	SetDrawEnv fstyle = 1; SetDrawEnv save; DrawText vXCoord,vYCoord-4,"Active Instruments:"; SetDrawEnv fstyle = 0; SetDrawEnv save
	vYCoord += 20
	vPreviousValue = COMBI_GetGlobalNumber("bAllInstruments","COMBIgor")
	CheckBox bAllInstruments,pos={vXCoord,vYCoord-5},size={61,14},title="All Instruments",value=vPreviousValue,proc=COMBI_UpdateInstrumentList,fSize=12,fstyle=2
	vYCoord += 20
	for(iIndex=0;iIndex<vTotalInstruments;iIndex+=1)
		sThisInstrumentName = removeending(stringfromlist(iIndex,sInstrumentFileList),".ipf")[6,inf]
		// get current status of this Plugin
		vPreviousValue = COMBI_CheckForInstrument(sThisInstrumentName)
		CheckBox $sThisInstrumentName,pos={vXCoord,vYCoord-5},size={61,14},title=sThisInstrumentName,value=vPreviousValue,proc=COMBI_UpdateInstrumentList,fSize=12
		vYCoord += 20
	endfor
	
	BuildMenu "COMBIgor"	
	killpath/A
	SetDataFolder $sTheCurrentUserFolder 
	
end

function COMBI_KillAllAddOns()
	string sPluginList = COMBI_ActivePluginList("Plugins")
	string sInstList = COMBI_ActiveInstrumentList("Instruments")
	int iPlugin,vPlugins = itemsinList(sPluginList)
	int iInst,vInsts = itemsinList(sInstList)
	
	for(iPlugin=0;iPlugin<vPlugins;iPlugin+=1)
		COMBI_KillPlugin(stringfromlist(iPlugin,sPluginList))
	endfor
	for(iInst=0;iInst<vInsts;iInst+=1)
		COMBI_KillInstrument(stringfromlist(iInst,sInstList))
	endfor
end

Function/S COMBI_GetCOMBIgorFolder()
	string sLoadPath = SpecialDirPath("Igor Pro User Files",0,0,0)+"User Procedures:"
	NewPath/Z/Q/O pUserPath, sLoadPath
	
	//get COMBIgor files if alias with COMBIgor in the name exists in the User procedures folder
	String sFolderList = IndexedFile(pUserPath, -1,"????")
	int vTotalThings = itemsinlist(sFolderList), iThisThing,  iTheCOMBIgorFolder = -1
	for(iThisThing=0;iThisThing<vTotalThings;iThisThing+=1)
		if(stringmatch(stringfromlist(iThisThing,sFolderList),"*Combigor*"))
			GetFileFolderInfo/P=pUserPath/Q stringfromlist(iThisThing,sFolderList)
			If(V_isAliasShortcut==1)
				sLoadPath = S_aliasPath
				iTheCOMBIgorFolder = iThisThing
			endif
		endif
	endfor
	
	//get folders if not alias, and a folder exist with COMBIgor in the name in the User procedures folder 
	if(iTheCOMBIgorFolder==-1)
		sFolderList = IndexedDir(pUserPath, -1,0)
		vTotalThings = itemsinlist(sFolderList)
		for(iThisThing=0;iThisThing<vTotalThings;iThisThing+=1)
			if(stringmatch(stringfromlist(iThisThing,sFolderList),"*Combigor*"))
				iTheCOMBIgorFolder = iThisThing
				sLoadPath = sLoadPath+stringfromlist(iTheCOMBIgorFolder,sFolderList)+":"
			endif
		endfor
	endif
	
	//check it was found by looking for COMBIgor.ipf inside.
	if(iTheCOMBIgorFolder!=-1)
		NewPath/Z/Q/O pTestPath, sLoadPath
		string sAllProcedures = IndexedFile(pTestPath, -1, ".ipf")
		if(whichlistitem("COMBIgor.ipf",sAllProcedures)==-1)
			iTheCOMBIgorFolder=-1
		endif
	endif
	
	
	//prompt if it was never found
	if(iTheCOMBIgorFolder==-1)
		DoAlert/T="COMBIgor input needed." 0,"Select directory containing COMBIgor procedures"
		Pathinfo/S pUserPath //direct to user folder
	 	newpath/Q/Z/O pPathName
	 	if (V_Flag)
	 		DoAlert/T="COMBIgor input needed." 0,"Please specify a folder location and initialize COMBIgor again."
			return "" // User canceled
		endif
	 	Pathinfo pPathName
	 	sLoadPath = S_path
	endif
	
	COMBI_GiveGlobal("sCOMBIgorFolderPath",sLoadPath,"COMBIgor")
	killpath/Z pUserPath
	killpath/Z pTestPath
	return sLoadPath
	
end

//NOTE:
//if you change COMBI_Update you must also change COMBI_ImportPreviousVersion2OrMore()
//to handle any changes from previous versions!
function COMBI_Update()
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	string sTheCurrentVersion = Combi_GetGlobalString("vCOMBIgorVersion", "COMBIgor")
	string sThisVersion = ksCOMBIgorVersion
	
	
	if(!stringmatch(sTheCurrentVersion,sThisVersion))
		string sIPFFolder = COMBI_GetCOMBIgorFolder()
		//go from 2.0 to 2.1
		if(stringmatch(sTheCurrentVersion,"2.0"))
			//change the folder for Plugins 
			setdatafolder root:Packages:COMBIgor:
			RenameDataFolder Gadgets,Plugins
			SetDataFolder $sTheCurrentUserFolder 
			//change global names from "Gadget to Plugin"
			wave/T wGlobals = root:Packages:COMBIgor:COMBI_Globals
			int iGlobal
			for(iGlobal=1;iGlobal<dimsize(wGlobals,0);iGlobal+=1)
				string sThisGlobalName = GetDimLabel(wGlobals,0,iGlobal)
				if(stringmatch(sThisGlobalName,"*Gadget*"))
					sThisGlobalName = replaceString("Gadget",sThisGlobalName,"Plugin")
					setdimLabel 0,iGLobal,$sThisGlobalName,wGlobals
				endif
			endfor
			//change plugin globals tables that might exist
			if(waveexists($"root:Packages:COMBIgor:Plugins:COMBI_FilterGadget_Globals"))
				rename $"root:Packages:COMBIgor:Plugins:COMBI_FilterGadget_Globals", COMBI_FilterPlugin_Globals
			endif
			if(waveexists($"root:Packages:COMBIgor:Plugins:COMBI_MathGadget_Globals"))
				rename $"root:Packages:COMBIgor:Plugins:COMBI_MathGadget_Globals", COMBI_MathPlugin_Globals
			endif
			//reload procedure files with new names
			Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Gadgets\""
			Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Plugins\""
			//success
			sTheCurrentVersion = "2.1"
			Print "Updated to COMBIgor 2.1"	
		endif
		//go from 2.1 to 2.2
		if(stringmatch(sTheCurrentVersion,"2.1"))
			//add sPlotOnLoad global
			Combi_GiveGlobal("sPlotOnLoad","Yes","COMBIgor")
			sTheCurrentVersion = "2.2"
			//add display globals
			COMBIDisplay_Global("sLibraryFilter","","COMBIgor")
			COMBIDisplay_Global("sDataTypeFilter","","COMBIgor")
			COMBIDisplay_Global("sMCMin","*","COMBIgor")
			COMBIDisplay_Global("sMCMax","*","COMBIgor")
			COMBIDisplay_Global("sMSMin","*","COMBIgor")
			COMBIDisplay_Global("sMSMax","*","COMBIgor")
			COMBIDisplay_Global("bMRange","0","COMBIgor")
			COMBIDisplay_Global("bMDeviation","0","COMBIgor")
			COMBIDisplay_Global("bMMax","0","COMBIgor")
			COMBIDisplay_Global("bMMin","0","COMBIgor")
			COMBIDisplay_Global("bMMean","0","COMBIgor")
			COMBIDisplay_Global("bMMedian","0","COMBIgor")
			COMBIDisplay_Global("bMNumbers","0","COMBIgor")
			COMBIDisplay_Global("sMStyle","Markers","COMBIgor")
			COMBIDisplay_Global("sMFitOption","None","COMBIgor")
			COMBIDisplay_Global("bMSaveStats","0","COMBIgor")
			Print "Updated to COMBIgor 2.2"
		endif
		//go from 2.2 to 2.3
		if(stringmatch(sTheCurrentVersion,"2.2"))
			//change "AllLibraries" to "FromMappingGrid"
			//loop all projects
			string sAllProjects = COMBI_Projects()
			int iProject
			for(iProject=0;iProject<itemsinlist(sAllProjects);iProject+=1)
				string sThisProject = stringfromlist(iProject,sAllProjects)
				//change folder name
				RenameDataFolder $"root:COMBIgor:"+sThisProject+":Data:AllLibraries", FromMappingGrid
			endfor
			sTheCurrentVersion = "2.3"
			Print "Updated to COMBIgor 2.3"
		endif
		//go from 2.3 to 2.4
		if(stringmatch(sTheCurrentVersion,"2.3"))
			//load the logo wave
			string sCombipath = Combi_GetGlobalString("sCOMBIgorFolderPath", "COMBIgor")
			SetDataFolder root:Packages:COMBIgor:
			ImageLoad/T=PNG/Q/N=COMBIgor_Logo sCombipath+"Logo.png"
			sTheCurrentVersion = "2.4"
			Print "Updated to COMBIgor 2.4"
		endif
		//go from 2.4 to 2.5
		if(stringmatch(sTheCurrentVersion,"2.4"))
			sTheCurrentVersion = "2.5"
			Print "Updated to COMBIgor 2.5"
		endif
		//go from 2.5...
	endif
	COMBI_GiveGlobal("vCOMBIgorVersion",sTheCurrentVersion,"COMBIgor")
	Print "Current Version: "+sTheCurrentVersion
	setdatafolder sTheCurrentUserFolder
end

function COMBI_ImportPreviousVersion2OrMore()
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//load experiment as folder and analyze which one is new
	string sRootFoldersBefore = stringbyKey("FOLDERS",DataFolderDir(-1))
	LoadData/O/L=7/Q/R/T
	string sRootFoldersAfter = stringbyKey("FOLDERS",DataFolderDir(-1))
	variable vTotalFolders = itemsinlist(sRootFoldersAfter,","), iFolder
	string sNewFolder = ""
	for(iFolder=0;iFolder<vTotalFolders;iFolder+=1)
		string sThisFolder = stringfromList(iFolder,sRootFoldersAfter,",")
		variable vMatching = itemsinlist(Listmatch(sRootFoldersBefore,sThisFolder,","))
		if(vMatching==0)
			sNewFolder = sThisFolder
		endif
	endfor
	sNewFolder = "'"+sNewFolder+"'"
	
	int iProject
	//check version
	wave/T wOldGlobals = $"root:"+sNewFolder+":Packages:COMBIgor:COMBI_Globals"
	string sThisVersion = wOldGlobals[%vCOMBIgorVersion][%COMBIgor]
	
	//get current globals
	wave/T ThisGlobals = root:Packages:COMBIgor:COMBI_Globals
	
	//go from 2.0 to 2.1
	if(stringmatch(sThisVersion,"2.0"))
			//change the folder for Plugins 
			setdatafolder $"root:"+sNewFolder+":Packages:COMBIgor:"
			RenameDataFolder Gadgets,Plugins
			SetDataFolder $sTheCurrentUserFolder
			
			//change global names from "Gadget to Plugin"
			int iGlobal
			for(iGlobal=1;iGlobal<dimsize(wOldGlobals,0);iGlobal+=1)
				string sThisGlobalName = GetDimLabel(wOldGlobals,0,iGlobal)
				if(stringmatch(sThisGlobalName,"*Gadget*"))
					sThisGlobalName = replaceString("Gadget",sThisGlobalName,"Plugin")
					setdimLabel 0,iGLobal,$sThisGlobalName,wOldGlobals
				endif
			endfor	
	endif
	
	//go from 2.1 to 2.2
	if(stringmatch(sThisVersion,"2.1"))
		// add sPlotOnLoad global - not needed as the current combigor already has it.
		sThisVersion = "2.2"
	endif
	//go from 2.2 to 2.3
	if(stringmatch(sThisVersion,"2.2"))
		//loop new projects
		for(iProject=2;iProject<dimsize(wOldGlobals,1);iProject+=1)
			string sNameOfProject = getdimLabel(wOldGlobals,1,iProject)
			RenameDataFolder $"root:"+sNewFolder+":COMBIgor:"+sNameOfProject+":Data:AllLibraries",FromMappingGrid
		endfor
		sThisVersion = "2.3"
		Print "Updated to COMBIgor 2.3"
	endif
	
	//transfer project level globals
	for(iGlobal=1;iGlobal<dimsize(wOldGlobals,0);iGlobal+=1)
		sThisGlobalName = GetDimLabel(wOldGlobals,0,iGlobal)
		for(iProject=2;iProject<dimsize(wOldGlobals,1);iProject+=1)
			string sThisOldProject = GetDimLabel(wOldGlobals,1,iProject)
				COMBI_GiveGlobal(sThisGlobalName,wOldGlobals[%$sThisGlobalName][%$sThisOldProject],sThisOldProject)
		endfor
	endfor
	
	//move project folders
	for(iProject=2;iProject<dimsize(wOldGlobals,1);iProject+=1)
		moveDataFolder/Z/O=3 $"root:"+sNewFolder+":COMBIgor:", root:
	endfor
	
	//move anthything else in projects
	setdatafolder $"root:"+sNewFolder+":Packages:"
	string sExtraPackages = ReplaceString(",", stringbyKey("FOLDERS",DataFolderDir(-1)),";")
	SetDataFolder $sTheCurrentUserFolder
	for(iProject=0;iProject<itemsinlist(sExtraPackages);iProject+=1)
		if(!stringmatch(stringfromList(iProject,sExtraPackages),"COMBIgor"))
			moveDataFolder/Z/O=3 $"root:"+sNewFolder+":Packages:"+stringfromList(iProject,sExtraPackages), root:Packages:
		endif
	endfor
	
	//move anything else in root:
	setdatafolder $"root:"+sNewFolder+":"
	string sExtraRootFolders = ReplaceString(",", stringbyKey("FOLDERS",DataFolderDir(-1)),";")
	SetDataFolder $sTheCurrentUserFolder
	for(iProject=0;iProject<itemsinlist(sExtraRootFolders);iProject+=1)
		if(!stringmatch(stringfromList(iProject,sExtraRootFolders),"Packages"))
			moveDataFolder/Z/O=3 $"root:"+sNewFolder+":"+stringfromList(iProject,sExtraRootFolders), root:
		endif
	endfor
	
	//delete packages 
	KilldataFolder/Z $"root:"+sNewFolder
	
end

//Functions to add to the wave Combi__Globals, returns a 0 for new variable, or 1 for same as previous, or 2 for value change
//user passes the name and value of the Global
function Combi_GiveGlobal(sGlobal,sValue,sFolder)
	string sGlobal // global variable name
	string sValue // global variable value
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get Combi__Globals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:Combi_Globals
	
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
		//return a 1 or 2 depending on previous value 
		if(stringmatch(sValue,sOldValue))
			return 1
		else
			return 2
		endif
	endif
	
	//if it is new
	if(Finddimlabel(twGlobals,0,sGlobal)==-2)
		//increase number of rows
		variable vPreviousSize = dimsize(twGlobals,0)
		redimension/N=(vPreviousSize+1,-1) twGlobals
		//label dimension
		setdimlabel 0,vPreviousSize,$sGlobal,twGlobals
		twGlobals[vPreviousSize][%$sFolder] = sValue
		//return a zero
		return 0
	endif
	
end

//Functions to read global in Combi_Globals, returns the value  "NAG" if Not A Global
function/S Combi_GetGlobalString(sGlobal2Read, sFolder)
	string sGlobal2Read // global of interst
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get Combi_Globals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:Combi_Globals
	
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return "NAG"
	endif
	
	//return value
	return twGlobals[%$sGlobal2Read][%$sFolder]
end

//Functions to read global in Combi_Globals, returns the value  "nan" if Not A Global
function Combi_GetGlobalNumber(sGlobal2Read, sFolder)
	string sGlobal2Read // global of interst
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get Combi_Globals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:Combi_Globals
	
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return nan
	endif
	
	//return value
	return str2num(twGlobals[%$sGlobal2Read][%$sFolder])
end

//function to check if COMBIgor is initialized, if not then initializes
function Combi_COMBIgorCheck()
	//check if initialized 
	if(!DataFolderExists("root:Packages:COMBIgor"))
		Combi()
	endif
end


//Making a new project, returns zero if already made does not overwrite
function Combi_StartNewProject()

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 

	//make a thing to prompt for, and give some initial value
	string sProjectName = "MyProject"

	// make prompts with descriptors 
	prompt sProjectName, "Project Name:"	
	
	//Prompt user for project basics
	DoPrompt "Define a new project", sProjectName
	if (V_Flag)
		return -1// User canceled
	endif
	
	sProjectName = CleanupName(sProjectName, 0)
	
	//check if initialized 
	if(!DataFolderExists("root:Packages:COMBIgor"))
		Combi()
	endif
	
	setdatafolder root: 
	SetDataFolder COMBIgor
	
	//exit if wave exists, return 0
	if(DataFolderExists("root:COMBIgor:"+sProjectName))
		DoAlert/T="COMBIgor error" 0,"That is already a project."
		SetDataFolder $sTheCurrentUserFolder 
		return 0
	endif
	
	//store this active folder
	Combi_GiveGlobal("sActiveFolder",sProjectName,"COMBIgor")
	Combi_GiveGlobal("sActiveFolder",sProjectName,sProjectName)
	
	//make folder 
	NewDataFolder/O/S $sProjectName
	NewDataFolder/O/S Data
	
	//make master 0D,1D, and 2D main waves
	Combi_NewMetaTable("Meta")
	Make/N=(1,1)/O Library
	
	SetDimLabel 0,-1,Samples,$COMBI_DataPath(sProjectName,0)
	SetDimLabel 1,-1,DataType,$COMBI_DataPath(sProjectName,0)
	Combi_NewDataLog("LogBook")
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
	//define the Library space
	Combi_DefineMappingGrid(sProjectName)
	
end
