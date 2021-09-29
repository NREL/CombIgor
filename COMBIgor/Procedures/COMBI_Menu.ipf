#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ May 2018 : Original, Main COMBI Menu, Procedures, Auto Options
// V1.1: Sage Bauers _ 20180514 : Build dynamic Plugin menu, add executeChosenMenuItem
// V1.11: Karen Heinselman _ Oct 2018 : Polishing and debugging

//Description of functions within:
// # include statements for including procedure files
// Build COMBI Menu
// executeChosenMenuItem : Calls Plugin procedure from dropdown

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Build Menu Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//COMBI Drop Down Menu
Menu "COMBIgor", dynamic
	//Set user Preferences
	SubMenu "Preferences"
		"Add-ons",/Q, COMBI_ActivateAddon()
		"Auto Options",/Q, COMBI_DefineAutoFunctions()
		"Plot Styling",/Q, COMBI_DefineStylePref()
	End
	//project level commands
	SubMenu "Projects"
		"(See Data"
		submenu "Project"
			submenu "Mapping Grid"
				COMBI_ProjectMenu("Project"),/Q,COMBI_ShowMappingGrid()
			end
			submenu "Library Data"
				COMBI_ProjectMenu("Project"),/Q,COMBI_ShowLibraryTable()
			end
			COMBI_ProjectMenu("Project"),/Q,COMBI_ShowProject()
		end
		submenu "Libraries"
			COMBI_ProjectMenu("Library"),/Q,COMBI_ShowLibrary()
		end
		submenu "Data Types"
			submenu "Meta Data"
				COMBI_ProjectMenu("Project"),/Q,COMBI_ShowMetaTable()
			end
			submenu "Scalar"
				COMBI_ProjectMenu("ScalarType"),/Q,COMBI_ShowDataType()
			end
			submenu "Vector"
				COMBI_ProjectMenu("VectorType"),/Q,COMBI_ShowDataType()
			end
			submenu "Matrix"
				COMBI_ProjectMenu("MatrixType"),/Q,COMBI_ShowDataType()
			end
		end
		"-"
		"(New Data"
		"New Project",/Q, COMBI_StartNewProject()
		"New Library",/Q, Combi_AddNewEntryFromMenu("Library")
		"New Data Type",/Q, Combi_AddNewEntryFromMenu("DataType")
		"Interpolate Project-2-Project",/Q, COMBI_Project2ProjectScalarInterp()
		"-"
		"(Importing Experiments (*.pxp)"
		"Import V2+",/Q, COMBI_ImportPreviousVersion2OrMore()
		"Import V1",/Q, COMBI_GetV1Data()
		"-"
		"(COMBIgor Data (*.txt)"
		submenu 	"Import Data"
			"Single File",/Q,COMBI_LoadCOMBIgorData(COMBI_ChooseProject(),"File")
			"Single Folder",/Q,COMBI_LoadCOMBIgorData(COMBI_ChooseProject(),"Folder")
			"Project Folder",/Q,COMBI_LoadCOMBIgorData(COMBI_ChooseProject(),"Project Folder")
		end
		"Export Data",/Q, COMBI_ExportCOMBIgorData()
		"-"
	End
	//Plugin level commands
	SubMenu "Plugins"
		//plugins will add to it on their own. See COMBI_ExamplePlugin.ipf
	End
	SubMenu "Instruments"
		//instruments will add to it on their own. See COMBI_Example.ipf
	End
	SubMenu "Data Log"
		"Make Note",/Q, COMBI_UserLogEntry()
		"Search",/Q, COMBI_SearchLogBook()
	End
	//graphics level commands
	SubMenu "Visualize"
		"Display",/Q, COMBIDisplay()
		SubMenu "Utilities"
			"Offset Plot Trace(s)",/Q, COMBI_OffsetTraces()
			"Color Plot Traces",/Q, COMBI_ColorTracesSelect("Choose") 
		End
	End
	//help
	SubMenu "Help"
		"General",/Q, COMBI_Help()
		"-"
		"Getting Started",/Q, COMBI_Help()
		"Tutorial",/Q, COMBI_Help()
		"-"
		"Instruments",/Q, COMBI_Help()
		"Plugins",/Q, COMBI_Help()
		"-"
		"Programming",/Q, COMBI_Help()
		"Make Example COMBIgor Data",/Q,COMBI_MakeExamplePreferredOUT(COMBI_ChooseProject())
		"-"
		"Update",/Q, COMBI_Update()
		"-"
		"Force compile",/Q, CompileCOMBIgor()
		"-"
		"www.COMBIgor.com",/Q, COMBI_GoToWebsite()
	End

