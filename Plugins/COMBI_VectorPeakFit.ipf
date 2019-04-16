#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original Example 
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
Static StrConstant sPluginName = "VectorPeakFit"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Plugins"
		 "Vector Peak Fitting",/Q, COMBI_VectorPeakFit()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
function COMBI_VectorPeakFit()
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	
	//check if initialized, get starting values if so, initialize if not
	string sProject, sLibrary, sDataX, sDataY, sFirstSample, sLastSample, sPeakType, sFitName //Library data 
	int bBGDOut, bAmpOut, bPosOut, bFWHMOut, bRawIntegral, bFitIntegral, bFitTrace, bResidualTrace,bFitPlot,bLogPlot // check box bools
	variable vPosCenter, vPosDelta, vAmplitudeMin, vAmplitudeMax, vBackgroundMin, vBackgroundMax, vFitRangeMin, vFitRangeMax, vPositionMin, vPositionMax //constraints

	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")))
		//not yet initialized
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_ChooseProject(),"COMBIgor")
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	else
		//previously initialized
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	endif
	
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sProject)))
		COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFitName","PeakFit",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataX"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataY"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sPeakType","PseudoVoigt",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFirstSample","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLastSample",COMBI_GetGlobalString("vTotalSamples", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"bAmpOut","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bBGDOut","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bPosOut","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bFWHMOut","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bRawIntegral","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bFitIntegral","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bFitTrace","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bFitPlot","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bLogPlot","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bResidualTrace","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vAmplitudeMin","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vAmplitudeMax","",sProject) 
		COMBI_GivePluginGlobal(sPluginName,"vBackgroundMin","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vBackgroundMax","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vFitRangeMin","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vFitRangeMax","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vPositionMin","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vPositionMax","",sProject)
	endif

	sPeakType = COMBI_GetPluginString(sPluginName,"sPeakType",sProject)
	sFitName = COMBI_GetPluginString(sPluginName,"sFitName",sProject)
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sDataX = COMBI_GetPluginString(sPluginName,"sDataX",sProject)
	sDataY = COMBI_GetPluginString(sPluginName,"sDataY",sProject)
	sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	bAmpOut  = COMBI_GetPluginNumber(sPluginName,"bAmpOut",sProject)
	bBGDOut = COMBI_GetPluginNumber(sPluginName,"bBGDOut",sProject)
	bPosOut = COMBI_GetPluginNumber(sPluginName,"bPosOut",sProject)
	bFWHMOut = COMBI_GetPluginNumber(sPluginName,"bFWHMOut",sProject)
	bRawIntegral = COMBI_GetPluginNumber(sPluginName,"bRawIntegral",sProject)
	bFitIntegral = COMBI_GetPluginNumber(sPluginName,"bFitIntegral",sProject)
	bFitTrace =  COMBI_GetPluginNumber(sPluginName,"bFitTrace",sProject)
	bFitPlot = COMBI_GetPluginNumber(sPluginName,"bFitPlot",sProject)
	bLogPlot = COMBI_GetPluginNumber(sPluginName,"bLogPlot",sProject)
	bResidualTrace =  COMBI_GetPluginNumber(sPluginName,"bResidualTrace",sProject)
	vAmplitudeMin = COMBI_GetPluginNumber(sPluginName,"vAmplitudeMin",sProject)
	vAmplitudeMax = COMBI_GetPluginNumber(sPluginName,"vAmplitudeMax",sProject)
	vBackgroundMin = COMBI_GetPluginNumber(sPluginName,"vBackgroundMin",sProject)
	vBackgroundMax = COMBI_GetPluginNumber(sPluginName,"vBackgroundMax",sProject)
	vFitRangeMin = COMBI_GetPluginNumber(sPluginName,"vFitRangeMin",sProject)
	vFitRangeMax = COMBI_GetPluginNumber(sPluginName,"vFitRangeMax",sProject)
	vPositionMin = COMBI_GetPluginNumber(sPluginName,"vPositionMin",sProject)
	vPositionMax = COMBI_GetPluginNumber(sPluginName,"vPositionMax",sProject)
	
	//get trace numbers
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	
	//get waves
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_VectorPeakFit_Globals	

	//kill if open already
	PauseUpdate; Silent 1 // pause for building window...
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z VectorPeakFitPanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z VectorPeakFitPanel
	
	int bPlotReady = 0
	int iPanelHeight = 415
	int iSample
	if(!stringmatch(sDataX," "))
		if(!stringmatch(sDataY," "))
			if(!stringmatch(sLibrary," "))
				if(waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX))
					if(waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY))
						bPlotReady = 1
						iPanelHeight+=250
						//plot variables
						variable vPlotXMax
						if(numtype(vFitRangeMax)==2)
							vPlotXMax = COMBI_Extremes(sProject,2,sDataX,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")
						else
							vPlotXMax = vFitRangeMax
						endif
						variable vPlotYMax = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")*1.2
						variable vPlotXMin
						if(numtype(vFitRangeMin)==2)
							vPlotXMin = COMBI_Extremes(sProject,2,sDataX,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")
						else
							vPlotXMin = vFitRangeMin
						endif
						variable vPlotYMin = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")*.8
					endif
				endif
			endif
		endif
	endif
	
	//make panel
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+300,vWinTop+iPanelHeight)/N=VectorPeakFitPanel as "COMBIgor Vector Peak Fit"
	SetDrawLayer ProgBack
	SetDrawEnv fname = sFont
	SetDrawEnv textxjust = 2,textyjust = 1
	SetDrawEnv fsize = 12
	SetDrawEnv save
	variable vYValue = 15
	
	
	//Project
	DrawText 90,vYValue, "Project:"
	PopupMenu sProject,pos={230,vYValue-10},mode=1,bodyWidth=190,value=COMBI_Projects(),proc=VectorPeakFit_UpdateGlobal,popvalue=sProject
	//Library1
	vYValue+=20
	DrawText 90,vYValue, "Library:"
	PopupMenu sLibrary,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+VectorPeakFit_DropList("Libraries"),proc=VectorPeakFit_UpdateGlobal,popvalue=sLibrary
	//XData
	vYValue+=20
	DrawText 90,vYValue, "X Data:"
	PopupMenu sDataX,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+VectorPeakFit_DropList("DataTypes"),proc=VectorPeakFit_UpdateGlobal,popvalue=sDataX
	//YData
	vYValue+=20
	DrawText 90,vYValue, "Y Data:"
	PopupMenu sDataY,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+VectorPeakFit_DropList("DataTypes"),proc=VectorPeakFit_UpdateGlobal,popvalue=sDataY
	//PeakType
	vYValue+=20
	DrawText 90,vYValue, "Peak Type:"
	PopupMenu sPeakType,pos={230,vYValue-10},mode=1,bodyWidth=190,value="PseudoVoigt;Gaussian;Lorentzian",proc=VectorPeakFit_UpdateGlobal,popvalue=sPeakType
	
	//Sample range
	vYValue+=20
	DrawText 90,vYValue, "Samples:"
	DrawText 195,vYValue, " - "
	SetVariable sFirstSample, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%sFirstSample][%$sProject]
	SetVariable sLastSample, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%sLastSample][%$sProject]	
	
	int iLogStatus = 0
	if(bLogPlot==1)
		iLogStatus =1
		vPlotYMax = 10*vPlotYMax
		if(vPlotYMin<0)
			vPlotYMin = 1
		endif
	endif
	
	//Addplot if defined
	if(bPlotReady==1)
		vYValue+=10
		wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX
		wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY
		Display/HOST=VectorPeakFitPanel/W=(10,vYValue,290,vYValue+250)/N=PeakPlot wYWave[iFirstSample][] vs wXWave[iFirstSample][]
		for(iSample=(iFirstSample+1);iSample<=iLastSample;iSample+=1)
			AppendToGraph/W=VectorPeakFitPanel#PeakPlot wYWave[iSample][] vs wXWave[iSample][]
		endfor
		ModifyGraph/W=VectorPeakFitPanel#PeakPlot log(left)=iLogStatus,tick=3,mirror=2
		Label/W=VectorPeakFitPanel#PeakPlot left sDataY
		Label/W=VectorPeakFitPanel#PeakPlot bottom sDataX
		ModifyGraph/W=VectorPeakFitPanel#PeakPlot margin(left)=30,margin(bottom)=25,margin(right)=10,margin(top)=0
		ModifyGraph/W=VectorPeakFitPanel#PeakPlot gbRGB=(65535.,65535.,65535.)
		ModifyGraph/W=VectorPeakFitPanel#PeakPlot wbRGB=(61166,61166,61166)
		ModifyGraph/W=VectorPeakFitPanel#PeakPlot gFont="Times",gfSize=10,  rgb=(0,0,0)
		SetAxis bottom vPlotXMin,vPlotXMax
		SetAxis left vPlotYMin,vPlotYMax
		//Draw Position
		SetDrawEnv xcoord= bottom,ycoord= left,dash= 2
		if(numtype(vPositionMin)==0&&numtype(vPositionMax)==0)
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 2, linefgc= (0,0,65535),linethick= 2.00
			DrawLine vPositionMin,vPlotYMin,vPositionMin,vPlotYMax
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 2, linefgc= (0,0,65535),linethick= 2.00
			DrawLine vPositionMax,vPlotYMin,vPositionMax,vPlotYMax
		endif
		if(numtype(vBackgroundMin)==0&&numtype(vBackgroundMax)==0)
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 2, linefgc=(1,26214,0),linethick= 2.00
			DrawLine vPlotXMin,vBackgroundMin,vPlotXMax,vBackgroundMin
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 2, linefgc=(1,26214,0),linethick= 2.00
			DrawLine vPlotXMin,vBackgroundMax,vPlotXMax,vBackgroundMax
		endif
		if(numtype(vAmplitudeMin)==0&&numtype(vAmplitudeMax)==0)
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 2, linefgc=(65535,0,0),linethick= 2.00
			DrawLine vPlotXMin,vAmplitudeMin,vPlotXMax,vAmplitudeMin
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 2, linefgc=(65535,0,0),linethick= 2.00
			DrawLine vPlotXMin,vAmplitudeMax,vPlotXMax,vAmplitudeMax
		endif
		
		
		vYValue+=240
	endif
	SetActiveSubwindow VectorPeakFitPanel
	SetDrawLayer ProgBack
	SetDrawEnv fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	
	//Constraints
	vYValue+=25
	SetDrawEnv textxjust = 1, fstyle=5, save; DrawText 150,vYValue, "       Fit Constraints       ";SetDrawEnv textxjust = 2,fstyle=0, save
	//Position
	vYValue+=20
	SetDrawEnv textrgb= (0,0,65535), save
	DrawText 90,vYValue, "Position:"
	DrawText 195,vYValue, " - "
	SetDrawEnv textrgb= (0,0,0), save
	SetVariable vPositionMin, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vPositionMin][%$sProject]
	SetVariable vPositionMax, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vPositionMax][%$sProject]
	//Max	
	vYValue+=20
	SetDrawEnv textrgb= (65535,0,0), save
	DrawText 90,vYValue, "Max:"
	DrawText 195,vYValue, " - "
	SetDrawEnv textrgb= (0,0,0), save
	SetVariable vAmplitudeMin, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vAmplitudeMin][%$sProject]
	SetVariable vAmplitudeMax, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vAmplitudeMax][%$sProject]
	//Background
	vYValue+=20
	SetDrawEnv textrgb= (1,26214,0), save
	DrawText 90,vYValue, "Background:"
	DrawText 195,vYValue, " - "
	SetDrawEnv textrgb= (0,0,0), save
	SetVariable vBackgroundMin, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vBackgroundMin][%$sProject]
	SetVariable vBackgroundMax, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vBackgroundMax][%$sProject]
	//Fit Range
	vYValue+=20
	DrawText 90,vYValue, "Fit Range:"
	DrawText 195,vYValue, " - "
	SetVariable vFitRangeMin, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vFitRangeMin][%$sProject]
	SetVariable vFitRangeMax, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%vFitRangeMax][%$sProject]
	
	//PeakOutputs
	vYValue+=25
	SetDrawEnv textxjust = 1, fstyle=5, save; DrawText 150,vYValue, "         Fit Outputs          ";SetDrawEnv textxjust = 2,fstyle=0, save
	vYValue+=10
	CheckBox bBGDOut,pos={25,vYValue},size={100,15},title="\F'"+sFont+"'BackGround",value=bBGDOut,proc=VectorPeakFit_Output, align=0,fsize=12
	CheckBox bAmpOut,pos={160,vYValue},size={100,15},title="\F'"+sFont+"'Amplitude",value=bAmpOut,proc=VectorPeakFit_Output, align=0,fsize=12
	vYValue+=15
	CheckBox bPosOut,pos={25,vYValue},size={100,15},title="\F'"+sFont+"'Position",value=bPosOut,proc=VectorPeakFit_Output, align=0,fsize=12
	CheckBox bFWHMOut,pos={160,vYValue},size={100,15},title="\F'"+sFont+"'F.W.H.M",value=bFWHMOut,proc=VectorPeakFit_Output, align=0,fsize=12
	vYValue+=15
	CheckBox bRawIntegral,pos={25,vYValue},size={100,15},title="\F'"+sFont+"'Raw Integral",value=bRawIntegral,proc=VectorPeakFit_Output, align=0,fsize=12
	CheckBox bFitIntegral,pos={160,vYValue},size={100,15},title="\F'"+sFont+"'Fit Integral",value=bFitIntegral,proc=VectorPeakFit_Output, align=0,fsize=12
	vYValue+=15
	CheckBox bFitTrace,pos={25,vYValue},size={100,15},title="\F'"+sFont+"'Fit Trace",value=bFitTrace,proc=VectorPeakFit_Output, align=0,fsize=12
	CheckBox bResidualTrace,pos={160,vYValue},size={100,15},title="\F'"+sFont+"'Residual Trace",value=bResidualTrace,proc=VectorPeakFit_Output, align=0,fsize=12
	vYValue+=15
	CheckBox bFitPlot,pos={25,vYValue},size={100,15},title="\F'"+sFont+"'Export Plots",value=bFitPlot,proc=VectorPeakFit_Output, align=0,fsize=12
	CheckBox bLogPlot,pos={160,vYValue},size={100,15},title="\F'"+sFont+"'Log Plots?",value=bLogPlot,proc=VectorPeakFit_Output, align=0,fsize=12
	
	//fit name
	SetDrawEnv textxjust = 2; SetDrawEnv save
	vYValue+=35
	DrawText 90,vYValue, "Peak Name:"
	SetVariable sFitName, title=" ",pos={90,vYValue-10},size={190,50},fsize=14,live=0,font=sFont,value=twGlobals[%sFitName][%$sProject]

	//compute
	vYValue+=15
	button btUpdate,title="Update",appearance={native,All},pos={20,vYValue},size={80,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=VectorPeakFit_Update
	button btGuess,title="Guess",appearance={native,All},pos={110,vYValue},size={80,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=VectorPeakFit_Guess
	button btFit,title="Fit",appearance={native,All},pos={200,vYValue},size={80,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=VectorPeakFit_Fit
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

Function VectorPeakFit_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	if(stringmatch("sProject",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sDataX"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sDataY"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sLibrary"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	else
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	COMBI_VectorPeakFit()
End

//function to return drop downs of Libraries for panel
function/S VectorPeakFit_DropList(sOption)
	string sOption //"Libraries" or "DataTypes"
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")	
	if(stringmatch(sOption,"DataTypes"))
		string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
		return COMBI_TableList(sProject,2,sLibrary,sOption)	
	else
		return COMBI_TableList(sProject,2,"All",sOption)	
	endif
end


function VectorPeakFit_Output(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	//Make sure user is in root folder
	COMBI_GivePluginGlobal(sPluginName,ctrlName,num2str(checked),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	
end

Function VectorPeakFit_Guess(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//globals
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	String sPeakType = COMBI_GetPluginString(sPluginName,"sPeakType",sProject)
	String sFitName = COMBI_GetPluginString(sPluginName,"sFitName",sProject)
	String sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	String sDataX = COMBI_GetPluginString(sPluginName,"sDataX",sProject)
	String sDataY = COMBI_GetPluginString(sPluginName,"sDataY",sProject)
	String sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	String sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	int bAmpOut  = COMBI_GetPluginNumber(sPluginName,"bAmpOut",sProject)
	int bBGDOut = COMBI_GetPluginNumber(sPluginName,"bBGDOut",sProject)
	int bPosOut = COMBI_GetPluginNumber(sPluginName,"bPosOut",sProject)
	int bFWHMOut = COMBI_GetPluginNumber(sPluginName,"bFWHMOut",sProject)
	int bRawIntegral = COMBI_GetPluginNumber(sPluginName,"bRawIntegral",sProject)
	int bFitIntegral = COMBI_GetPluginNumber(sPluginName,"bFitIntegral",sProject)
	int bFitTrace =  COMBI_GetPluginNumber(sPluginName,"bFitTrace",sProject)
	int bResidualTrace =  COMBI_GetPluginNumber(sPluginName,"bResidualTrace",sProject)
	int bFitPlot =  COMBI_GetPluginNumber(sPluginName,"bFitPlot",sProject)
	int bLogPlot =  COMBI_GetPluginNumber(sPluginName,"bLogPlot",sProject)
	variable vAmplitudeMin = COMBI_GetPluginNumber(sPluginName,"vAmplitudeMin",sProject)
	variable vAmplitudeMax = COMBI_GetPluginNumber(sPluginName,"vAmplitudeMax",sProject)
	variable vBackgroundMin = COMBI_GetPluginNumber(sPluginName,"vBackgroundMin",sProject)
	variable vBackgroundMax = COMBI_GetPluginNumber(sPluginName,"vBackgroundMax",sProject)
	variable vFitRangeMin = COMBI_GetPluginNumber(sPluginName,"vFitRangeMin",sProject)
	variable vFitRangeMax = COMBI_GetPluginNumber(sPluginName,"vFitRangeMax",sProject)
	variable vPositionMin = COMBI_GetPluginNumber(sPluginName,"vPositionMin",sProject)
	variable vPositionMax = COMBI_GetPluginNumber(sPluginName,"vPositionMax",sProject)
	
	//check inputs
	VectorPeakFit_CheckInputs(sProject,sLibrary,sDataX,sDataY,sFirstSample,sLastSample,sPeakType,sFitName,bAmpOut,bBGDOut,bPosOut,bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace,bFitPlot,bLogPlot,vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax)
	
	wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX
	wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY
	
	//get waves for processing
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	variable vTotalSamples = iLastSample-iFirstSample+1
	int vVectorLength = dimsize(wXWave,1)
	make/O/N=(vTotalSamples,vVectorLength,2) wSubRangeWave
	wave wSubRangeWave = root:wSubRangeWave
	wSubRangeWave[][][0] = wXWave[iFirstSample+p][q]//get X data
	wSubRangeWave[][][1] = wYWave[iFirstSample+p][q]//get Y data
	make/O/N=(vVectorLength) wProcessX
	wave wProcessX = root:wProcessX
	make/O/N=(vVectorLength) wProcessY
	wave wProcessY = root:wProcessY
	
	//fit range
	variable vXMax = COMBI_Extremes(sProject,2,sDataX,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")
	variable vXMin = COMBI_Extremes(sProject,2,sDataX,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")
	COMBI_GivePluginGlobal(sPluginName,"vFitRangeMin",num2str(vXMin),sProject)
	COMBI_GivePluginGlobal(sPluginName,"vFitRangeMax",num2str(vXMax),sProject)
	// Amp
	variable vYMax = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")
	COMBI_GivePluginGlobal(sPluginName,"vAmplitudeMax",num2str(vYMax*1.1),sProject)
	COMBI_GivePluginGlobal(sPluginName,"vAmplitudeMin",num2str(vYMax*0.9),sProject)
	//Background
	variable vYMin = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")
	COMBI_GivePluginGlobal(sPluginName,"vBackgroundMin",num2str(vYMin*0.95),sProject)
	COMBI_GivePluginGlobal(sPluginName,"vBackgroundMax",num2str(vYMin*1.5),sProject)
	//Position
	int iVectIndex, iSample
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		for(iVectIndex=0;iVectIndex<vVectorLength;iVectIndex+=1)
			variable vThisY = wYWave[iSample][iVectIndex]
			if(vThisY == vYMax)
				variable vThisXPost = wXWave[iSample][iVectIndex+15]
				variable vThisXPre = wXWave[iSample][iVectIndex-15]
				COMBI_GivePluginGlobal(sPluginName,"vPositionMin",num2str(vThisXPre),sProject)
				COMBI_GivePluginGlobal(sPluginName,"vPositionMax",num2str(vThisXPost),sProject)
			endif
		endfor
	endfor
	
	killwaves/Z wProcessX,wProcessY,wSubRangeWave
	COMBI_VectorPeakFit()
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
End

Function VectorPeakFit_Fit(ctrlName) : ButtonControl
	String ctrlName

	//globals
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	String sPeakType = COMBI_GetPluginString(sPluginName,"sPeakType",sProject)
	String sFitName = COMBI_GetPluginString(sPluginName,"sFitName",sProject)
	String sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	String sDataX = COMBI_GetPluginString(sPluginName,"sDataX",sProject)
	String sDataY = COMBI_GetPluginString(sPluginName,"sDataY",sProject)
	String sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	String sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	String sAmpOut  = COMBI_GetPluginString(sPluginName,"bAmpOut",sProject)
	String sBGDOut = COMBI_GetPluginString(sPluginName,"bBGDOut",sProject)
	String sPosOut = COMBI_GetPluginString(sPluginName,"bPosOut",sProject)
	String sFWHMOut = COMBI_GetPluginString(sPluginName,"bFWHMOut",sProject)
	String sRawIntegral = COMBI_GetPluginString(sPluginName,"bRawIntegral",sProject)
	String sFitIntegral = COMBI_GetPluginString(sPluginName,"bFitIntegral",sProject)
	String sFitTrace =  COMBI_GetPluginString(sPluginName,"bFitTrace",sProject)
	String sResidualTrace =  COMBI_GetPluginString(sPluginName,"bResidualTrace",sProject)
	String sFitPlot =  COMBI_GetPluginString(sPluginName,"bFitPlot",sProject)
	String sLogPlot =  COMBI_GetPluginString(sPluginName,"bLogPlot",sProject)
	String sAmplitudeMin = COMBI_GetPluginString(sPluginName,"vAmplitudeMin",sProject)
	String sAmplitudeMax = COMBI_GetPluginString(sPluginName,"vAmplitudeMax",sProject)
	String sBackgroundMin = COMBI_GetPluginString(sPluginName,"vBackgroundMin",sProject)
	String sBackgroundMax = COMBI_GetPluginString(sPluginName,"vBackgroundMax",sProject)
	String sFitRangeMin = COMBI_GetPluginString(sPluginName,"vFitRangeMin",sProject)
	String sFitRangeMax = COMBI_GetPluginString(sPluginName,"vFitRangeMax",sProject)
	String sPositionMin = COMBI_GetPluginString(sPluginName,"vPositionMin",sProject)
	String sPositionMax = COMBI_GetPluginString(sPluginName,"vPositionMax",sProject)
	
	int bAmpOut  = COMBI_GetPluginNumber(sPluginName,"bAmpOut",sProject)
	int bBGDOut = COMBI_GetPluginNumber(sPluginName,"bBGDOut",sProject)
	int bPosOut = COMBI_GetPluginNumber(sPluginName,"bPosOut",sProject)
	int bFWHMOut = COMBI_GetPluginNumber(sPluginName,"bFWHMOut",sProject)
	int bRawIntegral = COMBI_GetPluginNumber(sPluginName,"bRawIntegral",sProject)
	int bFitIntegral = COMBI_GetPluginNumber(sPluginName,"bFitIntegral",sProject)
	int bFitTrace =  COMBI_GetPluginNumber(sPluginName,"bFitTrace",sProject)
	int bResidualTrace =  COMBI_GetPluginNumber(sPluginName,"bResidualTrace",sProject)
	int bFitPlot =  COMBI_GetPluginNumber(sPluginName,"bFitPlot",sProject)
	int bLogPlot =  COMBI_GetPluginNumber(sPluginName,"bLogPlot",sProject)
	variable vAmplitudeMin = COMBI_GetPluginNumber(sPluginName,"vAmplitudeMin",sProject)
	variable vAmplitudeMax = COMBI_GetPluginNumber(sPluginName,"vAmplitudeMax",sProject)
	variable vBackgroundMin = COMBI_GetPluginNumber(sPluginName,"vBackgroundMin",sProject)
	variable vBackgroundMax = COMBI_GetPluginNumber(sPluginName,"vBackgroundMax",sProject)
	variable vFitRangeMin = COMBI_GetPluginNumber(sPluginName,"vFitRangeMin",sProject)
	variable vFitRangeMax = COMBI_GetPluginNumber(sPluginName,"vFitRangeMax",sProject)
	variable vPositionMin = COMBI_GetPluginNumber(sPluginName,"vPositionMin",sProject)
	variable vPositionMax = COMBI_GetPluginNumber(sPluginName,"vPositionMax",sProject)
	//pass
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		Print "VectorPeakFit_PeakFit(\""+sProject+"\",\""+sLibrary+"\",\""+sDataX+"\",\""+sDataY+"\",\""+sFirstSample+"\",\""+sLastSample+"\",\""+sPeakType+"\",\""+sFitName+"\","+sAmpOut+","+sBGDOut+","+sPosOut+","+sFWHMOut+","+sRawIntegral+","+sFitIntegral+","+sFitTrace+","+sResidualTrace+","+sFitPlot+","+sLogPlot+","+sAmplitudeMin+","+sAmplitudeMax+","+sBackgroundMin+","+sBackgroundMax+","+sFitRangeMin+","+sFitRangeMax+","+sPositionMin+","+sPositionMax+")"
	endif
	VectorPeakFit_PeakFit(sProject,sLibrary,sDataX,sDataY,sFirstSample,sLastSample,sPeakType,sFitName,bAmpOut,bBGDOut,bPosOut,bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace,bFitPlot,bLogPlot,vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax)
End

Function VectorPeakFit_Update(ctrlName) : ButtonControl
	String ctrlName
		COMBI_VectorPeakFit()
End

Function VectorPeakFit_CheckInputs(sProject,sLibrary,sDataX,sDataY,sFirstSample,sLastSample,sPeakType,sFitName,bAmpOut,bBGDOut,bPosOut,bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace,bFitPlot,bLogPlot,vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax)
	string sProject,sPeakType,sFitName,sLibrary,sDataX,sDataY,sFirstSample,sLastSample
	int bAmpOut,bBGDOut,bPosOut,	bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace, bFitPlot, bLogPlot
	variable vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//data x
	if(!waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX))

		Doalert/T="Bad Inputs",0," No such X data inputs. COMBIgor was looking for: "+COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	else
		wave wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX
	endif
	//data y
	if(!waveexists($COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY))
		Doalert/T="Bad Inputs",0," No such Y data inputs. COMBIgor was looking for: "+COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return-1
	else
		wave wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY
	endif
	//firstSample
	if(dimsize(wXWave,0)<(str2num(sFirstSample)-1)||str2num(sFirstSample)<1)
		Doalert/T="Bad Inputs",0,"Sample range must be between 1 and "+num2str(dimsize(wXWave,0)+1)
	endif
	//lastSample
	if(dimsize(wXWave,0)<(str2num(sLastSample)-1)||str2num(sLastSample)<1)
		Doalert/T="Bad Inputs",0,"Sample range must be between 1 and "+num2str(dimsize(wXWave,0)+1)
	endif
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end



Function VectorPeakFit_PeakFit(sProject,sLibrary,sDataX,sDataY,sFirstSample,sLastSample,sPeakType,sFitName,bAmpOut,bBGDOut,bPosOut,bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace,bFitPlot,bLogPlot,vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax)
	string sProject,sPeakType,sFitName,sLibrary,sDataX,sDataY,sFirstSample,sLastSample
	int bAmpOut,bBGDOut,bPosOut,	bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace,bFitPlot,bLogPlot
	variable vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//check inputs
	VectorPeakFit_CheckInputs(sProject,sLibrary,sDataX,sDataY,sFirstSample,sLastSample,sPeakType,sFitName,bAmpOut,bBGDOut,bPosOut,bFWHMOut,bRawIntegral,bFitIntegral,bFitTrace,bResidualTrace,bFitPlot,bLogPlot,vAmplitudeMin,vAmplitudeMax,vBackgroundMin,vBackgroundMax,vFitRangeMin,vFitRangeMax,vPositionMin,vPositionMax)
	//Get Wave	s
	wave wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataX
	wave wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDataY
	//get idea of processing
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	variable vTotalSamples = iLastSample-iFirstSample+1
	int vVectorLength = dimsize(wXWave,1)
	
	//range empty?
	if(numtype(vFitRangeMin)!=0)
		vFitRangeMin = COMBI_Extremes(sProject,2,sDataX,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")
	endif
	if(numtype(vFitRangeMax)!=0)
		vFitRangeMax = COMBI_Extremes(sProject,2,sDataX,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")
	endif
	//get peak guess
	int iVectIndex, iSample
	variable vGuessPosMin,vGuessPosMax
	variable vYMax = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		for(iVectIndex=0;iVectIndex<vVectorLength;iVectIndex+=1)
			variable vThisY = wYWave[iSample][iVectIndex]
			if(vThisY == vYMax)
				vGuessPosMax = wXWave[iSample][iVectIndex+15]
				vGuessPosMin = wXWave[iSample][iVectIndex-15]
			endif
		endfor
	endfor
	//Pos empty?
	if(numtype(vPositionMin)!=0)
		vPositionMin = vGuessPosMin
	endif
	if(numtype(vPositionMax)!=0)
		vPositionMax = vGuessPosMax
	endif
	//amp empty
	if(numtype(vAmplitudeMin)!=0)
		vAmplitudeMin = 0
	endif
	if(numtype(vAmplitudeMax)!=0)
		vAmplitudeMax = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Max")*1.1
	endif
	//Bkgd empty?
	if(numtype(vBackgroundMin)!=0)
		vBackgroundMin = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")*0.9
	endif
	if(numtype(vBackgroundMax)!=0)
		vBackgroundMax = COMBI_Extremes(sProject,2,sDataY,sLibrary,sFirstSample+";"+sLastSample+"; ; ; ; ","Min")*2
	endif
	
	int iVector, iVectorStart, iVectorEnd
	for(iVector=0;iVector<vVectorLength-1;iVector+=1)
		variable vThisX = wXWave[iFirstSample][iVector]
		variable vNextX = wXWave[iFirstSample][iVector+1]
		if((vThisX<=vFitRangeMin)&&(vNextX>vFitRangeMin))
			iVectorStart = iVector			
		endif
		if((vThisX<vFitRangeMax)&&(vNextX>=vFitRangeMax))
			iVectorEnd = iVector+1	
		endif
	endfor
	int vSubVectorLength = (iVectorEnd-iVectorStart+1)
	
	//make process waves
	make/O/N=(vSubVectorLength) wProcessX
	wave wProcessX = root:wProcessX
	make/O/N=(vSubVectorLength) wProcessY
	wave wProcessY = root:wProcessY
	make/O/N=(vSubVectorLength) wFitY
	wave wFitY = root:wFitY
	make/O/N=(vSubVectorLength) wFitX
	wave wFitX = root:wFitX

	//make constraint wave
	Make/D/N=1/O/T wLimitsWave
	wave/T wLimitsWave = root:wLimitsWave
	string sThisConstraint 
	int iLimitNum = 0
	
	//amp - K0
	if(numtype(vAmplitudeMin)==0)
		sThisConstraint = "K0 >= 0"
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	if(numtype(vAmplitudeMax)==0)
		sThisConstraint = "K0 <= "+num2str(vAmplitudeMax)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	//pos - K1
	if(numtype(vPositionMin)==0)
		sThisConstraint = "K1 >= "+num2str(vPositionMin)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	if(numtype(vPositionMax)==0)
		sThisConstraint = "K1 <= "+num2str(vPositionMax)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	//width - K2
	sThisConstraint = "K2 > 0"
	if(iLimitNum == dimsize(wLimitsWave,0)) //no room
		Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
	endif
	wLimitsWave[iLimitNum] = sThisConstraint
	iLimitNum+=1
	//bkg - K3
	if(numtype(vBackgroundMin)==0)
		sThisConstraint = "K3 >= "+num2str(vBackgroundMin)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	if(numtype(vBackgroundMax)==0)
		sThisConstraint = "K3 <= "+num2str(vBackgroundMax)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	//fracGaus - K4
	if(stringmatch(sPeakType,"PseudoVoigt"))
		sThisConstraint = "K4 >= "+num2str(0)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
		sThisConstraint = "K4 <= "+num2str(1)
		if(iLimitNum == dimsize(wLimitsWave,0)) //no room
			Redimension/N=(dimsize(wLimitsWave,0)+1) wLimitsWave 
		endif
		wLimitsWave[iLimitNum] = sThisConstraint
		iLimitNum+=1
	endif
	
	//for plot exporting
	if(bFitPlot==1)
		string sExportPath =COMBI_ExportPath("Read")
		if(stringmatch(sExportPath,"NO PATH"))
			sExportPath =COMBI_ExportPath("Temp")
		endif
		NewPath/Q/Z/O/C pExportPath sExportPath+sLibrary+":"
		NewPath/Q/Z/O/C pExportPath sExportPath+sLibrary+":Peak Fits:"
		NewPath/Q/Z/O/C pExportPath sExportPath+sLibrary+":Peak Fits:"+sDataY
	endif
	
	int iLogStatus
	variable vPlotYMax, vPlotYMin
	if(bLogPlot==1)
		iLogStatus =1
		vPlotYMax = vAmplitudeMax
		if(vBackgroundMin<=0)
			vPlotYMin = 1
		else
			vPlotYMin = vBackgroundMin
		endif
	else
		iLogStatus =0
		vPlotYMax = vAmplitudeMax
		vPlotYMin = vBackgroundMin
	endif
	
	//type of peak
	string sPeakFunction = sPeakType+"Peak"
	string sLog1,sLog2,sLog3,sLog4,sLog5
	//do for all Samples
	string sFitPlotWindow, sGraphicName
	variable vRawIntegral, vThisXDelta
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		sFitPlotWindow = "FitDisplayWindow_Pt"+num2str(iSample+1)
		sGraphicName = sLibrary+"_"+sDataY+"vs"+sDataX+"_"+sPeakType+"_Pt"+num2str(iSample+1)+".pdf"
		//populate process waves
		wProcessX[] = wXWave[iSample][iVectorStart+p]
		wProcessY[] = wYWave[iSample][iVectorStart+p]
		//coefficient wave
		if(stringmatch(sPeakType,"PseudoVoigt"))
			Make/D/O/N=(5) wCoeffWave
			wave wCoeffWave = root:wCoeffWave
			wCoeffWave[0] = COMBI_Extremes(sProject,2,sDataY,sLibrary,num2str(iSample+1)+";"+num2str(iSample+1)+"; ; ; ; ","Max")
			wCoeffWave[1] = (vPositionMin+vPositionMax)/2
			wCoeffWave[2] = Abs((vPositionMax-vPositionMin)/2)
			wCoeffWave[3] = (vBackgroundMin+vBackgroundMax)/2
			wCoeffWave[4] = 0.9
		else
			Make/D/O/N=(4) wCoeffWave
			wave wCoeffWave = root:wCoeffWave
			wCoeffWave[0] = COMBI_Extremes(sProject,2,sDataY,sLibrary,num2str(iSample+1)+";"+num2str(iSample+1)+"; ; ; ; ","Max")
			wCoeffWave[1] = (vPositionMin+vPositionMax)/2
			wCoeffWave[2] = Abs((vPositionMax-vPositionMin))/2
			wCoeffWave[3] = (vBackgroundMin+vBackgroundMax)/2
		endif
		//prefitplot
		Killwindow/Z $sFitPlotWindow
		COMBI_NewPlot(sFitPlotWindow)
		AppendToGraph/W=$sFitPlotWindow wProcessY[] vs wProcessX[]
		ModifyGraph mode(wProcessY)=3,rgb(wProcessY)=(0,0,0)
		//for data log
		sLog1 = "Peak Type: "+sPeakType
		sLog2 = "Data Fit in Vector Table: "+sDataY+" as a function of "+sDataX
		sLog4 = "FitRange: "+num2str(vFitRangeMin)+" to "+num2str(vFitRangeMax)
		//fit
		FuncFit/Q/C $sPeakFunction, wCoeffWave, wProcessY[] /X=wProcessX[] /C=wLimitsWave
		//popuate fit wave
		if(stringmatch(sPeakType,"PseudoVoigt"))
			wFitY[] = PseudoVoigtPeak(wCoeffWave,wProcessX[p])
			sLog3 = "Fit: "+PrintPseudoVoigtPeak(wCoeffWave)
		elseif(stringmatch(sPeakType,"Gaussian"))
			wFitY[] = GaussianPeak(wCoeffWave,wProcessX[p])
			sLog3 = "Fit: "+PrintGaussianPeak(wCoeffWave)
		elseif(stringmatch(sPeakType,"Lorentzian"))
			wFitY[] = LorentzianPeak(wCoeffWave,wProcessX[p])
			sLog3 = "Fit: "+PrintLorentzianPeak(wCoeffWave)
		endif
		//append fit
		AppendToGraph/W=$sFitPlotWindow  wFitY[] vs wProcessX[]
		ModifyGraph lstyle(wFitY)=3, lsize(wFitY)=2
		//StylePlot
		ModifyGraph log(left)=iLogStatus,tick(bottom)=3,mirror=2,lblMargin=5, margin(right)=110
		Label left COMBIDisplay_GetAxisLabel(sDataY)
		Label bottom COMBIDisplay_GetAxisLabel(sDataX)
		SetAxis left vPlotYMin,vPlotYMax
		SetAxis bottom vFitRangeMin,vFitRangeMax
		if(stringmatch(sPeakType,"PseudoVoigt"))
			TextBox/C/N=FitResult/F=0/Z=1/A=RC/X=2/Y=0.00/E=2 "\\K(0,0,0)Amplitude:\r\t\K(65535,0,0)"+num2str(wCoeffWave[0])+"\r\r\K(0,0,0)Position:\r\t\K(65535,0,0)"+num2str(wCoeffWave[1])+"\r\r\K(0,0,0)FWHM:\r\t\K(65535,0,0)"+num2str(2*wCoeffWave[2])+"\r\r\K(0,0,0)Background:\r\t\K(65535,0,0)"+num2str(wCoeffWave[3])+"\r\r\K(0,0,0)Fraction Gaussian:\r\t\K(65535,0,0)"+num2str(wCoeffWave[4])+""
		else
			TextBox/C/N=FitResult/F=0/Z=1/A=RC/X=2/Y=0.00/E=2 "\\K(0,0,0)Amplitude:\r\t\K(65535,0,0)"+num2str(wCoeffWave[0])+"\r\r\K(0,0,0)Position:\r\t\K(65535,0,0)"+num2str(wCoeffWave[1])+"\r\r\K(0,0,0)FWHM:\r\t\K(65535,0,0)"+num2str(2*wCoeffWave[2])+"\r\r\K(0,0,0)Background:\r\t\K(65535,0,0)"+num2str(wCoeffWave[3])
		endif
		DoUpdate/W=$sFitPlotWindow
		Sleep/S 0.1 //so the user can see the plot window
		//do exporting
		sFitName = cleanupName(sFitName,0)
		string sTotalFit
		if(bAmpOut)
			COMBI_GiveScalar(wCoeffWave[0],sProject,sLibrary,sFitName+"_Amp",iSample)
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_Amp",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bBGDOut)
			COMBI_GiveScalar(wCoeffWave[3],sProject,sLibrary,sFitName+"_Bkgrd",iSample)
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_Bkgrd",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bPosOut)
			COMBI_GiveScalar(wCoeffWave[1],sProject,sLibrary,sFitName+"_Position",iSample)
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_Position",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bFWHMOut)
			COMBI_GiveScalar(wCoeffWave[2]*2,sProject,sLibrary,sFitName+"_FWHM",iSample)
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_FWHM",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bRawIntegral)
			vRawIntegral = 0
			for(iVector=0;iVector<vSubVectorLength-1;iVector+=1)
				vThisXDelta = wProcessX[iVector+1]-wProcessX[iVector]
				vRawIntegral+= (vThisXDelta)*(wProcessY[iVector]-wCoeffWave[3])
			endfor
			COMBI_GiveScalar(vRawIntegral,sProject,sLibrary,sFitName+"_RawIntegral",iSample)
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_RawIntegral",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bFitIntegral)
			vRawIntegral = 0
			for(iVector=0;iVector<vSubVectorLength-1;iVector+=1)
				vThisXDelta = wProcessX[iVector+1]-wProcessX[iVector]
				vRawIntegral+= (vThisXDelta)*(wFitY[iVector]-wCoeffWave[3])
			endfor
			COMBI_GiveScalar(vRawIntegral,sProject,sLibrary,sFitName+"_FitIntegral",iSample)
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_FitIntegral",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		int vOrgSize
		int vNeededSize
		if(bFitTrace)
			COMBI_AddDataType(sProject,sLibrary,sFitName+"_FitY",2)
			COMBI_AddDataType(sProject,sLibrary,sFitName+"_FitX",2)
			wave wVectorWaveY = $COMBI_DataPAth(sProject,2)+sLibrary+":"+sFitName+"_FitY"
			wave wVectorWaveX = $COMBI_DataPAth(sProject,2)+sLibrary+":"+sFitName+"_FitX"
			vOrgSize = dimsize(wVectorWaveY,1); vNeededSize = dimsize(wProcessY,0)
			if(vNeededSize>vOrgSize)
				redimension/N=(-1,vNeededSize) wVectorWaveY
			endif
			vOrgSize = dimsize(wVectorWaveX,1); vNeededSize = dimsize(wProcessX,0)
			if(vNeededSize>vOrgSize)
				redimension/N=(-1,vNeededSize) wVectorWaveX
			endif
			SetScale/I y,vFitRangeMin,vFitRangeMax,wVectorWaveY
			SetScale/I x,1,dimsize(wVectorWaveY,0),wVectorWaveY
			wVectorWaveY[iSample][] = nan
			wVectorWaveY[iSample][] = wFitY[q]
			wVectorWaveX[iSample][] = nan
			wVectorWaveX[iSample][] = wProcessX[q]
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_FitY",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bResidualTrace)
			COMBI_AddDataType(sProject,sLibrary,sFitName+"_FitResidualY",2)
			COMBI_AddDataType(sProject,sLibrary,sFitName+"_FitX",2)
			wave wVectorWaveY = $COMBI_DataPAth(sProject,2)+sLibrary+":"+sFitName+"_FitResidualY"
			wave wVectorWaveX = $COMBI_DataPAth(sProject,2)+sLibrary+":"+sFitName+"_FitX"
			vOrgSize = dimsize(wVectorWaveY,1); vNeededSize = dimsize(wFitY,0)
			if(vNeededSize>vOrgSize)
				redimension/N=(-1,vNeededSize) wVectorWaveY
			endif
			vOrgSize = dimsize(wVectorWaveX,1); vNeededSize = dimsize(wProcessX,0)
			if(vNeededSize>vOrgSize)
				redimension/N=(-1,vNeededSize) wVectorWaveX
			endif
			SetScale/I y,vFitRangeMin,vFitRangeMax,wVectorWaveY
			SetScale/I x,1,dimsize(wVectorWaveY,0),wVectorWaveY
			wVectorWaveY[iSample][] = nan
			wVectorWaveY[iSample][] = wProcessY[q]-wFitY[q]
			wVectorWaveX[iSample][] = nan
			wVectorWaveX[iSample][] = wProcessX[q]
			COMBI_Add2Log(sProject,sLibrary,sFitName+"_FitResidualY",1,sLog1+";"+sLog2+";"+sLog3+";"+sLog4+";")
		endif
		if(bFitPlot==1)
			SavePICT/O/P=pExportPath/E=-2 as sGraphicName
		endif
		Killwindow/Z $sFitPlotWindow
	endfor
	
	//clean up
	killwaves/Z wProcessY, wProcessX, wCoeffWave, wFitY,wFitX, W_sigma,W_FitConstraint,wCoeffWave,M_FitConstraint,wLimitsWave
	Killpath/Z/A
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

Function GaussianPeak(wCoef,x) : FitFunc
	Wave wCoef//AMP,POS,FWHM,BKG
	Variable x
	return wCoef[0]*exp(-(((x-wCoef[1])^2)/(2*wCoef[2]^2)))+wCoef[3]
End

Function LorentzianPeak(wCoef,x) : FitFunc
	Wave wCoef//AMP,POS,FWHM,BKG
	Variable x
	return (wCoef[0]/(1+((x-wCoef[1])/wCoef[2])^2))+wCoef[3]
End

Function PseudoVoigtPeak(wCoef,x) : FitFunc
	Wave wCoef//AMP,POS,FWHM,BKG,FracGaus
	Variable x
	return ((wCoef[0]*exp(-(((x-wCoef[1])^2)/(2*wCoef[2]^2))))*(wCoef[4]))+((1-wCoef[4])*(wCoef[0]/(1+((x-wCoef[1])/wCoef[2])^2)))+wCoef[3]
End

Function/S PrintGaussianPeak(wCoef)
	Wave wCoef//AMP,POS,FWHM,BKG
	return num2str(wCoef[0])+"*exp(-(((x-"+num2str(wCoef[1])+")^2)/(2*"+num2str(wCoef[2])+"^2)))+"+num2str(wCoef[3])
End

Function/S PrintLorentzianPeak(wCoef)
	Wave wCoef//AMP,POS,FWHM,BKG
	return "("+num2str(wCoef[0])+"/(1+((x-"+num2str(wCoef[1])+")/"+num2str(wCoef[2])+")^2))+"+num2str(wCoef[3])
End

Function/S PrintPseudoVoigtPeak(wCoef)
	Wave wCoef//AMP,POS,FWHM,BKG,FracGaus
	return "(("+num2str(wCoef[0])+"*exp(-(((x-"+num2str(wCoef[1])+")^2)/(2*"+num2str(wCoef[2])+"^2))))*("+num2str(wCoef[4])+"))+((1-"+num2str(wCoef[4])+")*("+num2str(wCoef[0])+"/(1+((x-"+num2str(wCoef[1])+")/"+num2str(wCoef[2])+")^2)))+"+num2str(wCoef[3])
End