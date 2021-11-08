#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
//functions to display a figure including the display panel
// Version History
// V1: Kevin Talley _ May 2018 : Original

//Description of functions within:
//P_Plot : Appends to a plot up to 4 axis traces.


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Functions to add to the wave twCOMBI_PluginGlobals, returns a 0 for new variable, or 1 for same as previous, or 2 for value change
//user passes the name and value of the Global
function COMBIDisplay_Global(sGlobal,sValue,sFolder)
	string sGlobal // global variable name
	string sValue // global variable value
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get twCOMBI_PluginGlobals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:COMBI_DisplayGlobals
	
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
		//returns a 1 or 2 depending on previous value 
		if(stringmatch(sValue,sOldValue))
			return 1
		else
			return 2
		endif
	endif
	
	//if it is new
	if(Finddimlabel(twGlobals,0,sGlobal)==-2)
		//increase number or rows
		variable vPreviousSize = dimsize(twGlobals,0)
		redimension/N=(vPreviousSize+1,-1) twGlobals
		//label dimension
		setdimlabel 0,vPreviousSize,$sGlobal,twGlobals
		twGlobals[vPreviousSize][%$sFolder] = sValue
		//return a zero
		return 0
	endif
end

//Functions to read global in twCOMBI_DisplayGlobals, returns the value  "NAG" if Not A Global
function/S COMBIDisplay_GetString(sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get twCOMBI_PluginGlobals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:COMBI_DisplayGlobals
	
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return "NAG"
	endif
	
	//return value
	return twGlobals[%$sGlobal2Read][%$sFolder]
end

//Functions to read global in twCOMBI_DisplayGlobals, returns the value  "nan" if Not A Global
function COMBIDisplay_GetNumber(sGlobal2Read, sFolder)
	string sGlobal2Read // global of interest
	string sFolder // name of folder, "COMBIgor" for main globals
	
	//get twCOMBI_PluginGlobals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:COMBI_DisplayGlobals
	
	//return nan if no such Global exists 
	if(finddimlabel(twGlobals,0,sGlobal2Read)==-2)
		return nan
	endif
	
	//return value
	return str2num(twGlobals[%$sGlobal2Read][%$sFolder])
end

//function to make plotting panel
//grid established with columns of 150 and rows of 30 
function COMBIDisplay()
	
	//get initial values for popups
	variable vProject
	variable vSampleMin,vSampleMax
	variable bProject = 0
	
	if(Stringmatch(COMBIDisplay_GetString("sProject","COMBIgor"),"NAG"))
		vProject = 0
		//make all needed globals in global display wave bLockLibrary
		COMBIDisplay_Global("bLibraryLock","0","COMBIgor")
		COMBIDisplay_Global("vHMin","Auto","COMBIgor")
		COMBIDisplay_Global("vHMax","Auto","COMBIgor")
		COMBIDisplay_Global("vVMin","Auto","COMBIgor")
		COMBIDisplay_Global("vVMax","Auto","COMBIgor")
		COMBIDisplay_Global("vCMin","Auto","COMBIgor")
		COMBIDisplay_Global("vCMax","Auto","COMBIgor")
		COMBIDisplay_Global("vSMin","Auto","COMBIgor")
		COMBIDisplay_Global("vSMax","Auto","COMBIgor")
		COMBIDisplay_Global("vSampleMin","All","COMBIgor")
		COMBIDisplay_Global("vSampleMax","All","COMBIgor")
		COMBIDisplay_Global("vGA1Min","All","COMBIgor")
		COMBIDisplay_Global("vGA1Max","All","COMBIgor")
		COMBIDisplay_Global("vGA2Min","All","COMBIgor")
		COMBIDisplay_Global("vGA2Max","All","COMBIgor")
		COMBIDisplay_Global("sHScale","Linear","COMBIgor")
		COMBIDisplay_Global("sVScale","Linear","COMBIgor")
		COMBIDisplay_Global("sCScale","Linear","COMBIgor")
		COMBIDisplay_Global("sSScale","Linear","COMBIgor")
		COMBIDisplay_Global("sMCScale","Linear","COMBIgor")
		COMBIDisplay_Global("sMSScale","Linear","COMBIgor")
		COMBIDisplay_Global("sHDim","Library","COMBIgor")
		COMBIDisplay_Global("sVDim","Library","COMBIgor")
		COMBIDisplay_Global("sCDim","","COMBIgor")
		COMBIDisplay_Global("sSDim","","COMBIgor")
		COMBIDisplay_Global("sHData","","COMBIgor")
		COMBIDisplay_Global("sVData","","COMBIgor")
		COMBIDisplay_Global("sCData","","COMBIgor")
		COMBIDisplay_Global("sSData","","COMBIgor")
		COMBIDisplay_Global("sDData","All","COMBIgor")
		COMBIDisplay_Global("sDSample","All","COMBIgor")
		COMBIDisplay_Global("sHError","","COMBIgor")
		COMBIDisplay_Global("sVError","","COMBIgor")
		COMBIDisplay_Global("sCColor","Rainbow","COMBIgor")
		COMBIDisplay_Global("sMCColor","Rainbow","COMBIgor")
		COMBIDisplay_Global("sProject","","COMBIgor")
		COMBIDisplay_Global("sLibraryH","","COMBIgor")
		COMBIDisplay_Global("sLibraryV","","COMBIgor")
		COMBIDisplay_Global("sLibraryC","","COMBIgor")
		COMBIDisplay_Global("sLibraryS","","COMBIgor")
		COMBIDisplay_Global("sLibrarySee","","COMBIgor")
		COMBIDisplay_Global("sMLibrarySee","","COMBIgor")
		COMBIDisplay_Global("sHLocation","Bottom","COMBIgor")
		COMBIDisplay_Global("sMarker","Circles","COMBIgor")
		COMBIDisplay_Global("sMMarker","Circles","COMBIgor")
		COMBIDisplay_Global("sMode","Markers","COMBIgor")
		COMBIDisplay_Global("vMode","3","COMBIgor")
		COMBIDisplay_Global("vMarker","19","COMBIgor")
		COMBIDisplay_Global("vMMarker","19","COMBIgor")
		COMBIDisplay_Global("sMarker","Circles","COMBIgor")
		COMBIDisplay_Global("sVLocation","Left","COMBIgor")
		COMBIDisplay_Global("vDDim","0","COMBIgor")
		COMBIDisplay_Global("vHDim","0","COMBIgor")
		COMBIDisplay_Global("vVDim","0","COMBIgor")
		COMBIDisplay_Global("vCDim","-1","COMBIgor")
		COMBIDisplay_Global("vSDim","-1","COMBIgor")
		COMBIDisplay_Global("iActiveTab","0","COMBIgor")
		
		COMBIDisplay_Global("sMCData","","COMBIgor")
		COMBIDisplay_Global("sMSData","","COMBIgor")
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
		COMBIDisplay_Global("bMSaveStats","0","COMBIgor")
		COMBIDisplay_Global("sMStyle","Markers","COMBIgor")
		COMBIDisplay_Global("sMFitOption","None","COMBIgor")
		
		COMBIDisplay_Global("sMapType","y(mm) vs x(mm)","COMBIgor")
		COMBIDisplay_Global("sLibraryFilter","","COMBIgor")
		COMBIDisplay_Global("sDataTypeFilter","","COMBIgor")
		//set a few labels
		COMBIDisplay_Global("Sample","Library Sample Number","Label")
		COMBIDisplay_Global("x_mm","Library x dimension (mm)","Label")
		COMBIDisplay_Global("y_mm","Library y dimension (mm)","Label")
	
	endif
	
	//pre-populate the sProject Global
	string sProject
	if(ItemsinList(COMBI_Projects())>=1)
		if(whichListItem(COMBIDisplay_GetString("sProject","COMBIgor"),COMBI_Projects())==-1)
			COMBIDisplay_Global("sProject",stringfromList(0,COMBI_Projects()),"COMBIgor")
		endif
		vProject = whichListItem(COMBIDisplay_GetString("sProject","COMBIgor"),COMBI_Projects())+2
		bProject = 1
	elseif(ItemsinList(COMBI_Projects())==0)
		COMBIDisplay_Global("sProject",stringfromList(0,COMBI_ChooseProject()),"COMBIgor")
	endif
	sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	
	int iActiveTab = COMBIDisplay_GetNumber("iActiveTab","COMBIgor")
	int iPanelH, iPanelW
	if(iActiveTab==0)
		iPanelH = 285
		iPanelW = 950
	elseif(iActiveTab==1)
		iPanelH = 145
		iPanelW = 400
	elseif(iActiveTab==2)
		iPanelH = 408
		iPanelW = 350
	endif
	//kill if open already
	string sPanelName="COMBIDisplayPanel"
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z $sPanelName wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z $sPanelName
	//get global wave
	wave/T twGlobals = root:Packages:COMBIgor:COMBI_DisplayGlobals
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	string sDimOptions = "Library;Scalar;Vector"
	
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+iPanelW,vWinTop+iPanelH)/N=COMBIDisplayPanel as "Display COMBIgor Data"
	SetDrawLayer UserBack;SetDrawEnv fname = sFont;SetDrawEnv textxjust = 1,textyjust = 1;SetDrawEnv fsize = 12;SetDrawEnv save
	
	//get the Library qualifiers from Libraries space wave
	string sGA1,sGA2
	if(bProject==1)// if a project exists to use.
		wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
		wave wLibrary = $COMBI_DataPath(sProject,0)
		sGA1 = GetDimLabel(wMappingGrid,1,3)
		sGA2 = GetDimLabel(wMappingGrid,1,4)
	else
		sGA1 = ""
		sGA2 = ""
	endif
		
	//set pop up values
	variable vHDim,vVDim,vCDim,vSDim,vDDim
	variable vHScale,vVScale,vCScale,vSScale
	if(Stringmatch(COMBIDisplay_GetString("vDDim","COMBIgor"),"NAG"))
		vDDim = 1
		COMBIDisplay_Global("vDDim","0","COMBIgor")
	else
		vDDim = COMBIDisplay_GetNumber("vDDim","COMBIgor")+2
	endif
	if(Stringmatch(COMBIDisplay_GetString("sHDim","COMBIgor"),"NAG"))
		vHDim = 1
		vHScale = 1
		COMBIDisplay_Global("sHScale","Linear","COMBIgor")
		COMBIDisplay_Global("sHDim","","COMBIgor")
	else
		vHDim = whichListItem(COMBIDisplay_GetString("sHDim","COMBIgor"),"Library;Scalar;Vector")+1
		vHScale = whichListItem(COMBIDisplay_GetString("sHScale","COMBIgor"),"Linear;Log")+1
	endif
	if(Stringmatch(COMBIDisplay_GetString("sVDim","COMBIgor"),"NAG"))
		vVDim = 1
		vVScale = 1
		COMBIDisplay_Global("sVScale","Linear","COMBIgor")
		COMBIDisplay_Global("sVDim","","COMBIgor")
	else
		vVDim = whichListItem(COMBIDisplay_GetString("sVDim","COMBIgor"),"Library;Scalar;Vector")+1
		vVScale = whichListItem(COMBIDisplay_GetString("sVScale","COMBIgor"),"Linear;Log")+1
	endif
	if(Stringmatch(COMBIDisplay_GetString("sCDim","COMBIgor"),"NAG"))
		vCDim = 1
		vCScale = 1
		COMBIDisplay_Global("sCScale","Linear","COMBIgor")
		COMBIDisplay_Global("sCDim","","COMBIgor")
	else
		vCDim = whichListItem(COMBIDisplay_GetString("sCDim","COMBIgor"),"Library;Scalar;Vector")+2
		vCScale = whichListItem(COMBIDisplay_GetString("sCScale","COMBIgor"),"Linear;Log")+1
	endif
	if(Stringmatch(COMBIDisplay_GetString("sSDim","COMBIgor"),"NAG"))
		vSDim = 1
		vSScale = 1
		COMBIDisplay_Global("sSScale","Linear","COMBIgor")
		COMBIDisplay_Global("sSDim","","COMBIgor")
	else
		vSDim = whichListItem(COMBIDisplay_GetString("sSDim","COMBIgor"),"Library;Scalar;Vector")+2
		vSScale = whichListItem(COMBIDisplay_GetString("sSScale","COMBIgor"),"Linear;Log")+1
	endif
	variable vMode = whichListItem(COMBIDisplay_GetString("sMode","COMBIgor"),"Lines between points;Sticks to zero;Dots at Samples;Markers;Lines and markers;Histogram bars;Cityscape;Fill to zero;Sticks and markers")+1
	variable vMarker = COMBIDisplay_GetNumber("vMarker","COMBIgor")
	variable vMMarker = COMBIDisplay_GetNumber("vMMarker","COMBIgor")

	//Tabs
	variable vColW = 200 
	variable cRowH = 25
	variable vYValue = 15
	TabControl DekTak8Processing size={300,20},pos={iPanelW/2-150,vYValue-10},tabLabel(0)="Plotting",tabLabel(1)="See Data",tabLabel(2)="Mapping",Value=iActiveTab,proc=COMBIDisplay_TabAction,font=sFont,fstyle=1,fColor=(0,0,0),fsize=16
	DrawLine 10,vYValue+12,iPanelW-10,vYValue+12
	vYValue+= 25
	
	int Xbump
	if(iActiveTab==0)//Plotting
	
		//Project Row
		DrawText (80),vYValue-2, "COMBIgor project:"
		PopupMenu sProject,pos={(240),vYValue-10},mode=(WhichListItem(sProject, COMBI_Projects())+1),bodyWidth=150,value=COMBI_Projects(),proc=COMBIDisplay_UpdateGlobal
		
		//mode 
		DrawText 330,vYValue-2, "Mode:"
		PopupMenu sMode,pos={(455),vYValue-10},bodyWidth=150,mode=vMode,value="Lines between points;Sticks to zero;Dots at Samples;Markers;Lines and markers;Histogram bars;Cityscape;Fill to zero;Sticks and markers",proc=COMBIDisplay_UpdateGlobal

		//type saving
		button SaveType,title="Save Type",appearance={native,All},pos={530,vYValue-11},size={80,20},proc=COMBIDisplay_SaveType,font=sFont,fstyle=1,fColor=(65535,49151,49151),fsize=14
		button LoadType,title="Load Type",appearance={native,All},pos={630,vYValue-11},size={80,20},proc=COMBIDisplay_LoadType,font=sFont,fstyle=1,fColor=(65535,49151,49151),fsize=14 
		button SetLabel,title="Set Label",appearance={native,All},pos={730,vYValue-11},size={80,20},proc=COMBIDisplay_SetLabel,font=sFont,fstyle=1,fColor=(65535,49151,49151),fsize=14
		button Reset,title="Reset",appearance={native,All},pos={830,vYValue-11},size={80,20},proc=COMBIDisplay_ResetPanel,font=sFont,fstyle=1,fColor=(65535,49151,49151),fsize=14
		vYValue+=10
		
		// organization lines
		DrawLine 10,vYValue,940,vYValue//h
		DrawLine 150,vYValue,150,vYValue+167//v
		DrawLine 350,vYValue,350,vYValue+167//v
		DrawLine 550,vYValue,550,vYValue+167//v
		DrawLine 750,vYValue,750,vYValue+128//v
		vYValue+= 10
		DrawText 80,vYValue, "Axis/Attribute"
		DrawText 255,vYValue, "Horizontal"
		DrawText 455,vYValue, "Vertical"
		DrawText 655,vYValue, "Marker Color"
		DrawText 855,vYValue, "Marker Size"
		vYValue+= 10
		DrawLine 10,vYValue,940,vYValue//h
		
		//Axis Data Dims
		vYValue+= 15
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Data Catagory:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		PopupMenu sHDim,pos={280+10,vYValue-10},mode=vHDim,bodyWidth=180,value="Library;Scalar;Vector",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sVDim,pos={480+10,vYValue-10},mode=vVDim,bodyWidth=180,value="Library;Scalar;Vector",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sCDim,pos={680+10,vYValue-10},mode=vCDim,bodyWidth=180,value=" ;Library;Scalar;Vector",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sSDim,pos={880+10,vYValue-10},mode=vSDim,bodyWidth=180,value=" ;Library;Scalar;Vector",proc=COMBIDisplay_UpdateGlobal
		vYValue+= 10
		//Axis Libraries
		vYValue+= 10
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Library Name:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		CheckBox bLibraryLock,pos={20,vYValue-10},size={100,20},title="",value=COMBIDisplay_GetNumber("bLibraryLock","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		int iLibraryH = WhichListItem(COMBIDisplay_GetString("sLibraryH","COMBIgor"),COMBIDisplay_LibraryList("H"))+1
		int iLibraryV = WhichListItem(COMBIDisplay_GetString("sLibraryV","COMBIgor"),COMBIDisplay_LibraryList("V"))+1
		int iLibraryC = WhichListItem(COMBIDisplay_GetString("sLibraryC","COMBIgor"),COMBIDisplay_LibraryList("C"))+1
		int iLibraryS = WhichListItem(COMBIDisplay_GetString("sLibraryS","COMBIgor"),COMBIDisplay_LibraryList("S"))+1
		PopupMenu sLibraryH,pos={(280+10),vYValue-10},mode=(iLibraryH),bodyWidth=180,value=COMBIDisplay_LibraryList("H"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sLibraryV,pos={(480+10),vYValue-10},mode=(iLibraryV),bodyWidth=180,value=COMBIDisplay_LibraryList("V"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sLibraryC,pos={(680+10),vYValue-10},mode=(iLibraryC),bodyWidth=180,value=COMBIDisplay_LibraryList("C"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sLibraryS,pos={(880+10),vYValue-10},mode=(iLibraryS),bodyWidth=180,value=COMBIDisplay_LibraryList("S"),proc=COMBIDisplay_UpdateGlobal
		vYValue+= 10
		
		//Axis Data Types
		vYValue+= 10
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Data Type:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		int iHData = WhichListItem(COMBIDisplay_GetString("sHData","COMBIgor"),COMBIDisplay_DataList("H"))+1
		int iVData = WhichListItem(COMBIDisplay_GetString("sVData","COMBIgor"),COMBIDisplay_DataList("V"))+1
		int iCData = WhichListItem(COMBIDisplay_GetString("sCData","COMBIgor"),COMBIDisplay_DataList("C"))+1
		int iSData = WhichListItem(COMBIDisplay_GetString("sSData","COMBIgor"),COMBIDisplay_DataList("S"))+1
		PopupMenu sHData,pos={(280+10),vYValue-10},mode=(iHData),bodyWidth=180,value=COMBIDisplay_DataList("H"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sVData,pos={(480+10),vYValue-10},mode=(iVData),bodyWidth=180,value=COMBIDisplay_DataList("V"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sCData,pos={(680+10),vYValue-10},mode=(iCData),bodyWidth=180,value=COMBIDisplay_DataList("C"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sSData,pos={(880+10),vYValue-10},mode=(iSData),bodyWidth=180,value=COMBIDisplay_DataList("S"),proc=COMBIDisplay_UpdateGlobal
		vYValue+= 10

		//Axis Scale Type
		vYValue+= 10
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Scale Type:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		PopupMenu sHScale,pos={280+10,vYValue-10},mode=vHScale,bodyWidth=180,value="Linear;Log;-Linear;-Log",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sVScale,pos={480+10,vYValue-10},mode=vVScale,bodyWidth=180,value="Linear;Log;-Linear;-Log",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sCScale,pos={680+10,vYValue-10},mode=vCScale,bodyWidth=180,value="Linear;Log;-Linear;-Log",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sSScale,pos={880+10,vYValue-10},mode=vSScale,bodyWidth=180,value="Linear;Log;-Linear;-Log",proc=COMBIDisplay_UpdateGlobal
		vYValue+= 10

		//Axis Range 
		vYValue+= 10
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Range:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		PopupMenu vHMin,pos={(190),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vHMinF, title=" ",pos={157,vYValue-9},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vHMin][%COMBIgor]
		DrawText 250,vYValue, "-"
		PopupMenu vHMax,pos={(290),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vHMaxF, title=" ",pos={257,vYValue-9},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vHMax][%COMBIgor]
		PopupMenu vVMin,pos={(390),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vVMinF, title=" ",pos={357,vYValue-9},size={70,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vVMin][%COMBIgor]
		DrawText 450,vYValue, "-"
		PopupMenu vVMax,pos={(490),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vVMaxF, title=" ",pos={457,vYValue-9},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vVMax][%COMBIgor]
		PopupMenu vCMin,pos={(590),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vCMinF, title=" ",pos={557,vYValue-9},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vCMin][%COMBIgor]
		DrawText 650,vYValue, "-"
		PopupMenu vCMax,pos={(690),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vCMaxF, title=" ",pos={657,vYValue-9},size={70,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vCMax][%COMBIgor]
		PopupMenu vSMin,pos={(790),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vSMinF, title=" ",pos={757,vYValue-9},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vSMin][%COMBIgor]
		DrawText 850,vYValue, "-"
		PopupMenu vSMax,pos={(890),vYValue-10},mode=1,bodyWidth=80,value="Auto",proc=COMBIDisplay_UpdateGlobal
		SetVariable vSMaxF, title=" ",pos={857,vYValue-9},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vSMax][%COMBIgor]
		vYValue+= 10
		DrawLine 550,vYValue+2,940,vYValue+2

		//Axis Location 
		int iHLocation = WhichListItem(COMBIDisplay_GetString("sHLocation","COMBIgor"),"Bottom;Top")+1
		int iVLocation = WhichListItem(COMBIDisplay_GetString("sVLocation","COMBIgor"),"Left;Right")+1
		vYValue+= 10
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Location:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		
		PopupMenu sHLocation,pos={290,vYValue-10},mode=iHLocation,bodyWidth=180,value="Bottom;Top",proc=COMBIDisplay_UpdateGlobal
		PopupMenu sVLocation,pos={490,vYValue-10},mode=iVLocation,bodyWidth=180,value="Left;Right",proc=COMBIDisplay_UpdateGlobal
		vYValue+= 10
		
		//Axis Error 
		vYValue+= 10
		int iHError = WhichListItem(COMBIDisplay_GetString("sHError","COMBIgor"),COMBIDisplay_DataList("H"))+1
		int iVError = WhichListItem(COMBIDisplay_GetString("sVError","COMBIgor"),COMBIDisplay_DataList("V"))+1
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 130,vYValue-2, "Error Bars:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		
		PopupMenu sHError,pos={(290),vYValue-10},mode=iHError,bodyWidth=180,value=COMBIDisplay_DataList("H"),proc=COMBIDisplay_UpdateGlobal
		PopupMenu sVError,pos={(490),vYValue-10},mode=iVError,bodyWidth=180,value=COMBIDisplay_DataList("V"),proc=COMBIDisplay_UpdateGlobal
		vYValue+= 10
		DrawLine 10,vYValue+2,940,vYValue+2
	
		//extra marker options
		vYValue-= 18
		DrawText 580,vYValue-2, "Colors:"
		int iCColor = WhichListItem(COMBIDisplay_GetString("sCColor","COMBIgor"),CTabList())+1
		PopupMenu sCColor,pos={(690),vYValue-10},mode=iCColor,bodyWidth=130,value=CTabList(),proc=COMBIDisplay_UpdateGlobal

		DrawText 845,vYValue-2, "Markers:            \\Z18\W50"+num2str(vMarker)+"\W50"+num2str(vMarker)
		PopupMenu sMarker,pos={(790),vYValue-10},bodyWidth=25,value="*MARKERPOP*",proc=COMBIDisplay_UpdateGlobal
		vYValue+= 18
		
		//Library subspace and Plot/append buttons
		vYValue+= 17
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 80,vYValue-2, "Samples:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		PopupMenu vSampleMin,pos={94,vYValue-10},mode=1,bodyWidth=45,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),0),proc=COMBIDisplay_UpdateGlobal
		SetVariable vSampleMinF, title=" ",pos={90,vYValue-9},size={42,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vSampleMin][%COMBIgor]
		DrawText 152,vYValue, "to"
		PopupMenu vSampleMax,pos={165,vYValue-10},mode=1,bodyWidth=45,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),0),proc=COMBIDisplay_UpdateGlobal
		SetVariable vSampleMaxF, title=" ",pos={160,vYValue-9},size={42,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vSampleMax][%COMBIgor]
		vYValue+= 20
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 80,vYValue-2, sGA1+"s:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		PopupMenu vGA1Min,pos={94,vYValue-10},mode=1,bodyWidth=45,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),3),proc=COMBIDisplay_UpdateGlobal
		SetVariable vGA1MinF, title=" ",pos={90,vYValue-9},size={42,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vGA1Min][%COMBIgor]
		DrawText 152,vYValue, "to"
		PopupMenu vGA1Max,pos={165,vYValue-10},mode=1,bodyWidth=45,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),3),proc=COMBIDisplay_UpdateGlobal
		SetVariable vGA1MaxF, title=" ",pos={160,vYValue-9},size={42,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vGA1Max][%COMBIgor]
		vYValue+= 20
		SetDrawEnv textxjust = 2;SetDrawEnv save
		DrawText 80,vYValue-2, sGA2+"s:"
		SetDrawEnv textxjust = 1;SetDrawEnv save
		PopupMenu vGA2Min,pos={94,vYValue-10},mode=1,bodyWidth=45,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),4),proc=COMBIDisplay_UpdateGlobal
		SetVariable vGA2MinF, title=" ",pos={90,vYValue-9},size={42,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vGA2Min][%COMBIgor]
		DrawText 152,vYValue, "to"
		PopupMenu vGA2Max,pos={165,vYValue-10},mode=1,bodyWidth=45,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),4),proc=COMBIDisplay_UpdateGlobal
		SetVariable vGA2MaxF, title=" ",pos={160,vYValue-9},size={42,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%vGA2Max][%COMBIgor]
		
		//filters
		vYValue-=30
		DrawText 290,vYValue-2, "Library Filter:"
		SetVariable vLibraryFilterF, title=" ",pos={330,vYValue-9},size={120,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sLibraryFilter][%COMBIgor]
		vYValue+=20
		DrawText 280,vYValue-2, "Data Type Filter:"
		SetVariable vDataTypeFilterF, title=" ",pos={330,vYValue-9},size={120,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sDataTypeFilter][%COMBIgor]
		vYValue+=10
			
		//plot buttons
		button NewPlot,title="New Plot",appearance={native,All},pos={460,vYValue-40},size={110,40},proc=COMBIDisplay_DoPlot,font=sFont,fstyle=1,fColor=(49151,60031,65535),fsize=16
		button AppendPlot,title="Append Plot",appearance={native,All},pos={580,vYValue-40},size={110,40},proc=COMBIDisplay_DoPlot,font=sFont,fstyle=1,fColor=(49151,60031,65535),fsize=16
		button PlotHistory,title="See Plot Info",appearance={native,All},pos={700,vYValue-40},size={110,40},proc=COMBIDisplay_DataSource,font=sFont,fstyle=1,fColor=(57346,65535,49151),fsize=16
		button SavePlot,title="Save Plot",appearance={native,All},pos={820,vYValue-40},size={110,40},proc=COMBIDisplay_SavePlot,font=sFont,fstyle=1,fColor=(57346,65535,49151),fsize=16

	elseif(iActiveTab==1)//See Data
	
		//Project Row
		DrawText 100,vYValue, "COMBIgor project:"
		PopupMenu sProject,pos={300,vYValue-8},mode=1,bodyWidth=185,value=";"+COMBI_Projects(),proc=COMBIDisplay_UpdateGlobal
		SetVariable sProjectF, title=" ",pos={220-57,vYValue-7},size={175,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sProject][%COMBIgor] 
		vYValue+=25
	
		//Library 
		DrawText  (135),vYValue, "Library:"
		PopupMenu sLibrarySee,pos={300,vYValue-8},mode=1,bodyWidth=185,value=COMBIDisplay_LibraryList("D"),proc=COMBIDisplay_UpdateGlobal
		SetVariable sLibrarySeeF, title=" ",pos={220-57,vYValue-7},size={175,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sLibrarySee][%COMBIgor]
		vYValue+=25
				
		//See data
		DrawText  (50),vYValue, "Dimension:"
		PopupMenu sTableDim,pos={(115),vYValue-10},mode=vDDim,bodyWidth=75,value="Meta;Library;Scalar;Vector",proc=COMBIDisplay_UpdateGlobal
		DrawText  (185),vYValue, "data"
		PopupMenu sDData,pos={(330),vYValue-10},mode=1,bodyWidth=175,value=COMBIDisplay_DataList("D"),proc=COMBIDisplay_UpdateGlobal,font=sFont
		SetVariable sDDataF, title=" ",pos={204,vYValue-9},size={163,50},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sDData][%COMBIgor]
		vYValue+=25
		
		
		button SeeData,title=" See ",appearance={native,All},pos={(25),vYValue-10},size={150,20},proc=COMBIDisplay_SeeData,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
		DrawText  (225),vYValue, "for Sample"
		PopupMenu sDSample,pos={(300),vYValue-10},mode=1,bodyWidth=75,value="All;"+COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),0),proc=COMBIDisplay_UpdateGlobal
		
	elseif(iActiveTab==2)//Mapping Tab
		
		//Project Row
		DrawText 80,vYValue, "COMBIgor project:"
		PopupMenu sProject,pos={280,vYValue-8},mode=(WhichListItem(sProject, COMBI_Projects())+1),bodyWidth=185,value=COMBI_Projects(),proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//MappingGrid Row
		DrawText 80,vYValue, "MappingGrid Type:"
		int iMapType = WhichListItem(COMBIDisplay_GetString("sMapType","COMBIgor"),COMBIDisplay_DataList("MOp"))+1
		PopupMenu sMapType,pos={280,vYValue-8},mode=iMapType,bodyWidth=185,value=COMBIDisplay_DataList("MOp"),proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//Type Row
		DrawText 111,vYValue, "Fitting:"
		int iFitOption = WhichListItem(COMBIDisplay_GetString("sMFitOption","COMBIgor"),"None;PolyFit;PlaneFit")+1
		PopupMenu sMFitOption,pos={280,vYValue-8},mode=iFitOption,bodyWidth=185,value="None;PolyFit;PlaneFit",proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//plotting mode
		DrawText 101,vYValue, "Plot Type:"
		int iMStyle = WhichListItem(COMBIDisplay_GetString("sMStyle","COMBIgor"),"Markers;Contours(5);Both(5);Contours(10);Both(10);Contours(20);Both(20);Contours(50);Both(50)")+1
		PopupMenu sMStyle,pos={280,vYValue-8},mode=iMStyle,bodyWidth=185,value="Markers;Contours(5);Both(5);Contours(10);Both(10);Contours(20);Both(20);Contours(50);Both(50)",proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//Library 
		DrawText  (110),vYValue, "Library:"
		int iMLibrarySee = WhichListItem(COMBIDisplay_GetString("sMLibrarySee","COMBIgor"),COMBIDisplay_LibraryList("M"))+1
		PopupMenu sMLibrarySee,pos={280,vYValue-8},mode=iMLibrarySee,bodyWidth=185,value=COMBIDisplay_LibraryList("M"),proc=COMBIDisplay_UpdateGlobal
		vYValue+=25
		DrawLine 10,vYValue-10,340,vYValue-10
		
		//Color data
		DrawText  (100),vYValue, "Color Data:"
		int iMCData = WhichListItem(COMBIDisplay_GetString("sMCData","COMBIgor"),COMBIDisplay_DataList("M"))+1
		PopupMenu sMCData,pos={(280),vYValue-8},mode=iMCData,bodyWidth=185,value=COMBIDisplay_DataList("M"),proc=COMBIDisplay_UpdateGlobal,font=sFont
		vYValue+=20
		
		//Coloring Type
		DrawText  (96),vYValue, "Color Theme:"
		int iMCColor = WhichListItem(COMBIDisplay_GetString("sMCColor","COMBIgor"),CTabList())+1
		PopupMenu sMCColor,pos={(280),vYValue-8},mode=iMCColor,bodyWidth=185,mode=iMCColor,bodyWidth=150,value=CTabList(),proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//Coloring scale
		DrawText  (98),vYValue, "Color Scale:"
		int iMCScale = WhichListItem(COMBIDisplay_GetString("sMCScale","COMBIgor"),"Linear;Log")+1
		PopupMenu sMCScale,pos={(280),vYValue-8},mode=iMCScale,bodyWidth=185,mode=vCScale,value="Linear;Log",proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//color range
		DrawText  (98),vYValue, "Color Range:"
		SetVariable sMCMin, title=" ",pos={150,vYValue-7},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sMCMin][%COMBIgor]
		DrawText 235,vYValue, "-"
		SetVariable sMCMax, title=" ",pos={250,vYValue-7},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sMCMax][%COMBIgor]
		vYValue+=25
		
		DrawLine 10,vYValue-10,340,vYValue-10
		
		//Size data
		DrawText  (105),vYValue, "Size Data:"
		int iMSData = WhichListItem(COMBIDisplay_GetString("sMSData","COMBIgor"),COMBIDisplay_DataList("M"))+1
		PopupMenu sMSData,pos={(280),vYValue-8},mode=iMSData,bodyWidth=185,value=COMBIDisplay_DataList("M"),proc=COMBIDisplay_UpdateGlobal,font=sFont
		vYValue+=20
		
		//Marker Type
		//DrawText 845,vYValue-2, "Markers:            \\Z18\W50"+num2str(vMarker)+"\W50"+num2str(vMarker)
		//PopupMenu sMarker,pos={(790),vYValue-10},bodyWidth=25,value="*MARKERPOP*",proc=COMBIDisplay_UpdateGlobal
		
		DrawText  (178),vYValue, "Marker Type: \\Z18\W50"+num2str(vMMarker)+"\W50"+num2str(vMMarker)+"\W50"+num2str(vMMarker)+"\W50"+num2str(vMMarker)
		PopupMenu sMMarker,pos={(280),vYValue-8},bodyWidth=25,value="*MARKERPOP*",proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//Size scale
		DrawText  (100),vYValue, "Size Scale:"
		int iMSScale = WhichListItem(COMBIDisplay_GetString("sMSScale","COMBIgor"),"Linear;-Linear")+1
		PopupMenu sMSScale,pos={(280),vYValue-8},mode=iMSScale,bodyWidth=185,mode=vSScale,value="Linear;-Linear",proc=COMBIDisplay_UpdateGlobal
		vYValue+=20
		
		//size range
		DrawText  (98),vYValue, " Size Range:"
		SetVariable sMSMin, title=" ",pos={150,vYValue-7},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sMSMin][%COMBIgor]
		DrawText 235,vYValue, "-"
		SetVariable sMSMax, title=" ",pos={250,vYValue-7},size={70,18},fsize=12,live=1,noproc,font=sFont,value=twGlobals[%sMSMax][%COMBIgor]
		vYValue+=18
	
		DrawLine 10,vYValue-2,340,vYValue-2
		//statsitic options
		DrawText  (115),vYValue+7, " Stats:"
		CheckBox bMRange,pos={150,vYValue},size={100,20},title="Range",value=COMBIDisplay_GetNumber("bMRange","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		CheckBox bMDeviation,pos={250,vYValue},size={100,20},title="StdDev",value=COMBIDisplay_GetNumber("bMDeviation","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		vYValue+=20
		CheckBox bMMin,pos={150,vYValue},size={100,20},title="Min",value=COMBIDisplay_GetNumber("bMMin","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		CheckBox bMMax,pos={250,vYValue},size={100,20},title="Max",value=COMBIDisplay_GetNumber("bMMax","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		vYValue+=0
		CheckBox bMSaveStats,pos={20,vYValue},size={100,20},title="Save Stats\ras Library Data",value=COMBIDisplay_GetNumber("bMSaveStats","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		vYValue+=20
		CheckBox bMMean,pos={150,vYValue},size={100,20},title="Mean",value=COMBIDisplay_GetNumber("bMMean","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		CheckBox bMMedian,pos={250,vYValue},size={100,20},title="Median",value=COMBIDisplay_GetNumber("bMMedian","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12
		
		vYValue+=18
		DrawLine 10,vYValue,340,vYValue
		
		//See data
		vYValue+=17
		button MakeMap,title="Make Library Map",appearance={native,All},pos={(30),vYValue-10},size={200,30},proc=COMBIDisplay_DoMap,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
		CheckBox bMNumbers,pos={250,vYValue-2},size={100,20},title="Show Data",value=COMBIDisplay_GetNumber("bMNumbers","COMBIgor"),proc=COMBI_UpdateGlobalBool,fSize=12


	endif
	
	

	
	

end

Function COMBIDisplay_ReloadPanel(ctrlName) : ButtonControl
	String ctrlName
	COMBIDisplay()
End

Function COMBIDisplay_ResetPanel(ctrlName) : ButtonControl
	String ctrlName
	COMBIDisplay_Global("vHMin","Auto","COMBIgor")
	COMBIDisplay_Global("vHMax","Auto","COMBIgor")
	COMBIDisplay_Global("vVMin","Auto","COMBIgor")
	COMBIDisplay_Global("vVMax","Auto","COMBIgor")
	COMBIDisplay_Global("vCMin","Auto","COMBIgor")
	COMBIDisplay_Global("vCMax","Auto","COMBIgor")
	COMBIDisplay_Global("vSMin","Auto","COMBIgor")
	COMBIDisplay_Global("vSMax","Auto","COMBIgor")
	COMBIDisplay_Global("vSampleMin","All","COMBIgor")
	COMBIDisplay_Global("vSampleMax","All","COMBIgor")
	COMBIDisplay_Global("vGA1Min","All","COMBIgor")
	COMBIDisplay_Global("vGA1Max","All","COMBIgor")
	COMBIDisplay_Global("vGA2Min","All","COMBIgor")
	COMBIDisplay_Global("vGA2Max","All","COMBIgor")
	COMBIDisplay_Global("sHData","","COMBIgor")
	COMBIDisplay_Global("sVData","","COMBIgor")
	COMBIDisplay_Global("sCData","","COMBIgor")
	COMBIDisplay_Global("sSData","","COMBIgor")
	COMBIDisplay_Global("sHError","","COMBIgor")
	COMBIDisplay_Global("sVError","","COMBIgor")
	COMBIDisplay_Global("sLibraryH","","COMBIgor")
	COMBIDisplay_Global("sLibraryV","","COMBIgor")
	COMBIDisplay_Global("sLibraryC","","COMBIgor")
	COMBIDisplay_Global("sLibraryS","","COMBIgor")
	COMBIDisplay()
End

Function COMBIDisplay_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	COMBIDisplay_Global(ctrlName,popStr,"COMBIgor")
	
	if(stringmatch("sProject",ctrlName))
		COMBI_GiveGlobal("sActiveFolder",popStr,"COMBIgor")
	endif
	
	string sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	
	string sLibraryH = COMBIDisplay_GetString("sLibraryH","COMBIgor")
	string sLibraryV = COMBIDisplay_GetString("sLibraryV","COMBIgor")
	string sLibraryC = COMBIDisplay_GetString("sLibraryC","COMBIgor")
	string sLibraryS = COMBIDisplay_GetString("sLibraryS","COMBIgor")
	
	string sHData = COMBIDisplay_GetString("sHData","COMBIgor")
	string sHError = COMBIDisplay_GetString("sHError","COMBIgor")
	string sVData = COMBIDisplay_GetString("sVData","COMBIgor")
	string sVError = COMBIDisplay_GetString("sVError","COMBIgor")
	string sCData = COMBIDisplay_GetString("sCData","COMBIgor")
	string sSData = COMBIDisplay_GetString("sSData","COMBIgor")
	
	variable vHDim = COMBIDisplay_GetNumber("vHDim","COMBIgor")
	variable vVDim = COMBIDisplay_GetNumber("vVDim","COMBIgor")
	variable vCDim = COMBIDisplay_GetNumber("vCDim","COMBIgor")
	variable vSDim = COMBIDisplay_GetNumber("vSDim","COMBIgor")
	

	//Combi_CheckForDataType(sProject,sLibraryH,sHError,vHDim)
	
	if(stringmatch("sHDim",ctrlName))
		COMBIDisplay_Global("vHDim",num2str(WhichlistItem(popStr,"Library;Scalar;Vector")),"COMBIgor")
		if(itemsInList(Combi_TableList(sProject,vHDim,sLibraryH,"DataTypes"))==0)
			COMBIDisplay_Global("sLibraryH","","COMBIgor")
		endif
		COMBIDisplay_Global("sHData","","COMBIgor")
		COMBIDisplay_Global("sHError","","COMBIgor") 
	elseif(stringmatch("sVDim",ctrlName))
		COMBIDisplay_Global("vVDim",num2str(WhichlistItem(popStr,"Library;Scalar;Vector")),"COMBIgor")
		if(itemsInList(Combi_TableList(sProject,vVDim,sLibraryV,"DataTypes"))==0)
			COMBIDisplay_Global("sLibraryV","","COMBIgor")
		endif
		COMBIDisplay_Global("sVData","","COMBIgor")
		COMBIDisplay_Global("sVError","","COMBIgor")
	elseif(stringmatch("sCDim",ctrlName))
		COMBIDisplay_Global("vCDim",num2str(WhichlistItem(popStr,"Library;Scalar;Vector")),"COMBIgor")
		if(itemsInList(Combi_TableList(sProject,vCDim,sLibraryC,"DataTypes"))==0)
			COMBIDisplay_Global("sLibraryC","","COMBIgor")
		endif
		COMBIDisplay_Global("sCData","","COMBIgor")
	elseif(stringmatch("sSDim",ctrlName))
		COMBIDisplay_Global("vSDim",num2str(WhichlistItem(popStr,"Library;Scalar;Vector")),"COMBIgor")
		if(itemsInList(Combi_TableList(sProject,vSDim,sLibraryS,"DataTypes"))==0)
			COMBIDisplay_Global("sLibraryS","","COMBIgor")
		endif
		COMBIDisplay_Global("sSData","","COMBIgor") 
	elseif(stringmatch(ctrlName,"sLibrary*"))
		if(COMBIDisplay_GetNumber("bLibraryLock","COMBIgor")==1)
			if(strlen(COMBIDisplay_GetString("sHDim","COMBIgor"))>0)
				COMBIDisplay_Global("sLibraryH",popStr,"COMBIgor")
			endif
			if(strlen(COMBIDisplay_GetString("sVDim","COMBIgor"))>0)
				COMBIDisplay_Global("sLibraryV",popStr,"COMBIgor")
			endif
			if(strlen(COMBIDisplay_GetString("sCDim","COMBIgor"))>0)
				COMBIDisplay_Global("sLibraryC",popStr,"COMBIgor")
			endif
			if(strlen(COMBIDisplay_GetString("sSDim","COMBIgor"))>0)
				COMBIDisplay_Global("sLibraryS",popStr,"COMBIgor")
			endif
		endif
	elseif(stringmatch("sLibraryH",ctrlName))
		if(Combi_CheckForDataType(sProject,sLibraryH,sHData,vHDim)==0)
			COMBIDisplay_Global("sHData","","COMBIgor")
		endif
		if(Combi_CheckForDataType(sProject,sLibraryH,sHError,vHDim)==0)
			COMBIDisplay_Global("sHError","","COMBIgor")
		endif
	elseif(stringmatch("sLibraryV",ctrlName))
		if(Combi_CheckForDataType(sProject,sLibraryV,sVData,vVDim)==0)
			COMBIDisplay_Global("sVData","","COMBIgor")
		endif
		if(Combi_CheckForDataType(sProject,sLibraryV,sVError,vVDim)==0)
			COMBIDisplay_Global("sVError","","COMBIgor")
		endif
	elseif(stringmatch("sLibraryC",ctrlName))
		if(Combi_CheckForDataType(sProject,sLibraryC,sCData,vCDim)==0)
			COMBIDisplay_Global("sCData","","COMBIgor")
		endif
	elseif(stringmatch("sLibraryS",ctrlName))
		if(Combi_CheckForDataType(sProject,sLibraryS,sSData,vSDim)==0)
			COMBIDisplay_Global("sSData","","COMBIgor")
		endif
	elseif(stringmatch("sTableDim",ctrlName))
		COMBIDisplay_Global("vDDim",num2str(WhichlistItem(popStr,"Meta;Library;Scalar;Vector")-1),"COMBIgor")
		COMBIDisplay_Global("sLibrarySee","","COMBIgor")
		COMBIDisplay_Global("sDData","","COMBIgor") 
	elseif(stringmatch("sMode",ctrlName))
		COMBIDisplay_Global("vMode",num2str(WhichlistItem(popStr,"Lines between points;Sticks to zero;Dots at Samples;Markers;Lines and markers;Histogram bars;Cityscape;Fill to zero;Sticks and markers")),"COMBIgor")
	elseif(stringmatch("sMarker",ctrlName))
		COMBIDisplay_Global("vMarker",num2str(PopNum-1),"COMBIgor")
	elseif(stringmatch("sMMarker",ctrlName))
		COMBIDisplay_Global("vMMarker",num2str(PopNum-1),"COMBIgor")
	endif
		
	COMBIDisplay()
End

//function to return drop downs of data types for panel
function/S COMBIDisplay_DataList(sAxis)
	string sAxis //H,V,C,  S, D, M
	variable vDim
	string sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	string sLibrary = COMBIDisplay_GetString("sLibrary"+sAxis,"COMBIgor")
	string sDataTypeFilter = COMBIDisplay_GetString("sDataTypeFilter","COMBIgor")
	
	if(strlen(sProject)==0||stringmatch(sProject," "))
		return ""
	endif
	if(stringmatch(sAxis,"M"))
		vDim = 1
		 sLibrary = COMBIDisplay_GetString("sMLibrarySee","COMBIgor")
	else
		vDim = COMBIDisplay_GetNumber("v"+sAxis+"Dim","COMBIgor")
	endif
	
	if(stringmatch(sAxis,"MOp"))
		wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
		string sTempGA1 = getdimlabel(wMappingGrid,1,3)
		string sTempGA2 = getdimlabel(wMappingGrid,1,4)
		return "y(mm) vs x(mm);"+sTempGA2+" vs "+sTempGA1
	endif
	
	if(vDim==-1)//axis type set to none
		return " ;"
	endif
	
	if(stringmatch(sProject,""))// no project set
		return " ;"
	endif
	if(strlen(sDataTypeFilter)==0||stringmatch(sDataTypeFilter," "))
		sDataTypeFilter = "*"
	else
		sDataTypeFilter = "*"+sDataTypeFilter+"*"
	endif
	return " ;"+ListMatch(COMBI_TableList(sProject,vDim,sLibrary,"DataTypes", bRecursive=1), sDataTypeFilter)
end

//function to return drop downs of Librarys for panel
function/S COMBIDisplay_LibraryList(sAxisTag)
	string sAxisTag
	string sLibraryFilter = COMBIDisplay_GetString("sLibraryFilter","COMBIgor")
		
	int iDim
	if(stringmatch(sAxisTag,"M"))
		iDim = 1
	else
		iDim = COMBIDisplay_GetNumber("v"+sAxisTag+"Dim","COMBIgor")
	endif
	string sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	if(iDim<=2)
		//apply filter
		if(strlen(sLibraryFilter)==0||stringmatch(sLibraryFilter," "))
			sLibraryFilter = "*"
		else
			sLibraryFilter = "*"+sLibraryFilter+"*"
		endif
		return ListMatch(COMBI_TableList(sProject,iDim,"All","Libraries"), sLibraryFilter) 
	else 
		return " "
	endif
	
end

Function COMBIDisplay_DoPlot(ctrlName) : ButtonControl
	String ctrlName
	
	//get values from globals table
	String sHMin = COMBIDisplay_GetString("vHMin","COMBIgor")
	String sHMax = COMBIDisplay_GetString("vHMax","COMBIgor")
	String sVMin = COMBIDisplay_GetString("vVMin","COMBIgor")
	String sVMax = COMBIDisplay_GetString("vVMax","COMBIgor")
	String sCMin = COMBIDisplay_GetString("vCMin","COMBIgor")
	String sCMax = COMBIDisplay_GetString("vCMax","COMBIgor")
	String sSMin = COMBIDisplay_GetString("vSMin","COMBIgor")
	String sSMax = COMBIDisplay_GetString("vSMax","COMBIgor")
	String sSampleMin = COMBIDisplay_GetString("vSampleMin","COMBIgor")
	String sSampleMax = COMBIDisplay_GetString("vSampleMax","COMBIgor")
	String sGA1Min = COMBIDisplay_GetString("vGA1Min","COMBIgor")
	String sGA1Max = COMBIDisplay_GetString("vGA1Max","COMBIgor")
	String sGA2Min = COMBIDisplay_GetString("vGA2Min","COMBIgor")
	String sGA2Max = COMBIDisplay_GetString("vGA2Max","COMBIgor")
	String sHScale = COMBIDisplay_GetString("sHScale","COMBIgor")
	String sVScale = COMBIDisplay_GetString("sVScale","COMBIgor")
	String sCScale = COMBIDisplay_GetString("sCScale","COMBIgor")
	String sSScale = COMBIDisplay_GetString("sSScale","COMBIgor")
	String sHDim = COMBIDisplay_GetString("sHDim","COMBIgor")
	String sVDim = COMBIDisplay_GetString("sVDim","COMBIgor")
	String sCDim = COMBIDisplay_GetString("sCDim","COMBIgor")
	String sSDim = COMBIDisplay_GetString("sSDim","COMBIgor")
	String sHData = COMBIDisplay_GetString("sHData","COMBIgor")
	String sVData = COMBIDisplay_GetString("sVData","COMBIgor")
	String sCData = COMBIDisplay_GetString("sCData","COMBIgor")
	String sSData = COMBIDisplay_GetString("sSData","COMBIgor")
	String sHError = COMBIDisplay_GetString("sHError","COMBIgor")
	String sVError = COMBIDisplay_GetString("sVError","COMBIgor")
	String sCColor = COMBIDisplay_GetString("sCColor","COMBIgor")
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	String sLibraryH = COMBIDisplay_GetString("sLibraryH","COMBIgor")
	String sLibraryv = COMBIDisplay_GetString("sLibraryV","COMBIgor")
	String sLibraryC = COMBIDisplay_GetString("sLibraryC","COMBIgor")
	String sLibraryS = COMBIDisplay_GetString("sLibraryS","COMBIgor")
	String sHLocation = COMBIDisplay_GetString("sHLocation","COMBIgor")
	String sVLocation = COMBIDisplay_GetString("sVLocation","COMBIgor")
	string sColorTheme = COMBIDisplay_GetString("sCColor","COMBIgor")
	variable vMode = COMBIDisplay_GetNumber("vMode","COMBIgor")
	variable vMarker = COMBIDisplay_GetNumber("vMarker","COMBIgor")
	
	if(stringmatch(COMBI_GetGlobalString("sCommandLines","COMBIgor"),"Yes"))
		Print "COMBIDisplay_Plot(\""+sProject+"\",\""+ctrlName+"\",\""+sHDim+"\",\""+sLibraryH+"\",\""+sHData+"\",\""+sHError+"\",\""+sHScale+"\",\""+sHMin+"\",\""+sHMax+"\",\""+sHLocation+"\",\""+sVDim+"\",\""+sLibraryV+"\",\""+sVData+"\",\""+sVError+"\",\""+sVScale+"\",\""+sVMin+"\",\""+sVMax+"\",\""+sVLocation+"\",\""+sCDim+"\",\""+sLibraryC+"\",\""+sCData+"\",\""+sCScale+"\",\""+sCMin+"\",\""+sCMax+"\",\""+sColorTheme+"\",\""+sSDim+"\",\""+sLibraryS+"\",\""+sSData+"\",\""+sSScale+"\",\""+sSMin+"\",\""+sSMax+"\","+num2str(vMode)+","+num2str(vMarker)+",\""+sSampleMin+"\",\""+sSampleMax+"\",\""+sGA1Min+"\",\""+sGA1Max+"\",\""+sGA2Min+"\",\""+sGA2Max+"\")"
	endif
	
	COMBIDisplay_Plot(sProject,ctrlName,sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation,sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme,sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax,vMode,vMarker,sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max)

end


Function COMBIDisplay_DoMap(ctrlName) : ButtonControl
	String ctrlName
	
	//get values from globals table
	String sMCScale = COMBIDisplay_GetString("sMCScale","COMBIgor")
	String sMSScale = COMBIDisplay_GetString("sMSScale","COMBIgor")
	String sMCData = COMBIDisplay_GetString("sMCData","COMBIgor")
	String sMSData = COMBIDisplay_GetString("sMSData","COMBIgor")
	String sMCColor = COMBIDisplay_GetString("sMCColor","COMBIgor")
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	String sMLibrarySee = COMBIDisplay_GetString("sMLibrarySee","COMBIgor")
	string sMapType = COMBIDisplay_GetString("sMapType","COMBIgor")
	string sMCMin = COMBIDisplay_GetString("sMCMin","COMBIgor")
	string sMCMax = COMBIDisplay_GetString("sMCMax","COMBIgor")
	string sMSMin = COMBIDisplay_GetString("sMSMin","COMBIgor")
	string sMSMax = COMBIDisplay_GetString("sMSMax","COMBIgor")
	string bMRange = COMBIDisplay_GetString("bMRange","COMBIgor")
	string bMDeviation = COMBIDisplay_GetString("bMDeviation","COMBIgor")
	string bMMax = COMBIDisplay_GetString("bMMax","COMBIgor")
	string bMMin = COMBIDisplay_GetString("bMMin","COMBIgor")
	string bMMean = COMBIDisplay_GetString("bMMean","COMBIgor")
	string bMMedian = COMBIDisplay_GetString("bMMedian","COMBIgor")
	variable vMMarker = COMBIDisplay_GetNumber("vMMarker","COMBIgor")
	if(strlen(sMCMin)==0)
		sMCMin = "*"
	endif
	if(strlen(sMSMin)==0)
		sMSMin = "*"
	endif
	if(strlen(sMCMax)==0)
		sMCMax = "*"
	endif
	if(strlen(sMSMax)==0)
		sMSMax = "*"
	endif
	string sRangeString = sMCMin+","+sMCMax+","+sMSMin+","+sMSMax
	string sOptionString = bMRange+bMDeviation+bMMax+bMMin+bMMean+bMMedian
	String sMStyle = COMBIDisplay_GetString("sMStyle","COMBIgor")
	String sMFitOption = COMBIDisplay_GetString("sMFitOption","COMBIgor")
	
	if(stringmatch(COMBI_GetGlobalString("sCommandLines","COMBIgor"),"Yes"))
		Print "COMBIDisplay_Map(\""+sProject+"\",\""+sMLibrarySee+"\",\""+sMCData+"\",\""+sMCScale+"\",\""+sMCColor+"\",\""+sMSData+"\",\""+sMSScale+"\",\""+sMapType+"\",\""+sMStyle+"\",\""+sMFitOption+"\",\""+sRangeString+"\","+num2str(vMMarker)+"\","+sOptionString+"\")"
	endif
	
	if(COMBIDisplay_GetNumber("bMNumbers","COMBIgor")==1)
		string sListofWaves2Show = ""
		if(stringmatch(sMFitOption,"None"))
			if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMCData))
				sListofWaves2Show += "root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMCData+".ld,"
			endif
			if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMSData))
				sListofWaves2Show += "root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMSData+".ld,"
			endif
		else
			if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMCData))
				sListofWaves2Show += "root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMCData+"_"+sMFitOption+".ld,"
			endif
			if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMSData))
				sListofWaves2Show += "root:COMBIgor:"+sProject+":Data:"+sMLibrarySee+":"+sMSData+"_"+sMFitOption+".ld,"
			endif
		endif
		Execute "Edit/K=1 "+removeending(sListofWaves2Show,",")
	endif
	
	COMBIDisplay_Map(sProject,sMLibrarySee,sMCData,sMCScale,sMCColor,sMSData,sMSScale,sMapType,sMStyle,sMFitOption,sRangeString,vMMarker,sOptionString)

