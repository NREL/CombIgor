#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ May 2018 : Original


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//function to define Library space
function COMBI_DefineMappingGrid(sProject)
	string sProject // this project to define Library space for
	
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//Prompt values
	string sOptions
	prompt sOptions, "Library Type", POPUP, "Rows and Columns;Angle and Projection;Load .csv"
	
	//Prompt user
	DoPrompt "What Type of Mapping Grid?", sOptions
	if (V_Flag)
		return -1// User canceled
	endif
	
	//if rows and columns
	if(stringmatch(sOptions,"Rows and Columns"))
		//Make Wave to define
		SetDataFolder $"root:COMBIgor:"+sProject
		Make/O/N=(1,5) MappingGrid
		SetDimLabel 1,0, Sample,MappingGrid
		SetDimLabel 1,1, x_mm,MappingGrid
		SetDimLabel 1,2, y_mm,MappingGrid
		SetDimLabel 1,3, Row,MappingGrid
		SetDimLabel 1,4, Column,MappingGrid
		SetDataFolder $sTheCurrentUserFolder 
		COMBI_RowsAndColumns(sProject)
	endif
	
	//if rows and columns
	if(stringmatch(sOptions,"Angle and Projection"))
		//Make Wave to define
		SetDataFolder $"root:COMBIgor:"+sProject
		Make/O/N=(1,5) MappingGrid
		SetDimLabel 1,0, Sample,MappingGrid
		SetDimLabel 1,1, x_mm,MappingGrid
		SetDimLabel 1,2, y_mm,MappingGrid
		SetDimLabel 1,3, Angle,MappingGrid
		SetDimLabel 1,4, Radius,MappingGrid
		SetDataFolder $sTheCurrentUserFolder 
		COMBI_AngleAndProjection(sProject)
	endif
	
	//if load
	if(stringmatch(sOptions,"Load .csv"))
		COMBI_LoadProjectDefinition(sProject)
	endif
	
end

function COMBI_LoadProjectDefinition(sProject)
	string sProject // The COMBIgor Project
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	DoAlert/T="Loading Project Definition",1,"If desired, load a Library Space .csv with one row per sample and columns: Sample Index, x(mm), y(mm), Grid Axis 1, Grid Axis 2."
	if(V_flag!=1)
		return -1
	endif
	LoadWave/O/Q/J/W/A
	string sWaveNames = S_waveNames
	int iWave, iSample
	if(V_Flag!=5)
		DoAlert/T="Not the right type of wave.",0,"Please select a csv with 5 columns: Sample Index, x(mm), y(mm), Grid Axis 1, Grid Axis 2." 
		for(iWave=0;iWave<V_Flag;iWave+=1)
			Killwaves $"root:"+stringfromlist(iWave,sWaveNames)
		endfor
		return-1
	else
		//Make Wave to define
		SetDataFolder $"root:COMBIgor:"+sProject
		Make/O/N=(1,5) MappingGrid
		SetDataFolder $sTheCurrentUserFolder 
		wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
		for(iWave=0;iWave<5;iWave+=1)
			wave wMappingGridIn = $"root:"+stringfromlist(iWave,sWaveNames)
			redimension/N=(dimsize(wMappingGridIn,0),-1) wMappingGrid
			SetDimLabel 1,iWave, $stringfromlist(iWave,sWaveNames),wMappingGrid
			wMappingGrid[][iWave] = wMappingGridIn[p]
			Killwaves $"root:"+stringfromlist(iWave,sWaveNames)
		endfor
	endif
	DoAlert/T="Loading Project Definition",1,"If desired, load a Globals .csv with 2 columns: Global Name, Global Value"
	if(V_flag==3)
		return -1
	endif
	LoadWave/O/Q/J/W/A/K=2
	sWaveNames = S_waveNames
	if(V_Flag!=2)
		DoAlert/T="Not the right type of wave.",0,"Please select a csv with 2 columns: Global Name, Global Value" 
		for(iWave=0;iWave<V_Flag;iWave+=1)
			Killwaves $"root:"+stringfromlist(iWave,sWaveNames)
		endfor
		return-1
	else
		wave/T wGlobalsIn = $"root:"+stringfromlist(0,sWaveNames)
		wave/T wGlobalValuesIn = $"root:"+stringfromlist(1,sWaveNames)
		for(iWave=0;iWave<dimSize(wGlobalsIn,0);iWave+=1)
			COMBI_GiveGlobal(wGlobalsIn[iWave],wGlobalValuesIn[iWave],sProject)
		endfor
		KillWaves wGlobalsIn, wGlobalValuesIn
	endif
	KillStrings/Z root:S_fileName, root:S_path, root:S_waveNames
	Killvariables/Z root:V_Flag
	
	//redim the meta wave
	wave/T wMeta = $"root:COMBIgor:"+sProject+":Data:"+"Meta"
	redimension/N=(-1,COMBI_GetGlobalNumber("vTotalSamples",sProject),-1) wMeta
	
	//add to scalar data
	COMBI_AddLibraryToScalar(sProject,"FromMappingGrid")
	
	//add Sample labels
	for(iSample=0;iSample<dimsize(wMappingGrid,0);iSample+=1)
		setdimlabel 0, iSample, $"P"+num2str(1+iSample), wMappingGrid
	endfor
	
	//make Library Sample plot
	Display/K=1 wMappingGrid[][2]/TN=LibrarySamples vs wMappingGrid[][1]
	ModifyGraph zColor(LibrarySamples)={wMappingGrid[*][0],1,(dimsize(wMappingGrid,0)),Rainbow,0}
	ModifyGraph mirror=2
	ModifyGraph width=215,height=215
	ModifyGraph lsize=2
	ModifyGraph lstyle=7
	Label left "y (mm)"
	Label bottom "x (mm)"
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph msize=5
	ModifyGraph useMrkStrokeRGB=1
	ModifyGraph margin(right)=100
	ColorScale/C/N=text0/F=0/A=MC trace=LibrarySamples,axisRange={1,(dimsize(wMappingGrid,0))}
	ColorScale/C/N=text0 "Samples"
	ColorScale/C/N=text0/Z=1/X=75.00/Y=2.00
