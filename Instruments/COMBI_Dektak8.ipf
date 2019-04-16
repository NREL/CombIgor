#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original Example 
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

//Description of procedure purpose:
///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Instruments"
		Submenu  "Dektak8"
			"Process",/Q, Combi_Dektak8()
			"Thickness Map",/Q, Dektak8_ThicknessMap()
		end
	end
end

//this function is run when the user selects the Instrument from the Combigor drop down menu once activated
function Combi_Dektak8()
	string sPluginName = "Dektak8"
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//check if initialized, get starting values if so, initialize if not
	string sProject, sLibrary, sFirstSample, sLastSample, sFileName, sScanDirection, sScanStartStops, sScanLengths, sScanStartsY, sScanStartsX,sFeaturesPerScan, sFeatures2Exclude
	string sScan2Move,sScanMoveDelta, sDataLengths, vScan2Edit, vFeature2Edit, sThisStartStop, sTraceName, sFeatureMarker, sFeatureSpacings, sFocus2Edit, sXCurve, sYCurve
	int iActiveTab, vTotalScans, bScansDefined, iColor, vFeatureStart, vFeatureStop, bMaskDefined
	int iScan, iFeature, vCurvatureRemovalOrder,  iFScan, iLScan, iFFeature, iLFeature
	variable vFeatures, vFeatureDistance, vSmoothFactor, vThisDataLength, vFeatureWidth, vFilmWidth, vOffset, vMaskScaling
	int bExportPlots, bDeleteProcessData, bInterpThickness, bFitThickness, vFilmSubPoly

	if(stringmatch("NAG",Combi_GetInstrumentString(sPluginName,"sProject","COMBIgor")))
		//not yet initialized
		Combi_GiveInstrumentGlobal(sPluginName,"sProject",Combi_ChooseProject(),"COMBIgor")
		sProject = Combi_GetInstrumentString(sPluginName,"sProject","COMBIgor")
	else
		//previously initialized
		sProject = Combi_GetInstrumentString(sPluginName,"sProject","COMBIgor")
	endif
	
	if(stringmatch("NAG",Combi_GetInstrumentString(sPluginName,"sProject",sProject)))//define new global values
		Combi_GiveInstrumentGlobal(sPluginName,"sProject",sProject,sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sLibrary","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sFileName","NONE LOADED",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"iActiveTab","0",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vTotalScans","0",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sFirstSample","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sLastSample",Combi_GetGlobalString("vTotalSamples", sProject),sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScanDirection","+x",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScanStartStops","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScanLengths","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScanStartsY","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScanStartsX","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sFeaturesPerScan","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sFeatureSpacings","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScan2Move","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sScanMoveDelta","0.5",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sDataLengths","",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"bScansDefined","0",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vScan2Edit","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vCurvatureRemovalOrder","3",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vFilmSubPoly","5",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vFeature2Edit","All",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vSmoothFactor","0",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vFeatureWidth","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vFilmWidth","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vMaskScaling","100",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"vOffset","0",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sFocus2Edit","Film",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sXCurve","Either",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sYCurve","Either",sProject)
		//export options
		Combi_GiveInstrumentGlobal(sPluginName,"bExportPlots","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"bDeleteProcessData","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"bInterpThickness","0",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"bFitThickness","1",sProject)
		Combi_GiveInstrumentGlobal(sPluginName,"sFeatures2Exclude","",sProject)
	endif

	//get predefined globals 
	sFocus2Edit = Combi_GetInstrumentString(sPluginName,"sFocus2Edit",sProject)
	sXCurve = Combi_GetInstrumentString(sPluginName,"sXCurve",sProject)
	sYCurve = Combi_GetInstrumentString(sPluginName,"sYCurve",sProject)
	sFeatureSpacings = Combi_GetInstrumentString(sPluginName,"sFeatureSpacings",sProject)
	sScanStartsY = Combi_GetInstrumentString(sPluginName,"sScanStartsY",sProject)
	sScanStartsX = Combi_GetInstrumentString(sPluginName,"sScanStartsX",sProject)
	vTotalScans = Combi_GetInstrumentNumber(sPluginName,"vTotalScans",sProject)
	sFileName = Combi_GetInstrumentString(sPluginName,"sFileName",sProject)
	sLibrary = Combi_GetInstrumentString(sPluginName,"sLibrary",sProject)
	sFirstSample = Combi_GetInstrumentString(sPluginName,"sFirstSample",sProject)
	sLastSample = Combi_GetInstrumentString(sPluginName,"sLastSample",sProject)
	iActiveTab = Combi_GetInstrumentNumber(sPluginName,"iActiveTab",sProject)
	sScanDirection = Combi_GetInstrumentString(sPluginName,"sScanDirection",sProject)
	sScanStartStops = Combi_GetInstrumentString(sPluginName,"sScanStartStops",sProject)
	sScanLengths = Combi_GetInstrumentString(sPluginName,"sScanLengths",sProject)
	sFeaturesPerScan = Combi_GetInstrumentString(sPluginName,"sFeaturesPerScan",sProject)
	sScan2Move = Combi_GetInstrumentString(sPluginName,"sScan2Move",sProject)
	sScanMoveDelta = Combi_GetInstrumentString(sPluginName,"sScanMoveDelta",sProject)
	sDataLengths  = Combi_GetInstrumentString(sPluginName,"sDataLengths",sProject)
	bScansDefined = Combi_GetInstrumentNumber(sPluginName,"bScansDefined",sProject)
	bMaskDefined = Combi_GetInstrumentNumber(sPluginName,"bMaskDefined",sProject)
	vCurvatureRemovalOrder = Combi_GetInstrumentNumber(sPluginName,"vCurvatureRemovalOrder",sProject)
	vScan2Edit = Combi_GetInstrumentString(sPluginName,"vScan2Edit",sProject)
	vFeature2Edit = Combi_GetInstrumentString(sPluginName,"vFeature2Edit",sProject)
	vSmoothFactor = Combi_GetInstrumentNumber(sPluginName,"vSmoothFactor",sProject)
	vOffset = Combi_GetInstrumentNumber(sPluginName,"vOffset",sProject)
	vMaskScaling = Combi_GetInstrumentNumber(sPluginName,"vMaskScaling",sProject)
	vFilmSubPoly = Combi_GetInstrumentNumber(sPluginName,"vFilmSubPoly",sProject)
	//export options
	bExportPlots = Combi_GetInstrumentNumber(sPluginName,"bExportPlots",sProject)
	bDeleteProcessData = Combi_GetInstrumentNumber(sPluginName,"bDeleteProcessData",sProject)
	bInterpThickness = Combi_GetInstrumentNumber(sPluginName,"bInterpThickness",sProject)
	bFitThickness = Combi_GetInstrumentNumber(sPluginName,"bFitThickness",sProject)
	sFeatures2Exclude = Combi_GetInstrumentString(sPluginName,"sFeatures2Exclude",sProject)
	
	
	//get Libraries space values
	variable vLibraryWidth = Combi_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = Combi_GetGlobalNumber("vLibraryHeight",sProject)
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	variable vColumnSpacing = Combi_GetGlobalNumber("vColumnSpacing",sProject)
	variable vRowSpacing = Combi_GetGlobalNumber("vRowSpacing",sProject)
	int bXAxisFlip = Combi_GetGlobalNumber("bXAxesFlip",sProject)
	int bYAxisFlip = Combi_GetGlobalNumber("bYAxesFlip",sProject)
	string sOrigin = Combi_GetGlobalString("sOrigin",sProject)
	
	//get Sample index
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	
	//get waves
	wave/T twGlobals = root:Packages:COMBIgor:Instruments:Combi_Dektak8_Globals
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	
	//kill if open already, storing position
	PauseUpdate; Silent 1 // pause for building window...
	variable vWinLeft 
	variable vWinTop 
	GetWindow/Z Dektak8Panel wsize
	vWinLeft = V_left
	vWinTop = V_top
	if(vWinLeft==0&&0==vWinTop)
		vWinLeft = 20
		vWinTop = 20
	endif
	KillWindow/Z Dektak8Panel
	
	//make panel
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	int iPanelHeight, iPanelWide
	if(iActiveTab==0)//Destination
		iPanelHeight = 135
		iPanelWide = 300
	elseif(iActiveTab==1)//Scans
		if(bScansDefined==1)
			iPanelHeight = 525
			iPanelWide = 300
		else
			iPanelHeight = 390
			iPanelWide = 300
		endif
	elseif(iActiveTab==2)//Masks
		if(bScansDefined==1)
			iPanelHeight = 370
			iPanelWide = 600
		else
			iPanelHeight = 60
			iPanelWide = 300
		endif 
	elseif(iActiveTab==3)//Outputs
		if(bScansDefined==1&&bMaskDefined==1)
			iPanelHeight = 520
			iPanelWide = 600
		else
			iPanelHeight = 60
			iPanelWide = 300
		endif 
	endif
	
	NewPanel/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+iPanelWide,vWinTop+iPanelHeight)/N=Dektak8Panel as "COMBIgor Dektak8 MappingGrid"
	SetDrawLayer ProgBack
	SetDrawEnv fname = sFont,textxjust = 2,textyjust = 1,fsize = 12,save
	variable vYValue = 5
	
	//processing tabs
	TabControl DekTak8Processing size={260,20},pos={20,vYValue},tabLabel(0)="Destination",tabLabel(1)="Scans",tabLabel(2)="Mask",tabLabel(3)="Output",Value=iActiveTab,proc=Dektak8_TabAction
	DrawLine 5,vYValue+25,290,vYValue+25
	
	//draw each tab
	if(iActiveTab==0)//Destination
		//Project
		vYValue+=40
		DrawText 90,vYValue, "Project:"
		PopupMenu sProject,pos={230,vYValue-10},mode=1,bodyWidth=190,value=Combi_Projects(),proc=Dektak8_UpdateGlobal,popvalue=sProject
		//new things
		vYValue+=25
		button sNewLibrary,title="New Library",appearance={native,All},pos={23,vYValue-10},size={120,20},proc=Dektak8_New,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
		button sNewDataType,title="New Data Type",appearance={native,All},pos={156,vYValue-10},size={120,20},proc=Dektak8_New,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
		//Library
		vYValue+=25
		DrawText 90,vYValue, "Library:"
		PopupMenu sLibrary,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+Dektak8_DropList("Libraries"),proc=Dektak8_UpdateGlobal,popvalue=sLibrary
		//Sample range
		vYValue+=25
		DrawText 90,vYValue, "Samples:"
		DrawText 195,vYValue, " - "
		SetVariable sFirstSample, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%sFirstSample][%$sProject]
		SetVariable sLastSample, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=0,font=sFont,value=twGlobals[%sLastSample][%$sProject]	
	
	elseif(iActiveTab==1)//Scans
		//Load Scan button
		vYValue+=30
		button btLoadScan,title="Load Scan Data",appearance={native,All},pos={25,vYValue},size={250,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_LoadButton
		vYValue+=30
		SetDrawEnv textxjust = 1,save; 
		DrawText 150,vYValue, num2str(vTotalScans)+" data scans from .csv named:"
		vYValue+=15
		SetDrawEnv textxjust = 1,save; DrawText 150,vYValue, removeending(sFileName,".csv"); SetDrawEnv textxjust = 2,save; 
		DrawLine 5,vYValue+13,290,vYValue+13
		//add Library plot
		vYValue+=20
		Display/HOST=Dektak8Panel/W=(10,vYValue,290,vYValue+280)/N=ScanPlot wMappingGrid[iFirstSample,iLastSample][2] vs wMappingGrid[iFirstSample,iLastSample][1]
		ModifyGraph/W=Dektak8Panel#ScanPlot margin=30, margin(left)=40,margin(bottom)=40
		ModifyGraph/W=Dektak8Panel#ScanPlot tick=3,mirror=3
		ModifyGraph/W=Dektak8Panel#ScanPlot mode=3,marker=43,msize=4,rgb=(0,0,0)
		ModifyGraph/W=Dektak8Panel#ScanPlot gbRGB=(65535.,65535.,65535.)
		ModifyGraph/W=Dektak8Panel#ScanPlot wbRGB=(61166,61166,61166)
		Label/W=Dektak8Panel#ScanPlot left "y (mm)"
		Label/W=Dektak8Panel#ScanPlot bottom "x (mm)"
		ModifyGraph/W=Dektak8Panel#ScanPlot fSize=12,font=sFont
		if(bXAxisFlip==1)
			SetAxis bottom vLibraryWidth,0
		else
			SetAxis bottom 0,vLibraryWidth
		endif
		if(bYAxisFlip==1)
			SetAxis left 0,vLibraryHeight
		else
			SetAxis left vLibraryHeight,0
		endif
		SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),arrow= 1,linethick= 1.00, textrgb= (65535,0,0),textxjust= 1,textyjust= 1,save
		if(bScansDefined==1)
			for(iScan=0;iScan<vTotalScans;iScan+=1)
				variable vThisStartX, vThisStartY, vThisScanLength
				vThisStartX = str2num(stringfromlist(iScan,sScanStartsX))
				vThisStartY = str2num(stringfromlist(iScan,sScanStartsY))
				vThisScanLength = str2num(stringfromlist(iScan,sScanLengths))
				if(stringmatch(sScanDirection,"+x"))
					DrawText/W=Dektak8Panel#ScanPlot vThisStartX-2,vThisStartY,num2str(iScan+1)
					DrawLine/W=Dektak8Panel#ScanPlot vThisStartX,vThisStartY,vThisStartX+vThisScanLength,vThisStartY
					sFeatureMarker ="\Z16\f01\\W5010"
				elseif(stringmatch(sScanDirection,"-x"))
					DrawText/W=Dektak8Panel#ScanPlot vThisStartX+2,vThisStartY,num2str(iScan+1)
					DrawLine/W=Dektak8Panel#ScanPlot vThisStartX,vThisStartY,vThisStartX-vThisScanLength,vThisStartY
					sFeatureMarker ="\Z16\f01\\W5010"
				elseif(stringmatch(sScanDirection,"+y"))
					DrawText/W=Dektak8Panel#ScanPlot vThisStartX,vThisStartY-2,num2str(iScan+1)
					DrawLine/W=Dektak8Panel#ScanPlot vThisStartX,vThisStartY,vThisStartX,vThisStartY+vThisScanLength
					sFeatureMarker ="\Z16\f01\\W5009"
				elseif(stringmatch(sScanDirection,"-y"))
					DrawText/W=Dektak8Panel#ScanPlot vThisStartX,vThisStartY+2,num2str(iScan+1)
					DrawLine/W=Dektak8Panel#ScanPlot vThisStartX,vThisStartY,vThisStartX,vThisStartY-vThisScanLength
					sFeatureMarker ="\Z16\f01\\W5009"
				endif
			endfor
			wave/Z wResults = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results"
			if(waveexists(wResults))
				for(iFeature=0;iFeature<dimsize(wResults,0);iFeature+=1)
					DrawText/W=Dektak8Panel#ScanPlot wResults[iFeature][0],wResults[iFeature][1], sFeatureMarker
				endfor
			endif
		endif
		SetActiveSubwindow Dektak8Panel
		vYValue+=295	
		//scan move buttons
		if(bScansDefined==1)
			//scan define button
			DrawLine 5,vYValue,290,vYValue
			vYValue+=10
			button btScanDefine,title="Define Scans",appearance={native,All},pos={25,vYValue},size={250,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_ScanDefine
			SetDrawEnv fname = sFont,textxjust = 2,textyjust = 1,fsize = 12,save
			vYValue+=34
			DrawText 125,vYValue, "Move scan  "
			PopupMenu sScan2Move,pos={110,vYValue-9},mode=1,bodyWidth=40,value=Dektak8_DropList("Scan#s"),proc=Dektak8_UpdateGlobal,popvalue=sScan2Move
			DrawText 180,vYValue, "by"
			PopupMenu sScanMoveDelta,pos={175,vYValue-9},mode=1,bodyWidth=40,value="0.05;0.1;0.25;0.5;1;2;5;10",proc=Dektak8_UpdateGlobal,popvalue=sScanMoveDelta
			DrawText 250,vYValue, "mm"
			vYValue+=16
			button btMoveL,title="←",appearance={native,All},pos={-300/10+300/4*0.5,vYValue},size={300/5,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=20, proc=Dektak8_ScanMove
			button btMoveR,title="→",appearance={native,All},pos={-300/10+300/4*1.5,vYValue},size={300/5,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=20, proc=Dektak8_ScanMove
			button btMoveU,title="↑",appearance={native,All},pos={-300/10+300/4*2.5,vYValue},size={300/5,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=20, proc=Dektak8_ScanMove
			button btMoveD,title="↓",appearance={native,All},pos={-300/10+300/4*3.5,vYValue},size={300/5,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=20, proc=Dektak8_ScanMove
			vYValue+=45
			button btSaveScanSetup,title="Save Def.",appearance={native,All},pos={10,vYValue},size={135,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_SaveCurrentScanDef
			button btLoadScanSetup,title="Load Def.",appearance={native,All},pos={155,vYValue},size={135,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_SelectSavedScanDef
		endif
		
	elseif(iActiveTab==2)//Masks
		if(bScansDefined)
			TabControl DekTak8Processing,pos={170,vYValue}
			sFileName = cleanupName(sFileName,0)
			sFileName = ReplaceString("csv",sFileName,"")
			sFileName = ReplaceString("_",sFileName,"")
			wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
			if(!waveexists(wProcessData))
				DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
				return -1
			endif
			//curvature and noise remove 
			vYValue+=35
			DrawLine 290,vYValue-10,590,vYValue-10
			SetDrawEnv fname = sFont,textxjust = 0,textyjust = 1,fsize = 12,save
			DrawText 10,vYValue+10, "Curvature Removal Order: "
			PopupMenu vCurvatureRemovalOrder,pos={220,vYValue},mode=1,bodyWidth=80,value=Dektak8_PolyOrder("vCurvatureRemovalOrder"),proc=Dektak8_UpdateGlobal,popvalue=num2str(vCurvatureRemovalOrder)
			button btCurvature,title="Do",appearance={native,All},pos={540,vYValue},size={50,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_ScanProcessing
			DrawText 310,vYValue+10, "Smoothing Factor: "
			PopupMenu vSmoothFactor,pos={470,vYValue},mode=1,bodyWidth=80,value="0;1;2;3;4;5;6;7;8;9;10;15;20;25;30;35;40;45;50;60;70;80;90;100;500;1000",proc=Dektak8_UpdateGlobal,popvalue=num2str(vSmoothFactor)

			//scan and feature selection
			vYValue+=30
			DrawLine 5,vYValue,590,vYValue
			vYValue+=10
			DrawText 10,vYValue+10, "Scan to See/Edit: "
			PopupMenu vScan2Edit,pos={150,vYValue},mode=1,bodyWidth=60,value=Dektak8_DropList("Scan#s"),proc=Dektak8_UpdateGlobal,popvalue=vScan2Edit
			DrawText 220,vYValue+10, "Feature to See/Edit: "
			PopupMenu vFeature2Edit,pos={390,vYValue},mode=1,bodyWidth=60,value=Dektak8_DropList("Feature#s"),proc=Dektak8_UpdateGlobal,popvalue=vFeature2Edit
			DrawText 460,vYValue+10, "Focus: "
			PopupMenu sFocus2Edit,pos={530,vYValue},mode=1,bodyWidth=60,value="Film;Sub",proc=Dektak8_UpdateGlobal,popvalue=sFocus2Edit
			
			//colors for coloring traces
			colortab2wave Spectrum
			wave/i/u wColors = root:M_colors
			
			//make plot
			vYValue+=30
			Display/HOST=Dektak8Panel/W=(10,vYValue,590,vYValue+200)/N=MaskPlot 
			ModifyGraph/W=Dektak8Panel#MaskPlot margin=5, margin(left)=20,margin(bottom)=30
			ModifyGraph/W=Dektak8Panel#MaskPlot tick=3,mirror=3
			ModifyGraph/W=Dektak8Panel#MaskPlot mode=3,marker=43,msize=4,rgb=(0,0,0)
			ModifyGraph/W=Dektak8Panel#MaskPlot gbRGB=(65535.,65535.,65535.)
			ModifyGraph/W=Dektak8Panel#MaskPlot wbRGB=(61166,61166,61166)
			ModifyGraph/W=Dektak8Panel#MaskPlot fSize=12,font=sFont
			
			//append traces vFeature2Edit
			if(stringmatch("All",vScan2Edit))
				//All Scans
				iFScan = 0
				iLScan = vTotalScans-1
			else
				iFScan = str2num(vScan2Edit)-1
				iLScan = str2num(vScan2Edit)-1
			endif
			if(stringmatch("All",vFeature2Edit))
				//All Features
				if(stringmatch(sFocus2Edit,"Film")&&stringmatch(stringfromlist(0,sScanStartStops),"Film"))
					//Add one more
					iFFeature = 0
					iLFeature = str2num(stringfromlist(iFScan,sFeaturesPerScan))
				elseif(stringmatch(sFocus2Edit,"Sub")&&stringmatch(stringfromlist(0,sScanStartStops),"Substrate"))
					//remove last one
					iFFeature = 0
					iLFeature = str2num(stringfromlist(iFScan,sFeaturesPerScan))-1
				else
					iFFeature = 0
					iLFeature = str2num(stringfromlist(iFScan,sFeaturesPerScan))-1
				endif
			else
				//One Feature
				iFFeature = str2num(vFeature2Edit)-1
				iLFeature = str2num(vFeature2Edit)-1
			endif
			variable vTraces2Add = ((iLScan-iFScan+1)*(iLFeature-iFFeature+1))
			variable vTraceInc =(dimsize(wColors,0)-1)/(vTraces2Add+1)
			variable vTraceCount = 0
			for(iScan=iFScan;iScan<=iLScan;iScan+=1)
				for(iFeature=iFFeature;iFeature<=iLFeature;iFeature+=1)
					vFeatureStart = DekTak8_GetFeatureRange(iScan,iFeature,"Start")
					vFeatureStop = DekTak8_GetFeatureRange(iScan,iFeature,"Stop") 
					sTraceName = "S"+num2str(iScan)+"_F"+num2str(iFeature)
					AppendToGraph/R/W=Dektak8Panel#MaskPlot wProcessData[iScan][3][vFeatureStart,vFeatureStop]/TN=$sTraceName+"_Sub" vs wProcessData[iScan][0][vFeatureStart,vFeatureStop]//sub mask 
					ModifyGraph mode($sTraceName+"_Sub")=7,hbFill($sTraceName+"_Sub")=23,rgb($sTraceName+"_Sub")=(65535,0,0)
					AppendToGraph/R/W=Dektak8Panel#MaskPlot wProcessData[iScan][4][vFeatureStart,vFeatureStop]/TN=$sTraceName+"_Film" vs wProcessData[iScan][0][vFeatureStart,vFeatureStop]//film mask 
					ModifyGraph mode($sTraceName+"_Film")=7,hbFill($sTraceName+"_Film")=23,rgb($sTraceName+"_Film")=(2,39321,1)
				endfor
				for(iFeature=iFFeature;iFeature<=iLFeature;iFeature+=1)
					iColor = floor(vTraceCount*vTraceInc)
					vFeatureStart = DekTak8_GetFeatureRange(iScan,iFeature,"Start")
					vFeatureStop = DekTak8_GetFeatureRange(iScan,iFeature,"Stop") 
					sTraceName = "S"+num2str(iScan)+"_F"+num2str(iFeature)
					AppendToGraph/W=Dektak8Panel#MaskPlot wProcessData[iScan][2][vFeatureStart,vFeatureStop]/TN=$sTraceName vs wProcessData[iScan][0][vFeatureStart,vFeatureStop]//scan data
					ModifyGraph rgb($sTraceName)=(wColors[iColor][0],wColors[iColor][1],wColors[iColor][2])
					vTraceCount+=1
				endfor
			endfor
			killwaves/Z wColors
			Label/W=Dektak8Panel#MaskPlot left "Height (μm)"
			Label/W=Dektak8Panel#MaskPlot bottom "Scan Length (mm)"
			ModifyGraph/W=Dektak8Panel#MaskPlot highTrip(left)=1,lowTrip(left)=1,notation(left)=1
			ModifyGraph/W=Dektak8Panel#MaskPlot fSize=12,font=sFont
			ModifyGraph/W=Dektak8Panel#MaskPlot tick=3,nticks=10, mirror(bottom)=2,standoff(bottom)=0, nticks(left)=0
			SetAxis right -.05,1.05
			vYValue+=220
			SetActiveSubwindow Dektak8Panel
			//Mask Edit buttons vFeatureWidth, vFilmWidth
			SetVariable sSubWidth, title=" Substrate Region(mm):",pos={25,vYValue-9},size={225,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vFeatureWidth][%$sProject],fcolor=(65535,0,0)
			SetVariable sFilmWidth, title="      Film Region(mm):",pos={260,vYValue-9},size={225,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vFilmWidth][%$sProject],fcolor=(2,39321,1)
			vYValue+=20
			SetVariable sOffset, title="Mask Offset(mm):",pos={25,vYValue-9},size={225,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vOffset][%$sProject],fcolor=(0,0,0)
			SetVariable sEdgeExclusion, title="     Mask Scaling (%):",pos={260,vYValue-9},size={225,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vMaskScaling][%$sProject],fcolor=(0,0,0)
			//Adjust mask button
			button btMaskAdjust,title="Calc\rMask",appearance={native,All},pos={510,vYValue-30},size={70,40},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_CalcMask
		else
			vYValue+=35
			DrawText 150,vYValue+5, "No scan loaded."
		endif
	elseif(iActiveTab==3)//Outputs
		if(bScansDefined)
			if(bMaskDefined)
				TabControl DekTak8Processing,pos={170,vYValue}
				vYValue+=35
				DrawLine 290,vYValue-10,590,vYValue-10
				
				//Do fits on process data
				sFileName = cleanupName(sFileName,0)
				sFileName = ReplaceString("csv",sFileName,"")
				sFileName = ReplaceString("_",sFileName,"")
				Dektak8_DoFits(vFilmSubPoly,("root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName))
				wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
				wave wResults = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results" 
				if(!waveexists(wProcessData))
					DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
					return -1
				endif
				
				//vFilmSubPoly
				DrawText 180,vYValue+10, "Thickness fit order: "
				PopupMenu vFilmSubPoly,pos={220,vYValue},mode=1,bodyWidth=80,value=Dektak8_PolyOrder("vFilmSubPoly"),proc=Dektak8_UpdateGlobal,popvalue=num2str(vFilmSubPoly)
				vYValue+=25
				
				//scan and feature selection
				DrawText 180,vYValue+10, "Scan to see:"
				PopupMenu vScan2Edit,pos={220,vYValue},mode=1,bodyWidth=80,value=Dektak8_DropList("Scan#s"),proc=Dektak8_UpdateGlobal,popvalue=vScan2Edit
				vYValue+=25
				
				//colors for coloring traces
				colortab2wave Spectrum
				wave/i/u wColors = root:M_colors
							
				//make plot
				vYValue+=10
				Display/HOST=Dektak8Panel/W=(10,vYValue,290,vYValue+200)/N=FitPlot 
				ModifyGraph/W=Dektak8Panel#FitPlot margin=5, margin(left)=20,margin(bottom)=30
				ModifyGraph/W=Dektak8Panel#FitPlot tick=3,mirror=3
				ModifyGraph/W=Dektak8Panel#FitPlot mode=3,marker=43,msize=4,rgb=(0,0,0)
				ModifyGraph/W=Dektak8Panel#FitPlot gbRGB=(65535.,65535.,65535.)
				ModifyGraph/W=Dektak8Panel#FitPlot wbRGB=(61166,61166,61166)
				ModifyGraph/W=Dektak8Panel#FitPlot fSize=12,font=sFont
				
				//append traces vFeature2Edit
				if(stringmatch("All",vScan2Edit))
					//All Scans
					iFScan = 0
					iLScan = vTotalScans-1
				else
					iFScan = str2num(vScan2Edit)-1
					iLScan = str2num(vScan2Edit)-1
				endif
				variable vScans2Add = ((iLScan-iFScan+1))
				variable vScanInc =(dimsize(wColors,0)-1)/(vScans2Add+1)
				variable vScanCount = 0
				for(iScan=iFScan;iScan<=iLScan;iScan+=1)
					sTraceName = "S"+num2str(iScan)
					iColor = floor(vScanCount*vScanInc)
					AppendToGraph/W=Dektak8Panel#FitPlot wProcessData[iScan][5][]/TN=$sTraceName+"_Sub" vs wProcessData[iScan][0][]//sub 
					ModifyGraph rgb($sTraceName+"_Sub")=(wColors[iColor][0],wColors[iColor][1],wColors[iColor][2]), mode($sTraceName+"_Sub")=3,marker($sTraceName+"_Sub")=19,msize($sTraceName+"_Sub")=2
					AppendToGraph/W=Dektak8Panel#FitPlot wProcessData[iScan][6][]/TN=$sTraceName+"_Film" vs wProcessData[iScan][0][]//film 
					ModifyGraph rgb($sTraceName+"_Film")=(wColors[iColor][0],wColors[iColor][1],wColors[iColor][2]), mode($sTraceName+"_Film")=3,marker($sTraceName+"_Film")=19,msize($sTraceName+"_Film")=2
					AppendToGraph/W=Dektak8Panel#FitPlot wProcessData[iScan][7][]/TN=$sTraceName+"_SubFit" vs wProcessData[iScan][0][]//sub fit 
					ModifyGraph rgb($sTraceName+"_SubFit")=(0,0,0), lstyle($sTraceName+"_SubFit")=7
					AppendToGraph/W=Dektak8Panel#FitPlot wProcessData[iScan][8][]/TN=$sTraceName+"_FilmFit" vs wProcessData[iScan][0][]//fim fit 
					ModifyGraph rgb($sTraceName+"_FilmFit")=(0,0,0), lstyle($sTraceName+"_FilmFit")=7
					vScanCount+=1
				endfor
				killwaves/Z wColors
				Label/W=Dektak8Panel#FitPlot left "Height (μm)"
				Label/W=Dektak8Panel#FitPlot bottom "Scan Length (mm)"
				ModifyGraph/W=Dektak8Panel#FitPlot highTrip(left)=1,lowTrip(left)=1,notation(left)=1
				ModifyGraph/W=Dektak8Panel#FitPlot fSize=12,font=sFont
				ModifyGraph/W=Dektak8Panel#FitPlot tick=3,nticks=10, mirror(bottom)=2,standoff(bottom)=0, nticks(left)=0
				vYValue+=220
				SetActiveSubwindow Dektak8Panel
				
				//scan and feature selection
				vYValue+=5
				DrawText 140,vYValue+10, "X curvature:"
				PopupMenu sXCurve,pos={220,vYValue},mode=1,bodyWidth=120,value="Concave Up;Concave Down;Linear;Either",proc=Dektak8_UpdateGlobal,popvalue=sXCurve
				vYValue+=25
				DrawText 140,vYValue+10, "Y curvature:"
				PopupMenu sYCurve,pos={220,vYValue},mode=1,bodyWidth=120,value="Concave Up;Concave Down;Linear;Either",proc=Dektak8_UpdateGlobal,popvalue=sYCurve
				vYValue+=25
				DrawText 140,vYValue+10, "Exclude Feature(;):"
				SetVariable sFeatures2ExcludeF, title=" ",pos={150,vYValue},size={120,50},fsize=14,live=0,font=sFont,value=twGlobals[%sFeatures2Exclude][%$sProject]
				
				//add color plot of feature heights
				vYValue = 40
				Display/HOST=Dektak8Panel/W=(310,vYValue,590,vYValue+360)/N=ScanPlot wMappingGrid[iFirstSample,iLastSample][2] vs wMappingGrid[iFirstSample,iLastSample][1]
				AppendToGraph/W=Dektak8Panel#ScanPlot wResults[][1] vs wResults[][0] 
				ColorScale/C/N=text0/F=0/A=MT vert=0,side=2,widthPct=100,height=8,trace=DekTak8_Results
				ColorScale/C/N=text0 "Height Delta (\\e)"
				ColorScale/C/N=text0/X=0.00/Y=-50.00
				ColorScale/C/N=text0/B=1
				ColorScale/C/N=text0 font=sFont,fsize=12,tickLblRot=45
				ModifyGraph/W=Dektak8Panel#ScanPlot mode=3,marker=43, msize=4
				ModifyGraph/W=Dektak8Panel#ScanPlot marker(DekTak8_Results)=16, msize(DekTak8_Results)=6
				ModifyGraph/W=Dektak8Panel#ScanPlot zColor(DekTak8_Results)={wResults[*][2],*,*,Rainbow,0}
				ModifyGraph/W=Dektak8Panel#ScanPlot margin=30, margin(left)=40,margin(bottom)=40, margin(top)=110
				ModifyGraph/W=Dektak8Panel#ScanPlot tick=3,mirror=3
				ModifyGraph/W=Dektak8Panel#ScanPlot rgb=(0,0,0)
				ModifyGraph/W=Dektak8Panel#ScanPlot gbRGB=(65535.,65535.,65535.)
				ModifyGraph/W=Dektak8Panel#ScanPlot wbRGB=(61166,61166,61166)
				Label/W=Dektak8Panel#ScanPlot left "y (mm)"
				Label/W=Dektak8Panel#ScanPlot bottom "x (mm)"
				ModifyGraph/W=Dektak8Panel#ScanPlot fSize=12,font=sFont
				if(bXAxisFlip==1)
					SetAxis bottom vLibraryWidth,0
				else
					SetAxis bottom 0,vLibraryWidth
				endif
				if(bYAxisFlip==1)
					SetAxis left 0,vLibraryHeight
				else
					SetAxis left vLibraryHeight,0
				endif
				SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),arrow= 1,linethick= 1.00, textrgb= (65535,0,0),textxjust= 1,textyjust= 1,save
				SetActiveSubwindow Dektak8Panel
				
				vYValue+=340
				//make panel for output options
				
				
				//make button
				vYValue+=40
				DrawText 500,vYValue+10, "For using the defined curvature removal order and Thickness fit order: "
				vYValue+=20
				button btMaskAdjust,title="Calculate Thickness",appearance={native,All},pos={25,vYValue},size={250,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_DoOutputs
				button btFinished,title="Close and Clear",appearance={native,All},pos={325,vYValue},size={250,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_DoFinish
				
				vYValue+=35
				DrawText 500,vYValue+10, "For using all possiable fit order comibnations and analyzing the distribution: "
				vYValue+=20
				button btAutoThickness,title="Find the expected thickness",appearance={native,All},pos={125,vYValue},size={350,20},font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16, proc=Dektak8_DoAutoOutput

			else
				vYValue+=35
				DrawText 290,vYValue+5, "No mask defined. Revisit the Mask tab."
			endif
		else
			vYValue+=35
			DrawText 290,vYValue+5, "No scans loaded. Revisit the Scans tab."
		endif
		
	endif
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	

end

Function/S Dektak8_PolyOrder(sFit)
	string sFit //"vCurvatureRemovalOrder" or "vFilmSubPoly"
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	if(stringmatch(sFit,"vCurvatureRemovalOrder"))
		return "0;1;2;3;5;6;7;8;9"
	elseif(stringmatch(sFit,"vFilmSubPoly"))
		variable vCurveOrder = COMBI_GetInstrumentNumber("Dektak8","vCurvatureRemovalOrder",sProject)
		int iOrder
		string s2return = ""
		int iStart
		if(vCurveOrder==0)
			iStart = 1
		else
			iStart = vCurveOrder
		endif
		for(iOrder=iStart;iOrder<=9;iOrder+=1)
			s2return+=num2str(iOrder)+";"
		endfor
		return s2return
	endif
end

Function Dektak8_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	if(stringmatch("sProject",ctrlName))
		Combi_GiveInstrumentGlobal("Dektak8",ctrlName,popStr,"COMBIgor")
		Combi_GiveInstrumentGlobal("Dektak8","sLibrary"," ",Combi_GetInstrumentString("Dektak8","sProject","COMBIgor"))
	elseif(stringmatch("sLibrary",ctrlName))
		if(datafolderExists("root:COMBIgor:"+Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")+":Data:Dektak8:"+popStr+":"))
			string sdatafolder="root:COMBIgor:"+Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")+":Data:Dektak8:"+popStr+":"
			setdataFolder $sdatafolder
			string swaves =waveList("*", ";", "MINCOLS:9,MAXCOLS:9")
			swaves = removeEnding(swaves,";") + ".csv"
			setdatafolder root:
			Combi_GiveInstrumentGlobal("Dektak8","sFileName",swaves,Combi_GetInstrumentString("Dektak8","sProject","COMBIgor"))
		endif
		Combi_GiveInstrumentGlobal("Dektak8",ctrlName,popStr,Combi_GetInstrumentString("Dektak8","sProject","COMBIgor"))
	else
		Combi_GiveInstrumentGlobal("Dektak8",ctrlName,popStr,Combi_GetInstrumentString("Dektak8","sProject","COMBIgor"))
	endif
	Combi_Dektak8()
End

//function to return drop downs of Libraries for panel
function/S Dektak8_DropList(sOption)
	string sOption//"Libraries" or "DataTypes" or "Scan#s" or "Feature#s" or "SAVED"
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	int iScan, vTotalScans, iFeature, vThisFeatureNum
	if(stringmatch(sOption,"Libraries"))
		return Combi_TableList(sProject,1,"All",sOption)	
	elseif(stringmatch("DataTypes",sOption))
		string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
		return Combi_TableList(sProject,1,sLibrary,sOption)	
		
	elseif(stringmatch(sOption,"Scan#s"))
		vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
		string sScanNums="All;"
		for(iScan=0;iScan<vTotalScans;iScan+=1)
			sScanNums = AddlistItem(num2str(iScan+1),sScanNums,";",inf)
		endfor
		return sScanNums
		
	elseif(stringmatch(sOption,"Feature#s"))
		vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
		string sFocus2Edit = Combi_GetInstrumentString("Dektak8","sFocus2Edit",sProject)
		string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
		string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
		string vScan2Edit = Combi_GetInstrumentString("Dektak8","vScan2Edit",sProject)
		string sFeatureNums="All;"
		string sStartStop
		if(stringmatch("All",vScan2Edit))
			sStartStop = stringfromlist(0,sScanStartStops)
			for(iScan=0;iScan<vTotalScans;iScan+=1)
				vThisFeatureNum = str2num(stringfromlist(iScan,sFeaturesPerScan))
				for(iFeature=0;iFeature<vThisFeatureNum;iFeature+=1)
					if(whichlistItem(num2str(1+iFeature),sFeatureNums)<0)
						sFeatureNums = AddlistItem(num2str(iFeature+1),sFeatureNums,";",inf)
					endif
				endfor
			endfor
		else
			int iScanToEdit = str2num(vScan2Edit)-1
			sStartStop = stringfromlist(iScanToEdit,sScanStartStops)
			vThisFeatureNum = str2num(stringfromlist(iScanToEdit,sFeaturesPerScan))
			for(iFeature=0;iFeature<vThisFeatureNum;iFeature+=1)
				sFeatureNums = AddlistItem(num2str(iFeature+1),sFeatureNums,";",inf)
			endfor
		endif
		int iListLength = itemsInList(sFeatureNums)-1
		if(stringmatch(sFocus2Edit,"Film")&&stringmatch(sStartStop,"Film"))
			//Add one more
			sFeatureNums = AddlistItem(num2str(iListLength+1),sFeatureNums,";",inf)
		elseif(stringmatch(sFocus2Edit,"Film")&&stringmatch(sStartStop,"Substrate"))
			//remove last one
			sFeatureNums = replaceString(num2str(iListLength)+";",sFeatureNums,"")
		endif
		return sFeatureNums
	elseif(stringmatch(sOption,"SAVED"))
		string sAllSavedNames = "11 down columns;4 across rows;2 across each row (8 total);3 across Row 2 and 3 (6 total);33 Scans, along columns;2 across Row 2 and 3 (4 total)"
		wave/T twGlobals = root:Packages:COMBIgor:Instruments:Combi_Dektak8_Globals
		int iThisGlobal
		for(iThisGlobal=0;iThisGlobal<dimsize(twGlobals,0);iThisGlobal+=1)
			string sThisGlobalName = GetDimLabel(twGlobals,0,iThisGlobal)
			if(stringmatch(sThisGlobalName,"SAVED_*"))
				sAllSavedNames = AddListItem(replacestring("SAVED_",sThisGlobalName,""),sAllSavedNames,";",0)
			endif
		endfor
		return sAllSavedNames
	endif
end

//tab contol
function Dektak8_TabAction(ctrlName, tabNum) : TabControl
	String ctrlName
	Variable tabNum
	Combi_GiveInstrumentGlobal("Dektak8","iActiveTab",num2str(tabNum),Combi_GetInstrumentString("Dektak8","sProject","COMBIgor"))
	Combi_Dektak8()
end

//load button
function Dektak8_ScanMove(ctrlName) : ButtonControl
	String ctrlName
	//dektak globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScan2Move = Combi_GetInstrumentString("Dektak8","sScan2Move",sProject)
	variable vScanMoveDelta = Combi_GetInstrumentNumber("Dektak8","sScanMoveDelta",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject), iScan
	string sScanStartsXNew="", sScanStartsYNew=""
	
	//direction
	int vXSign, vYSign
	int bXAxisFlip = Combi_GetGlobalNumber("bXAxisFlip",sProject)
	int bYAxisFlip = Combi_GetGlobalNumber("bYAxisFlip",sProject)
	if(stringmatch(ctrlName,"btMoveL"))
		if(bXAxisFlip==0)
			vXSign = -1
		else
			vXSign = 1
		endif
	elseif(stringmatch(ctrlName,"btMoveR"))
		if(bXAxisFlip==0)
			vXSign = 1
		else
			vXSign = -1
		endif
	elseif(stringmatch(ctrlName,"btMoveU"))
		if(bYAxisFlip==0)
			vYSign = 1
		else
			vYSign = -1
		endif
	elseif(stringmatch(ctrlName,"btMoveD"))
		if(bYAxisFlip==0)
			vYSign = -1
		else
			vYSign = 1
		endif
	endif
	
	variable vMovedX, vMovedY
	if(stringmatch(sScan2Move,"All"))
		for(iScan=0;iScan<vTotalScans;iScan+=1)
			vMovedX = str2num(stringfromlist(iScan,sScanStartsX))+(vXSign*vScanMoveDelta)
			vMovedY = str2num(stringfromlist(iScan,sScanStartsY))+(vYSign*vScanMoveDelta)
			sScanStartsXNew = AddlistItem(num2str(vMovedX),sScanStartsXNew,";",inf)
			sScanStartsYNew = AddlistItem(num2str(vMovedY),sScanStartsYNew,";",inf)
		endfor
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsX",sScanStartsXNew,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsY",sScanStartsYNew,sProject)
		Dektak8_WriteFeaturePositions()
		Combi_Dektak8()
		return-1
	else
		int iScan2Move = Combi_GetInstrumentNumber("Dektak8","sScan2Move",sProject)-1
		vMovedX = str2num(stringfromlist(iScan2Move,sScanStartsX))+(vXSign*vScanMoveDelta)
		vMovedY = str2num(stringfromlist(iScan2Move,sScanStartsY))+(vYSign*vScanMoveDelta)
		for(iScan=0;iScan<vTotalScans;iScan+=1)
			if(iScan==iScan2Move)
				sScanStartsXNew = AddlistItem(num2str(vMovedX),sScanStartsXNew,";",inf)
				sScanStartsYNew = AddlistItem(num2str(vMovedY),sScanStartsYNew,";",inf)
			else
				sScanStartsXNew = AddlistItem(stringfromlist(iScan,sScanStartsX),sScanStartsXNew,";",inf)
				sScanStartsYNew = AddlistItem(stringfromlist(iScan,sScanStartsY),sScanStartsYNew,";",inf)
			endif
		endfor
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsX",sScanStartsXNew,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsY",sScanStartsYNew,sProject)
		Dektak8_WriteFeaturePositions()
		Combi_Dektak8()
		return-1
	endif
	
end

//load button
function Dektak8_LoadButton(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//dektak globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
	//combigor globals
	variable vLibraryWidth = Combi_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = Combi_GetGlobalNumber("vLibraryHeight",sProject)
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	variable vColumnSpacing = Combi_GetGlobalNumber("vColumnSpacing",sProject)
	variable vRowSpacing = Combi_GetGlobalNumber("vRowSpacing",sProject)
	int bXAxisFlip = Combi_GetGlobalNumber("bXAxesFlip",sProject)
	int bYAxisFlip = Combi_GetGlobalNumber("bYAxesFlip",sProject)
	string sOrigin = Combi_GetGlobalString("sOrigin",sProject)
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	//make/set folder to open into
	setdatafolder root: 
	NewDataFolder/S/O COMBIgor
	NewDataFolder/S/O $sProject
	NewDataFolder/S/O Data
	NewDataFolder/S/O Dektak8
	KillDataFolder/Z $sLibrary
	NewDataFolder/S/O $sLibrary
	//load new file and return to root
	LoadWave/G/D/N=Dektak/Q/M
	int vScansLoaded = V_flag
	string sLoadedWaves = S_waveNames
	string sPath = S_path
	string sFileName = S_fileName
	SetDataFolder root: 
	//check if scans are loaded, if so, get lengths, file names and paths and store them along with the data in to process wave
	int iScan, iIndex
	if(vScansLoaded>0)
		//store file info
		vTotalScans = vScansLoaded
		Combi_GiveInstrumentGlobal("Dektak8","sFileSource",sPath,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sFileName",sFileName,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","vTotalScans",num2str(vScansLoaded),sProject)
		//raw process wave
		//Rows - Scans, Columns - DataType, Layers-Vector Dim
		//Col 0 : original X in mm
		//Col 1 : original Y in micron (natural)
		//Col 2 : Curvature removed Y in natural
		//Col 3 : Mask for sub
		//Col 4 : Mask for film
		//Col 5 : masked sub values for fitting
		//Col 6 : masked film values for fitting
		//Col 7 : fit results for sub
		//Col 8 : fit results for film
		sFileName = ReplaceString("csv",cleanupname(sFileName,0),"")
		sFileName = ReplaceString("_",sFileName,"")
		SetDataFolder  $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"
		Make/O/N=(vScansLoaded,9,1) $sFileName
		SetDataFolder root: 
		wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
		wProcessData[][][] = nan
		
		//loop through scans
		sScanLengths = "" 
		sDataLengths = ""
		for(iScan=0;iScan<vScansLoaded;iScan+=1)
			//get wave
			wave wScan = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+stringfromList(iScan,sLoadedWaves)
			int vStorageLength = dimsize(wProcessData,2)
			int vNewScanLength = dimsize(wScan,0)
			//make storage wave bigger if needed
			if(vNewScanLength>vStorageLength)
				redimension/N=(-1,-1,vNewScanLength), wProcessData
				wProcessData[][][vStorageLength,vNewScanLength-1] = nan
			endif
			//move data
			for(iIndex=0;iIndex<vNewScanLength;iIndex+=1)
				wProcessData[iScan][0][iIndex] = wScan[iIndex][0]/1000
				wProcessData[iScan][1][iIndex] = wScan[iIndex][1]
				wProcessData[iScan][2][iIndex] = nan
				wProcessData[iScan][3][iIndex] = nan
				wProcessData[iScan][4][iIndex] = nan
			endfor
			//add to lists
			sScanLengths = AddListItem(num2str(wScan[(dimsize(wScan,0)-1)][0]/1000),sScanLengths,";",inf)
			sDataLengths = AddListItem(num2str(dimsize(wScan,0)),sDataLengths,";",inf)
			//killwaves
			killwaves wScan
		endfor
		//write
		Combi_GiveInstrumentGlobal("Dektak8","sScanLengths",sScanLengths,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sDataLengths",sDataLengths,sProject)
		sScanStartsX = ""
		sScanStartsY= ""
		sFeaturesPerScan= ""
		sScanStartStops= ""
		sFeatureSpacings=""
		
	else
		//No waves loaded
		Combi_GiveInstrumentGlobal("Dektak8","sFileSource","NONE",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sFileName","NONE LOADED",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","vTotalScans","0",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanLengths","",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsX","",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsY","",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sFeaturesPerScan","",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartStops","",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sDataLengths","",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","bScansDefined","0",sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartStops","",sProject)
		Combi_Dektak8()
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return-1
	endif
	
	//get initial scan defs, user inputs, then guess work
	string sScanDirection = "+y" ; prompt sScanDirection, "Scan direction:", popup, "+x;-x;+y;-y"
	string sScanIndexDirection = "+x" ; prompt sScanIndexDirection, "Scan number increase direction:", popup, "+x;-x;+y;-y"
	string sScanStartStopDefualt = "Film" ; prompt sScanStartStopDefualt, "Scan start/stop position:", popup, "Film;Substrate"
	variable vSubFeaturesIn = 1 ; prompt vSubFeaturesIn, "Substrate Samples along scan (counting starts/stops):"
	DoPrompt/HELP="This indicates how to place the scans on the Library" "Scan Details?" sScanDirection,sScanIndexDirection, sScanStartStopDefualt, vSubFeaturesIn
	if (V_Flag)
		return -1
	endif
	Combi_GiveInstrumentGlobal("Dektak8","sScanDirection",sScanDirection,sProject)
	variable vScanSpacing, vFeatureSpacing
	int iYScanDirection, iXScanDirection,iYPerpDirection, iXPerpDirection
	variable vScan1StartY, vScan1StartX
	if(stringmatch(sScanIndexDirection,"+x"))
		vScanSpacing =vColumnSpacing
		iYPerpDirection = 0; iXPerpDirection = 1
	elseif(stringmatch(sScanIndexDirection,"-x"))
		vScanSpacing =vColumnSpacing
		iYPerpDirection = 0; iXPerpDirection = -1
	elseif(stringmatch(sScanIndexDirection,"-y"))
		vScanSpacing =vRowSpacing
		iYPerpDirection = -1; iXPerpDirection = 0
	elseif(stringmatch(sScanIndexDirection,"+y"))
		vScanSpacing =vRowSpacing
		iYPerpDirection = 1; iXPerpDirection = 0
	endif
	if(stringmatch(sScanDirection,"+x"))
		vFeatureSpacing =vColumnSpacing
		iXScanDirection = 1; iYScanDirection = 0
	elseif(stringmatch(sScanDirection,"-x"))
		vFeatureSpacing =vColumnSpacing
		iXScanDirection = -1; iYScanDirection = 0
	elseif(stringmatch(sScanDirection,"-y"))
		vFeatureSpacing =vRowSpacing
		iXScanDirection = 0; iYScanDirection = -1
	elseif(stringmatch(sScanDirection,"+y"))
		vFeatureSpacing =vRowSpacing
		iXScanDirection = 0; iYScanDirection = 1
	endif
	
	//ask for spacings
	prompt vScanSpacing, "Scan spacing:"
	prompt vFeatureSpacing, "Substrate feature spacing:"
	DoPrompt/HELP="This value indicates where the features are in the scan" "Scan Details?" vScanSpacing,vFeatureSpacing
	if (V_Flag)
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	//get initialization values
	//guess start positions based on length, directions, and number
	variable vScanStartX
	variable vScanStartY, vHalfScanLength
	variable vSamplesPerScan 
	variable vScanLength
	variable vHalfScanPerpLength = (vTotalScans-1)*vScanSpacing/2
	variable vxDelta, vyDelta
	int vTotalFeatures = 0
	//spacing
	for(iScan=0;iScan<vTotalScans;iScan+=1)
		//starting at center
		vHalfScanLength = str2num(stringfromlist(iScan,sScanLengths))/2
		vScanStartX = (vLibraryWidth/2); vScanStartY = (vLibraryHeight/2)
		//move half of the scan distance back to starting Sample
		vxDelta = -(iXScanDirection*vHalfScanLength); vyDelta = -(iYScanDirection*vHalfScanLength)
		vScanStartX+=vxDelta; vScanStartY+=vyDelta
		//Move half of the ScanPerpLength back to starting Sample perp dir from scan dir
		vxDelta = -(iXPerpDirection*vHalfScanPerpLength); vyDelta = -(iYPerpDirection*vHalfScanPerpLength)
		vScanStartX+=vxDelta; vScanStartY+=vyDelta
		//move in the forward ScanPerp dir spacings times iscan
		vxDelta = (iXPerpDirection*iScan*vScanSpacing); vyDelta = (iYPerpDirection*iScan*vScanSpacing)
		vScanStartX+=vxDelta; vScanStartY+=vyDelta
		//add to list
		sScanStartsX = AddListItem(num2str(vScanStartX),sScanStartsX,";",inf)
		sScanStartsY = AddListItem(num2str(vScanStartY),sScanStartsY,";",inf)
		sFeaturesPerScan = AddListItem(num2str(vSubFeaturesIn),sFeaturesPerScan,";",inf)
		sScanStartStops = AddListItem(sScanStartStopDefualt,sScanStartStops,";",inf)
		sFeatureSpacings = AddListItem(num2str(vFeatureSpacing),sFeatureSpacings,";",inf)
		vTotalFeatures+=str2num(sFeaturesPerScan)
	endfor
	Combi_GiveInstrumentGlobal("Dektak8","sScanStartsX",sScanStartsX,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sScanStartsY",sScanStartsY,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sFeaturesPerScan",sFeaturesPerScan,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sScanStartStops",sScanStartStops,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","vTotalFeatures",num2str(vTotalFeatures),sProject)
	Combi_GiveInstrumentGlobal("Dektak8","bScansDefined","1",sProject)
	
	Combi_GiveInstrumentGlobal("Dektak8","sFeatureSpacings",sFeatureSpacings,sProject)
	Dektak8_WriteFeaturePositions()
	Combi_Dektak8()
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	return-1	
end

//scan define button
function Dektak8_ScanDefine(ctrlName) : ButtonControl
	String ctrlName
	//istrument globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sScanDirection = Combi_GetInstrumentString("Dektak8","sScanDirection",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	string sScan2Move = Combi_GetInstrumentString("Dektak8","sScan2Move",sProject)
	
	int iScan
	if(vTotalScans!= itemsinlist(sDataLengths))
		DoAlert/T="Where's the data?",0,"Please reload the scan data."
		return-1
	endif
	
	//combigor globals
	variable vLibraryWidth = Combi_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = Combi_GetGlobalNumber("vLibraryHeight",sProject)
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	variable vColumnSpacing = Combi_GetGlobalNumber("vColumnSpacing",sProject)
	variable vRowSpacing = Combi_GetGlobalNumber("vRowSpacing",sProject)
	int bXAxisFlip = Combi_GetGlobalNumber("bXAxesFlip",sProject)
	int bYAxisFlip = Combi_GetGlobalNumber("bYAxesFlip",sProject)
	string sOrigin = Combi_GetGlobalString("sOrigin",sProject)
	
	//ask user for input on each scan
	variable vThisStartX, vThisStartY, vThisFeaturePerScan, vThisFeatureSpacing
	string sNewStatXs="", sNewStartYs="", sNewFeaturesPerScan="", sNewUpsOrDowns="", sUpOrDown, sNewFeatureSpacings=""
	prompt vThisStartX, "The scan x start position (mm):"
	prompt vThisStartY, "The scan y start position (mm):"
	prompt vThisFeaturePerScan, "Substrate features per scan:"
	prompt vThisFeatureSpacing, "Spacing between features(mm):"
	prompt sUpOrDown, "Scan Start/End Type:",POPUP, "Film;Substrate"
	
	if(stringmatch(sScan2Move,"All"))
		for(iScan=0;iScan<vTotalScans;iScan+=1)
			vThisStartX = str2num(stringfromlist(iScan,sScanStartsX))
			vThisStartY = str2num(stringfromlist(iScan,sScanStartsY))
			vThisFeaturePerScan = str2num(stringfromlist(iScan,sFeaturesPerScan))
			vThisFeatureSpacing = str2num(stringfromList(iScan,sFeatureSpacings))
			sUpOrDown = stringfromlist(iScan,sScanStartStops)
			DoPrompt/HELP="This helps place scan "+num2str(iScan+1) "Scan "+num2str(1+iScan)+" positioning" vThisStartX,vThisStartY,vThisFeaturePerScan,vThisFeatureSpacing,sUpOrDown
			if (V_Flag)
				return -1
			endif
			sNewStatXs = AddListItem(num2str(vThisStartX),sNewStatXs,";",inf)
			sNewStartYs = AddListItem(num2str(vThisStartY),sNewStartYs,";",inf)
			sNewFeaturesPerScan = AddListItem(num2str(vThisFeaturePerScan),sNewFeaturesPerScan,";",inf)
			sNewUpsOrDowns = AddListItem(sUpOrDown,sNewUpsOrDowns,";",inf)
			sNewFeatureSpacings  = AddListItem(num2str(vThisFeatureSpacing),sNewFeatureSpacings,";",inf)
		endfor
	else
		for(iScan=0;iScan<vTotalScans;iScan+=1)
			vThisStartX = str2num(stringfromlist(iScan,sScanStartsX))
			vThisStartY = str2num(stringfromlist(iScan,sScanStartsY))
			vThisFeaturePerScan = str2num(stringfromlist(iScan,sFeaturesPerScan))
			vThisFeatureSpacing = str2num(stringfromList(iScan,sFeatureSpacings))
			sUpOrDown = stringfromlist(iScan,sScanStartStops)
			if((str2num(sScan2Move)-1)==iScan)
			DoPrompt/HELP="This helps place scan "+num2str(iScan+1) "Scan "+num2str(1+iScan)+" positioning" vThisStartX,vThisStartY,vThisFeaturePerScan,vThisFeatureSpacing,sUpOrDown
				if (V_Flag)
					return -1
				endif
			endif
			sNewStatXs = AddListItem(num2str(vThisStartX),sNewStatXs,";",inf)
			sNewStartYs = AddListItem(num2str(vThisStartY),sNewStartYs,";",inf)
			sNewFeaturesPerScan = AddListItem(num2str(vThisFeaturePerScan),sNewFeaturesPerScan,";",inf)
			sNewUpsOrDowns = AddListItem(sUpOrDown,sNewUpsOrDowns,";",inf)
			sNewFeatureSpacings  = AddListItem(num2str(vThisFeatureSpacing),sNewFeatureSpacings,";",inf)
		endfor
	endif
	
	Combi_GiveInstrumentGlobal("Dektak8","sScanStartsX",sNewStatXs,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sScanStartsY",sNewStartYs,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sFeaturesPerScan",sNewFeaturesPerScan,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sScanStartStops",sNewUpsOrDowns,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","sFeatureSpacings",sNewFeatureSpacings,sProject)
	Combi_GiveInstrumentGlobal("Dektak8","bScansDefined","1",sProject)
	
	//write results wave 
	Dektak8_WriteFeaturePositions()
	Combi_Dektak8()
	return-1
	
end

//scan define button
function Dektak8_ScanProcessing(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	//get dektak8 globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sScanDirection = Combi_GetInstrumentString("Dektak8","sScanDirection",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
	int vCurvatureRemovalOrder = Combi_GetInstrumentNumber("Dektak8","vCurvatureRemovalOrder",sProject)
	variable vSmoothFactor = Combi_GetInstrumentNumber("Dektak8","vSmoothFactor",sProject)
	variable vFeatureWidth  = Combi_GetInstrumentNumber("Dektak8","vFeatureWidth",sProject)
	variable vFilmWidth  = Combi_GetInstrumentNumber("Dektak8","vFilmWidth",sProject)
	variable vOffset = Combi_GetInstrumentNumber("Dektak8","vOffset",sProject)
	variable vMaskScaling = Combi_GetInstrumentNumber("Dektak8","vMaskScaling",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	
	//combigor globals
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	
	//get Process wave
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
	
	//declares some things
	variable vThisScanLength, vThisDataLength, vFeatures, vFeatureStart, vFeatureStop, vmmPerDataSample, vThisFeatureSpacing
	string sThisStartStop
	int iScan, iFeature, iFFeature, iLFeature, iFeatureStart, iFeatureStop, iHalfFilmRegion, iHalfSubRegion, iFeatureMid, iEdgeExclusion, iOffset, iEndOffset,iStartOffset
	if(!waveexists(wProcessData))
		DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif

	//processing wave
	Make/O/N=(dimsize(wProcessData,2)) wTempY
	Make/O/N=(vCurvatureRemovalOrder+1) wFitCoefs
	//Make/O/N=(vCurvatureRemovalOrder+1,vTotalScans) wCurvatureFitSigmas
	//wave wErrorWave = root:wCurvatureFitSigmas
	wave wTempY = root:wTempY
	wave wFitCoefs = root:wFitCoefs
	
	//loop through scans
	for(iScan=0;iScan<vTotalScans;iScan+=1)
		//get temp data
		wTempY[] = wProcessData[iScan][1][p]
		//smooth
		if(vSmoothFactor>0)
			Smooth/M=(0.0001)/R=(nan) vSmoothFactor, wTempY
		endif
		//remove curvature
		if(vCurvatureRemovalOrder==0)
			//no fit, just avereage value
			wProcessData[iScan][2][] = wTempY[r]
		elseif(vCurvatureRemovalOrder==1)
			//linear
			CurveFit/Q/W=2 line, kwCWave=wFitCoefs, wTempY[]
			wProcessData[iScan][2][] = wTempY[r] - poly(wFitCoefs,r)
		elseif(vCurvatureRemovalOrder>1)
			//poly
			CurveFit/Q/W=2 poly (vCurvatureRemovalOrder+1), kwCWave=wFitCoefs, wTempY[]
			wProcessData[iScan][2][] = wTempY[r] - poly(wFitCoefs,r)
		endif
		//prepopulate mask
		vThisScanLength = str2num(stringfromlist(iScan,sScanLengths))
		vThisDataLength = str2num(stringfromlist(iScan,sDataLengths))
		vFeatures = str2num(stringFromList(iScan,sFeaturesPerScan))
		sThisStartStop = stringFromList(iScan,sScanStartStops)
		vThisFeatureSpacing = str2num(stringFromList(iScan,sFeatureSpacings))
		for(iFeature=0;iFeature<vFeatures;iFeature+=1)
			if(!stringmatch("Auto",ctrlName))
				DekTak8_WriteMask(iScan,iFeature,sThisStartStop,vThisScanLength,vThisDataLength,vFeatures,vThisFeatureSpacing,vFeatureWidth,vFilmWidth,vMaskScaling,vOffset)
			endif
		endfor
		//wave wSigmaWave = root:W_sigma
		//wErrorWave[][iScan] = wSigmaWave[p]
	endfor
	killwaves/Z root:W_ParamConfidenceInterval,  wTempY, wFitCoefs, root:W_sigma
	//killwaves wErrorWave
	if(!stringmatch("Auto",ctrlName))
		Combi_Dektak8()
	endif
	Combi_GiveInstrumentGlobal("Dektak8","bMaskDefined","1",sProject)
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	return-1
end


function Dektak8_CalcMask(ctrlName) : ButtonControl
	String ctrlName
	
	//get dektak8 globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sScanDirection = Combi_GetInstrumentString("Dektak8","sScanDirection",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
	int vCurvatureRemovalOrder = Combi_GetInstrumentNumber("Dektak8","vCurvatureRemovalOrder",sProject)
	variable vSmoothFactor = Combi_GetInstrumentNumber("Dektak8","vSmoothFactor",sProject)
	variable vFeatureWidth  = Combi_GetInstrumentNumber("Dektak8","vFeatureWidth",sProject)
	variable vFilmWidth  = Combi_GetInstrumentNumber("Dektak8","vFilmWidth",sProject)
	variable vOffset = Combi_GetInstrumentNumber("Dektak8","vOffset",sProject)
	variable vMaskScaling = Combi_GetInstrumentNumber("Dektak8","vMaskScaling",sProject)
	string vScan2Edit = Combi_GetInstrumentString("Dektak8","vScan2Edit",sProject)
	string vFeature2Edit = Combi_GetInstrumentString("Dektak8","vFeature2Edit",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	string sFocus2Edit = Combi_GetInstrumentString("Dektak8","sFocus2Edit",sProject)
	
	//combigor globals
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	
	//get Process wave
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
	
	//declares some things
	variable vThisScanLength, vThisDataLength, vFeatures, vFeatureStart, vFeatureStop, vmmPerDataSample, vThisFeatureSpacing
	string sThisStartStop
	int iEdgeExclusionStart,iEdgeExclusionStop, iHalfScanLength
	int iScan, iFeature, iFFeature, iLFeature, iFeatureStart, iFeatureStop, iHalfFilmRegion, iHalfSubRegion, iFeatureMid, iEdgeExclusion, iOffset, iFScan, iLScan, iStartOffset, iEndOffset
	
	//make sure wave was found
	if(!waveexists(wProcessData))
		DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
		return -1
	endif
	
	//strat stop positions in scans and features
	if(stringmatch("All",vScan2Edit))
		//All Scans
		iFScan = 0
		iLScan = vTotalScans-1
	else
		iFScan = str2num(vScan2Edit)-1
		iLScan = str2num(vScan2Edit)-1
	endif
	if(stringmatch("All",vFeature2Edit))
		//All Features
		if(stringmatch(sFocus2Edit,"Film")&&stringmatch(stringfromlist(0,sScanStartStops),"Film"))
			//Add one more
			iFFeature = 0
			iLFeature = str2num(stringfromlist(iFScan,sFeaturesPerScan))
		elseif(stringmatch(sFocus2Edit,"Sub")&&stringmatch(stringfromlist(0,sScanStartStops),"Substrate"))
			//remove last one
			iFFeature = 0
			iLFeature = str2num(stringfromlist(iFScan,sFeaturesPerScan))-1
		else
			iFFeature = 0
			iLFeature = str2num(stringfromlist(iFScan,sFeaturesPerScan))-1
		endif
	else
		//One Feature
		iFFeature = str2num(vFeature2Edit)-1
		iLFeature = str2num(vFeature2Edit)-1
	endif
	
	//loop through scans
	for(iScan=iFScan;iScan<=iLScan;iScan+=1)
		//prepopulate mask
		vThisScanLength = str2num(stringfromlist(iScan,sScanLengths))
		vThisDataLength = str2num(stringfromlist(iScan,sDataLengths))
		vFeatures = str2num(stringFromList(iScan,sFeaturesPerScan))
		vThisFeatureSpacing = str2num(stringFromList(iScan,sFeatureSpacings))
		sThisStartStop = stringFromList(iScan,sScanStartStops)
		for(iFeature=iFFeature;iFeature<=iLFeature;iFeature+=1)
			DekTak8_WriteMask(iScan,iFeature,sThisStartStop,vThisScanLength,vThisDataLength,vFeatures,vThisFeatureSpacing,vFeatureWidth,vFilmWidth,vMaskScaling,vOffset)
		endfor
	endfor

	Combi_Dektak8()
	return-1
	
end

function Dektak8_WriteFeaturePositions()
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root: 
	//get dektak8 globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sScanDirection = Combi_GetInstrumentString("Dektak8","sScanDirection",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
	int vCurvatureRemovalOrder = Combi_GetInstrumentNumber("Dektak8","vCurvatureRemovalOrder",sProject)
	variable vSmoothFactor = Combi_GetInstrumentNumber("Dektak8","vSmoothFactor",sProject)
	variable vFeatureWidth  = Combi_GetInstrumentNumber("Dektak8","vFeatureWidth",sProject)
	variable vFilmWidth  = Combi_GetInstrumentNumber("Dektak8","vFilmWidth",sProject)
	variable vOffset = Combi_GetInstrumentNumber("Dektak8","vOffset",sProject)
	variable vMaskScaling = Combi_GetInstrumentNumber("Dektak8","vMaskScaling",sProject)
	string vScan2Edit = Combi_GetInstrumentString("Dektak8","vScan2Edit",sProject)
	string vFeature2Edit = Combi_GetInstrumentString("Dektak8","vFeature2Edit",sProject)
	variable vTotalFeatures = Combi_GetInstrumentNumber("Dektak8","vTotalFeatures",sProject)
	string sFocus2Edit = Combi_GetInstrumentString("Dektak8","sFocus2Edit",sProject)
	
	//declarations for internal variable 
	int iScan, iFeature, iThisFeature,  iYFactor, iXFactor
	variable vThisStartX, vThisStartY, vThisScanLength, vFeatures, vFeatureDistance, vThisFeatureSpacing, vThisFeatureDistance, vScanMidX, vScanMidY
	variable vFeatureX, vFeatureY
	//calculated feature positions and store in wave
	killwaves/Z $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results"
	setdataFolder $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary
	
	//Col0 - X, Col1 - Y, Col2 - Thickness	
	Make/O/N=(vTotalFeatures,3) DekTak8_Results 
	SetDataFolder $sTheCurrentUserFolder
	wave wResults = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results" 
	wResults[][]=nan
	
	if(stringmatch(sScanDirection,"+x"))
		iYFactor = 0; iXFactor = 1
	elseif(stringmatch(sScanDirection,"-x"))
		iYFactor = 0; iXFactor = -1
	elseif(stringmatch(sScanDirection,"+y"))
		iYFactor = 1; iXFactor = 0
	elseif(stringmatch(sScanDirection,"-y"))
		iYFactor = -1; iXFactor = 0
	endif
	
	iThisFeature = 0
	for(iScan=0;iScan<vTotalScans;iScan+=1)
		vThisStartX = str2num(stringfromlist(iScan,sScanStartsX))
		vThisStartY = str2num(stringfromlist(iScan,sScanStartsY))
		vThisScanLength = str2num(stringfromlist(iScan,sScanLengths))
		vThisFeatureSpacing = str2num(stringfromlist(iScan,sFeatureSpacings))
		vFeatures = str2num(stringFromList(iScan,sFeaturesPerScan))
		vScanMidX = vThisStartX+(iXFactor*vThisScanLength/2)
		vScanMidY = vThisStartY+(iYFactor*vThisScanLength/2)
		for(iFeature=0;iFeature<vFeatures;iFeature+=1)
			if(stringmatch(stringFromList(iScan,sScanStartStops),"Film"))
				vThisFeatureDistance = vThisFeatureSpacing*vFeatures
				vFeatureDistance = 0.5*vThisFeatureSpacing
			elseif(stringmatch(stringFromList(iScan,sScanStartStops),"Substrate"))
				vThisFeatureDistance = vThisFeatureSpacing*(vFeatures-1)
				vFeatureDistance = 0
			endif
			//first feature
			vFeatureX = vScanMidX-(iXFactor*vThisFeatureDistance/2)+(iXFactor*vFeatureDistance)
			vFeatureY = vScanMidY-(iYFactor*vThisFeatureDistance/2)+(iYFactor*vFeatureDistance)
			//this feature
			vFeatureX = vFeatureX +(iFeature*vThisFeatureSpacing*iXFactor)
			vFeatureY = vFeatureY +(iFeature*vThisFeatureSpacing*iYFactor)
			//store feature position
			wResults[iThisFeature][0] = vFeatureX
			wResults[iThisFeature][1] = vFeatureY
			iThisFeature+=1
		endfor
	endfor
	
end

Function Dektak8_New(ctrlName) : ButtonControl
	String ctrlName
	//Plugin globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	if(stringmatch("sNewDataType",ctrlName))
		Combi_NewEntry(sProject,"DataType")
	elseif(stringmatch("sNewLibrary",ctrlName))
		Combi_NewEntry(sProject,"Library")
	endif
	return-1
End

Function Dektak8_SelectSavedScanDef(ctrlName) : ButtonControl
	String ctrlName
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sSavedName = Combi_StringPrompt("","Saved scan def to load:",Dektak8_DropList("SAVED"),"These are pre-saved options.","Which to load?")
	string vTotalScansReal = Combi_GetInstrumentString("Dektak8","vTotalScans",sProject)
	string sStorageString 
	if(stringmatch("11 down columns",sSavedName))
		sStorageString ="+y$$Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;$$5.4;9.4;13.4;17.4;21.4;25.4;29.4;33.4;37.4;41.4;45.4;$$6.65;6.65;6.65;6.65;6.65;6.65;6.65;6.65;6.65;6.65;6.65;$$37.5;37.5;37.5;37.5;37.5;37.5;37.5;37.5;37.5;37.5;37.5;$$3;3;3;3;3;3;3;3;3;3;3;$$12.5;12.5;12.5;12.5;12.5;12.5;12.5;12.5;12.5;12.5;12.5;$$96$$11"
	elseif(stringmatch("4 across rows",sSavedName))
		sStorageString="+x$$Substrate;Substrate;Substrate;Substrate;$$2.4;2.4;2.4;2.4;$$6.65;19.15;31.65;44.15;$$46;46;46;46;$$12;12;12;12;$$4;4;4;4;$$96$$4"
	elseif(stringmatch("2 across each row (8 total)",sSavedName))
		sStorageString="-x$$Substrate;Substrate;Substrate;Substrate;Substrate;Substrate;Substrate;Substrate;$$48.4;48.4;48.4;48.4;48.4;48.4;48.4;48.4;$$4.4;8.9;16.9;21.4;29.65;33.9;42.15;46.4;$$46;46;46;46;46;46;46;46;$$12;12;12;12;12;12;12;12;$$4;4;4;4;4;4;4;4;$$96$$8"
	elseif(stringmatch("3 across Row 2 and 3 (6 total)",sSavedName))
		sStorageString="-x$$Substrate;Substrate;Substrate;Substrate;Substrate;Substrate;$$48.4;48.4;48.4;48.4;48.4;48.4;$$15.65;19.15;22.65;28.15;31.65;35.15;$$46;46;46;46;46;46;$$12;12;12;12;12;12;$$4;4;4;4;4;4;$$72$$6"
	elseif(stringmatch("33 Scans, along columns",sSavedName))
		sStorageString="+y$$Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;Film;$$5.4;9.4;13.4;17.4;21.4;25.4;29.4;33.4;37.4;41.4;45.4;5.4;9.4;13.4;17.4;21.4;25.4;29.4;33.4;37.4;41.4;45.4;5.4;9.4;13.4;17.4;21.4;25.4;29.4;33.4;37.4;41.4;45.4;$$9.9;9.9;9.9;9.9;9.9;9.9;9.9;9.9;9.9;9.9;9.9;22.4;22.4;22.4;22.4;22.4;22.4;22.4;22.4;22.4;22.4;22.4;34.9;34.9;34.9;34.9;34.9;34.9;34.9;34.9;34.9;34.9;34.9;$$6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;$$1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;$$6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;6;$$33$$33"
	elseif(stringmatch("2 across Row 2 and 3 (4 total)",sSavedName))
		sStorageString="-x$$Substrate;Substrate;Substrate;Substrate;$$48.4;48.4;48.4;48.4;$$16.15;22.15;28.65;34.65;$$46;46;46;46;$$12;12;12;12;$$4;4;4;4;$$48$$4"
	else
		sStorageString = Combi_GetInstrumentString("Dektak8","SAVED_"+sSavedName,"COMBIgor")
	endif
	string sScanDirection = stringFromList(0,sStorageString,"$$")
	string sScanStartStops = stringFromList(1,sStorageString,"$$")
	string sScanStartsX = stringFromList(2,sStorageString,"$$")
	string sScanStartsY = stringFromList(3,sStorageString,"$$")
	string sScanLengths = stringFromList(4,sStorageString,"$$")
	string sFeaturesPerScan = stringFromList(5,sStorageString,"$$")
	string sFeatureSpacings = stringFromList(6,sStorageString,"$$")
	string vTotalFeatures = stringFromList(7,sStorageString,"$$")
	string vTotalScans = stringFromList(8,sStorageString,"$$")

	if(stringmatch(vTotalScans,vTotalScansReal))
		Combi_GiveInstrumentGlobal("Dektak8","sScanDirection",sScanDirection,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartStops",sScanStartStops,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsX",sScanStartsX,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanStartsY",sScanStartsY,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sScanLengths",sScanLengths,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sFeaturesPerScan",sFeaturesPerScan,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","sFeatureSpacings",sFeatureSpacings,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","vTotalFeatures",vTotalFeatures,sProject)
		Combi_GiveInstrumentGlobal("Dektak8","vTotalScans",vTotalScans,sProject)
		Dektak8_WriteFeaturePositions()
		Combi_Dektak8()
	else
		DoAlert/T="Inconsistent number of scans",0,"There are "+vTotalScansReal+" scans loaded currently, but the setup currently being loaded is "+vTotalScans+" scans in length. Load aborted."
	endif
end

Function Dektak8_SaveCurrentScanDef(ctrlName) : ButtonControl
	String ctrlName
	//name to save it as
	string sSavedName = Combi_StringPrompt("Scan Setup Name","Name to call this scan configuration","","Please enter a name under which to save this scan configuration.","Save this scan setup")
	if(stringmatch(sSavedName,"CANCEL"))
		return -1
	endif
	sSavedName = cleanupName("SAVED_"+sSavedName,0)
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sScanDirection = Combi_GetInstrumentString("Dektak8","sScanDirection",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	string vTotalFeatures = Combi_GetInstrumentString("Dektak8","vTotalFeatures",sProject)
	string vTotalScans = Combi_GetInstrumentString("Dektak8","vTotalScans",sProject)
	string sStorageString = sScanDirection+"$$"+sScanStartStops+"$$"+sScanStartsX+"$$"+sScanStartsY+"$$"+sScanLengths+"$$"+sFeaturesPerScan+"$$"+sFeatureSpacings+"$$"+vTotalFeatures+"$$"+vTotalScans
	Combi_GiveInstrumentGlobal("Dektak8",sSavedName,sStorageString,"COMBIgor")
end

function DekTak8_WriteMask(iThisScan,iThisFeature,sStartStop,vScanLength,vDataLength,vFeatures,vFeatureSpacing,vSubstate,vFilm,vScaling,vOffset)
	int iThisScan,iThisFeature
	variable vScanLength,vFeatureSpacing,vSubstate,vFilm,vScaling,vOffset,vDataLength, vFeatures
	string sStartStop
	//for this project, get process wave
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	string sFocus2Edit = Combi_GetInstrumentString("Dektak8","sFocus2Edit",sProject)
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
	//make sure wave was found
	if(!waveexists(wProcessData))
		DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
		return -1
	endif
	//for checking for errors
	int vMaxDimSize = dimsize(wProcessData,2)-1
	//calcs
	variable iScalingFactor = vScaling/100
	variable iPer_mm = vScanLength/vDataLength/iScalingFactor
	int iMidScan = floor(vDataLength/2)
	int iPer_feature = floor(vFeatureSpacing/iPer_mm)
	int iHalffeature = floor(iPer_feature/2)
	int iOffset = floor(vOffset/iPer_mm)
	int iFilm = floor(vFilm/iPer_mm)
	int iHalfFilm = floor(iFilm/2)
	int iSub = floor(vSubstate/iPer_mm)
	int iHalfSub = floor(iSub/2)
	int iWindowStart = DekTak8_GetFeatureRange(iThisScan,iThisFeature,"Start")
	int iWindowEnd = DekTak8_GetFeatureRange(iThisScan,iThisFeature,"Stop")
	
	int iWindowMid = floor((iWindowStart+iWindowEnd)/2)
	int iFilm1Start,iFilm1End ,iFilm2Start,iFilm2End,iFeature1Start,iFeature1End,iFeature2Start,iFeature2End
	if(stringmatch(sFocus2Edit,"Film"))
		iFilm1Start = iWindowMid - iHalfFilm
		iFilm1End = iWindowMid + iHalfFilm
		iFeature1Start = iWindowStart 
		iFeature1End = iWindowStart + iHalfSub
		iFeature2Start = iWindowEnd - iHalfSub
		iFeature2End = iWindowEnd
	elseif(stringmatch(sFocus2Edit,"Sub"))
		iFilm1Start = iWindowStart 
		iFilm1End = iWindowStart + iHalfFilm
		iFilm2Start = iWindowEnd - iHalfFilm
		iFilm2End = iWindowEnd 
		iFeature1Start = iWindowMid - iHalfSub
		iFeature1End = iWindowMid + iHalfSub
	endif
	
	//clear this region
	wProcessData[iThisScan][3,4][iWindowStart,iWindowEnd] = nan
	
	int iBegin, iEnd
	if(stringmatch(sFocus2Edit,"Film"))
		//mark substrate Col3 and //mark film Col4
		if(iThisFeature==0)
			if(stringmatch(sStartStop,"Film"))
				iBegin = Dektak8_MaskCheck(iFeature2Start,vMaxDimSize)
				iEnd = Dektak8_MaskCheck(iFeature2End,vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck(iFeature2End-iHalffeature,vMaxDimSize)
				iEnd = Dektak8_MaskCheck(iFeature2End-iHalffeature+iHalfFilm,vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
			elseif(stringmatch(sStartStop,"Substrate"))
				iBegin = Dektak8_MaskCheck((iFeature2Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFeature2End),vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFeature2End-iPer_feature),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFeature2End-iPer_feature+iSub),vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFeature2End-iHalffeature-iHalfFilm),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFeature2End-iHalffeature+iHalfFilm),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
			endif
		elseif(iThisFeature==(vFeatures-1)&&stringmatch(sStartStop,"Substrate"))
			iBegin = Dektak8_MaskCheck((iFeature1Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFeature1End),vMaxDimSize)
			wProcessData[iThisScan][3][iBegin,iEnd] = 1
		elseif(iThisFeature==(vFeatures)&&stringmatch(sStartStop,"Film"))
			iBegin = Dektak8_MaskCheck((iFeature1Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFeature1End),vMaxDimSize)
			wProcessData[iThisScan][3][iBegin,iEnd] = 1
			iBegin = Dektak8_MaskCheck((iFeature1Start+iHalffeature-iHalfFilm),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFeature1Start+iHalffeature),vMaxDimSize)
			wProcessData[iThisScan][4][iBegin,iEnd] = 1
		else
			iBegin = Dektak8_MaskCheck((iFeature1Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFeature1End),vMaxDimSize)
			wProcessData[iThisScan][3][iBegin,iEnd] = 1
			iBegin = Dektak8_MaskCheck((iFeature2Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFeature2End),vMaxDimSize)
			wProcessData[iThisScan][3][iBegin,iEnd] = 1
			iBegin = Dektak8_MaskCheck((iFilm1Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFilm1End),vMaxDimSize)
			wProcessData[iThisScan][4][iBegin,iEnd] = 1
		endif	
	elseif(stringmatch(sFocus2Edit,"Sub"))
		//mark substrate Col3 //mark film Col4
		if(iThisFeature==0)
			if(stringmatch(sStartStop,"Film"))
				iBegin = Dektak8_MaskCheck((iFilm1Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm1End),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFilm2Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm2End),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFeature1Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFeature1End),vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
			elseif(stringmatch(sStartStop,"Substrate"))
				iBegin = Dektak8_MaskCheck((iFilm2Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm2End),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFilm2End-iHalffeature),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm2End-iHalffeature+iSub),vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
			endif
		elseif(iThisFeature==(vFeatures-1))
			if(stringmatch(sStartStop,"Film"))
				iBegin = Dektak8_MaskCheck((iFilm1Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm1End),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFilm2Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm2End),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFeature1Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFeature1End),vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
			elseif(stringmatch(sStartStop,"Substrate"))
				iBegin = Dektak8_MaskCheck((iFilm1Start),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm1End),vMaxDimSize)
				wProcessData[iThisScan][4][iBegin,iEnd] = 1
				iBegin = Dektak8_MaskCheck((iFilm1Start+iHalffeature-iSub),vMaxDimSize)
				iEnd = Dektak8_MaskCheck((iFilm1Start+iHalffeature),vMaxDimSize)
				wProcessData[iThisScan][3][iBegin,iEnd] = 1
			endif
		else
			iBegin = Dektak8_MaskCheck((iFilm2Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFilm2End),vMaxDimSize)
			wProcessData[iThisScan][4][iBegin,iEnd] = 1
			iBegin = Dektak8_MaskCheck((iFilm1Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFilm1End),vMaxDimSize)
			wProcessData[iThisScan][4][iBegin,iEnd] = 1
			iBegin = Dektak8_MaskCheck((iFeature1Start),vMaxDimSize)
			iEnd = Dektak8_MaskCheck((iFeature1End),vMaxDimSize)
			wProcessData[iThisScan][3][iBegin,iEnd] = 1
		endif
	endif
	
end

function DekTak8_GetFeatureRange(iThisScan,iThisFeature,sOption)
	int iThisScan,iThisFeature
	string sOption// "Start" or "Stop"
	
	//for this project, get process wave
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	variable vOffset = Combi_GetInstrumentNumber("Dektak8","vOffset",sProject)
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	string sFocus2Edit = Combi_GetInstrumentString("Dektak8","sFocus2Edit",sProject)
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
	//make sure wave was found
	if(!waveexists(wProcessData))
		DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
		return -1
	endif
	
	//scan def list
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	variable vMaskScaling = Combi_GetInstrumentNumber("Dektak8","vMaskScaling",sProject)
	
	//just this scan
	variable vScanLength = str2num(stringfromList(iThisScan,sScanLengths))
	variable vFeatureSpacing = str2num(stringfromList(iThisScan,sFeatureSpacings))
	variable vDataLength = str2num(stringfromList(iThisScan,sDataLengths))
	variable vFeatures = str2num(stringfromList(iThisScan,sFeaturesPerScan))
	string sStartStop = stringfromList(iThisScan,sScanStartStops)
	
	
	//for checking for errors
	int vMaxDimSize = dimsize(wProcessData,2)-1
	
	//calcs
	variable iPer_mm = vScanLength/vDataLength/(vMaskScaling/100)
	int iMidScan = floor(vDataLength/2)
	int iPer_feature = floor(vFeatureSpacing/iPer_mm)
	int iHalffeature = floor(iPer_feature/2)
	int iOffset = floor(vOffset/iPer_mm)
	
	int iAllFeatures, iFirstOffset, iFocusOffset
	if(stringmatch(sStartStop,"Film"))
		iAllFeatures = vFeatures*iPer_feature
		if(stringmatch(sFocus2Edit,"Film"))
			iFirstOffset = -floor(iPer_feature/2)
			iFocusOffset =  0
		elseif(stringmatch(sFocus2Edit,"Sub"))
			iFirstOffset = 0
			iFocusOffset= 0
		endif
	elseif(stringmatch(sStartStop,"Substrate"))
		iAllFeatures = (vFeatures-1)*iPer_feature
		if(stringmatch(sFocus2Edit,"Film"))
			iFirstOffset = -floor(iPer_feature/2)
			iFocusOffset = floor(iPer_feature/2)
		elseif(stringmatch(sFocus2Edit,"Sub"))
			iFirstOffset = -floor(iPer_feature/2)
			iFocusOffset = 0
		endif
	endif
	
	int iHalfAllFeatures = floor(iAllFeatures/2)
	int iWindowStart = iMidScan - iHalfAllFeatures + (iThisFeature*iPer_feature) + iOffset + iFirstOffset + iFocusOffset
	int iWindowEnd = iMidScan - iHalfAllFeatures + ((1+iThisFeature)*iPer_feature) + iOffset + iFirstOffset + iFocusOffset
	
	//check for numbers too big or small
	if(iThisFeature==0)
		iWindowStart = 0
	endif
	if(iThisFeature==vFeatures)
		iWindowEnd = vMaxDimSize
	endif
	if(iWindowStart<0)
		iWindowStart = 0
	elseif(iWindowStart>=vMaxDimSize)
		iWindowStart = vMaxDimSize
	endif
	if(iWindowEnd<0)
		iWindowEnd = 0
	elseif(iWindowEnd>=vMaxDimSize)
		iWindowEnd = vMaxDimSize
	endif

	if(stringmatch(sOption,"Start"))
		return iWindowStart
	elseif(stringmatch(sOption,"Stop"))
		return iWindowEnd
	else
		return -1
	endif
	
	
end

function Dektak8_Output(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	Combi_GiveInstrumentGlobal("Dektak8",ctrlName,num2str(checked),Combi_GetInstrumentString("Dektak8","sProject","COMBIgor"))
	
end

Function Dektak8_DoOutputs(ctrlName) : ButtonControl
	String ctrlName	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:

	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	variable vOffset = Combi_GetInstrumentNumber("Dektak8","vOffset",sProject)
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	string sXCurve = Combi_GetInstrumentString("Dektak8","sXCurve",sProject)
	string sYCurve = Combi_GetInstrumentString("Dektak8","sYCurve",sProject)
	
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
	wave wResultsData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results"
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	
	//get Libraries space values
	variable vLibraryWidth = Combi_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = Combi_GetGlobalNumber("vLibraryHeight",sProject)
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	variable vColumnSpacing = Combi_GetGlobalNumber("vColumnSpacing",sProject)
	variable vRowSpacing = Combi_GetGlobalNumber("vRowSpacing",sProject)
	int bXAxisFlip = Combi_GetGlobalNumber("bXAxesFlip",sProject)
	int bYAxisFlip = Combi_GetGlobalNumber("bYAxesFlip",sProject)
	string sOrigin = Combi_GetGlobalString("sOrigin",sProject)
	
	//make sure wave was found
	if(!waveexists(wProcessData))
		DoAlert/T="Cannot find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	if(!waveexists(wResultsData))
		DoAlert/T="Can't find the loaded wave", 0, "COMBIgor cannot find the wave root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results"
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	//get export options
	int bExportPlots = Combi_GetInstrumentNumber("Dektak8","bExportPlots",sProject)
	int bDeleteProcessData = Combi_GetInstrumentNumber("Dektak8","bDeleteProcessData",sProject)
	int bInterpThickness = Combi_GetInstrumentNumber("Dektak8","bInterpThickness",sProject)
	int bFitThickness = Combi_GetInstrumentNumber("Dektak8","bFitThickness",sProject)
	
	setdataFolder $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary
	Make/O/N=(dimsize(wMappingGrid,0),4) DekTak8_Thickness
	SetDataFolder root: 
	wave wThickness = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Thickness"
	wThickness[][] = nan
	wThickness[][0] = wMappingGrid[p][1]//x
	wThickness[][1] = wMappingGrid[p][2]//y
	//do fit thickness, 2D plane to the featuer heights
	WaveStats/Q/RMD=[][2,2]/Z wResultsData
	variable vMinZ 
	if(bFitThickness)
		Make/O/N=(6) wFitCoefsPlane
		wave wFitCoefsPlane = root:wFitCoefsPlane
		Make/O/T/N=0 twConstraints
		wave/T twConstraints = root:twConstraints
		make/O/N=(dimsize(wResultsData,0)) wXFitData, wYFitData, wZFitData
		wave wXFitData=root:wXFitData
		wave wYFitData=root:wYFitData
		wave wZFitData=root:wZFitData
		wXFitData[]=wResultsData[p][0]
		wYFitData[]=wResultsData[p][1]
		wZFitData[]=wResultsData[p][2]
		if(stringmatch(sXCurve,"Concave Up"))
			redimension/N=(dimsize(twConstraints,0)+1) twConstraints
			twConstraints[dimsize(twConstraints,0)-1] ="K3 > 0"
		elseif(stringmatch(sXCurve,"Concave Down"))
			redimension/N=(dimsize(twConstraints,0)+1) twConstraints
			twConstraints[dimsize(twConstraints,0)-1] ="K3 < 0"
		elseif(stringmatch(sXCurve,"Linear"))
			redimension/N=(dimsize(twConstraints,0)+2) twConstraints
			twConstraints[dimsize(twConstraints,0)-1] ="K3 < 0"
			twConstraints[dimsize(twConstraints,0)-2] ="K3 > 0"
		endif		
		if(stringmatch(sYCurve,"Concave Up"))
			redimension/N=(dimsize(twConstraints,0)+1) twConstraints
			twConstraints[dimsize(twConstraints,0)-1] ="K5 > 0"
		elseif(stringmatch(sYCurve,"Concave Down"))
			redimension/N=(dimsize(twConstraints,0)+1) twConstraints
			twConstraints[dimsize(twConstraints,0)-1] ="K5 < 0"
		elseif(stringmatch(sYCurve,"Linear"))
			redimension/N=(dimsize(twConstraints,0)+2) twConstraints
			twConstraints[dimsize(twConstraints,0)-1] ="K5 < 0"
			twConstraints[dimsize(twConstraints,0)-2] ="K5 > 0"
		endif		
		FuncFit/Q/W=2 Combi_PolyFit2D, wFitCoefsPlane, wZFitData[]/X={wXFitData[],wYFitData[]}/C=twConstraints
		wThickness[][2] = poly2d(wFitCoefsPlane,wThickness[p][0],wThickness[p][1])
		//move to scalar table
		int iSample
		for(iSample=0;iSample<dimsize(wThickness,0);iSample+=1)
			if(stringmatch(ctrlName,"Auto"))
				Combi_GiveScalar(wThickness[iSample][2],sProject,sLibrary,"Dektak8_ExpectedThickness",iSample)
			else
				Combi_GiveScalar(wThickness[iSample][2],sProject,sLibrary,"Dektak8_Thickness",iSample)
			endif
		endfor
		killwaves/Z wFitCoefsPlane, wXFitData, wYFitData, wZFitData,twConstraints
		//Killvariables/Z
		wave wFinalValues = $Combi_DataPath(sProject,1)+sLibrary+":Dektak8_Thickness"
		if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
			//simple map
			CombiDisplay_Map(sProject,sLibrary,"Dektak8_Thickness","Linear","BlueHot"," ","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",16,"000000")
			ColorScale/C/N=text0 "Thickness (μm)"
			Label left "y(mm)"
			Label bottom "x(mm)" 
			ModifyGraph useMrkStrokeRGB=1
			ModifyGraph msize=8
			//3D bad ass ness
			Killwindow/Z DektakDataVisual
			NewGizmo/N=DektakDataVisual/T="Dektak8_Thickness"/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))
			ModifyGizmo stopUpdates
			AppendToGizmo/Z defaultscatter=wResultsData, name=FeatureSamples
			AppendToGizmo/Z defaultscatter=wThickness, name=LibrarySamples
			ModifyGizmo/Q modifyObject=FeatureSamples, objectType=scatter, property={dropLines,16},property={dropLineColorType,0},property={dropLineWidth,.5}
			ModifyGizmo/Q modifyObject=FeatureSamples, objectType=scatter, property={color,0,0,0,1},property={shape,4},property={size,.5}
			ModifyGizmo/Q ModifyObject=FeatureSamples,objectType=scatter,property={ scatterColorType,0}	
			ModifyGizmo/Q modifyObject=LibrarySamples, objectType=scatter, property={dropLines,16},property={dropLineColorType,0},property={dropLineWidth,.5}
			ModifyGizmo/Q modifyObject=LibrarySamples, objectType=scatter, property={color,0,0,0,1},property={shape,12},property={size,.5}
			ModifyGizmo/Q ModifyObject=LibrarySamples,objectType=scatter,property={ scatterColorType,3}
			ModifyGizmo/Q ModifyObject=LibrarySamples,objectType=scatter,property={ markerCTab,BlueHot}
			ModifyGizmo/Q ModifyObject=LibrarySamples,objectType=scatter,property={ CTABScaling,100}, property={maxRGBA,wavemax(wFinalValues),0,0,0,1}, property={minRGBA,wavemin(wFinalValues),0,0,0,1}
			ModifyGizmo/Q setOuterBox={0,vLibraryWidth,0,vLibraryHeight,0,2*wavemax(wFinalValues)}
			ModifyGizmo/Q scalingOption=0
			ModifyGizmo/Q modifyObject=axes0, objectType=axes, property={11, visible, 0 },property={10, visible, 0 },property={7, visible, 0 }, property={6, visible, 0 }, property={2, visible, 0 }, property={3, visible, 0 }, property={4, visible, 1 }, property={5, visible, 0 }
			ModifyGizmo/Q modifyObject=axes0, objectType=axes, property={8, ticks, 3 }, property={9, ticks, 3 }, property={4, ticks, 3 }
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabel,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabel,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabel,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabel,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabel,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelText,"x(mm)"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelText,"y(mm)"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelText,"Thickness (μm)"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelText,"y(mm)"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelText,"x(mm)"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={0,axisLabelCenter,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={1,axisLabelCenter,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={4,axisLabelCenter,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={8,axisLabelCenter,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={9,axisLabelCenter,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelDistance,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelDistance,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelDistance,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelDistance,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelDistance,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelScale,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelScale,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelScale,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelScale,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelScale,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelTilt,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelTilt,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelTilt,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelTilt,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelTilt,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={0,axisLabelFont,"default"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={1,axisLabelFont,"default"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={4,axisLabelFont,"default"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={8,axisLabelFont,"default"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={9,axisLabelFont,"default"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelFlip,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelFlip,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelFlip,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabelFlip,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabelFlip,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,labelBillboarding,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,labelBillboarding,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,labelBillboarding,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,labelBillboarding,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,labelBillboarding,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,gridType,43}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,gridLinesColor,0.4,0.4,0.4,1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,gridPrimaryCount,5}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,gridSecondaryCount,5}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,gridLineWidth,2}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ -1,ticks,3}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ -1,tickScaling,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={0,fontName,"Times"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 8,axisLabel,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 9,axisLabel,0}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 0,axisLabelDistance,0.1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 1,axisLabelDistance,0.1}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={ 4,axisLabelDistance,0.2}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={0,axisLabelFont,"Times"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={1,axisLabelFont,"Times"}
			ModifyGizmo/Q ModifyObject=axes0,objectType=Axes,property={4,axisLabelFont,"Times"}
			ModifyGizmo resumeUpdates
		endif
	endif
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
end

Function Dektak8_DoFinish(ctrlName) : ButtonControl
	String ctrlName	
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	wave wProcessData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName
	wave wResultsData = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results"
	KillWindow/Z Dektak8Panel
	KillDataFolder/Z $"root:COMBIgor:"+sProject+":Data:Dektak8:"
	string sPluginName = "Dektak8"
	Combi_GiveInstrumentGlobal(sPluginName,"sLibrary","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sFileName","NONE LOADED",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"iActiveTab","0",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vTotalScans","0",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sFirstSample","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sLastSample",Combi_GetGlobalString("vTotalSamples", sProject),sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScanDirection","+x",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScanStartStops","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScanLengths","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScanStartsY","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScanStartsX","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sFeaturesPerScan","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sFeatureSpacings","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScan2Move","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sScanMoveDelta","0.5",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sDataLengths","",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"bScansDefined","0",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vScan2Edit","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vCurvatureRemovalOrder","3",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vFilmSubPoly","3",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vFeature2Edit","All",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vSmoothFactor","0",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vFeatureWidth","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vFilmWidth","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vMaskScaling","100",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"vOffset","0",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"sFocus2Edit","Film",sProject)
	//export options
	Combi_GiveInstrumentGlobal(sPluginName,"bExportPlots","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"bDeleteProcessData","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"bInterpThickness","1",sProject)
	Combi_GiveInstrumentGlobal(sPluginName,"bFitThickness","1",sProject)
end


function Dektak8_MaskCheck(iMaskEdge,iMaskMax)
	variable iMaskEdge//index number you want
	variable iMaskMax//dim size max
	if(iMaskEdge<0)
		return 0
	elseif(iMaskEdge>iMaskMax)
		return iMaskMax
	else
		return iMaskEdge
	endif
end

function Dektak8_DoFits(vFitOrder,sProcessFolder)
	variable vFitOrder
	string sProcessFolder
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	wave wProcessData = $sProcessFolder
	//get dektak8 globals
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sScanDirection = Combi_GetInstrumentString("Dektak8","sScanDirection",sProject)
	string sScanStartStops = Combi_GetInstrumentString("Dektak8","sScanStartStops",sProject)
	string sScanStartsX = Combi_GetInstrumentString("Dektak8","sScanStartsX",sProject)
	string sScanStartsY = Combi_GetInstrumentString("Dektak8","sScanStartsY",sProject)
	string sScanLengths = Combi_GetInstrumentString("Dektak8","sScanLengths",sProject)
	string sFeatureSpacings = Combi_GetInstrumentString("Dektak8","sFeatureSpacings",sProject)
	string sFeaturesPerScan = Combi_GetInstrumentString("Dektak8","sFeaturesPerScan",sProject)
	string sDataLengths = Combi_GetInstrumentString("Dektak8","sDataLengths",sProject)
	int vTotalScans = Combi_GetInstrumentNumber("Dektak8","vTotalScans",sProject)
	int vCurvatureRemovalOrder = Combi_GetInstrumentNumber("Dektak8","vCurvatureRemovalOrder",sProject)
	variable vSmoothFactor = Combi_GetInstrumentNumber("Dektak8","vSmoothFactor",sProject)
	variable vFeatureWidth  = Combi_GetInstrumentNumber("Dektak8","vFeatureWidth",sProject)
	variable vFilmWidth  = Combi_GetInstrumentNumber("Dektak8","vFilmWidth",sProject)
	variable vOffset = Combi_GetInstrumentNumber("Dektak8","vOffset",sProject)
	variable vMaskScaling = Combi_GetInstrumentNumber("Dektak8","vMaskScaling",sProject)
	string vScan2Edit = Combi_GetInstrumentString("Dektak8","vScan2Edit",sProject)
	string vFeature2Edit = Combi_GetInstrumentString("Dektak8","vFeature2Edit",sProject)
	variable vTotalFeatures = Combi_GetInstrumentNumber("Dektak8","vTotalFeatures",sProject)
	string sFeatures2Exclude = Combi_GetInstrumentString("Dektak8","sFeatures2Exclude",sProject)
	
	//declarations for internal variable 
	int iScan, iFeature, iThisFeature,  iYFactor, iXFactor, iIndex
	variable vThisStartX, vThisStartY, vThisScanLength, vFeatures, vFeatureDistance, vThisFeatureSpacing, vThisFeatureDistance, vScanMidX, vScanMidY
	variable vFeatureX, vFeatureY, vSubHeight,vFilmHeight
	string sStartStop
	
	//fill with masked values
	for(iScan=0;iScan<dimsize(wProcessData,0);iScan+=1)
		for(iIndex=0;iIndex<dimsize(wProcessData,2);iIndex+=1)
			wProcessData[iScan][5][iIndex] = nan
			wProcessData[iScan][6][iIndex] = nan
			wProcessData[iScan][7][iIndex] = nan
			wProcessData[iScan][8][iIndex] = nan
			if(wProcessData[iScan][3][iIndex]==1)
				wProcessData[iScan][5][iIndex] = wProcessData[iScan][2][iIndex]
			endif
			if(wProcessData[iScan][4][iIndex]==1)
				wProcessData[iScan][6][iIndex] = wProcessData[iScan][2][iIndex]
			endif
		endfor
	endfor
	
	//processing wave
	Make/O/N=(vFitOrder+1) wFitCoefsFilm
	Make/O/N=(vFitOrder+1) wFitCoefsSub
	//Make/O/N=(vFitOrder+1,dimsize(wProcessData,0)) wFeatureFitSigmas
	//Make/O/N=(vFitOrder+1) wFitCoefsSub
	wave wFitCoefsFilm = root:wFitCoefsFilm
	wave wFitCoefsSub = root:wFitCoefsSub
	//wave wTheCurveFitSigmas = root:wFeatureFitSigmas
	wave wResults = $"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":DekTak8_Results" 
	
	//loop through scans
	for(iScan=0;iScan<dimsize(wProcessData,0);iScan+=1)
		wResults[][2]=nan
		//remove curvature
		if(vFitOrder==1)
			//linear
			CurveFit/Q/W=2 line, kwCWave=wFitCoefsFilm, wProcessData[iScan][6][]
			CurveFit/Q/W=2 line, kwCWave=wFitCoefsSub, wProcessData[iScan][5][]
			wProcessData[iScan][7][] = poly(wFitCoefsSub,r)
			wProcessData[iScan][8][] = poly(wFitCoefsFilm,r)
		elseif(vFitOrder>1)
			//poly
			CurveFit/Q/W=2 poly (vFitOrder+1), kwCWave=wFitCoefsFilm, wProcessData[iScan][6][]
			CurveFit/Q/W=2 poly (vFitOrder+1), kwCWave=wFitCoefsSub, wProcessData[iScan][5][]
			wProcessData[iScan][7][] =  poly(wFitCoefsSub,r)
			wProcessData[iScan][8][] =  poly(wFitCoefsFilm,r)
		endif
		//wave FitSigmas = root:W_Sigma
		//wTheCurveFitSigmas[][iScan] = FitSigmas[p]
	endfor
	killwaves/Z root:W_ParamConfidenceInterval, wFitCoefsFilm, wFitCoefsFilm,wFitCoefsSub,root:W_Sigma
	//killwaves wTheCurveFitSigmas
	//calculate feature heights from fits
	int iXTotal, iXParts
	iThisFeature = 0
	int bFeature = 0, bSkipFeature = 0
	for(iScan=0;iScan<dimsize(wProcessData,0);iScan+=1)
		iFeature = 0
		vThisStartX = str2num(stringfromlist(iScan,sScanStartsX))
		vThisStartY = str2num(stringfromlist(iScan,sScanStartsY))
		vThisScanLength = str2num(stringfromlist(iScan,sScanLengths))
		vThisFeatureSpacing = str2num(stringfromlist(iScan,sFeatureSpacings))
		vFeatures = str2num(stringFromList(iScan,sFeaturesPerScan))
		vScanMidX = vThisStartX+(iXFactor*vThisScanLength/2)
		vScanMidY = vThisStartY+(iYFactor*vThisScanLength/2)
		sStartStop = stringFromList(iScan,sScanStartStops)
		if(stringmatch(sStartStop,"Substrate"))
			bSkipFeature = 1
			for(iIndex=0;iIndex<dimsize(wProcessData,2);iIndex+=1)
				if(wProcessData[iScan][3][iIndex]==1&&bFeature==0)
					bFeature = 1
					iXTotal = iIndex
					iXParts = 1
				elseif(wProcessData[iScan][3][iIndex]==1&&bFeature==1)	
					iXTotal+=iIndex
					iXParts+=1
				elseif(wProcessData[iScan][3][iIndex]!=1&&bFeature==1)
					bFeature = 0
					//end of feature take heights at mid feature 
					vSubHeight = wProcessData[iScan][7][floor(iXTotal/iXParts)]
					vFilmHeight = wProcessData[iScan][8][floor(iXTotal/iXParts)]
					if(whichlistItem(num2str(iThisFeature+1),sFeatures2Exclude)>-1)
						if(bSkipFeature==1&&iFeature==0)
							bSkipFeature = 0
						elseif(bSkipFeature==0&&iFeature!=(vFeatures-1))
							wResults[iThisFeature][2] = nan
						endif
						iThisFeature+=1
						iFeature+=1
					else
						if(bSkipFeature==1&&iFeature==0)
							bSkipFeature = 0
						elseif(bSkipFeature==0&&iFeature!=(vFeatures-1))
							wResults[iThisFeature][2] = vFilmHeight-vSubHeight
						endif
						iThisFeature+=1
						iFeature+=1
					endif
				else
					bFeature = 0
				endif
			endfor
		elseif(stringmatch(sStartStop,"Film"))
			for(iIndex=0;iIndex<dimsize(wProcessData,2);iIndex+=1)
				if(wProcessData[iScan][3][iIndex]==1&&bFeature==0)
					bFeature = 1
					iXTotal = iIndex
					iXParts = 1
				elseif(wProcessData[iScan][3][iIndex]==1&&bFeature==1)	
					iXTotal+=iIndex
					iXParts+=1
				elseif(wProcessData[iScan][3][iIndex]!=1&&bFeature==1)
					bFeature = 0
					//end of feature take heights at mid feature 
					if(whichlistItem(num2str(iThisFeature+1),sFeatures2Exclude)>-1)
						wResults[iThisFeature][2] = nan
						iThisFeature+=1
						iFeature+=1	
					else
						vSubHeight = wProcessData[iScan][7][floor(iXTotal/iXParts)]
						vFilmHeight = wProcessData[iScan][8][floor(iXTotal/iXParts)]
						wResults[iThisFeature][2] = vFilmHeight-vSubHeight
						iThisFeature+=1
						iFeature+=1	
					endif
				else
					bFeature = 0
				endif
			endfor
		endif
	endfor
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

function Dektak8_Define()
	Combi_Dektak8()
end

function/S Dektak8_Descriptions(sGlobalName)
	string sGlobalName
	string sInstrumentName = "Dektak8"
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:Combi_"+sInstrumentName+"_Globals"
	string sReturnstring = ""
	strswitch(sGlobalName)
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "No"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
	
end

function Dektak8_ThicknessMap()
	string sProject = COMBI_ChooseProject()
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library of interest:",0,0,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	string sZLabel = COMBI_StringPrompt("Thickness (μm)","Thickness label:","","","Plot Axis Label")
	if(stringmatch(sZLabel,"CANCEL"))
		return -1
	endif
	if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
		Print "Dektak8_MakeThicknessMap(\""+sProject+"\",\""+sLibrary+"\",\""+sZLabel+"\")"
	endif
	Dektak8_MakeThicknessMap(sProject,sLibrary,sZLabel)
end

function Dektak8_MakeThicknessMap(sProject,sLibrary,sZLabel)
	string sProject,sLibrary,sZLabel
	COMBIDisplay_Map(sProject,sLibrary,"Dektak8_Thickness","Linear","Rainbow","","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",19,"000000")
	ColorScale/C/N=text0 sZLabel
	ColorScale/C/N=text0/X=0.00/Y=2.00/E=2
end




//auto functionality after mask is defined
function Dektak8_DoAutoOutput(ctrlName) : ButtonControl
	String ctrlName	

	//get Dektak8 and Combigor details
	string sProject = Combi_GetInstrumentString("Dektak8","sProject","COMBIgor")
	string sLibrary = Combi_GetInstrumentString("Dektak8","sLibrary",sProject)
	string sTheCurrentUserFolder = GetDataFolder(1) 
	string sStoragePath = "root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples", sProject)
	string sFileName = Combi_GetInstrumentString("Dektak8","sFileName",sProject)
	sFileName = cleanupName(sFileName,0)
	sFileName = ReplaceString("csv",sFileName,"")
	sFileName = ReplaceString("_",sFileName,"")
	
	//folder to hold data
	setdataFolder $sStoragePath
	NewDataFolder/O/S AutoThickness
	sStoragePath+="AutoThickness:"
	Make/O/N=(10,9,vTotalSamples) AllThicknessValues//for collecting all values
	Make/O/N=(vTotalSamples,1) ThicknessBins//for binning
	Make/O/N=(vTotalSamples) Agreement_Percent//for binning
	Make/O/N=(vTotalSamples) Var_Thickness
	Make/O/N=(vTotalSamples) LibWork//for binning
	Make/O/N=(49) LibWork2//for binning
	setdataFolder root:
	Combi_AddDataType(sProject,sLibrary,"Dektak8_ExpectedPercentError",1)

	//get waves
	wave wAllThick = $sStoragePath+"AllThicknessValues"
	wave wThickBins = $sStoragePath+"ThicknessBins"
	wave wPercentAgree = $sStoragePath+"Agreement_Percent"
	wave wVarThick = $sStoragePath+"Var_Thickness"
	wave wWorker = $sStoragePath+"LibWork"
	wave wWorker2 = $sStoragePath+"LibWork2"
	setScale/I x,1,vTotalSamples,wPercentAgree
	setScale/I x,1,vTotalSamples,wVarThick
	wThickBins[][] = 0

	//Globals wave for Dektak8
	wave/T wDektakGlobals = root:Packages:COMBIgor:Instruments:COMBI_Dektak8_Globals
	
	//turn off output plots
	string sCurrentOutputOption = COMBI_GetGlobalString("sPlotOnLoad","COMBIgor")
	COMBI_GiveGlobal("sPlotOnLoad","No","COMBIgor")
	
	int iCurve,iFit,iSample,iStart
	int iCombo = 1
	killwindow Dektak8Panel//kill panel
	for(iCurve=0;iCurve<=9;iCurve+=1)
		if(iCurve==0)
			iStart = 1
		else
			iStart = iCurve
		endif
		wDektakGlobals[%vCurvatureRemovalOrder][%$sProject] = num2str(iCurve)//set curve poly
		Dektak8_ScanProcessing("Auto")//do curvature removal, no mask changing
		for(iFit=iStart;iFit<=9;iFit+=1)
			if((iFit+iCurve)<4)
				Continue
			endif
			COMBI_ProgressWindow("DektakProcessing","Calculating all fit combinations","Analyzing Dektak8",iCombo,50)
			DoUpdate/W=DektakProcessing
			wDektakGlobals[%vFilmSubPoly][%$sProject] = num2str(iFit)//set fit poly
			Dektak8_DoFits(iFit,"root:COMBIgor:"+sProject+":Data:Dektak8:"+sLibrary+":"+sFileName)//Do Thickness Fits 
			Dektak8_DoOutputs("Auto")
			//harvest wave 
			Duplicate/O $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":Dektak8_ExpectedThickness",$sStoragePath+"Curve"+num2str(iCurve)+"_Fit"+num2str(iFit)
			iCombo+=1
		endfor
	endfor
	//kill progress window
	COMBI_ProgressWindow("DektakProcessing","Calc. all 50 combinations","CALCULATING",iCombo,50)
	//reset plot option
	COMBI_GiveGlobal("sPlotOnLoad",sCurrentOutputOption,"COMBIgor")
	//get results wave and blank
	wave wAutoResults = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":Dektak8_ExpectedThickness"
	wave wAutoErrors = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":Dektak8_ExpectedPercentError"
	wAutoResults = nan
	setScale/I x,1,vTotalSamples,wAutoResults
	//compile results and find min/max
	variable vMin = inf
	variable vMax = -inf
	for(iCurve=0;iCurve<=9;iCurve+=1)
		if(iCurve==0)
			iStart = 1
		else
			iStart = iCurve
		endif
		for(iFit=iStart;iFit<=9;iFit+=1)
			if((iFit+iCurve)<4)
				Continue
			endif
			wave wThisResultsWave = $sStoragePath+"Curve"+num2str(iCurve)+"_Fit"+num2str(iFit)
			wAllThick[iCurve][iFit-1][] = wThisResultsWave[r]
			if(wavemax(wThisResultsWave)>vMax)
				vMax = wavemax(wThisResultsWave)
			endif
			if(wavemin(wThisResultsWave)<vMin)
				vMin = wavemin(wThisResultsWave)
			endif
			killwaves wThisResultsWave
		endfor
	endfor
	
	//scale and dim bin
	vMin = floor(vMin*1000)/1000
	vMax = ceil(vMax*1000)/1000
	redimension/N=(vTotalSamples,((vMax-vMin)/.005)) wThickBins
	redimension/N=(((vMax-vMin)/.005)) wWorker
	SetScale/I y,vMin,vMax, wThickBins
	SetScale/I x,vMin,vMax, wWorker
	for(iCurve=0;iCurve<=9;iCurve+=1)
		if(iCurve==0)
			iStart = 1
		else
			iStart = iCurve
		endif
		for(iFit=iStart;iFit<=9;iFit+=1)
			if((iFit+iCurve)<4)
				Continue
			endif
			for(iSample=0;iSample<vTotalSamples;iSample+=1)
				variable vThisThickness = wAllThick[iCurve][iFit-1][iSample]
				int iThisIndex = ScaleToIndex(wThickBins,vThisThickness,1)
				wThickBins[iSample][iThisIndex]+=1
			endfor
		endfor
	endfor
	
	//get max values
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		wWorker[] = wThickBins[iSample][p]
		iCombo=0
		for(iCurve=0;iCurve<=9;iCurve+=1)
			if(iCurve==0)
				iStart = 1
			else
				iStart = iCurve
			endif
			for(iFit=iStart;iFit<=9;iFit+=1)
				if((iFit+iCurve)<4)
					Continue
				endif
				wWorker2[iCombo] = wAllThick[iCurve][iFit-1][iSample]
				iCombo+=1
			endfor
		endfor
		if(wavemax(wWorker)>1)
			wavestats/Q wWorker
			wAutoResults[iSample] = V_maxloc
			wPercentAgree[iSample] = V_max/49*100
			wVarThick[iSample] = sqrt(variance(wWorker2))
			wAutoErrors[iSample] = sqrt(variance(wWorker2))/V_maxloc*100
		else
			wAutoResults[iSample] = nan
			wPercentAgree[iSample] = nan
			wVarThick[iSample] = nan
			wAutoErrors[iSample] = nan
		endif
		
		
	endfor
	
	//Killwaves wWorker, wWorker2
	
	//main
	string sWindowName = "Dektak8_Prob_"+sLibrary
	Display/L/K=1/N=$sWindowName wAutoResults
	ModifyGraph/W=$sWindowName margin(top)=200
	ModifyGraph/W=$sWindowName margin(bottom)=75
	ModifyGraph/W=$sWindowName width=400
	ModifyGraph/W=$sWindowName height=200
	ModifyGraph/W=$sWindowName margin(left)=75
	ModifyGraph/W=$sWindowName margin(right)=50
	ModifyGraph/W=$sWindowName gFont="Arial"
	ModifyGraph/W=$sWindowName gfSize=12
	ModifyGraph/W=$sWindowName mirror(left)=3
	
	Label/W=$sWindowName left "Thickness (μm)"
	SetAxis/W=$sWindowName left (0.95*wavemin(wAutoResults)),(1.05*wavemax(wAutoResults))
	ModifyGraph/W=$sWindowName minor(left)=1
	ModifyGraph/W=$sWindowName lblMargin(left)=10
	
	Label/W=$sWindowName bottom "Library sample (#)"
	ModifyGraph/W=$sWindowName mirror(bottom)=2
	ModifyGraph/W=$sWindowName manTick(bottom)={0,2,0,0}
	ModifyGraph/W=$sWindowName manMinor(bottom)={0,50}
	ModifyGraph/W=$sWindowName tickEnab(bottom)={1,vTotalSamples}
	SetAxis bottom 0,vTotalSamples+1
	ModifyGraph/W=$sWindowName mirror(bottom)=1
	ModifyGraph/W=$sWindowName lblMargin(bottom)=25
	
	ModifyGraph/W=$sWindowName mode=3
	ModifyGraph/W=$sWindowName msize=4
	ModifyGraph/W=$sWindowName mrkThick=1
	ModifyGraph/W=$sWindowName marker=19
	ErrorBars/W=$sWindowName/Y=4 Dektak8_ExpectedThickness Y,wave=(wVarThick,wVarThick)
	ModifyGraph/W=$sWindowName useMrkStrokeRGB=1

	//top percentage
	Display/L/HOST=$sWindowName/N=Agreement/W=(1,1,400,140) wPercentAgree
	sWindowName+="#Agreement"
	ModifyGraph/W=$sWindowName gFont="Arial"
	ModifyGraph/W=$sWindowName gfSize=12
	
	ModifyGraph/W=$sWindowName margin(left)=75
	ModifyGraph/W=$sWindowName margin(bottom)=10
	ModifyGraph/W=$sWindowName margin(right)=50
	ModifyGraph/W=$sWindowName margin(top)=10
	ModifyGraph/W=$sWindowName width=400
	ModifyGraph/W=$sWindowName height=140
	ModifyGraph/W=$sWindowName mirror(left)=3
	ModifyGraph/W=$sWindowName mirror(bottom)=2
	ModifyGraph/W=$sWindowName lblMargin(left)=10
	Label/W=$sWindowName left "Percent in agreement (%)"
	SetAxis/W=$sWindowName left 0,100
	ModifyGraph/W=$sWindowName minor(left)=1
	
	ModifyGraph/W=$sWindowName mirror(bottom)=2
	ModifyGraph/W=$sWindowName manTick(bottom)={0,2,0,0}
	ModifyGraph/W=$sWindowName manMinor(bottom)={0,50}
	ModifyGraph/W=$sWindowName tickEnab(bottom)={1,vTotalSamples}
	SetAxis bottom 0,vTotalSamples+1
	
	ModifyGraph/W=$sWindowName mode(Agreement_Percent)=1
	ModifyGraph/W=$sWindowName lblMargin(left)=10
	
	ModifyGraph/W=$sWindowName mode=8
	ModifyGraph/W=$sWindowName marker=19
	ModifyGraph/W=$sWindowName msize=3
	ModifyGraph/W=$sWindowName rgb=(0,0,65535)
	ModifyGraph/W=$sWindowName plusRGB=(0,0,65535)
	ModifyGraph/W=$sWindowName useMrkStrokeRGB=1
	ModifyGraph/W=$sWindowName grid(left)=2
	ModifyGraph/W=$sWindowName gridRGB(left)=(0,0,0)
	
	ModifyGraph/W=$sWindowName manTick(left)={0,10,0,0}
	ModifyGraph/W=$sWindowName manMinor(left)={1,50}
	
	sWindowName = "Dektak8_Prob_"+sLibrary
	SetActiveSubwindow $sWindowName
		
	NewImage/K=1 wThickBins
	ModifyGraph margin(left)=75,margin(bottom)=75,margin(right)=50,margin(top)=50,width=400,height=200
	ModifyGraph gFont="Arial",gfSize=12
	SetAxis/A left
	ModifyImage ThicknessBins ctab= {1,50,BlueHot256,0}
	ModifyGraph mirror(left)=1,mirror(top)=3,nticks(left)=10,lblMargin=10,btLen(left)=5,stLen(left)=2
	Label left "Thickness (μm)"
	Label top "Library sample (#)"
	ModifyGraph margin=50
	ModifyGraph margin(bottom)=100
	ModifyGraph mirror=3,nticks=10,fSize=12,lblMargin(left)=1,tkLblRot=0
	ModifyGraph standoff=1
	ColorScale/C/N=text0/F=0/B=1/M/A=MB/X=0.00/Y=2.00/E vert=0,widthPct=100,height=10,image=ThicknessBins,minor=1;DelayUpdate
	ColorScale/C/N=text0 "Fit combinations (#) "
	SetAxis left (0.95*wavemin(wAutoResults)),(1.05*wavemax(wAutoResults))
	
	setdatafolder $sTheCurrentUserFolder
	
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		//simple map
		CombiDisplay_Map(sProject,sLibrary,"Dektak8_ExpectedThickness","Linear","BlueHot"," ","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",16,"000000")
		ColorScale/C/N=text0 "Thickness (μm)"
		Label left "y(mm)"
		Label bottom "x(mm)" 
		ModifyGraph useMrkStrokeRGB=1
		ModifyGraph msize=8
		
		CombiDisplay_Map(sProject,sLibrary,"Dektak8_ExpectedPercentError","Linear","BlueHot"," ","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",16,"000000")
		ColorScale/C/N=text0 "Error(%)"
		Label left "y(mm)"
		Label bottom "x(mm)" 
		ModifyGraph useMrkStrokeRGB=1
		ModifyGraph msize=8
	endif
	
end
