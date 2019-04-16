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
Static StrConstant sPluginName = "DataSifter"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Plugins"
		 "Data Sifting",/Q, COMBI_DataSift()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this function is run when the user selects the Instrument from the COMBIgor drop down menu once activated
function COMBI_DataSift()
	
	//check if initialized, get starting values if so, initialize if not
	string sProject //project to operate within
	string sSLibrary1//Library to operate on
	string sSLibrary2//Library to operate on
	string sSLibrary3//Library to operate on
	string sDLibrary//Library to operate on
	string sData1
	string sData2
	string sData3
	string sDataD
	string sFirstSample
	string sLastSample
	string sOperation
	string sTable1
	string sTable2
	string sTable3
	string sTableD
	string sS1Type
	string sS2Type
	string sS3Type
	string sConstant1
	string sConstant2
	
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
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary3","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData1","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData2","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sData3","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDataD","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFirstSample","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLastSample",COMBI_GetGlobalString("vTotalSamples", sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTable1","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTable2","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTable3","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sTableD","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sS1Type","Data",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sS2Type","Data",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sS3Type","Data",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstant1","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sConstant2","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sOperation",">",sProject)
	endif
	
	sSLibrary1 = COMBI_GetPluginString(sPluginName,"sSLibrary1",sProject)
	sSLibrary2 = COMBI_GetPluginString(sPluginName,"sSLibrary2",sProject)
	sSLibrary3 = COMBI_GetPluginString(sPluginName,"sSLibrary3",sProject)
	sDLibrary = COMBI_GetPluginString(sPluginName,"sDLibrary",sProject)
	sData1 = COMBI_GetPluginString(sPluginName,"sData1",sProject)
	sData2 = COMBI_GetPluginString(sPluginName,"sData2",sProject)
	sData3 = COMBI_GetPluginString(sPluginName,"sData3",sProject)
	sDataD = COMBI_GetPluginString(sPluginName,"sDataD",sProject)
	sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	sTable1 = COMBI_GetPluginString(sPluginName,"sTable1",sProject)
	sTable2 = COMBI_GetPluginString(sPluginName,"sTable2",sProject)
	sTable3 = COMBI_GetPluginString(sPluginName,"sTable3",sProject)
	sTableD = COMBI_GetPluginString(sPluginName,"sTableD",sProject)
	sS1Type = COMBI_GetPluginString(sPluginName,"sS1Type",sProject)
	sS2Type = COMBI_GetPluginString(sPluginName,"sS2Type",sProject)
	sS3Type = COMBI_GetPluginString(sPluginName,"sS3Type",sProject)
	sOperation = COMBI_GetPluginString(sPluginName,"sOperation",sProject)
	
	wave/T twGlobals = root:Packages:COMBIgor:Plugins:COMBI_DataSifter_Globals
	
	//convert table dims
	sTable1 = stringfromlist(str2num(sTable1),"Meta;Library;Scalar;Vector; ")
	sTable2 = stringfromlist(str2num(sTable2),"Meta;Library;Scalar;Vector; ")
	sTable3 = stringfromlist(str2num(sTable3),"Meta;Library;Scalar;Vector; ")
	sTableD = stringfromlist(str2num(sTableD),"Meta;Library;Scalar;Vector; ")
	
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z DataSifterPanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z DataSifterPanel
	
	//make panel
	PauseUpdate; Silent 1 // pause for building window...
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+300,vWinTop+613)/N=DataSifterPanel as "COMBIgor Sifter Plugins"
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont
	SetDrawEnv textxjust = 2,textyjust = 1
	SetDrawEnv fsize = 12
	SetDrawEnv save
	variable vYValue = 15
	
	//Project
	DrawText 90,vYValue, "Project:"
	PopupMenu sProject,pos={230,vYValue-10},mode=1,bodyWidth=190,value=COMBI_Projects(),proc=DataSifter_UpdateGlobal,popvalue=sProject
	//new things
	vYValue+=15
	button sNewLibrary,title="New Library",appearance={native,All},pos={23,vYValue},size={120,20},proc=DataSifter_New,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	button sNewDataType,title="New Data Type",appearance={native,All},pos={156,vYValue},size={120,20},proc=DataSifter_New,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=14
	vYValue+=15
	
	//Source1___________
	//Type1
	SetDrawEnv textrgb=(65535,0,0); SetDrawEnv save
	vYValue+=20
	DrawText 90,vYValue, "Type:"
	PopupMenu sS1Type,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Data;Constant1;Constant2",proc=DataSifter_UpdateGlobal,popvalue=sS1Type
	//Table1
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTable1,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;Meta;Library;Scalar;Vector",proc=DataSifter_UpdateGlobal,popvalue=sTable1
	//Library1
	vYValue+=20
	DrawText 90,vYValue, "Library:"
	PopupMenu sSLibrary1,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("Libraries",-3,1),proc=DataSifter_UpdateGlobal,popvalue=sSLibrary1
	//Data1
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sData1,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("DataTypes",-3,1),proc=DataSifter_UpdateGlobal,popvalue=sData1
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	if(stringmatch(sS1Type,"Data"))
		if(!stringmatch(" ",sTable1))
			DrawText 150,vYValue, sTable1+"["+"Library"+"]["+num2str(str2num(sFirstSample)-1)+","+num2str(str2num(sLastSample)-1)+"]["+"Data"+"][*]"
		endif
	elseif(stringmatch(sS1Type,"Constant1"))
		DrawText 150,vYValue, "Constant1:"+twGlobals[%sConstant1][%$sProject]
	elseif(stringmatch(sS1Type,"Constant2"))
		DrawText 150,vYValue, "Constant2:"+twGlobals[%sConstant2][%$sProject]
	endif
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save

	
	//Source2__________
	SetDrawEnv textrgb=(0,0,65535); SetDrawEnv save
	//Type1
	vYValue+=20
	DrawText 90,vYValue, "Type:"
	PopupMenu sS2Type,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Data;Constant1;Constant2",proc=DataSifter_UpdateGlobal,popvalue=sS2Type
	//Table2
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTable2,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;Meta;Library;Scalar;Vector",proc=DataSifter_UpdateGlobal,popvalue=sTable2
	//Library2
	vYValue+=20
	DrawText 90,vYValue, "Library:"
	PopupMenu sSLibrary2,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("Libraries",-3,2),proc=DataSifter_UpdateGlobal,popvalue=sSLibrary2
	//Data2
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sData2,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("DataTypes",-3,2),proc=DataSifter_UpdateGlobal,popvalue=sData2
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	if(stringmatch(sS2Type,"Data"))
		if(!stringmatch(" ",sTable2))
			DrawText 150,vYValue, sTable2+"["+"Library"+"]["+num2str(str2num(sFirstSample)-1)+","+num2str(str2num(sLastSample)-1)+"]["+"Data"+"][*]"
		endif
	elseif(stringmatch(sS2Type,"Constant1"))
		DrawText 150,vYValue, "Constant1:"+twGlobals[%sConstant1][%$sProject]
	elseif(stringmatch(sS2Type,"Constant2"))
		DrawText 150,vYValue, "Constant2:"+twGlobals[%sConstant2][%$sProject]
	endif
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save
	
	
	//Dest__________
	SetDrawEnv  textrgb= (2,39321,1); SetDrawEnv save
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTableD,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Meta;Library;Scalar;Vector",proc=DataSifter_UpdateGlobal,popvalue=sTableD
	//DLibrary
	vYValue+=20
	DrawText 90,vYValue, " Library:"
	PopupMenu sDLibrary,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("Libraries",-2,4),proc=DataSifter_UpdateGlobal,popvalue=sDLibrary
	//DData
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sDataD,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("DataTypes",-2,4),proc=DataSifter_UpdateGlobal,popvalue=sDataD
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	DrawText 150,vYValue, sTableD+"["+"Library"+"]["+num2str(str2num(sFirstSample)-1)+","+num2str(str2num(sLastSample)-1)+"]["+"Data"+"][*]"
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save
	
	
	//Source3__________
	SetDrawEnv textrgb=(32896,16448,0); SetDrawEnv save
	//Type1
	vYValue+=20
	DrawText 90,vYValue, "Type:"
	PopupMenu sS3Type,pos={230,vYValue-10},mode=1,bodyWidth=190,value="Data;Constant1;Constant2",proc=DataSifter_UpdateGlobal,popvalue=sS3Type
	//Table2
	vYValue+=20
	DrawText 90,vYValue, "Dimension:"
	PopupMenu sTable3,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;Meta;Library;Scalar;Vector",proc=DataSifter_UpdateGlobal,popvalue=sTable3
	//Library2
	vYValue+=20
	DrawText 90,vYValue, "Library:"
	PopupMenu sSLibrary3,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("Libraries",-3,3),proc=DataSifter_UpdateGlobal,popvalue=sSLibrary3
	//Data2
	vYValue+=20
	DrawText 90,vYValue, "Data:"
	PopupMenu sData3,pos={230,vYValue-10},mode=1,bodyWidth=190,value=" ;"+DataSifter_DropList("DataTypes",-3,3),proc=DataSifter_UpdateGlobal,popvalue=sData3
	//printout
	vYValue+=20
	SetDrawEnv textxjust = 1,textyjust = 1,fstyle=1; SetDrawEnv save
	if(stringmatch(sS3Type,"Data"))
		if(!stringmatch(" ",sTable3))
			DrawText 150,vYValue, sTable3+"["+"Library"+"]["+num2str(str2num(sFirstSample)-1)+","+num2str(str2num(sLastSample)-1)+"]["+"Data"+"][*]"
		endif
	elseif(stringmatch(sS3Type,"Constant1"))
		DrawText 150,vYValue, "Constant1:"+twGlobals[%sConstant1][%$sProject]
	elseif(stringmatch(sS3Type,"Constant2"))
		DrawText 150,vYValue, "Constant2:"+twGlobals[%sConstant2][%$sProject]
	endif
	SetDrawEnv textxjust = 2,textyjust = 1,fstyle=0; SetDrawEnv save
	
	SetDrawEnv textrgb=(0,0,0); SetDrawEnv save
	//constant1
	vYValue+=20
	DrawText 90,vYValue, "Constant 1:"
	SetVariable sConstant1,title=" " ,pos={90,vYValue-10},size={190,20},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sConstant1][%$sProject]
	//constant2
	vYValue+=20
	DrawText 90,vYValue, "Constant 2:"
	SetVariable sConstant2,title=" " ,pos={90,vYValue-10},size={190,20},fsize=14,live=1,noproc,font=sFont,value=twGlobals[%sConstant2][%$sProject]
	
	//operator
	vYValue+=20
	DrawText 90,vYValue, "Operation:"
	PopupMenu sOperation,pos={230,vYValue-10},mode=1,bodyWidth=190,value=DataSifter_OperationList() ,proc=DataSifter_UpdateGlobal,popvalue=sOperation
	
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
	SetDrawEnv textxjust = 1, save
	if(stringmatch("<",sOperation)||stringmatch(">",sOperation)||stringmatch("<=",sOperation)||stringmatch(">=",sOperation)||stringmatch("==",sOperation)||stringmatch("!=",sOperation))
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 2, save;  DrawText 85,vYValue+25, "If: "
		SetDrawEnv textrgb=(65535,0,0),fsize = 20,textxjust = 2, save;  DrawText 110,vYValue+25, "\W5016"//S1
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 1, save;  DrawText 125,vYValue+25, sOperation
		SetDrawEnv textrgb=(0,0,65535),fsize = 20,textxjust = 2, save;  DrawText 180,vYValue+25, "\W5016"//S2
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 2, save;  DrawText 85,vYValue+45, "Then: "
		SetDrawEnv textrgb=(2,39321,1),fsize = 20,textxjust = 2, save;  DrawText 110,vYValue+45, "\W5016"//D
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 1, save;  DrawText 125,vYValue+45, "="
		SetDrawEnv textrgb=(32896,16448,0),fsize = 20,textxjust = 2, save;  DrawText 180,vYValue+45, "\W5016"//S3
	elseif(stringmatch("Doesn't Contain",sOperation)||stringmatch("Doesn't Match",sOperation))
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 2, save;  DrawText 65,vYValue+25, "If: "
		SetDrawEnv textrgb=(65535,0,0),fsize = 20,textxjust = 1, save;  DrawText 80,vYValue+25, "\W5016"//S1
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 1, save;  DrawText 165,vYValue+25, sOperation
		SetDrawEnv textrgb=(0,0,65535),fsize = 20,textxjust = 1, save;  DrawText 250,vYValue+25, "\W5016"//S2
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 2, save;  DrawText 65,vYValue+45, "Then: "
		SetDrawEnv textrgb=(2,39321,1),fsize = 20,textxjust = 1, save;  DrawText 80,vYValue+45, "\W5016"//D
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 1, save;  DrawText 100,vYValue+45, "="
		SetDrawEnv textrgb=(32896,16448,0),fsize = 20,textxjust = 1, save;  DrawText 120,vYValue+45, "\W5016"//S3
	elseif(stringmatch("Contains",sOperation)||stringmatch("Matches",sOperation))
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 2, save;  DrawText 65,vYValue+25, "If: "
		SetDrawEnv textrgb=(65535,0,0),fsize = 20,textxjust = 1, save;  DrawText 80,vYValue+25, "\W5016"//S1
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 1, save;  DrawText 140,vYValue+25, sOperation
		SetDrawEnv textrgb=(0,0,65535),fsize = 20,textxjust = 1, save;  DrawText 200,vYValue+25, "\W5016"//S2
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 2, save;  DrawText 65,vYValue+45, "Then: "
		SetDrawEnv textrgb=(2,39321,1),fsize = 20,textxjust = 1, save;  DrawText 80,vYValue+45, "\W5016"//D
		SetDrawEnv textrgb=(0,0,0),fsize = 16,textxjust = 1, save;  DrawText 100,vYValue+45, "="
		SetDrawEnv textrgb=(32896,16448,0),fsize = 20,textxjust = 1, save;  DrawText 120,vYValue+45, "\W5016"//S3
	elseif(stringmatch("Contains",sOperation))
		
	elseif(stringmatch("Doesn't Contain",sOperation))
		
	endif
	//compute
	vYValue+=62
	button Compute,title="Sifter Data!",appearance={native,All},pos={50,vYValue},size={200,30},proc=DataSifter_SiftButton,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=16
	