end


// defines Library space as the orthogonal grid
function COMBI_RowsAndColumns(sProject)
	string sProject // The COMBIgor Project

	//get Library Space Wave
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	wave/T wMeta = $"root:COMBIgor:"+sProject+":Data:"+"Meta"
	wave wLibrary = $"root:COMBIgor:"+sProject+":Data:"+"Library"
	
	//set sub categories
	SetDimLabel 1,3,Row,wMappingGrid
	SetDimLabel 1,4,Column,wMappingGrid
	
	//Prompt values
	variable vRows = 4// number of rows total
	variable vColumns = 11// number of columns
	variable vLibraryWidth = 50.8// width of Library in mm
	variable vLibraryHeight = 50.8// height of Library
	variable vRowSpacing = 12.5 // spacing of rows
	variable vColumnSpacing = 4 // spacing of columns
	string sOrigin = "Top Left" // origin location
	
	//user prompts
	prompt vRows, "Number of Rows"
	prompt vColumns, "Number of Columns"
	prompt vLibraryWidth, "Library Width (mm)"
	prompt vLibraryHeight, "Library Height (mm)"
	prompt vRowSpacing, "Row Spacing (mm)"
	prompt vColumnSpacing, "Column Spacing (mm)"
	prompt sOrigin, "Origin", POPUP, "Top Left;Top Right;Bottom Left;Bottom Right;Center"
	
	//Prompt user
	DoPrompt "Define the Library space?",vLibraryWidth,vLibraryHeight,vRows,vColumns,vRowSpacing,vColumnSpacing,sOrigin
	if (V_Flag)
		return -1// User canceled
	endif
	
	//store as globals
	COMBI_GiveGlobal("vTotalRows",num2str(vRows),sProject)
	COMBI_GiveGlobal("vTotalColumns",num2str(vColumns),sProject)
	COMBI_GiveGlobal("vLibraryWidth",num2str(vLibraryWidth),sProject)
	COMBI_GiveGlobal("vLibraryHeight",num2str(vLibraryHeight),sProject)
	COMBI_GiveGlobal("vRowSpacing",num2str(vRowSpacing),sProject)
	COMBI_GiveGlobal("vColumnSpacing",num2str(vColumnSpacing),sProject)
	COMBI_GiveGlobal("sOrigin",sOrigin,sProject)
	
	//offset for origin
	variable vXOffset
	variable vYOffset
	variable bYAxisFlip, bXAxisFlip
	strswitch(sOrigin)
		case "Top Left":
			vXOffset = 0
			vYOffset = 0
			bYAxisFlip = 1
			bXAxisFlip	= 0
			break
		case "Top Right":
			vXOffset = 0
			vYOffset = 0
			bYAxisFlip = 1
			bXAxisFlip	= 1
			break
		case "Bottom Left":
			vXOffset = 0
			vYOffset = 0
			bYAxisFlip = 0
			bXAxisFlip	= 0
			break
		case "Bottom Right":
			vXOffset = 0
			vYOffset = 0
			bYAxisFlip = 0
			bXAxisFlip	= 1
			break
		case "Center":
			vXOffset = -vLibraryHeight/2
			vYOffset = -vLibraryHeight/2
			bYAxisFlip = 0
			bXAxisFlip	= 0
			break
		default:
			break
	endswitch
	//store axis flip status
	COMBI_GiveGlobal("bXAxisFlip",num2str(bXAxisFlip),sProject)
	COMBI_GiveGlobal("bYAxisFlip",num2str(bYAxisFlip),sProject)
	
	//plot min max
	variable vMinY, vMaxY, vMinX, vMaxX
	if(bYAxisFlip==1)
		vMinY = vLibraryHeight+vYOffset
		vMaxY =  0+vYOffset
	else
		vMinY = 0+vYOffset
		vMaxY = vLibraryHeight+vYOffset
	endif
	if(bXAxisFlip==1)
		vMinX = vLibraryWidth+vXOffset
		vMaxX = 0+vXOffset
	else
		vMinX = 0+vXOffset
		vMaxX = vLibraryWidth+vXOffset
	endif


	//Math
	variable vTotalSamples = vRows*vColumns
	COMBI_GiveGlobal("vTotalSamples",num2str(vTotalSamples),sProject)
	variable vCenter_x = vLibraryWidth/2
	variable vCenter_y = vLibraryHeight/2
	
	//make waves correct number of Samples
	redimension/N=(vTotalSamples,-1) wMappingGrid
	redimension/N=(-1,vTotalSamples,-1) wMeta
	wMeta[][][]=""
	redimension/N=(-1,-1) wLibrary
	wLibrary[][]=nan

	
	//Write Things to Library Space
	variable iRow,iColumn,iSample
	for(iRow=0;iRow<vRows;iRow+=1)
		for(iColumn=0;iColumn<vColumns;iColumn+=1)
			iSample = iColumn+iRow*vColumns
			wMappingGrid[iSample][0] = iSample+1
			wMappingGrid[iSample][3] = iRow+1
			wMappingGrid[iSample][4] = iColumn+1
			// x = center - half the columns + this column
			wMappingGrid[iSample][1] = vCenter_x-((vColumns-1)/2*vColumnSpacing)+(iColumn*vColumnSpacing)+vXOffset
			// y = center - half of the rows + this row
			wMappingGrid[iSample][2] = vCenter_y-((vRows-1)/2*vRowSpacing)+(iRow*vRowSpacing)+vYOffset
		endfor
	endfor
	
	//add to scalar wave
	COMBI_AddLibraryToScalar(sProject,"FromMappingGrid")
	
	//add Sample labels
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		setdimlabel 0, iSample, $"P"+num2str(1+iSample), wMappingGrid
		setdimlabel 1, iSample, $"P"+num2str(1+iSample), wMeta
	endfor
	
	//make Library Sample plot
	COMBIDisplay_Map(sProject,"FromMappingGrid","Sample","Linear","Rainbow","","Linear","y(mm) vs x(mm)","Raw Data","Markers","*,*,*,*",19,"000000")
	
