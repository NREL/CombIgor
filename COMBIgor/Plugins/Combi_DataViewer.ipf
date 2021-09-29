#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Imran Khan _ Feb 2021 : An alternative data viewer similar to the 'Display' tool

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Static StrConstant sPluginName = "DataViewer"				//Name of Plugin

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Menu "COMBIgor"																//This builds the drop-down menu for this plugin
	SubMenu "Plugins"
		 "Data Viewer",/Q, COMBI_DataViewer()
	end
end
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------

function COMBI_DataViewer()				//This function is run when the user selects the Plugin from the COMBIgor drop down menu once activated. This will build the plugin panel that the user interacts with.
	string sWindowName=sPluginName+"_Panel"				//name for plugin panel
	
	//check if initialized, get starting values if so, initialize if not
	string sProject 	//project to operate within
	string sLibrary	//Library to operate on
	string sDataW, sDataT, sDataMap1, sDataMap2 		//Library data for plotting...
	string sScaleW, sScaleT, sScaleM1, sScaleM2
	string sFirstSample, sLastSample, sGA1Min, sGA1Max, sGA2Min,sGA2Max, sSamplePointRow, sSamplePointColumn
	string sXmin, sXmax, sYmin, sYmax 			//plotting variables
	variable vXmin, vXmax, vYmin, vYmax 			//plotting variables
	string sM1min, sM1max, sM2min, sM2max 			//plotting variables
	variable vM1min, vM1max, vM2min, vM2max 			//plotting variables      
	int isample

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
		COMBI_GivePluginGlobal(sPluginName,"sDataW","...",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataT","...",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataMap1","...",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataMap2","...",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sScaleW","Linear",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sScaleT","Linear",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sScaleM1","Linear",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sScaleM2","Linear",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFirstSample","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLastSample",COMBI_GetGlobalString("vTotalSamples", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGA1Min","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGA2Min","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGA1Max",COMBI_GetGlobalString("vTotalRows", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGA2Max",COMBI_GetGlobalString("vTotalColumns", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sSamplePointRow","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sSamplePointColumn","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sHData","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sVData","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sCData","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXmin","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXmax","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sYmin","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sYmax","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sM1min","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sM1max","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sM2min","A",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sM2max","A",sProject)
	endif
	
	//Library values
	variable vLibraryWidth = COMBI_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = COMBI_GetGlobalNumber("vLibraryHeight",sProject)
	variable vTotalRows = COMBI_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = COMBI_GetGlobalNumber("vTotalColumns",sProject)
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	variable vColumnSpacing = COMBI_GetGlobalNumber("vColumnSpacing",sProject)
	variable vRowSpacing = COMBI_GetGlobalNumber("vRowSpacing",sProject)
	
	//get values of globals to use in this function, mainly panel building
	sProject = COMBI_GetPluginString(sPluginName,"sProject",sProject)
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sDataW = COMBI_GetPluginString(sPluginName,"sDataW",sProject)
	sDataT = COMBI_GetPluginString(sPluginName,"sDataT",sProject)
	sDataMap1 = COMBI_GetPluginString(sPluginName,"sDataMap1",sProject)
	sDataMap2 = COMBI_GetPluginString(sPluginName,"sDataMap2",sProject)
	sScaleW = COMBI_GetPluginString(sPluginName,"sScaleW",sProject)
	sScaleT = COMBI_GetPluginString(sPluginName,"sScaleT",sProject)
	sScaleM1 = COMBI_GetPluginString(sPluginName,"sScaleM1",sProject)
	sScaleM2 = COMBI_GetPluginString(sPluginName,"sScaleM2",sProject)
	sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	sGA1Min = COMBI_GetPluginString(sPluginName,"sGA1Min",sProject)
	sGA1Max = COMBI_GetPluginString(sPluginName,"sGA1Max",sProject)
	sGA2Min = COMBI_GetPluginString(sPluginName,"sGA2Min",sProject)
	sGA2Max = COMBI_GetPluginString(sPluginName,"sGA2Max",sProject)	
	sSamplePointRow = COMBI_GetPluginString(sPluginName,"sSamplePointRow",sProject)
	sSamplePointColumn = COMBI_GetPluginString(sPluginName,"sSamplePointColumn",sProject)
	sXmin = COMBI_GetPluginString(sPluginName,"sXmin",sProject)
	sXmax = COMBI_GetPluginString(sPluginName,"sXmax",sProject)
	sYmin = COMBI_GetPluginString(sPluginName,"sYmin",sProject)
	sYmax = COMBI_GetPluginString(sPluginName,"sYmax",sProject)
	sM1min = COMBI_GetPluginString(sPluginName,"sM1min",sProject)
	sM1max = COMBI_GetPluginString(sPluginName,"sM1max",sProject)
	sM2min = COMBI_GetPluginString(sPluginName,"sM2min",sProject)
	sM2max = COMBI_GetPluginString(sPluginName,"sM2max",sProject)
	
		
	//get trace numbers
	int iFirstSample = str2num(sFirstSample)-1				//index of first sample
	int iLastSample = str2num(sLastSample)-1					//index of last sample
	
	//get the globals wave for use in panel building, mainly set varaible controls
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_DataViewer_Globals
	wave/T twCGlobals= root:Packages:COMBIgor:COMBI_Globals
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	
	//make panel position if old existed, kill if open already
	PauseUpdate; Silent 1 // pause for building window...
	variable vWinLeft = 10
	variable vWinTop = 0
	string sAllWindows = WinList(sWindowName,";","")
	if(strlen(sAllWindows)>1)
		GetWindow/Z $sWindowName wsize
		vWinLeft = V_left
		vWinTop = V_top
		KillWindow/Z $sWindowName
	endif
	
	//dimensions of panel
	variable vPanelHeight 	= 725
	variable vPanelWidth 	= 675
 
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "COMBIgor Data Viewer Plugin"
	ModifyPanel/W=$sWindowName cbRGB=(36385,38398,45535)
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	variable vXValue1, vXValue2, vYValue
	
	//Project select
	vXValue1 = 55; vXValue2 = 210; vYValue = 15
	DrawText vXValue1,vYValue, "Project:"
	PopupMenu sProject,pos={vXValue2,vYValue-10},mode=1,bodyWidth=200,value=COMBI_Projects(),proc=DataViewer_UpdateGlobal,popvalue=sProject
	//Library select
	DrawText vXValue1+255,vYValue, "Library:"
	PopupMenu sLibrary,pos={vXValue2+255,vYValue-10},mode=1,bodyWidth=200,value=DataViewer_DropList("Libraries",2),proc=DataViewer_UpdateGlobal,popvalue=sLibrary
	
	//Vector Plotting range
	vXValue1 = 580; vXValue2 = 620; vYValue = 200
	DrawText vXValue1,vYValue, "Samples:"
	vYValue+=20
	DrawText vXValue2-10,vYValue, "to"
	PopupMenu sFirstSample,pos={vXValue1-40,vYValue-10},mode=1,bodyWidth=40,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),0),proc=DataViewer_UpdateGlobal,popvalue=sFirstSample
	SetVariable sFirstSampleF,title=" ",pos={vXValue1-30,vYValue-9},size={26,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sFirstSample][%$sProject]
	PopupMenu sLastSample,pos={vXValue2-20,vYValue-10},mode=1,bodyWidth=40,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),0),proc=DataViewer_UpdateGlobal,popvalue=sLastSample
	SetVariable sLastSampleF,title=" ",pos={vXValue2-10,vYValue-9},size={26,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sLastSample][%$sProject]
	vYValue+=25
	DrawText vXValue1,vYValue, "Rows:"
	vYValue+=20
	DrawText vXValue2-15,vYValue, "to"
	PopupMenu sGA1Min,pos={vXValue1-40,vYValue-10},mode=1,bodyWidth=40,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),3),proc=DataViewer_UpdateGlobal,popvalue=sGA1Min
	PopupMenu sGA1Max,pos={vXValue2-20,vYValue-10},mode=1,bodyWidth=40,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),3),proc=DataViewer_UpdateGlobal,popvalue=sGA1Max
	vYValue+=25
	DrawText vXValue1,vYValue, "Columns:"
	vYValue+=20
	DrawText vXValue2-15,vYValue, "to"
	PopupMenu sGA2Min,pos={vXValue1-40,vYValue-10},mode=1,bodyWidth=40,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),4),proc=DataViewer_UpdateGlobal,popvalue=sGA2Min
	PopupMenu sGA2Max,pos={vXValue2-20,vYValue-10},mode=1,bodyWidth=40,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),4),proc=DataViewer_UpdateGlobal,popvalue=sGA2Max
	
	//Vector Plot Options
	vXValue1 = 640; vXValue2 = 715; vYValue = 65
	DrawText vXValue1+25,vYValue, "Horizontal axis data:"	
	vYValue+=7	
	PopupMenu sDataW,pos={vXValue1-25,vYValue},mode=1,bodyWidth=135,value=" ;"+DataViewer_DropList("DataTypes",2),proc=DataViewer_UpdateGlobal,popvalue=sDataW
	vYValue+=18
	SetVariable svXmin, title=" ",pos={vXValue1-110,vYValue+3},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sXmin][%$sProject]
	DrawText vXValue1-67,vYValue+9, "to"
	SetVariable svXmax, title=" ",pos={vXValue1-65,vYValue+3},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sXmax][%$sProject]
	PopupMenu sScaleW,pos={vXValue1-25,vYValue},mode=1,bodyWidth=60,value="Linear;Log",proc=DataViewer_UpdateGlobal,popvalue=sScaleW
	vYValue+=35
	DrawText vXValue1+25,vYValue, "Vertical axis Data:"				
	vYValue+=7	
	PopupMenu sDataT,pos={vXValue1-25,vYValue},mode=1,bodyWidth=135,value=" ;"+DataViewer_DropList("DataTypes",2),proc=DataViewer_UpdateGlobal,popvalue=sDataT
	vYValue+=18
	SetVariable svYmin, title=" ",pos={vXValue1-110,vYValue+3},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sYmin][%$sProject]
	DrawText vXValue1-67,vYValue+9, "to"
	SetVariable svYmax, title=" ",pos={vXValue1-65,vYValue+3},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sYmax][%$sProject]
	PopupMenu sScaleT,pos={vXValue1-25,vYValue},mode=1,bodyWidth=60,value="Linear;Log",proc=DataViewer_UpdateGlobal,popvalue=sScaleT
	
	//Mapping Data Field
	vXValue1 = 70;		vYValue = 370
	DrawText vXValue1,vYValue, "Map Data 1:"
	PopupMenu sDataMap1,pos={vXValue1+50,vYValue-10},mode=1,bodyWidth=100,value=" ;"+DataViewer_DropList("DataTypes",1),proc=DataViewer_UpdateGlobal,popvalue=sDataMap1
	SetVariable svM1min, title=" ",pos={vXValue1+116,vYValue-7},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sM1min][%$sProject]
	DrawText vXValue1+156,vYValue, "to"
	SetVariable svM1max, title=" ",pos={vXValue1+160,vYValue-7},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sM1max][%$sProject]
	PopupMenu sScaleM1,pos={vXValue1+200,vYValue-10},mode=1,bodyWidth=60,value="Linear;Log",proc=DataViewer_UpdateGlobal,popvalue=sScaleM1
	vXValue1 = 400;		vYValue = 370
	DrawText vXValue1,vYValue, "Map Data 2:"
	PopupMenu sDataMap2,pos={vXValue1+50,vYValue-10},mode=1,bodyWidth=100,value=" ;"+DataViewer_DropList("DataTypes",1),proc=DataViewer_UpdateGlobal,popvalue=sDataMap2
	SetVariable svM2min, title=" ",pos={vXValue1+116,vYValue-7},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sM2min][%$sProject]
	DrawText vXValue1+156,vYValue, "to"
	SetVariable svM2max, title=" ",pos={vXValue1+160,vYValue-7},size={30,30},fsize=9,live=1,noproc,font=sFont,value=twGlobals[%sM2max][%$sProject]
	PopupMenu sScaleM2,pos={vXValue1+200,vYValue-10},mode=1,bodyWidth=60,value="Linear;Log",proc=DataViewer_UpdateGlobal,popvalue=sScaleM2

	//Individual Point Data **************************************************************************************************************
	vXValue1 = 265;		vYValue = 670
	string sGA1,sGA2
	
	wave wColor1 = $Combi_DataPath(sProject,1)+sLibrary+":"+sDataMap1
	wave wColor2 = $Combi_DataPath(sProject,1)+sLibrary+":"+sDataMap2  	
	sGA1 = GetDimLabel(wMappingGrid,1,3)			//row
	sGA2 = GetDimLabel(wMappingGrid,1,4)			//column

	DrawRrect vXValue1-140, vYValue-20, vXValue1+280, vYValue+50 
	DrawText vXValue1+10,vYValue, "\f05Individual Point Data:"
	DrawText vXValue1+100,vYValue, "Sample  Row:"
	PopupMenu sSamplePointRow,pos={vXValue1+100,vYValue-10},mode=1,bodyWidth=45,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),3),proc=DataViewer_UpdateGlobal,popvalue=sSamplePointRow
	DrawText vXValue1+210,vYValue, "Column:"	
	PopupMenu sSamplePointColumn,pos={vXValue1+210,vYValue-10},mode=1,bodyWidth=45,value=";"+COMBI_LibraryQualifiers(DataViewer_GetString("sProject","COMBIgor"),4),proc=DataViewer_UpdateGlobal,popvalue=sSamplePointColumn
	
	int iSampleP = vTotalColumns * (str2num(sSamplePointRow) - 1) + (str2num(sSamplePointColumn) - 1)
	vYValue+=20
	if(waveexists(wColor1))
		DrawText vXValue1+150,vYValue, "\Z15"+COMBIDisplay_GetAxisLabel(sDataMap1)+" :\t\K(39321,1,1)"+num2str(wColor1[iSampleP])
	endif
	vYValue+=15
	if(waveexists(wColor2))
		DrawText vXValue1+150,vYValue, "\Z15"+COMBIDisplay_GetAxisLabel(sDataMap2)+" :\t\K(39321,1,1)"+num2str(wColor2[iSampleP])
	endif
	
	//Draw mapping plots **************************************************************************************************************
	//get the waves
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	string sHData, sVData, sCScale
	sHData = getdimLabel(wMappingGrid,1,1)		//format as a mm map
	sVData = getdimLabel(wMappingGrid,1,2)		//format as a mm map
	wave wHWave = $COMBI_DataPath(sProject,1)+"FromMappingGrid:"+sHData  
	wave wVWave = $COMBI_DataPath(sProject,1)+"FromMappingGrid:"+sVData

	// Mapping plot options
	variable vMaxH,vMinH,vMaxV,vMinV, vMaxC, vMinC, vHDelta, vVDelta
	string sHAxis, sVAxis 
	int vTicksH, vTicksV
	vMaxH = vLibraryWidth;						vMinH = 0
	vMaxV = vLibraryHeight;						vMinV = 0
	sHAxis = "x (mm)";							sVAxis = "y (mm)"
	vTicksH = floor(vLibraryWidth/5);		vTicksV = floor(vLibraryHeight/5)
	// Mapping plot 1
	vXValue1 = 10; vYValue = 380
	if(stringmatch(sM1min,"A"))
		vMinC = wavemin(wColor1)
	else
		vMinC = str2num(sM1min)
	endif
	if(stringmatch(sM1max,"A"))
		vMaxC = wavemax(wColor1)
	else
		vMaxC = str2num(sM1max)
	endif	
	if(waveexists(wColor1))						
		Display/HOST=$sWindowName/W=(vXValue1,vYValue,vXValue1+250,vYValue+250)/N=MAP1_Plot wVWave[] vs wHWave[]
		ModifyGraph/W=$sWindowName#MAP1_Plot mode=3, marker=16, mirror=2
		Label left sVAxis;						Label bottom sHAxis
		SetAxis left vMaxV,vMinV;				SetAxis bottom vMinH,vMaxH
		ModifyGraph/W=$sWindowName#MAP1_Plot width=200,height=200, fsize=12,font=sFont
		ModifyGraph/W=$sWindowName#MAP1_Plot nticks(left)=vTicksV,nticks(bottom)=vTicksH, tick=3
		ModifyGraph/W=$sWindowName#MAP1_Plot gbRGB=(50000,50000,50000), wbRGB=(49151,60031,65535)
		ModifyGraph/W=$sWindowName#MAP1_Plot margin(left)=40,margin(bottom)=40,margin(right)=80,margin(top)=20,lblLatPos=-20
		ModifyGraph/W=$sWindowName#MAP1_Plot zColor={wColor1,vMinC,vMaxC,Rainbow,0}
		ColorScale/C/N=text0 COMBIDisplay_GetAxisLabel(sDataMap1)
		ColorScale/C/N=text0/B=1/F=0/A=RC/X=-35.00/Y=0.00 width=10,heightPct=100,tickLen=0.00,tickThick=0.00, lblMargin=-5, lblRot=180, fsize=12
		if(stringmatch(sScaleM1,"Log"))
			ColorScale/C/N=text0 log=1,minor=1,logLTrip=0.1
			ModifyGraph/W=$sWindowName#MAP1_Plot logZColor=1
		else
			ModifyGraph/W=$sWindowName#MAP1_Plot logZColor=0
		endif
		ModifyGraph/W=$sWindowName#MAP1_Plot rgb(y_mm[iSampleP])=(65535,65535,65535)   
		ModifyGraph/W=$sWindowName#MAP1_Plot mrkStrokeRGB(y_mm[iSampleP])=(0,0,0)
	else
		DrawText vXValue1+200,vYValue+100, "\K(39321,1,1)Select Library:Data to plot !"
	endif
	// Mapping plot 2
	vXValue1 = 340;	vYValue = 380
	if(stringmatch(sM2min,"A"))
		vMinC = wavemin(wColor2)
	else
		vMinC = str2num(sM2min)
	endif
	if(stringmatch(sM2max,"A"))
		vMaxC = wavemax(wColor2)
	else
		vMaxC = str2num(sM2max)
	endif	
	if(waveexists(wColor2))						
		Display/HOST=$sWindowName/W=(vXValue1,vYValue,vXValue1+250,vYValue+250)/N=MAP2_Plot wVWave[] vs wHWave[]
		ModifyGraph/W=$sWindowName#MAP2_Plot mode=3, marker=16, mirror=2
		Label left sVAxis;						Label bottom sHAxis
		SetAxis left vMaxV,vMinV;				SetAxis bottom vMinH,vMaxH
		ModifyGraph/W=$sWindowName#MAP2_Plot width=200,height=200, fsize=12,font=sFont
		ModifyGraph/W=$sWindowName#MAP2_Plot nticks(left)=vTicksV,nticks(bottom)=vTicksH, tick=3
		ModifyGraph/W=$sWindowName#MAP2_Plot gbRGB=(50000,50000,50000), wbRGB=(49151,60031,65535)
		ModifyGraph/W=$sWindowName#MAP2_Plot margin(left)=40,margin(bottom)=40,margin(right)=80,margin(top)=20
		ModifyGraph/W=$sWindowName#MAP2_Plot zColor={wColor2,vMinC,vMaxC,Rainbow,0}
		ColorScale/C/N=text0 COMBIDisplay_GetAxisLabel(sDataMap2)
		ColorScale/C/N=text0/B=1/F=0/A=RC/X=-35.00/Y=0.00 width=10,heightPct=100,tickLen=0.00,tickThick=0.00, lblMargin=-5, lblRot=180, fsize=12
		if(stringmatch(sScaleM2,"Log"))
			ColorScale/C/N=text0 log=1,minor=1,logLTrip=0.1
			ModifyGraph/W=$sWindowName#MAP2_Plot logZColor=1
		else
			ModifyGraph/W=$sWindowName#MAP2_Plot logZColor=0
		endif
		ModifyGraph/W=$sWindowName#MAP2_Plot rgb(y_mm[iSampleP])=(65535,65535,65535)
		ModifyGraph/W=$sWindowName#MAP2_Plot mrkStrokeRGB(y_mm[iSampleP])=(0,0,0)
	else
		DrawText vXValue1+200,vYValue+100, "\K(39321,1,1)Select Library:Data to plot !"
	endif
	 	
	//*************************************************************************************************************************************
	//Draw Vector Plot **********************************************************************************************************************
	vXValue1 = 10;		vYValue=55
	int iTotalTraces = 0
	variable vGA1Min, vGA1Max, vGA2Min, vGA2Max
	vGA1Min = str2num(sGA1Min)
	vGA1Max = str2num(sGA1Max)
	vGA2Min = str2num(sGA2Min)
	vGA2Max = str2num(sGA2Max)
	
	wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataW
	wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataT
	if(waveexists(wXWave) & waveexists(wYWave))				//Graph Window for Vector Data		
		variable vGA1, vGA2
		for(iSample=(iFirstSample);iSample<=iLastSample;iSample+=1)    //iSample is the index of sample, i.e. iSample = SampleNo - 1;
			vGA1 = wMappingGrid[iSample][3]
			vGA2 = wMappingGrid[iSample][4]
			if(vGA1>=vGA1Min&&vGA1<=vGA1Max) 	// within GA1(row) range
				if(vGA2>=vGA2Min&&vGA2<=vGA2Max)		// within GA2(column) range
					if(iTotalTraces==0)
						Display/HOST=$sWindowName/W=(vXValue1,vYValue,vXValue1+510,vYValue+295)/N=Vector_Plot wYWave[iSample][] vs wXWave[iSample][]
						iTotalTraces+=1
					elseif(iTotalTraces>0)
						AppendToGraph/W=$sWindowName#Vector_Plot wYWave[iSample][] vs wXWave[iSample][]
						iTotalTraces+=1
					endif
				endif
			endif
		endfor
		if(iTotalTraces!=0)
			ModifyGraph/W=$sWindowName#Vector_Plot gbRGB=(50000,50000,50000), wbRGB=(65535,60076,49151), gFont=sfont, gfSize=10
			ModifyGraph/W=$sWindowName#Vector_Plot tick=1,mirror=2,grid=1,zero=4,zero=4, lsize=2
			Label/W=$sWindowName#Vector_Plot left "\Z14"+COMBIDisplay_GetAxisLabel(sDataT)
			Label/W=$sWindowName#Vector_Plot bottom "\Z14"+COMBIDisplay_GetAxisLabel(sDataW)
			ModifyGraph/W=$sWindowName#Vector_Plot margin(left)=50,margin(bottom)=45,margin(right)=10,margin(top)=0,lblmargin=3
			if(stringmatch(sScaleW,"Log"))
				ModifyGraph/W=$sWindowName#Vector_Plot log(bottom)=1
			endif
			if(stringmatch(sScaleT,"Log"))
				ModifyGraph/W=$sWindowName#Vector_Plot log(left)=1
			endif
			DoUpdate
			//Color the traces
			ColorTab2Wave Rainbow
			wave/I/U M_colors
			string sPlotName = sWindowName+"#Vector_Plot"
			string sAllTraces = TraceNameList(sPlotName,";",1)				//all traces on plot
			variable vTraceInk=(dimsize(M_colors,0)-1)/(iTotalTraces)
			int iTrace, vTraceCount=0, iColor
			if(itemsinlist(sAllTraces)!=0)
				for(iTrace=0;iTrace<=iTotalTraces;iTrace+=1)
					string sThisTrace = stringfromlist(iTrace,sAllTraces)				//get trace information
					iColor = trunc(vTraceCount*vTraceInk)
					ModifyGraph/W=$sWindowName#Vector_Plot rgb($sThisTrace)=(M_colors[iColor][0],M_colors[iColor][1],M_colors[iColor][2])
					vTraceCount+=1
				endfor	
			endif
			killwaves/z M_colors
			
			GetAxis/Q/W=$sWindowName#Vector_Plot left					// Setting the vertical axis range
			if(stringmatch(sYmin,"A"))
				vYmin = V_min
			else
				vYmin = str2num(sYmin)
			endif
			if(stringmatch(sYmax,"A"))
				vYmax = V_max
			else
				vYmax = str2num(sYmax)
			endif
			SetAxis/W=$sWindowName#Vector_Plot left, vYmin, vYmax
			
			GetAxis/Q/W=$sWindowName#Vector_Plot bottom					// Setting the horizontal axis range
			if(stringmatch(sXmin,"A"))
				vXmin = V_min
			else
				vXmin = str2num(sXmin)
			endif
			if(stringmatch(sXmax,"A"))
				vXmax = V_max
			else
				vXmax = str2num(sXmax)
			endif
			SetAxis/W=$sWindowName#Vector_Plot bottom, vXmin, vXmax
			
		else
			DrawText 250,vYValue+150, "\K(39321,1,1)Invalid data range to plot!"
		endif
	else
		DrawText 250,vYValue+150, "\K(39321,1,1)Select Library:Data to plot!"
	endif
	
	
	//Buttons to do things !!! *******************************************************************************************************
	vXValue1 = 190;		vYValue=30
	button bRefreshAction,title="Refresh All",appearance={native,All},pos={vXValue1,vYValue},size={130,20},proc=DataViewer_Button,font=sFont,fstyle=1,fColor=(36873,14755,58982),fsize=12
	
