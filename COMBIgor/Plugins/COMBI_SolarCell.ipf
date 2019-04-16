#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Imran Khan _ Jan 2019 : SolarCell Plugin initial release

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
Static StrConstant sPluginName = "SolarCell"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this plugin
Menu "COMBIgor"
	SubMenu "Plugins"
		 "SolarCell IV",/Q, COMBI_SolarCell()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This function is run when the user selects the Plugin from the COMBIgor drop down menu once activated. This will build the plugin panel that the user interacts with.
function COMBI_SolarCell()

	//name for plugin panel
	string sWindowName=sPluginName+"_Panel"
	
	//check if initialized, get starting values if so, initialize if not
	string sProject //project to operate within
	string sLibrary//Library to operate on
	string sData // Data type to operate on
	string sDataV, sDataI, sFirstSample, sLastSample, sArea, sDataJ
	string sVoc, sJsc, sFF, sEff, sRs, sRsh //Library data: Voltage, Current, Area, Current Density......
	string sXmin, sXmax, sYmin, sYmax
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
		COMBI_GivePluginGlobal(sPluginName,"sDataV"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataI"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sArea"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataJ"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFirstSample","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLastSample",COMBI_GetGlobalString("vTotalSamples", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sVoc","Voc",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sJsc","Jsc",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFF","FF",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sEff","Efficiency",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sRs","Rs",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sRsh","Rsh",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXmin","-0.5",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXmax","1.0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sYmin","-30",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sYmax","30",sProject)
	endif
	
	//get values of globals to use in this function, mainly panel building
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sDataV = COMBI_GetPluginString(sPluginName,"sDataV",sProject)
	sDataI = COMBI_GetPluginString(sPluginName,"sDataI",sProject)
	sArea = COMBI_GetPluginString(sPluginName,"sArea",sProject)
	sDataJ = COMBI_GetPluginString(sPluginName,"sDataJ",sProject)
	sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	sVoc = COMBI_GetPluginString(sPluginName,"sVoc",sProject)
	sJsc = COMBI_GetPluginString(sPluginName,"sJsc",sProject)
	sFF = COMBI_GetPluginString(sPluginName,"sFF",sProject)
	sEff = COMBI_GetPluginString(sPluginName,"sEff",sProject)
	sRs = COMBI_GetPluginString(sPluginName,"sRs",sProject)			
	sRsh = COMBI_GetPluginString(sPluginName,"sRsh",sProject)
	sXmin = COMBI_GetPluginString(sPluginName,"sXmin",sProject)
	sXmax = COMBI_GetPluginString(sPluginName,"sXmax",sProject)
	sYmin = COMBI_GetPluginString(sPluginName,"sYmin",sProject)
	sYmax = COMBI_GetPluginString(sPluginName,"sYmax",sProject)	
		
	//get trace numbers
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	variable iXmin = str2num(sXmin)
	variable iXmax = str2num(sXmax)	
	variable iYmin = str2num(sYmin)	
	variable iYmax = str2num(sYmax)
	
	//get the globals wave for use in panel building, mainly set varaible controls
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_SolarCell_Globals
	
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
	variable vPanelHeight = 350
	variable vPanelWidth = 820
 
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")

	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "COMBIgor SolarCell Plugin"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	variable vYValue = 15
	
	//This is the section of this function that you will edit to customize for your plugin. 
	//Project select
	DrawText 120,vYValue, "Project:"
	PopupMenu sProject,pos={270,vYValue-10},mode=1,bodyWidth=200,value=COMBI_Projects(),proc=SolarCell_UpdateGlobal,popvalue=sProject
	vYValue+=20
	//Library select
	DrawText 120,vYValue, "Library:"
	PopupMenu sLibrary,pos={270,vYValue-10},mode=1,bodyWidth=200,value=SolarCell_DropList("Libraries",2),proc=SolarCell_UpdateGlobal,popvalue=sLibrary
	vYValue+=25
	//Sample range
	DrawText 120,vYValue, "Samples:"
	DrawText 180,vYValue, " - "
	SetVariable sFirstSample, title=" ",pos={120,vYValue-10},size={40,40},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sFirstSample][%$sProject]
	SetVariable sLastSample, title=" ",pos={180,vYValue-10},size={40,40},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sLastSample][%$sProject]	
	vYValue+=30	
	//Voltage Data Field
	DrawText 120,vYValue, "Voltage Data:"
	PopupMenu sDataV,pos={240,vYValue-10},mode=1,bodyWidth=170,value=" ;"+SolarCell_DropList("DataTypes",2),proc=SolarCell_UpdateGlobal,popvalue=sDataV
	vYValue+=20
	//Current Data Field
	DrawText 120,vYValue, "Current Data:"
	PopupMenu sDataI,pos={240,vYValue-10},mode=1,bodyWidth=170,value=" ;"+SolarCell_DropList("DataTypes",2),proc=SolarCell_UpdateGlobal,popvalue=sDataI
	vYValue+=40
	//Current Density Data Field    //New vector data button
	DrawText 120,vYValue, "Current Density Data:"
	PopupMenu sDataJ,pos={240,vYValue-10},mode=1,bodyWidth=170,value=" ;"+SolarCell_DropList("DataTypes",2),proc=SolarCell_UpdateGlobal,popvalue=sDataJ
	button bNewVector,title="+",appearance={native,All},pos={295,vYValue-10},size={25,20},proc=SolarCell_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
	vYValue+=20
	//CellArea Field
	DrawText 120,vYValue, "Cell Area:"
	SetVariable sArea,title=" ",pos={120,vYValue-10},size={120,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sArea][%$sProject]
	vYValue+=20
	//Calculate Current Density button 
   button bCurrentAction,title="Calculate Current Density",appearance={native,All},pos={25,vYValue},size={275,20},proc=SolarCell_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
	vYValue+=50
	//Cell Parameter Labels
	DrawText 250,vYValue, "Cell Parameters' Data Labels:"
	vYValue+=20
	//Voc Jsc Label Field
	DrawText 40,vYValue, "Voc:"
	SetVariable sVoc,title=" " ,pos={45,vYValue-10},size={80,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sVoc][%$sProject]
	DrawText 210,vYValue, "Jsc:"
	SetVariable sJsc,title=" " ,pos={215,vYValue-10},size={100,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sJsc][%$sProject]
	vYValue+=20
	//FF Efficiency Label Field
	DrawText 40,vYValue, "FF:"
	SetVariable sFF,title=" " ,pos={45,vYValue-10},size={80,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sFF][%$sProject]
	DrawText 210,vYValue, "Efficiency:"
	SetVariable sEff,title=" " ,pos={215,vYValue-10},size={100,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sEff][%$sProject]
	vYValue+=20
	//Rs Rsh Label Field
	DrawText 40,vYValue, "Rs:"
	SetVariable sRs,title=" " ,pos={45,vYValue-10},size={80,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sRs][%$sProject]
	DrawText 210,vYValue, "Rsh:"
	SetVariable sRsh,title=" " ,pos={215,vYValue-10},size={100,20},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sRsh][%$sProject]
	vYValue+=20
	//Calculate Solar Cell Parameters
   button bParameterAction,title="Calculate Solar Cell Parameters",appearance={native,All},pos={10,vYValue},size={310,20},proc=SolarCell_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
	vYValue+=20
	//Plot range
	vYValue=10
	DrawText 410,vYValue, "Xmin=" 
	DrawText 510,vYValue, "Xmax="
	DrawText 620,vYValue, "Ymin=" 
	DrawText 720,vYValue, "Ymax="	
	SetVariable sXmin, title=" ",pos={415,vYValue-8},size={40,40},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sXmin][%$sProject]
	SetVariable sXmax, title=" ",pos={515,vYValue-8},size={40,40},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sXmax][%$sProject]
	SetVariable sYmin, title=" ",pos={625,vYValue-8},size={40,40},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sYmin][%$sProject]
	SetVariable sYmax, title=" ",pos={725,vYValue-8},size={40,40},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sYmax][%$sProject]
	vYValue+=10
	
	//Draw Plot
	if(waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataV) && waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataJ))
		wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataV
		wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataJ
		wave wVoc = $Combi_DataPath(sProject,1)+sLibrary+":"+sVoc
		wave wJsc = $Combi_DataPath(sProject,1)+sLibrary+":"+sJsc
		wave wRs = $Combi_DataPath(sProject,1)+sLibrary+":"+sRs
		wave wRsh = $Combi_DataPath(sProject,1)+sLibrary+":"+sRsh
		//Graph Window for JV Data
		Display/HOST=$sWindowName/W=(350,vYValue,800,vYValue+295)/N=JV_Plot wYWave[iFirstSample][] vs wXWave[iFirstSample][]
		for(iSample=(iFirstSample+1);iSample<=iLastSample;iSample+=1)
			AppendToGraph/W=$sWindowName#JV_Plot wYWave[iSample][] vs wXWave[iSample][]
		endfor
		ModifyGraph/W=$sWindowName#JV_Plot tick=1,mirror=2,grid(left)=1,zero(left)=4,grid(bottom)=1,zero(bottom)=4
		Label/W=$sWindowName#JV_Plot left sDataJ
		Label/W=$sWindowName#JV_Plot bottom sDataV
		ModifyGraph/W=$sWindowName#JV_Plot margin(left)=35,margin(bottom)=35,margin(right)=10,margin(top)=0,gFont="Times",gfSize=10
		SetAxis left iYmin,iYmax
		SetAxis bottom iXmin,iXmax
	else
		DrawText 600,vYValue+100, "No data available to plot !"
	endif
	
	if(waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataV) && waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataJ) && waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sVoc) && waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sJsc) && waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sRs) && waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sRsh))
		//Voc, Jsc lines
		SetDrawEnv save, xcoord= bottom, ycoord=left, dash=3, linefgc=(20000,40000,20000),linethick=2
		for(iSample=(iFirstSample);iSample<=iLastSample;iSample+=1)
			DrawLine/W=$sWindowName#JV_Plot wVoc[iSample],0,wVoc[iSample],-wJsc[iSample]
			DrawLine/W=$sWindowName#JV_Plot 0,-wJsc[iSample],wVoc[iSample],-wJsc[iSample]
		endfor
		//Rs, Rsh lines (extrapolated from values)
		SetDrawEnv save, xcoord= bottom, ycoord=left, dash=3, linefgc=(0,0,63333),linethick=2
		for(iSample=(iFirstSample);iSample<=iLastSample;iSample+=1)
			DrawLine/W=$sWindowName#JV_Plot wVoc[iSample],0,iXmax,(iXmax-wVoc[iSample])/wRs[iSample]      
			DrawLine/W=$sWindowName#JV_Plot 0,-wJsc[iSample],iXmin,-wJsc[iSample]+iXmin/wRsh[iSample]
		endfor
	endif
	
	//Refresh Plot and Export Plots button
	vYValue+=300
   button bRefreshAction,title="Refresh Plot",appearance={native,All},pos={420,vYValue},size={120,20},proc=SolarCell_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
   button bExportAction,title="Export Plots",appearance={native,All},pos={600,vYValue},size={120,20},proc=SolarCell_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
   
