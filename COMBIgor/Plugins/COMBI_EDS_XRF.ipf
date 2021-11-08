#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Dylan Bardgett, July 2019: Original drafting of procedures

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// Name of Plugin
Static StrConstant sPluginName = "EDS_XRF"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// This builds the drop-down menu for this plugin
Menu "COMBIgor"
	SubMenu "Plugins"
		 "EDS_XRF",/Q, COMBI_EDS_XRF()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// This function is run when the user selects the Plugin from the COMBIgor drop down menu once activated.
// This will build the plugin panel that the user interacts with.
function COMBI_EDS_XRF()

	// name for plugin panel
	string sWindowName=sPluginName+"_Panel"
	
	// check if initialized, get starting values if so, initialize if not
	string sInstrument // Instrument used to gather the data
	string sProject //project to operate within
	string sLibrary//Library to operate on
	string sData // Data to operate on

	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")))
		// not yet initialized
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_ChooseProject(),"COMBIgor")//get project to start with
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")//get project to use in this function
	else
		// previously initialized
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")//get the previously used project
	endif
	
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sProject)))//if first time for this project, initialize values
		COMBI_GivePluginGlobal(sPluginName,"sInstrument","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData","",sProject)
	endif
	
	// get values of globals to use in this function, mainly panel building
	sInstrument = COMBI_GetPluginString(sPluginName,"sInstrument",sProject)
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sData = COMBI_GetPluginString(sPluginName,"sData",sProject)
	
	// get the globals wave for use in panel building, mainly set varaible controls
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_Globals
	
	NewDataFolder/O root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves
	
	string sDataName = sProject+"_"+sLibrary
	string sSupplementalWavePath = "root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:"+sDataName+":"
	COMBI_GivePluginGlobal(sPluginName,"sSupplementalWavePath",sSupplementalWavePath,sProject)
	
	 
	// make panel position if old existed
	// kill if open already
	variable vWinLeft = 10
	variable vWinTop = 10
	string sAllWindows = WinList(sWindowName,";","")
	if(strlen(sAllWindows)>1)
		GetWindow/Z $sWindowName wsize
		vWinLeft = V_left
		vWinTop = V_top
		KillWindow/Z $sWindowName
	endif
	
	// dimensions of panel
	variable vPanelHeight = 300
	variable vPanelWidth = 325
 
	// make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = "Courier"
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "COMBIgor EDS XRF"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	variable vYValue = 15
	
	// This is the section of the function that generates the appropriate buttons and prompts within the plugin window
	
	// Instrument select
	DrawText 90,vYValue, "Instrument:"
	PopupMenu sInstrument,pos={215,vYValue-10},mode=1,bodyWidth=170,value="BrukerM4XRF;FischerXRF",proc=EDS_XRF_UpdateGlobal,popvalue=sInstrument
	vYValue+=20
	// Project select
	DrawText 90,vYValue, "Project:"
	PopupMenu sProject,pos={215,vYValue-10},mode=1,bodyWidth=170,value=COMBI_Projects(),proc=EDS_XRF_UpdateGlobal,popvalue=sProject
	vYValue+=20
	// Library select
	DrawText 90,vYValue, "Library:"
	PopupMenu sLibrary,pos={215,vYValue-10},mode=1,bodyWidth=170,value=EDS_XRF_DropList("Libraries"),proc=EDS_XRF_UpdateGlobal,popvalue=sLibrary
	vYValue+=20
	// Data select
	DrawText 90,vYValue, "Data:"
	PopupMenu sData,pos={215,vYValue-10},mode=1,bodyWidth=170,value=EDS_XRF_DropList("DataTypes"),proc=EDS_XRF_UpdateGlobal,popvalue=sData
	vYValue+=40
	// Create the IntegrationLimits Wave interface
	DrawText 235,vYValue, "IntegrationLimits Wave:"
	vYValue+=10
	// Plot Load IntegrationLimits button
	button bLoadIntegrationLimits,title="Load",appearance={native,All},pos={55,vYValue},size={45,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	// Plot Append to IntegrationLimits button
	button bAppendToIntegrationLimits,title="Edit",appearance={native,All},pos={135,vYValue},size={45,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	// Plot Save IntegrationLimits button
	button bSaveIntegrationLimits,title="Save",appearance={native,All},pos={215,vYValue},size={45,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=40
	// Create the Calibration interface
	DrawText 215,vYValue, "Calibration Wave:"
	vYValue+=10
	// Plot load Calibration button
	button bLoadCalibration,title="Load",appearance={native,All},pos={55,vYValue},size={45,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	// Plot Edit Calibration button
	button bEditCalibration,title="Edit",appearance={native,All},pos={135,vYValue},size={45,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	// Plot Save Calibration button
	button bSaveCalibration,title="Save",appearance={native,All},pos={215,vYValue},size={45,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=40
	// Plot Raw Intensity button
	button bMakeGizmo,title="Plot Raw Intensity",appearance={native,All},pos={45,vYValue},size={225,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=20
	// Plot load background button
	button bLoadBackground,title="Load Background Spectrum",appearance={native,All},pos={45,vYValue},size={225,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=20
	// Plot Quantify Composition button
	button bQuantifyComposition,title="Quantify Composition",appearance={native,All},pos={45,vYValue},size={225,20},proc=EDS_XRF_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14

end


// This function will update the globals when a drop-down is updated on the panel
Function EDS_XRF_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName//name of control, should be also name of global being updated
	Variable popNum//number in list
	String popStr //value selected
	if(stringmatch("sProject",ctrlName))
		// special place for the project
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	else 
		// store the global in based on the name of the control sending it
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	// reload panel
	COMBI_EDS_XRF()
	
end


// This function is used to grab the info from the project to return in the pop-up menu
Function/S EDS_XRF_DropList(sOption)
	string sOption//what type of list to return in the popup menu
	
	// get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	
	// for various options of drop list
	if(stringmatch(sOption,"Libraries"))//list of libraries 
		return Combi_TableList(sProject,1,"All","Libraries")
	elseif(stringmatch(sOption,"DataTypes"))//list of vector data for the select library (iDimension=2)
		return Combi_TableList(sProject,2,sLibrary,"DataTypes")
	endif
end


// This function handles the back end of the button on the panel, and calls the corresponding
// function that actually does something
Function EDS_XRF_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	
	//g et global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	string sData = COMBI_GetPluginString(sPluginName,"sData",sProject)
	string sInstrument = COMBI_GetPluginString(sPluginName,"sInstrument",sProject)
	
	if(stringmatch("bMakeGizmo",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		EDS_XRF_MakeGizmo(sProject,sLibrary,sData,sInstrument)
	endif
	
	if(stringmatch("bQuantifyComposition",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		EDS_XRF_QuantifyComposition(sProject,sLibrary,sData,sInstrument)
	endif
	
	if(stringmatch("bLoadIntegrationLimits",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		LoadIntegrationLimits(sProject,sLibrary)
	endif
	
	if(stringmatch("bAppendToIntegrationLimits",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		AppendToIntegrationLimits(sProject,sLibrary)
	endif
	
	if(stringmatch("bSaveIntegrationLimits",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		SaveIntegrationLimits(sProject,sLibrary)
	endif

	if(stringmatch("bLoadBackground",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		LoadBackground(sProject,sLibrary)
	endif
	
	if(stringmatch("bLoadCalibration",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		LoadCalibration(sProject,sLibrary)
	endif

	if(stringmatch("bEditCalibration",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		EditCalibration(sProject,sLibrary)
	endif

	if(stringmatch("bSaveCalibration",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		// pass to programatic function
		SaveCalibration(sProject,sLibrary)
	endif

end


// A quick and simple function to plot the raw spectra as a function of sample number in an easy to see gizmo
function EDS_XRF_MakeGizmo(sProject,sLibrary,sData,sInstrument)
	string sProject, sLibrary, sData, sInstrument
	string dPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sData
	string Name = sData+"_Gizmo"
	variable vNumSamples = DimSize($dPath,0)
	variable vInitialEnergy = -0.9548
	string sCurrentUserFolder = GetDataFolder(1)
	NewGizmo/N=$Name
	modifyGizmo/Z showaxisCue=1
	AppendToGizmo DefaultSurface= $dPath
	setscale/p y,vInitialEnergy,0.01,"", $dPath
	AppendToGizmo/N=$Name Axes=BoxAxes, name=axes1
	ModifyGizmo/N=$Name ModifyObject=axes1, objectType=Axes, property={4,ticks,3}
	ModifyGizmo/N=$Name ModifyObject=axes1, objectType=Axes, property={8,ticks,3}
	ModifyGizmo/N=$Name ModifyObject=axes1, objectType=Axes, property={9,ticks,3}
	ModifyGizmo/N=$Name setOuterBox={0,vNumSamples,0,25,0,50000}
	ModifyGizmo/N=$Name scalingOption=0
	
	SetDataFolder $sCurrentUserFolder
end


// This function calculates the integrated intensity for each emission line indicated by the user
// Inputs:
//		sProject: the project indicated by the user containing the relevant data and libraries
//		sLibrary: the library containing the relevant data
//		sData: the signal intensity data (y-axis) 
// Returns:
//		waves of the form Element_EmissionLine_Counts containing the integrated intensity of the specified emission
//			line for each sample in sData
//		if "plot on loading" is turned on, this function will also generate combi maps 
//			displaying the elemental intensity for each element
function EDS_XRF_QuantifyComposition(sProject,sLibrary,sData,sInstrument)
	// initialize variables
	string sProject, sLibrary, sData, sInstrument
	// set necessary file paths
	string dPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sData
	string libPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":"
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	string sCurrentUserFolder = GetDataFolder(1)
	setDataFolder $libPath
	variable vInitialEnergy = -0.9548
	string sIntegrationLimits = sSupplementalWavePath+"IntegrationLimits"
	wave IntegrationLimits = $sIntegrationLimits
	
	// initiate an iterable to parse through the emission lines
	variable iterElements = 0
	// generate the list of possible emission lines from the properly labeled IntegrationLimits wave
	string sEmissionList = ""
	for (iterElements=0;iterElements<(dimsize(IntegrationLimits,0));iterElements+=1)
		sEmissionList += GetDimLabel(IntegrationLimits,0,iterElements)+";"
	endfor
	

	wave dataWaves = $dPath
	// select the wave providing the background spectrum from the SupplementalWaves folder
	string sBackground = sSupplementalWavePath+"Background0"
	wave backgroundWave = $sBackground
	setscale/p x,vInitialEnergy,0.01,"", backgroundWave
	
	// create a matrix of identical dimension as the dataWave to hold the background waves
	duplicate/o dataWaves backgroundWaves
	
	string sBGSWaveName = sData+"_BGS"
	duplicate/o dataWaves $sBGSWaveName
	wave BGSWave = $sBGSWaveName
	setscale/p y,vInitialEnergy,0.01,"", dataWaves, backgroundWaves, BGSWave
	
	// set each row in backgroundWaves to be identical to the background wave
	backgroundWaves = 0
	backgroundWaves[0][] = backgroundWave[q]
	backgroundWaves[][] = backgroundWaves[0][q]
	
	// subtract the background
	BGSWave -= backgroundWaves
	
	// prompt user for which elements to measure
	variable numElements
	prompt numElements, "Number of elements?"
	doprompt "How many elements would you like to measure?", numElements
	if(V_flag==1)
	return -1
	endif	
	string thisElement, sUsedEmissionLineList = ""

	// create a matrix to hold all of the counts waves
	// (this step is redundant because the intensities for each emission line will be stored in their own waves anyways)
	string sCountsWaveName = sData+"_Counts"
	make/N=(dimsize(dataWaves,0),numElements)/o $sCountsWaveName
	wave elementalCounts = $sCountsWaveName

	// iterate through each emission line and find the integrated intensity
	variable iWave
	for (iterElements=0; iterElements<numElements; iterElements+=1)
		prompt thisElement, "Which Emission Line?", POPUP, sEmissionList
		doprompt "Which emission line would you like to measure?", thisElement
		if(V_flag==1)
			return -1
		endif	
		
		sEmissionList = RemoveListItem(WhichListItem(thisElement,sEmissionList),sEmissionList)
		sUsedEmissionLineList += thisElement+"_Counts;"
		setDimLabel 1,iterElements,$thisElement,elementalCounts
		
		string thisElementWaveName = thisElement+"_Counts"
		make/N=(dimsize(dataWaves,0))/o $thisElementWaveName
		wave thisElementWave = $thisElementWaveName
		
		// iterate through each sample
		for (iWave=0; iWave<(dimsize(dataWaves,0)); iWave+=1)
			string sampleName = "Sample_"+num2str(iWave)
			setDimLabel 0,iWave,$sampleName,elementalCounts
			make/N=(dimsize(BGSWave,1))/o thisTempWave
			thisTempWave = BGSWave[iWave][p]
			setscale/p x,vInitialEnergy,0.01,"", thisTempWave
			// integrate BGSWave to find the area under the curve of a given emission line
			setDataFolder $libPath
			elementalCounts[iWave][iterElements] = BGSInt(sProject,thisTempWave,thisElement)
		endfor
		
		// create a dedicated wave to store the integrated intensity of this emission line for each sample spectrum
		thisElementWave = elementalCounts[p][iterElements]
		
	endfor
	
	// get rid of any waves that are no longer necessary
	killwaves/Z thisTempWave, $libPath+"backgroundWaves"
	
	// if plot on loading
	// generate combi maps displaying the elemental intensity for each element
	int iEmissionLine
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		for(iEmissionLine=0;iEmissionLine<itemsinlist(sUsedEmissionLineList);iEmissionLine+=1)
			string sTheEmissionLine = stringfromlist(iEmissionLine,sUsedEmissionLineList)
			COMBIDisplay_Map(sProject,sLibrary,sTheEmissionLine,"Linear","Rainbow","","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",19,"000000")
		endfor
	endif
	
	DoUpdate
	
	string cont = "Yes"
	prompt cont "Compute relative intensities?", POPUP, "Yes;No"
	DoPrompt "Would you like to compute relative intensities?", cont
	if(V_flag==1)
		return -1
	endif	
	
	if (stringmatch(cont,"No")==1)
		return -1
	endif
	
	// create an iterable to parse through this element and that element
	variable iTopElement = 0, iBottomElement = 0
	string sTopElement = "", sBottomElement = ""
	string sRelativeIntensityList = ""
	for (iTopElement=0;iTopElement<numElements-1;iTopElement+=1)
		for (iBottomElement=iTopElement+1;iBottomElement<numElements;iBottomElement+=1)
			SetDataFolder $libPath
			sTopElement = StringFromList(iTopElement,sUsedEmissionLineList)
			sBottomElement = StringFromList(iBottomElement,sUsedEmissionLineList)
			string sThisRelativeWaveName = sTopElement+"_Per_"+sBottomElement
			make/N=(dimSize(dataWaves,0))/o $sThisRelativeWaveName
			wave relativeIntensity = $sThisRelativeWaveName
			string sTopString = sTopElement, sBottomString = sBottomElement
			wave wTopWave = $sTopString, wBottomWave = $sBottomString
			relativeIntensity = wTopWave / wBottomWave
			sRelativeIntensityList += sThisRelativeWaveName+";"
		endfor
	endfor
	
	
	// if plot on loading
	// generate combi maps displaying the relative emission line intensity for each element
	int iRelativeIntensity
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		for(iRelativeIntensity=0;iRelativeIntensity<itemsinlist(sRelativeIntensityList);iRelativeIntensity+=1)
			string sThisRelativeIntensity = stringfromlist(iRelativeIntensity,sRelativeIntensityList)
			COMBIDisplay_Map(sProject,sLibrary,sThisRelativeIntensity,"Linear","Rainbow","","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",19,"000000")
		endfor
	endif
	
	DoUpdate
	
	prompt cont, "Use calibration?", POPUP, "Yes;No"
	DoPrompt "Do you have a relative intensity calibration you would like to use?", cont
	if(V_flag==1)
		return -1
	endif	

	if (StringMatch(cont,"No")==1)
		return -1
	endif
	
	SetDataFolder $libPath
	variable calibrationSlope
	string sCalibratedIntensityList
	for (iRelativeIntensity=0;iRelativeIntensity<itemsinList(sRelativeIntensityList);iRelativeIntensity+=1)
//		prompt calibrationSlope, "Calibration for "+StringFromList(iRelativeIntensity,sRelativeIntensityList)
//		DoPrompt "Please provide the proportionality constant for each ratio of elements.", calibrationSlope
//		
		// some rather complicated code stripping the lengthy wave names into just "sThisEmissionLine" per "sThatEmissionLine"
		sThisRelativeWaveName = stringfromlist(iRelativeIntensity,sRelativeIntensityList)
		wave relativeIntensity = $sThisRelativeWaveName
		string sThisLine = RemoveListItem(1, sThisRelativeWaveName,"_Per_")
		sThisLine = RemoveFromList("Counts_Per_",sThisLine,"_")
		// store the name of this emission line to call from the calibration file
		string sThisEmissionLine = RemoveEnding(sThisLine,"_")
		sThisLine = RemoveListItem(1,sThisLine,"_")
		sThisLine = RemoveEnding(sThisLine,"_")
		string sThatLine = RemoveListItem(0, sThisRelativeWaveName,"_Per_")
		sThatLine = RemoveFromList("Counts_Per_",sThatLine,"_")
		// store the name of that emission line to call from the calibration file
		string sThatEmissionLine = RemoveEnding(sThatLine,"_")
		sThatline = RemoveListItem(1,sThatLine,"_")
		sThatLine = RemoveEnding(sThatLine,"_")
		
		string sCalibrationPath = sSupplementalWavePath+"Calibration"
		wave Calibration = $sCalibrationPath
		calibrationSlope = Calibration[%$sThatEmissionLine][%$sThisEmissionLine]
		
		// now start
		string sThisCalibratedWave = sThisLine+"Per"+sThatLine
		duplicate/o relativeIntensity $sThisCalibratedWave
		wave wCalibratedWave = $sThisCalibratedWave
		wCalibratedWave = relativeIntensity / calibrationSlope
		// if plot on loading
		// generate combi maps displaying the calibrated relative emission line intensity for each element
		if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
			COMBIDisplay_Map(sProject,sLibrary,sThisCalibratedWave,"Linear","Rainbow","","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",19,"000000")
		endif
	endfor
	
	setDataFolder $sCurrentUserFolder
	
	DoUpdate
	
end


// This function uses the trapezoidal rule to measure the area under the curve BGSWave between two endpoints stored in the 
// IntegrationLimits matrix
// Inputs:
//		sProject: a string containing the name of the current project
//		BGSWave: the wave to be integrated
//		sEmissionLine: the emission line of the form Element_EmissionLine (for example: Sn_La)
//		IntegrationLimits: a nx2 global wave providing the start and end points for integration, with the rows 
//			labeled by their corresponding emission lines
function BGSInt(sProject,BGSWave,sEmissionLine)
	wave BGSWave
	string sEmissionLine,sProject
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	string sIntegrationLimitsPath = sSupplementalWavePath+"IntegrationLimits"
	wave IntegrationLimits = $sIntegrationLimitsPath
	
	string sCurrentUserFolder = GetDataFolder(1)
	// grab the limits of integration from the IntegrationLimits wave using the appropriate Element_EmissionLine index
	variable A = IntegrationLimits[%$sEmissionLine][0]
	variable B = IntegrationLimits[%$sEmissionLine][1]
	
	// get area under curve
	variable vAuC = area(BGSWave,A,B)
	return vAuC
end


// A function to load the IntegrationLimits wave into the appropriate COMBI_EDS_XRF_SupplementalWaves folder
// Inputs:
//		sProject, sLibrary: strings containing the relevant project and library, respectively
//		IntegrationLimits: an Igor binary matrix whose rows are indexed by emission lines and whose columns are the 
//			upper and lower bounds of integration for the given line
function LoadIntegrationLimits(sProject,sLibrary)
	string sProject, sLibrary
	string sCurrentUserFolder = GetDataFolder(1)
	string sDataName = sProject+"_"+sLibrary
	string dPath = "root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:"+sDataName
	NewDataFolder/O/S $dPath
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	setDataFolder $sSupplementalWavePath
	LoadWave /O/N=IntegrationLimits
	setDataFolder $sCurrentUserFolder
end


// A function to save the IntegrationLimits wave into the library
// Inputs:
//		sProject, sLibrary: strings containing the relevant project and library, respectively
//		IntegrationLimits: an Igor binary matrix whose rows are indexed by emission lines and whose columns are the 
//			upper and lower bounds of integration for the given line
function SaveIntegrationLimits(sProject,sLibrary)
	string sProject, sLibrary
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	string sCurrentUserFolder = GetDataFolder(1)
	setDataFolder $sSupplementalWavePath
	string sParametersWaveName = "IntegrationLimits"
	if (WaveExists($sParametersWaveName)==1)
		wave IntegrationLimits = IntegrationLimits
		Save/C/I/O IntegrationLimits as "IntegrationLimits.ibw"
	elseif (WaveExists($sParametersWaveName)==0)
		DoAlert/T="The IntegrationLimits wave does not exist.", 0, "Please import or create an IntegrationLimits wave first."
		SetDataFolder $sCurrentUserFolder
		return -1
	endif
	setDataFolder $sCurrentUserFolder
end


// A function to append to the IntegrationLimits matrix
// NOTE: If an IntegrationLimits wave is not already loaded into the library, this function will
// create and populate a new one
// Inputs:
//		sProject, sLibrary: strings telling Igor where to look for the IntegrationLimits wave to populate
//
// Returns:
// 	adds a new row to the bottom of the IntegrationLimits containing the integration limits for the given line
function AppendToIntegrationLimits(sProject,sLibrary)
	string sProject, sLibrary
	string libPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":"
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	string sCurrentUserFolder = GetDataFolder(1)
	variable vLower, vUpper// A and B are the limitations of integration for the given emission line
	setDataFolder $sSupplementalWavePath
	wave IntegrationLimits = IntegrationLimits
	variable newRowIndex = dimsize(IntegrationLimits,0)-1
	
	// prompt user for the emission line to add
	string sEmissionLine
	prompt sEmissionLine, "Choose an emission line (eg. Sn_La)"
	DoPrompt/HELP="Please insert the element followed by an underscore and the Seigbahn notiation for the emission line you are interested in." "Which emission line would you like to add?", sEmissionLine
	if (V_flag==1)
		setDataFolder $sCurrentUserFolder
		return -1
	endif
	
	// prompt user for option to collect limits of integration directly or by placing points on a graph
	string option = ""
	prompt option, "Graphically or textually?", POPUP, "Graphically;Textually"
	DoPrompt "Would you like to select the cursors with a graph or directly with text?", option
	if (V_flag==1)
		setDataFolder $sCurrentUserFolder
		return -1
	endif
	
	// if textually, have the user input the integration limits
	if (stringMatch(option,"Textually")==1)
		prompt vLower, "Lower limit"
		prompt vUpper, "Upper limit"
		DoPrompt "Enter the upper and lower energy limits of integration for the "+sEmissionLine+" emission line.", vLower, vUpper
		if (V_flag==1)
			setDataFolder $sCurrentUserFolder
			return-1
		endif
		
		Redimension/N=(newRowIndex+1,2) IntegrationLimits
		setDimLabel 0,newRowIndex,$sEmissionLine,IntegrationLimits
	
		IntegrationLimits[newRowIndex][0] = vLower
		IntegrationLimits[newRowIndex][1] = vUpper
		
	endif
	
	// if graphically, the user has two choices: provide a single sample wave to plot or
	// provide a COMBI library containing a matrix of several sample waves
	if (stringMatch(option,"Graphically")==1)
		string sSampleWave
		SetDataFolder $libPath
		prompt sSampleWave,"Representative Wave?",POPUP,WaveList("*",";","")
		DoPrompt "Which wave would you like to use to set the integration limits?", sSampleWave
		if (V_flag==1)
			setDataFolder $sCurrentUserFolder
			return -1
		endif

		
		// if provided a single sample wave
		if (DimSize($sSampleWave,1)==0)
			// adjust the scaling of the wave and begin building a graph window
			setscale/p x,-0.9548,0.01,"", $sSampleWave
			string sGraphName = "Representative_wave_"+sSampleWave
			Display/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sGraphName $sSampleWave
			ModifyGraph/W=$sGraphName minor=1, rgb=(0,0,0), expand=1.5
			Label/W=$sGraphName left "\\Z10 Intensity / a.u." 
			Label/W=$sGraphName bottom "\\Z10 Energy / keV"
			Legend/C/N=text0/F=0/A=LT/X=60.00/Y=5
			ShowInfo/W=$sGraphName 
			DoUpdate/W=$sGraphName
			
			//make panel position if old existed
			//kill if open already
			string sWindowName = "Cursor_Window"
			variable vWinLeft = 0
			variable vWinTop = 0
			string sAllWindows = WinList(sWindowName,";","")
			if(strlen(sAllWindows)>1)
				GetWindow/Z $sWindowName wsize
				vWinLeft = V_left
				vWinTop = V_top
				KillWindow/Z $sWindowName
			endif
			
			//dimensions of panel
			variable vPanelHeight = 200
			variable vPanelWidth = 350
		 
			// make a subwindow to attach to the side of the graph window
			PauseUpdate; Silent 1 // pause for building window...
			string sFont = "Courier"
			NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/HOST=$sGraphName/EXT=0/N=$sWindowName as "Cursor Window"
			SetDrawLayer/W=$sWindowName UserBack
			SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 1,textyjust = 0, fsize = 12, origin = 0,0, xcoord=rel, ycoord=rel, save
			DrawText/W=$sWindowName 0.5,0.125, "Place cursors A and B at the"
			SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 1,textyjust = 0, fsize = 12, origin = 0,0, xcoord=rel, ycoord=rel, save
			SetDrawLayer/W=$sWindowName UserBack
			DrawText/W=$sWindowName 0.5,0.20, "desired limits of integration"
			SetDrawLayer/W=$sWindowName UserBack
			DrawText/W=$sWindowName 0.5,0.375, "Adjust the position of the cursors"
			DrawText/W=$sWindowName 0.5,0.45, "and press continue"
			button bGrabCursors,title="continue",appearance={native,All},pos={125,92.5},size={100,20},proc=Grab_Cursors_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			DrawText/W=$sWindowName 0.5,0.75, "To plot expected energies of emission edges,"
			DrawText/W=$sWindowName 0.5,0.825, "press \"NIST References\""
			button bNISTReferences,title="NIST References",appearance={native,All},pos={115,170},size={120,20},proc=NISTReference_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			
			// create a temporary wave containing the necessary parameters to be called again by the GrabCursors, "continue", button
			// inputs to tempGrabCursorsWave:
			//		sProject, sLibrary, sGraph, sEmissionLine
			setDataFolder root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:
			make/o/N=4/T tempGrabCursorsWave
			
			tempGrabCursorsWave[0] = sProject
			setDimLabel 0,0,CurrentProject, tempGrabCursorsWave
			tempGrabCursorsWave[1] = sLibrary
			setDimLabel 0,1,CurrentLibrary, tempGrabCursorsWave
			tempGrabCursorsWave[2] = sEmissionLine
			setDimLabel 0,2,EmissionLine, tempGrabCursorsWave
			tempGrabCursorsWave[3] = sGraphName
			setDimLabel 0,3,GraphName, tempGrabCursorsWave

		// if provided a COMBI library of waves
		elseif (DimSize($sSampleWave,1)>0)
			variable vMaxSamples = DimSize($sSampleWave,0)
			string sSampleNumber = "", sSampleList = ""
			
			// count the number of samples in the COMBI library
			variable iterSamples = 0
			for (iterSamples=0;iterSamples<vMaxSamples;iterSamples+=1)
				sSampleList+=num2str(iterSamples)+";"
			endfor
			
			// prompt the user to choose a representative spectrum from the COMBI library
			prompt sSampleNumber, "Sample number?" , POPUP, sSampleList
			string sHelpString = "It looks like you've selected a wave containing an array of samples. Please select one to represent your dataset."
			DoPrompt/HELP=sHelpString "Choose which sample to use to represent your dataset", sSampleNumber
			if (V_flag==1)
				return -1
			endif
			
			// adjust the scaling of the wave and begin building a graph window
			setscale/p y,-0.9548,0.01,"", $sSampleWave
			sGraphName = "Representative_wave_"+sSampleWave+"_"+sSampleNumber
			Display/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/N=$sGraphName $sSampleWave[str2num(sSampleNumber)][]
			ModifyGraph/W=$sGraphName minor=1, rgb=(0,0,0), expand = 1.5
			Label/W=$sGraphName left "\\Z10 Intensity / a.u." 
			Label/W=$sGraphName bottom "\\Z10 Energy / keV"
			Legend/C/N=text0/F=0/A=LT/X=60.00/Y=5
			ShowInfo/W=$sGraphName 
			DoUpdate/W=$sGraphName
			
			//make panel position if old existed
			//kill if open already
			sWindowName = "Cursor_Window"
			vWinLeft = 0
			vWinTop = 0
			sAllWindows = WinList(sWindowName,";","")
			if(strlen(sAllWindows)>1)
				GetWindow/Z $sWindowName wsize
				vWinLeft = V_left
				vWinTop = V_top
				KillWindow/Z $sWindowName
			endif
			
			//dimensions of panel
			vPanelHeight = 200
			vPanelWidth = 350
		 
			// make a subwindow to attach to the side of the graph window
			PauseUpdate; Silent 1 // pause for building window...
			sFont = "Courier"
			NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/HOST=$sGraphName/EXT=0/N=$sWindowName as "Cursor Window"
			SetDrawLayer/W=$sWindowName UserBack
			SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 1,textyjust = 0, fsize = 12, origin = 0,0, xcoord=rel, ycoord=rel, save
			DrawText/W=$sWindowName 0.5,0.125, "Place cursors A and B at the"
			SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 1,textyjust = 0, fsize = 12, origin = 0,0, xcoord=rel, ycoord=rel, save
			SetDrawLayer/W=$sWindowName UserBack
			DrawText/W=$sWindowName 0.5,0.20, "desired limits of integration"
			SetDrawLayer/W=$sWindowName UserBack
			DrawText/W=$sWindowName 0.5,0.375, "Adjust the position of the cursors"
			DrawText/W=$sWindowName 0.5,0.45, "and press continue"
			button bGrabCursors,title="continue",appearance={native,All},pos={125,92.5},size={100,20},proc=Grab_Cursors_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			DrawText/W=$sWindowName 0.5,0.75, "To plot expected energies of emission edges,"
			DrawText/W=$sWindowName 0.5,0.825, "press \"NIST References\""
			button bNISTReferences,title="NIST References",appearance={native,All},pos={115,170},size={120,20},proc=NISTReference_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12

			// create a temporary wave containing the necessary parameters to be called again by the GrabCursors, "continue", button
			// inputs to tempGrabCursorsWave:
			//		sProject, sLibrary, sGraph, sEmissionLine
			setDataFolder root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:
			make/o/N=4/T tempGrabCursorsWave
			
			tempGrabCursorsWave[0] = sProject
			setDimLabel 0,0,CurrentProject, tempGrabCursorsWave
			tempGrabCursorsWave[1] = sLibrary
			setDimLabel 0,1,CurrentLibrary, tempGrabCursorsWave
			tempGrabCursorsWave[2] = sEmissionLine
			setDimLabel 0,2,EmissionLine, tempGrabCursorsWave
			tempGrabCursorsWave[3] = sGraphName
			setDimLabel 0,3,GraphName, tempGrabCursorsWave
		endif
	endif
	setDataFolder $sCurrentUserFolder
end


// A button control to collect the x value of each cursor, A and B, and appends it to the
// IntegrationLimits wave under the index given by sEmissionLine
// inputs:
//		taken from the tempGetCursorsWave:
//			sProject, sLibrary: the COMBIgor project and library to operate within
//			sEmissionLine: the emission line to add to the IntegrationLimits wave
//			sGraphName: the name of the graph to grab the cursors from
// returns:
//		an additional row added to the bottom of the IntegrationLimits wave containing the emission
//		line and the lower and upper limits of integration, given by cursors A and B, respectively
Function Grab_Cursors_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	// call the tempGrabCursors wave to recover the input parameters
	wave/T tempGrabCursorsWave = root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:tempGrabCursorsWave
	string sProject = tempGrabCursorsWave[%CurrentProject], sLibrary = tempGrabCursorsWave[%CurrentLibrary], sEmissionLine = tempGrabCursorsWave[%EmissionLine], sGraphName = tempGrabCursorsWave[%GraphName]
	string libPath = "root:COMBIgor:"+sProject+":Data:"+sLibrary
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	
	variable vLower, vUpper
	string sCurrentUserFolder = GetDataFolder(1)
	setDataFolder $sSupplementalWavePath
	
	wave IntegrationLimits = IntegrationLimits
	if (waveExists(IntegrationLimits)==0)
			make/N=(0,2) IntegrationLimits
			setDimLabel 1,0,CursorA,IntegrationLimits
			setDimLabel 1,1,CursorB,IntegrationLimits
	endif
	
	// check if the button is pressed
	if(stringmatch("bGrabCursors",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif
		
		// collect the x-values of the A (lower) and B (upper) cursors
		vLower = xcsr(A)
		vUpper = xcsr(B)
		
		// add a new row to the IntegrationLimits wave and label it with sEmissionLine
		variable newRowIndex = dimsize(IntegrationLimits,0)
		Redimension/N=(newRowIndex+1,2) IntegrationLimits
		setDimLabel 0,newRowIndex,$sEmissionLine,IntegrationLimits
		// add the upper and lower limits of integration
		IntegrationLimits[newRowIndex][0] = vLower
		IntegrationLimits[newRowIndex][1] = vUpper
		
	endif
	
	// reset and return to original state
	KillWaves/Z tempGrabCursorsWave
	killWindow/Z $sGraphName
	setDataFolder $sCurrentUserFolder
end


// A quick and handy function to convert a text wave containing into a string list
// inputs:
//		wListWave: the wave to be converted into a list
// returns:
//		sListName: a string containing a list of the elements in the text wave wListWave
function/T ListWaveToList(wListWave)
	wave/T wListWave
	string sListName = ""
	variable iText
	for (iText=0; iText<DimSize(wListWave,0); iText+=1)
		sListName += wListWave[iText]+";"
	endfor
	return sListName
end


// A button control that locates and plots the X-ray emission edges of a  given element
// inputs:
//		prompted:
//			sThisElement: the element to be plotted
//			sThisLine: a standard emission line written in Seigbahn notation
// returns:
//		Vertical line or lines plotted on the uppermost graph corresponding to 
//		the element_emission line of interest
function NISTReference_Button(ctrlName) : ButtonControl
	string ctrlName //name of button
	
	// check if the button is pressed
	if(stringmatch("bNISTReferences",ctrlName))
		if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		endif

		// get user's current folder to return to
		string sCurrentUserFolder = GetDataFolder(1)
		
		// set the data folder to COMBIgor to hold a subfolder called "xRayLineEnergies"
		setDataFolder root:Packages:COMBIgor:Plugins:
		
	 	// select file path containing loader procedures if there is none stored
	 	string sCOMBIgorFolderPath = COMBI_GetGlobalString("sCOMBIgorFolderPath","COMBIgor")
	 	
	 	// create an import path to import the NIST Emission Line Data
	 	newPath/Q/O/Z pXrayLinePath sCOMBIgorFolderPath+"Plugins:Xray_Emission_Lines"
	 	
	 	// if the folder doesn't already exist, make and populate it
	 	if (DataFolderExists("xRayLineEnergies")==0)
		 	NewDataFolder/O/S xRayLineEnergies
		 	loadWave/P=pXrayLinePath/N=At_Num "At_Num.ibw"
		 	loadWave/P=pXrayLinePath/N=Element "Element.ibw"
		 	loadWave/P=pXrayLinePath/N=Ka1 "Ka1.ibw"
		 	loadWave/P=pXrayLinePath/N=Ka2 "Ka2.ibw"
			loadWave/P=pXrayLinePath/N=Kb1 "Kb1.ibw"
			loadWave/P=pXrayLinePath/N=La1 "La1.ibw"
			loadWave/P=pXrayLinePath/N=La2 "La2.ibw"
			loadWave/P=pXrayLinePath/N=Lb1 "Lb1.ibw"
			loadWave/P=pXrayLinePath/N=Lb2 "Lb2.ibw"
			loadWave/P=pXrayLinePath/N=Lg1 "Lg1.ibw"
			loadWave/P=pXrayLinePath/N=Ma1 "Ma1.ibw"
			loadWave/P=pXrayLinePath/N=xRayLineList "xRayLineList.ibw"
		endif
		
		// create path reference and get globals
		DFREF dPath = root:Packages:COMBIgor:Plugins:xRayLineEnergies:
		wave/T wElementList = dPath:Element
		wave/T wXRayLineList = dPath:xRayLineList
	
		string sElementList = ListWaveToList(wElementList), sLineList = ListWaveToList(wXRayLineList)
	
		// create local variables and prompts
		string sThisElement, sThisLine, sThisGraph, sGraphList = WinList("*",";","WIN:1")
		variable vWidthPos = 0.001, vWidthNeg = 0.001, vThisEnergy
		prompt sThisElement, "Which element?"
		prompt sThisLine, "Which X-ray line?", POPUP, sLineList
		prompt sThisGraph, "Which graph?", POPUP, "Top;" + sGraphList	
		doprompt "Pick element to add to plot", sThisElement, sThisLine, sThisGraph
		if(V_flag==1)
			SetDataFolder $sCurrentUserFolder
			return -1
		endif	
	
		// get wave index for selected element (indices consistent between waves and element string list)
		int iElementIndex = WhichListItem(sThisElement, sElementList)
		
		// get the graph window selected by user
		if(stringmatch(sThisGraph,"Top"))
			sThisGraph = WinName(0,1)
		endif	
		// name for new wave
		string sNewWaveName = sThisElement + "_" + sThisLine
		
	
		// prepare graph and kill wave if it already exists
		// note - there is a subtle bug where if the wave has been used elsewhere it cannot be killed. Don't have a good workaround for now.
		DoWindow/F $sThisGraph
		RemoveFromGraph/Z $sNewWaveName
		// thought - could check if wave exists and then iterate name if it does instead of killing, also letting user know
		killwaves/Z dPath:$sNewWaveName
			
		// create and populate wave based on the chosen element, lines, and widths	
		strswitch(sThisLine)	
			case "All":
				// get needed waves
				wave/SDFR=dPath Ka1, Ka2, Kb1, La1, La2, Lb1, Lb2, Lg1, Ma1
				make/N=(36,2)/o dPath:$sNewWaveName					
				wave wLineEnergies = dPath:$sNewWaveName
				wLineEnergies[0,1][0] = Ka1[iElementIndex] - vWidthNeg
				wLineEnergies[2,3][0] = 	Ka1[iElementIndex] + vWidthPos
				wLineEnergies[4,5][0] = Ka2[iElementIndex] - vWidthNeg
				wLineEnergies[6,7][0] = 	Ka2[iElementIndex] + vWidthPos
				wLineEnergies[8,9][0] = Kb1[iElementIndex] - vWidthNeg
				wLineEnergies[10,11][0] = Kb1[iElementIndex] + vWidthPos			
				wLineEnergies[12,13][0] = La1[iElementIndex] - vWidthNeg
				wLineEnergies[14,15][0] = 	La1[iElementIndex] + vWidthPos
				wLineEnergies[16,17][0] = La2[iElementIndex] - vWidthNeg
				wLineEnergies[18,19][0] = 	La2[iElementIndex] + vWidthPos
				wLineEnergies[20,21][0] = Lb1[iElementIndex] - vWidthNeg
				wLineEnergies[22,23][0] = Lb1[iElementIndex] + vWidthPos
				wLineEnergies[24,25][0] = Lb2[iElementIndex] - vWidthNeg
				wLineEnergies[26,27][0] = Lb2[iElementIndex] + vWidthPos
				wLineEnergies[28,29][0] = Lg1[iElementIndex] - vWidthNeg
				wLineEnergies[30,31][0] = Lg1[iElementIndex] + vWidthPos
				wLineEnergies[32,33][0] = Ma1[iElementIndex] + vWidthNeg
				wLineEnergies[34,35][0] = Ma1[iElementIndex] + vWidthPos			
				wLineEnergies[][1] = 0
				wLineEnergies[1,2][1] = 1
				wLineEnergies[5,6][1] = 1
				wLineEnergies[9,10][1] = 1
				wLineEnergies[13,14][1] = 1
				wLineEnergies[17,18][1] = 1
				wLineEnergies[21,22][1] = 1
				wLineEnergies[25,26][1] = 1
				wLineEnergies[29,30][1] = 1
				wLineEnergies[33,34][1] = 1
			break
			case "All_K":
				// get needed waves
				wave/SDFR=dPath Ka1, Ka2, Kb1	
				make/N=(12,2)/o dPath:$sNewWaveName					
				wave wLineEnergies = dPath:$sNewWaveName
				wLineEnergies[0,1][0] = Ka1[iElementIndex] - vWidthNeg
				wLineEnergies[2,3][0] = 	Ka1[iElementIndex] + vWidthPos
				wLineEnergies[4,5][0] = Ka2[iElementIndex] - vWidthNeg
				wLineEnergies[6,7][0] = 	Ka2[iElementIndex] + vWidthPos
				wLineEnergies[8,9][0] = Kb1[iElementIndex] - vWidthNeg
				wLineEnergies[10,11][0] = Kb1[iElementIndex] + vWidthPos						
				wLineEnergies[][1] = 0
				wLineEnergies[1,2][1] = 1
				wLineEnergies[5,6][1] = 1
				wLineEnergies[9,10][1] = 1
			break
			case "All_L":
				// get needed waves
				wave/SDFR=dPath La1, La2, Lb1, Lb2, Lg1
				make/N=(20,2)/o dPath:$sNewWaveName					
				wave wLineEnergies = dPath:$sNewWaveName
				wLineEnergies[0,1][0] = La1[iElementIndex] - vWidthNeg
				wLineEnergies[2,3][0] = 	La1[iElementIndex] + vWidthPos
				wLineEnergies[4,5][0] = La2[iElementIndex] - vWidthNeg
				wLineEnergies[6,7][0] = 	La2[iElementIndex] + vWidthPos
				wLineEnergies[8,9][0] = Lb1[iElementIndex] - vWidthNeg
				wLineEnergies[10,11][0] = Lb1[iElementIndex] + vWidthPos
				wLineEnergies[12,13][0] = Lb2[iElementIndex] - vWidthNeg
				wLineEnergies[14,15][0] = Lb2[iElementIndex] + vWidthPos
				wLineEnergies[16,17][0] = Lg1[iElementIndex] - vWidthNeg
				wLineEnergies[18,19][0] = Lg1[iElementIndex] + vWidthPos						
				wLineEnergies[][1] = 0
				wLineEnergies[1,2][1] = 1
				wLineEnergies[5,6][1] = 1
				wLineEnergies[9,10][1] = 1
				wLineEnergies[13,14][1] = 1
				wLineEnergies[16,18][1] = 1
			break
			default: // only a single transition line
				// get needed waves
				wave wThisLine = dPath:$sThisLine
				vThisEnergy = wThisLine[iElementIndex]
				
				make/N=(4,2)/o dPath:$sNewWaveName					
				wave wLineEnergies = dPath:$sNewWaveName
				wLineEnergies[0,1][0] = vThisEnergy - vWidthNeg
				wLineEnergies[2,3][0] = 	vThisEnergy + vWidthPos
				wLineEnergies[][1] = 0
				wLineEnergies[1,2][1] = 1
		endswitch
		
		// import the color text wave to use for coloring each emission line base on atomic number
		ColorTab2Wave Rainbow
		wave M_colors = M_colors
		
		// append these emission lines to the top graph
		AppendToGraph/L=Left_Overlay dPath:$sNewWaveName[][1] vs dPath:$sNewWaveName[][0]
		ReorderTraces _back_, {$sNewWaveName}
		ModifyGraph tick(Left_Overlay)=3,noLabel(Left_Overlay)=2,freePos(Left_Overlay)={0,kwFraction},axRGB(Left_Overlay)=(0,0,0,0),tlblRGB(Left_Overlay)=(0,0,0,0),alblRGB(Left_Overlay)=(0,0,0,0);DelayUpdate
		SetAxis Left_Overlay 0.1,0.9
		ModifyGraph mode($sNewWaveName)=7,hbFill($sNewWaveName)=4,rgb($sNewWaveName)=(M_colors[iElementIndex][0],M_colors[iElementIndex][1],M_colors[iElementIndex][2],63000)
		
		// clear uneccesary waves and reset
		KillWaves M_colors
		setDataFolder $sCurrentUserFolder
	endif
end

function LoadBackground(sProject, sLibrary)
	string sProject, sLibrary
	string sCurrentUserFolder = GetDataFolder(1)
	// get global import folder
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	
	string sDataName = sProject+"_"+sLibrary
	string dPath = "root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:"+sDataName
	NewDataFolder/O/S $dPath
	
	// if there's an import folder, use it
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		//load from the input file to FileIn
		LoadWave /P=pUserPath /A=Background /G /L={20,21,0,1,1} //the parameters in L are specific to the Bruker M4 Tornado ".txt" output files
	// if there isn't an import folder, get a folder
	else
		LoadWave /A=Background /G /L={20,21,0,1,1}
	endif
	
	setDataFolder $sCurrentUserFolder
end

// A button to load a calibration file (see user manual for a description of acceptable files)
// Inputs:
//		sProject, sLibrary: the current user project and library
// Returns:
//		Calibration: a wave containing the proportionality factors converting XRF relative intensities into 
//			relative composition. This wave will be saved into the Supplemental Wave Path in the plugins folder
function LoadCalibration(sProject, sLibrary)
	string sProject, sLibrary
	string sCurrentUserFolder = GetDataFolder(1)
	string sDataName = sProject+"_"+sLibrary
	string dPath = "root:Packages:COMBIgor:Plugins:COMBI_EDS_XRF_SupplementalWaves:"+sDataName
	NewDataFolder/O/S $dPath
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	setDataFolder $sSupplementalWavePath
	LoadWave /N=Calibration
	setDataFolder $sCurrentUserFolder
end

// A function to save the Calibration wave into the library
// Inputs:
//		sProject, sLibrary: strings containing the relevant project and library, respectively
function SaveCalibration(sProject,sLibrary)
	string sProject, sLibrary
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	string sCurrentUserFolder = GetDataFolder(1)
	setDataFolder $sSupplementalWavePath
	string sCalibrationName = "Calibration"
	if (WaveExists($sCalibrationName)==1)
		wave Calibration = Calibration
		Save/C/I/O Calibration as "Calibration.ibw"
	elseif (WaveExists($sCalibrationName)==0)
		DoAlert/T="The Calibration wave does not exist.", 0, "Please import or create a Calibration wave first."
		SetDataFolder $sCurrentUserFolder
		return -1
	endif
	setDataFolder $sCurrentUserFolder
end

function EditCalibration(sProject,sLibrary)
	string sProject, sLibrary
	string sSupplementalWavePath = COMBI_GetPluginString(sPluginName,"sSupplementalWavePath",sProject)
	string sCurrentUserFolder = GetDataFolder(1)
	setDataFolder $sSupplementalWavePath
	
	string sCalibrationName = "Calibration"
	if (WaveExists($sCalibrationName)==1)
		wave Calibration = Calibration
	elseif (WaveExists($sCalibrationName)==0)
		DoAlert/T="The Calibration wave does not exist.", 0, "Please import or create a Calibration wave first."
		SetDataFolder $sCurrentUserFolder
		return -1
	endif
	
	variable vNumEmissionLines = DimSize(Calibration,0)
	
	string sIntegrationLimits = "IntegrationLimits"
	if (WaveExists($sIntegrationLimits)==1)
		wave IntegrationLimits = IntegrationLimits
	elseif (WaveExists($sIntegrationLimits)==0)
		DoAlert/T="The IntegrationLimits wave does not exist.", 0, "Please import or create an IntegrationLimits wave first."
		SetDataFolder $sCurrentUserFolder
		return -1
	endif
	
	string sEmissionLineList = ""
	variable iEmissionLine
	for (iEmissionLine=0;iEmissionLine<DimSize(IntegrationLimits,0);iEmissionLine+=1)
		sEmissionLineList+=GetDimLabel(IntegrationLimits,0,iEmissionLine)+";"
	endfor
	
	string sThisEmissionLine = "", sThatEmissionLine = ""
	variable vCalibrationRatio
	prompt sThisEmissionLine, "Numerating Emission Line?", POPUP, sEmissionLineList
	sEmissionLineList = RemoveListItem(WhichListItem(sThisEmissionLine,sEmissionLineList),sEmissionLineList)
	prompt sThatEmissionLine, "Denominating Emission Line?", POPUP, sEmissionLineList
	string sCalibrationPrompt = "Numerator per denominator calibration constant?"
	prompt vCalibrationRatio, sCalibrationPrompt
	DoPrompt "Select each emission line to be used in the calibration.", sThisEmissionLine, sThatEmissionLine, vCalibrationRatio
	
	// If the numerating emission line exists
	if (FindDimLabel(Calibration,1,sThisEmissionLine)!=-2)
		// If the denominating emission also line exists
		if (FindDimLabel(Calibration,0,sThatEmissionLine)!=-2)
			Calibration[%$sThatEmissionLine][%$sThisEmissionLine] = vCalibrationRatio
		// If the numerating emission line exists, but the denominating emission line doesn't exist
		elseif (FindDimLabel(Calibration,0,sThatEmissionLine)==-2)
			Redimension/N=(vNumEmissionLines+1,vNumEmissionLines+1) Calibration
			SetDimLabel 0,vNumEmissionLines,$sThatEmissionLine,Calibration
			SetDimLabel 1,vNumEmissionLines,$sThatEmissionLine,Calibration
			Calibration[%$sThatEmissionLine][%$sThisEmissionLine] = vCalibrationRatio
			Calibration[%$sThisEmissionLine][%$sThatEmissionLine] = 1/vCalibrationRatio
			Calibration[%$sThatEmissionLine][%$sThatEmissionLine] = 1
		endif
	// If the numerating emission line doesn't exist
	elseif (FindDimLabel(Calibration,1,sThisEmissionLine)==-2)
		// If the numerating emission line doesn't exist, but the denominating emission line does
		if (FindDimLabel(Calibration,0,sThatEmissionLine)!=-2)
			Redimension/N=(vNumEmissionLines+1,vNumEmissionLines+1) Calibration
			SetDimLabel 0,vNumEmissionLines,$sThisEmissionLine,Calibration
			SetDimLabel 1,vNumEmissionLines,$sThisEmissionLine,Calibration
			Calibration[%$sThatEmissionLine][%$sThisEmissionLine] = vCalibrationRatio
			Calibration[%$sThisEmissionLine][%$sThatEmissionLine] = 1/vCalibrationRatio
			Calibration[%$sThisEmissionLine][%$sThisEmissionLine] = 1
		// If neither the numerating nor the denominating emission lines already exist
		elseif (FindDimLabel(Calibration,0,sThatEmissionLine)==-2)
			Redimension/N=(vNumEmissionLines+2,vNumEmissionLines+2) Calibration
			SetDimLabel 0, vNumEmissionLines,$sThisEmissionLine,Calibration
			SetDimLabel 1, vNumEmissionLines,$sThisEmissionLine,Calibration
			SetDimLabel 0, vNumEmissionLines+1,$sThatEmissionLine,Calibration
			SetDimLabel 1, vNumEmissionLines+1,$sThatEmissionLine,Calibration
			Calibration[%$sThatEmissionLine][%$sThisEmissionLine] = vCalibrationRatio
			Calibration[%$sThisEmissionLine][%$sThatEmissionLine] = 1/vCalibrationRatio			
			Calibration[%$sThisEmissionLine][%$sThisEmissionLine] = 1
			Calibration[%$sThatEmissionLine][%$sThatEmissionLine] = 1
		endif
	endif
	setDataFolder $sCurrentUserFolder	
end
