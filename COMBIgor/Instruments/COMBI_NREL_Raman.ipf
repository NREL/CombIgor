#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Description/Summary of Procedure File
// Version History
// V1: Celeste Melamed _ Dec 2018 : Original Example Vector Loader 
// V1.1: Kevin Talley _ March 202 : NREL Raman Original Loader

//Description of procedure purpose:
//This instrument add-on is for the Purpose of loading a single tax file output from the custom Ramen spectroscopy system at the national renewable energy laboratory. 
//Each file is the result of measurement from a single library and no multi library handling capabilities are included.
//

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Instrument
Static StrConstant sInstrument = "NREL_Raman"


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this instrument
Menu "COMBIgor"
	SubMenu "Instruments"
		Submenu "NREL Raman"
			"(Loading"
			"Combi Data",/Q, COMBI_NREL_Raman()
			"Single measurement",/Q, NREL_Raman_LoadFile()
		end
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




//returns a list of descriptors for each of the globals used to define file loading. 
Function/S NREL_Raman_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for
	
	//This section builds the menu, access panel, and the Define process for this instrument
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring =""
	//specific cases depending on instrument need. 
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "InInstrumentMenu":
			twGlobals[1][0] = "No"
			break
		//This case determines whether the function is in the Access Panel; change to "No" if you don't want it there
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "NREL_Raman":
			sReturnstring = "NREL_Raman"
			break
		//these are the specific variables that are collected by the Define process
		case "sWaveLength":
			sReturnstring =  "Observed Photon Wavelength (nm):"
			break
		case "sIntensity":
			sReturnstring =  "Observed Raman Intensity:"
			break
		case "sWaveNumber":
			sReturnstring =  "Observed Raman Wavenumber (cm\\S-1\\M):"
			break
		case "sEnergy":
			sReturnstring =  "Observed Photon Energy (eV):"
			break
		case "vNumPoints":
			sReturnstring = "Data-points per spectra:"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	//puts global value into 0th row and 0th column of globals wave for other functions to access
	twGlobals[0][0] = sReturnstring 
	return sReturnstring
end


