#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original BackgroundRemove 
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
Static StrConstant sPluginName = "BackgroundRemove"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Plugins"
		 "Background Removal",/Q, Combi_BackgroundRemove()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this function will be executed when the user selects to define the Plugin in the Plugin definition panel
function BackgroundRemove_InitialDefine(sProject)
	string sProject
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	//get number of Library Samples in this project 
	variable vTotalSamples=Combi_GetGlobalNumber("vTotalSamples",sProject)
	
	//declare variables for each of the definition values
	string sBKGLibrary
	string sSignal
	string sSubtractedSignal
	string sBKG
	variable vFirstSample
	variable vLastSample
	
	//not previously defined, start with default values 
	sBKGLibrary = "Library Name"
	sSignal = "Signal Name"
	sBKG = "Background Name"
	sSubtractedSignal = "New Data Name"
	vFirstSample = 1
	vLastSample = vTotalSamples
	//make folder at project level for holding references
	setdatafolder $"root:COMBIgor:"+sProject
	newdatafolder/O Masks
	newdatafolder/O Backgrounds
	SetDataFolder $sTheCurrentUserFolder 
	Combi_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)
	
	//mark as defined by storing project name in sProject for this project
	Combi_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)// store global
	Combi_GivePluginGlobal(sPluginName,"sBKGLibrary",sBKGLibrary,sProject)// store Plugin global 
	Combi_GivePluginGlobal(sPluginName,"sSignal",sSignal,sProject)// store Plugin global 
	Combi_GivePluginGlobal(sPluginName,"sBKG",sBKG,sProject)// store Plugin global 
	Combi_GivePluginGlobal(sPluginName,"sSubtractedSignal",sSubtractedSignal,sProject)// store Plugin global 
	Combi_GivePluginGlobal(sPluginName,"vFirstSample",num2str(vFirstSample),sProject)// store Plugin global 
	Combi_GivePluginGlobal(sPluginName,"vLastSample",num2str(vLastSample),sProject)// store Plugin global 
	Combi_GiveGlobal("sBKGRemoveProject",sProject,"COMBIgor")

	
end

