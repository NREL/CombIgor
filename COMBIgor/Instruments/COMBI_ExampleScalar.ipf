#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original Example
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging
// V1.02: Celeste Melamed _ Nov 2018 : Commenting and debugging
// V1.03: Celeste Melamed _ Dec 2018 : Adding comments for developers

//Description of procedure purpose:
//This Procedure Folder contains example text for a generic instrument named "Example", this can be followed as an example for creating new instruments in COMBIgor
//Each of the 4 functions shown here must exist to work with the Instrument definition panel, all function names should have "Example" replaced with the corresponding Instrument name.


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Instrument
//FOR DEVELOPERS: Define a unique instrument name here.
Static StrConstant sInstrument = "ExampleScalar"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this builds the drop-down menu for this instrument
//FOR DEVELOPERS: Change COMBI_ExampleScalar() to COMBI_YourInstrument() (to match the last function
//in this file), and change "Example Scalar Instrument" to whatever description you want
//in the drop-down COMBIgor menu for your instrument
Menu "COMBIgor"
	SubMenu "Instruments"
		 "Example Scalar Instrument",/Q, COMBI_ExampleScalar()
	end
end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//returns a list of descriptors for each of the globals used to define file loading. 
//FOR DEVELOPERS: In this function, you will define the instrument globals used for your
//unique instrument loader. For example, a data loader may need to know the
//column where a specific data type lives (ie the thickness column in an XRF loader).
//This can be stored as an Instrument global using the "vSomeNumber" case by changing the 
//name and the description. You may have multiple of each type -- ie more than one string,
//or only integers, etc -- and that's totally fine.
//There can be as many Instrument globals as needed, add a new "case" in the strswitch section for each.
Function/S ExampleScalar_Descriptions(sGlobalName)
	string sGlobalName//name of global a description is needed for

	//This section builds the menu, access panel, and the Define process for this instrument
	//globals wave that will be created for this wave upon activating in COMBIgor
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_"+sInstrument+"_Globals"
	string sReturnstring =""
	//The strswitch section builds the define panel for each instrument global
	//FOR DEVELOPERS: Here you will add or remove specific cases depending
	//on what your instrument needs. 
	strswitch(sGlobalName)//depending on value of sGlobalName
		case "InInstrumentMenu":
			twGlobals[1][0] = "No"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "No"
			break
		case "Example":
			sReturnstring = "Example Plugin"
			break
		case "sSomeString":
			sReturnstring =  "Description for sSomeString:"
			break
		case "sSomeDataType":
			sReturnstring =  "Description for sSomeDataType:"
			break
		case "vSomeNumber":
			sReturnstring = "Description for vSomeNumber"
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
//FOR DEVELOPERS: Edit this function so that the user defines all of the Globals that you introduced in the Descriptions
//function (above). Everywhere this function has "sSomeString", "sSomeDataType", or "vSomeNumber", you will need to edit/replace
//with your own specific globals for your instrument. This function uses many COMBIgor Data functions (ie the Combi_Prompt
//functions and the Combi_GetInstrument functions), so be sure to check those out and double check that you are passing them 
//the right inputs.
function ExampleScalar_Define()

	//get Instrument name from the globals
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	
	//get project to define
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//declare variables for each of the definition values
	//Might be something like string sIntensity for XRD intensity, or variable vThicknessColumn for XRF thickness source column
	//FOR DEVELOPERS: These are the same inputs introduced in the Descriptions function above.
	string sSomeString
	string sSomeDataType
	variable vSomeNumber
	
	//initialize the values depending on if they existed previously
	if(!stringmatch("NAG",COMBI_GetInstrumentString(sThisInstrumentName,"sProject",sProject)))
		//if project is defined previously, start with those values
		//FOR DEVELOPERS: Make sure these all match the globals defined above!
		sSomeString = COMBI_GetInstrumentString(sThisInstrumentName,"sSomeString",sProject)
		vSomeNumber = COMBI_GetInstrumentNumber(sThisInstrumentName,"vSomeNumber",sProject)
		sSomeDataType = COMBI_GetInstrumentString(sThisInstrumentName,"sSomeDataType",sProject)
	else 
		//not previously defined, start with default values that are set here 
		//FOR DEVELOPERS: Put in reasonable default values for your specific Globals here
		sSomeString = "Something"
		vSomeNumber = 1
		sSomeDataType = "DataTypeName"
	endif
	
	// This section prepares the settings to prompt the user for definition values
	//FOR DEVELOPERS: Pick and choose what your loader needs depending on the instrument
	string sPopUpOptions = "Option1;Option2;Option3"//list of options for a popup prompt, if "" then blank field with any entry accepted
	string sHelp = "This is the help string" //This is the help string, it is only seen when someone clicks "Help" on the prompt window
	string sWindowTop = "Prompt Window Title String" //This is displayed at the top of the prompt window
	string sStartDataTypes = "New"// starting Sample for data type prompt, "New" defaults to adding a new data type, anything else defaults to that value, can be a list for multiple data types 
	variable vNumberOption = 0//if 1 then user will be prompted for the number of items to define, of 0 then user will define the number of items in list sStartLibraries or sStartDataTypes
	variable vAddOption = 0// if 1 then user has the option to add a new Library or datatype, if 0 then user can only choose from those existing previously
	variable vSkipOption = 0// if 1 then user can choose to skip this Library or dataype entry, "Skip" is returned instead. If 0 then user has no skip option
	variable iDimension = 1//dimension of data 0 for Library, 1 for scalar, 2 for vector
	
	////sets up prompts for all of the globals using the Combi prompting functions
	sSomeString = COMBI_StringPrompt(sSomeString,ExampleScalar_Descriptions("sSomeString"),sPopUpOptions,sHelp,sWindowTop)
	sSomeDataType = COMBI_DataTypePrompt(sProject,sSomeDataType,ExampleScalar_Descriptions("sSomeDataType"),vNumberOption,vAddOption,vSkipOption,iDimension)
	vSomeNumber = COMBI_NumberPrompt(vSomeNumber,ExampleScalar_Descriptions("vSomeNumber"),sHelp,sWindowTop)
	
	//mark as defined by storing project name in sProject for this project 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sProject",sProject,sProject)// store global
	
	//store the inputs back in the instrument globals
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sSomeString",sSomeString,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"sSomeDataType",sSomeDataType,sProject)// store Instrument global 
	COMBI_GiveInstrumentGlobal(sThisInstrumentName,"vSomeNumber",num2str(vSomeNumber),sProject)// store Instrument global 
		
	//reload definition panel
	COMBI_InstrumentDefinition()
	