end

function COMBIDisplay_Map(sProject,sLibrarySee,sMCData,sCScale,sColorTheme,sMSData,sSScale,sMapType,sMStyle,sMFitOption,sRangeString,vMarker,sOptionString)
	string sProject,sLibrarySee,sMCData,sCScale,sColorTheme,sMSData,sSScale,sMapType,sOptionString,sRangeString,sMStyle,sMFitOption
	variable vMarker
	int bSize=1, bColor=1, vRightMargin = 30, vTopMargin = 30
	string sWindowTitle = sLibrarySee+" : "

	//fits if needed, change 2 the fit data
	int bFitResults = 0
	string  sRawCData, sRawSData
	if(stringmatch(sMFitOption,"PlaneFit"))
		bFitResults = 1
		if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMCData))
			COMBI_ScalarInterpolation(sProject,sProject,sLibrarySee,sMCData,"PlaneFit",0)
			sRawCData = sMCData
			sMCData = sMCData+"_PlaneFit"
		endif
		if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMSData))
			COMBI_ScalarInterpolation(sProject,sProject,sLibrarySee,sMSData,"PlaneFit",0)
			sRawSData = sMSData
			sMSData = sMSData+"_PlaneFit"
		endif
	elseif(stringmatch(sMFitOption,"PolyFit"))
		bFitResults = 1
		if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMCData))
			COMBI_ScalarInterpolation(sProject,sProject,sLibrarySee,sMCData,"PolyFit",0)
			sRawCData = sMCData
			sMCData = sMCData+"_PolyFit"
		endif
		if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMSData))
			COMBI_ScalarInterpolation(sProject,sProject,sLibrarySee,sMSData,"PolyFit",0)
			sRawSData = sMSData
			sMSData = sMSData+"_PolyFit"
		endif
		
	endif
	
	//get waves
	variable vMinC, vMaxC, vSMin, vSMax
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMCData))
		wave wColor = $"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMCData
		sWindowTitle = sWindowTitle+sMCData
		vRightMargin += 50
		vMaxC = wavemax(wColor)
		vMinC = wavemin(wColor)
	else
		bColor=0
	endif
	if(waveexists($"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMSData))
		wave wSize = $"root:COMBIgor:"+sProject+":Data:"+sLibrarySee+":"+sMSData
		sWindowTitle = sWindowTitle+" and "+sMSData
		vTopMargin += 50
		vSMin = wavemin(wSize)
		vSMax = wavemax(wSize)
	else
		bSize=0
	endif
	
	int bMRange = str2num(sOptionString[0])
	int bMDeviation  = str2num(sOptionString[1])
	int bMMax = str2num(sOptionString[2])
	int bMMin = str2num(sOptionString[3])
	int bMMean = str2num(sOptionString[4])
	int bMMedian = str2num(sOptionString[5])
	
	//ranges
	string sMCMin = stringfromlist(0,sRangeString,",")
	string sMCMax = stringfromlist(1,sRangeString,",")
	string sMSMin = stringfromlist(2,sRangeString,",")
	string sMSMax = stringfromlist(3,sRangeString,",")
	if(!stringmatch("*",sMCMin))
		vMinC = str2num(sMCMin)
	endif
	if(!stringmatch("*",sMCMax))
		vMaxC = str2num(sMCMax)
	endif
	if(!stringmatch("*",sMSMin))
		vSMin = str2num(sMSMin)
	endif
	if(!stringmatch("*",sMSMax))
		vSMax = str2num(sMSMax)
	endif
	
	//stats
	if(bColor==1)
		variable vCMinStat = wavemin(wColor)
		variable vCMaxStat = wavemax(wColor)
		variable vCMeanStat = mean(wColor)
		variable vCMedianStat = Median(wColor)
		variable vCRangeStat = vCMaxStat - vCMinStat
		variable vCDevStat = sqrt(variance(wColor))
	endif
	if(bSize==1)
		variable vSMinStat = wavemin(wSize)
		variable vSMaxStat = wavemax(wSize)
		variable vSMeanStat = mean(wSize)
		variable vSMedianStat = Median(wSize)
		variable vSRangeStat = vSMaxStat - vSMinStat
		variable vSDevStat = sqrt(variance(wSize))
	endif
	
	//Library values
	variable vLibraryWidth = COMBI_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = COMBI_GetGlobalNumber("vLibraryHeight",sProject)
	variable vTotalRows = COMBI_GetGlobalNumber("vTotalRows",sProject)
	variable vTotalColumns = COMBI_GetGlobalNumber("vTotalColumns",sProject)
	variable vColumnSpacing = COMBI_GetGlobalNumber("vColumnSpacing",sProject)
	variable vRowSpacing = COMBI_GetGlobalNumber("vRowSpacing",sProject)
	int bXAxisFlip = COMBI_GetGlobalNumber("bXAxisFlip",sProject)
	int bYAxisFlip = COMBI_GetGlobalNumber("bYAxisFlip",sProject)
	string sOrigin = COMBI_GetGlobalString("sOrigin",sProject)
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")

	string sHData, sVData
	if(stringmatch(sMapType,"y(mm) vs x(mm)"))//format as a mm map
		sHData = getdimLabel(wMappingGrid,1,1)
		sVData = getdimLabel(wMappingGrid,1,2)
	else// mapping grid map
		sHData = getdimLabel(wMappingGrid,1,4)
		sVData = getdimLabel(wMappingGrid,1,3)
	endif
	wave wHWave = $COMBI_DataPath(sProject,1)+"FromMappingGrid:"+sHData
	wave wVWave = $COMBI_DataPath(sProject,1)+"FromMappingGrid:"+sVData
	
	// options
	variable vMaxH,vMinH,vMaxV,vMinV, vHDelta, vVDelta
	string sHAxis, sVAxis 
	int vTicksH
	int vTicksV
	if(stringmatch(sMapType,"y(mm) vs x(mm)"))//format as a mm map
		vMaxH = vLibraryWidth
		vMinH = 0
		vMaxV = vLibraryHeight
		vMinV = 0
		sHAxis = "x (mm)"
		sVAxis = "y (mm)"
		vTicksH = floor(vLibraryWidth/5)
		vTicksV = floor(vLibraryHeight/5)
	else //formatSQ
		vVDelta = wavemax(wVWave)-wavemin(wVWave)
		vHDelta = wavemax(wHWave)-wavemin(wHWave)
		vMaxH = wavemax(wHWave)+.1*vHDelta
		vMinH = wavemin(wHWave)-.1*vHDelta
		vMaxV = wavemax(wVWave)+.1*vVDelta
		vMinV = wavemin(wVWave)-.1*vVDelta
		sHAxis =sHData
		sVAxis =sVData
		vTicksH = itemsinlist(COMBI_LibraryQualifiers(sProject,4))
		vTicksV = itemsinlist(COMBI_LibraryQualifiers(sProject,3))
	endif
	int iBold
	
	if(stringmatch(COMBI_GetGlobalString("sBoldOption","COMBIgor"),"No"))
		iBold=0
	else
		iBold=1
	endif
	
	//make plot
	string sWindowName = cleanupName(sLibrarySee+"_"+sMCData+"_"+sMSData+"_Map",0)
	killwindow/Z $sWindowName
	sWindowName = COMBI_NewPlot(sWindowName)
	DoWindow/T $sWindowName,sWindowTitle
	
	//map type
	string sMarkerTrace,slevellist = num2str(vMinC)
	int iLevel
	variable vThisLevel
	int bMarkers = 0
	variable vContours = 0
	if(stringmatch(sMStyle,"Contours*"))
		vContours = str2num(replaceString(")",replaceString("Contours(",sMStyle,""),""))
	elseif(stringmatch(sMStyle,"Both*"))
		vContours = str2num(replaceString(")",replaceString("Both(",sMStyle,""),""))
	endif
	if((bColor==1)&&(stringmatch(sMStyle,"Contours*")||stringmatch(sMStyle,"Both*")))//contours
		AppendXYZContour/W=$sWindowName wColor vs {wHWave,wVWave}
		ModifyContour/W=$sWindowName $sMCData ctabLines={vMinC,vMaxC,$sColorTheme,0}
		if(stringmatch(sMStyle,"Both*"))
			sMarkerTrace = "'"+sMCData+"=xymarkers'"
			ModifyContour/W=$sWindowName $sMCData xymarkers=1,labels=0
			ModifyContour/W=$sWindowName $sMCData labelBkg=1,labelHV=3
			bMarkers = 1
		endif
		if(stringmatch(sCScale,"Linear"))
			ModifyContour/W=$sWindowName $sMCData manLevels={vMinC,(vMaxC-vMinC)/(vContours+1),vContours+1}
		elseif(stringmatch(sCScale,"Log"))
			ModifyContour/W=$sWindowName $sMCData autoLevels={vMinC,vMaxC,0}
			for(iLevel=0;iLevel<vContours;iLevel+=1)
				slevellist += ","+num2str(vMinC+10^((iLevel+1)/(vContours+2)*log((vMaxC-vMinC))))
			endfor
			Execute "ModifyContour "+sMCData+" moreLevels=0,moreLevels={"+slevellist+"}"
		endif	
	else
		AppendToGraph/W=$sWindowName wVWave[]/TN=$sCScale vs wHWave[]
		sMarkerTrace = sCScale
		bMarkers = 1
	endif
	
	if(bMarkers==1)//format markers for "Markers" or "Both(#)"
		ModifyGraph/W=$sWindowName mode($sMarkerTrace)=3,marker($sMarkerTrace)=vMarker
		ModifyGraph/W=$sWindowName msize=5
	endif
	
	int vLeftResultsBump = 0, iResultsY = 5
	variable vStatScaling = 1
	string sWaveNote,vK0,vK1,vK2,vK3,vK4,vK5
	if(bFitResults==1)//show fit results from not "Raw Data" for type.
		vLeftResultsBump = 150
		vStatScaling = .75
		if(bColor==1)
			sWaveNote = note(wColor)
			vK0 = stringfromList(1,sWaveNote,"\r")
			vK1 = stringfromList(2,sWaveNote,"\r")
			vK2 = stringfromList(3,sWaveNote,"\r")
			vK3 = stringfromList(4,sWaveNote,"\r")
			vK4 = stringfromList(5,sWaveNote,"\r")
			vK5 = stringfromList(6,sWaveNote,"\r")
			TextBox/C/N=ColorFitResults/A=LT/F=0/X=2.00/Y=(iResultsY)/E=2 "\\K(65535,0,0)"+sRawCData+"\rpoly2D(x,y) fit:\K(0,0,0)\r"+vK0+"\r"+vK1+"\r"+vK2+"\r"+vK3+"\r"+vK4+"\r"+vK5
			iResultsY+=40
		endif
		if(bSize==1)
			sWaveNote = note(wSize)
			vK0 = stringfromList(1,sWaveNote,"\r")
			vK1 = stringfromList(2,sWaveNote,"\r")
			vK2 = stringfromList(3,sWaveNote,"\r")
			vK3 = stringfromList(4,sWaveNote,"\r")
			vK4 = stringfromList(5,sWaveNote,"\r")
			vK5 = stringfromList(6,sWaveNote,"\r")
			TextBox/C/N=SizeFitResults/A=LT/F=0/X=2.00/Y=(iResultsY)/E=2 "\\K(65535,0,0)"+sRawSData+"\rpoly2D(x,y) fit:\K(0,0,0)\r"+vK0+"\r"+vK1+"\r"+vK2+"\r"+vK3+"\r"+vK4+"\r"+vK5
		endif
	endif
	
	if(bColor==1)
		if(bMarkers==1)
			ModifyGraph/W=$sWindowName zColor($sMarkerTrace)={wColor,vMinC,vMaxC,$sColorTheme,0}
			ColorScale/C/N=text0/F=0/A=RC/X=-37.00/Y=0.00 width=10,heightPct=100,tickLen=0.00,tickThick=0.00,trace=$sMarkerTrace
		else
			ColorScale/C/N=text0/F=0/A=RC/X=-37.00/Y=0.00 width=10,heightPct=100,tickLen=0.00,tickThick=0.00,ctab={vMinC,vMaxC,$sColorTheme,0}
		endif
		ColorScale/C/N=text0 COMBIDisplay_GetAxisLabel(sMCData)
		if(stringmatch(sCScale,"Log"))
			ColorScale/C/N=text0 log=1,minor=1,logLTrip=0.1
			ModifyGraph/W=$sWindowName logZColor=1
		else
			ModifyGraph/W=$sWindowName logZColor=0
		endif
		ColorScale/C/N=text0 font=sFont,fsize=12,fstyle=iBold
		ColorScale/C/N=text0 nticks=10
	endif
	
	if(bSize==1&&bMarkers==1)
		string sDrawNum1, sDrawNum2, sDrawNum3, sDrawNum4, sDrawNum5
		variable vSMinS,vSMaxS
		if(stringmatch(sSScale,"Linear"))
			sDrawNum1 = num2str(vSMin)
			sDrawNum3 = num2str((vSMax+vSMin)/2)
			sDrawNum5 = num2str(vSMax)
			vSMinS = vSMin
			vSMaxS = vSMax
		elseif(stringmatch(sSScale,"Log"))
			sDrawNum1 = num2str(vSMin)
			sDrawNum3 = num2str(10^((Log(vSMax)+Log(vSMin))/2))
			sDrawNum5 = num2str(vSMax)
			vSMinS = vSMin
			vSMaxS = vSMax	
		elseif(stringmatch(sSScale,"-Linear"))
			sDrawNum1 = num2str(vSMax)
			sDrawNum3 = num2str((vSMax+vSMin)/2)
			sDrawNum5 = num2str(vSMin)
			vSMinS = vSMax
			vSMaxS = vSMin
		elseif(stringmatch(sSScale,"-Log"))
			sDrawNum1 = num2str(vSMax)
			sDrawNum3 = num2str(10^((Log(vSMax)+Log(vSMin))/2))
			sDrawNum5 = num2str(vSMin)
			vSMinS = vSMax
			vSMaxS = vSMin
		endif
		ModifyGraph/W=$sWindowName zmrkSize($sMarkerTrace)={wSize,vSMinS,vSMaxS,3,10}
		SetDrawEnv gstart, gname=SizeScale 
		SetDrawEnv xcoord= abs,ycoord= abs ,save
		SetDrawEnv linethick= 0.50, save
		DrawLine 60+vLeftResultsBump,50,250+vLeftResultsBump,50
		SetDrawEnv textrgb= (65535,65535,65535), save
		DrawText 205+vLeftResultsBump,60,"\K(65535,65535,65535)\\Z40\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 165+vLeftResultsBump,58.5,"\K(65535,65535,65535)\\Z32\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 125+vLeftResultsBump,57.5,"\K(65535,65535,65535)\\Z25\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 85+vLeftResultsBump,55,"\K(65535,65535,65535)\\Z17\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 50+vLeftResultsBump,53,"\K(65535,65535,65535)\\Z10\\k(0,0,0)\\W50"+num2str(vMarker)
		SetDrawEnv textrgb= (0,0,0),fname=sFont, save
		SetDrawEnv textxjust= 1,fsize=12, save
		SetDrawEnv fstyle= iBold, save
		DrawText 60+vLeftResultsBump,40, sDrawNum1
		DrawText 150+vLeftResultsBump,40, sDrawNum3
		DrawText 240+vLeftResultsBump,40, sDrawNum5
		DrawText 150+vLeftResultsBump,20, COMBIDisplay_GetAxisLabel(sMSData)
		SetDrawEnv gstop, gname=SizeScale 
	endif

	if(bYAxisFlip==1)
		SetAxis left vMaxV,vMinV
	else
		SetAxis left vMinV,vMaxV
	endif
	if(bXAxisFlip==1)
		SetAxis bottom vMaxH,vMinH
	else
		SetAxis bottom vMinH,vMaxH
	endif
	
	ModifyGraph/W=$sWindowName mirror=2
	Label left sVAxis
	Label bottom sHAxis
	ModifyGraph/W=$sWindowName lblMargin(left)=(vLeftResultsBump+5),lblMargin(bottom)=5,lblLatPos=0
	ModifyGraph/W=$sWindowName nticks(left)=vTicksV,nticks(bottom)=vTicksH
	ModifyGraph/W=$sWindowName fStyle=iBold
	ModifyGraph/W=$sWindowName tick=3,fsize=12,font=sFont
	ModifyGraph/W=$sWindowName margin(left)=(vLeftResultsBump+50),margin(bottom)=50,margin(right)=vRightMargin,margin(top)=vTopMargin,width=200,height=200
	
	variable vH2WRatio = vLibraryHeight/vLibraryWidth 
	ModifyGraph height={Aspect,vH2WRatio}
	
	TextBox/C/N=LibraryTag/F=0/A=RB/X=2.00/Y=2.00/E "\\K(65535,0,0)"+sLibrarySee


	//stats
	int vYTrack = 10
	int iSShift = 0
	if(bMRange||bMDeviation||bMMax||bMMin||bMMean||bMMedian)
		if(bColor==1&&bSize==1)
			ModifyGraph margin(right)=280
			iSShift=20
		elseif(bColor==1)
			ModifyGraph margin(right)=180
		elseif(bSize==1)
			ModifyGraph margin(right)=180
		endif
		if(bColor==1)
			TextBox/C/N=CNameTag/F=0/X=2/Y=(5)/E=2 "\\K(0,0,0)"+sMCData
		endif
		if(bSize==1)
			TextBox/C/N=SNameTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(5)/E=2 "\\K(0,0,0)"+sMSData
		endif
		if(bMMin)
			if(bColor==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vCMinStat,sProject,sLibrarySee,sMCData+"_Min")
				endif
				TextBox/C/N=CMinTag/F=0/X=2/Y=(vYTrack)/E=2 "\\K(65535,0,0)Min:"
				TextBox/C/N=CMin/F=0/X=2/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vCMinStat)
			endif
			if(bSize==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vSMinStat,sProject,sLibrarySee,sMSData+"_Min")
				endif
				TextBox/C/N=SMinTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack)/E=2 "\\K(65535,0,0)Min:"
				TextBox/C/N=SMin/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vSMinStat)
			endif
			vYTrack+=10
		endif
		
		if(bMMax)
			if(bColor==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vCMaxStat,sProject,sLibrarySee,sMCData+"_Max")
				endif
				TextBox/C/N=CMaxTag/F=0/X=2/Y=(vYTrack)/E=2 "\\K(65535,0,0)Max:"
				TextBox/C/N=CMax/F=0/X=2/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vCMaxStat)
			endif
			if(bSize==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vSMaxStat,sProject,sLibrarySee,sMSData+"_Max")
				endif
				TextBox/C/N=SMaxTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack)/E=2 "\\K(65535,0,0)Max:"
				TextBox/C/N=SMax/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vSMaxStat)
			endif
			vYTrack+=10
		endif
		
		if(bMRange)
			if(bColor==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vCRangeStat,sProject,sLibrarySee,sMCData+"_Range")
				endif
				TextBox/C/N=CRangeTag/F=0/X=2/Y=(vYTrack)/E=2 "\\K(65535,0,0)Range:"
				TextBox/C/N=CRange/F=0/X=2/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vCRangeStat)
			endif
			if(bSize==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vSRangeStat,sProject,sLibrarySee,sMSData+"_Range")
				endif
				TextBox/C/N=SRangeTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack)/E=2 "\\K(65535,0,0)Range:"
				TextBox/C/N=SRange/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vSRangeStat)
			endif
			vYTrack+=10
		endif
		
		if(bMMean)
			if(bColor==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vCMeanStat,sProject,sLibrarySee,sMCData+"_Mean")
				endif
				TextBox/C/N=CMeanTag/F=0/X=2/Y=(vYTrack)/E=2 "\\K(65535,0,0)Mean:"
				TextBox/C/N=CMean/F=0/X=2/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vCMeanStat)
			endif
			if(bSize==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vSMeanStat,sProject,sLibrarySee,sMSData+"_Mean")
				endif
				TextBox/C/N=SMeanTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack)/E=2 "\\K(65535,0,0)Mean:"
				TextBox/C/N=SMean/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vSMeanStat)
			endif
			vYTrack+=10
		endif
		
		if(bMMedian)
			if(bColor==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vCMedianStat,sProject,sLibrarySee,sMCData+"_Median")
				endif
				TextBox/C/N=CMedianTag/F=0/X=2/Y=(vYTrack)/E=2 "\\K(65535,0,0)Median:"
				TextBox/C/N=CMedian/F=0/X=2/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vCMedianStat)
			endif
			if(bSize==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vSMedianStat,sProject,sLibrarySee,sMSData+"_Median")
				endif
				TextBox/C/N=SMedianTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack)/E=2 "\\K(65535,0,0)Median:"
				TextBox/C/N=SMedian/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vSMedianStat)
			endif
			vYTrack+=10
		endif
		
		if(bMDeviation)
			if(bColor==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vCDevStat,sProject,sLibrarySee,sMCData+"_StdDev")
				endif
				TextBox/C/N=CDevTag/F=0/X=2/Y=(vYTrack)/E=2 "\\K(65535,0,0)StdDev:"
				TextBox/C/N=CDev/F=0/X=2/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vCDevStat)
			endif
			if(bSize==1)
				if(COMBIDisplay_GetNumber("bMSaveStats","COMBIgor")==1)
					Combi_GiveLibraryData(vSDevStat,sProject,sLibrarySee,sMSData+"_StdDev")
				endif
				TextBox/C/N=SDevTag/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack)/E=2 "\\K(65535,0,0)StdDev:"
				TextBox/C/N=SDev/F=0/X=((2+iSShift)*vStatScaling)/Y=(vYTrack+5)/E=2 "\\K(0,0,0)"+num2str(vSDevStat)
			endif
			vYTrack+=10
		endif
	endif