end


//This function will update the globals when a drop-down is updated on the panel. It's fairly general and shouldn't need to be edited much.
Function SolarCell_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
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
	COMBI_SolarCell()
end


//This function is used to grab the info from the project to return in the pop-up menu. function to return drop downs of Libraries for panel
function/S SolarCell_DropList(sOption, iDim)
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
Function SolarCell_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	string sDataV = COMBI_GetPluginString(sPluginName,"sDataV",sProject)
	string sDataI = COMBI_GetPluginString(sPluginName,"sDataI",sProject)
	string sDataJ = COMBI_GetPluginString(sPluginName,"sDataJ",sProject)
	string sArea = COMBI_GetPluginString(sPluginName,"sArea",sProject)
	string sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	string sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	string sVoc = COMBI_GetPluginString(sPluginName,"sVoc",sProject)
	string sJsc = COMBI_GetPluginString(sPluginName,"sJsc",sProject)
	string sFF = COMBI_GetPluginString(sPluginName,"sFF",sProject)
	string sEff = COMBI_GetPluginString(sPluginName,"sEff",sProject)
	string sRs = COMBI_GetPluginString(sPluginName,"sRs",sProject)
	string sRsh = COMBI_GetPluginString(sPluginName,"sRsh",sProject)
	
	//Copy and paste this for each different button you have that does something different if button "bCurrentAction" was pressed
	if(stringmatch("bNewVector",ctrlName))
		string sNewDataType = Combi_StringPrompt("CurrentDensity_AperM2","Name for a new Vector Data Type:","","A New Vector Data Type with the same dimension as the Current Data vector","A New Vector Data Type!")
		wave wCurrent = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataI
		Combi_AddDataType(sProject,sLibrary,sNewDataType,2,iVDim=dimsize(wCurrent,1))					//Export Plots
	endif
	
	if(stringmatch("bCurrentAction",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "SolarCell_CurrentNormalize(\""+sProject+"\",\""+sLibrary+"\",\""+sDataV+"\",\""+sDataI+"\",\""+sDataJ+"\",\""+sArea+"\",\""+sFirstSample+"\",\""+sLastSample+"\")"
		endif
		//pass to programatic function
		SolarCell_CurrentNormalize(sProject,sLibrary,sDataV,sDataI,sDataJ,sArea,sFirstSample,sLastSample)
	endif
	
	if(stringmatch("bParameterAction",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
			//print call line
			Print "SolarCell_CellParameters(\""+sProject+"\",\""+sLibrary+"\",\""+sDataV+"\",\""+sDataI+"\",\""+sDataJ+"\",\""+sArea+"\",\""+sFirstSample+"\",\""+sLastSample+"\",\""+sVoc+"\",\""+sJsc+"\",\""+sFF+"\",\""+sEff+"\",\""+sRs+"\",\""+sRsh+"\")"   //// 
		endif
		//pass to programatic function
		SolarCell_CellParameters(sProject,sLibrary,sDataV,sDataI,sDataJ,sArea,sFirstSample,sLastSample,sVoc,sJsc,sFF,sEff,sRs,sRsh)
	endif
	
	if(stringmatch("bRefreshAction",ctrlName))
		COMBI_SolarCell()							//Refresh Panel
	endif
	
	if(stringmatch("bExportAction",ctrlName))
		SolarCell_ExportPlot(sProject,sLibrary,sDataV,sDataJ,sFirstSample,sLastSample,sVoc,sJsc,sFF,sEff,sRs,sRsh)						//Export Plots
	endif

	
end

//This is where the action of the button happens; can modify to do behind the scenes data manipulation, plotting, etc.
Function SolarCell_CurrentNormalize(sProject,sLibrary,sDataV,sDataI,sDataJ,sArea,sFirstSample,sLastSample)
	string sProject, sLibrary, sDataV, sDataI, sDataJ, sArea, sFirstSample, sLastSample
	variable vArea = str2num(sArea)
	int scanIV, isample, iFirstSample, iLastSample
	iFirstSample = str2num(sFirstSample)-1    //index of first sample
	iLastSample = str2num(sLastSample)-1

	wave wCurrent = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataI
	wave wCurrentDensity = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataJ
	
	int pointsIV = dimsize(wCurrent,1)               			//get the max number of data points in the IV table
	
	for (isample = iFirstSample; isample < iLastSample+1; isample+=1)
		for (scanIV = 0; scanIV < pointsIV; scanIV+=1)
			wCurrentDensity[isample][scanIV] = wCurrent[isample][scanIV] / vArea 	//calculating current density A/cm2
		endfor
	endfor
end


Function SolarCell_CellParameters(sProject,sLibrary,sDataV,sDataI,sDataJ,sArea,sFirstSample,sLastSample,sVoc,sJsc,sFF,sEff,sRs,sRsh)
	string sProject, sLibrary, sDataV, sDataI, sDataJ, sArea, sFirstSample, sLastSample, sVoc, sJsc, sFF, sEff, sRs, sRsh
	variable vArea = str2num(sArea)
	int scanIV, isample, iFirstSample, iLastSample, zeroVpnt, zeroJpnt, Pmaxpnt
	variable Voc, Jsc, FF, Efficiency, Pmax, zeroV, zeroJ, Rs, Rsh, tempV, tempJ, tempP
	iFirstSample = str2num(sFirstSample)-1    //index of first sample
	iLastSample = str2num(sLastSample)-1
	
	Combi_AddDataType(sproject,slibrary,sVoc,1)
	Combi_AddDataType(sproject,slibrary,sJsc,1)
	Combi_AddDataType(sproject,slibrary,sFF,1)
	Combi_AddDataType(sproject,slibrary,sEff,1)
	Combi_AddDataType(sproject,slibrary,sRs,1)
	Combi_AddDataType(sproject,slibrary,sRsh,1)
	
	wave wCurrent = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataI
	wave wVoltage = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataV
	wave wCurrentDensity = $Combi_DataPath(sProject,2)+sLibrary+":"+sDataJ
	wave wVoc = $Combi_DataPath(sProject,1)+sLibrary+":"+sVoc
	wave wJsc = $Combi_DataPath(sProject,1)+sLibrary+":"+sJsc
	wave wFF = $Combi_DataPath(sProject,1)+sLibrary+":"+sFF
	wave wEff = $Combi_DataPath(sProject,1)+sLibrary+":"+sEff
	wave wRs = $Combi_DataPath(sProject,1)+sLibrary+":"+sRs
	wave wRsh = $Combi_DataPath(sProject,1)+sLibrary+":"+sRsh
	wave W_coef = root:W_coef
	
	int pointsIV = dimsize(wCurrent,1)               			//get the max number of data points in the IV table
	
	for (isample = iFirstSample; isample < iLastSample+1; isample+=1)
		zeroV = wVoltage[isample][0]      								//initial value before starting scanning for zero points
		zeroJ = wCurrentDensity[isample][0]
		Pmax = zeroV * zeroJ
		
		for (scanIV = 0; scanIV < pointsIV; scanIV+=1)			//this loop scans the IV data at specific 'point' for Voc, Jsc, and Pmax
			tempV = wVoltage[isample][scanIV]
			tempJ = wCurrentDensity[isample][scanIV]
			tempP = tempJ * tempV
			if (abs(zeroV) >= abs(tempV))
				zeroV = tempV
				zeroVpnt = scanIV
			endif
			if (abs(zeroJ) >= abs(tempJ))
				zeroJ = tempJ
				zeroJpnt = scanIV
			endif	
			if (Pmax >= tempP)
				Pmax = tempP
				Pmaxpnt = scanIV
			endif					
		endfor
		
		Voc = wVoltage[isample][zeroJpnt]															//Voc [V]
		Jsc = wCurrentDensity[isample][zeroVpnt]												//Jsc [A/m2]
		FF =  Pmax / (Voc * Jsc)																		//FF 	[ratio]																			
		Efficiency = Voc * (1*abs(Jsc)) * FF /1000												//Efficiency [ratio] Input Power [W]; 100mW/cm2 = 1000W/m2
		
		//Series Resistance, Rs calculated by line curvefitting at Voc
		CurveFit/N/Q/M=2/W=0 line, wCurrentDensity[isample][zeroJpnt-1,zeroJpnt+2]/X=wVoltage[isample][zeroJpnt-1,zeroJpnt+2]/D
		Rs = 1/W_coef[1]
		//Shunt resistance, Rsh calculated by line curvefitting at Jsc
		CurveFit/N/Q/M=2/W=0 line, wCurrentDensity[isample][zeroVpnt-1,zeroVpnt+3]/X=wVoltage[isample][zeroVpnt-1,zeroVpnt+3]/D
		Rsh = 1/W_coef[1]
		
		//Device data to mapping table
		wVoc[isample] = Voc							//Voc [V]
		wJsc[isample] = abs(Jsc)						//Jsc [A/m2]
		wFF[isample] = 100*FF							//FF 	[%]
		wEff[isample] = 100 * Efficiency			//Efficiency [%]
		wRs[isample] = Rs								//Rs [ohm]
		wRsh[isample] = Rsh							//Rsh [ohm]
	endfor	
		
	//COMBI_Add2Log(sProject,sLibraries,sDataType,vLogEntryType,sLogText)    ****
end


Function SolarCell_ExportPlot(sProject,sLibrary,sDataV,sDataJ,sFirstSample,sLastSample,sVoc,sJsc,sFF,sEff,sRs,sRsh)
	string sProject, sLibrary, sDataV, sDataJ, sFirstSample, sLastSample, sVoc, sJsc, sFF, sEff, sRs, sRsh
	int isample, iFirstSample, iLastSample, zeroVpnt, zeroJpnt, Pmaxpnt
	iFirstSample = str2num(sFirstSample)-1    //index of first sample
	iLastSample = str2num(sLastSample)-1
	
	wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataV
	wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataJ
	wave wVoc = $Combi_DataPath(sProject,1)+sLibrary+":"+sVoc
	wave wJsc = $Combi_DataPath(sProject,1)+sLibrary+":"+sJsc
	wave wFF = $Combi_DataPath(sProject,1)+sLibrary+":"+sFF
	wave wEff = $Combi_DataPath(sProject,1)+sLibrary+":"+sEff
	wave wRs = $Combi_DataPath(sProject,1)+sLibrary+":"+sRs
	wave wRsh = $Combi_DataPath(sProject,1)+sLibrary+":"+sRsh
	
	//for plot exporting
	string sExportPath =COMBI_ExportPath("Read")
	if(stringmatch(sExportPath,"NO PATH"))
		sExportPath =COMBI_ExportPath("Temp")
	endif
	NewPath/Q/Z/O/C pExportPath sExportPath+sLibrary+":"
	NewPath/Q/Z/O/C pExportPath sExportPath+sLibrary+":Solar Cell Plots:"

	if(!(waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sVoc) & waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sJsc) & waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sRs) & waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sRsh)))
		Doalert/T="Bad Inputs!",0,"Missing some parameters! Make sure the cell parameters are calculated, and/or, "
	endif

	string sFitPlotWindow, sGraphicName
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		sFitPlotWindow = "FitDisplayWindow_Pt"+num2str(iSample+1)
		sGraphicName = sLibrary+"_"+sDataJ+"vs"+sDataV+"_Pt"+num2str(iSample+1)+".pdf"
		//prefitplot
		Killwindow/Z $sFitPlotWindow
		COMBI_NewPlot(sFitPlotWindow)
		AppendToGraph/W=$sFitPlotWindow wYWave[iSample][] vs wXWave[iSample][]
		//StylePlot
		ModifyGraph tick(bottom)=0.1,mirror=2,lblMargin=5, margin(right)=110
		Label left COMBIDisplay_GetAxisLabel("Current Density (A/m2)")
		Label bottom COMBIDisplay_GetAxisLabel("Voltage (Volts)")
		TextBox/C/N=FitResult/F=0/Z=1/A=RC/X=2/Y=0.00/E=2 "\\K(0,0,0)Voc (Volts):\r\t\K(65535,0,0)"+num2str(wVoc[iSample])+"\r\r\K(0,0,0)Fill Factor (%):\r\t\K(65535,0,0)"+num2str(wFF[iSample])+"\r\r\K(0,0,0)Jsc (A/m2):\r\t\K(65535,0,0)"+num2str(wJsc[iSample])+"\r\r\K(0,0,0)Efficiency (%):\r\t\K(65535,0,0)"+num2str(wEff[iSample])+"\r\r\K(0,0,0)Rs (ohm/m2):\r\t\K(65535,0,0)"+num2str(wRs[iSample])+"\r\r\K(0,0,0)Rsh (ohm/m2):\r\t\K(65535,0,0)"+num2str(wRsh[iSample])+""
		DoUpdate/W=$sFitPlotWindow
		Sleep/S 0.50 //so the user can see the plot window	
		//do exporting
		SavePICT/O/P=pExportPath/E=-2 as sGraphicName

		Killwindow/Z $sFitPlotWindow
	endfor
end