end



//This function will be executed when the user selects the load data button in the Instrument definition panel
//FOR DEVELOPERS: This function will handle the actual loading of your data. 
function ExampleScalar_Load()

	//get users current folder to return to and moves to root for duration of function
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:

	//get Instrument name and project name from globals
	//stores in local strings
	string sThisInstrumentName = COMBI_GetGlobalString("sInstrumentName", "COMBIgor")
	string sProject = COMBI_GetGlobalString("sInstrumentProject", "COMBIgor")
	
	//get specific globals for this instrument
	//stores in local strings and variables
	//FOR DEVELOPERS: As with the Define function, edit these globals so they match the globals that you've
	//defined specifically for your instrument.
	string sSomeString = COMBI_GetInstrumentString(sThisInstrumentName,"sSomeString",sProject)
	variable vSomeNumber = COMBI_GetInstrumentNumber(sThisInstrumentName,"vSomeNumber",sProject)
	string sSomeDataType = COMBI_GetInstrumentString(sThisInstrumentName,"sSomeDataType",sProject)
		
	//FOR DEVELOPERS: The following code is fairly general and shouldn't need to be edited much.
	//This code prompts for a number of libraries and adds new libary names if they don't already exist.
	//It also uses the default ImportPath or prompts for a new one if it doesn't exist.
	
	//prompt the user for the number of Libraries that you want to load
	//stores in local int vNumberOfLibraries
	int vNumberOfLibraries = COMBI_NumberPrompt(1,"Number of Libraries in this file","This is the total number of libraries in the folder. If desired, some samples may be skipped during loading, but please enter the total number of libraries here.","Libraries in File Load")
	if(vNumberOfLibraries<=0)
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	//get project level globals if necessary
	variable vTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	//prompt user for library names and indices
	//loop over vNumberOfLibraries defined above
	variable iLibrary
	string sLibraries="", sFirstSamples="",sLastSamples="",sFirstIndexs="",sLastIndexs="", sThisLibrary
	for(iLibrary=0;iLibrary<vNumberOfLibraries;iLibrary+=1)
		//ask for library name
		string sLibraryDestinations = COMBI_LibraryLoadingPrompt(sProject,"Library "+num2str(iLibrary+1),"Library Name",1,1,1,iLibrary)
		//break if user cancelled
		if(stringmatch(sLibraryDestinations,"CANCEL"))
			SetDataFolder $sTheCurrentUserFolder 
			return -1
		endif
		//add library name and indices to master list, used for sorting later.
		sLibraries = AddListItem(cleanupname(stringfromlist(0,sLibraryDestinations),0),sLibraries,";",inf)
		sFirstSamples = AddListItem(stringfromlist(1,sLibraryDestinations),sFirstSamples,";",inf)
		sLastSamples = AddListItem(stringfromlist(2,sLibraryDestinations),sLastSamples,";",inf)
		sFirstIndexs = AddListItem(stringfromlist(3,sLibraryDestinations),sFirstIndexs,";",inf)
		sLastIndexs = AddListItem(stringfromlist(4,sLibraryDestinations),sLastIndexs,";",inf)
	endfor
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load some wave of data and name it LoadedExampleFile
	//FOR DEVELOPERS: This section will need to be edited in order to load the specific file type for your instrument.
	//This will likely be done by adding or removing flags from the LoadWave function (/Q and /O are examples of flags).
	//Check out the Igor documentation for LoadWave and figure out what your file type needs.
	LoadWave/N=LoadedExampleFile/Q/O
	wave/Z wLoadedFile = root:LoadedExampleFile
	
	//make list of data types (using the Instrument global sSomeString here)
	//FOR DEVELOPERS: This section will make a string list of your data column names (currently they are sSomeString), and also
	//make a string of the columns in the data file where you want to pull the data from. (This is because we are preparing to
	//pass the data into the COMBI_Sort function, which will parse the loaded data file and organize it into Combigor.) Edit here
	//to match your specific loaded data, and try to take advantage of your Globals!
	string sDataTypes = sSomeString+";"+sSomeString+";"+sSomeString+";"+sSomeString
	string sDataColumnNumbers = num2str(vSomeNumber-1)+";"+num2str(vSomeNumber-1)+";"+num2str(vSomeNumber-1)+";"+num2str(vSomeNumber-1)
	
	//have COMBIgor sort the wave using the Combi Data sort function
	//FOR DEVELOPERS: Check out the documentation for this Combi function in order to tailor it to your data.	
	COMBI_SortNewScalarData(sProject,wLoadedFile,sLibraries,sFirstSamples,sLastSamples,sFirstIndexs,sLastIndexs,sDataTypes,sDataColumnNumbers)
	
	//log actions in log book
	//FOR DEVELOPERS: Be sure to do this!!!! This is a crucial part of Combigor, and will help you in the long run.
	//COMBI_Add2Log(sProject,sLibraries,sDataType,vLogEntryType,sLogText)
	
	// gets rid of your loaded file so it doesn't clog up your Data Browser
	killwaves wLoadedFile
	killpath/A
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
//FOR DEVELOPERS: Change "ExampleScalar" to the name of your Instrument; make sure your loader is appropriately named COMBI_YourInstrument.ipf
function COMBI_ExampleScalar()
	COMBI_GiveGlobal("sInstrumentName","ExampleScalar","COMBIgor")
	COMBI_InstrumentDefinition()
	DisplayProcedure/W=$"COMBI_ExampleScalar.ipf"/L=0
end