//this function will be executed when the user selects to Plugin in the drop down
function Combi_BackgroundRemove()
	//get Plugin name and project name
	string sProject = Combi_GetGlobalString("sBKGRemoveProject","COMBIgor")
	if(stringmatch(sProject,"NAG"))//Plugin unused
		sProject = Combi_ChooseProject()
		Combi_GivePluginGlobal(sPluginName,"sProject",sProject,"COMBIgor")
		Combi_GiveGlobal("sBKGRemoveProject",sProject,"COMBIgor")
		BackgroundRemove_InitialDefine(sProject)
	else
		if(!stringmatch(sProject,Combi_GetPluginString(sPluginName,"sProject",sProject)))//ew to the Plugin
			Combi_GivePluginGlobal(sPluginName,"sProject",sProject,"COMBIgor")
			Combi_GiveGlobal("sBKGRemoveProject",sProject,"COMBIgor")
			BackgroundRemove_InitialDefine(sProject)
		else
			Combi_GivePluginGlobal(sPluginName,"sProject",sProject,"COMBIgor")
		endif
	endif
	
	//get Plugin globals
	string sBKGLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	string sSignal = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sBKG = Combi_GetPluginString(sPluginName,"sBKG",sProject)
	string sSubtractedSignal = Combi_GetPluginString(sPluginName,"sSubtractedSignal",sProject)
	int vFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)
	int vLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)
	
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z BackgroundRemovePanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z BackgroundRemovePanel
	
	//Check if initialized, do if not
	Combi_PluginReady(sPluginName)
	
	//get global wave
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:Combi_"+sPluginName+"_Globals"
	
	//panel building options
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	//to get initial values for popups
	variable bNewProject = 1
	variable vSampleMin,vSampleMax
		
	//make panel
	NewPanel/K=(Combi_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+400,vWinTop+260)/N=BackgroundRemovePanel as "Background Removal Plugins"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont
	SetDrawEnv textxjust = 2,textyjust = 1
	SetDrawEnv fsize = 12
	SetDrawEnv save
	variable vYValue = 15
	
	//Project Row
	SetDrawEnv textrot = 0; SetDrawEnv save; DrawText 175,vYValue, "COMBIgor project:"
	PopupMenu sProject,pos={320,vYValue-10},mode=1,bodyWidth=190,value=Combi_Projects(),proc=BackgroundRemove_UpdateGlobal
	SetVariable sProjectF, title=" ",pos={180,vYValue-10},size={175,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sProject][%$sProject]
	vYValue+=25
	
	//background subtraction fields
	DrawText 125,vYValue, "Library:"
	PopupMenu sBKGLibrary,pos={270,vYValue-10},mode=1,bodyWidth=190,value=BackgroundRemove_DropList("S"),proc=BackgroundRemove_UpdateGlobal
	SetVariable sBKGLibraryF, title=" ",pos={130,vYValue-10},size={175,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sBKGLibrary][%$sProject]
	vYValue+=25
	DrawText 125,vYValue, "Signal:"
	PopupMenu sSignal,pos={270,vYValue-10},mode=1,bodyWidth=190,value=BackgroundRemove_DropList("D"),proc=BackgroundRemove_UpdateGlobal
	SetVariable sSignalF, title=" ",pos={130,vYValue-10},size={175,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sSignal][%$sProject]
	vYValue+=25
	DrawText 125,vYValue, "Background:"
	PopupMenu sBKG,pos={270,vYValue-10},mode=1,bodyWidth=190,value=" ;"+BackgroundRemove_DropList("B"),proc=BackgroundRemove_UpdateGlobal
	SetVariable sBKGF, title=" ",pos={130,vYValue-10},size={175,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sBKG][%$sProject]
	vYValue+=25
	DrawText 125,vYValue, "New Data Name:"
	PopupMenu sSubtractedSignal,pos={270,vYValue-10},mode=1,bodyWidth=190,value=BackgroundRemove_DropList("D"),proc=BackgroundRemove_UpdateGlobal
	SetVariable sSubtractedSignalF, title=" ",pos={130,vYValue-10},size={175,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sSubtractedSignal][%$sProject]
	vYValue+=25
	DrawText 125,vYValue, "From Sample:"
	DrawText 275,vYValue, "To Sample:"
	SetVariable vFirstSample, title=" ",pos={125,vYValue-10},size={75,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%vFirstSample][%$sProject]
	SetVariable vLastSample, title=" ",pos={275,vYValue-10},size={75,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%vLastSample][%$sProject]	
	vYValue+=15
	button btCheckMask,title="Check Mask",appearance={native,All},pos={25,vYValue},size={100,25},proc=BackgroundRemove_CheckMask,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button btMarkPeak,title="Signal",appearance={native,All},pos={150,vYValue},size={100,25},proc=BackgroundRemove_MarkPeak,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button btMarkBKG,title="Bkgrd",appearance={native,All},pos={275,vYValue},size={100,25},proc=BackgroundRemove_MarkBKG,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=35
	button btMakeBKG,title="Make Bkgrd",appearance={native,All},pos={37,vYValue},size={150,25},proc=BackgroundRemove_MakeBKG,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button btRemoveBKG,title="Check Bkgrd",appearance={native,All},pos={213,vYValue},size={150,25},proc=BackgroundRemove_CheckBKG,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=35
	button btSimpleRemove,title="Simple Removal",appearance={native,All},pos={37,vYValue},size={150,25},proc=BackgroundRemove_SimpleRemove,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button btDynamicRemove,title="Dynamic Removal",appearance={native,All},pos={213,vYValue},size={150,25},proc=BackgroundRemove_DynamicRemove,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14

end