End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// determine last menu item selected, build and run that function
function COMBI_StartPlugin()
	GetLastUserMenuInfo
	string sMenuItem = ReplaceString(" ", S_value, "")
	Execute/Q "COMBI_"+sMenuItem+"()"
End

function COMBI_Help()
	
	GetLastUserMenuInfo
	string sMenuItem = S_value
	
	if(stringmatch(sMenuItem,"General"))
		DisplayHelpTopic "COMBIgor"
	elseif(stringmatch(sMenuItem,"Instruments"))
		DisplayHelpTopic "Instruments for COMBIgor"
	elseif(stringmatch(sMenuItem,"Plugins"))
		DisplayHelpTopic "Plugins for COMBIgor"
	elseif(stringmatch(sMenuItem,"Programming"))
		DisplayHelpTopic "Programming COMBIgor"
	elseif(stringmatch(sMenuItem,"Getting Started"))
		DisplayHelpTopic "Getting started with COMBIgor"
	elseif(stringmatch(sMenuItem,"Tutorial"))
		DisplayHelpTopic "A brief COMBIgor tutorial"
	endif
	
end


function/S COMBI_ProjectMenu(sType)
	string sType//Project,Library or DataType
	if(stringmatch(sType,"Library"))
		return Combi_TableList("AllCOMBIgor",-3,"All","Libraries")
	elseif(stringmatch(sType,"ScalarType"))
		return Combi_TableList("AllCOMBIgor",1,"All","DataTypes")
	elseif(stringmatch(sType,"VectorType"))
		return Combi_TableList("AllCOMBIgor",2,"All","DataTypes")
	elseif(stringmatch(sType,"MatrixType"))
		return Combi_TableList("AllCOMBIgor",3,"All","DataTypes")
	elseif(stringmatch(sType,"Project"))
		return COMBI_Projects()
	endif
end

function COMBI_ShowProject()
	GetLastUserMenuInfo	
	CreateBrowser
	ModifyBrowser setDataFolder="root:COMBIgor:"+S_value
	ModifyBrowser expandAll
end

function COMBI_ShowLibrary()
	GetLastUserMenuInfo	
	CreateBrowser
	ModifyBrowser select=S_value
end

function COMBI_ShowDataType()
	GetLastUserMenuInfo	
	CreateBrowser
	ModifyBrowser select=S_value
end

function COMBI_ShowMappingGrid()
	GetLastUserMenuInfo	
	string sProject = S_value
	CreateBrowser
	ModifyBrowser setDataFolder="root:COMBIgor:"+sProject
	ModifyBrowser select="MappingGrid"
	wave wGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	KillWindow/Z $sProject+"MappingGrid"
	KillWindow/Z $"Sample_Map_For_"+sProject
	Edit/K=1/N=$sProject+"MappingGrid" wGrid.ld as sProject+" Mapping Grid"
//	string sGA1 = getdimLabel(wGrid,1,3)
//	string sGA2 = getdimLabel(wGrid,1,4)
//	COMBIDisplay_Map(sProject,"FromMappingGrid","Sample","Linear","Rainbow"," ","Linear","y(mm) vs x(mm)",16)
//	DoWindow/C $"Sample_Map_For_"+sProject
//	COMBIDisplay_Map(sProject,"FromMappingGrid",sGA1,"Linear","Rainbow"," ","Linear","y(mm) vs x(mm)",16)
//	DoWindow/C $sGA1+"_Map_For_"+sProject
//	COMBIDisplay_Map(sProject,"FromMappingGrid",sGA2,"Linear","Rainbow"," ","Linear","y(mm) vs x(mm)",16)
//	DoWindow/C $sGA2+"_Map_For_"+sProject
	
	COMBI_MappingGridPlot(sProject)
	
end

function COMBI_ShowLibraryTable()
	GetLastUserMenuInfo	
	string sProject = S_value
	CreateBrowser
	ModifyBrowser setDataFolder="root:COMBIgor:"+sProject
	ModifyBrowser select="Library"
	Combi_SeeLibraryTable(sProject)
end

function COMBI_ShowMetaTable()
	GetLastUserMenuInfo	
	string sProject = S_value
	CreateBrowser
	ModifyBrowser setDataFolder="root:COMBIgor:"+sProject
	ModifyBrowser select="Meta"
	Combi_SeeMetaTable(sProject)
end

Function COMBI_GoToWebsite()
	BrowseURL/Z "http://www.COMBIgor.com"
end