#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#include <Ternary Diagram>

// Description/Summary of Procedure File
// Version History
// V1: Meagan Papac _ March 2019 : Original Ternary Plotter

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
Static StrConstant sPluginName = "TernaryPlotter"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this plugin
Menu "COMBIgor"
	SubMenu "Visualize"
		 "Ternary Plotter",/Q, COMBI_TernaryPlotter()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This function is run when the user selects the Ternary Plotter from the COMBIgor drop down menu once activated.
//This will build the plugin panel that the user interacts with.
function COMBI_TernaryPlotter()

	//name for panel
	string sWindowName=sPluginName+"_Panel"
	
	//check if initialized; get starting values, if so; otherwise, initialize
	string sProject //project to operate within
	string sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary //libraries for the different data types
	string sData //for retrieving list of data types
	string sApex1, sApex2, sApex3, sApex1Label, sApex2Label, sApex3Label, sConstantVariable, sConstantValue, sConstantTolerance, sColorScaleVariable, sColorScaleLabel, sMarkerSizeVariable //data types to plot
	string sConstantCondition, sColorScaleCondition, sMarkerSizeCondition, sMarkerSizeLabel
	//variable vConstantValue = str2num(sConstantValue), vConstantTolerance = str2num(sConstantTolerance) //to define range of constant variable
	string sAxisLabelCorner, sAxisLabelEdge, sConstantDataCategory, sColorScaleDataCategory, sMarkerSizeDataCategory, sMarkerStyle
	
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
		COMBI_GivePluginGlobal(sPluginName,"sApexLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex1","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex2","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex3","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex1Label","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex2Label","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex3Label","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstantLibrary","None",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstantVariable","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstantValue","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstantTolerance","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorScaleLibrary","None",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorScaleVariable","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorScaleLabel","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeLibrary","None",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeVariable","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeLabel","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerStyle","17",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAxisLabelCorner","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAxisLabelEdge","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstantDataCategory","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorScaleDataCategory","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeDataCategory","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstantCondition","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorScaleDataCondition","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeDataCondition","",sProject)
	endif
	
	//get values of globals to use in this function, mainly panel building
	sApexLibrary = COMBI_GetPluginString(sPluginName,"sApexLibrary",sProject)
	sData = COMBI_GetPluginString(sPluginName,"sData",sProject)
	sApex1 = COMBI_GetPluginString(sPluginName,"sApex1",sProject)
	sApex2 = COMBI_GetPluginString(sPluginName,"sApex2",sProject)
	sApex3 = COMBI_GetPluginString(sPluginName,"sApex3",sProject)
	sApex1Label = COMBI_GetPluginString(sPluginName,"sApex1Label",sProject)
	sApex2Label = COMBI_GetPluginString(sPluginName,"sApex2Label",sProject)
	sApex3Label = COMBI_GetPluginString(sPluginName,"sApex3Label",sProject)
	sConstantLibrary = COMBI_GetPluginString(sPluginName,"sConstantLibrary",sProject)
	sConstantVariable = COMBI_GetPluginString(sPluginName,"sConstantVariable",sProject)
	sConstantValue = COMBI_GetPluginString(sPluginName,"sConstantValue",sProject)
	sConstantTolerance = COMBI_GetPluginString(sPluginName,"sConstantTolerance",sProject)
	sColorScaleLibrary = COMBI_GetPluginString(sPluginName,"sColorScaleLibrary",sProject)
	sColorScaleVariable = COMBI_GetPluginString(sPluginName,"sColorScaleVariable",sProject)
	sColorScaleLabel = COMBI_GetPluginString(sPluginName,"sColorScaleLabel",sProject)
	sMarkerSizeLibrary = COMBI_GetPluginString(sPluginName,"sMarkerSizeLibrary",sProject)
	sMarkerSizeVariable = COMBI_GetPluginString(sPluginName,"sMarkerSizeVariable",sProject)
	sMarkerSizeLabel = COMBI_GetPluginString(sPluginName,"sMarkerSizeLabel",sProject)
	sMarkerStyle = COMBI_GetPluginString(sPluginName,"sMarkerStyle",sProject)
	sAxisLabelCorner = COMBI_GetPluginString(sPluginName,"sAxisLabelCorner",sProject)
	sAxisLabelEdge = COMBI_GetPluginString(sPluginName,"sAxisLabelEdge",sProject)
	sConstantDataCategory = COMBI_GetPluginString(sPluginName,"sConstantDataCategory",sProject)
	sColorScaleDataCategory = COMBI_GetPluginString(sPluginName,"sColorScaleDataCategory",sProject)
	sMarkerSizeDataCategory = COMBI_GetPluginString(sPluginName,"sMarkerSizeDataCategory",sProject)
	sConstantCondition = COMBI_GetPluginString(sPluginName,"sConstantCondition",sProject)
	sColorScaleCondition = COMBI_GetPluginString(sPluginName,"sColorScaleCondition",sProject)
	sMarkerSizeCondition = COMBI_GetPluginString(sPluginName,"sMarkerSizeCondition",sProject)

	//get the globals wave for use in panel building, mainly set variable controls
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_TernaryPlotter_Globals
	
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
	variable vPanelHeight = 475
	variable vPanelWidth = 625
	
	//to define variable dimensionality
	string sApex1Dim  
 
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = "Geneva"
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "COMBIgor Ternary Plotter"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 2, textyjust = 1, fsize = 12, save
	variable vYValue = 25
	
	//needed for defining dropdown menu items
	string quote = "\""
	string sCondList
		
	//Project select
	DrawText 85, vYValue, "Project:"
	PopupMenu sProject, pos={215,vYValue-10},mode=1,bodyWidth=170,value=COMBI_Projects(),proc=TernaryPlotter_UpdateGlobal,popvalue=sProject
	vYValue+=25	

	//Library select
	DrawText 85,vYValue, "Apex library:"
	PopupMenu sApexLibrary,pos={215,vYValue-10},mode=1,bodyWidth=170,value=TernaryPlotter_DropList("Libraries",""),proc=TernaryPlotter_UpdateGlobal,popvalue=sApexLibrary
	DrawText 375, vYValue, "Display label"
	DrawText 505, vYValue, "Label location"
	DrawLine vPanelWidth - 215, 15, vPanelWidth - 215, vYValue + 85
	DrawLine vPanelWidth - 107, 15, vPanelWidth - 107, vYValue + 85
	
	//Marker type selection 
	DrawText 605, vYValue, "Marker style"
	PopupMenu sMarkerStyle, value = "*MARKERPOP*", pos={545, vYValue +18}, mode=1, bodyWidth=15, proc=TernaryPlotter_UpdateGlobal
	variable/G vMarker
	NVAR vMarker
	string sMarkerNum = num2str(vMarker)
	killVariables vMarker
	DrawText 580, vYValue+26, "\W50"+sMarkerStyle
	vYValue+=25

	//Data type selection for first apex
	DrawText 85,vYValue, "Apex 1:"
	PopupMenu sApex1, pos={215, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("ScalarDataTypes", "Apex"), proc=TernaryPlotter_UpdateGlobal, popvalue=sApex1

	//set display label for ternary
	SetVariable sApex1Label, pos = {340, vYValue-10}, live = 1, noproc, bodyWidth = 100, fsize = 12, value = twGlobals[%sApex1Label][%$sProject], title = " "

	//check box to indicate label should be displayed at corner
	CheckBox sAxisLabelCorner, pos={430,vYValue-7},size={61,14},title="\F'"+sFont+"'Corner", fsize = 12,value = str2num(twGlobals[%sAxisLabelCorner][%$sProject]), proc = TernaryPlotter_UpdateGlobalBool
	vYValue+=25

	//Data type selection for second apex
	DrawText 85, vYValue, "Apex 2:"
	PopupMenu sApex2, pos={215, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("ScalarDataTypes", "Apex"), proc=TernaryPlotter_UpdateGlobal, popvalue=sApex2

	//set display label for ternary
	SetVariable sApex2Label, pos = {340, vYValue-10}, live = 1, noproc, bodyWidth = 100, fsize = 12, value = twGlobals[%sApex2Label][%$sProject], title = " "
	
	//check box to indicate label should be displayed at edge
	CheckBox sAxisLabelEdge, pos={430, vYValue-7}, size={61, 14}, title="\F'"+sFont+"'Edge", fsize = 12, value = str2num(twGlobals[%sAxisLabelEdge][%$sProject]), proc = TernaryPlotter_UpdateGlobalBool
	vYValue+=25

	//Data type selection for third apex
	DrawText 85, vYValue, "Apex 3:"
	PopupMenu sApex3, pos={215, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("ScalarDataTypes", "Apex"), proc=TernaryPlotter_UpdateGlobal, popvalue=sApex3
	SetVariable sApex3Label, pos = {340, vYValue-10}, live = 1, noproc, bodyWidth = 100, fsize = 12, value = twGlobals[%sApex3Label][%$sProject], title = " "
	vYValue+=25

	//insert lines
	DrawLine 25, vYValue, vPanelWidth - 25, vYValue
	vYValue += 25	

	//Library select
	DrawText 160, vYValue, "Constant variable library:"
	PopupMenu sConstantLibrary, pos={295, vYValue-10}, mode=1, bodyWidth=170, value="None"+TernaryPlotter_DropList("Libraries", ""), proc=TernaryPlotter_UpdateGlobal, popvalue=sConstantLibrary
	vYValue+=25
	
	//Data type selection for constant variable 
	if(stringMatch(sConstantLibrary, "!None"))
		DrawText 160, vYValue, "Constant variable:"
		PopupMenu sConstantDataCategory, pos={190, vYValue-10}, mode=1, bodyWidth=65, value="Scalar;Vector", proc=TernaryPlotter_UpdateGlobal, popvalue=sConstantDataCategory
		if(stringMatch(sConstantDataCategory, "Scalar"))
			PopupMenu sConstantVariable, pos={375, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("ScalarDataTypes", "Constant"), proc=TernaryPlotter_UpdateGlobal, popvalue=sConstantVariable
		elseif(stringMatch(sConstantDataCategory, "Vector"))
			PopupMenu sConstantVariable, pos={375, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("VectorDataTypes", "Constant"), proc=TernaryPlotter_UpdateGlobal, popvalue=sConstantVariable
			sCondList = quote + TernaryPlotter_GetColumnDimLabels(sProject, sConstantLibrary, sConstantVariable) + quote
			DrawText 508, vYValue-20, "Vector value"
			PopupMenu sConstantCondition, pos={455, vYValue-10}, mode=1, bodyWidth=65, value=#sCondList, proc=TernaryPlotter_UpdateGlobal, popvalue=sConstantCondition
		endif
	endif
	vYValue+=25

	//Input value for constant variable
	if(stringMatch(sConstantLibrary, "!None"))
		DrawText 245, vYValue, "Value:"
		SetVariable sConstantValue, pos = {255, vYValue-10}, live = 1, noproc, bodyWidth = 50, fsize = 12, value = twGlobals[%sConstantValue][%$sProject], title = " "
	endif
	vYValue+=25

	//Input tolerance for constant variable
	if(stringMatch(sConstantLibrary, "!None"))
		DrawText 245,vYValue, "Tolerance:"
		SetVariable sConstantTolerance, pos = {255,vYValue-10}, live = 1, noproc, bodyWidth=50, fsize = 12, value = twGlobals[%sConstantTolerance][%$sProject], title = " " 
	endif
	vYValue+=25

	//insert horizontal line
	DrawLine 25, vYValue, vPanelWidth - 25, vYValue
	vYValue += 25

	//Library select
	DrawText 125, vYValue, "Color scale library:"
	PopupMenu sColorScaleLibrary, pos={255, vYValue-10}, mode=1, bodyWidth=170, value="None"+TernaryPlotter_DropList("Libraries", ""), proc=TernaryPlotter_UpdateGlobal, popvalue=sColorScaleLibrary
	vYValue+=25

	if(stringMatch(sColorScaleLibrary, "!None"))
		DrawText 490, vYValue-20, "Display label"
		//Data type selection for color scale
		DrawText 125, vYValue, "Color scale variable:"
		PopupMenu sColorScaleDataCategory, pos={150, vYValue-10}, mode=1, bodyWidth=65, value="Scalar;Vector", proc=TernaryPlotter_UpdateGlobal, popvalue=sColorScaleDataCategory
		if(stringMatch(sColorScaleDataCategory, "Scalar"))
			PopupMenu sColorScaleVariable, pos={335, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("ScalarDataTypes", "ColorScale"), proc=TernaryPlotter_UpdateGlobal, popvalue=sColorScaleVariable
		elseif(stringMatch(sColorScaleDataCategory, "Vector"))
			PopupMenu sColorScaleVariable, pos={335, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("VectorDataTypes", "ColorScale"), proc=TernaryPlotter_UpdateGlobal, popvalue=sColorScaleVariable
			sCondList = quote + TernaryPlotter_GetColumnDimLabels(sProject, sColorScaleLibrary, sColorScaleVariable) + quote
			PopupMenu sColorScaleCondition, pos={540, vYValue-10}, mode=1, bodyWidth=65, value=#sCondList, proc=TernaryPlotter_UpdateGlobal, popvalue=sColorScaleCondition
			DrawText 593, vYValue-20, "Vector value"
		endif
		SetVariable sColorScaleLabel, pos = {460, vYValue-10}, live = 1, noproc, bodyWidth = 110, fsize = 12, value = twGlobals[%sColorScaleLabel][%$sProject], title = " "
	endif
	vYValue+=25

	//insert horizontal line
	DrawLine 25, vYValue, vPanelWidth - 25, vYValue
	vYValue += 25

	//Library select
	DrawText 125, vYValue, "Marker size library:"
	PopupMenu sMarkerSizeLibrary, pos={255, vYValue-10}, mode=1, bodyWidth=170, value="None"+TernaryPlotter_DropList("Libraries", ""), proc=TernaryPlotter_UpdateGlobal, popvalue=sMarkerSizeLibrary
	vYValue+=25	

	//Data type selection for marker size
	if(stringMatch(sMarkerSizeLibrary, "!None"))
		DrawText 125, vYValue, "Marker size variable:"
		PopupMenu sMarkerSizeDataCategory, pos={150, vYValue-10}, mode=1, bodyWidth=65, value="Scalar;Vector", proc=TernaryPlotter_UpdateGlobal, popvalue=sMarkerSizeDataCategory	
		DrawText 490, vYValue-20, "Display Label"
		if(stringMatch(sMarkerSizeDataCategory, "Scalar"))
			PopupMenu sMarkerSizeVariable, pos={335, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("ScalarDataTypes", "MarkerSize"), proc=TernaryPlotter_UpdateGlobal, popvalue=sMarkerSizeVariable
		elseif(stringMatch(sMarkerSizeDataCategory, "Vector"))
			PopupMenu sMarkerSizeVariable, pos={335, vYValue-10}, mode=1, bodyWidth=170, value=TernaryPlotter_DropList("VectorDataTypes", "MarkerSize"), proc=TernaryPlotter_UpdateGlobal, popvalue=sMarkerSizeVariable
			sCondList = quote + TernaryPlotter_GetColumnDimLabels(sProject, sMarkerSizeLibrary, sMarkerSizeVariable) + quote	
			PopupMenu sMarkerSizeCondition, pos={540, vYValue-10}, mode=1, bodyWidth=65, value=#sCondList, proc=TernaryPlotter_UpdateGlobal, popvalue=sMarkerSizeCondition
			DrawText 593, vYValue-20, "Vector value"
		endif
		SetVariable sMarkerSizeLabel, pos = {460, vYValue-10}, live = 1, noproc, bodyWidth = 110, fsize = 12, value = twGlobals[%sMarkerSizeLabel][%$sProject], title = " "
	endif
	vYValue+=25
	
	//Draws the Make Plot button
	button bMakePlot, title="Make New Plot", appearance={native, All}, pos={26, vYValue+10}, size={150, 25}, proc=TernaryPlotter_Button, font=sFont, fstyle=1, fColor=(21845, 21845, 21845), fsize=16
	button bAppendTrace, title="Append Trace", appearance={native, All}, pos={202, vYValue+10}, size={150, 25}, proc=TernaryPlotter_Button, font=sFont, fstyle=1, fColor=(21845, 21845, 21845), fsize=16
	button bDrawMarkerSizeLegend, title="Draw Marker Size Legend", appearance={native, All}, pos={378, vYValue+10}, size={220, 25}, proc=TernaryPlotter_Button, font=sFont, fstyle=1, fColor=(21845, 21845, 21845), fsize=16

end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This function will update the globals when a drop-down is updated on the panel.
Function TernaryPlotter_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName//name of control, should be also name of global being updated
	Variable popNum//number in list
	String popStr //value selected
	if(stringmatch("sProject",ctrlName))
		//special place for the project
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	elseif(stringMatch("sApex1", ctrlName))
		string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sProject)
		string sApex1 = COMBI_GetPluginString(sPluginName,"sApex1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex1Label", sApex1 ,sProject)
	elseif(stringMatch("sApex2", ctrlName))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sProject)
		string sApex2 = COMBI_GetPluginString(sPluginName,"sApex2",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex2Label", sApex2 ,sProject)
	elseif(stringMatch("sApex3", ctrlName))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sProject)
		string sApex3 = COMBI_GetPluginString(sPluginName,"sApex3",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sApex3Label", sApex3 ,sProject)
	elseif(stringMatch("sColorScaleVariable", ctrlName))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sProject)
		string sColorScaleVariable = COMBI_GetPluginString(sPluginName,"sColorScaleVariable",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorScaleLabel", sColorScaleVariable ,sProject)
	elseif(stringMatch("sMarkerSizeVariable", ctrlName))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sProject)
		string sMarkerSizeVariable = COMBI_GetPluginString(sPluginName,"sMarkerSizeVariable",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeLabel", sMarkerSizeVariable ,sProject)
	elseif(stringMatch("sMarkerStyle", ctrlName))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName, num2str(popNum - 1),sProject)
	else 
		//store the global in based on the name of the control sending it
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	
	//get project name for next round of if statements
	sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	
	//if "none" is not selected for constant, color scale, or marker size, set corresponding variables to ""
	if(stringMatch("sConstantLibrary", ctrlName))
		if(stringMatch(COMBI_GetPluginString(sPluginName,"sConstantLibrary",sProject), "None"))
			COMBI_GivePluginGlobal(sPluginName,"sConstantVariable", "" ,sProject)
			COMBI_GivePluginGlobal(sPluginName,"sConstantValue", "" ,sProject)
			COMBI_GivePluginGlobal(sPluginName,"sConstantTolerance", "" ,sProject)
		endif
	elseif(stringMatch("sColorScaleLibrary", ctrlName))
		if(stringMatch(COMBI_GetPluginString(sPluginName,"sColorScaleLibrary",sProject), "None"))
			COMBI_GivePluginGlobal(sPluginName,"sColorScaleVariable", "" ,sProject)
			COMBI_GivePluginGlobal(sPluginName,"sColorScaleLabel", "" ,sProject)
		endif
	elseif(stringMatch("sMarkerSizeLibrary", ctrlName))
		if(stringMatch(COMBI_GetPluginString(sPluginName,"sMarkerSizeLibrary",sProject), "None"))
			COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeVariable", "" ,sProject)
			COMBI_GivePluginGlobal(sPluginName,"sMarkerSizeLabel", "" ,sProject)
		endif
	endif
	//reload panel
	
	COMBI_TernaryPlotter()
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function TernaryPlotter_GetMarker(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName//name of control, should be also name of global being updated
	Variable popNum//number in list
	String popStr //value selected
	variable/G vMarker = popNum - 1
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Update values of corner and edge axis label locations
function TernaryPlotter_UpdateGlobalBool(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	COMBI_GivePluginGlobal("TernaryPlotter", ctrlname, num2str(checked), sProject)
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This function is used to grab the info from the project to return in the pop-up menu.
Function/S TernaryPlotter_DropList(sOption, sLibType)
	string sOption, sLibType//what type of list to return in the popup menu
	
	string sProject =  COMBI_GetPluginString("TernaryPlotter","sProject","COMBIgor")
	//string sCurrentApexLibrary = COMBI_GetPluginString("TernaryPlotter","sApexLibrary",sProject)
	string sLibrary 
	
	//get library that matches types of data being retrieved
	if(stringMatch(sLibType, "Apex"))
		sLibrary = COMBI_GetPluginString("TernaryPlotter","sApexLibrary",sProject)
	elseif(stringMatch(sLibType, "Constant"))
		sLibrary = COMBI_GetPluginString("TernaryPlotter","sConstantLibrary",sProject)
	elseif(stringMatch(sLibType, "ColorScale"))
		sLibrary = COMBI_GetPluginString("TernaryPlotter","sColorScaleLibrary",sProject)
	elseif(stringMatch(sLibType, "MarkerSize"))
		sLibrary = COMBI_GetPluginString("TernaryPlotter","sMarkerSizeLibrary",sProject)
	endif
	
	//get global values
	sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	//string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	
	//for various options of drop list
	if(stringmatch(sOption,"Libraries"))//list of libraries 
		return ";" + Combi_TableList(sProject,1,"All","Libraries")
	elseif(stringmatch(sOption,"ScalarDataTypes"))//list of scalar data for the select library
		return ";" + Combi_TableList(sProject,1,sLibrary,"DataTypes")
	elseif(stringmatch(sOption,"VectorDataTypes"))//list of vector data for the select library
		return ";" + Combi_TableList(sProject,2,sLibrary,"DataTypeswDim")
	endif
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//gets all dimension labels from a the wave specified
Function/S TernaryPlotter_GetColumnDimLabels(sProject, sLibrary, sWaveName)
	string sProject, sLibrary, sWaveName 
	variable i
	string sWavePath = Combi_DataPath(sProject, 2) + sLibrary + ":" + sWaveName
	wave wVariableWave = $sWavePath
	string sConditionList = ""
	for(i = 0; i < dimSize(wVariablewave, 1); i += 1)
		sConditionList = sConditionList + getDimLabel(wVariableWave, 1, i) + ";"
	endfor
	return sConditionList
End

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This function handles the back end of the button on the panel, and calls the corresponding
//function that actually does something.
Function TernaryPlotter_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sApexLibrary = COMBI_GetPluginString(sPluginName,"sApexLibrary",sProject)
	string sData = COMBI_GetPluginString(sPluginName,"sData",sProject)
	string sApex1 = COMBI_GetPluginString(sPluginName,"sApex1",sProject)
	string sApex2 = COMBI_GetPluginString(sPluginName,"sApex2",sProject)
	string sApex3 = COMBI_GetPluginString(sPluginName,"sApex3",sProject)
	string sApex1Label = COMBI_GetPluginString(sPluginName,"sApex1Label",sProject)
	string sApex2Label = COMBI_GetPluginString(sPluginName,"sApex2Label",sProject)
	string sApex3Label = COMBI_GetPluginString(sPluginName,"sApex3Label",sProject)
	string sConstantLibrary = COMBI_GetPluginString(sPluginName,"sConstantLibrary",sProject)
	string sConstantVariable = COMBI_GetPluginString(sPluginName,"sConstantVariable",sProject)
	string sConstantValue = COMBI_GetPluginString(sPluginName,"sConstantValue",sProject)
	string sConstantTolerance = COMBI_GetPluginString(sPluginName,"sConstantTolerance",sProject)
	string sColorScaleLibrary = COMBI_GetPluginString(sPluginName,"sColorScaleLibrary",sProject)
	string sColorScaleVariable = COMBI_GetPluginString(sPluginName,"sColorScaleVariable",sProject)
	string sColorScaleLabel = COMBI_GetPluginString(sPluginName,"sColorScaleLabel",sProject)
	string sMarkerSizeLibrary = COMBI_GetPluginString(sPluginName,"sMarkerSizeLibrary",sProject)
	string sMarkerSizeVariable = COMBI_GetPluginString(sPluginName,"sMarkerSizeVariable",sProject)
	string sMarkerSizeLabel = COMBI_GetPluginString(sPluginName,"sMarkerSizeVariable",sProject)
	string sMarkerStyle = COMBI_GetPluginString(sPluginName,"sMarkerStyle",sProject)
	string sAxisLabelCorner = COMBI_GetPluginString(sPluginName,"sAxisLabelCorner",sProject)
	string sAxisLabelEdge = COMBI_GetPluginString(sPluginName,"sAxisLabelEdge",sProject)
	string sConstantDataCategory = COMBI_GetPluginString(sPluginName,"sConstantDataCategory",sProject)
	string sColorScaleDataCategory = COMBI_GetPluginString(sPluginName,"sColorScaleDataCategory",sProject)
	string sMarkerSizeDataCategory = COMBI_GetPluginString(sPluginName,"sMarkerSizeDataCategory",sProject)
	string sConstantCondition = COMBI_GetPluginString(sPluginName,"sConstantCondition",sProject)
	string sColorScaleCondition = COMBI_GetPluginString(sPluginName,"sColorScaleCondition",sProject)
	string sMarkerSizeCondition = COMBI_GetPluginString(sPluginName,"sMarkerSizeCondition",sProject)	
	
	//FOR DEVELOPERS: Copy and paste this for each different button you have that does
	//something different.
	//if button "bSomeAction" was pressed
	if(stringmatch("bMakePlot",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "TernaryPlotter_MakePlot(\""+sProject+"\",\""+sApexLibrary+"\",\""+sConstantLibrary+"\",\""+sColorScaleLibrary+"\",\""+sMarkerSizeLibrary+"\",\""+sApex1+"\",\""+sApex1Label+"\",\""+ sApex2+"\",\""+sApex2Label+"\",\""+ sApex3+"\",\""+sApex3Label+"\",\""+sConstantDataCategory+"\",\""+sConstantVariable+"\",\""+ sConstantValue+"\",\""+ sConstantTolerance+"\",\""+sConstantCondition+"\",\""+sColorScaleDataCategory+"\",\""+ sColorScaleVariable+"\",\""+sColorScaleCondition+"\",\""+sColorScaleLabel+"\",\""+sMarkerSizeDataCategory+"\",\""+sMarkerSizeVariable+"\",\""+sMarkerSizeLabel+"\",\""+sMarkerSizeCondition+"\",\""+sAxisLabelCorner+"\",\""+sAxisLabelEdge+"\")"
		endif
		//pass to programatic function
		TernaryPlotter_MakePlot(sProject, sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary, sApex1, sApex1Label, sApex2, sApex2Label, sApex3, sApex3Label, sConstantDataCategory, sConstantVariable, sConstantValue, sConstantTolerance, sConstantCondition, sColorScaleDataCategory, sColorScaleVariable, sColorScaleCondition, sColorScaleLabel, sMarkerSizeDataCategory, sMarkerSizeVariable, sMarkerSizeLabel, sMarkerStyle, sMarkerSizeCondition, sAxisLabelCorner, sAxisLabelEdge)
	endif
	
	if(stringmatch("bAppendTrace",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "TernaryPlotter_AppendTrace(\""+sProject+"\",\""+sApexLibrary+"\",\""+sConstantLibrary+"\",\""+sColorScaleLibrary+"\",\""+sMarkerSizeLibrary+"\",\""+sApex1+"\",\""+sApex1Label+"\",\""+ sApex2+"\",\""+sApex2Label+"\",\""+ sApex3+"\",\""+sApex3Label+"\",\""+sConstantDataCategory+"\",\""+sConstantVariable+"\",\""+ sConstantValue+"\",\""+ sConstantTolerance+"\",\""+sConstantCondition+"\",\""+sColorScaleDataCategory+"\",\""+ sColorScaleVariable+"\",\""+sColorScaleCondition+"\",\""+sColorScaleLabel+"\",\""+sMarkerSizeDataCategory+"\",\""+sMarkerSizeVariable+"\",\""+sMarkerSizeLabel+"\",\""+sMarkerStyle+"\",\""+sMarkerSizeCondition+"\",\""+sAxisLabelCorner+"\",\""+sAxisLabelEdge+"\")"
		endif
		//pass to programatic function
		TernaryPlotter_AppendTrace(sProject, sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary, sApex1, sApex1Label, sApex2, sApex2Label, sApex3, sApex3Label, sConstantDataCategory, sConstantVariable, sConstantValue, sConstantTolerance, sConstantCondition, sColorScaleDataCategory, sColorScaleVariable, sColorScaleCondition, sColorScaleLabel, sMarkerSizeDataCategory, sMarkerSizeVariable, sMarkerSizeLabel, sMarkerStyle, sMarkerSizeCondition, sAxisLabelCorner, sAxisLabelEdge)
	endif	
	
	if(stringmatch("bDrawMarkerSizeLegend",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "TernaryPlotter_DrawMarkerSizeLegend(\""+"\")"
		endif
		//pass to programatic function
		TernaryPlotter_DrawMarkerSizeLegend()
	endif	
	
	if(stringmatch("bCloseWindow",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:"))//topmost plot window
			killWindow $sWindowName
		endif
	endif

	
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Make ternary plot, using inputs defined by use in panel
Function TernaryPlotter_MakePlot(sProject, sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary, sApex1, sApex1Label, sApex2, sApex2Label, sApex3, sApex3Label, sConstantDataCategory, sConstantVariable, sConstantValue, sConstantTolerance, sConstantCondition, sColorScaleDataCategory, sColorScaleVariable, sColorScaleCondition, sColorScaleLabel, sMarkerSizeDataCategory, sMarkerSizeVariable, sMarkerSizeLabel, sMarkerStyle, sMarkerSizeCondition, sAxisLabelCorner, sAxisLabelEdge)
	string sProject, sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary, sApex1, sApex1Label, sApex2, sApex2Label, sApex3, sApex3Label
	string sConstantDataCategory, sConstantVariable, sConstantValue, sConstantTolerance, sConstantCondition, sColorScaleDataCategory, sColorScaleVariable, sColorScaleCondition, sColorScaleLabel
	string sMarkerSizeDataCategory, sMarkerSizeVariable, sMarkerSizeLabel, sMarkerStyle, sMarkerSizeCondition, sAxisLabelCorner, sAxisLabelEdge
	
	//make plot wave  
	string sWaveName = TernaryPlotter_PlotWave("")//new wave
	
	//make trace name
	string sTraceName = sColorScaleLibrary+"_"+sColorScaleVariable
	
	//plot name
	int iPlotNum = 0
	string sPlotName = "TernaryPlot_" +sColorScaleVariable
	GetWindow/Z $sPlotName active
	if(V_Flag==0)//no error becasue plot existed, try again with increminted plot number
		do
			sPlotName = "TernaryPlot_" +sColorScaleVariable+"_"+num2str(iPlotNum)
			GetWindow/Z $sPlotName active 
			iPlotNum+=1
		while(V_Flag==0)//no error becasue plot existed, try again with increased plot number
	endif
	
	
	//define path for wave to plot from 
	string sWavePath = "root:Packages:COMBIgor:DisplayWaves:"+ sWaveName
	
	//get the wave to hold ternary plotting values
	wave wTernaryWave =$sWavePath
	
	//append info to wave note 
	string sNoteInfo = sProject+";"+sApexLibrary+";"+sConstantLibrary+";"+sColorScaleLibrary+";"+sMarkerSizeLibrary+";"+sApex1+";"+sApex1Label+";"+sApex2+";"+sApex2Label+";"+sApex3+";"+sApex3Label+";"+sConstantDataCategory+";"+sConstantVariable+";"+sConstantValue+";"+sConstantTolerance+";"+sConstantCondition+";"+sColorScaleDataCategory+";"+sColorScaleVariable+";"+sColorScaleCondition+";"+sColorScaleLabel+";"+sMarkerSizeDataCategory+";"+ sMarkerSizeVariable+";"+sMarkerSizeCondition+";"+ sMarkerSizeLabel+";"+sMarkerStyle
	Note/NOCR wTernaryWave sNoteInfo+"$"	
	
	//SetDimLabel 1, 0, Library, wTernaryWave
	SetDimLabel 1, 0, Sample, wTernaryWave
	SetDimLabel 1, 1, x_ternary, wTernaryWave
	SetDimLabel 1, 2, y_ternary, wTernaryWave
	SetDimLabel 1, 3, $sColorScaleVariable, wTernaryWave
	SetDimLabel 1, 4, $sMarkerSizeVariable, wTernaryWave
	
	//get variable waves
	wave wSample = $"root:COMBIgor:" + sProject + ":Data:FromMappingGrid:Sample"
	wave wApex1 = $"root:COMBIgor:" + sProject + ":Data:" + sApexLibrary + ":" + sApex1
	wave wApex2 = $"root:COMBIgor:" + sProject + ":Data:" + sApexLibrary + ":" + sApex2
	wave wApex3 = $"root:COMBIgor:" + sProject + ":Data:" + sApexLibrary + ":" + sApex3
	wave wConstant = $"root:COMBIgor:" + sProject + ":Data:" + sConstantLibrary + ":" + sConstantVariable
	wave wColorScale = $"root:COMBIgor:" + sProject + ":Data:" + sColorScaleLibrary + ":" + sColorScaleVariable
	wave wMarkerSize = $"root:COMBIgor:" + sProject + ":Data:" + sMarkerSizeLibrary + ":" + sMarkerSizeVariable
	
	//define loop variables
	variable i, vRow = dimsize(wTernaryWave,0)-1
	variable vApex1, vApex2, vApex3, vAddValue, vMaxY = -inf, vMinY = inf, vMaxMS = -inf, vMinMS = inf
		
	//go through points
	for(i = 0; i < DimSize(wApex1, 0); i += 1)
		
		//normalize variables
		vApex1 = wApex1[i]/(wApex1[i] + wApex2[i] + wApex3[i])
		vApex2 = wApex2[i]/(wApex1[i] + wApex2[i] + wApex3[i])
		vApex3 = wApex3[i]/(wApex1[i] + wApex2[i] + wApex3[i])
		
		//ensures that value is always added, if no constant library has been selected
		vAddValue = 1	
		
		//if constant library has been selected, determine whether values lies within value +- tolerance
		if(stringMatch(sConstantLibrary, "!None"))	
			//for scalar constant value
			if(stringMatch(sConstantDataCategory, "Scalar"))
				if(wConstant[i] < str2num(sConstantValue) + str2num(sConstantTolerance) && wConstant[i] > str2num(sConstantValue) - str2num(sConstantTolerance))
					vAddValue = 1
				else 
					vAddValue = 0
				endif
			elseif(stringMatch(sConstantDataCategory, "Vector"))
				if(wConstant[i][%$sConstantCondition] < str2num(sConstantValue) + str2num(sConstantTolerance) && wConstant[i][%$sConstantCondition] > str2num(sConstantValue) - str2num(sConstantTolerance))
					vAddValue = 1
				else
					vAddValue = 0
				endif
			endif	
		endif
		
		//if value is within the range defined for the constant variable, add values to ternary wave
		if(vAddValue == 1)
			Redimension /N = (vRow + 1, -1) wTernaryWave
			wTernaryWave[vRow][0] = wSample[i]
			wTernaryWave[vRow][1] = vApex2 + 0.5*vApex3
			wTernaryWave[vRow][2] = vApex3*sqrt(3)/2
			if(stringMatch(sColorScaleLibrary, "!None"))			
				//for scalar color scale wave
				if(stringMatch(sColorScaleDataCategory, "Scalar"))
					wTernaryWave[vRow][3] = wColorScale[i]
					if(wColorScale[i] > vMaxY)
						vMaxY = wColorScale[i]
					endif
					if(wColorScale[i] < vMinY)
						vMinY = wColorScale[i]
					endif
				//for vector color scale wave
				elseif(stringMatch(sColorScaleDataCategory, "Vector"))
					wTernaryWave[vRow][3] = wColorScale[i][%$sColorScaleCondition]
					if(wColorScale[i][%$sColorScaleCondition] > vMaxY)
						vMaxY = wColorScale[i][%$sColorScaleCondition]
					endif
					if(wColorScale[i][%$sColorScaleCondition] < vMinY)
						vMinY = wColorScale[i][%$sColorScaleCondition]
					endif
				else 
					wTernaryWave[vRow][3] = 0
				endif	
			endif
			//for scalar marker size wave
			if(stringMatch(sMarkerSizeLibrary, "!None"))			
				if(stringMatch(sMarkerSizeDataCategory, "Scalar"))
					wTernaryWave[vRow][4] = wMarkerSize[i]
					if(wMarkerSize[i] > vMaxMS)
						vMaxMS = wMarkerSize[i]
					endif
					if(wMarkerSize[i] < vMinMS)
						vMinMS = wMarkerSize[i]
					endif
				//for vector marker size wave 
				elseif(stringMatch(sMarkerSizeDataCategory, "Vector"))
					wTernaryWave[vRow][4] = wMarkerSize[i][%$sMarkerSizeCondition]
					if(wMarkerSize[i][%$sMarkerSizeCondition] > vMaxMS)
						vMaxMS = wMarkerSize[i][%$sMarkerSizeCondition]
					endif
					if(wMarkerSize[i][%$sMarkerSizeCondition] < vMinMS)
						vMinMS = wMarkerSize[i][%$sMarkerSizeCondition]
					endif
				endif
			else
				wTernaryWave[vRow][4] = 0
			endif
			vRow = vRow+1
		endif
	endfor
	
	//make plot window
	TernaryDiagramModule#NewTernaryGraphWindow (sPlotName)	
	
	//hook the killing function and tell the killing function the data source
	SetWindow $sPlotName userdata(DataSource)= "root:Packages:COMBIgor:DisplayWaves:"+sWaveName
	SetWindow $sPlotName hook(kill)=COMBIDispaly_KillPlotData
	
	//give min and max of colorscale and marker size for use in appended traces as user data on the plot window
	SetWindow $sPlotName  userdata(sMinY)=num2str(vMinY)
	SetWindow $sPlotName  userdata(sMaxY)=num2str(vMaxY)
	SetWindow $sPlotName  userdata(sMinMS)=num2str(vMinMS)
	SetWindow $sPlotName  userdata(sMaxMS)=num2str(vMaxMS)
	
	//font to use
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	//format the plot
	TernaryDiagramModule#RemoveAllTernaryCornerLabels(sPlotName)
	//TernaryDiagramModule#DrawTernaryGraphTickLabels(gname, delta(from 0 to 1), red, green, blue, "fontname", fontsize, fontstyle(0 = plain), labelOffset, "which(bottom,left,right)")
	TernaryDiagramModule#DrawTernaryGraphTickLabels(sPlotName, .2, 0.5, 0.5, 0.5, sFont, 20, 0, 10, "Left")
	TernaryDiagramModule#DrawTernaryGraphTickLabels(sPlotName, .2, 0.5, 0.5, 0.5, sFont, 20, 0, 10, "Right")
	TernaryDiagramModule#DrawTernaryGraphTickLabels(sPlotName, .2, 0.5, 0.5, 0.5, sFont, 20, 0, 10, "Bottom")
	
	ModifyGraph margin(left) = 100, margin(right) = 138, margin(top) = 72, margin(bottom) = 82
	ModifyGraph width=500,height=400
	AppendToGraph/L=TernaryGraphVertAxis/B=TernaryGraphHorizAxis wTernaryWave[][2]/TN=$sTraceName  vs wTernaryWave[][1]
	ModifyGraph marker($sTraceName)=str2num(sMarkerStyle), mode($sTraceName)=3
	if(stringMatch(sColorScaleLibrary, "!None"))
		ModifyGraph zColor($sTraceName)={wTernaryWave[][3] ,vMinY,vMaxY,YellowHot,0}	
		ColorScale/C/N=text0/F=0/A=MC trace=$sTraceName, width=12, heightPct=60, sColorScaleLabel
		ColorScale/C/N=text0/X=55/Y=10.00 font=sFont, fsize = 20, fstyle = 0, lblMargin = 10
	endif
	if(stringMatch(sMarkerSizeLibrary, "!None"))
		ModifyGraph zMrkSize($sTraceName)={wTernaryWave[][4] ,vMinMS,vMaxMS,1,6}	
	else
		ModifyGraph msize=5
	endif
	//Adds corner labels
	if(str2num(sAxisLabelCorner) == 1)
		TernaryDiagramModule#DrawTernaryGraphCornerLabels(sPlotName, sApex1Label, 0.5, 0.5, 0.5, sFont, 28, 0, 33.5, -40, "Left")
		TernaryDiagramModule#DrawTernaryGraphCornerLabels(sPlotName, sApex2Label, 0.5, 0.5, 0.5, sFont, 28, 0, 33.5, 40, "Right")
		TernaryDiagramModule#DrawTernaryGraphCornerLabels(sPlotName, sApex3Label, 0.5, 0.5, 0.5, sFont, 28, 0, 33.5, 0, "Top")
	endif
	//Adds edge labels
	if(str2num(sAxisLabelEdge) == 1)
		TernaryDiagramModule#DrawTernaryGraphAxisLabels(sPlotName, sApex1Label, 0.5, 0.5, 0.5, sFont, 28, 0, 40, 10, "Left")	
		TernaryDiagramModule#DrawTernaryGraphAxisLabels(sPlotName, sApex2Label, 0.5, 0.5, 0.5, sFont, 28, 0, 40, 10, "Bottom")	
		TernaryDiagramModule#DrawTernaryGraphAxisLabels(sPlotName, sApex3Label, 0.5, 0.5, 0.5, sFont, 28, 0, 40, 0, "Right")	
	endif
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Appends trace to active ternary plot window
Function TernaryPlotter_AppendTrace(sProject, sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary, sApex1, sApex1Label, sApex2, sApex2Label, sApex3, sApex3Label, sConstantDataCategory, sConstantVariable, sConstantValue, sConstantTolerance, sConstantCondition, sColorScaleDataCategory, sColorScaleVariable, sColorScaleCondition, sColorScaleLabel, sMarkerSizeDataCategory, sMarkerSizeVariable, sMarkerSizeLabel, sMarkerStyle, sMarkerSizeCondition, sAxisLabelCorner, sAxisLabelEdge)
	string sProject, sApexLibrary, sConstantLibrary, sColorScaleLibrary, sMarkerSizeLibrary, sApex1, sApex1Label, sApex2, sApex2Label, sApex3, sApex3Label
	string sConstantDataCategory, sConstantVariable, sConstantValue, sConstantTolerance, sConstantCondition, sColorScaleDataCategory, sColorScaleVariable, sColorScaleCondition, sColorScaleLabel
	string sMarkerSizeDataCategory, sMarkerSizeVariable, sMarkerSizeLabel, sMarkerStyle, sMarkerSizeCondition, sAxisLabelCorner, sAxisLabelEdge
	
	//get source wave
	string sWaveName = TernaryPlotter_PlotWave("TOP")//source wave from top plot
	
	//get name of plot
	string sPlotName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	
	//define path for wave to plot from 
	string sWavePath = "root:Packages:COMBIgor:DisplayWaves:"+ sWaveName
	
	//get wave to hold ternary plotting values
	wave wTernaryWave =$sWavePath
	
	//append info to wave note 
	string sNoteInfo = sProject+";"+sApexLibrary+";"+sConstantLibrary+";"+sColorScaleLibrary+";"+sMarkerSizeLibrary+";"+sApex1+";"+sApex1Label+";"+sApex2+";"+sApex2Label+";"+sApex3+";"+sApex3Label+";"+sConstantDataCategory+";"+sConstantVariable+";"+sConstantValue+";"+sConstantTolerance+";"+sConstantCondition+";"+sColorScaleDataCategory+";"+sColorScaleVariable+";"+sColorScaleCondition+";"+sColorScaleLabel+";"+sMarkerSizeDataCategory+";"+ sMarkerSizeVariable+";"+sMarkerSizeCondition+";"+sMarkerStyle
	Note/NOCR wTernaryWave sNoteInfo+"$"	
	
	//make trace name
	string sExistingTraces = TraceNameList(sPlotName, ";",1)
	string sTraceName = sColorScaleLibrary+"_"+sColorScaleVariable
	if(WhichListItem(sTraceName,sExistingTraces)!=-1)//trace name is taken
		int iTraceInc = 1
		do
			sTraceName = sColorScaleLibrary+"_"+sColorScaleVariable+"_"+num2str(iTraceInc)//add a incrementor
			iTraceInc+=1
		while(WhichListItem(sTraceName,sExistingTraces)!=-1)//try again, trace name still exist
	endif
	
	//define min and max variable for color scale and marker size
	variable vMaxY, vMinY, vMaxMS, vMinMS
	vMinY = str2num(GetUserData(sPlotName,"","sMinY"))
 	vMaxY = str2num(GetUserData(sPlotName,"","sMaxY"))
 	vMinMS = str2num(GetUserData(sPlotName,"","sMinMS"))
 	vMaxMS = str2num(GetUserData(sPlotName,"","sMaxMS"))
	
	//get variable waves
	wave wSample = $"root:COMBIgor:" + sProject + ":Data:FromMappingGrid:Sample"
	wave wApex1 = $"root:COMBIgor:" + sProject + ":Data:" + sApexLibrary + ":" + sApex1
	wave wApex2 = $"root:COMBIgor:" + sProject + ":Data:" + sApexLibrary + ":" + sApex2
	wave wApex3 = $"root:COMBIgor:" + sProject + ":Data:" + sApexLibrary + ":" + sApex3
	wave wConstant = $"root:COMBIgor:" + sProject + ":Data:" + sConstantLibrary + ":" + sConstantVariable
	wave wColorScale = $"root:COMBIgor:" + sProject + ":Data:" + sColorScaleLibrary + ":" + sColorScaleVariable
	wave wMarkerSize = $"root:COMBIgor:" + sProject + ":Data:" + sMarkerSizeLibrary + ":" + sMarkerSizeVariable
	
	//define loop variables
	variable i, vRow = dimsize(wTernaryWave,0)
	variable vApex1, vApex2, vApex3, vAddValue
	//save beginning row of trace for plotting later
	variable vThisTraceRow = vRow
		
	//go through points
	for(i = 0; i < DimSize(wApex1, 0); i += 1)
		
		//normalize variables
		vApex1 = wApex1[i]/(wApex1[i] + wApex2[i] + wApex3[i])
		vApex2 = wApex2[i]/(wApex1[i] + wApex2[i] + wApex3[i])
		vApex3 = wApex3[i]/(wApex1[i] + wApex2[i] + wApex3[i])
		
		//ensures that value is always added if no constant library has been selected
		vAddValue = 1	
		
		//if constant library has been selected, determine whether values lies within value +- tolerance
		if(stringMatch(sConstantLibrary, "!None"))	
			//for scalar constant value
			if(stringMatch(sConstantDataCategory, "Scalar"))
				if(wConstant[i] < str2num(sConstantValue) + str2num(sConstantTolerance) && wConstant[i] > str2num(sConstantValue) - str2num(sConstantTolerance))
					vAddValue = 1
				else 
					vAddValue = 0
				endif
			elseif(stringMatch(sConstantDataCategory, "Vector"))
				if(wConstant[i][%$sConstantCondition] < str2num(sConstantValue) + str2num(sConstantTolerance) && wConstant[i][%$sConstantCondition] > str2num(sConstantValue) - str2num(sConstantTolerance))
					vAddValue = 1
				else
					vAddValue = 0
				endif
			endif
		endif
		
		//if value is within the range defined for the constant variable, add values to ternary wave
		if(vAddValue == 1)
			Redimension /N = (vRow + 1,-1) wTernaryWave
			wTernaryWave[vRow][0] = wSample[i]
			wTernaryWave[vRow][1] = vApex2 + 0.5*vApex3
			wTernaryWave[vRow][2] = vApex3*sqrt(3)/2
			if(stringMatch(sColorScaleLibrary, "!None"))			
				//for scalar color scale wave
				if(stringMatch(sColorScaleDataCategory, "Scalar"))
					wTernaryWave[vRow][3] = wColorScale[i]
					if(wColorScale[i] > vMaxY)
						vMaxY = wColorScale[i]
					endif
					if(wColorScale[i] < vMinY)
						vMinY = wColorScale[i]
					endif
				//for vector color scale wave
				elseif(stringMatch(sColorScaleDataCategory, "Vector"))
					wTernaryWave[vRow][3] = wColorScale[i][%$sColorScaleCondition]
					if(wColorScale[i][%$sColorScaleCondition] > vMaxY)
						vMaxY = wColorScale[i][%$sColorScaleCondition]
					endif
					if(wColorScale[i][%$sColorScaleCondition] < vMinY)
						vMinY = wColorScale[i][%$sColorScaleCondition]
					endif
				endif
			else 
				wTernaryWave[vRow][3] = 0
			endif	
			//for scalar marker size wave
			if(stringMatch(sMarkerSizeLibrary, "!None"))			
				if(stringMatch(sMarkerSizeDataCategory, "Scalar"))
					wTernaryWave[vRow][4] = wMarkerSize[i]
					if(wMarkerSize[i] > vMaxMS)
						vMaxMS = wMarkerSize[i]
					endif
					if(wMarkerSize[i] < vMinMS)
						vMinMS = wMarkerSize[i]
					endif
				//for vector marker size wave 
				elseif(stringMatch(sMarkerSizeDataCategory, "Vector"))
					wTernaryWave[vRow][4] = wMarkerSize[i][%$sMarkerSizeCondition]
					if(wMarkerSize[i][%$sMarkerSizeCondition] > vMaxMS)
						vMaxMS = wMarkerSize[i][%$sMarkerSizeCondition]
					endif
					if(wMarkerSize[i][%$sMarkerSizeCondition] < vMinMS)
						vMinMS = wMarkerSize[i][%$sMarkerSizeCondition]
					endif
				endif
			else
				wTernaryWave[vRow][4] = 0
			endif
			vRow = vRow+1
		endif
	endfor
 	
	AppendToGraph/L=TernaryGraphVertAxis/B=TernaryGraphHorizAxis wTernaryWave[vThisTraceRow, dimsize(wTernaryWave, 0) - 1][2]/TN=$sTraceName  vs wTernaryWave[vThisTraceRow, dimsize(wTernaryWave, 0) - 1][1]		
	ModifyGraph marker($sTraceName)=str2num(sMarkerStyle), mode($sTraceName)=3
	if(stringMatch(sColorScaleLibrary, "!None"))
		for(i = 0; i < itemsInList(sExistingTraces); i+=1)
			string sThisTrace = stringFromList(i, sExistingTraces)
			ModifyGraph zColor($sTraceName)={wTernaryWave[][3] , vMinY, vMaxY, YellowHot, 0}	
		endfor
	endif
	if(stringMatch(sMarkerSizeLibrary, "!None"))
		for(i = 0; i < itemsInList(sExistingTraces); i+=1)
			sThisTrace = stringFromList(i, sExistingTraces)
			ModifyGraph zMrkSize($sTraceName)={wTernaryWave[][4], vMinMS, vMaxMS, 5, 10}	
		endfor
	else
		ModifyGraph msize=5
	endif
end

//plotting wave in COMBIgor
//the wave note consists of a list of traces information seperated by "$" charecters 
Function/S TernaryPlotter_PlotWave(sOption)
	string sOption //"" if none exist and a new one is needed, "TOP" to try the top window for a plot wave
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//to return
	string sPlotWave = ""
	
	//get display wave from top plot
	if(stringmatch(sOption,"TOP"))//from top plot
		string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
		string sDataWaveName = GetUserData(sWindowName, "", "DataSource")
		if(stringmatch(sDataWaveName,"root:Packages:COMBIgor:DisplayWaves:*"))
			sPlotWave = replaceString("root:Packages:COMBIgor:DisplayWaves:",sDataWaveName,"")
		endif
	endif
	
	//get a new wave
	if(!waveExists($"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave))//not existing, need new
		int vTotalPlotWaves = 0
		do
			vTotalPlotWaves+=1
			sPlotWave = "DisplayWave"+num2str(vTotalPlotWaves)
		while(waveexists($"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave))
		SetDataFolder root:Packages:COMBIgor:
		NewDataFolder/O/S DisplayWaves
		Make/N=(1,5) $sPlotWave
		SetDataFolder $sTheCurrentUserFolder 
	endif
	
	//return plot wave wave
	return sPlotWave
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function TernaryPlotter_DrawMarkerSizeLegend()
	
	//string sMarkerSizeLabel
	
	//get user font preferences
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	int iBold
	if(stringmatch(COMBI_GetGlobalString("sBoldOption","COMBIgor"),"No"))
		iBold=0
	else
		iBold=1
	endif
	
	//
	string sMarkerStyle
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sMarkerSizeLabel = COMBI_GetPluginString(sPluginName,"sMarkerSizeLabel", sProject)
	
	
	NewPanel/W=(150,150,335,285)/N=COMBIOptionSelect as "Select marker style"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 1,textyjust = 1, fsize = 14, save
	DrawText 95, 30, "Marker style:"
	PopupMenu sMarkerStyle, value = "*MARKERPOP*", pos={95, 50}, mode=1, bodyWidth=100, proc=TernaryPlotter_GetMarker
	button bCloseWindow, title="Ok", appearance={native, All}, pos={75, 100}, size={40, 25}, proc=TernaryPlotter_Button, font=sFont, fstyle=1, fColor=(21845, 21845, 21845), fsize=16
	PauseForUser COMBIOptionSelect
	
	NVAR vMarker
	string sMarkerNum = num2str(vMarker)
	killVariables vMarker
	
	//get name of plot
	string sPlotName = Stringfromlist(0,WinList("*", ";","WIN:1"))//topmost plot window
	//doWindow 
		
	//define min and max variable for color scale and marker size
	variable vMaxMS, vMinMS
 	vMinMS = str2num(GetUserData(sPlotName,"","sMinMS"))
 	vMaxMS = str2num(GetUserData(sPlotName,"","sMaxMS"))
	
	//strings to draw
	string sDrawNum1 = GetUserData(sPlotName,"","sMinMS")
	string sDrawNum3 = num2str((vMaxMS-vMinMS)/2 + vMinMS)
	string sDrawNum5 = GetUserData(sPlotName,"","sMaxMS")
	
	//draw
	SetDrawEnv/W=$sPlotName gstart, gname=SizeScale 
	SetDrawEnv/W=$sPlotName xcoord= abs,ycoord= abs ,save
	SetDrawEnv/W=$sPlotName linethick= 0.50, save
	SetDrawEnv/W=$sPlotName textrgb= (0,0,0),fname=sFont, save
	SetDrawEnv/W=$sPlotName textxjust= 1, textyjust = 1, fsize=20, save
	SetDrawEnv/W=$sPlotName fstyle= iBold, save
	DrawLine/W=$sPlotName 150, 143, 150, 320
	DrawText/W=$sPlotName 150, 145, "\K(65535,65535,65535)\\Z26\\k(0,0,0)\\W50"+sMarkerNum
	DrawText/W=$sPlotName 150, 190,"\K(65535,65535,65535)\\Z22\\k(0,0,0)\\W50"+sMarkerNum
	DrawText/W=$sPlotName 150, 235,"\K(65535,65535,65535)\\Z18\\k(0,0,0)\\W50"+sMarkerNum
	DrawText/W=$sPlotName 150, 280,"\K(65535,65535,65535)\\Z14\\k(0,0,0)\\W50"+sMarkerNum
	DrawText/W=$sPlotName 150, 325,"\K(65535,65535,65535)\\Z10\\k(0,0,0)\\W50"+sMarkerNum
	//SetDrawEnv/W=$sPlotName textrgb= (0,0,0), save
	DrawText/W=$sPlotName 100, 325, sDrawNum1
	DrawText/W=$sPlotName 100, 235, sDrawNum3
	DrawText/W=$sPlotName 100, 145, sDrawNum5
	SetDrawEnv/W=$sPlotName textrot = 90
	DrawText/W=$sPlotName 50, 240, COMBIDisplay_GetAxisLabel(sMarkerSizeLabel)
	SetDrawEnv/W=$sPlotName gstop, gname=SizeScale 
end