end


//This function will update the globals when a drop-down is updated on the panel. It's fairly general and shouldn't need to be edited much.
Function DataViewer_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
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
	COMBI_DataViewer()
end

function/S DataViewer_GetString(sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get twCOMBI_PluginGlobals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_DataViewer_Globals
	
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return "NAG"
	endif
	
	//return value
	return twGlobals[%$sGlobal2Read][%$sFolder]
end


//This function is used to grab the info from the project to return in the pop-up menu. function to return drop downs of Libraries for panel
function/S DataViewer_DropList(sOption, iDim)
	string sOption //"Libraries" or "DataTypes"
	int iDim //-3 for all, -2 for all numeric, -1 for Meta, 0 for Library, 1 for scalar, 2 for vector
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary
	if(stringmatch(sOption,"DataTypes") && iDim == 2)
		sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
		return COMBI_TableList(sProject,iDim,sLibrary,sOption)	
	elseif(stringmatch(sOption,"DataTypes") && iDim == 1)
		sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
		return COMBI_TableList(sProject,iDim,sLibrary,sOption)	
	elseif(stringmatch(sOption,"Libraries"))
		return COMBI_TableList(sProject,2,"All",sOption)	
	endif
end


//This function handles the back end of the button on the panel, and calls the corresponding function that actually does something.
Function DataViewer_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	
	if(stringmatch("bRefreshAction",ctrlName))
		COMBI_DataViewer()							//Refresh Panel
	endif
	
end