end

// defines Library space as the radial grid
function COMBI_AngleAndProjection(sProject)
	string sProject // The COMBIgor Project

	//get Library Space Wave
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	wave/T wMeta = $"root:COMBIgor:"+sProject+":Data:"+"Meta"
	wave wLibrary = $"root:COMBIgor:"+sProject+":Data:"+"Library"
	
	//set sub categories
	SetDimLabel 1,3,Angle,wMappingGrid
	SetDimLabel 1,4,Radius,wMappingGrid
	
	//Prompt values
	variable vAngleDelta = 12// degree between angle steps
	variable vRadiusDelta = 10// mm between projection lengths
	variable vLibraryDiameter = 100// diameter of Library in mm
	variable vTotalRings = 5//number of rings surrounding center Sample
	string sOrigin = "Top Center" // origin location
	string sDirection = "Clockwise" // origin location
	string sAngleOrigin = "Center"
	
	//user prompts
	prompt vAngleDelta, "Degrees between Angles(factor of 360):"
	prompt vRadiusDelta, "Millimeters between rings:"
	prompt vTotalRings, "Number of rings:"
	prompt vLibraryDiameter, "Library Width (mm)"
	prompt sOrigin, "(0,0) origin:", POPUP, "Top Left;Top Center;Top Right;Center Left;Center;Center Right;Bottom Left;Bottom Center;Bottom Right"
	prompt sAngleOrigin, "Zero Degree:", POPUP, "Top Center;Bottom Center;Center Left;Center Right;"
	prompt sDirection, "Rotation Direction:", POPUP, "Clockwise;Counter-clockswise"
	
	//Prompt user
	DoPrompt "Define the Library space?",vAngleDelta,vRadiusDelta,vTotalRings,vLibraryDiameter,sOrigin,sAngleOrigin,sDirection
	if (V_Flag)
		return -1// User canceled
	endif
	
	//check angle
	if(mod(360,vAngleDelta)!=0)
		DoAlert/T="COMBIgor error" 0,"Degrees between Angles should be a factor of 360."
		return -1
	endif
	
	//store as globals
	COMBI_GiveGlobal("vAngleDelta",num2str(vAngleDelta),sProject)
	COMBI_GiveGlobal("vRadiusDelta",num2str(vRadiusDelta),sProject)
	COMBI_GiveGlobal("vLibraryDiameter",num2str(vLibraryDiameter),sProject)
	COMBI_GiveGlobal("vTotalRings",num2str(vTotalRings),sProject)
	COMBI_GiveGlobal("sAngleOrigin",sAngleOrigin,sProject)
	COMBI_GiveGlobal("sOrigin",sOrigin,sProject)
	COMBI_GiveGlobal("sDirection",sDirection,sProject)

	//Number of Samples math
	variable vTotalAngles = (360/vAngleDelta)
	variable vTotalSamples = 1+vTotalAngles*vTotalRings
	COMBI_GiveGlobal("vTotalSamples",num2str(vTotalSamples),sProject)
	
	//origin math
	variable vRadius = vLibraryDiameter/2
	variable vYoffset, vXoffset
	variable vCenter_x = 0
	variable vCenter_y = 0
	variable bXAxisFlip = 0
	variable bYAxisFlip = 0
	if(stringmatch(sOrigin,"Top Left"))
		vXoffset = vRadius
		vYoffset = vRadius
		bYAxisFlip = 1
	elseif(stringmatch(sOrigin,"Top Center"))
		vXoffset = 0
		vYoffset = vRadius
		bYAxisFlip = 1
	elseif(stringmatch(sOrigin,"Top Right"))
		vXoffset = vRadius
		vYoffset = vRadius
		bYAxisFlip = 1
		bXAxisFlip = 1
	elseif(stringmatch(sOrigin,"Center Left"))
		vXoffset = vRadius
		vYoffset = 0
	elseif(stringmatch(sOrigin,"Center"))
		vXoffset = 0
		vYoffset = 0
	elseif(stringmatch(sOrigin,"Center Right"))
		vXoffset = vRadius
		vYoffset = 0
		bXAxisFlip = 1
	elseif(stringmatch(sOrigin,"Bottom Left"))
		vXoffset = vRadius
		vYoffset = vRadius
	elseif(stringmatch(sOrigin,"Bottom Center"))
		vXoffset = 0
		vYoffset = vRadius
	elseif(stringmatch(sOrigin,"Bottom Right"))
		vXoffset = vRadius
		vYoffset = vRadius
		bXAxisFlip=1
	endif
	//store axis flip status
	COMBI_GiveGlobal("bXAxisFlip",num2str(bXAxisFlip),sProject)
	COMBI_GiveGlobal("bYAxisFlip",num2str(bYAxisFlip),sProject)

	//make waves correct number of Samples
	redimension/N=(vTotalSamples,-1) wMappingGrid
	redimension/N=(-1,vTotalSamples,-1) wMeta
	wMeta[][][]=""
	redimension/N=(-1,-1) wLibrary
	wLibrary[][][]=nan
	
	//for origin
	variable vOriginOffset = 0
	if(stringmatch(sAngleOrigin,"Top Center"))
		if(bYAxisFlip==1)
			vOriginOffset = pi
		else
			vOriginOffset = 0
		endif
	elseif(stringmatch(sAngleOrigin,"Bottom Center"))
		if(bYAxisFlip==1)
			vOriginOffset = 0
		else
			vOriginOffset = pi
		endif
	elseif(stringmatch(sAngleOrigin,"Center Left"))
		if(bXAxisFlip==1)
			vOriginOffset = (pi/2)
		else
			vOriginOffset = (-pi/2)
		endif
	elseif(stringmatch(sAngleOrigin,"Center Right"))
		if(bXAxisFlip==1)
			vOriginOffset = (-pi/2)
		else
			vOriginOffset = (pi/2)
		endif
	endif
	
	//for direction
	variable vDirectionFactor
	if(bXAxisFlip==1)
		if(bYAxisFlip==1)
			vDirectionFactor = 1
		else
			vDirectionFactor = -1
		endif
	else
		if(bYAxisFlip==1)
			vDirectionFactor = -1
		else
			vDirectionFactor = 1
		endif 
	endif
	
	if(stringmatch(sDirection,"Counter-clockswise"))
		vDirectionFactor = -1*vDirectionFactor
	endif
	
	//plot min max
	variable vMinY, vMaxY, vMinX, vMaxX
	if(bYAxisFlip==1)
		vMinY = vRadius+vYoffset
		vMaxY =  -vRadius+vYoffset
	else
		vMinY = -vRadius+vYoffset
		vMaxY = vRadius+vYoffset
	endif
	if(bXAxisFlip==1)
		vMinX = vRadius+vXoffset
		vMaxX = -vRadius+vXoffset
	else
		vMinX = -vRadius+vXoffset
		vMaxX = vRadius+vXoffset
	endif
	
	//Write Things to Library Space
	variable iAngle,iRing,iSample
	variable vAngle,vProjection
	wMappingGrid[0][0] = iSample+1
	wMappingGrid[0][1] = vCenter_x+vXoffset
	wMappingGrid[0][2] = vCenter_y+vYoffset
	wMappingGrid[0][3] = 0
	wMappingGrid[0][4] = 0
	for(iAngle=0;iAngle<vTotalAngles;iAngle+=1)
		for(iRing=0;iRing<vTotalRings;iRing+=1)
			iSample = iAngle+iRing*vTotalAngles+1
			if(iSample==1)
			endif
			vAngle = vOriginOffset+(vDirectionFactor*iAngle*(2*pi/vTotalAngles))
			vProjection = (1+iRing)*vRadiusDelta
			wMappingGrid[iSample][0] = iSample+1
			wMappingGrid[iSample][3] = vAngle-vOriginOffset
			wMappingGrid[iSample][4] = vProjection
			// x = center - half the columns + this column
			wMappingGrid[iSample][1] = vCenter_x+(vProjection*Sin(vAngle))+vXoffset
			// y = center - half of the rows + this row
			wMappingGrid[iSample][2] = vCenter_y+(vProjection*Cos(vAngle))+vYoffset
		endfor
	endfor
	
	//add to scalar wave
	COMBI_AddLibraryToScalar(sProject,"All")
	
	//add Sample labels
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		setdimlabel 0, iSample, $"P"+num2str(1+iSample), wMappingGrid
		setdimlabel 1, iSample, $"P"+num2str(1+iSample), wMeta
	endfor
	
	//make Library Sample plot
	Display/K=1 wMappingGrid[][2]/TN=LibrarySamples vs wMappingGrid[][1]
	ModifyGraph zColor(LibrarySamples)={wMappingGrid[*][0],1,vTotalSamples,Rainbow,0}
	SetAxis left vMinY,vMaxY
	SetAxis bottom vMinX,vMaxX
	ModifyGraph mirror=2
	ModifyGraph width=360,height=360
	ModifyGraph lsize=2
	ModifyGraph lstyle=7
	Label left "y (mm)"
	Label bottom "x (mm)"
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph msize=5
	ModifyGraph useMrkStrokeRGB=1
	ModifyGraph margin(right)=100
	ColorScale/C/N=text0/F=0/A=MC trace=LibrarySamples,axisRange={1,vTotalSamples}
	ColorScale/C/N=text0 "Samples"
	ColorScale/C/N=text0/Z=1/X=65.00/Y=2.00
	
