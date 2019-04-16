#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
//#include <Ternary Diagram>

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Nov 2018 : Original Example Plugin 

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Static StrConstant sPluginName = "PieMaps"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Visualize"
		 "Pie chart maps",/Q, COMBI_PieMaps()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function COMBI_PieMaps()

	//name for plugin panel
	string sWindowName=sPluginName+"_Panel"
	
	//check if initialized, get starting values if so, initialize if not
	string sProject //project to operate within
	string sLibrary//Library to operate on
	string sDataTypes // Data type to operate on
	string sColorTheme // theme to use in plot
	int vDataTypes // how many to plot?

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
		COMBI_GivePluginGlobal(sPluginName,"sDataTypes","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sColorTheme",COMBI_GetGlobalString("sColorOption","COMBIgor"),sProject)
		COMBI_GivePluginGlobal(sPluginName,"vDataTypes","3",sProject)
	endif
	
	//get vlaues of globals to use in this function, mainly panel building
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sDataTypes = COMBI_GetPluginString(sPluginName,"sDataTypes",sProject)
	sColorTheme = COMBI_GetPluginString(sPluginName,"sColorTheme",sProject)
	vDataTypes = COMBI_GetPluginNumber(sPluginName,"vDataTypes",sProject)
	
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_PieMaps_Globals
	
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
	variable vPanelHeight = 120+20*vDataTypes
	variable vPanelWidth = 250
 
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "COMBIgor Pie Chart Maps"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	variable vYValue = 15
	
	//Project select
	DrawText 70,vYValue, "Project:"
	PopupMenu sProject,pos={195,vYValue-10},mode=1,bodyWidth=170,value=COMBI_Projects(),proc=PieMaps_UpdateGlobal,popvalue=sProject
	vYValue+=20
	//Library select
	DrawText 70,vYValue, "Library:"
	PopupMenu sLibrary,pos={195,vYValue-10},mode=1,bodyWidth=170,value=PieMaps_DropList("Libraries"),proc=PieMaps_UpdateGlobal,popvalue=sLibrary
	vYValue+=20
	//number of Data Select
	DrawText 70,vYValue, "Data Types:"
	PopupMenu vDataTypes,pos={195,vYValue-10},mode=1,bodyWidth=170,value="2;3;4;5;6;7;8;9;10;11;12;13;14;15",proc=PieMaps_UpdateGlobal,popvalue=num2str(vDataTypes)
	vYValue+=20
	//Data select
	int iDataType
	for(iDataType=0;iDataType<vDataTypes;iDataType+=1)
		DrawText 70,vYValue, "Data "+num2str(1+iDataType)+":"
		string sPopName = "Data"+num2str(iDataType)
		PopupMenu $sPopName,pos={195,vYValue-10},mode=1,bodyWidth=170,value=PieMaps_DropList("DataTypes"),proc=PieMaps_UpdateGlobal,popvalue=stringfromList(iDataType,sDataTypes)
		vYValue+=20
	endfor
	//Color select
	DrawText 70,vYValue, "Colors:"
	PopupMenu sColorTheme,pos={195,vYValue-10},mode=1,bodyWidth=170,value=ctablist(),proc=PieMaps_UpdateGlobal,popvalue=sColorTheme
	vYValue+=15
	//Do Something button
	button bMakePlot,title="Make Pie Chart Map",appearance={native,All},pos={25,vYValue},size={200,25},proc=PieMaps_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
	vYValue+=25
end