end

//this function looks ofr errors in the inputs for the plotting function
function COMBIDisplay_CheckPlotInputs(sProject,sAction,sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation,sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme,sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax,vMode,vMarker,sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max)
	string sProject,sAction,sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation,sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme,sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax,sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max
	variable vMode,vMarker
	string sdatatypelist
	
	string sAllLibraries = Combi_TableList(sProject,-3,"All","Libraries")
	string sAllData = Combi_TableList(sProject,-3,"All","DataTypes")
	
	//check for project
	if(strlen(sProject)==0)
		DoAlert/T="Bad Inputs for sProject",0,"No project given!"
		Return 0
	endif
	
	//check for Action
	if(whichListItem(sAction,"AppendPlot;NewPlot")==-1)
		DoAlert/T="Bad Inputs for sAction",0,"only NewPlot and AppendPlot are known actions"
		Return 0
	endif
	
	//Horizontal data : sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,
	if(whichListItem(sHDim,"Library;Scalar;Vector")==-1)
		DoAlert/T="Bad Inputs for sHDim",0,"only Library, Scalar, or Vector are known dimensions"
		Return 0
	endif
	if(whichListItem(sLibraryH,sAllLibraries)==-1)
		DoAlert/T="Bad Inputs for sLibraryH",0,sLibraryH+" isn't a known library in the "+sProject+" project."
		Return 0
	endif
	sdatatypelist = Combi_TableList(sProject,-3,sLibraryH,"DataTypes")
	if(whichListItem(sHData,sdatatypelist)<1)		
		DoAlert/T="Bad Inputs for sHData",0,sHData+" isn't a known datatype in the "+sProject+" project for library "+sLibraryH+"."
		Return 0
	endif
	if(whichListItem(sHScale,"Linear;-Linear;Log;-Log")==-1)
		DoAlert/T="Bad Inputs for sHScale",0,"Linear,-Linear,Log,-Log are the only known scale types for the horizontal axis; "+sHScale+" is not known."
		Return 0
	endif
	if(numtype(str2num(sHMin))!=0)
		if(whichListItem(sHMin,"*;Auto")==-1)
			DoAlert/T="Bad Inputs for sHMin",0,"Auto,*, or a number are needed for the horizontal min; "+sHMin+" is not a min value."
			Return 0
		endif
	endif
	if(numtype(str2num(sHMax))!=0)
		if(whichListItem(sHMax,"*;Auto")==-1)
			DoAlert/T="Bad Inputs for sHMax",0,"Auto,*, or a number are needed for the horizontal min; "+sHMax+" is not a min value."
			Return 0
		endif
	endif
	if(whichListItem(sHLocation,"Top;Bottom")==-1)
		DoAlert/T="Bad Inputs for sHLocation",0,"only Top, or Bottom are known values for horizontal axis location"
		Return 0
	endif
	
	
	//Vertical data : sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation
	if(whichListItem(sVDim,"Library;Scalar;Vector")==-1)
		DoAlert/T="Bad Inputs for sVDim",0,"only Library, Scalar, or Vector are known dimensions"
		Return 0
	endif
	if(whichListItem(sLibraryV,sAllLibraries)==-1)
		DoAlert/T="Bad Inputs for sLibraryV",0,sLibraryV+" isn't a known library in the "+sProject+" project."
		Return 0
	endif
	sdatatypelist = Combi_TableList(sProject,-3,sLibraryV,"DataTypes")
	if(whichListItem(sVData,sdatatypelist)<1)
		DoAlert/T="Bad Inputs for sVData",0,sVData+" isn't a known datatype in the "+sProject+" project for library "+sLibraryV+"."
		Return 0
	endif
	if(whichListItem(sVScale,"Linear;-Linear;Log;-Log")==-1)
		DoAlert/T="Bad Inputs for sVScale",0,"Linear,-Linear,Log,-Log are the only known scale types for the horizontal axis; "+sVScale+" is not known."
		Return 0
	endif
	if(numtype(str2num(sVMin))!=0)
		if(whichListItem(sVMin,"*;Auto")==-1)
			DoAlert/T="Bad Inputs for sVMin",0,"Auto,*, or a number are needed for the horizontal min; "+sVMin+" is not a min value."
			Return 0
		endif
	endif
	if(numtype(str2num(sVMax))!=0)
		if(whichListItem(sVMax,"*;Auto")==-1)
			DoAlert/T="Bad Inputs for sVMax",0,"Auto,*, or a number are needed for the horizontal min; "+sVMax+" is not a min value."
			Return 0
		endif
	endif
	if(whichListItem(sVLocation,"Left;Right")==-1)
		DoAlert/T="Bad Inputs for sVLocation",0,"only Top, or Bottom are known values for horizontal axis location"
		Return 0
	endif
	
	//Color data : sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme
	if(whichListItem(sCDim,"Library;Scalar;Vector;; ;")==-1)
		DoAlert/T="Bad Inputs for sCDim",0,"only Library, Scalar, or Vector are known dimensions"
		Return 0
	endif
	if(!(stringmatch(sCDim," ")||stringmatch(sCDim,"")))
		if(whichListItem(sLibraryC,sAllLibraries)==-1)
			DoAlert/T="Bad Inputs for sCDim",0,sLibraryC+" isn't a known library in the "+sProject+" project."
			Return 0
		endif
		sdatatypelist = Combi_TableList(sProject,-3,sLibraryC,"DataTypes")
		if(whichListItem(sCData,sdatatypelist)<1)
			DoAlert/T="Bad Inputs for sCData",0,sCData+" isn't a known datatype in the "+sProject+" project for library "+sLibraryC+"."
			Return 0
		endif
		
		if(whichListItem(sCScale,"Linear;-Linear;Log;-Log")==-1)
			DoAlert/T="Bad Inputs for sCScale",0,"Linear,-Linear,Log,-Log are the only known scale types for the horizontal axis; "+sCScale+" is not known."
			Return 0
		endif
		if(numtype(str2num(sCMin))!=0)
			if(whichListItem(sCMin,"*;Auto")==-1)
				DoAlert/T="Bad Inputs for sCMin",0,"Auto,*, or a number are needed for the horizontal min; "+sCMin+" is not a min value."
				Return 0
			endif
		endif
		if(numtype(str2num(sCMax))!=0)
			if(whichListItem(sCMax,"*;Auto")==-1)
				DoAlert/T="Bad Inputs for sCMax",0,"Auto,*, or a number are needed for the horizontal min; "+sCMax+" is not a min value."
				Return 0
			endif
		endif
		if(whichlistitem(sColorTheme,CTabList())==-1)
			DoAlert/T="Bad Inputs for sColorTheme",0,sColorTheme+" is a unknown color theme"
			Return 0
		endif
	endif
	
	//Size data : sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax
	if(whichListItem(sSDim,"Library;Scalar;Vector;; ;")==-1)
		DoAlert/T="Bad Inputs for sSDim",0,"only Library, Scalar, or Vector are known dimensions"
		Return 0
	endif
	if(!(stringmatch(sSDim," ")||stringmatch(sSDim,"")))
		if(whichListItem(sLibraryS,sAllLibraries)==-1)
			DoAlert/T="Bad Inputs for sLibraryS",0,sLibraryC+" isn't a known library in the "+sProject+" project."
			Return 0
		endif
		sdatatypelist = Combi_TableList(sProject,-3,sLibraryS,"DataTypes")
		if(whichListItem(sSData,sdatatypelist)<1)
			DoAlert/T="Bad Inputs for sSData",0,sSData+" isn't a known datatype in the "+sProject+" project for library "+sLibraryS+"."
			Return 0
		endif
		if(whichListItem(sSScale,"Linear;-Linear")==-1)
			DoAlert/T="Bad Inputs for sSScale",0,"Linear,-Linear are the only known scale types for the horizontal axis; "+sSScale+" is not known."
			Return 0
		endif
		if(numtype(str2num(sSMin))!=0)
			if(whichListItem(sSMin,"*;Auto")==-1)
				DoAlert/T="Bad Inputs for sSMin",0,"Auto,*, or a number are needed for the horizontal min; "+sSMin+" is not a min value."
				Return 0
			endif
		endif
		if(numtype(str2num(sSMax))!=0)
			if(whichListItem(sSMax,"*;Auto")==-1)
				DoAlert/T="Bad Inputs for sSMax",0,"Auto,*, or a number are needed for the horizontal min; "+sSMax+" is not a min value."
				Return 0
			endif
		endif
	endif
	
	//sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max
	int vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	if(str2num(sSampleMin)<1)
		DoAlert/T="Bad Inputs for sSampleMin",0,"Sample range must be 1 and "+num2str(vTotalSamples)+". You put in "+sSampleMin+" for min. Too low!"
		Return 0
	endif
	if(str2num(sSampleMin)>vTotalSamples)
		DoAlert/T="Bad Inputs for sSampleMin",0,"Sample range must be 1 and "+num2str(vTotalSamples)+". You put in "+sSampleMax+" for max. Too high!"
		Return 0
	endif
	if(str2num(sSampleMax)>vTotalSamples)
		DoAlert/T="Bad Inputs for sSampleMax",0,"Sample range must be 1 and "+num2str(vTotalSamples)+". You put in "+sSampleMax+" for max. Too high!"
		Return 0
	endif
	if(str2num(sSampleMin)<1)
		DoAlert/T="Bad Inputs for sSampleMax",0,"Sample range must be 1 and "+num2str(vTotalSamples)+". You put in "+sSampleMin+" for min. Too low!"
		Return 0
	endif
	string sAllGA1 = COMBI_LibraryQualifiers(sProject,3)+"All"
	if(whichlistItem(sGA1Min,sAllGA1)==-1)
		DoAlert/T="Bad Inputs for sGA1Min",0, "Grid Axsi 1 value must be one of the following values: "+sAllGA1
		Return 0
	endif
	if(whichlistItem(sGA1Max,sAllGA1)==-1)
		DoAlert/T="Bad Inputs for sGA1Max",0, "Grid Axsi 1 value must be one of the following values: "+sAllGA1
		Return 0
	endif
	
	string sAllGA2 = COMBI_LibraryQualifiers(sProject,4)+"All"
	if(whichlistItem(sGA2Min,sAllGA2)==-1)
		DoAlert/T="Bad Inputs for sGA2Min",0,"Grid Axsi 2 value must be one of the following values: "+sAllGA2
		Return 0
	endif
	if(whichlistItem(sGA2Max,sAllGA2)==-1)
		DoAlert/T="Bad Inputs for sGA2Max",0,"Grid Axsi 2 value must be one of the following values: "+sAllGA2
		Return 0
	endif
	
	//All good!
	Return 1