end

//function to add library space values to main scalar wave
function COMBI_AddLibraryToScalar(sProject,sLibraries)
	string sProject // the project to operate on
	string sLibraries // the library to add to
	//get the library space wave
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	string sDataTypes=GetDimLabel(wMappingGrid,1,0)+";"+GetDimLabel(wMappingGrid,1,1)+";"+GetDimLabel(wMappingGrid,1,2)+";"+GetDimLabel(wMappingGrid,1,3)+";"+GetDimLabel(wMappingGrid,1,4)
	COMBI_GiveData(wMappingGrid,sProject,sLibraries,sDataTypes,-1,1)
	
end

//function to return possible Library qualifers from Library space wave
function/S COMBI_LibraryQualifiers(sProject,vQualifierNumber)
	string sProject //COMBIgor Project
	variable vQualifierNumber //Index of column in MappingGrid 0 = Samples, 1 for x, 2 for y, 3=GA1, 4=GA2, -1 for a list of all types
	
	//get Library space wave
	wave/Z wSSpace = $"root:COMBIgor:"+sProject+":MappingGrid"
	
	string sAllTypes = ""
	if(vQualifierNumber==-1)
		sAllTypes+=GetDimLabel(wSSpace,1,0)+";"
		sAllTypes+=GetDimLabel(wSSpace,1,1)+";"
		sAllTypes+=GetDimLabel(wSSpace,1,2)+";"
		sAllTypes+=GetDimLabel(wSSpace,1,3)+";"
		sAllTypes+=GetDimLabel(wSSpace,1,4)+";"
		return sAllTypes
	endif
	
	//get all different values as you move up in Sample number
	variable iSample
	string sQualiferList = ""
	for(iSample=0;iSample<dimsize(wSSpace,0);iSample+=1)
		string sThisQualifier = num2str(wSSpace[iSample][vQualifierNumber])
		if(FindListItem(sThisQualifier,sQualiferList)<0)
			sQualiferList=AddListItem(sThisQualifier,sQualiferList,";",inf)
		endif
	endfor
	
	//return list of qualifiers
	return sQualiferList
	
