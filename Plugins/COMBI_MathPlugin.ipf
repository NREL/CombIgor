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
Static StrConstant sPluginName = "MathPlugin"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Plugins"
		 "Math Helper",/Q, COMBI_MathPlugin()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
function COMBI_MathPlugin()
	
	//check if initialized, get starting values if so, initialize if not
	string sProject //project to operate within
	string sSLibrary1//Library to operate on
	string sSLibrary2//Library to operate on
	string sDLibrary//Library to operate on
	string sData1
	string sData2
	string sDataD
	string sFirstSample
	string sLastSample
	string sOperation
	string sTable1
	string sTable2
	string sTableD
	string sS1Type
	string sS2Type
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
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary1","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary2","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData1","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData2","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataD","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFirstSample","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLastSample",COMBI_GetGlobalString("vTotalSamples", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTable1","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTable2","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTableD","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sS1Type","Data",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sS2Type","Data",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstant","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sOperation","Add",sProject)
	endif
	
	sSLibrary1 = COMBI_GetPluginString(sPluginName,"sSLibrary1",sProject)
	sSLibrary2 = COMBI_GetPluginString(sPluginName,"sSLibrary2",sProject)
	sDLibrary = COMBI_GetPluginString(sPluginName,"sDLibrary",sProject)
	sData1 = COMBI_GetPluginString(sPluginName,"sData1",sProject)
	sData2 = COMBI_GetPluginString(sPluginName,"sData2",sProject)
	sDataD = COMBI_GetPluginString(sPluginName,"sDataD",sProject)
	sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	sTable1 = COMBI_GetPluginString(sPluginName,"sTable1",sProject)
	sTable2 = COMBI_GetPluginString(sPluginName,"sTable2",sProject)
	sTableD = COMBI_GetPluginString(sPluginName,"sTableD",sProject)
	sS1Type = COMBI_GetPluginString(sPluginName,"sS1Type",sProject)
	sS2Type = COMBI_GetPluginString(sPluginName,"sS2Type",sProject)
	sOperation = COMBI_GetPluginString(sPluginName,"sOperation",sProject)
	
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_MathPlugin_Globals
	
	//convert table dims
	string sTable1Pre = stringfromlist(str2num(sTable1),"Library;Scalar;Vector; ")
	string sTable2Pre = stringfromlist(str2num(sTable2),"Library;Scalar;Vector; ")
	string sTableDPre = stringfromlist(str2num(sTableD),"Library;Scalar;Vector; ")
	
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z MathPluginPanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z MathPluginPanel
	
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+300,vWinTop+463)/N=MathPluginPanel as "COMBIgor Math Plugins"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont
	SetDrawEnv textxjust = 2,textyjust = 1
	SetDrawEnv fsize = 12
	SetDrawEnv save
	variable vYValue = 15
	
	//Project
	DrawText 90,vYValue, "Project:"
	PopupMenu sProject,pos={230,vYValue-10},mode=1,bodyWidth=190,value=COMBI_Projects(),proc=MathPlugin_UpdateGlobal,popvalue=sProject
	//new things
	vYValue+=15
	button sNewLibrary,title="New Library",appearance={native,All},pos={23,vYValue},size={120,20},proc=MathPlugin_New,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button sNewDataType,title="New Data Type",appearance={native,All},pos={156,vYValue},size={120,20},proc=MathPlugin_New,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=15
	
	//Source1___________
	//Type1
	SetDrawEnv textrgb=(65535,0,0); SetDrawEnv save
	vYValue+=20
	DrawText 90,vYValue, "Type:"
	PopupMenu sS1Type,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Data;Constant",proc=MathPlugin_UpdateGlobal,popvalue=sS1Type
	//Table1
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTable1,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;Library;Scalar;Vector",proc=MathPlugin_UpdateGlobal,popvalue=sTable1Pre
	//Library1
	vYValue+=20
	DrawText 90,vYValue, "Library:"
	PopupMenu sSLibrary1,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+MathPlugin_DropList("Libraries",-2,1),proc=MathPlugin_UpdateGlobal,popvalue=sSLibrary1
	//Data1
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sData1,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+MathPlugin_DropList("DataTypes",-2,1),proc=MathPlugin_UpdateGlobal,popvalue=sData1
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	if(stringmatch(sS1Type,"Data"))
		if(!stringmatch(" ",sTable1))
			if(stringmatch(sTable1,"0"))
				DrawText 150,vYValue, "LibraryData["+sSLibrary1+"]["+sData1+"]"
			elseif(stringmatch(sTable1,"1"))
				DrawText 150,vYValue, "Scalar:"+sSLibrary1+":"+sData1
			elseif(stringmatch(sTable1,"2"))
				 DrawText 150,vYValue,"Vector:"+sSLibrary1+":"+sData1
			endif
		endif
	elseif(stringmatch(sS1Type,"Constant"))
		DrawText 150,vYValue, "Constant:"+twGlobals[%sConstant][%$sProject]
	endif
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save

	
	//Source2__________
	SetDrawEnv textrgb=(0,0,65535); SetDrawEnv save
	//Type1
	vYValue+=20
	DrawText 90,vYValue, "Type:"
	PopupMenu sS2Type,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Data;Constant",proc=MathPlugin_UpdateGlobal,popvalue=sS2Type
	//Table2
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTable2,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;Library;Scalar;Vector",proc=MathPlugin_UpdateGlobal,popvalue=sTable2Pre
	//Library2
	vYValue+=20
	DrawText 90,vYValue, "Library:"
	PopupMenu sSLibrary2,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+MathPlugin_DropList("Libraries",-2,2),proc=MathPlugin_UpdateGlobal,popvalue=sSLibrary2
	//Data2
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sData2,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+MathPlugin_DropList("DataTypes",-2,2),proc=MathPlugin_UpdateGlobal,popvalue=sData2
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	if(stringmatch(sS2Type,"Data"))
		if(!stringmatch(" ",sTable2))
			if(stringmatch(sTable2,"0"))
				DrawText 150,vYValue, "LibraryData["+sSLibrary2+"]["+sData2+"]"
			elseif(stringmatch(sTable2,"1"))
				DrawText 150,vYValue, sSLibrary2+":"+sData2
			elseif(stringmatch(sTable2,"2"))
				 DrawText 150,vYValue,sSLibrary2+":"+sData2
			endif
		endif
	elseif(stringmatch(sS2Type,"Constant"))
		DrawText 150,vYValue, "Constant:"+twGlobals[%sConstant][%$sProject]
	endif
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save
	
	//Dest__________
	SetDrawEnv  textrgb= (2,39321,1); SetDrawEnv save
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTableD,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Library;Scalar;Vector",proc=MathPlugin_UpdateGlobal,popvalue=sTableDPre
	//DLibrary
	vYValue+=20
	DrawText 90,vYValue, " Library:"
	PopupMenu sDLibrary,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+MathPlugin_DropList("Libraries",-2,3),proc=MathPlugin_UpdateGlobal,popvalue=sDLibrary
	//DData
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sDataD,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+MathPlugin_DropList("DataTypes",-2,3),proc=MathPlugin_UpdateGlobal,popvalue=sDataD
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	if(stringmatch(sTableD,"0"))
		DrawText 150,vYValue, "LibraryData["+sDLibrary+"]["+sDataD+"]"
	elseif(stringmatch(sTableD,"1"))
		DrawText 150,vYValue, sDLibrary+":"+sDataD
	elseif(stringmatch(sTableD,"2"))
		 DrawText 150,vYValue,sDLibrary+":"+sDataD
	endif
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save
	
	SetDrawEnv textrgb=(0,0,0); SetDrawEnv save
	//constant
	vYValue+=20
	DrawText 90,vYValue, "Constant:"
	SetVariable sConstant,title=" " ,pos={90,vYValue-10},size={190,20},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sConstant][%$sProject]
	//operator
	vYValue+=20
	DrawText 90,vYValue, "Operation:"
	PopupMenu sOperation,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Add;Subtract;Multiply;Divide;Power;Max;Min;Mean;Range",proc=MathPlugin_UpdateGlobal,popvalue=sOperation
	//Sample range
	vYValue+=20
	DrawText 90,vYValue, "Samples:"
	DrawText 200,vYValue, " - "
	SetVariable sFirstSample, title=" ",pos={90,vYValue-10},size={80,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sFirstSample][%$sProject]
	SetVariable sLastSample, title=" ",pos={200,vYValue-10},size={80,50},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sLastSample][%$sProject]	
	vYValue+=15
	DrawLine 0,vYValue,400,vYValue
	//draw equation
	vYValue-=5
	SetDrawEnv fsize = 20; SetDrawEnv save
	if(stringmatch("Add",sOperation))
		SetDrawEnv textrgb=(65535,0,0);  DrawText 40,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 55,vYValue+40, "+"
		SetDrawEnv textrgb=(0,0,65535);  DrawText 90,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 105,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 140,vYValue+40, "\W5016"
	elseif(stringmatch("Subtract",sOperation))
		SetDrawEnv textrgb=(65535,0,0);  DrawText 40,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 55,vYValue+40, "-"
		SetDrawEnv textrgb=(0,0,65535);  DrawText 90,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 105,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 140,vYValue+40, "\W5016"
	elseif(stringmatch("Multiply",sOperation))
		SetDrawEnv textrgb=(65535,0,0);  DrawText 40,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 55,vYValue+40, "x"
		SetDrawEnv textrgb=(0,0,65535);  DrawText 90,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 105,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 140,vYValue+40, "\W5016"
	elseif(stringmatch("Divide",sOperation))
		SetDrawEnv textrgb=(65535,0,0);  DrawText 40,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 55,vYValue+40, "/"
		SetDrawEnv textrgb=(0,0,65535);  DrawText 90,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  DrawText 105,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 140,vYValue+40, "\W5016"
	elseif(stringmatch("Power",sOperation))
		SetDrawEnv textrgb=(65535,0,0);  DrawText 50,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,65535); SetDrawEnv fsize = 16; SetDrawEnv save; DrawText 65,vYValue+30, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 80,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 120,vYValue+40, "\W5016"
	elseif(stringmatch("Max",sOperation))
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 120,vYValue+40, "Max("
		SetDrawEnv textrgb=(65535,0,0);  DrawText 145,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 155,vYValue+40, ")"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 60,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 40,vYValue+40, "\W5016"
	elseif(stringmatch("Min",sOperation))
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 120,vYValue+40, "Min("
		SetDrawEnv textrgb=(65535,0,0);  DrawText 145,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 155,vYValue+40, ")"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 60,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 40,vYValue+40, "\W5016"
	elseif(stringmatch("Mean",sOperation))
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 120,vYValue+40, "Mean("
		SetDrawEnv textrgb=(65535,0,0);  DrawText 145,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 155,vYValue+40, ")"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 50,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 40,vYValue+40, "\W5016"
	elseif(stringmatch("Range",sOperation))
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 125,vYValue+40, "Range("
		SetDrawEnv textrgb=(65535,0,0);  DrawText 150,vYValue+40, "\W5016"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 160,vYValue+40, ")"
		SetDrawEnv textrgb=(0,0,0);  SetDrawEnv fsize = 20; SetDrawEnv save;DrawText 50,vYValue+40, "="
		SetDrawEnv textrgb=(2,39321,1);  DrawText 40,vYValue+40, "\W5016"
	endif
	//compute
	vYValue+=17
	button Compute,title="Compute!",appearance={native,All},pos={175,vYValue},size={100,40},proc=MathPlugin_ComputeButton,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
	