end

functionInfo(

function COMBIDisplay_Plot(sProject,sAction,sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation,sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme,sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax,vMode,vMarker,sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max)
	string sProject,sAction,sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation,sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme,sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax,sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max
	variable vMode,vMarker
	int bgoodinputs = COMBIDisplay_CheckPlotInputs(sProject,sAction,sHDim,sLibraryH,sHData,sHError,sHScale,sHMin,sHMax,sHLocation,sVDim,sLibraryV,sVData,sVError,sVScale,sVMin,sVMax,sVLocation,sCDim,sLibraryC,sCData,sCScale,sCMin,sCMax,sColorTheme,sSDim,sLibraryS,sSData,sSScale,sSMin,sSMax,vMode,vMarker,sSampleMin,sSampleMax,sGA1Min,sGA1Max,sGA2Min,sGA2Max)
	if(bgoodinputs == 0)
		return -1
	endif
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//get axis waves
	string sHAxisWave, sVAxisWave, sCAxisWave, sSAxisWave, sHErWave="", sVErWave=""
	int iHDim, iVdim, iCdim=-1, iSDim=-1
	int iHVecLength, iVVecLength, iCVecLength, iSVecLength
		
	if(stringmatch(sHDim,"Library"))
		sHAxisWave = COMBI_DataPath(sProject,0);iHDim=0;iHVecLength = 1;wave/Z wHAxis = $sHAxisWave
	elseif(stringmatch(sHDim,"Scalar"))
		sHAxisWave = COMBI_DataPath(sProject,1)+sLibraryH+":"+sHData;iHDim=1;iHVecLength = 1;wave/Z wHAxis = $sHAxisWave
		if(strlen(sHError)>0)
			sHErWave = COMBI_DataPath(sProject,1)+sLibraryH+":"+sHError
			wave/Z wHErWave = $sHErWave
		endif
	elseif(stringmatch(sHDim,"Vector"))
	 	sHAxisWave = COMBI_DataPath(sProject,2)+sLibraryH+":"+sHData;iHDim=2;iHVecLength = dimsize($sHAxisWave,1);wave/Z wHAxis = $sHAxisWave
	 	if(strlen(sHError)>0)
			sHErWave = COMBI_DataPath(sProject,2)+sLibraryH+":"+sHError
			wave/Z wHErWave = $sHErWave
		endif
	endif
	if(stringmatch(sVDim,"Library"))
		sVAxisWave = COMBI_DataPath(sProject,0);iVDim=0;iVVecLength = 1;	wave/Z wVAxis = $sVAxisWave
	elseif(stringmatch(sVDim,"Scalar"))
		sVAxisWave = COMBI_DataPath(sProject,1)+sLibraryV+":"+sVData;iVDim=1;iVVecLength = 1;wave/Z wVAxis = $sVAxisWave
		if(strlen(sVError)>0)
			sVErWave = COMBI_DataPath(sProject,1)+sLibraryV+":"+sVError
			wave/Z wVErWave = $sVErWave
		endif
	elseif(stringmatch(sVDim,"Vector"))
	 	sVAxisWave = COMBI_DataPath(sProject,2)+sLibraryV+":"+sVData;iVDim=2;iVVecLength = dimsize($sVAxisWave,1);wave/Z wVAxis = $sVAxisWave
	 	if(strlen(sVError)>0)
			sVErWave = COMBI_DataPath(sProject,2)+sLibraryV+":"+sVError
			wave/Z wVErWave = $sVErWave
		endif
	endif
	if(stringmatch(sCDim,"Library"))
		sCAxisWave = COMBI_DataPath(sProject,0);iCDim = 0;iCVecLength = 1;wave/Z wCAxis = $sCAxisWave
	elseif(stringmatch(sCDim,"Scalar"))
		sCAxisWave = COMBI_DataPath(sProject,1)+sLibraryC+":"+sCData;iCDim = 1;iCVecLength = 1;wave/Z wCAxis = $sCAxisWave
	elseif(stringmatch(sCDim,"Vector"))
		sCAxisWave = COMBI_DataPath(sProject,2)+sLibraryC+":"+sCData;iCDim = 2;iCVecLength = dimsize($sCAxisWave,1);wave/Z wCAxis = $sCAxisWave
	else
		sCAxisWave = "";iCDim =-1;iCVecLength = 1
	endif
	if(stringmatch(sSDim,"Library"))
		sSAxisWave = COMBI_DataPath(sProject,0);iSDim = 0;iSVecLength = 1;wave/Z wSAxis = $sSAxisWave
	elseif(stringmatch(sSDim,"Scalar"))
		sSAxisWave = COMBI_DataPath(sProject,1)+sLibraryS+":"+sSData;iSDim = 1;iSVecLength = 1;wave/Z wSAxis = $sSAxisWave
	elseif(stringmatch(sSDim,"Vector"))
		sSAxisWave = COMBI_DataPath(sProject,2)+sLibraryS+":"+sSData;iSDim = 2;iSVecLength = dimsize($sSAxisWave,1);wave/Z wSAxis = $sSAxisWave
	else
		sSAxisWave = "";iSDim =-1;iSVecLength = 1
	endif
	
	//get Library space wave
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	string sGA1 = GetDimLabel(wMappingGrid,1,3)
	string sGA2 = GetDimLabel(wMappingGrid,1,4)
	
	//get plotting stuff
	variable bYAxisFlip = COMBI_GetGlobalNumber("bYAxisFlip", sProject)
	variable bXAxisFlip = COMBI_GetGlobalNumber("bXAxisFlip", sProject)
	variable vLibraryHeight = COMBI_GetGlobalNumber("vLibraryHeight", sProject)
	variable vLibraryWidth = COMBI_GetGlobalNumber("vLibraryWidth", sProject)
	
	//determine how many dims
	variable vTotalAxes = 2
	string sWindowName = "Plot_" + sHData + "_" + sVData
	string sWindowTitle = sHData + " vs. " + sVData
	if(stringmatch(sCData,"")||stringmatch(sCData," "))
	else
		vTotalAxes+=1
		sWindowName = sWindowName + "_" + sCData
		sWindowTitle = sWindowTitle + " as " + sCData
	endif
	if(stringmatch(sSData,"")||stringmatch(sSData," "))
	else
		vTotalAxes+=1
		sWindowName = sWindowName + "_" + sSData
		sWindowTitle = sWindowTitle + " as " + sSData
	endif
	
	//get plot window / name of window / plot wave
	int vTotalPlotWaves = 0
	do
		vTotalPlotWaves+=1
		string sWaveName2Use = "DisplayWave"+num2str(vTotalPlotWaves)
	while(waveexists($"root:Packages:COMBIgor:DisplayWaves:"+sWaveName2Use))
	
	string sDataWave
	if(stringmatch(sAction,"NewPlot"))
		sWindowName = COMBI_NewPlot(sWindowName)
		DoWindow/T $sWindowName,sWindowTitle
		//make new data wave for this plot
		SetDataFolder root:Packages:COMBIgor
		NewDataFolder/O/S DisplayWaves
		Make/N=(vTotalSamples,6,0) $sWaveName2Use
		SetDataFolder $sTheCurrentUserFolder 
		//set userdata to wave path+name
		SetWindow $sWindowName userdata(DataSource)= "root:Packages:COMBIgor:DisplayWaves:"+sWaveName2Use
		SetWindow $sWindowName userdata(HOrigins) = ""
		SetWindow $sWindowName userdata(VOrigins) = ""
		SetWindow $sWindowName userdata(COrigins) = ""
		SetWindow $sWindowName userdata(SOrigins) = ""
		SetWindow $sWindowName userdata(HErOrigins) = ""
		SetWindow $sWindowName userdata(VErOrigins) = ""
		SetWindow $sWindowName userdata(SampleRanges) = ""
		SetWindow $sWindowName userdata(GA1Ranges) = ""
		SetWindow $sWindowName userdata(GA2Ranges) = ""
		SetWindow $sWindowName userdata(VectorLengths) = ""
		SetWindow $sWindowName userdata(DataSourceStart) = ""
		SetWindow $sWindowName userdata(DataSourceEnd) = ""
		SetWindow $sWindowName hook(kill)=COMBIDispaly_KillPlotData
		sDataWave = "root:Packages:COMBIgor:DisplayWaves:"+sWaveName2Use
	elseif(stringmatch(sAction,"AppendPlot"))
		sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
		if(strlen(sWindowName)==0)
			DoAlert/T="No plot",0,"COMBIgor cannot find any active plots."
			return -1
		endif
		sDataWave = GetUserData(sWindowName, "", "DataSource")
	endif
	wave wDataSource = $sDataWave
	int vPlotWaveLength = dimsize(wDataSource,0)
	
	//set Sample and SQ limits
	variable vSampleMin
	if(stringmatch(sSampleMin,"All"))
		vSampleMin = str2num(stringfromlist(0,COMBI_LibraryQualifiers(sProject,0)))
	else
		vSampleMin = str2num(sSampleMin)
	endif
	variable vSampleMax
	if(stringmatch(sSampleMax,"All"))
		vSampleMax = str2num(stringfromlist(itemsinlist(COMBI_LibraryQualifiers(sProject,0))-1,COMBI_LibraryQualifiers(sProject,0)))
	else
		vSampleMax = str2num(sSampleMax)
	endif
	variable vGA1Min
	if(stringmatch(sGA1Min,"All"))
		vGA1Min = str2num(stringfromlist(0,COMBI_LibraryQualifiers(sProject,3)))
	else
		vGA1Min = str2num(sGA1Min)
	endif
	variable vGA1Max
	if(stringmatch(sGA1Max,"All"))
		vGA1Max = str2num(stringfromlist(itemsinlist(COMBI_LibraryQualifiers(sProject,3))-1,COMBI_LibraryQualifiers(sProject,3)))
	else
		vGA1Max = str2num(sGA1Max)
	endif
	variable vGA2Min
	if(stringmatch(sGA2Min,"All"))
		vGA2Min = str2num(stringfromlist(0,COMBI_LibraryQualifiers(sProject,4)))
	else
		vGA2Min = str2num(sGA2Min)
	endif
	variable vGA2Max
	if(stringmatch(sGA2Max,"All"))
		vGA2Max = str2num(stringfromlist(itemsinlist(COMBI_LibraryQualifiers(sProject,4))-1,COMBI_LibraryQualifiers(sProject,4)))
	else
		vGA2Max = str2num(sGA2Max)
	endif
	
	//convert to numbers
	variable vHMax
	if(stringmatch(sHMax,"Auto"))
		vHMax = COMBI_Extremes(sProject,iHDim,sHData,sLibraryH,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Max")
	else
		vHMax = str2num(sHMax)
	endif
	variable vHMin
	if(stringmatch(sHMin,"Auto"))
		vHMin = COMBI_Extremes(sProject,iHDim,sHData,sLibraryH,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Min")
	else
		vHMin = str2num(sHMin)
	endif
	
	variable vVMax
	if(stringmatch(sVMax,"Auto"))
		vVMax = COMBI_Extremes(sProject,iVDim,sVData,sLibraryV,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Max")
	else
		vVMax = str2num(sVMax)
	endif
	variable vVMin
	if(stringmatch(sVMin,"Auto"))
		vVMin = COMBI_Extremes(sProject,iVDim,sVData,sLibraryV,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Min")
	else
		vVMin = str2num(sVMin)
	endif
	variable vCMax
	if(stringmatch(sCMax,"Auto")&&iCDim>=0)
		vCMax = COMBI_Extremes(sProject,iCDim,sCData,sLibraryC,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Max")
	else
		vCMax = str2num(sCMax)
	endif
	variable vCMin
	if(stringmatch(sCMin,"Auto")&&iCDim>=0)
		vCMin = COMBI_Extremes(sProject,iCDim,sCData,sLibraryC,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Min")
	else
		vCMin = str2num(sCMin)
	endif
	variable vSMax
	if(stringmatch(sSMax,"Auto")&&iSDim>=0)
		vSMax = COMBI_Extremes(sProject,iSDim,sSData,sLibraryS,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Max")
	else
		vSMax = str2num(sSMax)
	endif
	variable vSMin
	if(stringmatch(sSMin,"Auto")&&iSDim>=0)
		vSMin = COMBI_Extremes(sProject,iSDim,sSData,sLibraryS,num2str(vSampleMin)+";"+num2str(vSampleMax)+";"+num2str(vGA1Min)+";"+num2str(vGA1Max)+";"+num2str(vGA2Min )+";"+num2str(vGA2Max),"Min")
	else
		vSMin = str2num(sSMin)
	endif
	
	//appending? Get the min max values from current plot axes
	variable bNewHAxes, bNewVAxes
	string sAllPreviousTraces = traceNameList(sWindowName,";",0)
	GetAxis/Q/W=$sWindowName $sHLocation
	if(V_flag==0)
		bNewHAxes=0
		vHMin = V_min
		vHMax = V_max
	elseif(V_flag==1)
		bNewHAxes=1
	endif
	GetAxis/Q/W=$sWindowName $sVLocation
	if(V_flag==0)
		bNewVAxes=0
		vVMin = V_min
		vVMax = V_max
	elseif(V_flag==1)
		bNewVAxes=1
	endif

	//start building command
	string sAppendCommand ="AppendToGraph"+"/W="+sWindowName
	
	//add for locations
	if(stringmatch(sHLocation,"Top"))
		sAppendCommand = sAppendCommand + "/T"
	elseif(stringmatch(sHLocation,"Bottom"))
		sAppendCommand = sAppendCommand + "/B"
	endif
	if(stringmatch(sVLocation,"Left"))
		sAppendCommand = sAppendCommand + "/L"
	elseif(stringmatch(sVLocation,"Right"))
		sAppendCommand = sAppendCommand + "/R"
	endif
	
	//determine if 2D
	variable b2D=0, b2DSample=1
	if(iSDim==-1&&iCDim==-1)
		b2D=1
		if(stringmatch(sHDim,"Vector"))
			b2DSample=0
		endif
		if(stringmatch(sVDim,"Vector"))
			b2DSample=0
		endif
	endif
	
	//variables needed in following loops
	variable vSample, bTraceUnique, vTraceRepeat, vGA1, vGA2, iGA1, iGA2, iFirstP, iLastP, vThisGA1,iTrace,vTraceIn, iColor, vTraceCount, vTraceInk
	string sSampleCommand, sTraceName, sThisGA1, sThisGA2, sGA1List, sGA1Command, sThisErrorCommand
	
	//count total traces to add
	int vTotalTraces2Add = 0
	int vTraceMultiplier = 1
	if(b2D==1&&b2DSample==1)//Sample as active index
		sGA1List = COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),3)
		for(iGA1=0;iGA1<itemsinlist(sGA1List);iGA1+=1)//for each GA1 in the range
			sThisGA1 = stringfromlist(iGA1,sGA1List)
			vThisGA1 = str2num(sThisGA1)
			if(vThisGA1>=vGA1Min&&vThisGA1<=vGA1Max) // within GA1 range
				vTotalTraces2Add+=1
			endif
		endfor
	else //vector index			
		for(vSample=1;vSample<=vTotalSamples;vSample+=1)
			if(vSample>=vSampleMin&&vSample<=vSampleMax) // within Sample range
				vGA1 = wMappingGrid[vSample-1][3]
				vGA2 = wMappingGrid[vSample-1][4]
				if(vGA1>=vGA1Min&&vGA1<=vGA1Max) // within GA1 range
					if(vGA2>=vGA2Min&&vGA2<=vGA2Max)// within GA2 range
						vTotalTraces2Add+=1
					endif
				endif
			endif
		endfor		
	endif
	
	//move data to plotting wave
	int vNeededVecDim = Max(iHVecLength,iVVecLength,iCVecLength,iSVecLength)
	int iCurrentLength = dimSize(wDataSource,2)
	redimension/N=(-1,-1,iCurrentLength+vNeededVecDim) wDataSource
	wDataSource[][][iCurrentLength,iCurrentLength+vNeededVecDim-1] = nan
	int iVector
	variable vThisH, vThisV, vThisC, vThisS, vThisHEr, vThisVEr
	for(vSample=1;vSample<=vTotalSamples;vSample+=1)
		if(vSample>=vSampleMin&&vSample<=vSampleMax) // within Sample range
			vGA1 = wMappingGrid[vSample-1][3]
			vGA2 = wMappingGrid[vSample-1][4]
			if(vGA1>=vGA1Min&&vGA1<=vGA1Max) // within GA1 range
				if(vGA2>=vGA2Min&&vGA2<=vGA2Max)// within GA2 range
					for(iVector=0;iVector<vNeededVecDim;iVector+=1)
						vThisHEr = nan
						vThisVEr = nan
						if(stringmatch(sHDim,"Library"))
							vThisH = wHAxis[%$sLibraryH][%$sHData]
							if(strlen(sHError)>0)
								vThisHEr = wHAxis[%$sLibraryH][%$sHError]
							endif
						elseif(stringmatch(sHDim,"Scalar"))
							vThisH = wHAxis[vSample-1]
							if(strlen(sHError)>0)
								vThisHEr = wHErWave[vSample-1]
							endif
						elseif(stringmatch(sHDim,"Vector"))
						 	vThisH = wHAxis[vSample-1][iVector]
						 	if(strlen(sHError)>0)
								vThisHEr = wHErWave[vSample-1][iVector]
							endif
						endif
						if(stringmatch(sVDim,"Library"))
							vThisV = wVAxis[%$sLibraryV][%$sVData]
							if(strlen(sVError)>0)
								vThisVEr = wVAxis[%$sLibraryV][%$sVError]
							endif
						elseif(stringmatch(sVDim,"Scalar"))
							vThisV = wVAxis[vSample-1]
							if(strlen(sVError)>0)
								vThisVEr = wVErWave[vSample-1]
							endif
						elseif(stringmatch(sVDim,"Vector"))
						 	vThisV = wVAxis[vSample-1][iVector]
						 	if(strlen(sVError)>0)
								vThisVEr = wVErWave[vSample-1][iVector]
							endif
						endif
						if(stringmatch(sCDim,"")||stringmatch(sCDim," "))
							vThisC = nan
						elseif(stringmatch(sCDim,"Library"))
							vThisC = wCAxis[%$sLibraryC][%$sCData]
						elseif(stringmatch(sCDim,"Scalar"))
							vThisC = wCAxis[vSample-1]
						elseif(stringmatch(sCDim,"Vector"))
							vThisC = wCAxis[vSample-1][iVector]
						endif
						if(stringmatch(sSDim,"")||stringmatch(sSDim," "))
							vThisS = nan
						elseif(stringmatch(sSDim,"Library"))
							vThisS = wSAxis[%$sLibraryS][%$sSData]
						elseif(stringmatch(sSDim,"Scalar"))
							vThisS = wSAxis[vSample-1]
						elseif(stringmatch(sSDim,"Vector"))
							vThisS = wSAxis[vSample-1][iVector]
						endif
						wDataSource[vSample-1][0][iCurrentLength+iVector] = vThisH
						wDataSource[vSample-1][1][iCurrentLength+iVector] = vThisV
						wDataSource[vSample-1][2][iCurrentLength+iVector] = vThisC
						wDataSource[vSample-1][3][iCurrentLength+iVector] = vThisS
						wDataSource[vSample-1][4][iCurrentLength+iVector] = vThisHEr
						wDataSource[vSample-1][5][iCurrentLength+iVector] = vThisVEr
					endfor
				endif
			endif
		endif
	endfor
	//log in user data
	SetWindow $sWindowName userdata(DataSourceStart)+=num2str(iCurrentLength)+";"
	SetWindow $sWindowName userdata(DataSourceEnd)+=Num2str(iCurrentLength+iVector)+";"
	SetWindow $sWindowName userdata(HOrigins)+=sHAxisWave+";"
	SetWindow $sWindowName userdata(VOrigins)+=sVAxisWave+";"
	SetWindow $sWindowName userdata(COrigins)+=sCAxisWave+";"
	SetWindow $sWindowName userdata(SOrigins)+=sSAxisWave+";"
	SetWindow $sWindowName userdata(HErOrigins)+=sHErWave+";"
	SetWindow $sWindowName userdata(VErOrigins)+=sVErWave+";"
	SetWindow $sWindowName userdata(SampleRanges)+=num2str(vSampleMin)+" to "+num2str(vSampleMax)+";"
	SetWindow $sWindowName userdata(GA1Ranges)+=num2str(vGA1Min)+" to "+num2str(vGA1Max)+";"
	SetWindow $sWindowName userdata(GA2Ranges)+=num2str(vGA2Min)+" to "+num2str(vGA2Max)+";"
	SetWindow $sWindowName userdata(VectorLengths)+=num2str(vNeededVecDim)+";"
			
	//get color info for coloring traces
	colortab2wave $sColorTheme
	wave/i/u M_colors
	vTraceInk=(dimsize(M_colors,0)-1)/(vTotalTraces2Add)

	//append each Sample to plot window
	vTraceCount=1
	if(b2D==1&&b2DSample==1)//Sample as active index (2D)
		sGA1List = COMBI_LibraryQualifiers(COMBIDisplay_GetString("sProject","COMBIgor"),3)
		for(iGA1=0;iGA1<itemsinlist(sGA1List);iGA1+=1)//for each GA1 in the range
			sThisGA1 = stringfromlist(iGA1,sGA1List)
			vThisGA1 = str2num(sThisGA1)
			if(vThisGA1>=vGA1Min&&vThisGA1<=vGA1Max) // within GA1 range
				iFirstP=vTotalSamples-1
				iLastP=0
				for(vSample=0;vSample<vTotalSamples;vSample+=1)//find the range of Samples for this GA1
					vGA2 = wMappingGrid[vSample][4]
					vGA1 = wMappingGrid[vSample][3]
					if(vGA2>=vGA2Min&&vGA2<=vGA2Max)// within GA2 range
						if(vThisGA1==vGA1)
							if(iFirstP>vSample)//lowest Sample
								iFirstP = vSample
							endif
							if(iLastP<vSample)//highest Sample
								iLastP = vSample
							endif
						endif
					endif
				endfor
				//add text specifics for unique trace name
				bTraceUnique = 0
				sTraceName = sLibraryV+"_"+sVData+"_vs_"+sLibraryH+"_"+sHData+"_"+sGA1+sThisGA1	
				sTraceName = cleanupname(sTraceName,0)			
				if(stringmatch(sAction,"AppendPlot"))
					if(findListItem(sTraceName,sAllPreviousTraces)==-1)
						bTraceUnique=1
					else
						vTraceRepeat = 0
						do
							if(findListItem(sTraceName+num2str(vTraceRepeat),sAllPreviousTraces)==-1)
								bTraceUnique=1
							else
								vTraceRepeat+=1
							endif
						while(bTraceUnique==0)
						sTraceName = sTraceName+num2str(vTraceRepeat)
					endif
				endif// iCurrentLength,iCurrentLength+vNeededVecDim-1
				sGA1Command = sAppendCommand+" "+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][1]["+num2str(iCurrentLength)+"]/TN="+sTraceName+" vs "+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][0]["+num2str(iCurrentLength)+"]"
				//appendtograph
				Execute/Q/Z sGA1Command
				ModifyGraph mode($sTraceName)=vMode
				ModifyGraph marker($sTraceName)=vMarker
				
				//color the 2D trace
				iColor = trunc(vTraceCount*vTraceInk)
				ModifyGraph rgb($sTraceName)=(M_colors[iColor][0],M_colors[iColor][1],M_colors[iColor][2])
				vTraceCount+=1
								
				//error bars if added
				if(stringmatch(sHError,"")||stringmatch(sHError," "))
					if(stringmatch(sVError,"")||stringmatch(sVError," "))
					else
						sThisErrorCommand = "ErrorBars "+sTraceName+" Y, wave=("+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][5]["+num2str(iCurrentLength)+"],"+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][5]["+num2str(iCurrentLength)+"])"
						Execute/Q/Z sThisErrorCommand
					endif
				else
					if(stringmatch(sVError,"")||stringmatch(sVError," "))
						sThisErrorCommand =  "ErrorBars "+sTraceName+" X, wave=("+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][4]["+num2str(iCurrentLength)+"],"+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][4]["+num2str(iCurrentLength)+"])"
						Execute/Q/Z sThisErrorCommand
					else
						sThisErrorCommand =  "ErrorBars "+sTraceName+" XY, wave=("+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][4]["+num2str(iCurrentLength)+"],"+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][4]["+num2str(iCurrentLength)+"]),wave=("+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][5]["+num2str(iCurrentLength)+"],"+sDataWave+"["+num2str(iFirstP)+","+num2str(iLastP)+"][5]["+num2str(iCurrentLength)+"])"
						Execute/Q/Z sThisErrorCommand
					endif
				endif
			endif
		endfor
	else //vector index			
		for(vSample=1;vSample<=vTotalSamples;vSample+=1)
			if(vSample>=vSampleMin&&vSample<=vSampleMax) // within Sample range
				vGA1 = wMappingGrid[vSample-1][3]
				vGA2 = wMappingGrid[vSample-1][4]
				if(vGA1>=vGA1Min&&vGA1<=vGA1Max) // within GA1 range
					if(vGA2>=vGA2Min&&vGA2<=vGA2Max)// within GA2 range
						//add text specifics
						bTraceUnique = 0
						sTraceName = sLibraryV+"_"+sVData+"_vs_"+sLibraryH+"_"+sHData+"_as_"+sLibraryC+"_"+sCData+"_P"+num2str(vSample)
						sTraceName = cleanupname(sTraceName,0)
						if(strlen(sTraceName)>250)
							sTraceName = sTraceName[0,249]
						endif
						if(stringmatch(sAction,"AppendPlot"))
							if(findListItem(sTraceName,sAllPreviousTraces)==-1)
								bTraceUnique=1
							else
								vTraceRepeat = 0
								do
									if(findListItem(sTraceName+num2str(vTraceRepeat),sAllPreviousTraces)==-1)
										bTraceUnique=1
									else
										vTraceRepeat+=1
									endif
								while(bTraceUnique==0)
								sTraceName = sTraceName+num2str(vTraceRepeat)
							endif
						endif //iCurrentLength+vNeededVecDim
						sSampleCommand = sAppendCommand+" "+sDataWave+"["+num2str(vSample-1)+"][1]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"]/TN="+sTraceName+" vs "+sDataWave+"["+num2str(vSample-1)+"][0]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"]"
						//appendtograph
						Execute/Q/Z sSampleCommand
						ModifyGraph mode($sTraceName)=vMode
						//color scaling
						if(stringmatch(sCData,"")||stringmatch(sCData," "))
							//no color scale
							ModifyGraph marker($sTraceName)=vMarker
							ModifyGraph msize($sTraceName)=5
							iColor = trunc(vTraceCount*vTraceInk)
							ModifyGraph rgb($sTraceName)=(M_colors[iColor][0],M_colors[iColor][1],M_colors[iColor][2])
						else
							//color scale
							if(stringmatch(sCScale,"Linear")||stringmatch(sCScale,"Log"))
								Execute/Q/Z "ModifyGraph zColor("+sTraceName+")={"+sDataWave+"["+num2str(vSample-1)+"][2]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+num2str(vCMin)+","+num2str(vCMax)+","+sColorTheme+",0}"
							elseif(stringmatch(sCScale,"-Linear")||stringmatch(sCScale,"-Log"))
								Execute/Q/Z "ModifyGraph zColor("+sTraceName+")={"+sDataWave+"["+num2str(vSample-1)+"][2]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+num2str(vCMax)+","+num2str(vCMin)+","+sColorTheme+",0}"
							endif
							if(stringmatch(sCScale,"*Log"))
								ModifyGraph logZColor($sTraceName)=1
							endif
							ModifyGraph marker($sTraceName)=vMarker
							ModifyGraph msize($sTraceName)=5	
						endif
						
						//size scaling
						if(stringmatch(sSData," ")||stringmatch(sSData,""))
							//no size scale
						else
							//size scale
							if(stringmatch(sSScale,"Linear"))
								Execute/Q/Z "ModifyGraph zmrkSize("+sTraceName+")={"+sDataWave+"["+num2str(vSample-1)+"][3]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+num2str(vSMin)+","+num2str(vSMax)+",0,10}"
							elseif(stringmatch(sSScale,"-Linear"))
								Execute/Q/Z "ModifyGraph zmrkSize("+sTraceName+")={"+sDataWave+"["+num2str(vSample-1)+"][3]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+num2str(vSMax)+","+num2str(vSMin)+",0,10}"
							endif
						endif
						
						//error bars if added
						if(stringmatch(sHError,"")||stringmatch(sHError," "))
							if(stringmatch(sVError,"")||stringmatch(sVError," "))
							else
								sThisErrorCommand = "ErrorBars "+sTraceName+" Y, wave=("+sDataWave+"["+num2str(vSample-1)+"][5]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+sDataWave+"["+num2str(vSample-1)+"][5]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"])"
								Execute/Q/Z sThisErrorCommand
							endif
						else
							if(stringmatch(sVError,"")||stringmatch(sVError," "))
								sThisErrorCommand =  "ErrorBars "+sTraceName+" X, wave=("+sDataWave+"["+num2str(vSample-1)+"][4]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+sDataWave+"["+num2str(vSample-1)+"][4]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"])"
								Execute/Q/Z sThisErrorCommand
							else
								sThisErrorCommand =  "ErrorBars "+sTraceName+" XY, wave=("+sDataWave+"["+num2str(vSample-1)+"][4]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+sDataWave+"["+num2str(vSample-1)+"][4]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"]),wave=("+sDataWave+"["+num2str(vSample-1)+"][5]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"],"+sDataWave+"["+num2str(vSample-1)+"][5]["+num2str(iCurrentLength)+","+num2str(iCurrentLength+vNeededVecDim-1)+"])"
								Execute/Q/Z sThisErrorCommand
							endif
						endif
						vTraceCount+=1
					endif
				endif
			endif
		endfor		
	endif
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	int iBold
	if(stringmatch(COMBI_GetGlobalString("sBoldOption","COMBIgor"),"No"))
		iBold=0
	else
		iBold=1
	endif
	//format if new
	if(bNewHAxes==1)
		Label $sHLocation COMBIDisplay_GetAxisLabel(sHData)
		ModifyGraph lblPosMode($sHLocation)=0
		if(stringmatch(sHScale,"Linear"))
			setaxis $sHLocation vHMin,vHMax 
		elseif(stringmatch(sHScale,"Log"))
			ModifyGraph log($sHLocation)=1
			if(vHMin>0&&vHMax>0)
				setaxis $sHLocation vHMin,vHMax 
			endif
			setaxis $sHLocation vHMin,vHMax
		elseif(stringmatch(sHScale,"-Linear"))
			setaxis $sHLocation vHMax,vHMin
		elseif(stringmatch(sHScale,"-Log"))
			ModifyGraph log($sHLocation)=1
			if(vHMin>0&&vHMax>0)
				setaxis $sHLocation vHMax,vHMin 
			endif
		endif
	endif
	if(bNewVAxes==1)
		Label $sVLocation COMBIDisplay_GetAxisLabel(sVData)
		ModifyGraph lblPosMode($sVLocation)=0
		if(stringmatch(svScale,"Linear"))
			setaxis $sVLocation vVMin,vVMax 
		elseif(stringmatch(sVScale,"Log"))
			ModifyGraph log($sVLocation)=1
			if(vVMin>0&&vVMax>0)
				setaxis $sVLocation vVMin,vVMax
			endif
		elseif(stringmatch(sVScale,"-Linear"))
			setaxis $sVLocation vVMax,vVMin
		elseif(stringmatch(sVScale,"-Log"))
			ModifyGraph log($sVLocation)=1
			if(vVMin>0&&vVMax>0)
				setaxis $sVLocation vVMax,vVMin
			endif
		endif
	endif
	if(iCDim>=0)
		ModifyGraph margin(right)=100
		if(stringmatch(sCScale,"Linear"))
			ColorScale/Z=0/C/N=zScaleLeg/F=0/A=MC ctab={vCMin,vCMax,$sColorTheme,0}
		elseif(stringmatch(sCScale,"Log"))
			if(vCMin>0&&vCMax>0)
				ColorScale/C/N=zScaleLeg log=1
			endif
			ColorScale/C/N=zScaleLeg/F=0/A=MC ctab={vCMin,vCMax,$sColorTheme,0}
		elseif(stringmatch(sCScale,"-Log"))
			if(vCMin>0&&vCMax>0)
				ColorScale/C/N=zScaleLeg log=1
			endif
			ColorScale/C/N=zScaleLeg/F=0/A=MC ctab={vCMax,vCMin,$sColorTheme,1}
		elseif(stringmatch(sCScale,"-Linear"))
			ColorScale/C/N=zScaleLeg/F=0/A=MC ctab={vCMin,vCMax,$sColorTheme,1}
			ColorScale/C/N=zScaleLeg/F=0/A=MC ctab={vCMin,vCMax,$sColorTheme,1}
			if(vCMin>0&&vCMax>0)
				ColorScale/C/N=zScaleLeg log=1
			endif
		endif
		ColorScale/C/N=zScaleLeg trace=$sTraceName
		ColorScale/C/N=zScaleLeg/Z=0/A=RC/X=-35/Y=0.00 width=10,heightPct=80
		ColorScale/C/N=zScaleLeg minor=1,logLTrip=0.001,logHTrip=100
		ColorScale/C/N=zScaleLeg fsize=12,fstyle=0,lblMargin=-10,minor=1
		ColorScale/C/N=zScaleLeg COMBIDisplay_GetAxisLabel(sCData)
	
	endif
	if(iSDim>=0&&bNewVAxes==1)
		string sDrawNum1, sDrawNum2, sDrawNum3, sDrawNum4, sDrawNum5
		variable vSMinS,vSMaxS
		if(stringmatch(sSScale,"Linear"))
			sDrawNum1 = num2str(vSMin)
			sDrawNum3 = num2str((vSMax+vSMin)/2)
			sDrawNum5 = num2str(vSMax)
			vSMinS = vSMin
			vSMaxS = vSMax
		elseif(stringmatch(sSScale,"Log"))
			sDrawNum1 = num2str(vSMin)
			sDrawNum3 = num2str(10^((Log(vSMax)+Log(vSMin))/2))
			sDrawNum5 = num2str(vSMax)
			vSMinS = vSMin
			vSMaxS = vSMax	
		elseif(stringmatch(sSScale,"-Linear"))
			sDrawNum1 = num2str(vSMax)
			sDrawNum3 = num2str((vSMax+vSMin)/2)
			sDrawNum5 = num2str(vSMin)
			vSMinS = vSMax
			vSMaxS = vSMin
		elseif(stringmatch(sSScale,"-Log"))
			sDrawNum1 = num2str(vSMax)
			sDrawNum3 = num2str(10^((Log(vSMax)+Log(vSMin))/2))
			sDrawNum5 = num2str(vSMin)
			vSMinS = vSMax
			vSMaxS = vSMin
		endif
		SetDrawEnv gstart, gname=SizeScale
		SetDrawEnv xcoord= abs,ycoord= abs ,save
		SetDrawEnv linethick= 0.50, save
		DrawLine 60,50,250,50
		SetDrawEnv textrgb= (65535,65535,65535), save
		DrawText 205,60,"\K(65535,65535,65535)\\Z40\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 165,58.5,"\K(65535,65535,65535)\\Z32\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 125,57.5,"\K(65535,65535,65535)\\Z25\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 85,55,"\K(65535,65535,65535)\\Z17\\k(0,0,0)\\W50"+num2str(vMarker)
		DrawText 50,53,"\K(65535,65535,65535)\\Z10\\k(0,0,0)\\W50"+num2str(vMarker)
		SetDrawEnv textrgb= (0,0,0),fname=sFont, save
		SetDrawEnv textxjust= 1,fsize=12, save
		ModifyGraph margin(top)=80
		SetDrawEnv fstyle= iBold, save
		DrawText 60,40, sDrawNum1
		DrawText 150,40, sDrawNum3
		DrawText 240,40, sDrawNum5
		DrawText 150,20, COMBIDisplay_GetAxisLabel(sSData)
		SetDrawEnv gstop, gname=SizeScale 
	endif
	
	//check if Library map by mm or SQ
	if(bNewHAxes==1&&bNewVAxes==1)
		if(stringmatch(sVData,"y_mm")&&stringmatch(sHData,"x_mm"))//format as a mm map
			if(bYAxisFlip==1)
				SetAxis left vLibraryHeight,0
			else
				SetAxis left 0,vLibraryHeight
			endif
			if(bXAxisFlip==1)
				SetAxis bottom vLibraryWidth,0
			else
				SetAxis bottom 0,vLibraryWidth
			endif
			ModifyGraph width=216,height=216
			ModifyGraph mirror=2
		elseif(stringmatch(sVData,"Rows")&&stringmatch(sHData,"Columns"))//format as a R v C map
		
		
		endif
	endif
	
	//killwaves
	killwaves/z M_colors
	