end

//add SampleID
function COMBI_AddSampleID2Library(sProject,sLibrary)
	string sProject
	string sLibrary // all if ""
	wave wLibrary = $Combi_DataPath(sProject,0)
	string sFromMappingGrid
	if(stringmatch(sLibrary,""))
		sFromMappingGrid = Combi_TableList(sProject,-3,"All","Libraries")
	else
		sFromMappingGrid = sLibrary
	endif
	
	//meta wave
	wave wMappingGrid = $COMBI_DataPath(sProject,-2)
	string sGridAxis1 = GetDimLabel(wMappingGrid,1,3)
	string sGridAxis2 = GetDimLabel(wMappingGrid,1,4)
	
	int iSample,iLibrary
	for(iSample=0;iSample<Combi_GetGlobalNumber("vTotalSamples",sProject);iSample+=1)
		for(iLibrary=0;iLibrary<itemsinList(sFromMappingGrid);iLibrary+=1)
			string sTheLibrary = StringFromList(iLibrary,sFromMappingGrid)
			if(Combi_CheckForLibrary(sProject,sTheLibrary,-3))
				Combi_GiveMeta(sProject,"SampleID",sTheLibrary,sTheLibrary+"_S"+num2str(iSample+1),iSample)
				Combi_GiveMeta(sProject,"Sample",sTheLibrary,"S"+num2str(iSample+1),iSample)
				string sGridPosition = sGridAxis1+num2str(wMappingGrid[iSample][3])+"_"+sGridAxis2+num2str(wMappingGrid[iSample][4]) 
				Combi_GiveMeta(sProject,"MappingGridPosition",sTheLibrary,sGridPosition,iSample)
			endif
		endfor
	endfor
end