//function to update the globals from the diffraction ref panel
Function BackgroundRemove_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	if(stringmatch("sProject",ctrlName))
		Combi_GiveGlobal("sBKGRemoveProject",popStr,"COMBIgor")
	else
		Combi_GivePluginGlobal(sPluginName,ctrlName,popStr,Combi_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	Combi_BackgroundRemove()		
End

//function to return drop downs of data types for panel
function/S BackgroundRemove_DropList(sOption)
	string sOption //S for Libraries, or D for DataTypes, or B for Backgrounds
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	if(stringmatch(sProject,""))// no project set
		return " ;"
	endif
	if(stringmatch("S",sOption))
		return " ;"+Combi_TableList(sProject,2,"All","Libraries")
	elseif(stringmatch("D",sOption))
		return " ;"+Combi_TableList(sProject,2,"All","DataTypes")
	elseif(stringmatch("B",sOption))
		setdatafolder $"root:COMBIgor:"+sProject+":Backgrounds:"
		string sAllBackgrounds = Wavelist("*",";","")
		SetDataFolder $sTheCurrentUserFolder
		Return sAllBackgrounds
	endif
	
end

Function BackgroundRemove_SimpleRemove(ctrlName) : ButtonControl
	string ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	//get COMBIgor Plugin variables
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sSubtractedSignal = Combi_GetPluginString(sPluginName,"sSubtractedSignal",sProject)
	string sBKG = Combi_GetPluginString(sPluginName,"sBKG",sProject)
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	variable vTotalSamples = iLastSample-iFirstSample
	
	//make folder paths
	string sMaskFolder = "root:COMBIgor:"+sProject+":Masks:"
	string sBackgroundsFolder = "root:COMBIgor:"+sProject+":Backgrounds:"
		
	//get COMBIgor project variables
	variable vTotalLibrarySamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	
	//get background
	setdatafolder $sBackgroundsFolder
	string sTheseMatchingWaves = Wavelist(sBKG,";","")
	SetDataFolder $sTheCurrentUserFolder
	if(itemsinlist(sTheseMatchingWaves)==0)
		DoAlert/T="COMBIgor error" 0,"Make the background first for Library "+sLibrary
		return-1
	endif
	wave wBackgroundWave = $sBackgroundsFolder+sBKG
	
	//get vector data for this project
	wave wVectorData = $Combi_DataPath(sProject,2)+sLibrary+":"+sIntensity
	variable vVectorLength = dimsize(wVectorData,3)
	
	//prompt user for new combi data type name
	string sNewDataType = cleanupname(sSubtractedSignal,0)
	variable vBackgroungScaler = 1
	prompt sNewDataType, "Name for data with background subtracted:"
	prompt vBackgroungScaler, "Background Scalar:"
	DoPrompt/HELP="Enter a data name under which to store the new vector data." "Simple background removal options", sNewDataType, vBackgroungScaler
	if (V_Flag)
		return -1// User canceled
	endif
	
	//Get a giving wave to populate and populate with data as is.
	make/O/N=(dimsize(wVectorData,0),1,dimsize(wVectorData,1)) wGivingBkGd
	wave wGiving = root:wGivingBkGd
	wGiving[][0][] = wVectorData[p][r]
	
	//do subtraction on Samples within range
	variable iSample
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		wGiving[iSample][0][] = wGiving[iSample][0][r]-vBackgroungScaler*wBackgroundWave[r][iSample]
	endfor
	
	//give back to COMBIgor
	Combi_GiveData(wGiving,sProject,sLibrary,sNewDataType,-1,2)
	killwaves wGiving
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Process: BackgroundRemove_SimpleRemove"
	sLogEntry2 = "Source Intensity Data: "+sIntensity
	sLogEntry3 = "Background Removed Data: "+sNewDataType
	sLogEntry4 = "Background Data: "+sBackgroundsFolder+sBKG
	sLogEntry5 = "Background Scalar: "+num2str(vBackgroungScaler)
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sLibrary,sNewDataType,2,sLogText)	
	
	
End

