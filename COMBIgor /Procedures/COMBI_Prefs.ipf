#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ May 2018 : Original

//Description of functions within:
//C_DefineAutoFunctions

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//function to define the auto functionality option globals.
function COMBI_DefineAutoFunctions()

	//check if initialized 
	if(!DataFolderExists("root:Packages:COMBIgor"))
		COMBI()
	endif

	//make things to prompt for
	string sOptionExport = COMBI_GetGlobalString("sExportOption","COMBIgor")
	if(stringmatch(sOptionExport,"Export Folder"))
		sOptionExport  = "No Change"
	endif
	string sOptionImport = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch(sOptionImport,"Import Folder"))
		sOptionImport = "No Change"
	endif
	int vKillOption = COMBI_GetGlobalNumber("vKillOption","COMBIgor")
	string sOptionSave
	if(vKillOption==1)
		sOptionSave = "No Save Option"
	elseif(vKillOption==0)
		sOptionSave = "Save Option"
	endif
	string sCommandLines = COMBI_GetGlobalString("sCommandLines","COMBIgor")
	string sPlotOnLoad = COMBI_GetGlobalString("sPlotOnLoad","COMBIgor")
	if(stringmatch(sPlotOnLoad,"NAG"))
		sPlotOnLoad = "No"
	endif
	
	// make prompts with descriptors 
	prompt sOptionExport, "Export Option:", POPUP, "None;Export Folder;No Change"
	prompt sOptionImport, "Import Option:", POPUP, "None;Import Folder;No Change"
	prompt sOptionSave, "Window Kill Behavior:", POPUP, "Save Option;No Save Option"
	prompt sCommandLines, "Print call lines?:", POPUP, "Yes;No"
	prompt sPlotOnLoad, "Plot data upon loading?:", POPUP, "Yes;No"
	
	//Prompt user
	DoPrompt "How can I help you?", sOptionImport, sOptionExport, sOptionSave,sCommandLines, sPlotOnLoad
	if (V_Flag)
		return -1// User canceled
	endif
	
	//store prefs
	if(!stringmatch(sOptionExport,"No change"))
		COMBI_GiveGlobal("sExportOption",sOptionExport,"COMBIgor")
	endif
	if(!stringmatch(sOptionImport,"No change"))
		COMBI_GiveGlobal("sImportOption",sOptionImport,"COMBIgor")
	endif

	COMBI_GiveGlobal("sCommandLines",sCommandLines,"COMBIgor")
	COMBI_GiveGlobal("sPlotOnLoad",sPlotOnLoad,"COMBIgor")
	
	if(stringmatch(sOptionSave,"Save Option"))
		COMBI_GiveGlobal("vKillOption","0","COMBIgor")
	endif
	if(stringmatch(sOptionSave,"No Save Option"))
		COMBI_GiveGlobal("vKillOption","1","COMBIgor")
	endif
	
	//set paths
	if(stringmatch(sOptionExport,"Export Folder"))
		COMBI_ExportPath("New")
	endif
	if(stringmatch(sOptionImport,"Import Folder"))
		COMBI_ImportPath("New")
	endif
	
end

//function to define the style preferences for plotting.
function COMBI_DefineStylePref()

	//check if initialized 
	if(!DataFolderExists("root:Packages:COMBIgor"))
		COMBI()
	endif

	//make things to prompt for
	string sOptionFont
	string sOptionBold
	string sOptionColor
	
	// make prompts with descriptors 
	prompt sOptionFont, "Font Choice:", POPUP, FontList(";")
	prompt sOptionBold, "Bold:", POPUP, "Yes;No" 
	prompt sOptionColor "Color Theme Default:", POPUP, CTabList()
	
	//Prompt user
	DoPrompt "Select your preferences", sOptionFont, sOptionBold, sOptionColor
	if (V_Flag)
		return -1// User canceled
	endif
	
	//store prefs
	COMBI_GiveGlobal("sFontOption",sOptionFont,"COMBIgor")
	COMBI_GiveGlobal("sBoldOption",sOptionBold,"COMBIgor")
	COMBI_GiveGlobal("sColorOption",sOptionColor,"COMBIgor")
	
	
end