end

Function DataSifter_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	if(stringmatch("sProject",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	elseif(stringmatch("sTable1",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTable1",num2str(WhichListItem(popStr, "Meta;Library;Scalar;Vector; ")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sData1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sTable2",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTable2",num2str(WhichListItem(popStr, "Meta;Library;Scalar;Vector; ")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sData2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sTable3",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTable3",num2str(WhichListItem(popStr, "Meta;Library;Scalar;Vector; ")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sData3"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sSLibrary3"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sTableD",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sTableD",num2str(WhichListItem(popStr, "Meta;Library;Scalar;Vector")),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sDataD"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		COMBI_GivePluginGlobal(sPluginName,"sDLibrary"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sS1Type",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		if(stringmatch(popStr,"Constant1")||stringmatch(popStr,"Constant2"))
			COMBI_GivePluginGlobal(sPluginName,"sTable1","4",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sSLibrary1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sData1"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		endif
	elseif(stringmatch("sS2Type",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		if(stringmatch(popStr,"Constant1")||stringmatch(popStr,"Constant2"))
			COMBI_GivePluginGlobal(sPluginName,"sTable2","4",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sSLibrary2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sData2"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		endif
	elseif(stringmatch("sS3Type",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		if(stringmatch(popStr,"Constant1")||stringmatch(popStr,"Constant2"))
			COMBI_GivePluginGlobal(sPluginName,"sTable3","4",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sSLibrary3"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
			COMBI_GivePluginGlobal(sPluginName,"sData3"," ",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
		endif
	else
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	COMBI_DataSift()
End

//function to return drop downs of Libraries for panel
function/S DataSifter_DropList(sOption,iDim,iData)
	string sOption //"Libraries" or "DataTypes"
	int iDim //-3 for all, -2 for all numeric, -1 for Meta, 0 for Library, 1 for scalar, 2 for vector
	int iData //1 for Data1, 2 for Data2, 3 for Data3, 4 for DataD
	int iDataTypeDim
	int iLibraryDim
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	string sLibrary
	if(stringmatch(sOption,"Libraries"))
		if(iData==1)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTable1",sProject)-1
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		elseif(iData==2)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTable2",sProject)-1
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		elseif(iData==3)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTable3",sProject)-1
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		elseif(iData==4)
			iLibraryDim = COMBI_GetPluginNumber(sPluginName,"sTableD",sProject)-1
			return COMBI_TableList(sProject,iLibraryDim,"All",sOption)
		endif
		
	elseif(stringmatch(sOption,"DataTypes"))
		if(iData==1)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTable1",sProject)-1
			sLibrary =  COMBI_GetPluginString(sPluginName,"sSLibrary1",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		elseif(iData==2)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTable2",sProject)-1
			sLibrary =  COMBI_GetPluginString(sPluginName,"sSLibrary2",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		elseif(iData==3)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTable3",sProject)-1
			sLibrary =  COMBI_GetPluginString(sPluginName,"sSLibrary3",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		elseif(iData==4)
			iDataTypeDim = COMBI_GetPluginNumber(sPluginName,"sTableD",sProject)-1
			sLibrary =  COMBI_GetPluginString(sPluginName,"sDLibrary",sProject)
			return COMBI_TableList(sProject,iDataTypeDim,sLibrary,sOption)
		endif
	endif
	
	
	
end

Function DataSifter_New(ctrlName) : ButtonControl
	String ctrlName
	//Plugin globals
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	if(stringmatch("sNewDataType",ctrlName))
		COMBI_NewEntry(sProject,"DataType")
	elseif(stringmatch("sNewLibrary",ctrlName))
		COMBI_NewEntry(sProject,"Library")
	endif
	return -1
End

Function DataSifter_SiftButton(ctrlName) : ButtonControl
	String ctrlName
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	
	string sS1Type = COMBI_GetPluginString(sPluginName,"sS1Type",sProject)
	string sTable1 = COMBI_GetPluginString(sPluginName,"sTable1",sProject)
	string sData1 = COMBI_GetPluginString(sPluginName,"sData1",sProject)
	string sSLibrary1 = COMBI_GetPluginString(sPluginName,"sSLibrary1",sProject)
	
	string sS2Type = COMBI_GetPluginString(sPluginName,"sS2Type",sProject)
	string sTable2 = COMBI_GetPluginString(sPluginName,"sTable2",sProject)
	string sData2 = COMBI_GetPluginString(sPluginName,"sData2",sProject)
	string sSLibrary2 = COMBI_GetPluginString(sPluginName,"sSLibrary2",sProject)
	
	string sS3Type = COMBI_GetPluginString(sPluginName,"sS3Type",sProject)
	string sTable3 = COMBI_GetPluginString(sPluginName,"sTable3",sProject)
	string sData3 = COMBI_GetPluginString(sPluginName,"sData3",sProject)
	string sSLibrary3 = COMBI_GetPluginString(sPluginName,"sSLibrary3",sProject)
	
	string sOperation = COMBI_GetPluginString(sPluginName,"sOperation",sProject)
	
	string sTableD = COMBI_GetPluginString(sPluginName,"sTableD",sProject)
	string sDataD = COMBI_GetPluginString(sPluginName,"sDataD",sProject)
	string sDLibrary = COMBI_GetPluginString(sPluginName,"sDLibrary",sProject)
	
	string sFirstSample = COMBI_GetPluginString(sPluginName,"sFirstSample",sProject)
	string sLastSample = COMBI_GetPluginString(sPluginName,"sLastSample",sProject)
	
	string sConstant1 = COMBI_GetPluginString(sPluginName,"sConstant1",sProject)
	string sConstant2 = COMBI_GetPluginString(sPluginName,"sConstant2",sProject)
	
	if(DataSifter_CheckInputs(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2)==0)
		return -1
	endif
	
	//call line
	if(stringmatch("Yes",COMBI_GetGlobalString("sCommandLines","COMBIgor")))
		Print "DataSifter_Sift(\""+sProject+"\",\""+sS1Type+"\",\""+sTable1+"\",\""+sData1+"\",\""+sSLibrary1+"\",\""+sS2Type+"\",\""+sTable2+"\",\""+sData2+"\",\""+sSLibrary2+"\",\""+sS3Type+"\",\""+sTable3+"\",\""+sData3+"\",\""+sSLibrary3+"\",\""+sOperation+"\",\""+sTableD+"\",\""+sDataD+"\",\""+sDLibrary+"\",\""+sFirstSample+"\",\""+sLastSample+"\",\""+sConstant1+"\",\""+sConstant2+"\")"
	endif
	//pass
	DataSifter_Sift(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2)
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

Function DataSifter_Sift(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2)
	String sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:
	if(DataSifter_CheckInputs(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2)==0)
		//return to users active data folder
		SetDataFolder $sTheCurrentUserFolder 
		return -1
	endif
	
	 //make sure tables are equalized for all dims
	int iTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)-1
	
	//make process wave, 4 Libraries, 4 data types, all Samples, only one vector dim for now (if vectors are used it will be increased to match vector length)
	Make/O/T/N=(4,iTotalSamples+1,4,1), wProcessWave
	wave/T wProcessWave = root:wProcessWave
	setdimLabel 0,0,sSLibrary1,wProcessWave
	setdimLabel 0,1,sSLibrary2,wProcessWave
	setdimLabel 0,2,sSLibrary3,wProcessWave
	setdimLabel 2,0,sData1,wProcessWave
	setdimLabel 2,1,sData2,wProcessWave
	setdimLabel 2,2,sData3,wProcessWave
	setdimLabel 0,3,DestLibrary,wProcessWave
	setdimLabel 2,3,DestData,wProcessWave
	
	//for correct sizing
	int bVectorSized = 0, iVector
	int iWaveOrgSize=0, iWaveNewSize=0
	int bSamplesInSifters = 0
	if(stringmatch(sTableD,"3"))
		 wave wWaveDPre = $COMBI_DataPath(sProject,2)+sDLibrary+":"+sDataD
		iWaveOrgSize = dimsize(wProcessWave,3)-1
		iWaveNewSize = dimsize(wWaveDPre,1)-1
		redimension/N=(-1,-1,-1,iWaveNewSize+1) wProcessWave
		wProcessWave[][][][(iWaveOrgSize+1),iWaveNewSize] = wProcessWave[p][q][r][iWaveOrgSize]
		bVectorSized=1
	endif
	
	//get source 1
	if(stringmatch("Data",sS1Type))//from COMBIgor storage
		if(stringmatch(sTable1,"0"))//meta data
			 wave/T wWave1 = $COMBI_DataPath(sProject,str2num(sTable1)-1)
			 //transfer data to string
			 wProcessWave[%sSLibrary1][][%sData1][] = wWave1[%$sSLibrary1][%$sData1]
		elseif(stringmatch(sTable1,"1"))//Library data
			 wave wWave1Num = $COMBI_DataPath(sProject,str2num(sTable1)-1)
			 //transfer data to string
			  wProcessWave[%sSLibrary1][][%sData1][] = num2str(wWave1Num[%$sSLibrary1][%$sData1])
		elseif(stringmatch(sTable1,"2"))//scalar data
			 wave wWave1Num = $COMBI_DataPath(sProject,str2num(sTable1)-1)+sSLibrary1+":"+sData1
			 //transfer data to string
			  wProcessWave[%sSLibrary1][][%sData1][] = num2str(wWave1Num[q])
			  bSamplesInSifters=1
		elseif(stringmatch(sTable1,"3"))//vector data
			wave wWave1Num = $COMBI_DataPath(sProject,str2num(sTable1)-1)+sSLibrary1+":"+sData1
			//expand vectro dim to match
			if(bVectorSized==0)
				iWaveOrgSize = dimsize(wProcessWave,3)-1
				iWaveNewSize = dimsize(wWave1Num,1)-1
				redimension/N=(-1,-1,-1,iWaveNewSize+1) wProcessWave
				wProcessWave[][][][(iWaveOrgSize+1),iWaveNewSize] = wProcessWave[p][q][r][iWaveOrgSize]
				bVectorSized=1
			endif
			//transfer data to string
			for(iVector=0;iVector<=iWaveNewSize;iVector+=1)
				wProcessWave[%sSLibrary1][][%sData1][iVector] = num2str(wWave1Num[q][iVector])
			endfor
			bSamplesInSifters=1
		endif
	elseif(stringmatch("Constant1",sS1Type))//constant 1 on panel 
		wProcessWave[%sSLibrary1][][%sData1][] = sConstant1
	elseif(stringmatch("Constant2",sS1Type))//constant 2 on panel 
		wProcessWave[%sSLibrary1][][%sData1][] = sConstant2
	endif

	//get source 2
	if(stringmatch("Data",sS2Type))//from COMBIgor storage
		if(stringmatch(sTable2,"0"))//meta data
			 wave/T wWave2 = $COMBI_DataPath(sProject,str2num(sTable2)-1)
			 //transfer data to string
			 wProcessWave[%sSLibrary2][][%sData2][] = wWave2[%$sSLibrary2][%$sData2]
		elseif(stringmatch(sTable2,"1"))//Library data 
			 wave wWave2Num = $COMBI_DataPath(sProject,str2num(sTable2)-1)
			 //transfer data to string
			  wProcessWave[%sSLibrary2][][%sData2][] = num2str(wWave2Num[%$sSLibrary2][%$sData2])
		elseif(stringmatch(sTable2,"2"))//scalar data
			 wave wWave2Num = $COMBI_DataPath(sProject,str2num(sTable2)-1)+sSLibrary2+":"+sData2
			 //transfer data to string
			  wProcessWave[%sSLibrary2][][%sData2][] = num2str(wWave2Num[q])
			 bSamplesInSifters=1
		elseif(stringmatch(sTable2,"3"))//vector data
			wave wWave2Num = $COMBI_DataPath(sProject,str2num(sTable2)-1)+sSLibrary2+":"+sData2
			//expand vectro dim to match
			if(bVectorSized==0)
				iWaveOrgSize = dimsize(wProcessWave,3)-1
				iWaveNewSize = dimsize(wWave2Num,1)-1
				redimension/N=(-1,-1,-1,iWaveNewSize+1) wProcessWave
				wProcessWave[][][][(iWaveOrgSize+1),iWaveNewSize] = wProcessWave[p][q][r][iWaveOrgSize]
				bVectorSized=1
			endif
			//transfer data to string//transfer data to string
			for(iVector=0;iVector<=iWaveNewSize;iVector+=1)
				wProcessWave[%sSLibrary2][][%sData2][iVector] = num2str(wWave2Num[q][iVector])
			endfor
			bSamplesInSifters=1
		endif
	elseif(stringmatch("Constant1",sS2Type))//constant 1 on panel 
		wProcessWave[%sSLibrary2][][%sData2][] = sConstant1
	elseif(stringmatch("Constant2",sS2Type))//constant 2 on panel 
		wProcessWave[%sSLibrary2][][%sData2][] = sConstant2
	endif
	
	//get source 3
	if(stringmatch("Data",sS3Type))//from COMBIgor storage
		if(stringmatch(sTable3,"0"))//meta data
			 wave/T wWave3 = $COMBI_DataPath(sProject,str2num(sTable3)-1)
			 //transfer data to string
			 wProcessWave[%sSLibrary3][][%sData3][] = wWave3[%$sSLibrary3][%$sData3]
		elseif(stringmatch(sTable3,"1"))//Library data
			 wave wWave3Num = $COMBI_DataPath(sProject,str2num(sTable3)-1)
			 //transfer data to string
			  wProcessWave[%sSLibrary3][][%sData3][] = num2str(wWave3Num[%$sSLibrary3][%$sData3])
		elseif(stringmatch(sTable3,"2"))//Library data or scalar data
			 wave wWave3Num = $COMBI_DataPath(sProject,str2num(sTable3)-1)+sSLibrary3+":"+sData3
			 //transfer data to string
			  wProcessWave[%sSLibrary3][][%sData3][] = num2str(wWave3Num[q])
			  bSamplesInSifters=1
		elseif(stringmatch(sTable3,"3"))//vector data
			wave wWave3Num = $COMBI_DataPath(sProject,str2num(sTable3)-1)+sSLibrary3+":"+sData3
			//expand vector dim to match
			if(bVectorSized==0)
				iWaveOrgSize = dimsize(wProcessWave,3)-1
				iWaveNewSize = dimsize(wWave3Num,1)-1
				redimension/N=(-1,-1,-1,iWaveNewSize+1) wProcessWave
				wProcessWave[][][][(iWaveOrgSize+1),iWaveNewSize] = wProcessWave[p][q][r][iWaveOrgSize]
				bVectorSized=1
			endif
			//transfer data to string
			for(iVector=0;iVector<=iWaveNewSize;iVector+=1)
				wProcessWave[%sSLibrary3][][%sData3][iVector] = num2str(wWave3Num[q][iVector])
			endfor
			bSamplesInSifters=1
		endif
	elseif(stringmatch("Constant1",sS3Type))//constant 1 on panel 
		wProcessWave[%sSLibrary3][][%sData3][] = sConstant1
	elseif(stringmatch("Constant2",sS3Type))//constant 2 on panel 
		wProcessWave[%sSLibrary3][][%sData3][] = sConstant2
	endif
	
	//get Sample bounds 
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1
	int iSample
	
	//get vector (chunk) bounds
	int iFirstChunk = 0
	int iLastChunk = dimsize(wProcessWave,3)-1
	int iChunk
	
	//for chunk tracking
	int bChunkTrack = 0
	if(bVectorSized==1)
		if(stringmatch(sTableD,"1")||stringmatch(sTableD,"2")) //destination not vector
			if(stringmatch(sTable1,"3")||stringmatch(sTable2,"3")||stringmatch(sTable3,"3"))// Siftering involves vectors
				redimension/N=(-1,-1,6,-1) wProcessWave
				wProcessWave[][][4][] =""
				wProcessWave[][][5][] ="0"
				setdimLabel 2,4,ChunkNumbers,wProcessWave
				setdimLabel 2,5,TotalHits,wProcessWave
				bChunkTrack = 1
			endif
		endif
	endif
	
	//loop through all Samples and chunks to test with approriate operation
	for(iSample=iFirstSample;iSample<=iLastSample;iSample+=1)
		for(iChunk=iFirstChunk;iChunk<=iLastChunk;iChunk+=1)
			strswitch(sOperation)
				case ">":
					if(str2num(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk])>str2num(wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case ">=":
					if(str2num(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk])>=str2num(wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "<":
					if(str2num(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk])<str2num(wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "<=":
					if(str2num(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk])<=str2num(wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "!=":
					if(str2num(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk])!=str2num(wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "==":
					if(str2num(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk])==str2num(wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "Matches":
					if(stringmatch(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk],wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "Doesn't Match":
					if(!stringmatch(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk],wProcessWave[%sSLibrary2][iSample][%sData2][iChunk]))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "Contains":
					if(stringmatch(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk],("*"+wProcessWave[%sSLibrary2][iSample][%sData2][iChunk])+"*"))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
				case "Doesn't Contain":
					if(!stringmatch(wProcessWave[%sSLibrary1][iSample][%sData1][iChunk],("*"+wProcessWave[%sSLibrary2][iSample][%sData2][iChunk])+"*"))
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = wProcessWave[%sSLibrary3][iSample][%sData3][iChunk]
						if(bChunkTrack==1)
							wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0] = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]+num2str(iChunk)+";"
							wProcessWave[%DestLibrary][iSample][%TotalHits][0] = num2str(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])+1)
						endif
					else
						wProcessWave[%DestLibrary][iSample][%DestData][iChunk] = ""
					endif
					break
			endswitch
		endfor
	endfor
	string sScalarizeChunksOption = "No", sScalarizeSamplesOption = "No", sAllChunks
	int bMoreThan1Chunk,vTotalHits, iThisChunk
	variable vTotal, vMin, vMax, vThisValue
	
	//scalarizing
	if(stringmatch(sTableD,"0")||stringmatch(sTableD,"1")||stringmatch(sTableD,"2"))//anything less than vector
		if(bChunkTrack==1)// if Siftering involved chunks
			bMoreThan1Chunk=0
			for(iSample=0;iSample<=iTotalSamples;iSample+=1)
				if(str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])>1)
					bMoreThan1Chunk = 1
				endif
			endfor
			if(bMoreThan1Chunk==1)
				//how to scalarize
				sScalarizeChunksOption = COMBI_StringPrompt("Average","How to scalarize multiple hit results into the scalar table","Average;First;Last;Sum;Min;Max","This specifies how to convert non-scalar results (multiple chunks) into scalar format.","Scalarizing Options!")
				if(stringmatch(sScalarizeChunksOption,"CANCEL"))
					return-1
				else
					//do transform, store result in chunk 0
					if(stringmatch(sScalarizeChunksOption,"Average"))
						for(iSample=0;iSample<=iTotalSamples;iSample+=1)
							vTotal = 0
							vTotalHits = str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])
							if(vTotalHits==0)
								continue
							endif
							sAllChunks = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]
							for(iChunk=0;iChunk<vTotalHits;iChunk+=1)
								iThisChunk = str2num(stringfromlist(iChunk,sAllChunks))
								vTotal+=str2num(wProcessWave[%DestLibrary][iSample][%DestData][iThisChunk])
							endfor
							wProcessWave[%DestLibrary][iSample][%DestData][0] = num2str(vTotal/vTotalHits)
						endfor
					elseif(stringmatch(sScalarizeChunksOption,"First"))
						for(iSample=0;iSample<=iTotalSamples;iSample+=1)
							vTotalHits = str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])
							if(vTotalHits==0)
								continue
							endif
							sAllChunks = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]
							iThisChunk = str2num(stringfromlist(0,sAllChunks))
							wProcessWave[%DestLibrary][iSample][%DestData][0] = wProcessWave[%DestLibrary][iSample][%DestData][iThisChunk]
						endfor
					elseif(stringmatch(sScalarizeChunksOption,"Last"))
						for(iSample=0;iSample<=iTotalSamples;iSample+=1)
							vTotalHits = str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])
							if(vTotalHits==0)
								continue
							endif
							sAllChunks = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]
							iThisChunk = str2num(stringfromlist(vTotalHits-1,sAllChunks))
							wProcessWave[%DestLibrary][iSample][%DestData][0] = wProcessWave[%DestLibrary][iSample][%DestData][iThisChunk]
						endfor
					elseif(stringmatch(sScalarizeChunksOption,"Sum"))
						for(iSample=0;iSample<=iTotalSamples;iSample+=1)
							vTotal = 0
							vTotalHits = str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])
							if(vTotalHits==0)
								continue
							endif
							sAllChunks = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]
							for(iChunk=0;iChunk<vTotalHits;iChunk+=1)
								iThisChunk = str2num(stringfromlist(iChunk,sAllChunks))
								vTotal+=str2num(wProcessWave[%DestLibrary][iSample][%DestData][iThisChunk])
							endfor
							wProcessWave[%DestLibrary][iSample][%DestData][0] = num2str(vTotal)
						endfor
					elseif(stringmatch(sScalarizeChunksOption,"Min"))
						for(iSample=0;iSample<=iTotalSamples;iSample+=1)
							vMin = inf
							vTotalHits = str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])
							if(vTotalHits==0)
								continue
							endif
							sAllChunks = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]
							for(iChunk=0;iChunk<vTotalHits;iChunk+=1)
								iThisChunk = str2num(stringfromlist(iChunk,sAllChunks))
								vThisValue = str2num(wProcessWave[%DestLibrary][iSample][%DestData][iThisChunk])
								if(vThisValue<vMin)
									vMin = vThisValue
								endif
							endfor
							wProcessWave[%DestLibrary][iSample][%DestData][0] = num2str(vMin)
						endfor
					elseif(stringmatch(sScalarizeChunksOption,"Max"))
						for(iSample=0;iSample<=iTotalSamples;iSample+=1)
							vMax = -inf
							vTotalHits = str2num(wProcessWave[%DestLibrary][iSample][%TotalHits][0])
							if(vTotalHits==0)
								continue
							endif
							sAllChunks = wProcessWave[%DestLibrary][iSample][%ChunkNumbers][0]
							for(iChunk=0;iChunk<vTotalHits;iChunk+=1)
								iThisChunk = str2num(stringfromlist(iChunk,sAllChunks))
								vThisValue = str2num(wProcessWave[%DestLibrary][iSample][%DestData][iThisChunk])
								if(vThisValue>vMax)
									vMax = vThisValue
								endif
							endfor
							wProcessWave[%DestLibrary][iSample][%DestData][0] = num2str(vMax)
						endfor
					endif
				endif
			endif
		endif
	endif
	
	//Library table destination but Sifter is by Sample?
	if(stringmatch(sTableD,"1"))	
		if(bSamplesInSifters==1)
			sScalarizeSamplesOption = COMBI_StringPrompt("Average","How to put per-sample results into library table","Average;First;Last;Sum;Min;Max","This specifies how to convert non-library results (multiple Samples) into library format.","Samplizing Options!")
			if(stringmatch(sScalarizeSamplesOption,"CANCEL"))
				return-1
			else
				//do transform
				variable vThisSampleHit
				if(stringmatch(sScalarizeSamplesOption,"Average"))
					vTotal = 0
					vTotalHits = 0
					for(iSample=0;iSample<=iTotalSamples;iSample+=1)
						vThisSampleHit = str2num(wProcessWave[%DestLibrary][iSample][%DestData][0])
						if(numtype(vThisSampleHit)!=0)
							continue
						endif
						vTotal+=vThisSampleHit
						vTotalHits+=1
					endfor
					wProcessWave[%DestLibrary][0][%DestData][0] = num2str(vTotal/vTotalHits)
				elseif(stringmatch(sScalarizeSamplesOption,"First"))
					//just gonna use col 0
				elseif(stringmatch(sScalarizeSamplesOption,"Last"))
					wProcessWave[%DestLibrary][0][%DestData][0] = wProcessWave[%DestLibrary][iTotalSamples][%DestData][0]
				elseif(stringmatch(sScalarizeSamplesOption,"Sum"))
					vTotal = 0
					for(iSample=0;iSample<=iTotalSamples;iSample+=1)
						vThisSampleHit = str2num(wProcessWave[%DestLibrary][iSample][%DestData][0])
						if(numtype(vThisSampleHit)!=0)
							continue
						endif
						vTotal+=vThisSampleHit
					endfor
					wProcessWave[%DestLibrary][0][%DestData][0] = num2str(vTotal)
				elseif(stringmatch(sScalarizeSamplesOption,"Min"))
					vMin = inf
					for(iSample=0;iSample<=iTotalSamples;iSample+=1)
						vThisSampleHit = str2num(wProcessWave[%DestLibrary][iSample][%DestData][0])
						if(numtype(vThisSampleHit)!=0)
							continue
						endif
						if(vThisSampleHit<vMin)
							vMin = vThisSampleHit
						endif
					endfor
					if(vMin!=inf)
						wProcessWave[%DestLibrary][0][%DestData][0] = num2str(vMin)
					else
						wProcessWave[%DestLibrary][0][%DestData][0]  = ""
					endif
				elseif(stringmatch(sScalarizeSamplesOption,"Max"))
					vMax = -inf
					for(iSample=0;iSample<=iTotalSamples;iSample+=1)
						vThisSampleHit = str2num(wProcessWave[%DestLibrary][iSample][%DestData][0])
						if(numtype(vThisSampleHit)!=0)
							continue
						endif
						if(vThisSampleHit>vMax)
							vMax = vThisSampleHit
						endif
					endfor
					if(vMax!=-inf)
						wProcessWave[%DestLibrary][0][%DestData][0] = num2str(vMax)
					else
						wProcessWave[%DestLibrary][0][%DestData][0] = ""
					endif
				endif
			endif
		endif
	endif
	
	if(stringmatch(sTableD,"0"))//meta data
		wave/T wWaveDT = $COMBI_DataPath(sProject,str2num(sTableD)-1)
		wWaveDT[%$sDLibrary][][%$sDataD] = wProcessWave[%DestLibrary][q][%DestData][0] 
	elseif(stringmatch(sTableD,"1"))//libray data
		wave wWaveDNum = $COMBI_DataPath(sProject,str2num(sTableD)-1)
		wWaveDNum[%$sDLibrary][%$sDataD] = str2num(wProcessWave[%DestLibrary][0][%DestData][0])
	elseif(stringmatch(sTableD,"2"))//scalar data
		wave wWaveDNum = $COMBI_DataPath(sProject,str2num(sTableD)-1)+sDLibrary+":"+sDataD
		if(dimsize(wProcessWave,1)==dimsize(wWaveDNum,0))
			wWaveDNum[] = str2num(wProcessWave[%DestLibrary][p][%DestData][0])
		endif			 
	elseif(stringmatch(sTableD,"3"))//vector data
		wave wWaveDNum = $COMBI_DataPath(sProject,str2num(sTableD)-1)+sDLibrary+":"+sDataD
		if(dimsize(wProcessWave,3)==dimsize(wWaveDNum,1))
			wWaveDNum[][] = str2num(wProcessWave[%DestLibrary][p][%DestData][q])
		endif		
	endif
	
	//add to data log
	string sLogEntry1,sLogEntry2,sLogEntry3,sLogEntry4,sLogEntry5,sLogText
	sLogEntry1 = "Siftered by COMBIgor Data Sifter Plugin: "
	sLogEntry2 = "DataSifter_Sift(\""+sProject+"\",\""+sS1Type+"\",\""+sTable1+"\",\""+sData1+"\",\""+sSLibrary1+"\",\""+sS2Type+"\",\""+sTable2+"\",\""+sData2+"\",\""+sSLibrary2+"\",\""+sS3Type+"\",\""+sTable3+"\",\""+sData3+"\",\""+sSLibrary3+"\",\""+sOperation+"\",\""+sTableD+"\",\""+sDataD+"\",\""+sDLibrary+"\",\""+sFirstSample+"\",\""+sLastSample+"\",\""+sConstant1+"\",\""+sConstant2+"\")"
	sLogEntry3 = "Test Condition:    "+"Red Source="+sS1Type+",Table Dim:"+sTable1+",Data:"+sData1+",Library:"+sSLibrary1+".   Operation= "+sOperation+".   Blue source="+sS2Type+",Table Dim:"+sTable2+",Data:"+sData2+",Library:"+sSLibrary2
	sLogEntry4 = "Resulting Operation:    "+"Brown Source="+sS3Type+",Table Dim:"+sTable3+",Data:"+sData3+",Library:"+sSLibrary3+" stored in  Green=Table Dim:"+sTableD+",Data:"+sDataD+",Library:"+sDLibrary
	sLogEntry5 = "Scalarizing Options: Samples="+sScalarizeSamplesOption+", Chunks="+sScalarizeChunksOption
	sLogText = sLogEntry1+";"+sLogEntry2+";"+sLogEntry3+";"+sLogEntry4+";"+sLogEntry5
	COMBI_Add2Log(sProject,sDLibrary,sDataD,2,sLogText)		
	
	//kill constant waves 
	killwaves/Z wProcessWave
	
	//return to users active data folder
	SetDataFolder $sTheCurrentUserFolder 