End

Function COMBIDisplay_SeeData(ctrlName) : ButtonControl
	String ctrlName
	
	//get globals
	variable vDDim = COMBIDisplay_GetNumber("vDDim","COMBIgor")
	String sDData = COMBIDisplay_GetString("sDData","COMBIgor")
	String sDSample = COMBIDisplay_GetString("sDSample","COMBIgor")
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	String sLibrarySee = COMBIDisplay_GetString("sLibrarySee","COMBIgor")
	
	//needed
	string sTableName
	variable iSample = 0, iDataType = 1, iLibrary = 1
	variable bAllData = 1,bAllSamples = 1
	
	//get wave
	if(vDDim==1)
		wave wCOMBIData = $COMBI_DataPath(sProject,vDDim)+sLibrarySee+":"+sDData
	elseif(vDDim==2)
		wave wCOMBIData = $COMBI_DataPath(sProject,vDDim)+sLibrarySee+":"+sDData
	endif
		
	if(vDDim==-1)
		COMBI_SeeMetaTable(sProject)
	elseif(vDDim==0)//Library table
		 sTableName = COMBI_SeeLibraryTable(sProject)
	elseif(vDDim==1)//scalar table
		Edit wCOMBIData
	elseif(vDDim==2)//vector data table
		 Edit wCOMBIData
		 if(stringmatch(sDSample,"All"))
		 	ModifyTable elements=(-3,-2)
		else
			ModifyTable elements=(-3,-2)
		endif
	endif
	
