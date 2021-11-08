#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ APRIL 2019 : Original

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Instrument
Static StrConstant sInstrument = "Scanatron5000"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this builds the drop-down menu for this instrument
Menu "COMBIgor"
	SubMenu "Instruments"
		 SubMenu "Scanatron 5000"
		 "Loading",/Q, COMBI_Scanatron5000()
		 "Make Image",/Q, COMBI_Scanatron5000_SelectImage()
		 end
	end
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//returns a list of descriptors for each of the globals used to define file loading. 
Function/S Scanatron5000_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for

	//This section builds the menu, access panel, and the Define process for this instrument
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring =""
	//The strswitch section builds the define panel for each instrument global
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "Yes"
			break
		case "Scanatron5000":
			sReturnstring = "Scanatron 5000"
			break
		case "bLoadTransImage":
			sReturnstring =  "Load Transmission Image?"
			break
		case "bLoadRefImage":
			sReturnstring =  "Load Reflection Image?"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	//puts value into 0th row and 0th column of globals wave for other functions to access
	twGlobals[0][0] = sReturnstring 
	return sReturnstring
end



//This function will be executed when the user selects to define the Instrument in the Instrument definition panel
function Scanatron5000_Define()

	//get Instrument name from the globals
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	string bLoadTransImage
	string bLoadRefImage
	
	//initialize the values depending on if they existed previously
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		bLoadTransImage = COMBI_GetInstrumentString(sThisInstrumentName,"bLoadTransImage",sProject)
		bLoadRefImage = COMBI_GetInstrumentString(sThisInstrumentName,"bLoadRefImage",sProject)
	else 
		//not previously defined, start with default values that are set here 
		bLoadTransImage = "No"
		bLoadRefImage = "No"
	endif
	
	// This section prepares the settings to prompt the user for definition values
	string sPopUpOptions = "Yes;No"
	
	////sets up prompts for all of the globals using the Combi prompting functions
	bLoadTransImage = COMBI_StringPrompt(bLoadTransImage,Scanatron5000_Descriptions("bLoadTransImage"),sPopUpOptions,"","Load Tranmission?")
	//break if user cancelled
	if(stringmatch(bLoadTransImage,"CANCEL"))
		return -1
	endif
	bLoadRefImage = COMBI_StringPrompt(bLoadRefImage,Scanatron5000_Descriptions("bLoadRefImage"),sPopUpOptions,"","Load Tranmission?")
	//break if user cancelled
	if(stringmatch(bLoadRefImage,"CANCEL"))
		return -1
	endif
	
	//mark as defined by storing project name in sProject for this project 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	
	//store the inputs back in the instrument globals
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bLoadRefImage",bLoadRefImage,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"bLoadTransImage",bLoadTransImage,sProject)// store Instrument global 
		
	//reload definition panel
	COMBI_InstrumentDefinition()
	
end