Function PieMaps_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName//name of control, should be also name of global being updated
	Variable popNum//number in list
	String popStr //value selected
	string sProject,sDataTypes, sNewDataTypes =""
	int iDataType
	if(stringmatch("sProject",ctrlName))
		//special place for the project
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	elseif(stringmatch("vDataTypes",ctrlName))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		sDataTypes = COMBI_GetPluginString(sPluginName,"sDataTypes",sProject)
		for(iDataType=0;iDataType<str2num(popStr);iDataType+=1)
			sNewDataTypes = AddListItem(stringfromList(iDataType,sDataTypes),sNewDataTypes,";",inf)
		endfor
		COMBI_GivePluginGlobal(sPluginName,"sDataTypes",sNewDataTypes,sProject)
		COMBI_GivePluginGlobal(sPluginName,"vDataTypes",popStr,sProject)
	elseif(stringmatch(ctrlName,"Data*"))
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
		sDataTypes = COMBI_GetPluginString(sPluginName,"sDataTypes",sProject)
		int iThisDataType = str2num(ctrlName[4,(strlen(ctrlName)-1)])
		for(iDataType=0;iDataType<itemsInList(sDataTypes);iDataType+=1)
			if(iDataType==iThisDataType)
				sNewDataTypes = AddListItem(popStr,sNewDataTypes,";",inf)
			else
				sNewDataTypes = AddListItem(stringfromList(iDataType,sDataTypes),sNewDataTypes,";",inf)
			endif
		endfor
		COMBI_GivePluginGlobal(sPluginName,"sDataTypes",sNewDataTypes,sProject)
	else 
		//store the global in based on the name of the control sending it
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	//reload panel
	COMBI_PieMaps()
end

Function/S PieMaps_DropList(sOption)
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