end


//tab contol
function COMBIDisplay_TabAction(ctrlName, tabNum) : TabControl
	String ctrlName
	Variable tabNum
	COMBIDisplay_Global("iActiveTab",num2str(tabNum),"COMBIgor")
	COMBIDisplay()
end

//for linking data tables to plots
Function COMBIDispaly_KillPlotData(s)
	STRUCT WMWinHookStruct &s
	if(s.eventCode==2)//window being killed
		string sWindowName = s.winName
		string sDataWaveName = GetUserData(sWindowName, "", "DataSource")
		string sAllTraces = TraceNameList(sWindowName,";", 1 )
		int iTrace
		For(iTrace=0;iTrace<itemsinList(sAllTraces);iTrace+=1)
			string sThisTrace = stringFromList(iTrace,sAllTraces)
			RemovefromGraph/W=$sWindowName/Z $sThisTrace
		endfor
		wave wToKill = $sDataWaveName
		Killwaves/Z wToKill
	endif
End

function COMBIDisplay_SavePlot(ctrlName) : ButtonControl
	String ctrlName
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	if(strlen(sWindowName)==0)
		DoAlert/T="No plot",0,"COMBIgor cannot find any active plots."
		return -1
	endif
	
	//first tracename
	string sTrace1 = TraceNameList(sWindowName,";",1)
	
	string sFilename = COMBI_StringPrompt(stringfromlist(0,sTrace1),"File name:","","This will be the name of the file, with .pdf added to the end of course","File name?")
	COMBI_Save(sProject,sWindowName,"",sFilename,"PDF")
	
	//save data?
	DoAlert/T="What about the data info?",1,"Would you like to export a .txt file of the plot into as well?"
	if(V_Flag==1)
		string sDataWave = GetUserData(sWindowName, "", "DataSource")
		wave/Z wDataSource = $sDataWave
		int vPlotWaveLength = dimsize(wDataSource,0)
		wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
		string sGA1 = GetDimLabel(wMappingGrid,1,3)
		string sGA2 = GetDimLabel(wMappingGrid,1,4)
		string sLogBookName = sWindowName+"_DataHistory"
		string sWindowTitle = " History of data in "+sFilename 
		PauseUpdate; Silent 1 // pause for building window...
		killwindow/Z $sLogBookName
		newnotebook/V=0/O/Z/F=0/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sLogBookName/W=(10,10,610,810) as sWindowTitle
		string sTab = "\t"
		string sReturn = "\r"
		
		string sHOrigins = GetUserData(sWindowName, "", "HOrigins")
		string sVOrigins = GetUserData(sWindowName, "", "VOrigins")
		string sCOrigins = GetUserData(sWindowName, "", "COrigins")
		string sSOrigins = GetUserData(sWindowName, "", "SOrigins")
		string sHErOrigins = GetUserData(sWindowName, "", "HErOrigins")
		string sVErOrigins = GetUserData(sWindowName, "", "VErOrigins")
		string sSampleRanges = GetUserData(sWindowName, "", "SampleRanges")
		string sGA1Ranges = GetUserData(sWindowName, "", "GA1Ranges")
		string sGA2Ranges = GetUserData(sWindowName, "", "GA2Ranges")
		string sVectorLengths = GetUserData(sWindowName, "", "VectorLengths")
		string sDataSourceStart = GetUserData(sWindowName, "", "DataSourceStart")
		string sDataSourceEnd = GetUserData(sWindowName, "", "DataSourceEnd")
		int iDataSet
	
		for(iDataSet=0;iDataSet<itemsInList(sSampleRanges);iDataSet+=1)
			notebook $sLogBookName text= "Data set "+num2str(1+iDataSet)+sReturn
			notebook $sLogBookName text=sTab+ "Horizontal Data "+" : "+stringfromlist(iDataSet,sHOrigins)+sReturn
			notebook $sLogBookName text=sTab+ "Horizontal Error Data "+" : "+stringfromlist(iDataSet,sHErOrigins)+sReturn
			notebook $sLogBookName text=sTab+ "Vertical Data "+" : "+stringfromlist(iDataSet,sVOrigins)+sReturn
			notebook $sLogBookName text=sTab+ "Vertical Error Data "+" : "+stringfromlist(iDataSet,sVErOrigins)+sReturn
			notebook $sLogBookName text=sTab+ "Color Data "+" : "+stringfromlist(iDataSet,sCOrigins)+sReturn
			notebook $sLogBookName text=sTab+ "Size Data "+" : "+stringfromlist(iDataSet,sSOrigins)+sReturn
			notebook $sLogBookName text=sTab+ "Samples Range"+" : "+stringfromlist(iDataSet,sSampleRanges)+sReturn
			notebook $sLogBookName text=sTab+ sGA1+" Range "+" : "+stringfromlist(iDataSet,sGA1Ranges)+sReturn
			notebook $sLogBookName text=sTab+ sGA2+" Range "+" : "+stringfromlist(iDataSet,sGA2Ranges)+sReturn
			notebook $sLogBookName text=sTab+ "Vector Length "+" : "+stringfromlist(iDataSet,sVectorLengths)+sReturn
			notebook $sLogBookName text=sReturn
		endfor
		COMBI_Save(sProject,sLogBookName,"",sFilename+"_Info","Notebook")
		KillWindow $sLogBookName
	endif
	
	
end

