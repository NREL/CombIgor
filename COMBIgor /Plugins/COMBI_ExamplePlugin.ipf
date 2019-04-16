#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Nov 2018 : Original Example Plugin 
// V1.01: Celeste Melamed _ Dec 2018 : Adding comments for developers

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
//FOR DEVELOPERS: Define a unique plugin name here.
Static StrConstant sPluginName = "ExamplePlugin"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this plugin
//FOR DEVELOPERS: Change COMBI_ExamplePlugin() to COMBI_YourPlugin() (to match the last function
//in this file), and change "Example Plugin" to whatever description you want
//in the drop-down COMBIgor menu for your instrument. If there is additional functionality for your
//Plugin, you can add another nested Submenu.
Menu "COMBIgor"
	SubMenu "Plugins"
		 "Example Plugin",/Q, COMBI_ExamplePlugin()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This function is run when the user selects the Plugin from the COMBIgor drop down menu once activated.
//This will build the plugin panel that the user interacts with.
//FOR DEVELOPERS: Most of this function just generates the graphics for the panel;
//however, at the bottom, you will need to edit the specific drop-downs and buttons that
//you want to have in your plugin.
function COMBI_ExamplePlugin()

	//name for plugin panel
	string sWindowName=sPluginName+"_Panel"
	
	//check if initialized, get starting values if so, initialize if not
	string sProject //project to operate within
	string sLibrary//Library to operate on
	string sData // Data type to operate on

	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")))
		//not yet initialized
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_ChooseProject(),"COMBIgor")//get project to start with
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")//get project to use in this function
	else
		//previously initialized
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")//get the previously used project
	endif
	
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sProject)))//if first time for this project, initialize values
		COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData","",sProject)
	endif
	
	//get values of globals to use in this function, mainly panel building
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sData = COMBI_GetPluginString(sPluginName,"sData",sProject)
	
	//get the globals wave for use in panel building, mainly set varaible controls
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_ExamplePlugin_Globals
	
	//make panel position if old existed
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 10
	string sAllWindows = WinList(sWindowName,";","")
	if(strlen(sAllWindows)>1)
		GetWindow/Z $sWindowName wsize
		vWinLeft = V_left
		vWinTop = V_top
		KillWindow/Z $sWindowName
	endif
	
	//dimensions of panel
	variable vPanelHeight = 100
	variable vPanelWidth = 250
 
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = "Courier"
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "COMBIgor Example Plugin"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	variable vYValue = 15
	
	//FOR DEVELOPERS: This is the section of this function that you will edit to customize
	//for your plugin. Currently there are three drop downs and a button; modify and/or
	//add new versions of these for your own purposes.
	//Project select
	DrawText 70,vYValue, "Project:"
	PopupMenu sProject,pos={195,vYValue-10},mode=1,bodyWidth=170,value=COMBI_Projects(),proc=ExamplePlugin_UpdateGlobal,popvalue=sProject
	vYValue+=20
	//Library select
	DrawText 70,vYValue, "Library:"
	PopupMenu sLibrary,pos={195,vYValue-10},mode=1,bodyWidth=170,value=ExamplePlugin_DropList("Libraries"),proc=ExamplePlugin_UpdateGlobal,popvalue=sLibrary
	vYValue+=20
	//Data select
	DrawText 70,vYValue, "Data:"
	PopupMenu sData,pos={195,vYValue-10},mode=1,bodyWidth=170,value=ExamplePlugin_DropList("DataTypes"),proc=ExamplePlugin_UpdateGlobal,popvalue=sData
	vYValue+=20
	//Do Something button
	button bSomeAction,title="Do A Thing",appearance={native,All},pos={25,vYValue},size={200,20},proc=ExamplePlugin_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
end


//This function will update the globals when a drop-down is updated on the panel.
//FOR DEVELOPERS: The following function is fairly general and shouldn't need to be edited much.
Function ExamplePlugin_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName//name of control, should be also name of global being updated
	Variable popNum//number in list
	String popStr //value selected
	if(stringmatch("sProject",ctrlName))
		//special place for the project
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	else 
		//store the global in based on the name of the control sending it
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	//reload panel
	COMBI_ExamplePlugin()
end


//This function is used to grab the info from the project to return in the pop-up menu.
//FOR DEVELOPERS: This is currently functional for Libraries and the corresponding scalar
//data types. This will need to be edited to add other data types, for example, vector 
//or library.
Function/S ExamplePlugin_DropList(sOption)
	string sOption//what type of list to return in the popup menu
	
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	
	//for various options of drop list
	if(stringmatch(sOption,"Libraries"))//list of libraries 
		return Combi_TableList(sProject,1,"All","Libraries")
	elseif(stringmatch(sOption,"DataTypes"))//list of scalar data for the select library
		return Combi_TableList(sProject,1,sLibrary,"DataTypes")
	endif
End



//This function handles the back end of the button on the panel, and calls the corresponding
//function that actually does something.
//FOR DEVELOPERS: This function will need to be modified a little bit for each added button
//that does something, but the majority of it should stay the same.
Function ExamplePlugin_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	string sData = COMBI_GetPluginString(sPluginName,"sData",sProject)
	
	//FOR DEVELOPERS: Copy and paste this for each different button you have that does
	//something different.
	//if button "bSomeAction" was pressed
	if(stringmatch("bSomeAction",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "ExamplePlugin_SomeAction(\""+sProject+"\",\""+sLibrary+"\",\""+sData+"\")"
		endif
		//pass to programatic function
		ExamplePlugin_SomeAction(sProject,sLibrary,sData)
	endif
end




//example function used to do something, called by the button function. 
//Currently it just prints the project, library, and data type names
//FOR DEVELOPERS: This is where the action of the button happens; can modify to do
//behind the scenes data manipulation, plotting, etc.
Function ExamplePlugin_SomeAction(sProject,sLibrary,sData)
	string sProject, sLibrary, sData 
	Print sProject
	Print sLibrary
	Print sData
end