//This function will be executed when the user selects the load data button in the Instrument definition panel
//FOR DEVELOPERS: This function will handle the actual loading of your data. 
function Scanatron5000_Load()

	//get users current folder to return to and moves to root for duration of function
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:

	//get Instrument name and project name from globals
	//stores in local strings
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//get specific globals for this instrument
	string bLoadRefImage = COMBI_GetInstrumentString(sThisInstrumentName,"bLoadRefImage",sProject)
	string bLoadTransImage = COMBI_GetInstrumentString(sThisInstrumentName,"bLoadTransImage",sProject)
	
	//prompt user for library name
	string sLibraryDestination = COMBI_LibraryPrompt(sProject,"New Library","Images for library:",0,1,0,1)
	//break if user cancelled
	if(stringmatch(sLibraryDestination,"CANCEL"))
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//go to library folder
	COMBI_IntoDataFolder(sProject,1)//data folder
	NewDataFolder/O/S $stringfromlist(0,sLibraryDestination) //library folder
	
	//load ref image
	if(stringmatch(bLoadRefImage,"Yes"))
		DoAlert/T="About to load" 0, "Please select the relection image (.tif) for library: "+sLibraryDestination
		ImageLoad/T=tiff/O/Q/N=Scanatron5000_Reflection 
		wave RImage = $"root:COMBIgor:"+sProject+":Data:"+stringfromlist(0,sLibraryDestination)+":Scanatron5000_Reflection"
		SetScale/I x,1.5,49.3,"mm" RImage
		SetScale/I y,1.5,49.3,"mm" RImage
	endif
	
	//load tran image
	if(stringmatch(bLoadTransImage,"Yes"))
		DoAlert/T="About to load" 0, "Please select the transmission image (.tif) for library: "+sLibraryDestination
		ImageLoad/T=tiff/O/Q/N=Scanatron5000_Transmission 
		wave TImage = $"root:COMBIgor:"+sProject+":Data:"+stringfromlist(0,sLibraryDestination)+":Scanatron5000_Transmission"
		SetScale/I x,1.5,49.3,"mm" TImage
		SetScale/I y,1.5,49.3,"mm" TImage
	endif
	
	setdataFolder root: //back to root data folder
	
	//make images 
	if(stringmatch(bLoadTransImage,"Yes"))
		COMBI_Scanatron5000_MakeImage(sProject,stringfromlist(0,sLibraryDestination),"T")
	endif
	if(stringmatch(bLoadRefImage,"Yes"))
		COMBI_Scanatron5000_MakeImage(sProject,stringfromlist(0,sLibraryDestination),"R")
	endif
	
	//log actions in log book
	//FOR DEVELOPERS: Be sure to do this!!!! This is a crucial part of Combigor, and will help you in the long run.
	//COMBI_Add2Log(sProject,sLibraries,sDataType,vLogEntryType,sLogText)
	
	// gets rid of your loaded file so it doesn't clog up your Data Browser
	killpath/A
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
function COMBI_Scanatron5000()
	COMBI_GiveGlobal("sInstrumentName","Scanatron5000","COMBIgor")
	COMBI_InstrumentDefinition()
end


function COMBI_Scanatron5000_MakeImage(sProject,sLibrary,sType)
	string sProject
	string sLibrary
	string sType // "R" or "T"
	string sWavePath = "root:COMBIgor:"+sProject+":Data:"+sLibrary+":"
	if(stringmatch(sType,"T"))
		sWavePath+="Scanatron5000_Transmission"
	endif
	if(stringmatch(sType,"R"))
		sWavePath+="Scanatron5000_Reflection"
	endif
	if(!waveexists($sWavePath))
		DoAlert/T="No such image!" 0, "That image for that library doesn't exist"
	endif
	NewImage/K=1 $sWavePath
	DoWindow/C/T $sLibrary+"_"+sType+"_Image",sLibrary+"_"+sType+""
	ModifyGraph mirror=3,fSize=12,tkLblRot=0,tlOffset=0
	ModifyGraph margin=30,width=300,height=300
	SetAxis left 50.8,0
	SetAxis top 0,50.8
	TextBox/C/N=LibTag/F=0/M/A=RB/X=0.00/Y=0.00/E "\\K(65535,0,0)"+sLibrary
	Label left "Library y dimension (mm)";DelayUpdate
	Label top "Library x dimension (mm)"
	//add sample points
	variable vLibraryWidth = COMBI_GetGlobalNumber("vLibraryWidth",sProject)
	variable vLibraryHeight = COMBI_GetGlobalNumber("vLibraryHeight",sProject)
	if(vLibraryWidth==50.8&&vLibraryHeight==50.8)
		
		wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
		AppendToGraph/L/T wMappingGrid[][2] vs wMappingGrid[][1]
		ModifyGraph mode=3,marker=1,msize=6
		ModifyGraph mrkThick=2,rgb=(65535,0,0)
	endif
end

function COMBI_Scanatron5000_SelectImage()
	string sProject = COMBI_ChooseProject()
	if(stringmatch(sProject,""))
		return -1
	endif
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library","Library of interest:",0,0,0,2)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	string sType = COMBI_StringPrompt("Transmission","Image Type:","Transmission;Reflection","","Image Type?")
	if(stringmatch(sType,"Transmission"))
		COMBI_Scanatron5000_MakeImage(sProject,sLibrary,"T")
	elseif(stringmatch(sType,"Reflection"))
		COMBI_Scanatron5000_MakeImage(sProject,sLibrary,"R")
	endif
end