function COMBIDisplay_SaveType(ctrlName) : ButtonControl
	String ctrlName
	//get values from globals table
	String sHMin = COMBIDisplay_GetString("vHMin","COMBIgor")
	String sHMax = COMBIDisplay_GetString("vHMax","COMBIgor")
	String sVMin = COMBIDisplay_GetString("vVMin","COMBIgor")
	String sVMax = COMBIDisplay_GetString("vVMax","COMBIgor")
	String sCMin = COMBIDisplay_GetString("vCMin","COMBIgor")
	String sCMax = COMBIDisplay_GetString("vCMax","COMBIgor")
	String sSMin = COMBIDisplay_GetString("vSMin","COMBIgor")
	String sSMax = COMBIDisplay_GetString("vSMax","COMBIgor")
	String sSampleMin = COMBIDisplay_GetString("vSampleMin","COMBIgor")
	String sSampleMax = COMBIDisplay_GetString("vSampleMax","COMBIgor")
	String sGA1Min = COMBIDisplay_GetString("vGA1Min","COMBIgor")
	String sGA1Max = COMBIDisplay_GetString("vGA1Max","COMBIgor")
	String sGA2Min = COMBIDisplay_GetString("vGA2Min","COMBIgor")
	String sGA2Max = COMBIDisplay_GetString("vGA2Max","COMBIgor")
	String sHScale = COMBIDisplay_GetString("sHScale","COMBIgor")
	String sVScale = COMBIDisplay_GetString("sVScale","COMBIgor")
	String sCScale = COMBIDisplay_GetString("sCScale","COMBIgor")
	String sSScale = COMBIDisplay_GetString("sSScale","COMBIgor")
	String sHDim = COMBIDisplay_GetString("sHDim","COMBIgor")
	String sVDim = COMBIDisplay_GetString("sVDim","COMBIgor")
	String sCDim = COMBIDisplay_GetString("sCDim","COMBIgor")
	String sSDim = COMBIDisplay_GetString("sSDim","COMBIgor")
	String sHData = COMBIDisplay_GetString("sHData","COMBIgor")
	String sVData = COMBIDisplay_GetString("sVData","COMBIgor")
	String sCData = COMBIDisplay_GetString("sCData","COMBIgor")
	String sSData = COMBIDisplay_GetString("sSData","COMBIgor")
	String sHError = COMBIDisplay_GetString("sHError","COMBIgor")
	String sVError = COMBIDisplay_GetString("sVError","COMBIgor")
	String sCColor = COMBIDisplay_GetString("sCColor","COMBIgor")
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	String sLibraryH = COMBIDisplay_GetString("sLibraryH","COMBIgor")
	String sLibraryv = COMBIDisplay_GetString("sLibraryV","COMBIgor")
	String sLibraryC = COMBIDisplay_GetString("sLibraryC","COMBIgor")
	String sLibraryS = COMBIDisplay_GetString("sLibraryS","COMBIgor")
	String sHLocation = COMBIDisplay_GetString("sHLocation","COMBIgor")
	String sVLocation = COMBIDisplay_GetString("sVLocation","COMBIgor")
	string sColorTheme = COMBIDisplay_GetString("sCColor","COMBIgor")
	variable vMode = COMBIDisplay_GetNumber("vMode","COMBIgor")
	variable vMarker = COMBIDisplay_GetNumber("vMarker","COMBIgor")
	string sStorageWave = sProject+"&&"+"StoreAfterHere"+"&&"+sHDim+"&&"+sLibraryH+"&&"+sHData+"&&"+sHError+"&&"+sHScale+"&&"+sHMin+"&&"+sHMax+"&&"+sHLocation+"&&"+sVDim+"&&"+sLibraryV+"&&"+sVData+"&&"+sVError+"&&"+sVScale+"&&"+sVMin+"&&"+sVMax+"&&"+sVLocation+"&&"+sCDim+"&&"+sLibraryC+"&&"+sCData+"&&"+sCScale+"&&"+sCMin+"&&"+sCMax+"&&"+sColorTheme+"&&"+sSDim+"&&"+sLibraryS+"&&"+sSData+"&&"+sSScale+"&&"+sSMin+"&&"+sSMax+"&&"+num2str(vMode)+"&&"+num2str(vMarker)+"&&"+sSampleMin+"&&"+sSampleMax+"&&"+sGA1Min+"&&"+sGA1Max+"&&"+sGA2Min+"&&"+sGA2Max
	string sStorageName = COMBI_StringPrompt("Store plot type as","Unique name for this plot type:","","This will be the name assigned to this plot type.","Save plot type for recalling later.")
	if(stringmatch(sStorageName,"CANCEL"))
		return -1
	endif
	sStorageName = cleanupname(sStorageName,0)
	COMBIDisplay_Global(sStorageName+"_SavedPlotType",sStorageWave,"COMBIgor")
end