Function PieMaps_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	string sColorTheme = COMBI_GetPluginString(sPluginName,"sColorTheme",sProject)
	string sDataTypes = COMBI_GetPluginString(sPluginName,"sDataTypes",sProject)
	
	//if button "bMakePlot" was pressed
	if(stringmatch("bMakePlot",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "PieMaps_MakePlot(\""+sProject+"\",\""+sLibrary+"\",\""+sDataTypes+"\",\""+sColorTheme+"\")"
		endif
		//pass to programatic function
		PieMaps_MakePlot(sProject,sLibrary,sDataTypes,sColorTheme)
	endif

end

//example function used to do something, called by the button function
Function PieMaps_MakePlot(sProject,sLibrary,sDataTypes,sColorTheme)
	string sProject,sLibrary,sDataTypes,sColorTheme
	
	//get plotting wave 
	string sDimList=""
	int iDataType
	for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)
		sDimList = AddListItem("1",sDimList,";",inf)
	endfor
	
	wave wMapppingGrid = $Combi_DataPath(sProject,-2)
	
	//make plotting wave for markers
	string sPlotWave = COMBI_Add2PlotWave(sProject,sLibrary,sDataTypes,sDimList,0,-1,"")
	wave wPlotWave = $"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave
	string sWaveNote = note(wPlotWave)
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	variable vLibraryWidth = COMBI_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = COMBI_GetGlobalNumber("vLibraryHeight",sProject)
	string sAllX = COMBI_LibraryQualifiers(sProject,1)
	string sAllY = COMBI_LibraryQualifiers(sProject,2)
	int vTotalXVals = itemsinlist(sAllX)
	int vTotalYVals = itemsinlist(sAllY)
	variable vMinX = str2num(stringfromlist(0, sAllX)) 
	variable vMaxX = str2num(stringfromlist(vTotalXVals-1, sAllX)) 
	variable vMinY = str2num(stringfromlist(0, sAllY)) 
	variable vMaxY = str2num(stringfromlist(vTotalYVals-1, sAllY)) 
	variable vmmPerPieX = ((vMaxX-vMinX)/vTotalXVals)
	variable vmmPerPieY = ((vMaxY-vMinY)/vTotalYVals)
	variable vPerPieX = vmmPerPieX/vLibraryWidth
	variable vPerPieY = vmmPerPieY/vLibraryHeight
	variable vPieRadius  = min(vPerPieX,vPerPieY)
	
	//norm plot wave 
	int iRow
	variable vTotal
	for(iRow=0;iRow<dimsize(wPlotWave,0);iRow+=1)
		vTotal=0
		for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)
			vTotal+=wPlotWave[iRow][iDataType]
		endfor
		wPlotWave[iRow][]=wPlotWave[iRow][q]/vTotal
	endfor
	
		//new plot window
	string sPlotWindow = sLibrary+"_"+replacestring(";",sDataTypes,"_")+"PieMap"
	Killwindow/Z $sPlotWindow
	sPlotWindow = Combi_NewGizmo(sPlotWindow)
	ModifyGizmo/N=$sPlotWindow stopUpdates
	SetWindow $sPlotWindow userdata(DataSource)="root:Packages:COMBIgor:DisplayWaves:"+sPlotWave
	SetWindow $sPlotWindow hook(kill)=COMBIDispaly_KillPlotData
	
	//Appned to Gizmo
	
	ModifyGizmo/N=$sPlotWindow opName=LibraryScale, operation=scale,data={1.3,1.3,1}
	
	//axis direction
	int bXAxisFlip = COMBI_GetGlobalNumber("bXAxisFlip",sProject)
	int bYAxisFlip = COMBI_GetGlobalNumber("bYAxisFlip",sProject)
	int cXAxisDir,cYAxisDir
	if(bXAxisFlip==1)
		cXAxisDir = -1
	else
		cXAxisDir = 1
	endif
	if(bYAxisFlip==1)
		cYAxisDir = -1
	else
	 	cYAxisDir = 1
	endif
	
	
	AppendToGizmo/D Axes=Axes,name=XAxis1
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ -1,axisType,1048576}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,axisRange,1*cYAxisDir,-1*cYAxisDir,0,-1*cYAxisDir,-1*cYAxisDir,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,axisMinValue,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,axisMaxValue,vLibraryWidth}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,ticks,3}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,tickScaling,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,fontName,sFont
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,tickEnable,0,vLibraryWidth}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,labelOffset,0,0.2,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis1,objectType=Axes,property={ 0,fontScaleFactor,1}
	
	AppendToGizmo/D Axes=Axes,name=XAxis2
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ -1,axisType,1048576}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,axisRange,1*cYAxisDir,1*cYAxisDir,0,-1*cYAxisDir,1*cYAxisDir,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,axisMinValue,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,axisMaxValue,vLibraryWidth}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,ticks,3}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,tickScaling,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,fontName,sFont
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,tickEnable,0,vLibraryWidth}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,labelOffset,0,0,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=XAxis2,objectType=Axes,property={ 0,fontScaleFactor,1}

	
	AppendToGizmo/D Axes=Axes,name=YAxis1
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ -1,axisType,1048576}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,axisRange,1*cXAxisDir,1*cXAxisDir,0,1*cXAxisDir,-1*cXAxisDir,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,axisMinValue,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,axisMaxValue,vLibraryHeight}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,ticks,3}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,tickScaling,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,fontName,sFont
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,tickEnable,0,vLibraryHeight}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,labelOffset,0.15,0.1,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis1,objectType=Axes,property={ 0,fontScaleFactor,1}

	
	AppendToGizmo/D Axes=Axes,name=YAxis2
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ -1,axisType,1048576}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,axisRange,-1*cXAxisDir,1*cXAxisDir,0,-1*cXAxisDir,-1*cXAxisDir,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,axisMinValue,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,axisMaxValue,vLibraryHeight}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,ticks,3}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,tickScaling,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,fontName,sFont
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,tickEnable,0,vLibraryHeight}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,labelOffset,-0.05,0.1,0}
	ModifyGizmo/N=$sPlotWindow ModifyObject=YAxis2,objectType=Axes,property={ 0,fontScaleFactor,1}


	//pies markers
	for(iRow=0;iRow<dimsize(wPlotWave,0);iRow+=1)
		variable vThisAngle = 0
		for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)
			string sWedgeName = stringFromList(iDataType,sDataTypes)+"_"+num2str(iRow)
			string sThisColor = replacestring(")",replacestring("(",COMBI_GetUniqueColor(iDataType+1,itemsinlist(sDataTypes)),""),"")
			variable vThisR = str2num(stringfromlist(0,sThisColor,","))/65535
			variable vThisG = str2num(stringfromlist(1,sThisColor,","))/65535
			variable vThisB = str2num(stringfromlist(2,sThisColor,","))/65535
			variable vThisX = (wMapppingGrid[iRow][1]-vLibraryWidth/2)/(vLibraryWidth/2)*cXAxisDir
			variable vThisY = (wMapppingGrid[iRow][2]-vLibraryHeight/2)/(vLibraryHeight/2)*cYAxisDir
			AppendToGizmo/D/N=$sPlotWindow pieWedge=$sWedgeName
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ rMax,vPieRadius}
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ zMin,0}
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ zMax,.01}
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ colorType,1}
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ translate,vThisX,vThisY,0}
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={	topRGBA,vThisR,vThisG,vThisB,1}
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ startAngle,vThisAngle}
			vThisAngle+=360*wPlotWave[iRow][iDataType]
			ModifyGizmo/N=$sPlotWindow ModifyObject=$sWedgeName,objectType=pieWedge,property={ endAngle,vThisAngle}
		endfor
	endfor
	
	//axis labels
	TextBox/W=$sPlotWindow/C/N=XAxis1/F=0/A=MC/X=0.00/Y=-40.00 "\\Z14\\F'"+sFont+"'\\K(0,0,0)x(mm)"
	TextBox/W=$sPlotWindow/C/N=XAxis2/F=0/A=MC/X=0.00/Y=40.00 "\\Z14\\F'"+sFont+"'\\K(0,0,0)x(mm)"
	TextBox/W=$sPlotWindow/C/N=YAxis1/F=0/A=MC/X=-40.00/Y=0.00/O=90 "\\Z14\\F'"+sFont+"'\\K(0,0,0)y(mm)"
	TextBox/W=$sPlotWindow/C/N=YAxis2/F=0/A=MC/X=40.00/Y=0.00/O=-90 "\\Z14\\F'"+sFont+"'\\K(0,0,0)y(mm)"
	//key
	//key
	variable vKeyTransDelta = 60/(itemsinlist(sDataTypes)-1)
	vKeyTransDelta = min(20,vKeyTransDelta)
	variable vKeyWide = (itemsinlist(sDataTypes)-1)*vKeyTransDelta
	for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)
		string sThisDataType = stringfromlist(iDataType,sDataTypes)
		sThisColor = COMBI_GetUniqueColor(iDataType+1,itemsinlist(sDataTypes))
		TextBox/W=$sPlotWindow/C/N=$sThisDataType/F=0/A=MC/X=(-vKeyWide/2+iDataType*vKeyTransDelta)/Y=45 "\\Z14\\F'"+sFont+"'\\K"+sThisColor+sThisDataType
	endfor
	
	//MoveWindow/W=$sPlotWindow/M 0,0,(15*(vLibraryWidth/vLibraryHeight)),15


