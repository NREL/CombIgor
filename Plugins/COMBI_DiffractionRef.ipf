#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original DiffractionRef 
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
Static StrConstant sPluginName = "DiffractionRef"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Plugins"
		 "Diffraction References",/Q, COMBI_DiffractionRef()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//function to update the globals from the diffraction ref panel
Function DiffractionRef_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	if(stringmatch("sProject",ctrlName))
		COMBI_GiveGlobal("sActiveFolder",popStr,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	elseif(stringmatch("sSoftwavePref",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	else
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif		
end

//this function is ran when the user selects the Plugin from the COMBIgor drop down menu once activated
function COMBI_DiffractionRef()
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//get Plugin name and project name
	string sProject = COMBI_GetGlobalString("sPluginProject", "COMBIgor")
	
	//get specific globals
	string sPreferredSoftware = COMBI_GetPluginString(sPluginName,"sPreferredSoftware",sProject)

	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z DiffractionRefPanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z DiffractionRefPanel
	//define Plugin name to use in COMBIgor
	//Check if initialized, do if not
	COMBI_PluginReady(sPluginName)
	//get global wave
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sPluginName+"_Globals"
	//panel building options
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	//to get initial values for popups
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor")))
		COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref","CrystalDiffract","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"vWavelength","1.541","COMBIgor")
	endif
	variable bNewProject = 1
	variable vSampleMin,vSampleMax
	string sDegreeAxis, sIntensityAxis, sAction, sProfile, sPeaks, sExternalType, sExternalLocation, sSoftwavePref, sScale, sLibrary
	//get project if one exist, make if not	
	if(Stringmatch(COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"),"NAG"))//no project exist (first use - intialize)
		sProject = COMBI_ChooseProject()//get global
		if(Stringmatch(sProject,""))//user cancelled choosing project
			Return -1
		endif
		COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,"COMBIgor")//get, and set global
		COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)//get, and set global
		COMBI_GivePluginGlobal(sPluginName,"sDegreeAxis"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sntensityAxis"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sProfile"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sPeaks"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAction","See",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sExternalType"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sExternalLocation"," ",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sScale","Q",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLibrary","",sProject)
		if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor")))
			COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref"," ",sProject)
		endif
		setdatafolder $"root:COMBIgor:"+sProject
		newdatafolder/O/S DiffractionRefs
		newdatafolder/O Profiles
		newdatafolder/O Peaks
		SetDataFolder $sTheCurrentUserFolder 
	else
		sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")//get global
	endif

	sDegreeAxis = COMBI_GetPluginString(sPluginName,"sDegreeAxis",sProject)
	sIntensityAxis = COMBI_GetPluginString(sPluginName,"sIntensityAxis",sProject)
	sProfile = COMBI_GetPluginString(sPluginName,"sProfile",sProject)
	sPeaks = COMBI_GetPluginString(sPluginName,"sPeaks",sProject)
	sExternalType = COMBI_GetPluginString(sPluginName,"sExternalType",sProject)
	sExternalLocation = COMBI_GetPluginString(sPluginName,"sExternalLocation",sProject)
	sSoftwavePref = COMBI_GetPluginString(sPluginName,"sSoftwavePref",sProject)
	sAction = COMBI_GetPluginString(sPluginName,"sAction",sProject)
	sScale = COMBI_GetPluginString(sPluginName,"sScale",sProject)
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	variable vWavelength = COMBI_GetPluginNumber(sPluginName,"vWavelength",sProject)
	
	//make panel
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+450,vWinTop+180)/N=DiffractionRefPanel as "Diffraction Reference Plugin"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont
	SetDrawEnv textxjust = 2,textyjust = 1
	SetDrawEnv fsize = 12
	SetDrawEnv save
	variable vYValue = 15
	
	//Project Row
	SetDrawEnv textrot = 0; SetDrawEnv save; 
	DrawText 85,vYValue, "Project:"
	PopupMenu sProject,pos={180,vYValue-10},mode=1,bodyWidth=140,value=COMBI_Projects(),proc=DiffractionRef_UpdateGlobal,popvalue=sProject
	DrawText 295,vYValue, "Library:"
	PopupMenu sLibrary,pos={390,vYValue-10},mode=1,bodyWidth=140,value=DiffractionRef_RefList("Libraries"),proc=DiffractionRef_UpdateGlobal,popvalue=sLibrary
	
	//AxisRow
	vYValue+=20
	SetDrawEnv textrot = 0; SetDrawEnv save; 
	DrawText 85,vYValue, "Intensity:"
	PopupMenu sIntensityAxis,pos={180,vYValue-10},mode=1,bodyWidth=140,value=DiffractionRef_RefList("DataTypes"),proc=DiffractionRef_UpdateGlobal,popvalue=sIntensityAxis
	DrawText 295,vYValue, "Degree:"
	PopupMenu sDegreeAxis,pos={390,vYValue-10},mode=1,bodyWidth=140,value=DiffractionRef_RefList("DataTypes"),proc=DiffractionRef_UpdateGlobal,popvalue=sDegreeAxis
	
	//Action Row
	vYValue+=20
	SetDrawEnv textrot = 0; SetDrawEnv save; DrawText 85,vYValue, "Scale:"
	PopupMenu sScale,pos={180,vYValue-10},mode=1,bodyWidth=140,value=" ;"+DiffractionRef_RefList("Scale"),proc=DiffractionRef_UpdateGlobal,popvalue=sScale	
	SetDrawEnv textrgb= (65535,0,0)
	DrawText 295,vYValue, "Action:"
	PopupMenu sAction,pos={390,vYValue-10},mode=1,bodyWidth=140,value=" ;"+DiffractionRef_RefList("Action"),proc=DiffractionRef_UpdateGlobal,popvalue=sAction

			
	//select profile
	vYValue+=20
	SetDrawEnv textrot = 0; SetDrawEnv save; DrawText 155,vYValue, "Reference Profile:"
	PopupMenu sProfile,pos={300,vYValue-10},mode=1,bodyWidth=190,value=" ;All;"+DiffractionRef_RefList("Profiles"),proc=DiffractionRef_UpdateGlobal,popvalue=sProfile
	button btDoProfileAction,title="Do",appearance={native,All},pos={370,vYValue-10},size={60,20},proc=DiffractionRef_DoAction,font=sFont,fstyle=1,fColor=(65535,32768,32768),fsize=14

	//select peak list
	vYValue+=20
	SetDrawEnv textrot = 0; SetDrawEnv save; DrawText 155,vYValue, "Reference Peaks:"
	PopupMenu sPeaks,pos={300,vYValue-10},mode=1,bodyWidth=190,value=" ;All;"+DiffractionRef_RefList("Peaks"),proc=DiffractionRef_UpdateGlobal,popvalue=sPeaks
	button btDoPeakAction,title="Do",appearance={native,All},pos={370,vYValue-10},size={60,20},proc=DiffractionRef_DoAction,font=sFont,fstyle=1,fColor=(65535,32768,32768),fsize=14
	
	// organization line
	vYValue+= 10
	DrawLine 10,vYValue+5,430,vYValue+5
	
	//Reference Loading
	vYValue+=15
	SetDrawEnv textrgb= (0,0,65535)
	DrawText 300,vYValue, "Reference Loading"
	vYValue+=20
	SetDrawEnv textrot = 0; SetDrawEnv save; 
	DrawText 125,vYValue, "Wavelength (Å):"
	SetVariable vWavelength, title=" ",pos={130,vYValue-8},size={100,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%vWavelength][%COMBIgor]
	DrawText 295,vYValue, "Source:"
	PopupMenu sSoftwavePref,pos={390,vYValue-10},mode=1,bodyWidth=140,value=DiffractionRef_SoftwareList(),proc=DiffractionRef_UpdateGlobal,popvalue=sSoftwavePref
	
	vYValue+=15
	button btLoadProfile,title="Load Profile",appearance={native,All},pos={20,vYValue},size={120,20},proc=DiffractionRef_LoadRef,font=sFont,fstyle=1,fColor=(32768,40777,65535),fsize=14
	button btLoadPeaks,title="Load Peaks",appearance={native,All},pos={167.5,vYValue},size={120,20},proc=DiffractionRef_LoadRef,font=sFont,fstyle=1,fColor=(32768,40777,65535),fsize=14
	button btLoadBoth,title="Load Both",appearance={native,All},pos={315,vYValue},size={120,20},proc=DiffractionRef_LoadRef,font=sFont,fstyle=1,fColor=(32768,40777,65535),fsize=14
	vYValue+=20
	
end

//load a crystal diffact relfection list ouptup file
Function/S DiffractionRef_CDRelectionLoad()

	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//get file to read
	variable vFileRef
	Open/R/T=".txt" vFileRef
	string sOpened=S_fileName
	variable vFolderInPath = itemsinlist(sOpened,":")
	string sFullname = stringfromlist(vFolderInPath-1,sOpened,":")
	string sFileName = Cleanupname(removeending(sFullname,".txt"),0)
	
	//Read to string
	string sThisLine = PadString("",inf,4)
	FReadLine/T="" vFileRef, sThisLine
	Close vFileRef
	
	//parse each line, add to string list
	variable vFirstDataLine = 431
	variable vRowLength = 74
	variable iRow = 0
	string sThisRow
	string sH=""
	string sK=""
	string sL=""
	string sdhkl=""
	string sTwTheta=""
	string sPercentMaxInt=""
	
	do
		variable vFirstChar = vFirstDataLine+iRow*vRowLength
		variable vLastChar = vFirstChar+vRowLength
		sThisRow = sThisLine[vFirstChar+2,vLastChar-2]
		sH = AddListItem(sThisRow[0,0],sH,";",inf)
		sK = AddListItem(sThisRow[4,4],sK,";",inf)
		sL = AddListItem(sThisRow[8,8],sL,";",inf)
		sdhkl = AddListItem(num2str(str2num(sThisRow[12,18])),sdhkl,";",inf)
		sTwTheta = AddListItem(num2str(str2num(sThisRow[21,28])),sTwTheta,";",inf)
		sPercentMaxInt = AddListItem(num2str(str2num(sThisRow[45,49])/100),sPercentMaxInt,";",inf)
		iRow+=1
	while(vLastChar<strlen(sThisLine))
	
	//PackintoWave
	Make/O/N=(iRow-1,7) $sFileName
	wave wNewPeakList = $"root:"+sFileName
	setdimlabel 1,0,H,wNewPeakList
	setdimlabel 1,1,K,wNewPeakList
	setdimlabel 1,2,L,wNewPeakList
	setdimlabel 1,3,dHKL,wNewPeakList
	setdimlabel 1,4,TwoTheta,wNewPeakList
	setdimlabel 1,5,Q,wNewPeakList
	setdimlabel 1,6,FractionMaxIntensity,wNewPeakList
	for(iRow=0;iRow<itemsinlist(sH)-1;iRow+=1)
		wNewPeakList[iRow][0] = str2num(stringfromlist(iRow,sH))
		wNewPeakList[iRow][1] = str2num(stringfromlist(iRow,sK))
		wNewPeakList[iRow][2] = str2num(stringfromlist(iRow,sL))
		wNewPeakList[iRow][3] = str2num(stringfromlist(iRow,sdhkl))
		wNewPeakList[iRow][4] = str2num(stringfromlist(iRow,sTwTheta))
		wNewPeakList[iRow][5] = (2*pi)/str2num(stringfromlist(iRow,sdhkl))
		wNewPeakList[iRow][6] = str2num(stringfromlist(iRow,sPercentMaxInt))
	endfor
	
	//return name of waave
	return sFileName
end


//function to load a Ref 
function DiffractionRef_LoadRef(ctrlName) : ButtonControl
	string ctrlName
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//check for BrukerXRD
	string sOptions
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sInType = COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor")
	variable vWaveLength = COMBI_GetPluginNumber(sPluginName,"vWaveLength","COMBIgor")
		
	//prompt user for import type and file name
	string sRefName = ""
	prompt sRefName, "Desired Name:"
	DoPrompt/HELP="This tells COMBIgor what the incoming data looks like" "Importing a new Ref Profile", sRefName
	if (V_Flag)
		return -1// User canceled
	endif
	sRefName = cleanupname(sRefName,0)
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
		
	string sWavePath,sWaveSelected, sUserChoiceProject, sTheseWaves	
		
	//profile
	if(stringmatch(ctrlName,"btLoadProfile")||stringmatch(ctrlName,"btLoadBoth"))		
		
		DoAlert/T="Profile Loading",0,"Select the profile file in the next open file dialog."
		
		//make destination wave
		setdatafolder $"root:COMBIgor:"+sProject+":DiffractionRefs:Profiles:"
		Make/O/N=(1,4) $sRefName
		wave wDestination = $"root:COMBIgor:"+sProject+":DiffractionRefs:Profiles:"+sRefName
		SetDataFolder $sTheCurrentUserFolder 
		setdimlabel 1,0,TwoTheta,wDestination
		setdimlabel 1,1,Q,wDestination
		setdimlabel 1,2,Intensity,wDestination
		setdimlabel 1,3,Normalized_Int,wDestination
			
		
		if(stringmatch(sInType,"DiffracPlus"))
			string sRootWavesBefore = stringbyKey("WAVES",DataFolderDir(-1))
			Execute "BrukerXRD_LoadFile()"
			string sRootWavesAfter = stringbyKey("WAVES",DataFolderDir(-1))
			variable vTotalWaves = itemsinlist(sRootWavesAfter,","), iWave
			string sNewWave = ""
			for(iWave=0;iWave<vTotalWaves;iWave+=1)
				string sThisWave = stringfromList(iWave,sRootWavesAfter,",")
				variable vMatching = itemsinlist(Listmatch(sRootWavesBefore,sThisWave,","))
				if(vMatching==0)
					sNewWave = sThisWave
				endif
			endfor
			wave wThisNewRef = $"root:"+sNewWave//get wave
		elseif(stringmatch(sInType,"CrystalDiffract"))
			LoadWave/G/M/Q/O/N=LoadedProfile//load file
			wave wThisNewRef = $"root:LoadedProfile0"//get wave
		elseif(stringmatch(sInType,"Vesta"))
			LoadWave/G/M/Q/O/N=LoadedProfile//load file
			wave wThisNewRef = $"root:LoadedProfile0"//get wave
		elseif(stringmatch(sInType,"PDF+"))
			LoadWave/G/M/Q/O/N=LoadedProfile//load file
			wave wThisNewRef = $"root:LoadedProfile0"//get wave
		elseif(stringmatch(sInType,"ICSD"))
			LoadWave/G/M/Q/O/N=LoadedProfile//load file
			wave wThisNewRef = $"root:LoadedProfile0"//get wave
		elseif(stringmatch(sInType,"From Another Project"))
			sUserChoiceProject = COMBI_ChooseProject()
			setdatafolder $"root:COMBIgor:"+sUserChoiceProject+":DiffractionRefs:Profiles:"
			sTheseWaves = Wavelist("*",";","")
			SetDataFolder $sTheCurrentUserFolder 
			prompt sWaveSelected, "Which one?:", POPUP, sTheseWaves
			if (V_Flag)
				return -1// User canceled
			endif
			sWavePath = "root:COMBIgor:"+sUserChoiceProject+":DiffractionRefs:Profiles:"+sWaveSelected
			wave wThisNewRef = $sWavePath
		endif
		
		//redim
		Redimension/N=(dimsize(wThisNewRef,0),-1) wDestination
		wDestination[][]=nan
		
		//Degree
		wDestination[][0] = wThisNewRef[p][0]
		
		//Q
		wDestination[][1] = 4*pi*Sin(wThisNewRef[p][0]*pi/360)/vWaveLength
		
		//Int
		wDestination[][2] = wThisNewRef[p][1]
		
		//normed int
		variable iIndex, vMin = inf, vMax=-inf
		for(iIndex=0;iIndex<dimsize(wThisNewRef,0);iIndex+=1)
			if(wThisNewRef[iIndex][1]<vMin)
				vMin = wThisNewRef[iIndex][1]
			endif
			if(wThisNewRef[iIndex][1]>vMax)
				vMax = wThisNewRef[iIndex][1]
			endif
		endfor
		wDestination[][3] = (wThisNewRef[p][1]-vMin)/(vMax-vMin)
	
		//replace 0 with nan in the normalized scan for log scale plots
		for(iIndex=0;iIndex<dimsize(wDestination,0);iIndex+=1)
			if(wDestination[iIndex][3]==0)
				wDestination[iIndex][3] = nan
			endif
		endfor
		Killwaves/Z wThisNewRef
	endif
	
	//direct next dialog towards import path if import option is on.
	sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//peak list
	if(stringmatch(ctrlName,"btLoadPeaks")||stringmatch(ctrlName,"btLoadBoth"))
	
		DoAlert/T="Peak Loading",0,"Select the peak file in the next open file dialog."
		
		//make destination wave
		setdatafolder $"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"
		Make/O/N=(1,7) $sRefName
		wave wDestination = $"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+sRefName
		SetDataFolder $sTheCurrentUserFolder 
		setdimlabel 1,0,H,wDestination
		setdimlabel 1,1,K,wDestination
		setdimlabel 1,2,L,wDestination
		setdimlabel 1,3,dHKL,wDestination
		setdimlabel 1,4,TwoTheta,wDestination
		setdimlabel 1,5,Q,wDestination
		setdimlabel 1,6,FractionMaxIntensity,wDestination
			
		
		if(stringmatch(sInType,"Vesta"))
			LoadWave/G/M/Q/O/N=LoadedPeaks/L={0,1,0,0,0}//load file
			wave wThisNewRef = $"root:LoadedPeaks0"//get wave
			redimension/N=(dimsize(wThisNewRef,0),-1) wDestination
			wDestination[][0] = wThisNewRef[p][0]
			wDestination[][1] = wThisNewRef[p][1]
			wDestination[][2] = wThisNewRef[p][2]
			wDestination[][3] = wThisNewRef[p][3]
			wDestination[][4] = wThisNewRef[p][7]
			wDestination[][5] = 4*pi*Sin(wThisNewRef[p][7]*pi/360)/vWaveLength
			wDestination[][6] = wThisNewRef[p][8]/100
		elseif(stringmatch(sInType,"ICSD"))
			LoadWave/G/M/Q/O/N=LoadedPeaks/L={0,1,0,0,0}//load file
			wave wThisNewRef = $"root:LoadedPeaks0"//get wave
			redimension/N=(dimsize(wThisNewRef,0),-1) wDestination
			wDestination[][0] = wThisNewRef[p][0]
			wDestination[][1] = wThisNewRef[p][1]
			wDestination[][2] = wThisNewRef[p][2]
			wDestination[][3] = wThisNewRef[p][4]
			wDestination[][4] = wThisNewRef[p][3]
			wDestination[][5] = 4*pi*Sin(wThisNewRef[p][3]*pi/360)/vWaveLength
			wDestination[][6] = wThisNewRef[p][6]/1000
		elseif(stringmatch(sInType,"CrystalDiffract"))
			sWavePath = DiffractionRef_CDRelectionLoad()
			wave wThisNewRef = $sWavePath
			Redimension/N=(dimsize(wThisNewRef,0),-1) wDestination
			wDestination[][]=nan
			wDestination[][] = wThisNewRef[p][q]
			Killwaves/Z wThisNewRef
		elseif(stringmatch(sInType,"PDF+"))
			sWavePath = DiffractionRef_PDFRelectionLoad()
			wave wThisNewRef = $sWavePath
			Redimension/N=(dimsize(wThisNewRef,0),-1) wDestination
			wDestination[][]=nan
			wDestination[][] = wThisNewRef[p][q]
			Killwaves/Z wThisNewRef
		elseif(stringmatch(sInType,"From Another Project"))
			sUserChoiceProject = COMBI_ChooseProject()
			setdatafolder $"root:COMBIgor:"+sUserChoiceProject+":DiffractionRefs:Peaks:"
			sTheseWaves = Wavelist("*",";","")
			SetDataFolder $sTheCurrentUserFolder 
			prompt sWaveSelected, "Which one?:", POPUP, sTheseWaves
			if (V_Flag)
				return -1// User canceled
			endif
			sWavePath = "root:COMBIgor:"+sUserChoiceProject+":DiffractionRefs:Peaks:"+sWaveSelected
			wave wThisNewRef = $sWavePath
			Redimension/N=(dimsize(wThisNewRef,0),-1) wDestination
			wDestination[][]=nan
			wDestination[][] = wThisNewRef[p][q]
			Killwaves/Z wThisNewRef
		endif
	endif
end


//load a crystal diffact relfection list ouptup file
Function/S DiffractionRef_PDFRelectionLoad()

	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//get file to read
	variable vFileRef
	Open/R/T=".xml" vFileRef
	string sOpened=S_fileName
	variable vFolderInPath = itemsinlist(sOpened,":")
	string sFullname = stringfromlist(vFolderInPath-1,sOpened,":")
	string sFileName = Cleanupname(removeending(sFullname,".xml"),0)
	
	//Read to string
	string sThisFile = PadString("",inf,4)
	FReadLine/T="" vFileRef, sThisFile
	Close vFileRef 
	
	//make list
	sThisFile = replaceString("\r",sThisFile,";")
	sThisFile = replaceString(num2char(13),sThisFile,"")
	sThisFile = replaceString(num2char(10),sThisFile,"")

	int iPDFDataStart = whichListItem("</pdf_data>",sThisFile,";")	
	int vTotalLines = itemsInList(sThisFile)
	int iLine
	
	string sInts="",sTheta="",sHs="",sKs="",sLs="",sDs=""
	string sThisLine, sThisTag1, sThisTag2
	for(iLine=iPDFDataStart;iLine<vTotalLines;iLine+=1)
		sThisLine = stringfromList(iLine,sThisFile)
		sThisLine = replaceString("<",sThisLine,";")
		sThisLine = replaceString(">",sThisLine,";")
		sThisLine = replaceString("/",sThisLine,"")
		sThisTag1 = stringfromlist(1,sThisLine)//tag1
		sThisTag2 = stringfromlist(3,sThisLine)//tag2
		if(!stringmatch(sThisTag1,sThisTag2))
			continue//pass on this line
		endif
		strswitch(sThisTag1)
			case "intensity": 
				sInts = AddListItem(stringfromList(2,sThisLine),sInts,";",inf)
				break
			case "h": 
				sHs = AddListItem(stringfromList(2,sThisLine),sHs,";",inf)
				break
			case "k":
				sKs = AddListItem(stringfromList(2,sThisLine),sKs,";",inf)
				break
			case "l":
				sLs = AddListItem(stringfromList(2,sThisLine),sLs,";",inf)
				break
			case "theta":
				sTheta = AddListItem(stringfromList(2,sThisLine),sTheta,";",inf)
				break
			case "da":
				sDs = AddListItem(stringfromList(2,sThisLine),sDs,";",inf)
				break
			default:
				break
		endswitch
	endfor
	int vTotalPeaks = itemsInList(sDs)
	
	//PackintoWave
	Make/O/N=(vTotalPeaks,7) $sFileName
	wave wNewPeakList = $"root:"+sFileName
	setdimlabel 1,0,H,wNewPeakList
	setdimlabel 1,1,K,wNewPeakList
	setdimlabel 1,2,L,wNewPeakList
	setdimlabel 1,3,dHKL,wNewPeakList
	setdimlabel 1,4,TwoTheta,wNewPeakList
	setdimlabel 1,5,Q,wNewPeakList
	setdimlabel 1,6,FractionMaxIntensity,wNewPeakList
	for(iLine=0;iLine<vTotalPeaks;iLine+=1)
		wNewPeakList[iLine][0] = str2num(stringfromlist(iLine,sHs))
		wNewPeakList[iLine][1] = str2num(stringfromlist(iLine,sKs))
		wNewPeakList[iLine][2] = str2num(stringfromlist(iLine,sLs))
		wNewPeakList[iLine][3] = str2num(stringfromlist(iLine,sDs))
		wNewPeakList[iLine][4] = str2num(stringfromlist(iLine,sTheta))
		wNewPeakList[iLine][5] = (2*pi)/str2num(stringfromlist(iLine,sDs))
		wNewPeakList[iLine][6] = str2num(stringfromlist(iLine,sInts))
	endfor
	
	//return name of waave
	return sFileName
end

function/S DiffractionRef_RefList(sOption)
	string sOption //"Profiles" or "Peaks"
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	string sProject  = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sFolderPath = "root:COMBIgor:"+sProject+":DiffractionRefs:"+sOption+":"
	string sLibrary  = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	
	if(stringmatch(sOption,"Action"))
		return "See Ref;Add to Top;Compare"
	endif
	
	if(stringmatch(sOption,"Scale"))
		return "Q;TwoTheta"
	endif
	
	if(stringmatch(sOption,"Libraries"))
		return Combi_TableList(sProject,2,"All","Libraries")
	endif
	
	if(stringmatch(sOption,"DataTypes"))
		return Combi_TableList(sProject,2,sLibrary,"DataTypes")
	endif
	setDataFolder $sFolderPath
	string sAllRefs = Wavelist("*",";","")
	SetDataFolder $sTheCurrentUserFolder 
	return sAllRefs
end

function/S DiffractionRef_SoftwareList()
	string sOptions
	if(COMBI_CheckForInstrument("BrukerXRD")==1)
		sOptions = "DiffracPlus;CrystalDiffract;Vesta;PDF+;ICSD;From Another Project"
	else
		sOptions = "CrystalDiffract;Vesta;PDF+;ICSD;From Another Project"
	endif
	return sOptions
end

function DiffractionRef_DoAction(ctrlName) : ButtonControl
	string ctrlName
	string sProject  = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sAction = COMBI_GetPluginString(sPluginName,"sAction",sProject)
	string sProfile = COMBI_GetPluginString(sPluginName,"sProfile",sProject)
	string sPeaks = COMBI_GetPluginString(sPluginName,"sPeaks",sProject)
	string sScale = COMBI_GetPluginString(sPluginName,"sScale",sProject)
	
	string sProfileNames, sPeakNames
	int iProfile, iPeak
	if(stringmatch(sProfile,"All"))
		sProfileNames = DiffractionRef_RefList("Profiles")
	else
		sProfileNames = sProfile
	endif
	
	if(stringmatch(sPeaks,"All"))
		sPeakNames = DiffractionRef_RefList("Peaks")
	else
		sPeakNames = sPeaks
	endif
	
	if(stringmatch(ctrlName,"btDoProfileAction"))
		for(iProfile=0;iProfile<itemsinlist(sProfileNames);iProfile+=1)
			if(stringmatch(sAction,"Add to Top"))
				DiffractionRef_AddProfile2Top(sProject,stringfromlist(iProfile,sProfileNames),sScale)
			elseif(stringmatch(sAction,"See Ref"))
				DiffractionRef_SeeRefData(sProject,stringfromlist(iProfile,sProfileNames))
			endif
		endfor
		if(stringmatch(sAction,"Compare"))
			
		endif
	endif
	
	if(stringmatch(ctrlName,"btDoPeakAction"))
		for(iPeak=0;iPeak<itemsinlist(sPeakNames);iPeak+=1)
			if(stringmatch(sAction,"Add to Top"))
				
			elseif(stringmatch(sAction,"See Ref"))
				DiffractionRef_SeePeaks(sProject,stringfromlist(iPeak,sPeakNames))
			endif
		endfor
		if(stringmatch(sAction,"Compare"))
			DiffractionRef_ComparePeaks(sProject,stringfromlist(iPeak,sPeakNames),"Peaks")
		endif
	endif
	
	
end

function DiffractionRef_SeeRefData(sProject,sWaveName)
	string sProject
	string sWaveName 

	wave wThisRef2Display = $"root:COMBIgor:"+sProject+":DiffractionRefs:Profiles:"+sWaveName
	int iProfileLength = dimsize(wThisRef2Display,0)
	string sTraceName = sWaveName+"_Profile"
	KillWindow/Z $sWaveName+"_RefPlots"
	
	int iHeight, iTopMargin
	if(waveexists($"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+sWaveName))
		iHeight = 260
	else
		iHeight = 200
	endif
	
	Display/K=1/L/B/N=$sWaveName+"_RefPlots" wThisRef2Display[][3]/TN=$sWaveName+"_Q" vs wThisRef2Display[][1]
	Appendtograph/R/T/W=$sWaveName+"_RefPlots" wThisRef2Display[][3]/TN=$sWaveName+"_QTop" vs wThisRef2Display[][1]
	ModifyGraph/W=$sWaveName+"_RefPlots" rgb=(65535,0,0)
	DoWindow/T/W=$sWaveName+"_RefPlots" $sWaveName+"_RefPlots",sWaveName
	
	ModifyGraph/W=$sWaveName+"_RefPlots" width=800,height=100
	Label/W=$sWaveName+"_RefPlots" left "Int. / (Max Int.)"
	Label/W=$sWaveName+"_RefPlots" bottom "Q (2π/Å) "
	ModifyGraph/W=$sWaveName+"_RefPlots" minor=1,btLen=3,stLen=1
	ModifyGraph/W=$sWaveName+"_RefPlots" fSize=14
	ModifyGraph/W=$sWaveName+"_RefPlots" hbFill=2
	ModifyGraph/W=$sWaveName+"_RefPlots" mode=7,lsize=2
	ModifyGraph/W=$sWaveName+"_RefPlots" margin(left)=50,margin(bottom)=50,margin(right)=25
	ModifyGraph/W=$sWaveName+"_RefPlots" margin(top)=iHeight
	ModifyGraph/W=$sWaveName+"_RefPlots" lblMargin=10
	ModifyGraph/W=$sWaveName+"_RefPlots" nticks(left)=1,nticks(right)=1,nticks(bottom)=20,nticks(top)=20
	ModifyGraph/W=$sWaveName+"_RefPlots" zapTZ(left)=1,zapTZ(right)=1
	ModifyGraph/W=$sWaveName+"_RefPlots" manTick(left)={1,1,0,2},manTick(right)={0,1,0,2}
	ModifyGraph/W=$sWaveName+"_RefPlots" manMinor(left)={0,50},manMinor(right)={0,50}
	ModifyGraph/W=$sWaveName+"_RefPlots" tickEnab(left)={0,1},tickEnab(right)={0,1}
	ModifyGraph/W=$sWaveName+"_RefPlots" btLen=4
	ModifyGraph/W=$sWaveName+"_RefPlots" grid(right)=0,grid(left)=1
	ModifyGraph/W=$sWaveName+"_RefPlots" grid(top)=0,grid(bottom)=1
	ModifyGraph/W=$sWaveName+"_RefPlots" noLabel(top)=2
	ModifyGraph/W=$sWaveName+"_RefPlots" stLen=2
	SetAxis/W=$sWaveName+"_RefPlots" right 0,1
	ModifyGraph/W=$sWaveName+"_RefPlots" standoff=0
	ModifyGraph/W=$sWaveName+"_RefPlots" gridRGB=(34952,34952,34952)
	SetAxis/W=$sWaveName+"_RefPlots" bottom wThisRef2Display[0][1],wThisRef2Display[iProfileLength-1][1]
	SetAxis/W=$sWaveName+"_RefPlots" top wThisRef2Display[0][1],wThisRef2Display[iProfileLength-1][1]
	SetAxis/W=$sWaveName+"_RefPlots" left 0,1
	
	
	Display/W=(0,iHeight-225,600,iHeight-50)/L/B/HOST=$sWaveName+"_RefPlots"/N=$"RefPlotTT" wThisRef2Display[][3]/TN=$sWaveName+"_TT" vs wThisRef2Display[][0]
	Appendtograph/W=$sWaveName+"_RefPlots#RefPlotTT"/T/R wThisRef2Display[][3]/TN=$sWaveName+"_TTTop" vs wThisRef2Display[][0]
	
	
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" width=800,height=100
	Label/W=$sWaveName+"_RefPlots#RefPlotTT" left "Int. / (Max Int.)"
	Label/W=$sWaveName+"_RefPlots#RefPlotTT" bottom "2Theta (deg.) "
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" minor=1,btLen=3,stLen=1
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" fSize=14
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" hbFill=2
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" mode=7,lsize=2
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" margin(left)=50,margin(bottom)=50,margin(right)=25
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" margin(top)=25
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" lblMargin=10
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" nticks(left)=1,nticks(right)=1,nticks(bottom)=20,nticks(top)=20
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" zapTZ(left)=1,zapTZ(right)=1
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" manTick(left)={1,1,0,2},manTick(right)={0,1,0,2}
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" manMinor(left)={0,50},manMinor(right)={0,50}
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" tickEnab(left)={0,1},tickEnab(right)={0,1}
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" btLen=4
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" grid(right)=0,grid(left)=1
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" grid(top)=0,grid(bottom)=1
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" noLabel(top)=2
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" stLen=2
	SetAxis/W=$sWaveName+"_RefPlots#RefPlotTT" right 0,1
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" standoff=0
	ModifyGraph/W=$sWaveName+"_RefPlots#RefPlotTT" gridRGB=(34952,34952,34952)
	SetAxis/W=$sWaveName+"_RefPlots#RefPlotTT" bottom wThisRef2Display[0][0],wThisRef2Display[iProfileLength-1][0]
	SetAxis/W=$sWaveName+"_RefPlots#RefPlotTT" top wThisRef2Display[0][0],wThisRef2Display[iProfileLength-1][0]
	SetAxis/W=$sWaveName+"_RefPlots#RefPlotTT" left 0,1

	if(waveexists($"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+sWaveName))
		wave wThisRef2DisplayPeaks = $"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+sWaveName
		int iPeak
		for(iPeak=0;iPeak<dimsize(wThisRef2DisplayPeaks,0);iPeak+=1)
			variable vThisQ = wThisRef2DisplayPeaks[iPeak][5]
			variable vThisTT = wThisRef2DisplayPeaks[iPeak][4]
			string sThisTag = "\\Z14("+num2str(wThisRef2DisplayPeaks[iPeak][0])+num2str(wThisRef2DisplayPeaks[iPeak][1])+num2str(wThisRef2DisplayPeaks[iPeak][2])+")"
			string sThisName = "P"+num2str(wThisRef2DisplayPeaks[iPeak][0])+num2str(wThisRef2DisplayPeaks[iPeak][1])+num2str(wThisRef2DisplayPeaks[iPeak][2])
			sThisName = cleanupName(sThisName,0)
			int iQPt = DiffractionRef_GetRowFromColumn(wThisRef2Display,vThisQ,1,1)
			int iTTPt = DiffractionRef_GetRowFromColumn(wThisRef2Display,vThisTT,1,0)
			//SetDrawEnv xcoord= bottom,ycoord= abs,textxjust= 1,textrot= 90,fsize= 14,save
			if(iQPt!=0&&iQPt!=(dimsize(wThisRef2Display,0)-1))
				Tag/W=$sWaveName+"_RefPlots"/X=0/Y=3/C/N=$sThisName+"Q"/O=90/F=0/Z=1/B=1/I=1/A=MB/L=2/P=10 top, vThisQ," "+sThisTag
			endif
			if(iTTPt!=0&&iTTPt!=(dimsize(wThisRef2Display,0)-1))
				Tag/W=$sWaveName+"_RefPlots#RefPlotTT"/X=0/Y=3/C/N=$sThisName+"TT"/O=90/F=0/Z=1/B=1/I=1/A=MB/L=2/P=10 top, vThisTT," "+sThisTag
			endif
		endfor
	endif
	SetActiveSubwindow $sWaveName+"_RefPlots"
	
	TextBox/C/N=text0/F=0/B=1/A=LT/X=5.00/Y=5.00/E=2 "\K(65535,0,0)\\Z14"+sWaveName

end

function DiffractionRef_GetRowFromColumn(Wave2Search,v2Find,vTolerance,iColumn)
	wave Wave2Search
	variable v2Find,vTolerance
	int iColumn
	
	int iRow, iRow2Return = 0
	variable vDelta = inf
	
	for(iRow=0;iRow<dimsize(Wave2Search,0);iRow+=1)
		variable vThisDelta = abs(v2Find-Wave2Search[iRow][iColumn])
		if(vThisDelta<vDelta)
			if(vThisDelta<vTolerance)
				iRow2Return = iRow
				vDelta = vThisDelta
			endif
		endif
	endfor
	
	return iRow2Return
end

function DiffractionRef_AddProfile2Top(sProject,sWaveName,sType)
	string sProject
	string sWaveName 
	string sType //"TwoTheta" or "Q"
	
	int iColumn
	if(stringmatch(sType,"TwoTheta"))
		iColumn = 0
	elseif(stringmatch(sType,"Q"))
		iColumn = 1
	else
		return -1
	endif

	wave wThisRef2Display = $"root:COMBIgor:"+sProject+":DiffractionRefs:Profiles:"+sWaveName
	int iProfileLength = dimsize(wThisRef2Display,0)
	
	if(waveexists($"root:COMBIgor:"+sProject+":DiffractionRefs:Profiles:"+sWaveName))
		
		//get window info
		string sTopGraphName=Stringfromlist(0,WinList("*", ";","WIN:1"))
		
		//get user data
		string sRefsAlreadyHere = GetUserData(sTopGraphName,"","DiffractionRefs")
		//add user data
		if(whichlistitem(sWaveName,sRefsAlreadyHere)!=-1)
			DoAlert/T="Duplicate trace",0,"That trace is already on the plot."
			return-1
		else
			SetWindow $sTopGraphName userdata(DiffractionRefs)+=sWaveName+";" 
		endif
		
		Delayupdate 
		//getwindow size
		GetWindow $sTopGraphName, gsize
		variable vWTop = V_top
		variable vWBottom = V_bottom
		variable vWLeft = V_left
		variable vWRight = V_right
		
		//get axis range
		GetAxis/Q Bottom
		variable vBMin = V_min
		variable vBMax = V_max
		
		//get plot sizes
		GetWindow $sTopGraphName, psize
		variable vPTop = V_top
		variable vPBottom = V_bottom
		variable vPLeft = V_left
		variable vPRight = V_right
		
		//adjustmargin
		variable vOldMarg = vPTop
		variable vNewMarg = vOldMarg+25
		ModifyGraph/W=$sTopGraphName margin(top)=vNewMarg
		
		//move exsiting down
		int iPreRef
		string sThisColor
		int vTotalPre = itemsinlist(sRefsAlreadyHere)
		For(iPreRef=0;iPreRef<vTotalPre;iPreRef+=1)
			string sThisPre = stringfromlist(iPreRef,sRefsAlreadyHere)
			GetWindow $sTopGraphName+"#"+sThisPre gsize
			variable vPreGTop = V_top
			variable vPreGBottom = V_bottom
			variable vPreGLeft = V_left
			variable vPreGRight = V_right
			MoveSubwindow/W=$sTopGraphName+"#"+sThisPre fnum=(vPreGLeft,vPreGTop+25,vPreGRight,vPreGBottom+25)
			//change colors
			sThisColor = COMBI_GetUniqueColor(iPreRef+1,vTotalPre+1)
			Execute "ModifyGraph/W="+sTopGraphName+"#"+sThisPre+" rgb="+sThisColor
			TextBox/W=$sTopGraphName+"#"+sThisPre/C/N=$sThisPre "    \K"+sThisColor+" "+sThisPre
		endfor
		sThisColor = COMBI_GetUniqueColor(iPreRef+1,vTotalPre+1)
		//add ref
		Display/HOST=$sTopGraphName/W=(vWLeft,vWTop,vWRight,vWTop+25)/N=$sWaveName wThisRef2Display[][3]/TN=$sWaveName vs wThisRef2Display[][iColumn] as sWaveName
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName margin(top)=5
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName margin(left)=vPLeft
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName margin(right)=vWRight-vPRight
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName margin(bottom)=5
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName nticks(bottom)=0
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName mirror=2
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName noLabel=2
		SetAxis/W=$sTopGraphName+"#"+sWaveName left 0,1
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName manTick(left)={0,0,0,1}
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName tickEnab(left)={-4,-3}
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName tickEnab(bottom)={-inf,-500}
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName manTick(left)={0,0,0,1}
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName manMinor(left)={0,50}
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName mode=7
		ModifyGraph/W=$sTopGraphName+"#"+sWaveName hbFill=2
		execute "ModifyGraph/W="+sTopGraphName+"#"+sWaveName+" rgb="+sThisColor

		SetAxis/W=$sTopGraphName+"#"+sWaveName bottom V_min,V_max
		
		//add ref tag
		int iY,iX
		iY=floor(30)
		if(vPLeft>(vWRight-vPRight))
			iX=floor(0)
			TextBox/W=$sTopGraphName+"#"+sWaveName/N=$sWaveName+"#"+sWaveName/F=0/Z=1/B=1/A=LT/X=(iX)/Y=(iY)/E=2 "   \K"+sThisColor+sWaveName
		else
			iX=floor(vPRight/vWRight*100)
			TextBox/W=$sTopGraphName+"#"+sWaveName/N=$sWaveName/F=0/Z=1/B=1/A=LT/X=(iX)/Y=(iY)/E=2 "   \K"+sThisColor+sWaveName
		endif
		
		SetActiveSubwindow $sTopGraphName
		
	endif
	
end

function DiffractionRef_SeePeaks(sProject,sWaveName)
	string sProject
	string sWaveName 
	//root:COMBIgor:MyProject:DiffractionRefs:Peaks:Wz_AlN
	string sTitle = sWaveName+" peak list in COMBIgor"
	wave wRef = $"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+sWaveName
	KillWindow/Z $sWaveName+"_Ref"
	Edit/K=1/N=$sWaveName+"_Ref"/W=(10,10,510,710) wRef.ld as sTitle
	ModifyTable/W=$sWaveName+"_Ref" alignment=1
	ModifyTable/W=$sWaveName+"_Ref" sigDigits=4
	ModifyTable/W=$sWaveName+"_Ref" width=50
	
end

function DiffractionRef_ComparePeaks(sProject,sWaveName,sType)
	string sProject
	string sWaveName 
	string sType//"Peaks" or "Profile"

	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 

	//from storage
	string sDegreeAxis = COMBI_GetPluginString(sPluginName,"sDegreeAxis",sProject)
	string sIntensityAxis = COMBI_GetPluginString(sPluginName,"sIntensityAxis",sProject)
	string sProfile = COMBI_GetPluginString(sPluginName,"sProfile",sProject)
	string sPeaks = COMBI_GetPluginString(sPluginName,"sPeaks",sProject)
	string sScale = COMBI_GetPluginString(sPluginName,"sScale",sProject)
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	int vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)

	//waves
	wave/Z wDegree = $COMBI_DataPAth(sProject,2)+sLibrary+":"+sDegreeAxis
	wave/Z wIntensity = $COMBI_DataPAth(sProject,2)+sLibrary+":"+sIntensityAxis
	If(!waveExists(wDegree))
		DoAlert/T="No Degree Selected",0,"Please select a degree vector data wave"
		return-1
	Endif
	If(!waveExists(wIntensity))
		DoAlert/T="No Intensity Selected",0,"Please select an intensity vector data wave"
		return-1
	Endif
	If(dimsize(wDegree,1)!=dimsize(wIntensity,1))
		DoAlert/T="Unequal Dim Size",0,"These vectors are of different length, I quit"
		return-1
	Endif
	
	//which peaks/profiles?
	string sProfileNames, sPeakNames
	int iProfile, iPeak, iSample
	if(stringmatch(sProfile,"All"))
		sProfileNames = DiffractionRef_RefList("Profiles")
	else
		sProfileNames = sProfile
	endif
	if(stringmatch(sPeaks,"All"))
		sPeakNames = DiffractionRef_RefList("Peaks")
	else
		sPeakNames = sPeaks
	endif
	
	//find peaks in selected data
	//to manipulate
	Killwindow/Z PeakFindingPluginWorkings
	Display/K=1/N=PeakFindingPluginWorkings/W=(10,10,510,510)
	NewDataFolder/O/S PeakFinder
	Make/O/N=(dimsize(wIntensity,0),dimsize(wIntensity,1)) $sIntensityAxis+"_Raw"
	Make/O/N=(dimsize(wIntensity,0),dimsize(wIntensity,1)) $sIntensityAxis+"_Smooth"
	Make/O/N=(dimsize(wIntensity,0),dimsize(wIntensity,1)) $sIntensityAxis+"_Diff"
	Make/O/N=(dimsize(wIntensity,0),dimsize(wIntensity,1)) $sIntensityAxis+"_Peaks"
	Make/O/N=(dimsize(wIntensity,1)) $sIntensityAxis+"_Temp"
	SetDataFolder $sTheCurrentUserFolder 
	wave wRaw = $"root:PeakFinder:"+sIntensityAxis+"_Raw"
	wave wSmooth = $"root:PeakFinder:"+sIntensityAxis+"_Smooth"
	wave wDiff = $"root:PeakFinder:"+sIntensityAxis+"_Diff"
	wave wPeaks = $"root:PeakFinder:"+sIntensityAxis+"_Peaks"
	wave wTemp = $"root:PeakFinder:"+sIntensityAxis+"_Temp"
	
	for(iSample=0;iSample<dimsize(wIntensity,0);iSample+=1)
		wTemp[] = wIntensity[iSample][p]
		wRaw[iSample][] = (wIntensity[iSample][q]-wavemin(wTemp))/(wavemax(wTemp)-wavemin(wTemp))
		wSmooth[iSample][] = wRaw[iSample][q]
		wDiff[iSample][] = wRaw[iSample][q]//for smoothed
	endfor
	wPeaks[][] = nan
	
	//smooth data
	Smooth/S=4/DIM=1 7,wSmooth
	Smooth/S=4/DIM=1 7,wDiff
	
	//differentiate
	Differentiate/DIM=1	wDiff
	
	//search for zero crossings in diff spec
	int vStreakTol = 10
	int bNeg, bPos, iVector, iNStreak, iPStreak, iNCheck, iAhead
	string sAllResults = ""

	for(iSample=0;iSample<dimsize(wIntensity,0);iSample+=1)
		iNStreak = 0
		iPStreak = 0
		bNeg = 0
		bPos = 0
		wTemp[] = wIntensity[iSample][p]
		variable vMedian = median(wTemp)
		for(iVector=0;iVector<dimsize(wIntensity,1);iVector+=1)
			if(wIntensity[iSample][iVector]>vMedian)//more than median level
				if(wDiff[iSample][iVector]<0&&1==bPos)//transition from pos to negative
					if(iPStreak>vStreakTol)//streak positive was big enough
						iNCheck = 1
						for(iAhead=0;iAhead<vStreakTol;iAhead+=1)//look head
							if(iVector+iAhead<dimsize(wIntensity,1))//within wave range
								if(wDiff[iSample][iVector+iAhead]>0)//some positive ahead
									iNCheck = 0
								endif
							endif
						endfor
						if(iNCheck==1)
							wPeaks[iSample][iVector] = wRaw[iSample][iVector]
							sAllResults = AddListItem(DiffractionRef_FindClosestPeak(wDegree[iSample][iVector]),sAllResults)
						endif
					endif
				endif
			endif
			//update streak trackers
			if(wDiff[iSample][iVector]<0)//negative
				iNStreak+=1
				iPStreak = 0
			elseif(wDiff[iSample][iVector]>0)//positive
				iPStreak+=1
				iNStreak = 0
			endif
			
			//update trackers
			if(wDiff[iSample][iVector]<0)//negative
				bNeg = 1
				bPos = 0
			elseif(wDiff[iSample][iVector]>0)//positive
				bPos = 1
				bNeg = 0
			endif
			
		endfor
	endfor
	string sPeaks2Tag = ""
	for(iPeak=0;iPeak<itemsinlist(sAllResults);iPeak+=1)
		if(whichlistitem(stringfromlist(iPeak,sAllResults),sPeaks2Tag)==-1)
			if(strlen(stringfromlist(iPeak,sAllResults))>0)
				sPeaks2Tag = AddListItem(stringfromlist(iPeak,sAllResults),sPeaks2Tag)
			endif
		endif
	endfor
		
	//AddSubPlots
	Display/K=1/N=Raw/HOST=PeakFindingPluginWorkings/W=(0,0,500,100)
	Display/K=1/N=Smoothed/HOST=PeakFindingPluginWorkings/W=(0,100,500,200)
	Display/K=1/N=Diffed/HOST=PeakFindingPluginWorkings/W=(0,200,500,300)
	Display/K=1/N=Peaks/HOST=PeakFindingPluginWorkings/W=(0,400,500,500)
	
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		string sTraceName = sLibrary+"_Sample"+num2str(isample)
		AppendToGraph/W=PeakFindingPluginWorkings#Raw wRaw[iSample][]/TN=$sTraceName+"_Raw" vs wDegree[iSample][]
		AppendToGraph/W=PeakFindingPluginWorkings#Smoothed wSmooth[iSample][]/TN=$sTraceName+"_Smooth" vs wDegree[iSample][]
		AppendToGraph/W=PeakFindingPluginWorkings#Diffed wDiff[iSample][]/TN=$sTraceName+"_Diff" vs wDegree[iSample][]
		AppendToGraph/T/W=PeakFindingPluginWorkings#Peaks wPeaks[iSample][]/TN=$sTraceName+"_Peaks" vs wDegree[iSample][]
	endfor
	
	//format
	COMBI_ColorPlotTraces("Rainbow",sPlotName="PeakFindingPluginWorkings#Raw")
	TextBox/W=PeakFindingPluginWorkings#Raw/C/N=text0/F=0 "Raw Data"
	ModifyGraph/W=PeakFindingPluginWorkings#Raw margin(left)=40,margin(bottom)=20,margin(right)=5,margin(top)=5
	ModifyGraph/W=PeakFindingPluginWorkings#Raw mirror=2,grid=1,tick=3,zero=1,gridStyle=1,gridHair=3,gridRGB=(0,0,0), highTrip(left)=1,log(left)=1
	SetAxis/W=PeakFindingPluginWorkings#Raw left 0.001,1.1
	
	COMBI_ColorPlotTraces("Rainbow",sPlotName="PeakFindingPluginWorkings#Smoothed")
	TextBox/W=PeakFindingPluginWorkings#Smoothed/C/N=text0/F=0 "Smoothed Data"
	ModifyGraph/W=PeakFindingPluginWorkings#Smoothed margin(left)=40,margin(bottom)=20,margin(right)=5,margin(top)=5
	ModifyGraph/W=PeakFindingPluginWorkings#Smoothed mirror=2,grid=1,tick=3,zero=1,gridStyle=1,gridHair=3,gridRGB=(0,0,0), highTrip(left)=1,log(left)=1
	SetAxis/W=PeakFindingPluginWorkings#Smoothed left 0.001,1.1
	
	COMBI_ColorPlotTraces("Rainbow",sPlotName="PeakFindingPluginWorkings#Diffed")
	TextBox/C/N=text0/F=0/W=PeakFindingPluginWorkings#Diffed "Differentiated Data"
	ModifyGraph/W=PeakFindingPluginWorkings#Diffed margin(left)=40,margin(bottom)=20,margin(right)=5,margin(top)=5
	ModifyGraph/W=PeakFindingPluginWorkings#Diffed mirror=2,grid=1,tick=3,zero=1,gridStyle=1,gridHair=3,gridRGB=(0,0,0), highTrip(left)=1
	
	COMBI_ColorPlotTraces("Rainbow",sPlotName="PeakFindingPluginWorkings#Peaks")
	TextBox/C/N=text0/F=0/W=PeakFindingPluginWorkings#Peaks "Peaks in Data"
	ModifyGraph/W=PeakFindingPluginWorkings#Peaks margin(left)=40,margin(bottom)=20,margin(right)=5,margin(top)=5
	ModifyGraph/W=PeakFindingPluginWorkings#Peaks mirror=2,grid=1,tick=3,zero=1,gridStyle=1,gridHair=3,gridRGB=(0,0,0), highTrip(left)=1,mode=3,marker=19,msize=3,mrkThick=1,log(left)=1, mode=8,usePlusRGB=1, plusRGB=(0,0,0), mirror(top)=0,noLabel(top)=2, mirror(top)=1
	SetAxis/W=PeakFindingPluginWorkings#Peaks left 0.001,1.1
	
	SetActiveSubwindow PeakFindingPluginWorkings
	
	//add the peaks found
	for(iPeak=0;iPeak<itemsinlist(sPeaks2Tag);iPeak+=1)
		string sRefName = stringfromlist(0,stringfromList(iPeak,sPeaks2Tag),"@@")
		int iRefPeakIndex = str2num(stringfromlist(1,stringfromList(iPeak,sPeaks2Tag),"@@"))
		wave wThisRef2Tag = $"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+sRefName
		string sThisTag = sRefName+"  ("+num2str(wThisRef2Tag[iRefPeakIndex][%H])+num2str(wThisRef2Tag[iRefPeakIndex][%K])+num2str(wThisRef2Tag[iRefPeakIndex][%L])+")"
		Tag/W=PeakFindingPluginWorkings#Peaks/X=0/Y=(wThisRef2Tag[iRefPeakIndex][%FractionMaxIntensity]*30)/C/N=$sRefName+num2str(iRefPeakIndex)/O=90/F=0/Z=1/B=1/I=1/A=MB/L=2/P=10 top, wThisRef2Tag[iRefPeakIndex][%$sScale],"         "+sThisTag
	endfor
end


function/S  DiffractionRef_FindClosestPeak(vPeakPos)
	variable vPeakPos//value to find closest peak
	
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sDegreeAxis = COMBI_GetPluginString(sPluginName,"sDegreeAxis",sProject)
	string sIntensityAxis = COMBI_GetPluginString(sPluginName,"sIntensityAxis",sProject)
	string sProfile = COMBI_GetPluginString(sPluginName,"sProfile",sProject)
	string sPeaks = COMBI_GetPluginString(sPluginName,"sPeaks",sProject)
	string sExternalType = COMBI_GetPluginString(sPluginName,"sExternalType",sProject)
	string sExternalLocation = COMBI_GetPluginString(sPluginName,"sExternalLocation",sProject)
	string sSoftwavePref = COMBI_GetPluginString(sPluginName,"sSoftwavePref",sProject)
	string sAction = COMBI_GetPluginString(sPluginName,"sAction",sProject)
	string sScale = COMBI_GetPluginString(sPluginName,"sScale",sProject)
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	
	//which peaks/profiles?
	string sProfileNames, sPeakNames
	int iProfile, iSample
	if(stringmatch(sPeaks,"All"))
		sPeakNames = DiffractionRef_RefList("Peaks")
	else
		sPeakNames = sPeaks
	endif
	
	variable vThreshold
	if(stringmatch(sScale,"Q"))
		vThreshold = 0.05
	elseif(stringmatch(sScale,"TwoTheta"))
		vThreshold = 1
	endif
	
	//search all peak list
	int iRef,iPeak
	string s2return = ""
	string sAllPeakRefs = DiffractionRef_RefList("Peaks")
	for(iRef=0;iRef<itemsinList(sPeakNames);iRef+=1)
		wave wThisRef = $"root:COMBIgor:"+sProject+":DiffractionRefs:Peaks:"+stringfromlist(iRef,sPeakNames)
		for(iPeak=0;iPeak<dimsize(wThisRef,0);iPeak+=1)
			variable vThisPeakDelta = abs(wThisRef[iPeak][%$sScale]-vPeakPos)
			if(vThreshold>vThisPeakDelta)
				s2return = AddListItem(stringfromlist(iRef,sAllPeakRefs)+"@@"+num2str(iPeak),s2return)
			endif
		endfor
	endfor
	
	return s2return
end