function COMBIDisplay_LoadType(ctrlName) : ButtonControl
	String ctrlName
	//get twCOMBI_PluginGlobals from COMBIgor folder
	wave/T twGlobals = root:Packages:COMBIgor:COMBI_DisplayGlobals
	int iGlobal
	string sSavedList =""
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	for(iGlobal=1;iGlobal<dimsize(twGlobals,0);iGlobal+=1)
		string sThisLabel=GetDimLabel(twGlobals,0,iGlobal)
		if(stringmatch(sThisLabel,"*_SavedPlotType"))
			sSavedList = AddListItem(replaceString("_SavedPlotType",sThisLabel,""),sSavedList)
		endif
	endfor
	string sThisLoadSelect = COMBI_StringPrompt("","Saved type to load:",sSavedList,"These are the only options I can find saved","Load saved plot type!")
	if(stringmatch(sThisLoadSelect,"CANCEL"))
		return-1
	endif
	string sStorageString = COMBIDisplay_GetString(sThisLoadSelect+"_SavedPlotType","COMBIgor")
	
	COMBIDisplay_Global("sHDim",stringfromlist(2,sStorageString,"&&"),"COMBIgor")
	if(COMBI_CheckForLibrary(sProject,stringfromlist(3,sStorageString,"&&"),whichlistitem(stringfromlist(2,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sLibraryH",stringfromlist(3,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sLibraryH","","COMBIgor")
	endif
	if(COMBI_CheckForDataType(sProject,stringfromlist(3,sStorageString,"&&"),stringfromlist(4,sStorageString,"&&"),whichlistitem(stringfromlist(2,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sHData",stringfromlist(4,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sHData","","COMBIgor")
	endif
	if(COMBI_CheckForDataType(sProject,stringfromlist(3,sStorageString,"&&"),stringfromlist(5,sStorageString,"&&"),whichlistitem(stringfromlist(2,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sHError",stringfromlist(5,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sHError","","COMBIgor")
	endif
	COMBIDisplay_Global("sHScale",stringfromlist(6,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sHMin",stringfromlist(7,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sHMax",stringfromlist(8,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sHLocation",stringfromlist(9,sStorageString,"&&"),"COMBIgor")
	
	COMBIDisplay_Global("sVDim",stringfromlist(10,sStorageString,"&&"),"COMBIgor")
	if(COMBI_CheckForLibrary(sProject,stringfromlist(11,sStorageString,"&&"),whichlistitem(stringfromlist(10,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sLibraryV",stringfromlist(11,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sLibraryV","","COMBIgor")
	endif
	if(COMBI_CheckForDataType(sProject,stringfromlist(11,sStorageString,"&&"),stringfromlist(12,sStorageString,"&&"),whichlistitem(stringfromlist(10,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sVData",stringfromlist(12,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sVData","","COMBIgor")
	endif
	if(COMBI_CheckForDataType(sProject,stringfromlist(11,sStorageString,"&&"),stringfromlist(13,sStorageString,"&&"),whichlistitem(stringfromlist(10,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sVError",stringfromlist(13,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sVError","","COMBIgor")
	endif
	COMBIDisplay_Global("sVScale",stringfromlist(14,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sVMin",stringfromlist(15,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sVMax",stringfromlist(16,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sVLocation",stringfromlist(17,sStorageString,"&&"),"COMBIgor")
	
	COMBIDisplay_Global("sCDim",stringfromlist(18,sStorageString,"&&"),"COMBIgor")
	if(COMBI_CheckForLibrary(sProject,stringfromlist(19,sStorageString,"&&"),whichlistitem(stringfromlist(18,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sLibraryC",stringfromlist(19,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sLibraryC","","COMBIgor")
	endif
	if(COMBI_CheckForDataType(sProject,stringfromlist(20,sStorageString,"&&"),stringfromlist(20,sStorageString,"&&"),whichlistitem(stringfromlist(18,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sCData",stringfromlist(20,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sCData","","COMBIgor")
	endif
	COMBIDisplay_Global("sCScale",stringfromlist(21,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sCMin",stringfromlist(22,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sCMax",stringfromlist(23,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sColorTheme",stringfromlist(24,sStorageString,"&&"),"COMBIgor")
	
	COMBIDisplay_Global("sSDim",stringfromlist(25,sStorageString,"&&"),"COMBIgor")
	if(COMBI_CheckForLibrary(sProject,stringfromlist(26,sStorageString,"&&"),whichlistitem(stringfromlist(25,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sLibraryS",stringfromlist(26,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sLibraryS","","COMBIgor")
	endif
	if(COMBI_CheckForDataType(sProject,stringfromlist(26,sStorageString,"&&"),stringfromlist(27,sStorageString,"&&"),whichlistitem(stringfromlist(25,sStorageString,"&&"),"Library;Scalar;Vector")))
		COMBIDisplay_Global("sSData",stringfromlist(27,sStorageString,"&&"),"COMBIgor")
	else
		COMBIDisplay_Global("sSData","","COMBIgor")
	endif
	COMBIDisplay_Global("sSScale",stringfromlist(28,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sSMin",stringfromlist(29,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sSMax",stringfromlist(30,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("vMode",stringfromlist(31,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("vMarker",stringfromlist(32,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sSampleMin",stringfromlist(33,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sSampleMax",stringfromlist(34,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sGA1Min",stringfromlist(35,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sGA1Max",stringfromlist(36,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sGA2Min",stringfromlist(37,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay_Global("sGA2Max",stringfromlist(38,sStorageString,"&&"),"COMBIgor")
	COMBIDisplay()
end

function COMBIDisplay_DataSource(ctrlName) : ButtonControl
	String ctrlName
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	
	if(strlen(sWindowName)==0)
		DoAlert/T="No Plots?", 0, "COMBIgor cannot find any open graphs to get history from."
		return -1
	endif
	
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	string sGA1 = GetDimLabel(wMappingGrid,1,3)
	string sGA2 = GetDimLabel(wMappingGrid,1,4)
	string sLogBookName = sWindowName+"_DataHistory"
	string sWindowTitle = " History of data in "+sWindowName 
	killwindow/Z $sLogBookName
	newnotebook/O/Z/F=0/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sLogBookName/W=(10,10,610,810) as sWindowTitle
	string sTab = "\t"
	string sReturn = "\r"
	
	string sDataWave = GetUserData(sWindowName, "", "DataSource")
	string sHOrigins = GetUserData(sWindowName, "", "HOrigins")
	string sVOrigins = GetUserData(sWindowName, "", "VOrigins")
	string sCOrigins = GetUserData(sWindowName, "", "COrigins")
	string sSOrigins = GetUserData(sWindowName, "", "SOrigins")
	string sHErOrigins = GetUserData(sWindowName, "", "HErOrigins")
	string sVErOrigins = GetUserData(sWindowName, "", "VErOrigins")
	string sSampleRanges = GetUserData(sWindowName, "", "SampleRanges")
	string sGA1Ranges = GetUserData(sWindowName, "", "GA1Ranges")
	string sGA2Ranges = GetUserData(sWindowName, "", "GA2Ranges")
	string sVectorLengths = GetUserData(sWindowName, "", "VectorLengths")
	string sDataSourceStart = GetUserData(sWindowName, "", "DataSourceStart")
	string sDataSourceEnd = GetUserData(sWindowName, "", "DataSourceEnd")
	int iDataSet

	notebook $sLogBookName text= "Datawave: "+sDataWave+sReturn
	for(iDataSet=0;iDataSet<itemsInList(sSampleRanges);iDataSet+=1)
		notebook $sLogBookName text=sTab+ "Data set "+num2str(1+iDataSet)+sReturn
		notebook $sLogBookName text=sTab+ "Layer index: "+" : "+stringfromlist(iDataSet,sDataSourceStart)+" to "+stringfromlist(iDataSet,sDataSourceEnd)+sReturn
		notebook $sLogBookName text=sTab+ "Horizontal Data "+" : "+stringfromlist(iDataSet,sHOrigins)+sReturn
		notebook $sLogBookName text=sTab+ "Horizontal Error Data "+" : "+stringfromlist(iDataSet,sHErOrigins)+sReturn
		notebook $sLogBookName text=sTab+ "Vertical Data "+" : "+stringfromlist(iDataSet,sVOrigins)+sReturn
		notebook $sLogBookName text=sTab+ "Vertical Error Data "+" : "+stringfromlist(iDataSet,sVErOrigins)+sReturn
		notebook $sLogBookName text=sTab+ "Color Data "+" : "+stringfromlist(iDataSet,sCOrigins)+sReturn
		notebook $sLogBookName text=sTab+ "Size Data "+" : "+stringfromlist(iDataSet,sSOrigins)+sReturn
		notebook $sLogBookName text=sTab+ "Samples Range"+" : "+stringfromlist(iDataSet,sSampleRanges)+sReturn
		notebook $sLogBookName text=sTab+ sGA1+" Range "+" : "+stringfromlist(iDataSet,sGA1Ranges)+sReturn
		notebook $sLogBookName text=sTab+ sGA2+" Range "+" : "+stringfromlist(iDataSet,sGA2Ranges)+sReturn
		notebook $sLogBookName text=sTab+ "Vector Length "+" : "+stringfromlist(iDataSet,sVectorLengths)+sReturn
		notebook $sLogBookName text=sReturn
	endfor
	
end

Function COMBI_OffsetTraces()
	variable xoffs=0,yoffs=0,xDelta=0,yDelta=0
	string bAllTraces = "All", bAdd2OrNew = "Add"
	prompt xoffs,"x-offset (all traces equally):"
	prompt xDelta,"x delta (increases with trace #):"
	prompt yoffs,"y-offset (all traces equally):"
	prompt yDelta,"y delta (increases with trace #, decades for log plots):"
	prompt bAllTraces,"Offset traces:", popup, "All;One"
	prompt bAdd2OrNew,"If already fffset traces:", popup, "Add;New"
	string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	if(strlen(sWindowName)==0)
		DoAlert/T="No Plots?", 0, "COMBIgor cannot find any graphs to operate on."
		return -1
	endif
	string sHelpString ="The offset is applied to all traces, the delta is applied after multiplying my the trace number."
	DoPrompt/HELP=sHelpString "Define the offset", xoffs,xDelta,yoffs,yDelta, bAllTraces,bAdd2OrNew
	if (V_Flag)
		return -1 // User canceled
	endif
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		Print  "COMBI_OffsetPlotTraces("+num2str(xoffs)+","+num2str(xDelta)+","+num2str(yoffs)+","+num2str(yDelta)+",\""+bAllTraces+"\",\""+bAdd2OrNew+"\")"
	endif
	COMBI_OffsetPlotTraces(xoffs,xDelta,yoffs,yDelta,bAllTraces,bAdd2OrNew) 
	return-1
end

Function COMBI_OffsetPlotTraces(xoffs,xDelta,yoffs,yDelta,bAllTraces,bAdd2OrNew) 
	variable xoffs,xDelta,yoffs,yDelta
	string bAllTraces// "All" or "One"
	string bAdd2OrNew// "Add" or "New"

	silent 1; pauseupdate 
	//get top plot name
	string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	if(strlen(sWindowName)==0)
		DoAlert/T="No plot",0,"COMBIgor cannot find any active plots."
		return -1
	endif
	
	//all traces on plot
	string sAllTraces = TraceNameList(sWindowName,";",1)
	if(itemsinlist(sAllTraces)==0)
		DoAlert/T="No traces",0,"COMBIgor cannot find any traces on the plot named "+sWindowName+"."
		return -1
	endif
	
	//get single trace
	int iTrace, vTotalTraces
	if(stringmatch(bAllTraces,"One"))
		vTotalTraces = 1
		sAllTraces = COMBI_StringPrompt(stringfromlist(0,sAllTraces),"Trace to do offesets:",sAllTraces,"Pick the trace on which to operate.","Pick a trace!")
		if(stringmatch(sAllTraces,"CANCEL"))
			return -1
		endif
		xDelta = 0
		yDelta = 0
	else
		vTotalTraces = itemsinlist(sAllTraces)
	endif
	
	String expr="{([[:ascii:]]*),([[:ascii:]]*)}"
	string sXOffset2Start, sYOffset2Start 
	variable vThisXOffset, vThisYOffset, vThisOffsetStartY, vThisOffsetStartX
	for(iTrace=0;iTrace<vTotalTraces;iTrace+=1)
		//get trace information
		string sThisTrace = stringfromlist(iTrace,sAllTraces)
		string sTraceInformation = traceinfo(sWindowName,sThisTrace,0)
		//starting offset
		string sTraceOffset2Start = StringByKey("offset(x)",sTraceInformation,"=",";")
		SplitString/E=(expr) sTraceOffset2Start, sXOffset2Start, sYOffset2Start
		if(stringmatch("Add",bAdd2OrNew))
			vThisOffsetStartX = str2num(sXOffset2Start)
			vThisOffsetStartY = str2num(sYOffset2Start)
		else
			vThisOffsetStartX = 0
			vThisOffsetStartY = 0
		endif
		//is y-axis log?
		if(stringmatch("1",StringByKey("log(x)",AxisInfo(sWindowName,"left"),"=")))
			//apply ylog offset
			vThisYOffset = yoffs+(10^(yDelta*iTrace))+vThisOffsetStartY
			vThisXOffset = xoffs+xDelta*iTrace+vThisOffsetStartX
			ModifyGraph/W=$sWindowName muloffset($sThisTrace)={0,vThisYOffset}
			ModifyGraph/W=$sWindowName offset($sThisTrace)={vThisXOffset,0}
		else
			vThisYOffset = yoffs+yDelta*iTrace+vThisOffsetStartY
			vThisXOffset = xoffs+xDelta*iTrace+vThisOffsetStartX
			ModifyGraph/W=$sWindowName offset($sThisTrace)={vThisXOffset,vThisYOffset}
		endif
		
	endfor
	SetAxis/A
	return-1
end

Function COMBI_ColorTracesSelect(sOptions)
	string sOptions //"Default", "Choose", or a ColorScheme such as "Rainbow"
	string sColorTheme
	if(stringmatch("Choose",sOptions))
		sColorTheme = COMBI_StringPrompt("Rainbow","Color to use:",CTabList(),"I will color using this theme.","Choose coloring theme")
	elseif(stringmatch("Default",sOptions))
		sColorTheme = Combi_GetGlobalString("sColorTheme", "COMBIgor")
	else
		sColorTheme = sOptions
	endif 
	
	//get top plot name
	string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
	if(strlen(sWindowName)==0)
		DoAlert/T="No plot",0,"COMBIgor cannot find any active plots."
		return -1
	endif
	
	
	//all traces on plot
	string sAllTraces = TraceNameList(sWindowName,";",1)
	if(itemsinlist(sAllTraces)==0)
		DoAlert/T="No traces",0,"COMBIgor cannot find any traces on the plot named "+sWindowName+"."
		return -1
	endif
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		Print  "COMBI_ColorPlotTraces(\""+sColorTheme+"\")"
	endif
	COMBI_ColorPlotTraces(sColorTheme) 
	
end

Function COMBI_ColorPlotTraces(sColorTheme,[sPlotName]) 
	string sColorTheme
	string sPlotName
	

	colortab2wave $sColorTheme
	wave/i/u M_colors
	
	silent 1; pauseupdate 
	//get top plot name
	string sWindowName
	if(ParamIsDefault(sPlotName))
		sWindowName= Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
		if(strlen(sWindowName)==0)
			DoAlert/T="No plot",0,"COMBIgor cannot find any active plots."
			return -1
		endif
	else
		sWindowName = sPlotName
	endif
	
	
	//all traces on plot
	string sAllTraces = TraceNameList(sWindowName,";",1)
	if(itemsinlist(sAllTraces)==0)
		DoAlert/T="No traces",0,"COMBIgor cannot find any traces on the plot named "+sWindowName+"."
		return -1
	endif
	
	int vTotalTraces = itemsinlist(sAllTraces)
	variable vTraceInk=(dimsize(M_colors,0)-1)/(vTotalTraces)
	int iTrace, vTraceCount=0, iColor
	for(iTrace=0;iTrace<vTotalTraces;iTrace+=1)
		//get trace information
		string sThisTrace = stringfromlist(iTrace,sAllTraces)
		iColor = trunc(vTraceCount*vTraceInk)
		ModifyGraph/W=$sWindowName rgb($sThisTrace)=(M_colors[iColor][0],M_colors[iColor][1],M_colors[iColor][2])
		vTraceCount+=1
	endfor
	
	killwaves M_colors
	return-1
end


function/S COMBI_GetUniqueColor(vColor,vColors,[sColorTheme])
	int vColor // this unique color
	int vColors //total colors
	string sColorTheme
	if(paramIsDefault(sColorTheme))
		sColorTheme = "dBZ14"
	endif 
	ColorTab2Wave $sColorTheme
	wave wColorWave = M_colors
	deletePoints 6,1,wColorWave//delete yellow
	int vTotalColorsAvailable = dimsize(wColorWave,0)
	if(vColor>vTotalColorsAvailable)
		do
			vColor-=vTotalColorsAvailable
			vColors-=vTotalColorsAvailable
		while(vColors>vTotalColorsAvailable)
	endif
	int iThisColor = floor(((vColor/vColors)*vTotalColorsAvailable)-1)
	string sReturnColor = "("+num2str(wColorWave[iThisColor][0])+","+num2str(wColorWave[iThisColor][1])+","+num2str(wColorWave[iThisColor][2])+")"
	killwaves wColorWave
	return sReturnColor
end

//Append a hooked plot wave, columns matching length of sDataTypes
Function/S COMBI_Add2PlotWave(sProject,sLibrary,sDataTypes,sDims,iFirstSample,iLastSample,sPlotWave)
	string sProject//COMBIgor project
	string sLibrary//name of library, or "All" to include all libraries with that data
	string sDataTypes//name of data types
	string sDims //dims of data types
	int iFirstSample// first sample (0 indexed) to include, 0 for start
	int iLastSample// last sample (o indexed) to include, -1 for through end
	string sPlotWave //name of plot wave, "" if none exist and a new one is needed, "TOP" to try the top window for a plot wave
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Library Loop Control
	int iLibrary	 
	if(stringmatch(sLibrary,"All"))
		sLibrary = Combi_TableList(sProject,-3,"All","Libraries")
	endif
	
	//sample control
	int iSample
	if(iLastSample==-1)//all samples
		iLastSample = COMBI_GetGlobalNumber("vTotalSamples",sProject)-1
	endif
	
	//get dispaly wave from top plot if needed
	if(stringmatch(sPlotWave,"TOP"))//from top plot
		string sWindowName = Stringfromlist(0,WinList("*", ";","WIN:1"))//top most plot window
		string sDataWaveName = GetUserData(sWindowName, "", "DataSource")
		if(stringmatch(sDataWaveName,"root:Packages:COMBIgor:DisplayWaves:*"))
			sPlotWave = replaceString("root:Packages:COMBIgor:DisplayWaves:",sDataWaveName,"")
		endif
	endif
	
	//get wave
	if(!waveExists($"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave))//not existing, need new
		int vTotalPlotWaves = 0
		do
			vTotalPlotWaves+=1
			sPlotWave = "DisplayWave"+num2str(vTotalPlotWaves)
		while(waveexists($"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave))
		SetDataFolder root:Packages:COMBIgor:
		NewDataFolder/O/S DisplayWaves
		Make/N=(1,itemsinlist(sDataTypes)) $sPlotWave
		SetDataFolder $sTheCurrentUserFolder 
		wave wPlotWave = $"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave
	else
		wave wPlotWave = $"root:Packages:COMBIgor:DisplayWaves:"+sPlotWave
		//mismached columns and datatypes?
		if(dimsize(wPlotWave,1)!=itemsinlist(sDataTypes))
			DoAlert/T="Mismatched",0,"The number of data types COMBIgor is trying to append doesn't match the number already there. Append aborted."
			return ""
		endif
	endif
	int iStartRow = dimsize(wPlotWave,0)-1
	
	//loop controls and variables 
	int iDataType, iDim, iData
	string sTheLibrary, sTheDataType
	
	for(iLibrary=0;iLibrary<itemsinlist(sLibrary);iLibrary+=1)//Libraries
		for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)//SAmples
			sTheLibrary = stringfromlist(iLibrary,sLibrary)
			//needed rows?
			int vNeededRows = 1
			for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)//DataTypes
				sTheDataType = stringfromlist(iDataType,sDataTypes)
				iDim = str2num(stringfromlist(iDataType,sDims))
				if(iDim==2)//Vector
					int vVectorLength = dimSize($COMBI_DataPath(sProject,2)+sTheLibrary+":"+sTheDataType,1)
					if(vVectorLength>vNeededRows)
						vNeededRows = vVectorLength
					endif
				endif
			endfor
			//addnumber of rows
			redimension/N=(iStartRow+vNeededRows,-1) wPlotWave
			//add data
			for(iDataType=0;iDataType<itemsinlist(sDataTypes);iDataType+=1)//DataTypes
				sTheDataType = stringfromlist(iDataType,sDataTypes)
				iDim = str2num(stringfromlist(iDataType,sDims))
				if(iDim==0)//Vector
					wave wDataWave = $COMBI_DataPath(sProject,0)
					if(Combi_CheckForData(sProject,sTheLibrary,sTheDataType,iDim,iSample)==1)//data exist
						for(iData=0;iData<vNeededRows;iData+=1)
							wPlotWave[iStartRow+iData][iDataType] = wDataWave[%$sTheLibrary][%$sTheDataType]
						endfor
					else
						for(iData=0;iData<vNeededRows;iData+=1)
							wPlotWave[iStartRow+iData][iDataType] = nan
						endfor
					endif
				elseif(iDim==1)//Scalar
					wave wDataWave = $COMBI_DataPath(sProject,1)+sTheLibrary+":"+sTheDataType
					if(Combi_CheckForData(sProject,sTheLibrary,sTheDataType,iDim,iSample)==1)//data exist
						for(iData=0;iData<vNeededRows;iData+=1)
							wPlotWave[iStartRow+iData][iDataType] = wDataWave[iSample]
						endfor
					else
						for(iData=0;iData<vNeededRows;iData+=1)
							wPlotWave[iStartRow+iData][iDataType] = nan
						endfor
					endif
				elseif(iDim==2)//Vector
					wave wDataWave = $COMBI_DataPath(sProject,2)+sTheLibrary+":"+sTheDataType
					if(Combi_CheckForData(sProject,sTheLibrary,sTheDataType,iDim,iSample)==1&&vNeededRows==dimsize(wDataWave,1))//data exist and vector length matches length needed
						for(iData=0;iData<vNeededRows;iData+=1)
							wPlotWave[iStartRow+iData][iDataType] = wDataWave[iSample][iData]
						endfor
					else
						for(iData=0;iData<vNeededRows;iData+=1)
							wPlotWave[iStartRow+iData][iDataType] = nan
						endfor
					endif
				endif
			endfor
			//store sample information in note
			Note/NOCR wPlotWave sProject+";"+sTheLibrary+";"+replaceString(";",sDataTypes,"&")+";"+num2str(iSample)+";"+num2str(iStartRow)+";"+num2str(iStartRow+vNeededRows-1)+"$"
			//next time start from the current end
			iStartRow+=vNeededRows
		endfor
	endfor
	//store library information
	return sPlotWave
end

function COMBI_MappingGridPlot(sProject)
	string sProject
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	int nRows, xMin, xRangeInclusive, colorIndexWaveRow, iSample
	variable vLibraryWidth = Combi_GetGlobalNumber("vLibraryWidth", sProject)
	variable vLibraryHeight = Combi_GetGlobalNumber("vLibraryHeight", sProject)
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples", sProject)
	variable vH2WRatio=vLibraryHeight/vLibraryWidth
	variable vBoxYNeg = -1
	variable vBoxYPos = 1
	variable vBoxXNeg = -1
	variable vBoxXPos = 1
	
	variable vXDensity = itemsInList(COMBI_LibraryQualifiers(sProject,1))
	variable vYDensity = itemsInList(COMBI_LibraryQualifiers(sProject,2))
	variable vSphereDensity = (.9/max(vXDensity,vYDensity))
	
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	SetDataFolder $"root:COMBIgor:"+sProject+":"
	NewDataFolder/S/O Data
	NewDataFolder/S/O FromMappingGrid
	NewDataFolder/S/O MappingGridPlot
	
	Make/D/O/N=(vTotalSamples,3) Layer1,Layer2,Layer3,Layer4,Layer1C,Layer2C,Layer3C
	Make/D/O/N=(vTotalSamples,4) Layer1C,Layer2C,Layer3C
	Make/D/O/N=(vTotalSamples) Layer1Temp,Layer2Temp,Layer3Temp
	
	//grid axis labels
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	string sGA1 = GetDimLabel(wMappingGrid,1,3)
	string sGA2 = GetDimLabel(wMappingGrid,1,4)
	
	//coloring	
	ColorTab2Wave Rainbow
	Rename  $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:M_colors",Rainbow
	wave RainbowColors = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Rainbow"
	redimension/N=(-1,4) RainbowColors
	RainbowColors[][3] = 1
	
	wave Layer1 = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer1"
	wave Layer1C = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer1C"
	wave Layer1Temp = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer1Temp"
	wave Layer2 = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer2"
	wave Layer2C = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer2C"
	wave Layer2Temp = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer2Temp"
	wave Layer3 = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer3"
	wave Layer3C = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer3C"
	wave Layer3Temp = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer3Temp"
	wave Layer3 = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer3"
	wave Layer3C = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer3C"
	wave Layer3Temp = $"root:COMBIgor:"+sProject+":Data:FromMappingGrid:MappingGridPlot:Layer3Temp"	
	
	//axis direction
	int bXAxisFlip = COMBI_GetGlobalNumber("bXAxisFlip",sProject)
	int bYAxisFlip = COMBI_GetGlobalNumber("bYAxisFlip",sProject)
	
	Layer1[][1] = wMappingGrid[p][2]//y
	Layer2[][1] = wMappingGrid[p][2]//y
	Layer3[][1] = wMappingGrid[p][2]//y
	Layer1[][0] = wMappingGrid[p][1]//x
	Layer2[][0] = wMappingGrid[p][1]//x
	Layer3[][0] = wMappingGrid[p][1]//x
	Layer1[][2] = 1//z
	Layer2[][2] = 2//z
	Layer3[][2] = 3//z
	Layer1Temp[] = wMappingGrid[p][0]//color as sample
	Layer2Temp[] = wMappingGrid[p][3]//color as GA1
	Layer3Temp[] = wMappingGrid[p][4]//color as GA2
	
	//library info
	SetScale/I x, wavemin(Layer1Temp)*0.9,wavemax(Layer1Temp)*1.1, RainbowColors
	for(iSample=0;iSample<vTotalSamples;iSample+=1)		
		Layer1C[iSample][0] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][0]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][0]/65535
		Layer1C[iSample][1] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][0]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][1]/65535
		Layer1C[iSample][2] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][0]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][2]/65535
		Layer1C[iSample][3] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][0]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][3]
	endfor
	
	SetScale/I x, wavemin(Layer2Temp)*0.9,wavemax(Layer2Temp)*1.1, RainbowColors
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		Layer2C[iSample][0] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][3]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][0]/65535
		Layer2C[iSample][1] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][3]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][1]/65535
		Layer2C[iSample][2] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][3]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][2]/65535
		Layer2C[iSample][3] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][3]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][3]
	endfor
	
	SetScale/I x, wavemin(Layer3Temp)*0.9,wavemax(Layer3Temp)*1.1, RainbowColors
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		Layer3C[iSample][0] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][4]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][0]/65535
		Layer3C[iSample][1] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][4]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][1]/65535
		Layer3C[iSample][2] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][4]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][2]/65535
		Layer3C[iSample][3] = RainbowColors[floor(DimSize(RainbowColors,0)*(wMappingGrid[iSample][4]-DimOffset(RainbowColors,0))/((DimSize(RainbowColors,0)-1) * DimDelta(RainbowColors,0)))][3]
	endfor

	
	//3D gizmo
	Killwindow/Z $"MappingGripdPlot_"+sProject
	NewGizmo/N=$"MappingGripdPlot_"+sProject/T="Mapping Grid Plot"/K=1
	ModifyGizmo opName=translatedown, operation=translate,data={0,0,-0.45}
	if(bXAxisFlip==1)
		ModifyGizmo opName=inverting, operation=scale,data={-1,1,1}
	endif
	if(bYAxisFlip==1)
		ModifyGizmo opName=inverting, operation=scale,data={1,-1,1}
	endif
	ModifyGizmo opName=shaping, operation=scale,data={1,vH2WRatio,1}
	
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/N=$"MappingGripdPlot_"+sProject stopUpdates
	
	//Add scatters
	AppendToGizmo/Z/N=$"MappingGripdPlot_"+sProject defaultscatter=Layer1, name=Layer1
	AppendToGizmo/Z/N=$"MappingGripdPlot_"+sProject defaultscatter=Layer2, name=Layer2
	AppendToGizmo/Z/N=$"MappingGripdPlot_"+sProject defaultscatter=Layer3, name=Layer3
	
	//market object
	AppendToGizmo attribute shininess={42,42},name=shininess
	AppendToGizmo/Z/N=$"MappingGripdPlot_"+sProject sphere={vSphereDensity,10,10}, name=MarkerObject1
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyObject=MarkerObject1, objectType=Sphere, property={useGlobalAttributes,1}
	AppendToGizmo/Z/N=$"MappingGripdPlot_"+sProject sphere={vSphereDensity,10,10}, name=MarkerObject2
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyObject=MarkerObject2, objectType=Sphere, property={useGlobalAttributes,1}
	AppendToGizmo/Z/N=$"MappingGripdPlot_"+sProject sphere={vSphereDensity,10,10}, name=MarkerObject3
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyObject=MarkerObject3, objectType=Sphere, property={useGlobalAttributes,1}
	
	//add scatter color
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/Q modifyObject=Layer3, objectType=scatter,property={shape,7},property={size,1},property={scatterColorType,1},property={colorWave,Layer1C}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/Q modifyObject=Layer3, objectType=scatter,property={objectName,MarkerObject1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/Q modifyObject=Layer2, objectType=scatter,property={shape,7},property={size,1},property={scatterColorType,1},property={colorWave,Layer2C}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/Q modifyObject=Layer2, objectType=scatter,property={objectName,MarkerObject2}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/Q modifyObject=Layer1, objectType=scatter,property={shape,7},property={size,1},property={scatterColorType,1},property={colorWave,Layer3C}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject/Q modifyObject=Layer1, objectType=scatter,property={objectName,MarkerObject3}
	
	//change visable axis
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 0,visible,1}//x
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 1,visible,1}//y
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 2,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 3,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 4,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 5,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 6,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 7,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 8,visible,1}//x
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 9,visible,1}//y
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 10,visible,0}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 11,visible,0}
	
	//axis range and ticks
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={0, axisMinValue, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={0, axisMaxValue, vLibraryWidth }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={0, canonicalTick, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={0, canonicalIncrement, 5 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={1, axisMinValue, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={1, axisMaxValue, vLibraryHeight }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={1, canonicalTick, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={1, canonicalIncrement, 5 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 0,ticks,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 1,ticks,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={8, axisMinValue, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={8, axisMaxValue, vLibraryHeight }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={8, canonicalTick, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={8, canonicalIncrement, 5 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={9, axisMinValue, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={9, axisMaxValue, vLibraryWidth }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={9, canonicalTick, 0 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={9, canonicalIncrement, 5 }
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 8,ticks,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject ModifyObject=axes0,objectType=Axes,property={ 9,ticks,1}
	
	//axis range
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject setOuterBox={0,vLibraryWidth,0,vLibraryHeight,.5,4.5}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject scalingOption=0
	
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	//plane 1
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D quad={vBoxXPos,vBoxYPos,-.76,vBoxXPos,vBoxYNeg,-.76,vBoxXNeg,vBoxYNeg,-.76,vBoxXNeg,vBoxYPos,-.76},name=Plane1
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane1,objectType=quad,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane1,objectType=quad,property={colorValue,0,1,1,1,1}
	TextBox/C/N=P1/F=0/A=MC/X=40.00/Y=-31.00 "\\Z12\\F'"+sFont+"'"+sGA2
	//plane 2
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D quad={vBoxXPos,vBoxYPos,-.26,vBoxXPos,vBoxYNeg,-.26,vBoxXNeg,vBoxYNeg,-.26,vBoxXNeg,vBoxYPos,-.26},name=Plane2
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane2,objectType=quad,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane2,objectType=quad,property={colorValue,0,1,1,1,1}
	TextBox/C/N=P2/F=0/A=MC/X=40.00/Y=-19.00 "\\Z12\\F'"+sFont+"'"+sGA1
	//plane 3
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D quad={vBoxXPos,vBoxYPos,.24,vBoxXPos,vBoxYNeg,.24,vBoxXNeg,vBoxYNeg,.24,vBoxXNeg,vBoxYPos,.24},name=Plane3
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane3,objectType=quad,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane3,objectType=quad,property={colorValue,0,1,1,1,1}
	TextBox/C/N=P3/F=0/A=MC/X=40.00/Y=-7 "\\Z12\\F'"+sFont+"'Sample #"

		
	//lines for plane 1
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXPos,vBoxYPos,-.76,vBoxXPos,vBoxYNeg,-.76},name=Plane11
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane11,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane11,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXPos,vBoxYNeg,-.76,vBoxXNeg,vBoxYNeg,-.76},name=Plane12
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane12,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane12,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXNeg,vBoxYNeg,-.76,vBoxXNeg,vBoxYPos,-.76},name=Plane13
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane13,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane13,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXNeg,vBoxYPos,-.76,vBoxXPos,vBoxYPos,-.76},name=Plane14
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane14,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane14,objectType=line,property={colorValue,0,0,0,0,1}
	//lines for plane 2
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXPos,vBoxYPos,-.26,vBoxXPos,vBoxYNeg,-.26},name=Plane21
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane21,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane21,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXPos,vBoxYNeg,-.26,vBoxXNeg,vBoxYNeg,-.26},name=Plane22
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane22,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane22,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXNeg,vBoxYNeg,-.26,vBoxXNeg,vBoxYPos,-.26},name=Plane23
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane23,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane23,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXNeg,vBoxYPos,-.26,vBoxXPos,vBoxYPos,-.26},name=Plane24
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane24,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane24,objectType=line,property={colorValue,0,0,0,0,1}
	//lines for plane 3
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXPos,vBoxYPos,.24,vBoxXPos,vBoxYNeg,.24},name=Plane31
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane31,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane31,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXPos,vBoxYNeg,.24,vBoxXNeg,vBoxYNeg,.24},name=Plane32
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane32,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane32,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXNeg,vBoxYNeg,.24,vBoxXNeg,vBoxYPos,.24},name=Plane33
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane33,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane33,objectType=line,property={colorValue,0,0,0,0,1}
	AppendToGizmo/N=$"MappingGripdPlot_"+sProject/D line={vBoxXNeg,vBoxYPos,.24,vBoxXPos,vBoxYPos,.24},name=Plane34
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane34,objectType=line,property={colorType,1}
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject modifyobject=Plane34,objectType=line,property={colorValue,0,0,0,0,1}
	
	
	//box axis
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,gridType,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,ticks,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 1,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,tickScaling,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 1,tickScaling,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,fontScaleFactor,0.9}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 1,fontScaleFactor,0.9}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={0,fontName,sFont}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={1,fontName,sFont}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 1,tickEnable,0,vLibraryHeight}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,tickEnable,0,vLibraryWidth}
	
	
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 8,gridType,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 8,ticks,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 9,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 8,tickScaling,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 9,tickScaling,2}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 8,fontScaleFactor,0.9}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 9,fontScaleFactor,0.9}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={8,fontName,sFont}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={9,fontName,sFont}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 8,tickEnable,0,vLibraryHeight}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 9,tickEnable,0,vLibraryWidth}

	//axis labels
	TextBox/C/N=XAxis/F=0/A=MC/B=1/X=30.00/Y=-45.00 "\\Z12\\F'"+sFont+"'x(mm)"
	TextBox/C/N=YAxis/F=0/A=MC/B=1/X=-30.00/Y=-45 "\\Z12\\F'"+sFont+"'y(mm)"

	SetDataFolder $sTheCurrentUserFolder 
	
	ModifyGizmo/N=$"MappingGripdPlot_"+sProject resumeUpdate
	
	//color scales
	ColorScale/C/N=SampleScale/F=0/A=MC/X=-20/Y=30 width=10,height=150, ctab={wavemin(Layer1Temp),wavemax(Layer1Temp),Rainbow,0},font=sFont,fsize=12,tickLen=0.00
	ColorScale/C/N=SampleScale "Sample #"
	ColorScale/C/N=GA1Scale/F=0/A=MC/X=0/Y=30 width=10,height=150, ctab={wavemin(Layer2Temp),wavemax(Layer2Temp),Rainbow,0},font=sFont,fsize=12,tickLen=0.00
	ColorScale/C/N=GA1Scale sGA1
	ColorScale/C/N=GA2Scale/F=0/A=MC/X=20/Y=30 width=10,height=150, ctab={wavemin(Layer3Temp),wavemax(Layer3Temp),Rainbow,0},font=sFont,fsize=12,tickLen=0.00
	ColorScale/C/N=GA2Scale sGA2
	
	Killwaves/Z RainbowColors, Layer1Temp,Layer2Temp,Layer3Temp,Layer4Temp
	
end

function COMBIDisplay_SetLabel(ctrlName) : ButtonControl
	String ctrlName
	String sProject = COMBIDisplay_GetString("sProject","COMBIgor")
	string sDataType = COMBI_DataTypePrompt(sProject,"Select data","Data type to set label for:",0,0,0,-2)
	if(stringmatch(sDataType,"CANCEL"))
		return -1
	endif
	string sNewLabel = COMBIDisplay_GetAxisLabel(sDataType)
	sNewLabel = COMBI_StringPrompt(sNewLabel,"Label for "+sDataType+":","","This is the label give to plot axes with this data type name.","Define Plot Axis Label")
	if(stringmatch(sNewLabel,"CANCEL"))
		return -1
	endif
	COMBIDisplay_Global(sDataType,sNewLabel,"Label")
end

function/S COMBIDisplay_GetAxisLabel(sDataType)
	string sDataType
	string sLabel = COMBIDisplay_GetString(sDataType,"Label")
	if(stringmatch(sLabel,"NAG")||stringmatch(sLabel,""))
		sLabel = sDataType
	endif
	if(stringmatch(sDataType,sLabel))
		if(strsearch(sDataType, ":", 0)>=0)
			int iLastColon = strsearch(sDataType,":",inf,1)
			sLabel = sDataType[(iLastColon+1),(strlen(sDataType)-1)]
		endif
	endif	
	return sLabel
end


function COMBI_UpdateGlobalBool(ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	COMBIDisplay_Global(ctrlName,num2str(checked),"COMBIgor")
end

//function for making a "plot new" plot window, returns name of plot window actually made
function/S Combi_NewPlot(sWindowName)
	string sWindowName //name for new window 
	string sFontOption = Combi_GetGlobalString("sFontOption","COMBIgor")
	string sWindowTitle = sWindowName
	sWindowName = cleanupName(sWindowName,0)
	if(strlen(sWindowName)>25)
		sWindowName = ReplaceString("_",sWindowName,"")
	endif
	if(strlen(sWindowName)>25)
		sWindowName = ReplaceString("a",sWindowName,"")
	endif
	if(strlen(sWindowName)>25)
		sWindowName = ReplaceString("e",sWindowName,"")
	endif
	if(strlen(sWindowName)>25)
		sWindowName = ReplaceString("i",sWindowName,"")
	endif
	if(strlen(sWindowName)>25)
		sWindowName = ReplaceString("o",sWindowName,"")
	endif
	if(strlen(sWindowName)>25)
		sWindowName = ReplaceString("u",sWindowName,"")
	endif	
	if(strlen(sWindowName)>25)
		sWindowName = sWindowName[0,23]
	endif	
	
	string sTheRightName
	if(itemsinlist(WinList(sWindowName,";",""))>0)
		int iIndex = 1
		do
			sTheRightName = sWindowName + num2str(iIndex)
			iIndex+=1
		while(itemsinlist(WinList(sTheRightName,";",""))>0)
	else
		sTheRightName = sWindowName
	endif
	display/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sTheRightName as sWindowTitle
	ModifyGraph gFont=sFontOption
	ModifyGraph width=400,height=200,gfSize=12
	ModifyGraph width=0,height=0
	return S_name
end

//function for making a "plot new" plot window, returns name of plot window actually made
function/S Combi_NewGizmo(sWindowName)
	string sWindowName //name for new window 
	string sFontOption = Combi_GetGlobalString("sFontOption","COMBIgor")
	sWindowName = cleanupName(sWindowName,0)
	string sTheRightName
	if(itemsinlist(WinList(sWindowName,";",""))>0)
		int iIndex = 1
		do
			sTheRightName = sWindowName + num2str(iIndex)
			iIndex+=1
		while(itemsinlist(WinList(sTheRightName,";",""))>0)
	else
		sTheRightName = sWindowName
	endif
	
	NewGizmo/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sTheRightName
	return S_name
end