end

function/S DataSifter_OperationList()
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	int iTable1 = COMBI_GetPluginNumber(sPluginName,"sTable1",sProject)
	int iTable2 = COMBI_GetPluginNumber(sPluginName,"sTable2",sProject)
	int iTable3 = COMBI_GetPluginNumber(sPluginName,"sTable3",sProject)
	int iTableD = COMBI_GetPluginNumber(sPluginName,"sTableD",sProject)
	if(iTable1>0&&iTable2>0)
		return ">;>=;<=;<;!=;=="
	elseif((iTable3==0||iTable3==4)&&iTableD==0)
		return "Matches;Doesn't Match;Contains;Doesn't Contain"
	else
		return "!!!"
	endif
	
end

//return 0 if bad inputs, 1 if good inputs
Function DataSifter_CheckInputs(sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2)
	string sProject,sS1Type,sTable1,sData1,sSLibrary1,sS2Type,sTable2,sData2,sSLibrary2,sS3Type,sTable3,sData3,sSLibrary3,sOperation,sTableD,sDataD,sDLibrary,sFirstSample,sLastSample,sConstant1,sConstant2
	int iTotalSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)-1
	int iFirstSample = str2num(sFirstSample)-1
	int iLastSample = str2num(sLastSample)-1

	//check Sample range 
	if(iFirstSample<0||iFirstSample>iTotalSamples)
		DoAlert/T="Bad Sample Range" 0, "First sample should be between 0 and "+num2str(iTotalSamples+1)+"!"
		return 0
	endif
	if(iLastSample<0||iLastSample>iTotalSamples)
		DoAlert/T="Bad Sample Range" 0, "Last sample should be between 0 and "+num2str(iTotalSamples+1)+"!"
		return 0
	endif

	//check s1
	if(stringmatch(sS1Type,"Data"))
		if(stringmatch(sSLibrary1," ")||stringmatch(sData1," ")||stringmatch(sTable1,"4"))
			DoAlert/T="Incomplete Inputs" 0, "To use red as data, it must have a valid dimension, library name, and data type."
			return 0
		endif
	elseif(stringmatch(sS1Type,"Constant1"))
		if(numtype(str2num(sConstant1))!=0)
			DoAlert/T="Bad inputs" 0, "To use red as Constant 1, there must be a number in the field."
			return 0
		endif
	elseif(stringmatch(sS1Type,"Constant2"))
		if(numtype(str2num(sConstant2))!=0)
			DoAlert/T="Bad inputs!" 0, "To use red as Constant 2, there must be a number in the field."
			return 0
		endif
	endif


	//check s2
	if(stringmatch(sS2Type,"Data"))
		if(stringmatch(sSLibrary2," ")||stringmatch(sData2," ")||stringmatch(sTable2,"4"))
			DoAlert/T="Incomplete Inputs" 0, "To use blue as data, it must have a valid dimension, library name, and data type."
			return -1
		endif
	elseif(stringmatch(sS2Type,"Constant1"))
		if(numtype(str2num(sConstant1))!=0)
			DoAlert/T="Bad inputs" 0, "To use blue as Constant 1, there must be a number in the field."
			return 0
		endif
	elseif(stringmatch(sS2Type,"Constant2"))
		if(numtype(str2num(sConstant2))!=0)
			DoAlert/T="Bad inputs" 0, "To use blue as Constant 2, there must be a number in the field."
			return 0
		endif
	endif
	
	
	//check s3
	if(stringmatch(sS3Type,"Data"))
		if(stringmatch(sSLibrary3," ")||stringmatch(sData3," ")||stringmatch(sTable3,"4"))
			DoAlert/T="Incomplete Inputs" 0, "To use magenta as data, it must have a valid dimension, library name, and data type."
			return 0
		endif
	elseif(stringmatch(sS3Type,"Constant1"))
		if(strlen(sConstant1)==0)
			DoAlert/T="Bad inputs" 0, "To use magenta as Constant 1, there must be a number in the field."
			return 0
		endif
	elseif(stringmatch(sS3Type,"Constant2"))
		if(strlen(sConstant2)==0)
			DoAlert/T="Bad inputs" 0, "To use magenta as Constant 2, there must be a number in the field."
			return 0
		endif
	endif
	
	//check Dest
	if(stringmatch(sTableD,"Data"))
		if(stringmatch(sDLibrary," ")||stringmatch(sDataD," ")||stringmatch(sTableD,"4"))
			DoAlert/T="Incomplete Inputs" 0, "Green must have a valid dimension, library name, and data type."
			return 0
		endif
	elseif(stringmatch(sTableD,"Constant1"))
		DoAlert/T="Bad inputs" 0, "Why set the destination (green) to a constant?"
		return 0
	elseif(stringmatch(sTableD,"Constant2"))
		DoAlert/T="Bad inputs" 0, "Why set the destination (green) to a constant?"
		return 0
	endif
	
	
	//string vs numeric
	//if string Siftering
	if(whichListItem(sOperation,"Matches;Doesn't Match;Contains;Doesn't Contain")!=-1)
		if(stringmatch(sTable1,"1")||stringmatch(sTable1,"2")||stringmatch(sTable1,"3"))
			if(stringmatch(sTable2,"1")||stringmatch(sTable2,"2")||stringmatch(sTable2,"3"))
				DoAlert/T="Bad Sifter Inputs" 0, "String Sifter only works with constants or metadata."
				return 0
			endif
		endif
	endif
	
	//if numeric Siftering
	if(whichListItem(sOperation,">;>=;<=;<;!=;==")!=-1)
		if(stringmatch(sTable1,"0")||stringmatch(sTable1,"4"))
			if(stringmatch(sTable2,"0")||stringmatch(sTable2,"4"))
				DoAlert/T="Bad Sifter Inputs" 0, "Numeric Sifter only works with library, scalar, or vector data!"
				return 0
			endif
		endif
	endif
	
	return 1
	
End