//this function will be executed when the user selects to define the Instrument in the Instrument definition panel
function NREL_Raman_Define()

	//get Instrument name
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	string sWaveLength
	string sIntensity
	string sWaveNumber
	string sEnergy
	variable vNumPoints
	
	//initialize the values depending on if they existed previously 
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		//FOR DEVELOPERS: Make sure these all match the globals defined above!
		sWaveLength = COMBI_GetInstrumentString(sThisInstrumentName,"sWaveLength",sProject)
		sIntensity = COMBI_GetInstrumentString(sThisInstrumentName,"sIntensity",sProject)
		sWaveNumber = COMBI_GetInstrumentString(sThisInstrumentName,"sWaveNumber",sProject)
		sEnergy = COMBI_GetInstrumentString(sThisInstrumentName,"sEnergy",sProject)
		vNumPoints = COMBI_GetInstrumentNumber(sThisInstrumentName,"vNumPoints",sProject)

	else 
		//not previously defined, start with default values 
		//FOR DEVELOPERS: Put in reasonable default values for your specific Globals here
		sWaveLength = "Raman_Wavelength" 
		sIntensity = "Raman_Intensity"
		sWaveNumber = "Raman_WaveNumber"
		sEnergy = "Raman_Energy"
		vNumPoints = 1015
		//set the global
		Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)
	endif
	
		
	//get names for data types
	//cleanupname makes sure the data type name is allowed
	sWaveLength = cleanupname(COMBI_DataTypePrompt(sProject,sWaveLength,NREL_Raman_Descriptions("sWaveLength"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sWaveLength,"CANCEL"))
		return -1
	endif
	
	//cleanupname makes sure the data type name is allowed
	sIntensity = cleanupname(COMBI_DataTypePrompt(sProject,sIntensity,NREL_Raman_Descriptions("sIntensity"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sIntensity,"CANCEL"))
		return -1
	endif
	
	//cleanupname makes sure the data type name is allowed
	sWaveNumber = cleanupname(COMBI_DataTypePrompt(sProject,sWaveNumber,NREL_Raman_Descriptions("sWaveNumber"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sWaveNumber,"CANCEL"))
		return -1
	endif
	
	//cleanupname makes sure the data type name is allowed
	sEnergy = cleanupname(COMBI_DataTypePrompt(sProject,sEnergy,NREL_Raman_Descriptions("sEnergy"),0,1,0,2),0)
	//if cancel was selected -- break
	if(stringmatch(sEnergy,"CANCEL"))
		return -1
	endif
	
	//points per spectra
	vNumPoints = COMBI_NumberPrompt(vNumPoints,NREL_Raman_Descriptions("vNumPoints"),"","Data points?")
	if(numtype(vNumPoints)==2)
		return -1
	endif
	
	//mark as defined by storing instrument globals in sProject for this project
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sWaveLength",sWaveLength,sProject)// store Instrument global
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sIntensity",sIntensity,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sWaveNumber",sWaveNumber,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sEnergy",sEnergy,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vNumPoints",num2str(vNumPoints),sProject)// store Instrument global 
	//labels
	COMBIDisplay_Global(sWaveLength,"Wavelength (nm)","Label")
	COMBIDisplay_Global(sIntensity,"Raman Intensity (a.u.)","Label")
	COMBIDisplay_Global(sWaveNumber,"Wavenumber (cm\\S-1\\M)","Label")
	COMBIDisplay_Global(sEnergy,"Energy (eV)","Label")
	//mark as defined by storing the instrument name in the main globals
	Combi_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,"COMBIgor")

	//reload definition panel
	COMBI_InstrumentDefinition()
	
end


////this function will be executed when the user selects to load data button in the Instrument definition panel
function NREL_Raman_Load()

	//initializes the instrument
	Combi_InstrumentReady("NREL_Raman")
	//get Instrument name and project name, store in local strings
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//prompts for project, load type (ie individual file or folder), and wavelength
	//FOR DEVELOPER: Edit here to reflect the specific load type and number (if necessary) for your instrument.
	string sIsNew
	prompt sProject, "Project:", Popup, Combi_Projects()
	prompt sIsNew, "Measured after February 1, 2018?", popup, "Yes;No"
	
	DoPrompt/HELP="This tells me how you want to load data." "Loading Input", sIsNew
	//this breaks if the user selects cancel
	if (V_Flag)
		return -1
	endif
	
	//library
	string sLibrary = COMBI_LibraryPrompt(sProject,"New","Name of Library:",0,1,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
		
	//if the user has the command line setting on, print the call line so the user can use it programmatically
	if(stringmatch("Yes",Combi_GetGlobalString("sCommandLines","COMBIgor")))
		Print "NREL_Raman_Loader(\""+sProject+"\",\""+sLibrary+"\",\""+sIsNew+"\")"
	endif
	//call the LoadFolder function
	NREL_Raman_Loader(sProject,sLibrary,sIsNew)
	
end



//this function loads a file of Raman Data
function NREL_Raman_Loader(sProject,sLibrary,sIsNew)
	//define strings and variables	
	string sProject,sLibrary,sIsNew
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	variable vIndex
	string sThisInstrumentName = "NREL_Raman"
	
	//defined globals for Raman Instrument
	string sWaveLength = Combi_GetInstrumentString("NREL_Raman","sWaveLength",sProject)
	string sIntensity = Combi_GetInstrumentString("NREL_Raman","sIntensity",sProject)
	string sWaveNumber = Combi_GetInstrumentString("NREL_Raman","sWaveNumber",sProject)
	string sEnergy = Combi_GetInstrumentString("NREL_Raman","sEnergy",sProject)
	variable  vNumPoints = Combi_GetInstrumentNumber("NREL_Raman","vNumPoints",sProject)
	
	//vTotalSamples is the number of samples on a standard library (usually 44)
	variable vTotalSamples = Combi_GetGlobalNumber("vTotalSamples",sProject)
	variable vTotalColumns = Combi_GetGlobalNumber("vTotalColumns",sProject)
	variable vTotalRows = Combi_GetGlobalNumber("vTotalRows",sProject)
	variable vRowSpacing = Combi_GetGlobalNumber("vRowSpacing",sProject)
	variable vColumnSpacing = Combi_GetGlobalNumber("vColumnSpacing",sProject)
	
	// get global import folder
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	//if the predefined import folder exists, set the initial path to that folder
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
	endif
	LoadWave/G/D/A=RamanLoaderWaves/Q
	
	//stores some path info in v_flag and s_path variables
	string sThisLoadFile = S_path+":"+S_fileName //for storing source folder in data log

	//check for 44 points and 4 waves
	string sLoadedWaves = S_waveNames
	int iWave
	if(itemsInList(sLoadedWaves)!=4)
		DoAlert/T="Wrong file format!" 0,"This File doesn't have 4 columns. It should be columns of X, Y, Wavelength, and Intensity"
		for(iWave=0;iWave<itemsInList(sLoadedWaves);iWave+=1)
			killwaves $"root:"+stringfromList(iWave,sLoadedWaves)
		endfor
		Return -1
	endif
	wave wFirst = $"root:"+stringfromList(0,sLoadedWaves)
	if(dimSize(wFirst,0)!=(vTotalSamples*vNumPoints))
		DoAlert/T="Wrong file format!" 0,"This File doesn't have "+num2str(vTotalSamples*vNumPoints)+" data points (rows). It should have "+num2str(vNumPoints)+" data points for each of the "+num2str(vTotalSamples)+" samples."
		for(iWave=0;iWave<itemsInList(sLoadedWaves);iWave+=1)
			killwaves $"root:"+stringfromList(iWave,sLoadedWaves)
		endfor
		Return -1
	endif
	
	//ordering wave
	Make/O/N=(vTotalSamples)/D RamanSampleOrder
	wave wSampleOrder = root:RamanSampleOrder
	int vNumSwitches = 0
	variable vMethod = 1
	int vPos = 0
	int i
	for(i = 0; i < vTotalSamples; i += 1)
		if(vMethod == 1)
			wSampleOrder[i] = (vTotalRows - vNumSwitches)*vTotalColumns - vPos - 1
			vPos += 1
		endif
		if(vMethod == -1)
			wSampleOrder[i] = (vTotalRows - vNumSwitches - 1)*vTotalColumns + vPos
			vPos += 1
		endif
		if(vPos == vTotalColumns)
			vMethod = -vMethod
			vNumSwitches += 1
			vPos = 0
		endif
	endfor
	
	//get waves
	if(stringmatch("Yes",sIsNew))
		wave wX_In = $"root:"+stringfromList(0,sLoadedWaves)
		wave wY_In = $"root:"+stringfromList(1,sLoadedWaves)
		wave wWaveNumber_In = $"root:"+stringfromList(2,sLoadedWaves)
		wave wInt_In = $"root:"+stringfromList(3,sLoadedWaves)
	elseif(stringmatch("No",sIsNew))
		wave wY_In = $"root:"+stringfromList(0,sLoadedWaves)
		wave wX_In = $"root:"+stringfromList(1,sLoadedWaves)
		wave wWaveNumber_In = $"root:"+stringfromList(2,sLoadedWaves)
		wave wInt_In = $"root:"+stringfromList(3,sLoadedWaves)
	endif
	
	//destination waves
	COMBI_AddDataType(sProject,sLibrary,sWaveLength,2,iVDim=vNumPoints) 
	COMBI_AddDataType(sProject,sLibrary,sIntensity,2,iVDim=vNumPoints) 
	COMBI_AddDataType(sProject,sLibrary,sWaveNumber,2,iVDim=vNumPoints) 
	COMBI_AddDataType(sProject,sLibrary,sEnergy,2,iVDim=vNumPoints) 
	wave wWaveLength_Stored = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sWaveLength
	wave wInt_Stored = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sIntensity
	wave wWaveNumber_Stored = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sWaveNumber
	wave wEnergy_Stored = $"root:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sEnergy	
	
	//movedata
	int iRow,iCol,iSample,iIndex,iMeasured
	for(iRow=0;iRow<vTotalRows;iRow+=1)
		for(iCol=0;iCol<vTotalColumns;iCol+=1)
			iSample = iRow*vTotalColumns+iCol
			iMeasured = wSampleOrder[iSample]
			iIndex = iMeasured*vNumPoints
			//move data
			wWaveLength_Stored[iSample][] = 1E7/wWaveNumber_In[iIndex+q]//convert from cm^-1 to nm
			wInt_Stored[iSample][] = wInt_In[iIndex+q]
			wWaveNumber_Stored[iSample][] = wWaveNumber_In[iIndex+q]
			wEnergy_Stored[iSample][] = 0.0123997/wWaveLength_Stored[iSample][q]//convert from nm to eV
		endfor
	endfor
	
	//clean up
	killwaves wY_In, wX_In, wWaveNumber_In, wInt_In, wSampleOrder

	////this section adds important info to data log////
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Source File: "+sThisLoadFile
	sLogEntry2 = "Library Samples: "+num2str(1)+" to "+num2str(vTotalSamples)
	sLogEntry3 = "Raw Data: "+sIntensity+" vs "+sWaveNumber
	sLogEntry4 = ""
	sLogEntry5 = ""
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	Combi_Add2Log(sProject,sLibrary,"NREL_Raman",1,sLogText)			
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
	
	//if plot on loading
	if(stringmatch(COMBI_GetGlobalString("sPlotOnLoad","COMBIgor"),"Yes"))
		COMBIDisplay_Plot(sProject,"NewPlot","Vector",sLibrary,sWaveNumber,"","Linear","Auto","Auto","Bottom","Vector",sLibrary,sIntensity,"","Linear","Auto","Auto","Left","","","","Linear","Auto","Auto","Rainbow","","","","Linear","Auto","Auto",0,19,"All","All","All","All","All","All")
		ModifyGraph tick=2,mirror=3
		ModifyGraph log(left)=1
	endif
	
end


//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
//FOR DEVELOPERS: Change "NREL_Raman" to the name of your Instrument; make sure your loader is appropriately named COMBI_YourInstrument.ipf
function COMBI_NREL_Raman()
	COMBI_GiveGlobal("sInstrumentName","NREL_Raman","COMBIgor")
	COMBI_InstrumentDefinition()
end

// for single point load
function NREL_Raman_LoadFile()
	
	//choose file and load
	LoadWave/G/D/A=RamanLoaderWaves/Q
	string sLoadedWaves = S_waveNames
	wave wWaveNumber_In = $"root:"+stringfromList(2,sLoadedWaves)
	wave wInt_In = $"root:"+stringfromList(3,sLoadedWaves)
	
	//rename
	setscale/P x,dimOffset(wWaveNumber_In,0),dimdelta(wWaveNumber_In,0),"cm^-1",wWaveNumber_In
	killwaves/Z Raman_WaveNumber,Raman_Intensity
	rename wWaveNumber_In,Raman_WaveNumber
	rename wInt_In,Raman_Intensity
	
	//clean
	killwaves $stringfromList(0,sLoadedWaves), $stringfromList(1,sLoadedWaves)
	
end