Function BackgroundRemove_DynamicRemove(ctrlName) : ButtonControl
	string ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	//get COMBIgor Plugin variables
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sBKG = Combi_GetPluginString(sPluginName,"sBKG",sProject)
	string sSubtractedSignal = Combi_GetPluginString(sPluginName,"sSubtractedSignal",sProject)
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	variable vTotalSamples = iLastSample-iFirstSample
	
	//make folder paths
	string sMaskFolder = "root:COMBIgor:"+sProject+":Masks:"
	string sBackgroundsFolder = "root:COMBIgor:"+sProject+":Backgrounds:"
		
	//get COMBIgor project variables
	variable vTotalLibrarySamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	
	//get background
	setdatafolder $sBackgroundsFolder
	string sTheseMatchingWaves = Wavelist(sBKG,";","")
	SetDataFolder $sTheCurrentUserFolder 
	if(itemsinlist(sTheseMatchingWaves)==0)
		DoAlert/T="COMBIgor error." 0,"Make the background first for Library "+sLibrary
		return-1
	endif
	wave wBackgroundWave = $sBackgroundsFolder+sBKG
	
	//get mask
	setdatafolder $sMaskFolder
	sTheseMatchingWaves = Wavelist(sLibrary+"_Mask",";","")
	SetDataFolder $sTheCurrentUserFolder 
	if(itemsinlist(sTheseMatchingWaves)==0)
		DoAlert/T="COMBIgor error." 0,"Make the mask first for Library "+sLibrary
		return-1
	endif
	wave wMaskWave = $sMaskFolder+sLibrary+"_Mask"
	
	//get combi data for this project
	wave wVectorData = $Combi_DataPath(sProject,2)+sLibrary+":"+sIntensity
	Combi_AddDataType(sProject,sLibrary,"XRD_BKGD_SCALER",1)
	wave wScalarData = $Combi_DataPath(sProject,1)+sLibrary+":XRD_BKGD_SCALER"
	variable vVectorLength = dimsize(wVectorData,1)
	
	//prompt user for new combi data type name
	string sNewDataType = cleanupname(sSubtractedSignal,0)
	prompt sNewDataType, "Name for data with background subtracted:"
	DoPrompt/HELP="Enter a data name under which to store the new vector data" "Dynamic background removal options", sNewDataType
	if (V_Flag)
		return -1// User canceled
	endif
	
	//Get a giving wave to populate and populate with data from source intensity.
	make/O/N=(dimsize(wVectorData,0),1,dimsize(wVectorData,1)) wGivingBkGd
	wave wGiving = root:wGivingBkGd
	setScale/I z, wVectorData[0][0], wVectorData[0][dimsize(wVectorData,1)-1], wGiving
	wGiving[][0][] = wVectorData[p][r]
	
	//Tempwave for determing the scale factor
	Make/N=(vVectorLength) wRatios
	Wave wRatios = root:wRatios
	
	//do on Samples within range
	variable iSample, iVector, vScaler
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		wRatios[]=nan
		for(iVector=0;iVector<vVectorLength;iVector+=1)	
			if(wMaskWave[iVector][iSample]==1)
				wRatios[iVector] = wGiving[iSample][0][iVector]/wBackgroundWave[iVector][iSample]
			endif
		endfor
		vScaler = median(wRatios)
		wScalarData[iSample] = vScaler
		wGiving[iSample][0][] = wGiving[iSample][0][r]-vScaler*wBackgroundWave[r][iSample]
	endfor
	
	//give back to COMBIgor
	Combi_GiveData(wGiving,sProject,sLibrary,sNewDataType,-1,2)
	Killwaves wRatios, wGiving
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Process: BackgroundRemove_DynamicRemove"
	sLogEntry2 = "Source Intensity Data: "+sIntensity
	sLogEntry3 = "Background Removed Data: "+sNewDataType
	sLogEntry4 = "Mask: "+sMaskFolder+sLibrary+"_Mask"
	sLogEntry5 = "Background Data: "+sBackgroundsFolder+sBKG
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sLibrary,sNewDataType,2,sLogText)		

	
End