end

Function MathPlugin_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	if(stringmatch("sProject",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	elseif(stringmatch("sTable1",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTable1",num2str(WhichListItem(popStr, "Library;Scalar;Vector; ")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sData1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sTable2",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTable2",num2str(WhichListItem(popStr, "Library;Scalar;Vector; ")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sData2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sTableD",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTableD",num2str(WhichListItem(popStr, "Library;Scalar;Vector")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sDataD"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sDLibrary"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sS1Type",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		if(stringmatch(popStr,"Constant"))
			COMBI_GivePluginGlobal(sPluginName,"sTable1","3",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sSLibrary1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sData1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		endif
	elseif(stringmatch("sS2Type",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		if(stringmatch(popStr,"Constant"))
			COMBI_GivePluginGlobal(sPluginName,"sTable2","3",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sSLibrary2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sData2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		endif
	else
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	COMBI_MathPlugin()
End

//function to return drop downs of Libraries for panel
function/S MathPlugin_DropList(sOption,iDim,iData)
	string sOption //"Libraries" or "DataTypes"
	int iDim //-3 for all, -2 for all numeric, -1 for Meta, 0 for Library, 1 for scalar, 2 for vector
	int iData //1 for Data1, 2 for Data2, 3 for DataD
	int iDataTypeDim
	int iLibraryDim
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	if(stringmatch(sOption,"Libraries"))
		if(iData==1)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTable1",sProject)
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		elseif(iData==2)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTable2",sProject)
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		elseif(iData==3)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTableD",sProject)
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		endif
		
	elseif(stringmatch(sOption,"DataTypes"))
		string sLibrary
		if(iData==1)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTable1",sProject)
			sLibrary =  COMBI_GetPluginString(sPluginName,"sSLibrary1",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		elseif(iData==2)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTable2",sProject)
			sLibrary =  COMBI_GetPluginString(sPluginName,"sSLibrary2",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		elseif(iData==3)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTableD",sProject)
			sLibrary =  COMBI_GetPluginString(sPluginName,"sDLibrary",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		endif
	endif
	
	
	
end

Function MathPlugin_New(ctrlName) : ButtonControl
	String ctrlName
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	if(stringmatch("sNewDataType",ctrlName))
		COMBI_NewEntry(sProject,"DataType")
	elseif(stringmatch("sNewLibrary",ctrlName))
		COMBI_NewEntry(sProject,"Library")
	endif
	return -1
End

Function MathPlugin_ComputeButton(ctrlName) : ButtonControl
	String ctrlName
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sS1Type = COMBI_GetPluginString(sPluginName,"sS1Type",sProject)
	string sTable1 = COMBI_GetPluginString(sPluginName,"sTable1",sProject)
	string sData1 = COMBI_GetPluginString(sPluginName,"sData1",sProject)
	string sSLibrary1 = COMBI_GetPluginString(sPluginName,"sSLibrary1",sProject)
	string sS2Type = COMBI_GetPluginString(sPluginName,"sS2Type",sProject)
	string sTable2 = COMBI_GetPluginString(sPluginName,"sTable2",sProject)
	string sData2 = COMBI_GetPluginString(sPluginName,"sData2",sProject)
	string sSLibrary2 = COMBI_GetPluginString(sPluginName,"sSLibrary2",sProject)
	string sOperation = COMBI_GetPluginString(sPluginName,"sOperation",sProject)
	string sTableD = COMBI_GetPluginString(sPluginName,"sTableD",sProject)
	string sDataD = COMBI_GetPluginString(sPluginName,"sDataD",sProject)
	string sDLibrary = COMBI_GetPluginString(sPluginName,"sDLibrary",sProject)
	string sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	string sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	string sConstant = COMBI_GetPluginString(sPluginName,"sConstant",sProject)
	//pass
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		Print "MathPlugin_Compute(\""+sProject+"\",\""+sS1Type+"\",\""+sTable1+"\",\""+sData1+"\",\""+sSLibrary1+"\",\""+sS2Type+"\",\""+sTable2+"\",\""+sData2+"\",\""+sSLibrary2+"\",\""+sOperation+"\",\""+sTableD+"\",\""+sDataD+"\",\""+sDLibrary+"\",\""+sFirstSample+"\",\""+sLastSample+"\",\""+sConstant+"\")"
	endif
	MathPlugin_Compute(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant)
end


	
Function MathPlugin_Compute(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant)
	String sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant

	//get wave paths
	//do math
	int iTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)-1
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	if(iFirstSample<0||iFirstSample>iTotalSamples)
		DoAlert/T="Bad Sample Range" 0, "First Sample should be between 0 and "+num2str(iTotalSamples+1)+"."
	endif
	if(iLastSample<0||iLastSample>iTotalSamples)
		DoAlert/T="Bad Sample Range" 0, "Last Sample should be between 0 and "+num2str(iTotalSamples+1)+"."
	endif
	
	int bSkipS12 = 0
	if(stringmatch("Min",sOperation))
		bSkipS12=1
	elseif(stringmatch("Max",sOperation))
		bSkipS12=1
	elseif(stringmatch("Mean",sOperation))
		bSkipS12=1
	elseif(stringmatch("Range",sOperation))
		bSkipS12=1
	endif
	
	string sWave1, sWave2
	string sWave1Source, sWave2Source
	if(!stringmatch("3",sTable1))//not blank dim
		if(stringmatch(sTable1,"0"))
			sWave1 = COMBI_DataPath(sProject,0)+"[%"+sSLibrary1+"][%"+sData1+"]"
		elseif(stringmatch(sTable1,"1"))
			if(stringmatch(sTableD,"1")||stringmatch(sTableD,"2"))
				sWave1 = COMBI_DataPath(sProject,1)+sSLibrary1+":"+sData1+"[p]"
				sWave1Source = COMBI_DataPath(sProject,1)+sSLibrary1+":"+sData1
			else
				if(bSkipS12==0)
					DoAlert/T="Invalid data types",0,"Green must be scalar or vector if red is scalar. "
					return-1
				else
					sWave1 = COMBI_DataPath(sProject,1)+sSLibrary1+":"+sData1+"[p]"
					sWave1Source = COMBI_DataPath(sProject,1)+sSLibrary1+":"+sData1
				endif
			endif
		elseif(stringmatch(sTable1,"2"))
			if(stringmatch(sTableD,"2"))
				sWave1 = COMBI_DataPath(sProject,2)+sSLibrary1+":"+sData1+"[p][q]"
				sWave1Source = COMBI_DataPath(sProject,2)+sSLibrary1+":"+sData1
			else
				if(bSkipS12==0)
					DoAlert/T="Invalid data types",0,"Green needs to be vector if red is. "
					return-1
				else
					sWave1 = COMBI_DataPath(sProject,2)+sSLibrary1+":"+sData1+"[p]"
					sWave1Source = COMBI_DataPath(sProject,2)+sSLibrary1+":"+sData1
				endif
			endif
		endif
	endif
	if(!stringmatch("3",sTable2))//not blank dim
		if(stringmatch(sTable2,"0"))
			sWave2 = COMBI_DataPath(sProject,0)+"[%"+sSLibrary2+"][%"+sData2+"]"
		elseif(stringmatch(sTable2,"1"))
			if(stringmatch(sTableD,"1")||stringmatch(sTableD,"2"))
				sWave2 = COMBI_DataPath(sProject,1)+sSLibrary2+":"+sData2+"[p]"
				sWave2Source = COMBI_DataPath(sProject,1)+sSLibrary2+":"+sData2
			else
				 if(bSkipS12==0)
					DoAlert/T="Invalid data types",0,"Green must be scalar or vector if blue is scalar. "
					return-1
				else
					sWave2 = COMBI_DataPath(sProject,1)+sSLibrary2+":"+sData2+"[p]"
					sWave2Source = COMBI_DataPath(sProject,1)+sSLibrary2+":"+sData2
				endif
			endif
		elseif(stringmatch(sTable2,"2"))
			if(stringmatch(sTableD,"2"))
				sWave2 = COMBI_DataPath(sProject,2)+sSLibrary2+":"+sData2+"[p][q]"
				sWave2Source = COMBI_DataPath(sProject,2)+sSLibrary2+":"+sData2
			else
				if(bSkipS12==0)
					DoAlert/T="Invalid data types",0,"Green needs to be vector if blue is."
					return-1
				else
					sWave2 = COMBI_DataPath(sProject,2)+sSLibrary2+":"+sData2+"[p][q]"
					sWave2Source = COMBI_DataPath(sProject,2)+sSLibrary2+":"+sData2
				endif
			endif
		endif
	endif	
	
	if(bSkipS12==0)
		if(stringmatch(sS1Type,"Data"))
			if(stringmatch(sSLibrary1," ")||stringmatch(sData1," ")||stringmatch(sTable1,"3"))
				DoAlert/T="Incomplete Inputs" 0, "To use red as data, it must have have a valid dimension, library name, and data type."
				return -1
			endif
		endif
		if(stringmatch(sS2Type,"Data"))
			if(stringmatch(sSLibrary2," ")||stringmatch(sData2," ")||stringmatch(sTable2,"3"))
				DoAlert/T="Incomplete Inputs" 0, "To use blue as data, it must have a valid dimension, library name, and data type."
				return -1
			endif
		endif
		if(stringmatch(sDLibrary," ")||stringmatch(sDataD," "))
			DoAlert/T="Incomplete Inputs" 0, "Green must have a valid dimension, library name, and data type."
			return -1
		endif
	endif
	
	string sWaveD, sWaveDSource
	if(stringmatch(sTableD,"0"))
		sWaveD = COMBI_DataPath(sProject,0)+"[%"+sDLibrary+"][%"+sDataD+"] = "
		sWaveDSource = COMBI_DataPath(sProject,0)
	elseif(stringmatch(sTableD,"1"))
		sWaveD = COMBI_DataPath(sProject,1)+sDLibrary+":"+sDataD+"["+num2str(iFirstSample)+","+num2str(iLastSample)+"] = "
		sWaveDSource = COMBI_DataPath(sProject,1)+sDLibrary+":"+sDataD
	elseif(stringmatch(sTableD,"2"))
		sWaveD = COMBI_DataPath(sProject,2)+sDLibrary+":"+sDataD+"["+num2str(iFirstSample)+","+num2str(iLastSample)+"][] = "
		sWaveDSource = COMBI_DataPath(sProject,2)+sDLibrary+":"+sDataD
		//sized?
		if(waveexists($sWaveDSource))
			if(waveexists($sWave1Source))
				if(dimsize($sWave1Source,1)>dimsize($sWaveDSource,1))
					redimension/N=(-1,dimsize($sWave1Source,1)) $sWaveDSource
				endif
			endif
			if(waveexists($sWave2Source))
				if(dimsize($sWave2Source,1)>dimsize($sWaveDSource,1))
					redimension/N=(-1,dimsize($sWave2Source,1)) $sWaveDSource
				endif
			endif
		endif
	endif
	
	//mathing
	string sSource1,sSource2
	string sComand = sWaveD
	
	
	if(bSkipS12==0)
		if(stringmatch("Data",sS1Type))
			sComand = sComand+sWave1
			sSource1 = sWave1
		elseif(stringmatch("Constant",sS1Type))
			sComand = sComand+sConstant
			sSource1 = sConstant
		endif

		if(stringmatch("Add",sOperation))
			sComand = sComand+"+"
		elseif(stringmatch("Subtract",sOperation))
			sComand = sComand+"-"
		elseif(stringmatch("Multiply",sOperation))
			sComand = sComand+"*"
		elseif(stringmatch("Divide",sOperation))
			sComand = sComand+"/"
		elseif(stringmatch("Power",sOperation))
			sComand = sComand+"^"
		endif
	
		if(stringmatch("Data",sS2Type))
			sComand = sComand+sWave2
			sSource2 = sWave2
		elseif(stringmatch("Constant",sS2Type))
			sComand = sComand+sConstant
			sSource2 = sConstant
		endif
	else
		sSource2 =""
		if(stringmatch("Data",sS1Type))
			sSource1 = sWave1
		elseif(stringmatch("Constant",sS1Type))
			sSource1 = sConstant
		endif
		if(stringmatch(sTableD,"0"))
			sComand = sComand+num2str(COMBI_Extremes(sProject,str2num(sTable1),sData1,sSLibrary1,num2str(iFirstSample+1)+";"+num2str(iLastSample+1)+"; ; ; ; ",sOperation))
		elseif(stringmatch(sTableD,"1"))
			sComand = sComand+"COMBI_Extremes(\""+sProject+"\","+sTable1+",\""+sData1+"\",\""+sSLibrary1+"\","+"num2str(p+1)+\";\"+num2str(p+1)+\"; ; ; ; \",\""+sOperation+"\")"
		elseif(stringmatch(sTableD,"2"))
			DoAlert/T="Nonsense inputs" 0, "It doesn't make sense to store this per-sample number in vector data, please store in scalar type."
			return -1
		endif
	endif
	
	Execute sComand

	string sLogText1="Math Plugins used to compute this value"
	string sLogText2="Source1(A): "+sSource1
	string sLogText3="Source2(B): "+sSource2
	string sLogText4="Operation: "+sOperation
	string sLogText5="Sample Range: "+sFirstSample+" to "+sLastSample
	COMBI_Add2Log(sProject,sDLibrary,sDataD,2,sLogText1+";"+sLogText2+";"+sLogText3+";"+sLogText4+";"+sLogText5)
	
end