//	//key
//	variable vKeyTransDelta = 2/(itemsinlist(sDataTypes)-1)
//	variable vKeyWide = (itemsinlist(sDataTypes)-1)*vKeyTransDelta
//	ModifyGizmo opName=translate4, operation=translate,data={(-1.25-vKeyWide/2),1.4,0}
//	for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)
//		string sThisDataType = stringfromlist(iDataType,sDataTypes)
//		sThisColor = replacestring(")",replacestring("(",COMBI_GetUniqueColor(iDataType+1,itemsinlist(sDataTypes)),""),"")
//		vThisR = str2num(stringfromlist(0,sThisColor,","))/65535
//		vThisG = str2num(stringfromlist(1,sThisColor,","))/65535
//		vThisB = str2num(stringfromlist(2,sThisColor,","))/65535
//		AppendToGizmo/N=$sPlotWindow/D string=sThisDataType,name=$sThisDataType
//		ModifyGizmo/N=$sPlotWindow opName=$"translate"+num2str(5+iDataType), operation=translate,data={vKeyTransDelta,0,0}
//		ModifyGizmo/N=$sPlotWindow ModifyObject=$sThisDataType,objectType=string,property={ colorType,1}
//		ModifyGizmo/N=$sPlotWindow ModifyObject=$sThisDataType,objectType=string,property={ color,vThisR,vThisG,vThisB,1}
//		Execute "ModifyGizmo/N="+sPlotWindow+" ModifyObject="+sThisDataType+",objectType=string,property={font,\""+sFont+"\"}"
//	endfor
	ModifyGizmo/N=$sPlotWindow resumeUpdates
end