Function BackgroundRemove_MakeBKG(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	//get COMBIgor Plugin variables
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sBKG = Combi_GetPluginString(sPluginName,"sBKG",sProject)
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	variable vTotalSamples = iLastSample-iFirstSample
	
	//make folder paths
	string sMaskPath = "root:COMBIgor:"+sProject+":Masks:"
	string sBackgroundsFolder = "root:COMBIgor:"+sProject+":Backgrounds:"
		
	//get COMBIgor project variables
	variable vTotalLibrarySamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	
	//get mask
	string sMaskName = sLibrary+"_Mask"
	wave wMaskWave = $sMaskPath+sMaskName
	setdatafolder $sMaskPath
	string sTheseMatchingWaves = Wavelist(sMaskName,";","")
	SetDataFolder $sTheCurrentUserFolder 
	if(itemsinlist(sTheseMatchingWaves)==0)
		DoAlert/T="COMBIgor error" 0,"Check the mask first for Library "+sLibrary
		return-1
	endif
	
	//get vector data for this project
	wave wVectorData = $Combi_DataPath(sProject,2)+sLibrary+":"+sIntensity
	
	//user input
	string sWaveName
	if(stringmatch(sBKG,"")||stringmatch(sBKG," "))
		sWaveName = "Interpolated"
	else
		sWaveName = sBKG
	endif
	variable vSplineValue = 0.04
	prompt sWaveName, "Name for newly made background:"
	prompt vSplineValue, "Spline Smoothing Factor (>=0)"
	DoPrompt/HELP="This is the name assigned to this background scan and the smoothing factor." "Make background", sWaveName, vSplineValue
	if (V_Flag)
		return -1// User canceled
	endif
	sWaveName=Cleanupname(sWaveName,0)
	Combi_GivePluginGlobal(sPluginName,"sBKG",sWaveName,sProject)
	//Check if existed previously and make neccesarry waves
	setdatafolder $sBackgroundsFolder
	variable bNewBackground = 0
	sTheseMatchingWaves = Wavelist(sWaveName,";","")
	if(itemsinlist(sTheseMatchingWaves)==0)
		Make/N=(dimsize(wVectorData,1),vTotalLibrarySamples)/O $sWaveName
		Make/N=(dimsize(wVectorData,1))/O wInterpBKGD
		Make/N=(dimsize(wVectorData,1))/O wTempBKGD
		bNewBackground = 1
	else
		Make/N=(dimsize(wVectorData,1))/O wInterpBKGD
		Make/N=(dimsize(wVectorData,1))/O wTempBKGD
	endif
	SetDataFolder $sTheCurrentUserFolder 
	Wave wNewBackground = $sBackgroundsFolder+sWaveName
	SetScale/P x, dimoffset(wVectorData,1),dimdelta(wVectorData,1), wNewBackground
	Wave wInterpBackground = $sBackgroundsFolder+"wInterpBKGD"
	Wave wTempBackground = $sBackgroundsFolder+"wTempBKGD"
	if(bNewBackground==1)
		wNewBackground[][]=nan
	endif
	
	//Populate the new background wave for Samples operating on (mask = 1)
	variable iVector,iSample
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		wNewBackground[][iSample] = nan
		for(iVector=0;iVector<dimsize(wVectorData,1);iVector+=1)
			if(wMaskWave[iVector][iSample]==1)
				wNewBackground[iVector][iSample]=wVectorData[iSample][iVector]
			endif
		endfor
	endfor
		
	//Interp new backgrounds
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		wTempBackground[] = wNewBackground[p][iSample]
		Interpolate2/T=3/N=(dimsize(wVectorData,1))/F=(vSplineValue)/Y=wInterpBackground wTempBackground
		wNewBackground[][iSample] = wInterpBackground[p]
	endfor
	
	//kill working waves
	killwaves wInterpBackground,wTempBackground

	//add to open mask window, if right one
	string sWindowName = sLibrary+"MaskDef"
	GetWindow/Z $sWindowName active
	If(V_Flag==0)
		AppendToGraph/L/W=$sWindowName wNewBackground[][iFirstSample]/TN=$sWaveName
		ModifyGraph lstyle($sWaveName)=2,lsize($sWaveName)=2,rgb($sWaveName)=(0,0,0)
	endif
End

Function BackgroundRemove_CheckMask(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sMaskPath = "root:COMBIgor:"+Combi_GetPluginString(sPluginName,"sProject","COMBIgor")+":Masks:"
	string sMaskName = sLibrary+"_Mask"
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	wave wVectorData = $Combi_DataPath(sProject,2)+sLibrary+":"+sIntensity
	//check for inputs needed
	if(stringmatch(sLibrary,"")||stringmatch(sLibrary," "))
		DoAlert/T="COMBIgor error" 0,"Please specify a Library."
		return -1
	endif
	if(stringmatch(sIntensity,"")||stringmatch(sIntensity," "))
		DoAlert/T="COMBIgor error" 0,"Please specify an intensity."
		return -1
	endif
	//Check if existed previously
	setdatafolder $sMaskPath
	variable bNewMask = 0
	if(itemsinlist(Wavelist(sMaskName,";",""))==0)
		Make/N=(DimSize(wVectorData,1),vTotalSamples) $sMaskName
		wave wMaskWave = $sMaskPath+sMaskName
		//set scale based on scale of signal 
		SetScale/P x, dimoffset(wVectorData,1),dimdelta(wVectorData,1), wMaskWave
		bNewMask = 1
	endif
	SetDataFolder $sTheCurrentUserFolder 
	wave wMaskWave = $sMaskPath+sMaskName
	if(bNewMask==1)
		wMaskWave[][]=1
	endif
	//Mask Plot
	string sWindowName = sLibrary+"MaskDef"
	string sWindowTitle = "Mask for Library: "+sLibrary+", Intensity: "+sIntensity
	Killwindow/Z $sWindowName
	sWindowName = Combi_NewPlot(sWindowName)
	DoWindow/T $sWindowName,sWindowTitle
	//append mask
	AppendToGraph/R/W=$sWindowName wMaskWave[][iFirstSample]/TN=$sMaskName
	ModifyGraph mode($sMaskName)=7,useNegRGB($sMaskName)=1,usePlusRGB($sMaskName)=1,hbFill($sMaskName)=5,rgb($sMaskName)=(0,0,0),plusRGB($sMaskName)=(0,0,0),negRGB($sMaskName)=(0,0,0)
	//apendd traces
	variable iSample
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		string sTraceName = sLibrary+"_"+num2str(iSample+1)
		AppendToGraph/L/W=$sWindowName wVectorData[iSample][]/TN=$sTraceName
	endfor
	//format
	ModifyGraph log(left)=1,mirror(bottom)=2,lblMargin(right)=10,lblMargin(left)=10
	Label right "Mask Value (1 = Bkgrd, 0 = Peak)"
	Label left sIntensity
	Label bottom "Scale"
	SetAxis right -0,1
	//add cursors
	Cursor/A=1 A $sTraceName 0
	Cursor/A=1 B $sTraceName DimSize(wVectorData,1)-1
	
End

Function BackgroundRemove_MarkPeak(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sMaskPath = "root:COMBIgor:"+Combi_GetPluginString(sPluginName,"sProject",sProject)+":Masks:"
	string sMaskName = sLibrary+"_Mask"
	setdatafolder $sMaskPath
	if(itemsinlist(Wavelist(sMaskName,";",""))==0)
		DoAlert/T="COMBIgor error" 0,"The "+sLibrary+"_Mask doesn't exist."
		return -1
	endif
	SetDataFolder $sTheCurrentUserFolder 
	wave wMaskWave = $sMaskPath+sMaskName
	string sAPos = CsrInfo(A)
	string sBPos = CsrInfo(B)
	variable vAPos = NumberByKey("POINT",sAPos)
	variable vBPos = NumberByKey("POINT",sBPos)
	wMaskWave[vAPos,vBPos][iFirstSample,iLastSample]=0
End

Function BackgroundRemove_MarkBKG(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sMaskPath = "root:COMBIgor:"+Combi_GetPluginString(sPluginName,"sProject",sProject)+":Masks:"
	string sMaskName = sLibrary+"_Mask"
	setdatafolder $sMaskPath
	if(itemsinlist(Wavelist(sMaskName,";",""))==0)
		DoAlert/T="COMBIgor error" 0,"The "+sLibrary+"_Mask doesn't exist."
		return -1
	endif
	SetDataFolder $sTheCurrentUserFolder 
	wave wMaskWave = $sMaskPath+sMaskName
	string sAPos = CsrInfo(A)
	string sBPos = CsrInfo(B)
	variable vAPos = NumberByKey("POINT",sAPos)
	variable vBPos = NumberByKey("POINT",sBPos)
	wMaskWave[vAPos,vBPos][iFirstSample,iLastSample]=1
End

Function BackgroundRemove_CheckBKG(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	//Make sure user is in root folder
	setdatafolder root:
	string sProject = Combi_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary = Combi_GetPluginString(sPluginName,"sBKGLibrary",sProject)
	string sIntensity = Combi_GetPluginString(sPluginName,"sSignal",sProject)
	string sBKG = Combi_GetPluginString(sPluginName,"sBKG",sProject)
	string sBKGDPath = "root:COMBIgor:"+Combi_GetPluginString(sPluginName,"sProject",sProject)+":Backgrounds:"
	variable vTotalLibrarySamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	variable iFirstSample = Combi_GetPluginNumber(sPluginName,"vFirstSample",sProject)-1
	variable iLastSample = Combi_GetPluginNumber(sPluginName,"vLastSample",sProject)-1
	variable vTotalSamples = iLastSample-iFirstSample
	string sWindowName = sLibrary+"BKGDCheck"
	string sWindowTitle = "Checking "+sBKG+" against "+sIntensity+" for  Library: "+sLibrary
	wave wVectorData = $Combi_DataPath(sProject,2)+sLibrary+":"+sIntensity
	wave wBKGWave = $sBKGDPath+sBKG
	
	//get background
	setdatafolder $sBKGDPath
	string sTheseMatchingWaves = Wavelist(sBKG,";","")
	SetDataFolder $sTheCurrentUserFolder 
	if(itemsinlist(sTheseMatchingWaves)==0)
		DoAlert/T="COMBIgor error" 0,"Pick a background for Library "+sLibrary
		return-1
	endif
	
	Killwindow/Z $sWindowName
	sWindowName = Combi_NewPlot(sWindowName)
	DoWindow/T $sWindowName,sWindowTitle
	
	//append by Sample
	variable iSample
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		string sScanName = sLibrary+"_"+num2str(iSample)
		string sBKGDName = sBKG+"_"+num2str(iSample)
		AppendToGraph/L/W=$sWindowName wVectorData[iSample][]/TN=$sScanName
		AppendToGraph/L/W=$sWindowName wBKGWave[][iSample]/TN=$sBKGDName
		ModifyGraph lstyle($sBKGDName)=2,rgb($sBKGDName)=(0,0,0)
	endfor
	ModifyGraph log(left)=1,mirror=2,lblMargin(left)=10;DelayUpdate
	Label left "Int";DelayUpdate
	Label bottom "Vector Index (i)"
End

