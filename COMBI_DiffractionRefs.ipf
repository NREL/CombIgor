#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ Sept 2018 : Original DiffractionRef 
// V1.01: Karen Heinselman _ Oct 2018 : Polishing and debugging
// V2: Kevin Talley _ Jan 2020 : revamp with added functionality
///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Notes Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Profiles go in a single folder root:COMBIgor:DiffractionRefs, are 2D, and and have 4 columns 
	//Column 0 = 2theta,
	//Column 1 = Q
	//Column 2 = Intensity
	//Column 3 = NormalizedIntensity
//Peak list go into another root:COMBIgor:DiffractionRefs and are 2D waves with 7 columns
	//Column 0 = Peak number
	//Column 1 = h
	//Column 2 = k
	//Column 3 = l
	//Column 4 = d
	//Column 5 = 2T
	//Column 6 = Q
	//Column 7 = Int
	//column 8 = Frac max int
	//column 9 = multiplicity

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Name of Plugin
Static StrConstant sPluginName = "DiffractionRefs"
static strconstant sSoftwareTypes = "CrystalDiffract;Vesta;ICSD"
static strconstant sFileTypes = "Profile;Peaks"
static strconstant sAllAxisTypes = "TwoTheta;Q;Intensity;Fraction of Max Intensity"
static Constant iOutsidePlotSize = 100
static strConstant sDifRefPanel = "DiffractionRefPanel"
static strConstant sMarkers2Use = "29;26;23;19;15;14;58;60;62;28;25;22;8;4;3;57;59;61"

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Menu "COMBIgor"
	SubMenu "Plugins"
		Submenu "Diffraction References"
			"Main Panel",/Q, DiffractionRefs_MainPanel()
			"-"
			"(Loading"
			Submenu "Profiles"
				"(Source:"
				"ICSD",/Q, DiffractionRefs_ICSD_LoadProfile()
				"CrystalDiffract",/Q, DiffractionRefs_CD_LoadProfile()
				"Vesta",/Q, DiffractionRefs_Vesta_LoadProfile()
			end
			Submenu "Reflection List"
				"(Source:"
				"ICSD",/Q, DiffractionRefs_ICSD_LoadReflections()
				"CrystalDiffract",/Q, DiffractionRefs_CD_LoadReflections()
				"Vesta",/Q, DiffractionRefs_Vesta_LoadReflections()
			end
			//Submenu "Folder of Refs"
			//	"Profiles",/Q, DiffractionRefs_FolderOfProfiles()
			//	"Peaks",/Q, DiffractionRefs_FolderOfReflections()
			//	"Folders of Both", /Q, DiffractionRefs_FolderOfRefs()
			//end
		end
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Data Importing Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//for cleaning up a peak list where peaks exist at same dspacings
function DiffractionRefs_CleanPeakList(sRef)
	string sRef
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sRef+":"+sRef+"_Peaks"
	int iTotalPeaks = dimsize(wRef,0)
	Make/O/T/N=(iTotalPeaks,8)  $"root:COMBIgor:DiffractionRefs:"+sRef+":"+sRef+"_Peaks_Simplified"
	wave/T wSimplified = $"root:COMBIgor:DiffractionRefs:"+sRef+":"+sRef+"_Peaks_Simplified"
	setdimlabel 1,0,PeakNumber,wSimplified
	setdimlabel 1,1,HKLList,wSimplified
	setdimlabel 1,2,d_Ang,wSimplified
	setdimlabel 1,3,TwoTheta,wSimplified
	setdimlabel 1,4,Q_2PiPerAng,wSimplified
	setdimlabel 1,5,Intensity,wSimplified
	setdimlabel 1,6,FracMaxIntensity,wSimplified
	setdimlabel 1,7,PeakMultiplicity,wSimplified
		
	int iPeak = 0
	int iSimpPeak = 0
	variable vThisd
	variable vMaxInt = -inf
	for(iPeak=0;iPeak<iTotalPeaks;iPeak+=1)
		//skip if int is zero
		if(wRef[iPeak][%Intensity]<=0)
			continue
		endif
		if(iSimpPeak==0)
				wSimplified[iSimpPeak][%PeakNumber] = Num2str(wRef[iPeak][%PeakNumber])
				wSimplified[iSimpPeak][%HKLList] = "("+Num2str(wRef[iPeak][%h_index])+Num2str(wRef[iPeak][%k_index])+Num2str(wRef[iPeak][%l_index])+")"
				wSimplified[iSimpPeak][%d_Ang] = Num2str(wRef[iPeak][%d_Ang])
				wSimplified[iSimpPeak][%TwoTheta] = Num2str(wRef[iPeak][%TwoTheta])
				wSimplified[iSimpPeak][%Q_2PiPerAng] = Num2str(wRef[iPeak][%Q_2PiPerAng])
				wSimplified[iSimpPeak][%Intensity] = Num2str(wRef[iPeak][%Intensity])
				wSimplified[iSimpPeak][%PeakMultiplicity] = Num2str(wRef[iPeak][%PeakMultiplicity])
				iSimpPeak+=1
		else
			if(stringmatch(num2str(wRef[iPeak][%d_Ang]),wSimplified[iSimpPeak-1][%d_Ang]))
				//add, same d
				wSimplified[iSimpPeak-1][%PeakNumber] = wSimplified[iSimpPeak-1][%PeakNumber]+","+Num2str(wRef[iPeak][%PeakNumber])
				wSimplified[iSimpPeak-1][%HKLList] = wSimplified[iSimpPeak-1][%HKLList]+",("+Num2str(wRef[iPeak][%h_index])+Num2str(wRef[iPeak][%k_index])+Num2str(wRef[iPeak][%l_index])+")"
				wSimplified[iSimpPeak-1][%Intensity] = num2str(str2num(wSimplified[iSimpPeak-1][%Intensity])+wRef[iPeak][%Intensity])
				wSimplified[iSimpPeak-1][%PeakMultiplicity] = num2str(str2num(wSimplified[iSimpPeak-1][%PeakMultiplicity])+wRef[iPeak][%PeakMultiplicity])
			else
				//new peak, new d
				wSimplified[iSimpPeak][%PeakNumber] = Num2str(wRef[iPeak][%PeakNumber])
				wSimplified[iSimpPeak][%HKLList] = "("+Num2str(wRef[iPeak][%h_index])+Num2str(wRef[iPeak][%k_index])+Num2str(wRef[iPeak][%l_index])+")"
				wSimplified[iSimpPeak][%d_Ang] = Num2str(wRef[iPeak][%d_Ang])
				wSimplified[iSimpPeak][%TwoTheta] = Num2str(wRef[iPeak][%TwoTheta])
				wSimplified[iSimpPeak][%Q_2PiPerAng] = Num2str(wRef[iPeak][%Q_2PiPerAng])
				wSimplified[iSimpPeak][%Intensity] = Num2str(wRef[iPeak][%Intensity])
				wSimplified[iSimpPeak][%PeakMultiplicity] = Num2str(wRef[iPeak][%PeakMultiplicity])
				iSimpPeak+=1
			endif
		endif
		
	endfor
	redimension/N=(iSimpPeak,-1) wSimplified
	
	//frac of max
	for(iPeak=0;iPeak<iSimpPeak;iPeak+=1)
		vMaxInt = max(vMaxInt,str2num(wSimplified[iPeak][%Intensity]))
	endfor
		for(iPeak=0;iPeak<iSimpPeak;iPeak+=1)
		wSimplified[iPeak][%FracMaxIntensity] = num2str(str2num(wSimplified[iPeak][%Intensity])/vMaxInt)
	endfor
	
	//get min and max values of ref data
	wave wForIntStats = newfreeWave(4,iSimpPeak)
	wForIntStats[] = str2num(wSimplified[p][%Intensity])
	variable/G $"root:COMBIgor:DiffractionRefs:"+sRef+":vIntMax" = wavemax(wForIntStats)	
	
	wave wForTTStats = newfreeWave(4,iSimpPeak)
	wForTTStats[] = str2num(wSimplified[p][%TwoTheta])
	variable/G $"root:COMBIgor:DiffractionRefs:"+sRef+":vTTMax" = wavemax(wForTTStats)
	variable/G $"root:COMBIgor:DiffractionRefs:"+sRef+":vTTMin" = wavemin(wForTTStats)
	
	wave wForQStats = newfreeWave(4,iSimpPeak)
	wForQStats[] = str2num(wSimplified[p][%Q_2PiPerAng])
	variable/G $"root:COMBIgor:DiffractionRefs:"+sRef+":vQMax" = wavemax(wForQStats)
	variable/G $"root:COMBIgor:DiffractionRefs:"+sRef+":vQMin" = wavemin(wForQStats)
	
	//wave for tag refs
	Make/O/N=(iSimpPeak,6)  $"root:COMBIgor:DiffractionRefs:"+sRef+":"+sRef+"_Tags"
	wave wTags = $"root:COMBIgor:DiffractionRefs:"+sRef+":"+sRef+"_Tags"
	setdimlabel 1,0,TwoTheta,wTags
	setdimlabel 1,1,Q_2PiPerAng,wTags
	setdimlabel 1,2,FracMaxIntensity,wTags
	setdimlabel 1,3,Intensity,wTags
	setdimlabel 1,4,Unit,wTags
	setdimlabel 1,5,Zero,wTags
	wTags[][%TwoTheta] = str2num(wSimplified[p][%TwoTheta])
	wTags[][%Q_2PiPerAng] = str2num(wSimplified[p][%Q_2PiPerAng])
	wTags[][%Unit] = 1
	wTags[][%Zero] = 0
	wTags[][%Intensity] = str2num(wSimplified[p][%Intensity])
	wTags[][%FracMaxIntensity] = str2num(wSimplified[p][%FracMaxIntensity])

end

//load a Vesta profile output file, returns "CANCEL" if cancelled in the process.
Function/S DiffractionRefs_Vesta_LoadProfile([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//go to profile folder 
	setdatafolder root:COMBIgor
	NewDataFolder/O/S DiffractionRefs
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load data
	LoadWave/G/M/Q/O/N=LoadedProfile
	if(strlen(S_fileName)==0)
		return "CANCEL"
	endif
	string sLoadedName = removeending(S_fileName,".int")
	string sLoadedFile = S_path+S_filename
	string sLoadedWave = stringfromlist(0,S_waveNames)
	wave wLoadedIn = $"root:COMBIgor:DiffractionRefs:"+sLoadedWave
	killStrings/Z S_waveNames,S_path,S_fileName
	killvariables/Z V_Flag
	
	//name data
	if(paramIsDefault(sName))
		sName = COMBI_StringPrompt(sLoadedName,"Name:","","This is what the refrence will be stored and retrieved as.","Name of this refrence.")
		sName = CleanupName(sName,0)
		if(stringmatch(sName,"CANCEL"))
			return "CANCEL"
		endif
	endif
	
	//wavelength of 2theta
	variable vWavelength = 1.54059
	vWavelength = COMBI_NumberPrompt(vWavelength,"2Theta wavelength (Ang)","This is used to convert from 2Theta to Q","Wavelength?")
	if(numtype(vWavelength)==2)
		return "CANCEL"
	endif
	
	//add end folder and final wave
	NewDataFolder/O/S $sName
	Make/O/D/N=(dimsize(wLoadedIn,0),4) $sName+"_Profile"
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sName+":"+sName+"_Profile"
	setdimLabel 1,0,TwoTheta,wRef
	setdimLabel 1,1,Q_2PiPerAng,wRef
	setdimLabel 1,2,Intensity,wRef
	setdimLabel 1,3,FracMaxIntensity,wRef
	note wRef,"DiffractionRefs;Profile;Vesta;File:"+sLoadedFile
	wRef = nan
	setdatafolder root: 
	
	//add from loaded to final
	wRef[][0] = wLoadedIn[p][0] //2Theta
	wRef[][1] = 4*Pi*Sin(wLoadedIn[p][0]/2/180*pi)/vWavelength
	wRef[][2] = wLoadedIn[p][1] //Int.
	deletePoints/M=1 0,1,wLoadedIn
	deletePoints/M=1 1,1,wLoadedIn
	wRef[][3] = wLoadedIn[p][0]/wavemax(wLoadedIn) //Norm Int.
	
	//remove zero
	int iRow,iCol
	for(iRow=0;iRow<dimsize(wRef,0);iRow+=1)
		for(iCol=0;iCol<dimsize(wRef,1);iCol+=1)
			if(wRef[iRow][iCol]==0)
				wRef[iRow][iCol]=nan
			endif
		endfor
	endfor
	
	//kill the laoded wave
	killwaves wLoadedIn
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
	//return the name of the ref
	return sName
end

//load a Vesta table of relfections output file
Function/S DiffractionRefs_Vesta_LoadReflections([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//go to profile folder 
	setdatafolder root:COMBIgor
	NewDataFolder/O/S DiffractionRefs
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load data
	LoadWave/G/M/Q/O/N=LoadedPeaks/L={0,1,0,0,0}//load file
	if(strlen(S_fileName)==0)
		return "CANCEL"
	endif
	string sLoadedName = removeending(S_fileName,".txt")
	string sLoadedFile = S_path+S_filename
	string sLoadedWave = stringfromlist(0,S_waveNames)
	wave wLoadedIn = $"root:COMBIgor:DiffractionRefs:"+sLoadedWave
	killStrings/Z S_waveNames,S_path,S_fileName
	killvariables/Z V_Flag
	
	//name data
	if(paramIsDefault(sName))
		sName = COMBI_StringPrompt(sLoadedName,"Name:","","This is what the refrence will be stored and retrieved as.","Name of this refrence.")
		sName = CleanupName(sName,0)
		if(stringmatch(sName,"CANCEL"))
			return "CANCEL"
		endif
	endif
	
	//add end folder and final wave
	NewDataFolder/O/S $sName
	Make/O/D/N=(dimsize(wLoadedIn,0),10) $sName+"_Peaks"
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sName+":"+sName+"_Peaks"
	setdimLabel 1,0,PeakNumber,wRef
	setdimLabel 1,1,h_index,wRef
	setdimLabel 1,2,k_index,wRef
	setdimLabel 1,3,l_index,wRef
	setdimLabel 1,4,d_Ang,wRef
	setdimLabel 1,5,TwoTheta,wRef
	setdimLabel 1,6,Q_2PiPerAng,wRef
	setdimLabel 1,7,Intensity,wRef
	setdimLabel 1,8,FracMaxIntensity,wRef
	setdimLabel 1,9,PeakMultiplicity,wRef
	note wRef,"DiffractionRefs;Peaks;Vesta;File:"+sLoadedFile
	wRef = nan
	setdatafolder root: 
	
	//add from loaded to final
	wRef[][0] = p+1//Column 0 = Peak number
	wRef[][1] = wLoadedIn[p][0] //Column 1 = h
	wRef[][2] = wLoadedIn[p][1] //Column 2 = k
	wRef[][3] = wLoadedIn[p][2] //Column 3 = l
	wRef[][4] = wLoadedIn[p][3] //Column 4 = d
	wRef[][5] = wLoadedIn[p][7] //Column 5 = 2T
	wRef[][6] = 2*pi/wLoadedIn[p][3] //Column 6 = Q
	wRef[][7] = wLoadedIn[p][8] //Column 7 = Int
	wRef[][9] = wLoadedIn[p][9] //column 9 = multiplicity
	deletePoints/M=1 0,8,wLoadedIn
	deletePoints/M=1 1,3,wLoadedIn
	wRef[][8] = wLoadedIn[p][0]/wavemax(wLoadedIn) //column 8 = Frac max int
	
	//setdimLabel, per peak
	int iPeak
	for(iPeak=0;iPeak<dimsize(wRef,0);iPeak+=1)
		string sPeakLabel = "("+num2str(wRef[iPeak][1])+num2str(wRef[iPeak][2])+num2str(wRef[iPeak][3])+")"
		SetDimLabel 0,iPeak,$sPeakLabel,wRef
	endfor
	
	//kill the laoded wave
	killwaves wLoadedIn
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
	
	//make a simlified list of peaks
	DiffractionRefs_CleanPeakList(sName)
	
	//return the name of the ref
	return sName
end

//load a ICSD profile output file
Function/S DiffractionRefs_ICSD_LoadProfile([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//go to profile folder 
	setdatafolder root:COMBIgor
	NewDataFolder/O/S DiffractionRefs
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load data
	LoadWave/G/M/Q/O/N=LoadedProfile
	if(strlen(S_fileName)==0)
		return "CANCEL"
	endif
	string sLoadedName = removeending(S_fileName,".csv")
	string sLoadedFile = S_path+S_filename
	string sLoadedWave = stringfromlist(0,S_waveNames)
	wave wLoadedIn = $"root:COMBIgor:DiffractionRefs:"+sLoadedWave
	killStrings/Z S_waveNames,S_path,S_fileName
	killvariables/Z V_Flag
	
	//name data
	if(paramIsDefault(sName))
		sName = COMBI_StringPrompt(sLoadedName,"Name:","","This is what the refrence will be stored and retrieved as.","Name of this refrence.")
		sName = CleanupName(sName,0)
		if(stringmatch(sName,"CANCEL"))
			return "CANCEL"
		endif
	endif
	
	//wavelength of 2theta
	variable vWavelength = 1.54059
	vWavelength = COMBI_NumberPrompt(vWavelength,"2Theta wavelength (Ang)","This is used to convert from 2Theta to Q","Wavelength?")
	if(numtype(vWavelength)==2)
		return "CANCEL"
	endif
	
	//add end folder and final wave
	NewDataFolder/O/S $sName
	Make/O/D/N=(dimsize(wLoadedIn,0),4) $sName+"_Profile"
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sName+":"+sName+"_Profile"
	setdimLabel 1,0,TwoTheta,wRef
	setdimLabel 1,1,Q_2PiPerAng,wRef
	setdimLabel 1,2,Intensity,wRef
	setdimLabel 1,3,FracMaxIntensity,wRef
	note wRef,"DiffractionRefs;Profile;ICSD;File:"+sLoadedFile
	wRef = nan
	setdatafolder root: 
	
	//add from loaded to final
	wRef[][0] = wLoadedIn[p][0] //2Theta
	wRef[][1] = 4*Pi*Sin(wLoadedIn[p][0]/2/180*pi)/vWavelength//Q
	wRef[][2] = wLoadedIn[p][1] //Int.
	deletePoints/M=1 0,1,wLoadedIn
	wRef[][3] = wLoadedIn[p][0]/wavemax(wLoadedIn) //Norm Int.
	
	//remove zero
	int iRow,iCol
	for(iRow=0;iRow<dimsize(wRef,0);iRow+=1)
		for(iCol=0;iCol<dimsize(wRef,1);iCol+=1)
			if(wRef[iRow][iCol]==0)
				wRef[iRow][iCol]=nan
			endif
		endfor
	endfor
	
	//kill the laoded wave
	killwaves wLoadedIn
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
	//return the name of the ref
	return sName
end

//load a ICSD table of relfections output file
Function/S DiffractionRefs_ICSD_LoadReflections([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//go to profile folder 
	setdatafolder root:COMBIgor
	NewDataFolder/O/S DiffractionRefs
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load data
	LoadWave/G/M/Q/O/N=LoadedPeaks/L={0,1,0,0,0}//load file
	if(strlen(S_fileName)==0)
		return "CANCEL"
	endif
	string sLoadedName = removeending(S_fileName,".csv")
	string sLoadedFile = S_path+S_filename
	string sLoadedWave = stringfromlist(0,S_waveNames)
	wave wLoadedIn = $"root:COMBIgor:DiffractionRefs:"+sLoadedWave
	killStrings/Z S_waveNames,S_path,S_fileName
	killvariables/Z V_Flag
	
	//name data
	if(paramIsDefault(sName))
		sName = COMBI_StringPrompt(sLoadedName,"Name:","","This is what the refrence will be stored and retrieved as.","Name of this refrence.")
		sName = CleanupName(sName,0)
		if(stringmatch(sName,"CANCEL"))
			return "CANCEL"
		endif
	endif
	
	//add end folder and final wave
	NewDataFolder/O/S $sName
	Make/O/D/N=(dimsize(wLoadedIn,0),10) $sName+"_Peaks"
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sName+":"+sName+"_Peaks"
	setdimLabel 1,0,PeakNumber,wRef
	setdimLabel 1,1,h_index,wRef
	setdimLabel 1,2,k_index,wRef
	setdimLabel 1,3,l_index,wRef
	setdimLabel 1,4,d_Ang,wRef
	setdimLabel 1,5,TwoTheta,wRef
	setdimLabel 1,6,Q_2PiPerAng,wRef
	setdimLabel 1,7,Intensity,wRef
	setdimLabel 1,8,FracMaxIntensity,wRef
	setdimLabel 1,9,PeakMultiplicity,wRef
	note wRef,"DiffractionRefs;Peaks;ICSD;File:"+sLoadedFile
	wRef = nan
	setdatafolder root: 
	
	//add from loaded to final
	wRef[][0] = p+1//Column 0 = Peak number
	wRef[][1] = wLoadedIn[p][0] //Column 1 = h
	wRef[][2] = wLoadedIn[p][1] //Column 2 = k
	wRef[][3] = wLoadedIn[p][2] //Column 3 = l
	wRef[][4] = wLoadedIn[p][4] //Column 4 = d
	wRef[][5] = wLoadedIn[p][3] //Column 5 = 2T
	wRef[][6] = 2*pi/wLoadedIn[p][4] //Column 6 = Q
	wRef[][7] = wLoadedIn[p][6] //Column 7 = Int
	wRef[][9] = wLoadedIn[p][5] //column 9 = multiplicity
	deletePoints/M=1 0,6,wLoadedIn
	wRef[][8] = wLoadedIn[p][0]/wavemax(wLoadedIn) //column 8 = Frac max int
	
	//setdimLabel, per peak
	int iPeak
	for(iPeak=0;iPeak<dimsize(wRef,0);iPeak+=1)
		string sPeakLabel = "("+num2str(wRef[iPeak][1])+num2str(wRef[iPeak][2])+num2str(wRef[iPeak][3])+")"
		SetDimLabel 0,iPeak,$sPeakLabel,wRef
	endfor
	
	//kill the laoded wave
	killwaves wLoadedIn
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
	//make a simlified list of peaks
	DiffractionRefs_CleanPeakList(sName)
	return sName
end

//load a crystaldiffact table of relfections output file
Function/S DiffractionRefs_CD_LoadReflections([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//go to profile folder 
	setdatafolder root:COMBIgor
	NewDataFolder/O/S DiffractionRefs
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load data
	variable vFileRef
	Open/R/T=".txt" vFileRef
	if(strlen(S_fileName)==0)
		return "CANCEL"
	endif
	string sOpened=S_fileName
	int vFolderInPath = itemsinlist(sOpened,":")
	string sFilename = stringfromlist(vFolderInPath-1,sOpened,":")
	string sPath = removeEnding(sOpened,sFilename)
	string sLoadedName = removeending(sFilename,".txt")
	string sLoadedFile = sPath+sFilename
	
	//name data
	if(paramIsDefault(sName))
		sName = COMBI_StringPrompt(sLoadedName,"Name:","","This is what the refrence will be stored and retrieved as.","Name of this refrence.")
		sName = CleanupName(sName,0)
		if(stringmatch(sName,"CANCEL"))
			return "CANCEL"
		endif
	endif
	
	//Read to string
	string sThisLine = PadString("",inf,4)
	FReadLine/T="" vFileRef, sThisLine
	Close vFileRef
	
	//parse each line, add to string list
	int iFirstDataLine = 431
	int iRowLength = 74
	int iRow = 0
	string sThisRow
	string sH=""
	string sK=""
	string sL=""
	string sdhkl=""
	string sTwTheta=""
	string sPercentMaxInt=""
	string sMulti = ""
	string sInt = ""
	//loop each line
	do
		int iFirstChar = iFirstDataLine+iRow*iRowLength
		int iLastChar = iFirstChar+iRowLength
		sThisRow = sThisLine[iFirstChar,iLastChar-2]
		sH = AddListItem(sThisRow[0,2],sH,";",inf)
		sK = AddListItem(sThisRow[4,6],sK,";",inf)
		sL = AddListItem(sThisRow[8,10],sL,";",inf)
		sdhkl = AddListItem(num2str(str2num(sThisRow[14,20])),sdhkl,";",inf)
		sTwTheta = AddListItem(num2str(str2num(sThisRow[23,30])),sTwTheta,";",inf)
		sInt = AddListItem(num2str(str2num(sThisRow[34,44])),sInt,";",inf)
		sPercentMaxInt = AddListItem(num2str(str2num(sThisRow[47,51])),sPercentMaxInt,";",inf)
		sMulti = AddListItem(num2str(str2num(sThisRow[55,56])),sMulti,";",inf)
		iRow+=1
	while(iLastChar<strlen(sThisLine))
	
	//add end folder and final wave
	NewDataFolder/O/S $sName
	Make/O/D/N=(iRow-1,10) $sName+"_Peaks"
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sName+":"+sName+"_Peaks"
	setdimLabel 1,0,PeakNumber,wRef
	setdimLabel 1,1,h_index,wRef
	setdimLabel 1,2,k_index,wRef
	setdimLabel 1,3,l_index,wRef
	setdimLabel 1,4,d_Ang,wRef
	setdimLabel 1,5,TwoTheta,wRef
	setdimLabel 1,6,Q_2PiPerAng,wRef
	setdimLabel 1,7,Intensity,wRef
	setdimLabel 1,8,FracMaxIntensity,wRef
	setdimLabel 1,9,PeakMultiplicity,wRef
	note wRef,"DiffractionRefs;Peaks;CrystalDiffract;File:"+sLoadedFile
	wRef = nan
	setdatafolder root: 
	
	//add from loaded to final	
	for(iRow=0;iRow<itemsinlist(sH)-1;iRow+=1)
		wRef[iRow][0] = irow+1//Column 0 = Peak number
		wRef[iRow][1] = str2num(stringfromlist(iRow,sH)) //Column 1 = h
		wRef[iRow][2] = str2num(stringfromlist(iRow,sK)) //Column 2 = k
		wRef[iRow][3] = str2num(stringfromlist(iRow,sL)) //Column 3 = l
		wRef[iRow][4] = str2num(stringfromlist(iRow,sdhkl))//Column 4 = d
		wRef[iRow][5] = str2num(stringfromlist(iRow,sTwTheta))//Column 5 = 2T
		wRef[iRow][6] = 2*pi/wRef[iRow][4] //Column 6 = Q
		wRef[iRow][7] = str2num(stringfromlist(iRow,sInt))//Column 7 = Int
		wRef[iRow][9] = str2num(stringfromlist(iRow,sMulti))//column 9 = multiplicity
		wRef[iRow][8] = str2num(stringfromlist(iRow,sPercentMaxInt))/100//column 8 = Frac max int
	endfor

	//setdimLabel, per peak
	int iPeak
	for(iPeak=0;iPeak<dimsize(wRef,0);iPeak+=1)
		string sPeakLabel = "("+num2str(wRef[iPeak][1])+num2str(wRef[iPeak][2])+num2str(wRef[iPeak][3])+")"
		SetDimLabel 0,iPeak,$sPeakLabel,wRef
	endfor
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
	
	//make a simlified list of peaks
	DiffractionRefs_CleanPeakList(sName)
	
	//return the name of the ref
	return sName
end

//load a crystaldiffact profile output file
Function/S DiffractionRefs_CD_LoadProfile([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//go to profile folder 
	setdatafolder root:COMBIgor
	NewDataFolder/O/S DiffractionRefs
	
	//direct next dialog towards import path if import option is on.
	string sLoadPath = COMBI_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = COMBI_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
	endif
	
	//load data
	LoadWave/G/M/Q/O/N=LoadedProfile
	if(strlen(S_fileName)==0)
		return "CANCEL"
	endif
	string sLoadedName = removeending(S_fileName,".csv")
	string sLoadedFile = S_path+S_filename
	string sLoadedWave = stringfromlist(0,S_waveNames)
	wave wLoadedIn = $"root:COMBIgor:DiffractionRefs:"+sLoadedWave
	killStrings/Z S_waveNames,S_path,S_fileName
	killvariables/Z V_Flag
	
	//name data
	if(paramIsDefault(sName))
		sName = COMBI_StringPrompt(sLoadedName,"Name:","","This is what the refrence will be stored and retrieved as.","Name of this refrence.")
		sName = CleanupName(sName,0)
		if(stringmatch(sName,"CANCEL"))
			return "CANCEL"
		endif
	endif
	
	//wavelength of 2theta
	variable vWavelength = 1.54059
	vWavelength = COMBI_NumberPrompt(vWavelength,"2Theta wavelength (Ang)","This is used to convert from 2Theta to Q","Wavelength?")
	if(numtype(vWavelength)==2)
		return "CANCEL"
	endif
	
	//add end folder and final wave
	NewDataFolder/O/S $sName
	Make/O/D/N=(dimsize(wLoadedIn,0),4) $sName+"_Profile"
	wave wRef = $"root:COMBIgor:DiffractionRefs:"+sName+":"+sName+"_Profile"
	setdimLabel 1,0,TwoTheta,wRef
	setdimLabel 1,1,Q_2PiPerAng,wRef
	setdimLabel 1,2,Intensity,wRef
	setdimLabel 1,3,FracMaxIntensity,wRef
	note wRef,"DiffractionRefs;Profile;CrystalDiffract;File:"+sLoadedFile
	wRef = nan
	setdatafolder root: 
	
	//add from loaded to final
	wRef[][0] = wLoadedIn[p][0] //2Theta
	wRef[][1] = 4*Pi*Sin(wLoadedIn[p][0]/2/180*pi)/vWavelength//Q
	wRef[][2] = wLoadedIn[p][1] //Int.
	deletePoints/M=1 0,1,wLoadedIn
	wRef[][3] = wLoadedIn[p][0]/wavemax(wLoadedIn) //Norm Int.
	
	//remove zero
	int iRow,iCol
	for(iRow=0;iRow<dimsize(wRef,0);iRow+=1)
		for(iCol=0;iCol<dimsize(wRef,1);iCol+=1)
			if(wRef[iRow][iCol]==0)
				wRef[iRow][iCol]=nan
			endif
		endfor
	endfor
	
	//kill the laoded wave
	killwaves wLoadedIn
	
	//return to user folder
	SetDataFolder $sTheCurrentUserFolder
	//return the name of the ref
	return sName
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------General Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//interprets the inputs on the panel and stores the needed plotting inofrmation
function DiffractionRefs_TranslateInputs()

	//window to operate on
	string sName = ""
	string sTopGraphName = COMBI_GetPluginString(sPluginName,"sTopGraphName","COMBIgor")
	if(whichListItem(sTopGraphName,winlist("*",";","WIN:1"))!=-1)
		sName = GetUserData(sTopGraphName,"","RefInfo")
	else
		sTopGraphName = ""
	endif
	
	//which folder to translate?
	string sGlobalFolder = ""
	if(strlen(sName)>0)
		sGlobalFolder = sName
	else
		sGlobalFolder = "COMBIgor"
	endif
	
	//needed variables	
	string sRefType,sRefMode,sRefPosition,sDegAxis,sIntAxis,sDegPosition,sIntPosition,sIntLog
	sRefType = COMBI_GetPluginString(sPluginName,"sRefType",sGlobalFolder)
	sRefMode = COMBI_GetPluginString(sPluginName,"sRefMode",sGlobalFolder)
	sRefPosition = COMBI_GetPluginString(sPluginName,"sRefPosition",sGlobalFolder)	
	sDegAxis = COMBI_GetPluginString(sPluginName,"sDegAxis",sGlobalFolder)
	sIntAxis = COMBI_GetPluginString(sPluginName,"sIntAxis",sGlobalFolder)
	sDegPosition = COMBI_GetPluginString(sPluginName,"sDegPosition",sGlobalFolder)
	sIntPosition = COMBI_GetPluginString(sPluginName,"sIntPosition",sGlobalFolder)
	sIntLog = COMBI_GetPluginString(sPluginName,"sIntLog",sGlobalFolder)	
	
	//varaibles to store
	string sHozDataLabel = ""
	string sVertDataLabel = ""
	string sHozLocation = ""
	string sVertLocation = ""
	string sHozLabel = ""
	string sVertLabel = ""
	string sHozAxisTag = ""
	string sVertAxisTag = ""
	int bIntLog = 0
	string sIntTag
	string sDegTag
	
	//Int
	string sIntDataLabel
	string sIntLabel
	if(stringmatch(sIntAxis,"Fraction of Max"))
		sIntLabel = "Fraction of Max Intensity"
		sIntDataLabel = "FracMaxIntensity"
	elseif(stringmatch(sIntAxis,"Intensity"))
		sIntLabel = "Intensity (a.u)"
		sIntDataLabel = "Intensity"
	endif
	
	//Deg
	string sDegLabel
	string sDegDataLabel
	if(stringmatch(sDegAxis,"Q"))
		sDegDataLabel = "Q_2PiPerAng"
		sDegLabel = "Q (2π/Å)"
	elseif(stringmatch(sDegAxis,"TwoTheta"))
		sDegDataLabel = "TwoTheta"
		sDegLabel = "Diffraction Angle (deg.)"
	endif
	
	//log int?
	if(stringmatch(sIntLog,"Log"))
		bIntLog = 1
	else
		bIntLog = 0
	endif
	
	//translate 
	if(stringmatch(sDegPosition,"left"))
		sVertDataLabel = sDegDataLabel
		sVertLocation = sDegPosition
		sVertLabel = sDegLabel
		sVertAxisTag = "L"
		sDegTag = sVertAxisTag
	elseif(stringmatch(sDegPosition,"right"))
		sVertDataLabel = sDegDataLabel
		sVertLocation = sDegPosition
		sVertLabel = sDegLabel
		sVertAxisTag = "R"		
		sDegTag = sVertAxisTag
	elseif(stringmatch(sDegPosition,"top"))
		sHozDataLabel = sDegDataLabel
		sHozLocation = sDegPosition
		sHozLabel = sDegLabel
		sHozAxisTag = "T"
		sDegTag = sHozAxisTag
	elseif(stringmatch(sDegPosition,"bottom"))
		sHozDataLabel = sDegDataLabel
		sHozLocation = sDegPosition
		sHozLabel = sDegLabel
		sHozAxisTag = "B"
		sDegTag = sHozAxisTag
	endif
	
	
	//Int Location
	if(stringmatch(sIntPosition,"left"))
		sVertDataLabel = sIntDataLabel
		sVertLocation = sIntPosition
		sVertLabel = sIntLabel
		sVertAxisTag = "L"
		sIntTag = sVertAxisTag
	elseif(stringmatch(sIntPosition,"right"))
		sVertDataLabel = sIntDataLabel
		sVertLocation = sIntPosition
		sVertLabel = sIntLabel
		sVertAxisTag = "R"
		sIntTag = sVertAxisTag
	elseif(stringmatch(sIntPosition,"top"))
		sHozDataLabel = sIntDataLabel
		sHozLocation = sIntPosition
		sHozLabel = sIntLabel
		sHozAxisTag = "T"
		sIntTag = sHozAxisTag
	elseif(stringmatch(sIntPosition,"bottom"))
		sHozDataLabel = sIntDataLabel
		sHozLocation = sIntPosition
		sHozLabel = sIntLabel
		sHozAxisTag = "B"
		sIntTag = sHozAxisTag
	endif
	
	//store 
	COMBI_GivePluginGlobal(sPluginName,"sHozDataLabel",sHozDataLabel,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sHozLocation",sHozLocation,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sHozLabel",sHozLabel,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sHozAxisTag",sHozAxisTag,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sVertDataLabel",sVertDataLabel,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sVertLocation",sVertLocation,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sVertLabel",sVertLabel,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sVertAxisTag",sVertAxisTag,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"bIntLog",num2str(bIntLog),sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sIntTag",sIntTag,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sDegTag",sDegTag,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sDegDataLabel",sDegDataLabel,sGlobalFolder)
	COMBI_GivePluginGlobal(sPluginName,"sIntDataLabel",sIntDataLabel,sGlobalFolder)
	
	
	//graph info
	string sAxisFlag = ""
	if(strlen(sName)>0)
		//things about this top graph
		GetAxis /W=$sTopGraphName/Q top
		if(V_flag==0)
			COMBI_GivePluginGlobal(sPluginName,"bGT",num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGT_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGT_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bGT_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"top"),"=",";"),sGlobalFolder)
		else
			COMBI_GivePluginGlobal(sPluginName,"bGT",num2str(0),sGlobalFolder)
		endif
		GetAxis /W=$sTopGraphName/Q bottom
		if(V_flag==0)
			COMBI_GivePluginGlobal(sPluginName,"bGB",num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGB_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGB_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bGB_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"bottom"),"=",";"),sGlobalFolder)
		else
			COMBI_GivePluginGlobal(sPluginName,"bGB",num2str(0),sGlobalFolder)
		endif
		GetAxis /W=$sTopGraphName/Q left
		if(V_flag==0)
			COMBI_GivePluginGlobal(sPluginName,"bGL",num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGL_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGL_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bGL_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"left"),"=",";"),sGlobalFolder)
		else
			COMBI_GivePluginGlobal(sPluginName,"bGL",num2str(0),sGlobalFolder)
		endif
		GetAxis /W=$sTopGraphName/Q right
		if(V_flag==0)
			COMBI_GivePluginGlobal(sPluginName,"bGR",num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGR_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vGR_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bGR_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"right"),"=",";"),sGlobalFolder)
		else
			COMBI_GivePluginGlobal(sPluginName,"bGR",num2str(0),sGlobalFolder)
		endif
		
		GetAxis /W=$sTopGraphName/Q TwoTheta
		if(V_flag==0)
			sAxisFlag = COMBI_GetPluginString(sPluginName,"sDegTag",sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag,num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag+"_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"TwoTheta"),"=",";"),sGlobalFolder)
			if(stringmatch(sAxisFlag,"L"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","TwoTheta",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"R"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","TwoTheta",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"T"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","TwoTheta",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"B"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","TwoTheta",sGlobalFolder)
			endif
		endif
		GetAxis /W=$sTopGraphName/Q Q_2PiPerAng
		if(V_flag==0)
			sAxisFlag = COMBI_GetPluginString(sPluginName,"sDegTag",sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag,num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag+"_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"Q_2PiPerAng"),"=",";"),sGlobalFolder)
			if(stringmatch(sAxisFlag,"L"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","Q_2PiPerAng",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"R"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","Q_2PiPerAng",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"T"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","Q_2PiPerAng",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"B"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","Q_2PiPerAng",sGlobalFolder)
			endif
		endif
		GetAxis /W=$sTopGraphName/Q Intensity
		if(V_flag==0)
			sAxisFlag = COMBI_GetPluginString(sPluginName,"sIntTag",sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag,num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag+"_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"Intensity"),"=",";"),sGlobalFolder)
			if(stringmatch(sAxisFlag,"L"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","Intensity",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"R"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","Intensity",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"T"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","Intensity",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"B"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","Intensity",sGlobalFolder)
			endif
		endif
		GetAxis /W=$sTopGraphName/Q FracMaxIntensity
		if(V_flag==0)
			sAxisFlag = COMBI_GetPluginString(sPluginName,"sIntTag",sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag,num2str(1),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Max",num2str(V_max),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"vG"+sAxisFlag+"_Min",num2str(V_min),sGlobalFolder)
			COMBI_GivePluginGlobal(sPluginName,"bG"+sAxisFlag+"_Log",StringByKey("log(x)",AxisInfo(sTopGraphName,"FracMaxIntensity"),"=",";"),sGlobalFolder)
			if(stringmatch(sAxisFlag,"L"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","FracMaxIntensity",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"R"))
				COMBI_GivePluginGlobal(sPluginName,"sVertLocation","FracMaxIntensity",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"T"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","FracMaxIntensity",sGlobalFolder)
			elseif(stringmatch(sAxisFlag,"B"))
				COMBI_GivePluginGlobal(sPluginName,"sHozLocation","FracMaxIntensity",sGlobalFolder)
			endif
		endif
		
		GetWindow $sTopGraphName gsize //window dimensions into V_left, V_right, V_top, and V_bottom in points from the top left of the screen.
		COMBI_GivePluginGlobal(sPluginName,"iGL",num2str(V_left),sGlobalFolder)//graph left location
		COMBI_GivePluginGlobal(sPluginName,"iGR", num2str(V_right),sGlobalFolder)//graph right location
		COMBI_GivePluginGlobal(sPluginName,"iWinWidth",num2str(V_right),sGlobalFolder)//pixels across window
		COMBI_GivePluginGlobal(sPluginName,"iGT", num2str(V_top),sGlobalFolder)//graph top location
		COMBI_GivePluginGlobal(sPluginName,"iGB", num2str(V_bottom),sGlobalFolder)//graph bottom location
		COMBI_GivePluginGlobal(sPluginName,"iWinHeight", num2str(V_bottom),sGlobalFolder)//pixels across window
		GetWindow $sTopGraphName wsize //window dimensions into V_left, V_right, V_top, and V_bottom in points from the top left of the screen.
		COMBI_GivePluginGlobal(sPluginName,"iWL", num2str(V_left),sGlobalFolder)//window left location
		COMBI_GivePluginGlobal(sPluginName,"iWR", num2str(V_right),sGlobalFolder)//window right location
		COMBI_GivePluginGlobal(sPluginName,"iWT", num2str(V_top),sGlobalFolder)//window top location
		COMBI_GivePluginGlobal(sPluginName,"iWB", num2str(V_bottom),sGlobalFolder)//window bottom location
		GetWindow $sTopGraphName psize //window dimensions into V_left, V_right, V_top, and V_bottom in points from the top left of the screen.
		COMBI_GivePluginGlobal(sPluginName,"iPL", num2str(V_left),sGlobalFolder)//window left location
		COMBI_GivePluginGlobal(sPluginName,"iPR", num2str(V_right),sGlobalFolder)//window right location
		COMBI_GivePluginGlobal(sPluginName,"iPT", num2str(V_top),sGlobalFolder)//window top location
		COMBI_GivePluginGlobal(sPluginName,"iPB", num2str(V_bottom),sGlobalFolder)//window bottom location
		COMBI_GivePluginGlobal(sPluginName,"iPlotWidth", num2str(V_right-V_left),sGlobalFolder)//pixels across plot
		COMBI_GivePluginGlobal(sPluginName,"iPlotHeight", num2str(V_bottom-V_top),sGlobalFolder)//pixels across plot
	
	endif
	
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Plotting Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DiffractionRefs_ChangeProfileRefColor(sWindowName)
	string sWindowName
	string sName = GetUserData(sWindowName,"","RefInfo")
	if(strlen(sName)>0)
		string sRefsAdded = COMBI_GetPluginString(sPluginName,"sRefsAdded",sName)
		int iTotalRefsAdded = COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded",sName)
		string sRefType = COMBI_GetPluginString(sPluginName,"sRefType",sName)
		int iRef
		for(iRef=0;iRef<iTotalRefsAdded;iRef+=1)
			string sThisRef = stringfromlist(iRef,sRefsAdded)
			string sThisColor = COMBI_GetUniqueColor(iRef+1,iTotalRefsAdded)
			if(stringmatch(sRefType,"Profile"))
				Execute "ModifyGraph/W="+sWindowName+" rgb("+sThisRef+")="+sThisColor
			elseif(stringmatch(sRefType,"Peaks"))
			
			endif
		endfor
	endif
end

function DiffractionRefs_NewRefPlot(sRefType,sRefName)
	string sRefType// "Profile" or "Peaks"
	string sRefName// Name of the refrence 
	
	
	//trnaslate
	DiffractionRefs_TranslateInputs()
	
	string sLegendText
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	string sHozDataLabel = COMBI_GetPluginString(sPluginName,"sHozDataLabel","COMBIgor")
	string sVertDataLabel = COMBI_GetPluginString(sPluginName,"sVertDataLabel","COMBIgor")
	string sDegDataLabel = COMBI_GetPluginString(sPluginName,"sDegDataLabel","COMBIgor")
	string sIntDataLabel = COMBI_GetPluginString(sPluginName,"sIntDataLabel","COMBIgor")
	string sHozAxisTag = COMBI_GetPluginString(sPluginName,"sHozAxisTag","COMBIgor")
	string sVertAxisTag = COMBI_GetPluginString(sPluginName,"sVertAxisTag","COMBIgor")
	string sVertLabel = COMBI_GetPluginString(sPluginName,"sVertLabel","COMBIgor")
	string sHozLabel = COMBI_GetPluginString(sPluginName,"sHozLabel","COMBIgor")
	string sDegTag = COMBI_GetPluginString(sPluginName,"sDegTag","COMBIgor")
	string sIntTag = COMBI_GetPluginString(sPluginName,"sIntTag","COMBIgor")
	string sFlags = "/"+COMBI_GetPluginString(sPluginName,"sVertAxisTag","COMBIgor")+"/"+COMBI_GetPluginString(sPluginName,"sHozAxisTag","COMBIgor")
	string sWindowName = "DiffractionRef_"+sRefType+"_"+sRefName
	
	//get ref stats for axis min and max
	NVAR vTTMin = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vTTMin"
	NVAR vTTMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vTTMax"
	NVAR vQMin = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vQMin"
	NVAR vQMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vQMax"
	NVAR vIntMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vIntMax"
	variable vDegMin, vDegMax, vLocalIntMin = 0, vLocalIntMax = 1
	if(stringmatch(COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor"),"TwoTheta"))
		vDegMin = vTTMin
		vDegMax = vTTMax
	else
		vDegMin = vQMin
		vDegMax = vQMax
	endif
	if(stringmatch(COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),"Intensity"))
		vLocalIntMax = vIntMax
	endif
	if(COMBI_GetPluginNumber(sPluginName,"bIntLog","COMBIgor")==1)
		if(stringmatch(COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),"Intensity"))
			vLocalIntMin = vIntMax/1000
		else
			vLocalIntMin = .001
		endif
	endif
		
	//axis min and max, set
	variable vDegRange = vDegMax-vDegMin
	variable vIntRange = vLocalIntMax-vLocalIntMin
	
	if(stringmatch(sRefType,"Profile"))
		//get wave
		wave/Z wRefProfile = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile"
		if(!waveexists(wRefProfile))
			return 0
		endif
		//make plot
		sWindowName = COMBI_NewPlot(sWindowName)
		//append ref wave
		Execute "AppendToGraph/W="+sWindowName+sFlags+" root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile[][%"+sVertDataLabel+"]/TN="+sRefName+" vs root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile[][%"+sHozDataLabel+"]"
		Execute "ModifyGraph/W="+sWindowName+" mode("+sRefName+")=7,hbFill("+sRefName+")=2"
		if(COMBI_GetPluginNumber(sPluginName,"bIntLog","COMBIgor")==1)
			Execute "ModifyGraph log("+COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor")+")=1"
		endif
		//format int
		Execute "Label "+COMBI_GetPluginString(sPluginName,"sHozLocation","COMBIgor")+" \""+COMBI_GetPluginString(sPluginName,"sHozLabel","COMBIgor")+"\""
		Execute "Label "+COMBI_GetPluginString(sPluginName,"sVertLocation","COMBIgor")+" \""+COMBI_GetPluginString(sPluginName,"sVertLabel","COMBIgor")+"\""
		//legend
		sLegendText = "\\s("+sRefName+") "+sRefName
		Legend/C/N=Refs/J/F=0/A=RC sLegendText

		//set axis ranges
		if((0.1*vDegRange)>vDegMin)
			SetAxis bottom (0),(vDegMax+(0.1*vDegRange))
		else
			SetAxis bottom (vDegMin-(0.1*vDegRange)),(vDegMax+(0.1*vDegRange))
		endif
		if((0.1*vIntRange)>vLocalIntMin)
			SetAxis left vLocalIntMin,(vLocalIntMax+(0.15*vIntRange))
		else
			SetAxis left (vLocalIntMin-(0.1*vIntRange)),(vLocalIntMax+(0.1*vIntRange))
		endif

		//bring to front
		Dowindow/F $sWindowName	
		//label and attach ref panel
		DiffractionRefs_AddAPlot(sName=sWindowName)//start ref process
		COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sWindowName,"COMBIgor")//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sRefName+";",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded","1",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","Append",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sRefType","Profile",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sWindowName)
		//copy inputs from panel folder to the plot folder in globals
		COMBI_GivePluginGlobal(sPluginName,"sRefPosition",COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sDegAxis",COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sIntAxis",COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sDegPosition",COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sIntPosition",COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sIntLog",COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor"),sWindowName)
		//trnaslate
		DiffractionRefs_TranslateInputs()
		//reload
		DiffractionRefs_MainPanel()
		
	elseif(stringmatch(sRefType,"Peaks"))
		
		//get wave
		wave/Z/T wRefPeaks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Peaks_Simplified"
		if(!waveexists(wRefPeaks))
			return 0
		endif
		//make plot
		sWindowName = COMBI_NewPlot(sWindowName)
		DiffractionRefs_AddAPlot(sName=sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sWindowName,"COMBIgor")//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sRefName+";",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded","1",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","Append",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sRefType","Peaks",sWindowName)//attaches ref panel
		COMBI_GivePluginGlobal(sPluginName,"sLegendText","",sWindowName)
		//copy inputs from panel folder to the plot folder in globals
		COMBI_GivePluginGlobal(sPluginName,"sRefPosition",COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sDegAxis",COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sIntAxis",COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sDegPosition",COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sIntPosition",COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor"),sWindowName)
		COMBI_GivePluginGlobal(sPluginName,"sIntLog",COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor"),sWindowName)
		
		//reload
		DiffractionRefs_MainPanel()

		//add axes
		Execute "NewFreeAxis/"+sVertAxisTag+"/W="+sWindowName+" "+sVertDataLabel
		Execute "NewFreeAxis/"+sHozAxisTag+"/W="+sWindowName+" "+sHozDataLabel
		ModifyGraph freePos($sHozDataLabel)=0,freePos($sVertDataLabel)=0
		if(COMBI_GetPluginNumber(sPluginName,"bIntLog",sWindowName)==1)
			ModifyGraph log($COMBI_GetPluginString(sPluginName,"sIntDataLabel",sWindowName))=1
		endif
		
		//set axis ranges
		if((0.15*vDegRange)>vDegMin)
			SetAxis $sDegDataLabel (0),(vDegMax+(0.15*vDegRange))
		else
			SetAxis $sDegDataLabel (vDegMin-(0.15*vDegRange)),(vDegMax+(0.15*vDegRange))
		endif
		if((0.1*vIntRange)>vLocalIntMin)
			SetAxis $sIntDataLabel vLocalIntMin,(vLocalIntMax+(0.15*vIntRange))
		else
			SetAxis $sIntDataLabel (vLocalIntMin-(0.15*vIntRange)),(vLocalIntMax+(0.15*vIntRange))
		endif
		
		//labels
		ModifyGraph lblPosMode=1
		Execute "Label "+COMBI_GetPluginString(sPluginName,"sHozDataLabel","COMBIgor")+" \""+COMBI_GetPluginString(sPluginName,"sHozLabel","COMBIgor")+"\""
		Execute "Label "+COMBI_GetPluginString(sPluginName,"sVertDataLabel","COMBIgor")+" \""+COMBI_GetPluginString(sPluginName,"sVertLabel","COMBIgor")+"\""
		
		//color?
		string sColor = COMBI_GetUniqueColor(1,1)
		
		//Add Peaks draw environemetn
		SetDrawEnv/W=$sWindowName gstart,gname=$sRefName,save	
		SetDrawEnv/W=$sWindowName xcoord=$sHozDataLabel,save
		SetDrawEnv/W=$sWindowName ycoord=$sVertDataLabel,save
		SetDrawEnv/W=$sWindowName linethick= 2.00,save
		SetDrawEnv/W=$sWindowName fname=sFont,save
		Execute "SetDrawEnv/W="+sWindowName+" linefgc= "+sColor+",save"
		Execute "SetDrawEnv/W="+sWindowName+" textrgb= "+sColor+",save"
		
		//loop peaks to draw
		int iPeak	
		variable vY_Str,vY_End,vX_Str,vX_End
		for(iPeak=0;iPeak<dimsize(wRefPeaks,0);iPeak+=1)
			//skip?
			if(str2num(wRefPeaks[iPeak][%$sDegDataLabel])<vDegMin)
				continue
			endif
			if(str2num(wRefPeaks[iPeak][%$sDegDataLabel])>vDegMax)
				continue
			endif
			if(str2num(wRefPeaks[iPeak][%$sIntDataLabel])<vLocalIntMin)
				continue
			endif
			//draw
			if(stringmatch(sDegTag,"L")||stringmatch(sDegTag,"R"))
				vY_Str = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
				vY_End = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
			elseif(stringmatch(sDegTag,"T")||stringmatch(sDegTag,"B"))
				vX_Str = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
				vX_End = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
			endif
			if(stringmatch(sIntTag,"L")||stringmatch(sIntTag,"R"))
				vY_Str = vLocalIntMin
				vY_End = str2num(wRefPeaks[iPeak][%$sIntDataLabel])
			elseif(stringmatch(sIntTag,"T")||stringmatch(sIntTag,"B"))
				vX_Str = vLocalIntMin
				vX_End = str2num(wRefPeaks[iPeak][%$sIntDataLabel])
			endif
			DrawLine/W=$sWindowName vX_Str,vY_Str,vX_End,vY_End
		endfor
		SetDrawEnv/W=$sWindowName gstop,gname=$sRefName,save
		//legend
		sLegendText = "\\K"+sColor+" "+sRefName
		COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sWindowName)
		Legend/C/N=Refs/J/F=0/A=RC sLegendText
		
		//log?
		if(COMBI_GetPluginNumber(sPluginName,"bIntLog","COMBIgor")==1)
			Execute "ModifyGraph log("+sIntDataLabel+")=1"
		endif
		
		//bring to front
		Dowindow/F $sWindowName	
	endif
end

function DiffractionRefs_AppendRef(sRefType,sRefName,sName,iAddOrRemove)
	string sRefType// "Profile" or "Peaks"
	string sRefName// Name of the refrence 
	string sName// name to call for the folder in the plugin globals wave
	int iAddOrRemove //-1 to remove, 1 to add
	
	//if sName is not a window, abort
	if(strlen(sName)==0)
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","New","COMBIgor")
		return 0
	endif
	if(whichlistitem(sName,WinList("*",";","WIN:1"))==-1)
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","New","COMBIgor")
		return 0
	endif
	
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	DiffractionRefs_TranslateInputs()
	
	string sVertDataLabel = COMBI_GetPluginString(sPluginName,"sVertDataLabel",sName)
	string sVertLabel = COMBI_GetPluginString(sPluginName,"sVertLabel",sName)
	string sVertAxisTag = COMBI_GetPluginString(sPluginName,"sVertAxisTag",sName)
	string sVertLocation = COMBI_GetPluginString(sPluginName,"sVertLocation",sName)

	string sDegDataLabel = COMBI_GetPluginString(sPluginName,"sDegDataLabel",sName)
	string sDegPosition = COMBI_GetPluginString(sPluginName,"sDegPosition",sName)
	string sDegTag = COMBI_GetPluginString(sPluginName,"sDegTag",sName)
	string sDegAxis = COMBI_GetPluginString(sPluginName,"sDegAxis",sName)
	
	string sIntDataLabel = COMBI_GetPluginString(sPluginName,"sIntDataLabel",sName)
	string sIntPosition = COMBI_GetPluginString(sPluginName,"sIntPosition",sName)
	string sIntTag = COMBI_GetPluginString(sPluginName,"sIntTag",sName)
	string sIntAxis = COMBI_GetPluginString(sPluginName,"sIntAxis",sName)
	
	string sHozLabel = COMBI_GetPluginString(sPluginName,"sHozLabel",sName)
	string sHozDataLabel = COMBI_GetPluginString(sPluginName,"sHozDataLabel",sName)
	string sHozAxisTag= COMBI_GetPluginString(sPluginName,"sHozAxisTag",sName)
	string sHozLocation = COMBI_GetPluginString(sPluginName,"sHozLocation",sName)
	
	string sRefsAdded = COMBI_GetPluginString(sPluginName,"sRefsAdded",sName)
	int iTotalRefsAdded = COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded",sName)
	
	string sLegendText = ""
	int bNewIntAxis = 0
	int bNewDegAxis = 0
	
	//get ref stats for axis min and max
	NVAR vTTMin = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vTTMin"
	NVAR vTTMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vTTMax"
	NVAR vQMin = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vQMin"
	NVAR vQMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vQMax"
	NVAR vIntMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vIntMax"
	variable vDegMin, vDegMax, vLocalIntMin = 0.001, vLocalIntMax = 1
	if(stringmatch(sDegAxis,"TwoTheta"))
		vDegMin = vTTMin
		vDegMax = vTTMax
	else
		vDegMin = vQMin
		vDegMax = vQMax
	endif
	if(stringmatch(sIntAxis,"Intensity"))
		vLocalIntMax = vIntMax
	endif
	if(COMBI_GetPluginNumber(sPluginName,"bIntLog",sName)==1)
		if(stringmatch(sIntAxis,"Intensity"))
			vLocalIntMin = vIntMax/1000
		else
			vLocalIntMin = COMBI_GetPluginNumber(sPluginName,"vG"+sIntTag+"_Min",sName)
		endif
	endif
	variable vDegRange = vDegMax-vDegMin
	variable vIntRange = vLocalIntMax-vLocalIntMin
	
	if(stringmatch(sRefType,"Profile"))
		//get wave
		wave/Z wRefProfile = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile"
		if(!waveexists(wRefProfile))
			return 0
		endif
		
		string sFlags = "/"+sVertAxisTag+"/"+sHozAxisTag	
				
		if(iAddOrRemove==1)//append
			if(iTotalRefsAdded==1)//first added
				COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sName,"COMBIgor")//attaches ref panel
				COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sRefName+";",sName)
				COMBI_GivePluginGlobal(sPluginName,"iT otalRefsAdded","1",sName)
				COMBI_GivePluginGlobal(sPluginName,"sRefMode","Append",sName)
				COMBI_GivePluginGlobal(sPluginName,"sRefType","Profile",sName)
				COMBI_GivePluginGlobal(sPluginName,"sLegendText","",sName)
				//copy inputs from panel folder to the plot folder in globals
				COMBI_GivePluginGlobal(sPluginName,"sRefPosition",COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sDegAxis",COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sIntAxis",COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sDegPosition",COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sIntPosition",COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sIntLog",COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor"),sName)	
				//do the needed axes exist?, make if not
				if(COMBI_GetPluginNumber(sPluginName,"bG"+sIntTag,sName)==0)
					bNewIntAxis = 1
					if(stringmatch(sIntTag,"L"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation","left",sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sIntTag,"R"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation","right",sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sIntTag,"T"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation","top",sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					elseif(stringmatch(sIntTag,"B"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation","bottom",sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					endif
				endif
				if(COMBI_GetPluginNumber(sPluginName,"bG"+sDegTag,sName)==0)
					bNewDegAxis = 1
					if(stringmatch(sDegTag,"L"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation","left",sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sDegTag,"R"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation","right",sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sDegTag,"T"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation","top",sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					elseif(stringmatch(sDegTag,"B"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation","bottom",sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					endif
				endif	
				sHozLocation = COMBI_GetPluginString(sPluginName,"sHozLocation",sName)
				sVertLocation = COMBI_GetPluginString(sPluginName,"sVertLocation",sName)
			endif	
		
			if(itemsInList(TraceNameList(sName,";",1))==0)
				DiffractionRefs_NewRefPlot(sRefType,sRefName)
				return 0
			endif
			
			//is this the first in the legend?
			sLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sName)
			if(strlen(sLegendText)==0||stringmatch(sLegendText,"NAG")||stringmatch(sLegendText,"\r"))
				sLegendText = "\\s("+sRefName+") "+sRefName
			else
				sLegendText = sLegendText+"\r\\s("+sRefName+") "+sRefName
			endif
			//legend text
			Legend/C/N=Refs/J sLegendText
			COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sName)
		
			//append ref wave
			Execute "AppendToGraph/W="+sName+sFlags+" root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile[][%"+sVertDataLabel+"]/TN="+sRefName+" vs root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile[][%"+sHozDataLabel+"]"
			Execute "ModifyGraph/W="+sName+" mode("+sRefName+")=7,hbFill("+sRefName+")=2"
			
			//if the hor axis is new
			if(COMBI_GetPluginNumber(sPluginName,"bG"+sHozAxisTag,sName)==0)
				Execute "Label "+sHozLocation+" \""+sHozLabel+"\""
			endif
			
			//if the vert axis is new
			if(COMBI_GetPluginNumber(sPluginName,"bG"+sVertAxisTag,sName)==0)
				Execute "Label "+sVertLocation+" \""+sVertLabel+"\""
			endif
			
			//if intensity axis is new make log if need
			if(COMBI_GetPluginNumber(sPluginName,"bG"+sIntTag,sName)==0)
				if(COMBI_GetPluginNumber(sPluginName,"bIntLog","COMBIgor")==1)
					Execute "ModifyGraph log("+sIntPosition+")=1"
				endif
			endif
			
			//trnaslate
			DiffractionRefs_TranslateInputs()
			//reload
			DiffractionRefs_MainPanel()
			
			//mod new axes
			if(bNewDegAxis==1)
				if((0.15*vDegRange)>vDegMin)
					SetAxis $sDegPosition (0),(vDegMax+(0.15*vDegRange))
				else
					SetAxis $sDegPosition (vDegMin-(0.15*vDegRange)),(vDegMax+(0.15*vDegRange))
				endif
				Label/W=$sName $sDegPosition COMBI_GetPluginString(sPluginName,"sDegLabel",sName)
				ModifyGraph/W=$sName lblPosMode($sDegPosition)=1
			endif
			if(bNewIntAxis==1)
				if((0.1*vIntRange)>vLocalIntMin)
					SetAxis $sIntPosition vLocalIntMin,(vLocalIntMax+(0.15*vIntRange))
				else
					SetAxis $sIntPosition (vLocalIntMin-(0.15*vIntRange)),(vLocalIntMax+(0.15*vIntRange))
				endif
				Label/W=$sName $sIntPosition COMBI_GetPluginString(sPluginName,"sIntLabel",sName)
				ModifyGraph/W=$sName lblPosMode($sIntPosition)=1
			endif
			
		elseif(iAddOrRemove==-1)//remove
			if(whichlistitem(sRefName,TraceNameList(sName,";",1))==-1)
				//reload
				DiffractionRefs_MainPanel()
				return 0
			endif
			Execute "RemoveFromGraph/W="+sName+" "+sRefName
			//legend text
			sLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sName)
			sLegendText = RemoveFromList("\\s("+sRefName+") "+sRefName, sLegendText, "\r" )			
			Legend/C/N=Refs/J sLegendText
			COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sName)
		
			
		endif
		DiffractionRefs_ChangeProfileRefColor(sName)
		
	elseif(stringmatch(sRefType,"Peaks"))
		if(iAddOrRemove==1)//add
			if(iTotalRefsAdded==1)//first added
				COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sName,"COMBIgor")//attaches ref panel
				COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sRefName+";",sName)
				COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded","1",sName)
				COMBI_GivePluginGlobal(sPluginName,"sRefMode","Append",sName)
				COMBI_GivePluginGlobal(sPluginName,"sRefType","Peaks",sName)
				COMBI_GivePluginGlobal(sPluginName,"sLegendText","",sName)
				//copy inputs from panel folder to the plot folder in globals
				COMBI_GivePluginGlobal(sPluginName,"sRefPosition",COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sDegAxis",COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sIntAxis",COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sDegPosition",COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sIntPosition",COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor"),sName)
				COMBI_GivePluginGlobal(sPluginName,"sIntLog",COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor"),sName)	
				//do the needed axes exist?, make if not
				if(COMBI_GetPluginNumber(sPluginName,"bG"+sIntTag,sName)==0)
					bNewIntAxis = 1
					Execute "NewFreeAxis/"+sIntTag+"/W="+sName+" "+sIntDataLabel
					ModifyGraph freePos($sIntDataLabel)=0
					if(COMBI_GetPluginNumber(sPluginName,"bIntLog",sName)==1)
						ModifyGraph log($sIntDataLabel)=1
					endif
					if(stringmatch(sIntTag,"L"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation",sIntDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sIntTag,"R"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation",sIntDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sIntTag,"T"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation",sIntDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					elseif(stringmatch(sIntTag,"B"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation",sIntDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sIntLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					endif
				endif		
				if(COMBI_GetPluginNumber(sPluginName,"bG"+sDegTag,sName)==0)
					bNewDegAxis = 1
					Execute "NewFreeAxis/"+sDegTag+"/W="+sName+" "+sDegDataLabel
					ModifyGraph freePos($sDegDataLabel)=0
					if(stringmatch(sDegTag,"L"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation",sDegDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sDegTag,"R"))
						COMBI_GivePluginGlobal(sPluginName,"sVertLocation",sDegDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sVertLabel",sName),sName)
					elseif(stringmatch(sDegTag,"T"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation",sDegDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					elseif(stringmatch(sDegTag,"B"))
						COMBI_GivePluginGlobal(sPluginName,"sHozLocation",sDegDataLabel,sName)
						COMBI_GivePluginGlobal(sPluginName,"sDegLabel",COMBI_GetPluginString(sPluginName,"sHozLabel",sName),sName)
					endif
				endif	
				sHozLocation = COMBI_GetPluginString(sPluginName,"sHozLocation",sName)
				sVertLocation = COMBI_GetPluginString(sPluginName,"sVertLocation",sName)
			endif
			//reload
			DiffractionRefs_MainPanel()
			//get wave
			wave/Z/T wRefPeaks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Peaks_Simplified"
			if(!waveexists(wRefPeaks))
				return 0
			endif
			
			//trnaslate
			DiffractionRefs_TranslateInputs()
			//reload
			DiffractionRefs_MainPanel()
			
			//mod new axes
			if(bNewDegAxis==1)
				if((0.15*vDegRange)>vDegMin)
					SetAxis $sDegDataLabel (0),(vDegMax+(0.15*vDegRange))
				else
					SetAxis $sDegDataLabel (vDegMin-(0.15*vDegRange)),(vDegMax+(0.15*vDegRange))
				endif
				Label/W=$sName $sDegDataLabel COMBI_GetPluginString(sPluginName,"sDegLabel",sName)
				ModifyGraph/W=$sName lblPosMode($sDegDataLabel)=1
			endif
			if(bNewIntAxis==1)
				if((0.1*vIntRange)>vLocalIntMin)
					SetAxis $sIntDataLabel vLocalIntMin,(vLocalIntMax+(0.15*vIntRange))
				else
					SetAxis $sIntDataLabel (vLocalIntMin-(0.15*vIntRange)),(vLocalIntMax+(0.15*vIntRange))
				endif
				Label/W=$sName $sIntDataLabel COMBI_GetPluginString(sPluginName,"sIntLabel",sName)
				ModifyGraph/W=$sName lblPosMode($sIntDataLabel)=1
			endif
			
			//re-color
			int iRef
			string sColor
			for(iRef=0;iRef<(iTotalRefsAdded-1);iRef+=1)
				sColor = COMBI_GetUniqueColor((iRef+1),iTotalRefsAdded)
				DiffractionRefs_ChangePeakRefColor(sName,Stringfromlist(iRef,sRefsAdded),sColor)
			endfor
			sColor = COMBI_GetUniqueColor((iRef+1),iTotalRefsAdded)
			
			//Add Peaks draw environemetn
			SetDrawEnv/W=$sName gstart,gname=$sRefName,save
			SetDrawEnv/W=$sName xcoord=$sHozLocation,ycoord=$sVertLocation,linethick= 2.00,fname=sFont,save
			Execute "SetDrawEnv/W="+sName+" linefgc= "+sColor+",textrgb= "+sColor+",save"
			
			//get deg min and max for window
			variable vMinDeg = COMBI_GetPluginNumber(sPluginName,"vG"+sDegTag+"_Min",sName)
			variable vMaxDeg = COMBI_GetPluginNumber(sPluginName,"vG"+sDegTag+"_Max",sName)
			
			//loop peaks to draw
			int iPeak	
			variable vY_Str,vY_End,vX_Str,vX_End
			for(iPeak=0;iPeak<dimsize(wRefPeaks,0);iPeak+=1)
				if(str2num(wRefPeaks[iPeak][%$COMBI_GetPluginString(sPluginName,"sDegDataLabel",sName)])<vDegMin)
					continue
				endif
				if(str2num(wRefPeaks[iPeak][%$COMBI_GetPluginString(sPluginName,"sDegDataLabel",sName)])>vDegMax)
					continue
				endif
				if(str2num(wRefPeaks[iPeak][%$COMBI_GetPluginString(sPluginName,"sIntDataLabel",sName)])<vLocalIntMin)
					continue
				endif
				if(stringmatch(sDegTag,"L")||stringmatch(sDegTag,"R"))
					vY_Str = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
					vY_End = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
				elseif(stringmatch(sDegTag,"T")||stringmatch(sDegTag,"B"))
					vX_Str = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
					vX_End = str2num(wRefPeaks[iPeak][%$sDegDataLabel])
				endif
				
				if(stringmatch(sIntTag,"L")||stringmatch(sIntTag,"R"))
					vY_Str = vLocalIntMin
					vY_End = str2num(wRefPeaks[iPeak][%$sIntDataLabel])
				elseif(stringmatch(sIntTag,"T")||stringmatch(sIntTag,"B"))
					vX_Str = vLocalIntMin
					vX_End = str2num(wRefPeaks[iPeak][%$sIntDataLabel])
				endif
				//drawline
				if(str2num(wRefPeaks[iPeak][%$sDegDataLabel])>vMinDeg&&str2num(wRefPeaks[iPeak][%$sDegDataLabel])<vMaxDeg)
					DrawLine/W=$sName vX_Str,vY_Str,vX_End,vY_End
				endif
			endfor
			SetDrawEnv/W=$sName gstop
			
			//is this the first in the legend?
			sLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sName)
			if(strlen(sLegendText)==0||stringmatch(sLegendText,"NAG")||stringmatch(sLegendText,"\r"))
				sLegendText = "\\K"+sColor+sRefName
			else
				sLegendText = sLegendText+"\r\\K"+sColor+sRefName
			endif
			//legend text
			Legend/C/N=Refs/J sLegendText
			COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sName)
		
		elseif(iAddOrRemove==-1)//remove
			DiffractionRefs_RemovePeakRef(sName,sRefName)
		endif
	endif
end

function DiffractionRefs_RemovePeakRef(sWindow,sRefName)
	string sWindow,sRefName
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:	
	//get the recreation lines
	DrawAction/L=UserFront/W=$sWindow getgroup=$sRefName, commands
	//delete the group
	DrawAction/L=UserFront/W=$sWindow getgroup=$sRefName, delete=V_startPos,V_endPos
	setdatafolder $sTheCurrentUserFolder
	//legend
	string sLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sWindow)
	int iReplaceEnd = strsearch(sLegendText,sRefName,0)-1+2+strlen(sRefName)
	int iReplaceStart = strsearch(sLegendText,"(",iReplaceEnd,1)-strlen("\\K")
	if(iReplaceEnd>iReplaceStart&&iReplaceEnd>0)
		string sToRemove = sLegendText[iReplaceStart,iReplaceEnd]
		if(stringmatch(sToRemove,"*\r\\"))
			sToRemove = sLegendText[iReplaceStart,iReplaceEnd-2]
		endif		
		sLegendText = ReplaceString(sToRemove,sLegendText,"")
		COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sWindow)
	endif
	Legend/C/N=Refs/J sLegendText
	
end

function DiffractionRefs_ChangePeakRefColor(sWindow,sRefName,sColor)
	string sWindow,sRefName,sColor
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:	
	//get the recreation lines
	DrawAction/L=UserFront/W=$sWindow getgroup=$sRefName, commands
	string sRecreation = S_recreation
	//delete the group
	DrawAction/L=UserFront/W=$sWindow getgroup=$sRefName, delete=V_startPos,V_endPos
	//change draw environment
	Execute/Q "SetDrawEnv/W="+sWindow+" linefgc= "+sColor+",textrgb= "+sColor+",save"
	//redraw with new color
	string sLinesToReExecute
	int iLine
	sRecreation = replaceString("\r",sRecreation,"")
	sRecreation = replacestring("SetDrawEnv",sRecreation,"SetDrawEnv/W="+sWindow)
	sRecreation = replacestring("DrawLine",sRecreation,"DrawLine/W="+sWindow)
	for(iLine=V_startPos;iLine<=V_endPos;iLine+=1)
		sRecreation = replaceString("// ;ITEMNO:"+num2str(iLine)+";\t",sRecreation,";")
	endfor
	//set up drawing environment first
	string sThisLine
	for(iLine=0;iLine<itemsInList(sRecreation);iLine+=1)
		sThisLine = stringfromlist(iLine,sRecreation)
		if(stringmatch(sThisLine,"SetDrawEnv*"))
			if(stringmatch(sThisLine,"*gstop*"))
				break
			else
				execute/Q sThisLine	
			endif
		endif
	endfor
	Execute/Q "SetDrawEnv/W="+sWindow+" linefgc= "+sColor+",textrgb= "+sColor+",save"
	//drawlines
	for(iLine=0;iLine<itemsInList(sRecreation);iLine+=1)
		sThisLine = stringfromlist(iLine,sRecreation)
		if(stringmatch(sThisLine,"DrawLine*"))
			execute/Q sThisLine
		endif
	endfor
	Execute/Q "SetDrawEnv/W="+sWindow+" gstop"
	setdatafolder $sTheCurrentUserFolder
	//legend
	string sLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sWindow)
	int iReplaceEnd = strsearch(sLegendText,sRefName,0)
	int iReplaceStart = strsearch(sLegendText,"(",iReplaceEnd,1)
	if(iReplaceEnd>iReplaceStart&&iReplaceEnd>0)
		string sColor2Replace = sLegendText[iReplaceStart,iReplaceEnd-1]
		sLegendText = ReplaceString(sColor2Replace, sLegendText, sColor)
		COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sWindow)
	endif
	Legend/C/N=Refs/J sLegendText
end

	

function DiffractionRefs_TagRef(sRefType,sRefName,sName,iAddOrRemove)
	string sRefType// "Profile" or "Peaks"
	string sRefName// Name of the refrence 
	string sName// name to call for the folder in the plugin globals wave
	int iAddOrRemove //-1 to remove, 1 to add
	
	//things
	int iPeak
	
	//if sName is not a window, abort
	if(strlen(sName)==0)
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","New","COMBIgor")
		return 0
	endif
	if(whichlistitem(sName,WinList("*",";","WIN:1"))==-1)
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","New","COMBIgor")
		return 0
	endif
	
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	DiffractionRefs_TranslateInputs()
	
	string sRefPosition = COMBI_GetPluginString(sPluginName,"sRefPosition",sName)
	
	string sVertDataLabel = COMBI_GetPluginString(sPluginName,"sVertDataLabel",sName)
	string sVertLabel = COMBI_GetPluginString(sPluginName,"sVertLabel",sName)
	string sVertAxisTag = COMBI_GetPluginString(sPluginName,"sVertAxisTag",sName)
	string sVertLocation = COMBI_GetPluginString(sPluginName,"sVertLocation",sName)

	string sDegDataLabel = COMBI_GetPluginString(sPluginName,"sDegDataLabel",sName)
	string sDegPosition = COMBI_GetPluginString(sPluginName,"sDegPosition",sName)
	string sDegTag = COMBI_GetPluginString(sPluginName,"sDegTag",sName)
	string sDegAxis = COMBI_GetPluginString(sPluginName,"sDegAxis",sName)
	
	string sIntDataLabel = COMBI_GetPluginString(sPluginName,"sIntDataLabel",sName)
	string sIntPosition = COMBI_GetPluginString(sPluginName,"sIntPosition",sName)
	string sIntTag = COMBI_GetPluginString(sPluginName,"sIntTag",sName)
	string sIntAxis = COMBI_GetPluginString(sPluginName,"sIntAxis",sName)
	
	string sHozLabel = COMBI_GetPluginString(sPluginName,"sHozLabel",sName)
	string sHozDataLabel = COMBI_GetPluginString(sPluginName,"sHozDataLabel",sName)
	string sHozAxisTag= COMBI_GetPluginString(sPluginName,"sHozAxisTag",sName)
	string sHozLocation = COMBI_GetPluginString(sPluginName,"sHozLocation",sName)
	
	string sRefsAdded = COMBI_GetPluginString(sPluginName,"sRefsAdded",sName)
	string sTagType = COMBI_GetPluginString(sPluginName,"sTagType",sName)
	string sWhereToTag = COMBI_GetPluginString(sPluginName,"sWhereToTag",sName)
	string sAddMarkers = COMBI_GetPluginString(sPluginName,"sAddMarkers",sName)
	int iTotalRefsAdded = COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded",sName)
	
	string sLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sName)
	
	//get ref stats for axis min and max
	NVAR vTTMin = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vTTMin"
	NVAR vTTMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vTTMax"
	NVAR vQMin = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vQMin"
	NVAR vQMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vQMax"
	NVAR vIntMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vIntMax"
	variable vDegMin, vDegMax, vLocalIntMin = 0.001, vLocalIntMax = 1
	if(stringmatch(sDegAxis,"TwoTheta"))
		vDegMin = vTTMin
		vDegMax = vTTMax
	else
		vDegMin = vQMin
		vDegMax = vQMax
	endif
	if(stringmatch(sIntAxis,"Intensity"))
		vLocalIntMax = vIntMax
	endif
	if(COMBI_GetPluginNumber(sPluginName,"bIntLog",sName)==1)
		if(stringmatch(sIntAxis,"Intensity"))
			vLocalIntMin = vIntMax/1000
		else
			vLocalIntMin = .001
		endif
	endif
	variable vDegRange = vDegMax-vDegMin
	variable vIntRange = vLocalIntMax-vLocalIntMin
	
	string sAllTheTraces = TraceNameList(sName,";",1)
	string sTraceToTag = ""

	if(iAddOrRemove==1)//add
		if(iTotalRefsAdded==1)//first added
			COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sName,"COMBIgor")//attaches ref panel
			COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sRefName+";",sName)
			COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded","1",sName)
			COMBI_GivePluginGlobal(sPluginName,"sRefMode","Tags",sName)
			COMBI_GivePluginGlobal(sPluginName,"sRefType","Peaks",sName)
			COMBI_GivePluginGlobal(sPluginName,"sLegendText","",sName)
			//copy inputs from panel folder to the plot folder in globals
			COMBI_GivePluginGlobal(sPluginName,"sRefPosition",COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor"),sName)
			COMBI_GivePluginGlobal(sPluginName,"sDegAxis",COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor"),sName)
			COMBI_GivePluginGlobal(sPluginName,"sIntAxis",COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor"),sName)
			COMBI_GivePluginGlobal(sPluginName,"sDegPosition",COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor"),sName)
			COMBI_GivePluginGlobal(sPluginName,"sIntPosition",COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor"),sName)
			COMBI_GivePluginGlobal(sPluginName,"sIntLog",COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor"),sName)			
			COMBI_GivePluginGlobal(sPluginName,"sTagType",COMBI_GetPluginString(sPluginName,"sTagType","COMBIgor"),sName)			
			COMBI_GivePluginGlobal(sPluginName,"sWhereToTag",COMBI_GetPluginString(sPluginName,"sWhereToTag","COMBIgor"),sName)	
			COMBI_GivePluginGlobal(sPluginName,"sAddMarkers",COMBI_GetPluginString(sPluginName,"sAddMarkers","COMBIgor"),sName)			
			
			//get trace to tag
			if(stringmatch(sWhereToTag,"Trace"))
				sTraceToTag = COMBI_StringPrompt(StringFromList(0, sAllTheTraces),"Append to:",sAllTheTraces,"This is the Trace COMBIgor will attach the tags too.","Choose Trace")
				if(stringmatch(sTraceToTag,"CANCEL"))
					return -1
				endif
				COMBI_GivePluginGlobal(sPluginName,"sTraceToTag",sTraceToTag,sName)
			endif
			
		else
			sTraceToTag = COMBI_GetPluginString(sPluginName,"sTraceToTag",sName)
		endif
		
		//reload
		DiffractionRefs_MainPanel()
		
		//get waves
		wave/Z/T wRefPeaks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Peaks_Simplified"
		string sTheTagWave =  "root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Tags"
		wave/Z wRefPeaksTag = $sTheTagWave
		if(!waveexists(wRefPeaks))
			return 0
		endif
		
		//add to wave if needed.
		if(stringmatch(sWhereToTag,"Trace"))
			//add column if it doesnt exist.
			if(-2==FindDimLabel(wRefPeaksTag,1,sTraceToTag))
				Redimension/N=(-1,(dimsize(wRefPeaksTag,1)+1)) wRefPeaksTag
				SetDimLabel 1,(dimsize(wRefPeaksTag,1)-1),$sTraceToTag,wRefPeaksTag
			endif		
			//which is degree??
			string sTheTraceInfo = TraceInfo(sName,sTraceToTag,0)
			string sTheTraceIntRange
			string sTheTraceDegRange
			string sTheTraceDegreeLoc
			string sTheTraceOtherLoc
			if(stringmatch(sVertDataLabel,sDegDataLabel))//X is intensity
				wave wDegreeData = XWaveRefFromTrace(sName,sTraceToTag)
				wave wIntData = traceNameToWaveRef(sName,sTraceToTag)
				sTheTraceIntRange = StringByKey("XRANGE",sTheTraceInfo)
				sTheTraceDegRange = StringByKey("YRANGE",sTheTraceInfo)
				sTheTraceDegreeLoc = StringByKey("YAXIS",sTheTraceInfo)
				sTheTraceOtherLoc = StringByKey("XAXIS",sTheTraceInfo)
			elseif(stringmatch(sHozDataLabel,sDegDataLabel))//Y is intensity
				wave wDegreeData = traceNameToWaveRef(sName,sTraceToTag)
				wave wIntData = XWaveRefFromTrace(sName,sTraceToTag)
				sTheTraceIntRange = StringByKey("YRANGE",sTheTraceInfo)
				sTheTraceDegRange = StringByKey("XRANGE",sTheTraceInfo)
				sTheTraceDegreeLoc = StringByKey("XAXIS",sTheTraceInfo)
				sTheTraceOtherLoc = StringByKey("YAXIS",sTheTraceInfo)
			endif
			
			//loop the degree column and extract int values
			String expr="([[:digit:]]+),([[:ascii:]]+)"
			String sFirst, sLast

			// get trace wave source data
			int iIntDim, iIntStart, iIntEnd
			sTheTraceIntRange = replacestring("][",sTheTraceIntRange,";")
			sTheTraceIntRange = replacestring("]",sTheTraceIntRange,"")
			sTheTraceIntRange = replacestring("[",sTheTraceIntRange,"")
			int iIntTotalDims = itemsinlist(sTheTraceIntRange)
			if(stringmatch(stringfromList(0,sTheTraceIntRange),"*,*")||Stringmatch("*",stringfromList(0,sTheTraceIntRange)))
				iIntDim = 0
			elseif(stringmatch(stringfromList(1,sTheTraceIntRange),"*,*")||Stringmatch("*",stringfromList(1,sTheTraceIntRange)))
				iIntDim = 1
			elseif(stringmatch(stringfromList(2,sTheTraceIntRange),"*,*")||Stringmatch("*",stringfromList(2,sTheTraceIntRange)))
				iIntDim = 2
			elseif(stringmatch(stringfromList(3,sTheTraceIntRange),"*,*")||Stringmatch("*",stringfromList(3,sTheTraceIntRange)))
				iIntDim = 3
			endif
			if(stringmatch(stringfromList(iIntDim,sTheTraceIntRange),"*,*"))
				SplitString/E=(expr) stringfromList(iIntDim,sTheTraceIntRange), sFirst, sLast
				iIntStart = str2num(sFirst)
				if(stringmatch("*",sLast))
					iIntEnd = dimsize(wDegreeData,0)-1
				else
					iIntEnd = str2num(sLast)
				endif
			else
				iIntStart = 0
				iIntEnd = dimsize(wDegreeData,0)-1
			endif
				
			int iDegDim = 0
			int bDegWave = 0
			int iDegStart, iDegEnd
			int iDegTotalDims = 0
			if(strlen(sTheTraceDegRange)>0)
				bDegWave = 1
				sTheTraceDegRange = replacestring("][",sTheTraceDegRange,";")
				sTheTraceDegRange = replacestring("]",sTheTraceDegRange,"")
				sTheTraceDegRange = replacestring("[",sTheTraceDegRange,"")
				iDegTotalDims = itemsinList(sTheTraceDegRange)
				if(stringmatch(stringfromList(0,sTheTraceDegRange),"*,*")||Stringmatch("*",stringfromList(0,sTheTraceDegRange)))
					iDegDim = 0
				elseif(stringmatch(stringfromList(1,sTheTraceDegRange),"*,*")||Stringmatch("*",stringfromList(1,sTheTraceDegRange)))
					iDegDim = 1
				elseif(stringmatch(stringfromList(2,sTheTraceDegRange),"*,*")||Stringmatch("*",stringfromList(2,sTheTraceDegRange)))
					iDegDim = 2
				elseif(stringmatch(stringfromList(3,sTheTraceDegRange),"*,*")||Stringmatch("*",stringfromList(3,sTheTraceDegRange)))
					iDegDim = 3
				endif
				if(stringmatch(stringfromList(iDegDim,sTheTraceDegRange),"*,*"))
					SplitString/E=(expr) stringfromList(iDegDim,sTheTraceDegRange), sFirst, sLast
					iDegStart = str2num(sFirst)
					if(stringmatch("*",sLast))
						iDegEnd = dimsize(wDegreeData,0)-1
					else
						iDegEnd = str2num(sLast)
					endif
				else
					iDegStart = 0
					iDegEnd = dimsize(wDegreeData,0)-1
				endif
			endif
			
			//find deg index
			for(iPeak=0;iPeak<dimsize(wRefPeaksTag,0);iPeak+=1)
				variable vDegToFind = wRefPeaksTag[iPeak][%$sDegDataLabel]
				int iPointOfInterest
				int iRow,iColumn,iLayer,iChunk
				if(bDegWave==0)//scale to find deg
					variable vDegOffset = DimOffset(wIntData,iIntDim)
					variable vDegDelta = DimDelta(wIntData,iIntDim)
					iPointOfInterest = floor((vDegToFind-vDegOffset)/vDegDelta)
				elseif(bDegWave==1)//x wave to find deg
					if(iDegTotalDims==1)
						iRow = str2num(stringfromlist(0,sTheTraceDegRange))
						iColumn = 0
						iLayer = 0
						iChunk = 0
					elseif(iDegTotalDims==2)
						iRow = str2num(stringfromlist(0,sTheTraceDegRange))
						iColumn = str2num(stringfromlist(1,sTheTraceDegRange))
						iLayer = 0
						iChunk = 0
					elseif(iDegTotalDims==3)
						iRow = str2num(stringfromlist(0,sTheTraceDegRange))
						iColumn = str2num(stringfromlist(1,sTheTraceDegRange))
						iLayer = str2num(stringfromlist(2,sTheTraceDegRange))
						iChunk = 0
					elseif(iDegTotalDims==4)
						iRow = str2num(stringfromlist(0,sTheTraceDegRange))
						iColumn = str2num(stringfromlist(1,sTheTraceDegRange))
						iLayer = str2num(stringfromlist(2,sTheTraceDegRange))
						iChunk = str2num(stringfromlist(3,sTheTraceDegRange))
					endif
					int iDegree
					variable vThisDegValue
					variable vNextDegValue
					int iDegreeIndex = -1
					for(iDegree=iDegStart;iDegree<iDegEnd;iDegree+=1)
						if(iDegDim==0)
							vThisDegValue = wDegreeData[iDegree][iColumn][iLayer][iChunk]
							vNextDegValue = wDegreeData[iDegree+1][iColumn][iLayer][iChunk]
						elseif(iDegDim==1)
							vThisDegValue = wDegreeData[iRow][iDegree][iLayer][iChunk]
							vNextDegValue = wDegreeData[iRow][iDegree+1][iLayer][iChunk]
						elseif(iDegDim==2)
							vThisDegValue = wDegreeData[iRow][iColumn][iDegree][iChunk]
							vNextDegValue = wDegreeData[iRow][iColumn][iDegree+1][iChunk]
						elseif(iDegDim==3)
							vThisDegValue = wDegreeData[iRow][iColumn][iLayer][iDegree]
							vNextDegValue = wDegreeData[iRow][iColumn][iLayer][iDegree+1]
						endif
						if(vDegToFind>=vThisDegValue&&vDegToFind<=vNextDegValue)
							iDegreeIndex = iDegree
							Break
						endif
					endfor
					if(iDegreeIndex==-1)//never found
						wRefPeaksTag[iPeak][%$sTraceToTag] = nan
						continue
					endif
					//get int at that index
					if(iIntTotalDims==1)
						iRow = str2num(stringfromlist(0,sTheTraceIntRange))
						iColumn = 0
						iLayer = 0
						iChunk = 0
					elseif(iIntTotalDims==2)
						iRow = str2num(stringfromlist(0,sTheTraceIntRange))
						iColumn = str2num(stringfromlist(1,sTheTraceIntRange))
						iLayer = 0
						iChunk = 0
					elseif(iIntTotalDims==3)
						iRow = str2num(stringfromlist(0,sTheTraceIntRange))
						iColumn = str2num(stringfromlist(1,sTheTraceIntRange))
						iLayer = str2num(stringfromlist(2,sTheTraceIntRange))
						iChunk = 0
					elseif(iIntTotalDims==4)
						iRow = str2num(stringfromlist(0,sTheTraceIntRange))
						iColumn = str2num(stringfromlist(1,sTheTraceIntRange))
						iLayer = str2num(stringfromlist(2,sTheTraceIntRange))
						iChunk = str2num(stringfromlist(3,sTheTraceIntRange))
					endif
					if(iIntDim==0)
						wRefPeaksTag[iPeak][%$sTraceToTag] = wIntData[(iDegree-iDegStart+iIntStart)][iColumn][iLayer][iChunk]
					elseif(iIntDim==1)
						wRefPeaksTag[iPeak][%$sTraceToTag] = wIntData[iRow][(iDegree-iDegStart+iIntStart)][iLayer][iChunk]
					elseif(iIntDim==2)
						wRefPeaksTag[iPeak][%$sTraceToTag] = wIntData[iRow][iColumn][(iDegree-iDegStart+iIntStart)][iChunk]
					elseif(iIntDim==3)
						wRefPeaksTag[iPeak][%$sTraceToTag] = wIntData[iRow][iColumn][iLayer][(iDegree-iDegStart+iIntStart)]
					endif
				endif
			endfor
		endif
		
		//append a trace to tag
		//Trace;Left Axis Max;Left Axis Min;Left Zero;Left Infinite
		string sAppendCommandString = ""
		int bDoOffset = 0
		string sIntLabelToUse
		if(stringmatch(sWhereToTag,"Trace"))
			sIntLabelToUse = sTraceToTag
		elseif(stringmatch(sWhereToTag,"*Zero"))
			sIntLabelToUse = "Zero"
		else
			sIntLabelToUse = "Unit"
			bDoOffset = 1
		endif
		
		string sOTherTag
		variable vTheScaleMax,vTheScaleMin
		if(stringmatch(sWhereToTag,"Trace"))
			if(stringmatch(sTheTraceOtherLoc,"left"))
				sOTherTag = "L"
			elseif(stringmatch(sTheTraceOtherLoc,"right"))
				sOTherTag = "R"
			elseif(stringmatch(sTheTraceOtherLoc,"top"))
				sOTherTag = "T"
			elseif(stringmatch(sTheTraceOtherLoc,"bottom"))
				sOTherTag = "B"
			endif
		elseif(stringmatch(sWhereToTag,"Left*"))
			sOTherTag = "L"
			if(stringmatch(COMBI_GetPluginString(sPluginName,"bGL",sName),"0"))
				DoAlert/T="Error" 0,"You selecteded: "+sWhereToTag+" for the location, but that axis does not exist."
				return -1
			else
		 		vTheScaleMin = COMBI_GetPluginNumber(sPluginName,"vGL_Min",sName)
		 		vTheScaleMax = COMBI_GetPluginNumber(sPluginName,"vGL_Max",sName)
			endif
		elseif(stringmatch(sWhereToTag,"Right*"))
			sOTherTag = "R"
			if(stringmatch(COMBI_GetPluginString(sPluginName,"bGR",sName),"0"))
				DoAlert/T="Error" 0,"You selecteded: "+sWhereToTag+" for the location, but that axis does not exist."
				return -1
			else
		 		vTheScaleMin = COMBI_GetPluginNumber(sPluginName,"vGR_Min",sName)
		 		vTheScaleMax = COMBI_GetPluginNumber(sPluginName,"vGR_Max",sName)
			endif
		elseif(stringmatch(sWhereToTag,"Top*"))
			sOTherTag = "T"
			if(stringmatch(COMBI_GetPluginString(sPluginName,"bGT",sName),"0"))
				DoAlert/T="Error" 0,"You selecteded: "+sWhereToTag+" for the location, but that axis does not exist."
				return -1
			else
		 		vTheScaleMin = COMBI_GetPluginNumber(sPluginName,"vGT_Min",sName)
		 		vTheScaleMax = COMBI_GetPluginNumber(sPluginName,"vGT_Max",sName)
			endif
		elseif(stringmatch(sWhereToTag,"Bottom*"))
			sOTherTag = "B"
			if(stringmatch(COMBI_GetPluginString(sPluginName,"bGB",sName),"0"))
				DoAlert/T="Error" 0,"You selecteded: "+sWhereToTag+" for the location, but that axis does not exist."
				return -1
			else
		 		vTheScaleMin = COMBI_GetPluginNumber(sPluginName,"vGB_Min",sName)
		 		vTheScaleMax = COMBI_GetPluginNumber(sPluginName,"vGB_Max",sName)
			endif
		endif	
			
		if(stringmatch(sDegTag,"T")||stringmatch(sDegTag,"B"))//vertical intenstity
			sAppendCommandString = "AppendToGraph/"+sOTherTag+"/"+sDegTag+" "+sTheTagWave+"[][%"+sIntLabelToUse+"]/TN="+sRefName+"_Tags vs "+sTheTagWave+"[][%"+sDegDataLabel+"]"
		elseif(stringmatch(sDegTag,"L")||stringmatch(sDegTag,"R"))//horizontal intensity
			sAppendCommandString = "AppendToGraph/"+sOTherTag+"/"+sDegTag+" "+sTheTagWave+"[][%"+sDegDataLabel+"]/TN="+sRefName+"_Tags vs "+sTheTagWave+"[][%"+sIntLabelToUse+"]"
		endif 
		Execute sAppendCommandString
		
		//format
		string sColor = "(0,0,0)"
		
		if(stringmatch(sAddMarkers,"Yes"))
			string sThisMarkerChoice = stringfromlist(iTotalRefsAdded,sMarkers2Use)
			Execute "ModifyGraph mode("+sRefName+"_Tags)=3,msize("+sRefName+"_Tags)=5,marker("+sRefName+"_Tags)="+sThisMarkerChoice+",mrkThick("+sRefName+"_Tags)=0,rgb("+sRefName+"_Tags)="+sColor
		else
			Execute "ModifyGraph mode("+sRefName+"_Tags)=2,msize("+sRefName+"_Tags)=0,lsize("+sRefName+"_Tags)=0,rgb("+sRefName+"_Tags)="+sColor
		endif
		
		//offset trace if needed. The trace will start with a value of 1
		if(bDoOffset==1)
			if(stringmatch(sDegTag,"T")||stringmatch(sDegTag,"B"))//vert offser
				if(stringmatch(sWhereToTag,"*Min"))
					ModifyGraph offset($sRefName+"_Tags")={0,(vTheScaleMin-1)}
				elseif(stringmatch(sWhereToTag,"*Max"))
					ModifyGraph offset($sRefName+"_Tags")={0,(vTheScaleMax-1)}
				endif
			elseif(stringmatch(sDegTag,"L")||stringmatch(sDegTag,"R"))//hor offset
				if(stringmatch(sWhereToTag,"*Min"))
					ModifyGraph offset($sRefName+"_Tags")={(vTheScaleMin-1),0}
				elseif(stringmatch(sWhereToTag,"*Max"))
					ModifyGraph offset($sRefName+"_Tags")={(vTheScaleMax-1),0}
				endif
			endif 
		endif
		
		//Add Peaks draw environemetn
		SetDrawEnv/W=$sName gstart,gname=$sRefName,save
		SetDrawEnv/W=$sName xcoord=$sHozLocation,ycoord=$sVertLocation,linethick= 2.00,fname=sFont,save
		Execute "SetDrawEnv/W="+sName+" linefgc= "+sColor+",textrgb= "+sColor+",save"
		
		//get deg min and max for window
		variable vMinDeg = COMBI_GetPluginNumber(sPluginName,"vG"+sDegTag+"_Min",sName)
		variable vMaxDeg = COMBI_GetPluginNumber(sPluginName,"vG"+sDegTag+"_Max",sName)
		
		//loop peaks to draw	
		for(iPeak=0;iPeak<dimsize(wRefPeaks,0);iPeak+=1)
			if(str2num(wRefPeaks[iPeak][%$sDegDataLabel])>vMinDeg&&str2num(wRefPeaks[iPeak][%$sDegDataLabel])<vMaxDeg)
				string sTagText = "\\K"+sColor
				if(stringmatch(sTagType,"HKL"))
					sTagText+=wRefPeaks[iPeak][%HKLList]
				elseif(stringmatch(sTagType,"Name"))
					sTagText+=sRefName
				endif
				string sTagName = sRefName+"_HKL_"+num2str(iPeak)
				//based on orientation
				if(stringmatch(sRefPosition,"top"))//tags above the markers with lines down to them.
					Tag/O=90/N=$sTagName/F=0/B=1/I=1/A=MB/X=0.00/Y=5.00/L=1 $sRefName+"_Tags", iPeak, sTagText
				elseif(stringmatch(sRefPosition,"bottom"))//tags below the markers with lines up to them.
					Tag/O=90/N=$sTagName/F=0/B=1/I=1/A=MT/X=0.00/Y=-5.00/L=1 $sRefName+"_Tags", iPeak, sTagText
				elseif(stringmatch(sRefPosition,"left"))//tags to the left of markers with lines to the right.
					Tag/N=$sTagName/F=0/B=1/I=1/A=RC/X=-5.00/Y=0.00/L=1 $sRefName+"_Tags", iPeak, sTagText
				elseif(stringmatch(sRefPosition,"right"))//tags to the right of markers with lines to the left.
					Tag/N=$sTagName/F=0/B=1/I=1/A=LC/X=5.00/Y=0.00/L=1 $sRefName+"_Tags", iPeak, sTagText
				endif
				if(stringmatch(sAddMarkers,"Yes"))
					if(stringmatch(sTagType,"None"))
						Execute "Tag/C/N="+sTagName+"/L=0"
					else
						Execute "Tag/C/N="+sTagName+"/TL={lineRGB="+sColor+"}"
					endif
				endif
			endif
		SetDrawEnv/W=$sName gstop
	endfor
	
	//is this the first in the legend?
	if(strlen(sLegendText)==0||stringmatch(sLegendText,"NAG")||stringmatch(sLegendText,"\r"))
		sLegendText = "\\s("+sRefName+"_Tags)\\K"+sColor+sRefName
	else
		sLegendText = sLegendText+"\r\\s("+sRefName+"_Tags)\\K"+sColor+sRefName
	endif
	
	//legend text
	Legend/C/N=Refs/J/F=0/B=1  sLegendText
	COMBI_GivePluginGlobal(sPluginName,"sLegendText",sLegendText,sName)

	elseif(iAddOrRemove==-1)//remove
		if(whichlistitem(sRefName+"_Tags",TraceNameList(sName,";",1))==-1)
			//reload
			DiffractionRefs_MainPanel()
			return 0
		endif
		Execute "RemoveFromGraph/W="+sName+" "+sRefName+"_Tags"
		string sOldLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sName)
		int iReplaceEnd = strsearch(sOldLegendText,")"+sRefName,0)+strlen(")"+sRefName)-1
		int iReplaceStart = strsearch(sOldLegendText,"\\s("+sRefName+"_Tags)\\K(",iReplaceEnd,1)
		string sToRemove = sOldLegendText[iReplaceStart,iReplaceEnd]
		if(iReplaceEnd>iReplaceStart&&iReplaceEnd>0)
			if(iReplaceEnd!=(strlen(sOldLegendText)-1))
			 	if(iReplaceStart!=0)//not last, not first
					sOldLegendText = ReplaceString(sToRemove+"\r",sOldLegendText,"")
				else //not last, first
					sOldLegendText = ReplaceString(sToRemove+"\r",sOldLegendText,"")
				endif
			else //last
				if(iReplaceStart!=0)//last, not first
					sOldLegendText = ReplaceString("\r"+sToRemove,sOldLegendText,"")
				else //last, first
					sOldLegendText = ReplaceString(sToRemove,sOldLegendText,"")
				endif
			endif		
			
			
			COMBI_GivePluginGlobal(sPluginName,"sLegendText",sOldLegendText,sName)
		endif
		Legend/C/N=Refs/J/F=0/B=1 sOldLegendText
		DiffractionRefs_MainPanel()
	endif
	
	//recolor the traces
	if(iTotalRefsAdded>=1)
		int iRefToColor
		for(iRefToColor=0;iRefToColor<iTotalRefsAdded;iRefToColor+=1)
			string sThisRefToReColor = stringfromList(iRefToColor,sRefsAdded)
			sColor = COMBI_GetUniqueColor((iRefToColor+1),iTotalRefsAdded)
			DiffractionRefs_ChangeTagRefColor(sName,sThisRefToReColor,sColor)
		endfor
	endif
	
end


function DiffractionRefs_FolderOfReflections()
	string sTheSoftware = COMBI_StringPrompt(COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor"),"Software Type:",sSoftwareTypes,"","Choose Software Type")
	if(stringmatch(sTheSoftware,"CANCEL"))
		return -1
	endif
	COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref",sTheSoftware,"COMBIgor")
	
	string sFileType =""
	if(stringmatch(sTheSoftware,"CrystalDiffract"))
		sFileType = ".txt"
	elseif(stringmatch(sTheSoftware,"Vesta"))
		sFileType = ".txt"
	elseif(stringmatch(sTheSoftware,"ICSD"))
		sFileType = ".csv"
	endif
		
	// get import path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O pLoadPath
	else
		NewPath/Z/Q/O pLoadPath
	endif
	
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	string sAllFiles = IndexedFile(pLoadPath,-1,".txt")
	sAllFiles = sortlist(sAllFiles,";",16)
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	
	killpath pLoadPath
	
end


function DiffractionRefs_FolderOfProfiles()
	string sTheSoftware = COMBI_StringPrompt(COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor"),"Software Type:",sSoftwareTypes,"","Choose Software Type")
	if(stringmatch(sTheSoftware,"CANCEL"))
		return -1
	endif
	COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref",sTheSoftware,"COMBIgor")
	
	string sFileType =""
	if(stringmatch(sTheSoftware,"CrystalDiffract"))
		sFileType = ".txt"
	elseif(stringmatch(sTheSoftware,"Vesta"))
		sFileType = ".int"
	elseif(stringmatch(sTheSoftware,"ICSD"))
		sFileType = ".csv"
	endif
		
	// get import path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O pLoadPath
	else
		NewPath/Z/Q/O pLoadPath
	endif
	
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	string sAllFiles = IndexedFile(pLoadPath,-1,".txt")
	sAllFiles = sortlist(sAllFiles,";",16)
	variable vNumberOfFiles = itemsinlist(sAllFiles)
	
	killpath pLoadPath
	
end

function DiffractionRefs_FolderOfRefs()
	string sTheSoftware = COMBI_StringPrompt(COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor"),"Software Type:",sSoftwareTypes,"","Choose Software Type")
	if(stringmatch(sTheSoftware,"CANCEL"))
		return -1
	endif
	COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref",sTheSoftware,"COMBIgor")
	
	string sFileType_Pr ="", sFileType_Pk =""
	if(stringmatch(sTheSoftware,"CrystalDiffract"))
		sFileType_Pr = ".txt"
		sFileType_Pk = ".txt"
	elseif(stringmatch(sTheSoftware,"Vesta"))
		sFileType_Pr = ".int"
		sFileType_Pk = ".txt"
	elseif(stringmatch(sTheSoftware,"ICSD"))
		sFileType_Pr = ".csv"
		sFileType_Pk = ".csv"
	endif
		
	// get import path
	string sLoadPath = Combi_GetGlobalString("sImportOption","COMBIgor")
	if(stringmatch("Import Folder",sLoadPath))
		sLoadPath = Combi_GetGlobalString("sImportPath","COMBIgor")
		NewPath/Z/Q/O pUserPath, sLoadPath
		Pathinfo/S pUserPath //direct to user folder
		NewPath/Z/Q/O pLoadPath
	else
		NewPath/Z/Q/O pLoadPath
	endif
	
	Pathinfo pLoadPath
	string sThisLoadFolder = S_path //for storing source folder in data log
	
	string sAllFolders = IndexedDir(pLoadPath,-1,0)
	sAllFolders = sortlist(sAllFolders,";",16)
	variable vNumberOfFolders = itemsinlist(sAllFolders)
	
	killpath pLoadPath
	
end

function DiffractionRefs_ChangeTagRefColor(sName,sRefName,sColor)
	string sName,sRefName,sColor
	string sTheCurrentUserFolder = GetDataFolder(1) 
	setdatafolder root:	
	
	string sDegDataLabel = COMBI_GetPluginString(sPluginName,"sDegDataLabel",sName)
	string sTagType = COMBI_GetPluginString(sPluginName,"sTagType",sName)
	string sDegTag = COMBI_GetPluginString(sPluginName,"sDegTag",sName)
	
	wave/Z/T wRefPeaks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Peaks_Simplified"
	wave/Z wRefPeaksTag = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Tags"
	
	//get deg min and max for window
	variable vMinDeg = COMBI_GetPluginNumber(sPluginName,"vG"+sDegTag+"_Min",sName)
	variable vMaxDeg = COMBI_GetPluginNumber(sPluginName,"vG"+sDegTag+"_Max",sName)
	
	//loop peaks
	int iPeak
	for(iPeak=0;iPeak<dimsize(wRefPeaks,0);iPeak+=1)
		if(str2num(wRefPeaks[iPeak][%$sDegDataLabel])>vMinDeg&&str2num(wRefPeaks[iPeak][%$sDegDataLabel])<vMaxDeg)
			string sTagText = "\\K"+sColor
			if(stringmatch(sTagType,"HKL"))
				sTagText+=wRefPeaks[iPeak][%HKLList]
			elseif(stringmatch(sTagType,"Name"))
				sTagText+=sRefName
			endif
			string sTagName = sRefName+"_HKL_"+num2str(iPeak)
			Execute "Tag/C/N="+sTagName+"/TL={lineRGB="+sColor+"} "+sRefName+"_Tags, "+num2str(iPeak)+",\""+sTagText+"\""
		endif
	endfor
	
	//change markers
	Execute "ModifyGraph/W="+sName+" rgb("+sRefName+"_Tags)="+sColor
	
	//change legend
	string sOldLegendText = COMBI_GetPluginString(sPluginName,"sLegendText",sName)
	int iReplaceEnd = strsearch(sOldLegendText,")"+sRefName,0)
	int iReplaceStart = strsearch(sOldLegendText,"\\s("+sRefName+"_Tags)\\K",iReplaceEnd,1)+strLen("\\s("+sRefName+"_Tags)\\K")
	if(iReplaceEnd>iReplaceStart&&iReplaceEnd>0)
		string sToChange = sOldLegendText[iReplaceStart,iReplaceEnd]
		sOldLegendText = ReplaceString(sToChange,sOldLegendText,sColor)
		COMBI_GivePluginGlobal(sPluginName,"sLegendText",sOldLegendText,sName)
	endif
	Legend/C/N=Refs/J/F=0/B=1 sOldLegendText
	
	setdatafolder $sTheCurrentUserFolder
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Panel Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//function to bo actions when buttons are pressed on panel
function DiffractionRefs_DoAction(ctrlName) : ButtonControl
	string ctrlName
	//top graph name
	string sTopGraph = stringfromlist(0,WinList("*",";","WIN:1"))
	// bring window to front
	if(strlen(sTopGraph)>0)
		DoWindow/F/Z $sTopGraph
	endif	
	//needed variables
	string sTheSoftware
	
	if(stringmatch("btGetPlotInfo",ctrlName))//GetPlot
		if(strlen(sTopGraph)==0)//no graph
			DiffractionRefs_MainPanel()
			return 0
		endif
		//ref info wave
		string sName = GetUserData(sTopGraph,"","RefInfo")
		if(strlen(sName)>0)
			COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sName,"COMBIgor")
		else
			DiffractionRefs_AddAPlot(sName=sName)
			COMBI_GivePluginGlobal(sPluginName,"sTopGraphName",sTopGraph,"COMBIgor")
		endif
			
			DiffractionRefs_MainPanel()
			
	elseif(stringmatch("btFreePlot",ctrlName))//Free Plot
		COMBI_GivePluginGlobal(sPluginName,"sTopGraphName","","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","New","COMBIgor")	
		DiffractionRefs_MainPanel()
		
	elseif(stringmatch("btLoadProfile",ctrlName))
	
		sTheSoftware = COMBI_StringPrompt(COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor"),"Software Type:",sSoftwareTypes,"","Choose Software Type")
		if(stringmatch(sTheSoftware,"CANCEL"))
			return -1
		endif
		COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref",sTheSoftware,"COMBIgor")
		if(stringmatch(sTheSoftware,"CrystalDiffract"))
			DiffractionRefs_CD_LoadProfile()
		elseif(stringmatch(sTheSoftware,"Vesta"))
			DiffractionRefs_Vesta_LoadProfile()
		elseif(stringmatch(sTheSoftware,"ICSD"))
			DiffractionRefs_ICSD_LoadProfile()
		endif
		
	elseif(stringmatch("btLoadPeaks",ctrlName))
		sTheSoftware = COMBI_StringPrompt(COMBI_GetPluginString(sPluginName,"sSoftwavePref","COMBIgor"),"Software Type:",sSoftwareTypes,"","Choose Software Type")
		if(stringmatch(sTheSoftware,"CANCEL"))
			return -1
		endif
		COMBI_GivePluginGlobal(sPluginName,"sSoftwavePref",sTheSoftware,"COMBIgor")
		if(stringmatch(sTheSoftware,"CrystalDiffract"))
			DiffractionRefs_CD_LoadReflections()
		elseif(stringmatch(sTheSoftware,"Vesta"))
			DiffractionRefs_Vesta_LoadReflections()
		elseif(stringmatch(sTheSoftware,"ICSD"))
			DiffractionRefs_ICSD_LoadReflections()
		endif
	endif
		
end


//function to update the globals from the diffraction ref panel
Function DiffractionRefs_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	int bGraphs = 0
	if(itemsInList(winlist("*","","WIN:1"))>1)
		bGraphs = 1
	endif
	int bUpdateRefInfoToo = 0
	string sTopGraphName = Combi_GetPluginString(sPluginName,"sTopGraphName","COMBIgor")
	if(strlen(sTopGraphName)>0)
	   bUpdateRefInfoToo = 1
	endif
	if(stringmatch(ctrlName,"sIntAxis"))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
		endif
		DiffractionRefs_MainPanel()
	elseif(stringmatch(ctrlName,"sIntPosition"))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
		endif
		DiffractionRefs_MainPanel()
	elseif(stringmatch(ctrlName,"sDegAxis"))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
		endif
		DiffractionRefs_MainPanel()
	elseif(stringmatch(ctrlName,"sDegPosition"))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")		
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
		endif
		DiffractionRefs_MainPanel()
	elseif(stringmatch(ctrlName,"sRefMode"))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		if(stringmatch(popStr,"Tags"))
			COMBI_GivePluginGlobal(sPluginName,"sRefType","Peaks","COMBIgor")
		elseif(stringmatch(popStr,"Inspect"))
	
		endif
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
			if(stringmatch(popStr,"Tags"))
				COMBI_GivePluginGlobal(sPluginName,"sRefType","Peaks",sTopGraphName)
			endif
		endif
		DiffractionRefs_MainPanel()
	elseif(stringmatch(ctrlName,"sRefType"))
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
		endif
		DiffractionRefs_MainPanel()
	else
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
		if(bUpdateRefInfoToo==1)
			COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,sTopGraphName)
		endif
		DiffractionRefs_MainPanel()
	endif
end

//checkbutton
Function DiffractionRefs_UpdateRefBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	string sNewRefList
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			string sRefName = cba.ctrlName
			string sGraphName = COMBI_GetPluginString(sPluginName,"sTopGraphName","COMBIgor")
			string sName = Getuserdata(sGraphName,"","RefInfo")
			DiffractionRefs_TranslateInputs()
			if(checked==1)//add
				if(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"New"))//need to update	
					DiffractionRefs_NewRefPlot(COMBI_GetPluginString(sPluginName,"sRefType","COMBIGor"),sRefName)
				elseif(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"Inspect"))
					DiffractionRefs_InspectRef(sRefName)
				else
					//add to total refs added
					COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded",num2str(COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded", sName)+1),sName)
					
					//add to list of refs added
					sNewRefList = AddListItem(sRefName, COMBI_GetPluginString(sPluginName,"sRefsAdded",sName),";",inf)
					COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sNewRefList,sName)
					
					//call appropriate action
					if(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"Append"))
						DiffractionRefs_AppendRef(COMBI_GetPluginString(sPluginName,"sRefType","COMBIGor"),sRefName,sName,1)
						
					elseif(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"Tags"))
						DiffractionRefs_TagRef(COMBI_GetPluginString(sPluginName,"sRefType","COMBIGor"),sRefName,sName,1)
						
					endif		
				endif
			elseif(checked==0)//remove
				//remove to total refs added
				COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded",num2str(COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded", sName)-1),sName)
				
				//remove to list of refs added
				sNewRefList = RemoveFromList(sRefName, COMBI_GetPluginString(sPluginName,"sRefsAdded",sName))
				COMBI_GivePluginGlobal(sPluginName,"sRefsAdded",sNewRefList,sName)
				
				//call appropriate action
				if(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"Append"))
					DiffractionRefs_AppendRef(COMBI_GetPluginString(sPluginName,"sRefType","COMBIGor"),sRefName,sName,-1)
				elseif(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"Tags"))
					DiffractionRefs_TagRef(COMBI_GetPluginString(sPluginName,"sRefType","COMBIGor"),sRefName,sName,-1)
				endif
			endif
			if(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIGor"),"New"))//needed unchecked
				CheckBox $sRefName win=$sDifRefPanel,value=0
			endif
			DiffractionRefs_UpdateMainPanel()
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

function DiffractionRefs_UpdateMainPanel()
	
	//window to operate on
	string sName = ""
	string sTopGraphName = COMBI_GetPluginString(sPluginName,"sTopGraphName","COMBIgor")
	if(whichListItem(sTopGraphName,winlist("*",";","WIN:1"))!=-1)
		sName = GetUserData(sTopGraphName,"","RefInfo")
	else
		sTopGraphName = ""
	endif
	
	//to lock out popups
	int iModeLock = 0
	if(strlen(sName)>0)
		if(COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded",sName)>0)
			iModeLock = 2
		endif 
	endif
	
	//needed variables	
	string sRefType,sRefMode,sRefPosition,sDegAxis,sIntAxis,sDegPosition,sIntPosition,sIntLog,sTagType, sWhereToTag, sAddMarkers
	sRefType = COMBI_GetPluginString(sPluginName,"sRefType","COMBIgor")
	sRefMode = COMBI_GetPluginString(sPluginName,"sRefMode","COMBIgor")
	sRefPosition = COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor")	
	sDegAxis = COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor")
	sIntAxis = COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor")
	sDegPosition = COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor")
	sIntPosition = COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor")
	sIntLog = COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor")
	sTagType = COMBI_GetPluginString(sPluginName,"sTagType","COMBIgor")
	sWhereToTag = COMBI_GetPluginString(sPluginName,"sWhereToTag","COMBIgor")
	sAddMarkers = COMBI_GetPluginString(sPluginName,"sAddMarkers","COMBIgor")
	
	//update popups
	PopupMenu sRefMode win=$sDifRefPanel,popvalue=sRefMode,disable=iModeLock
	if(!stringmatch(sRefMode,"Inspect"))
		PopupMenu sRefType win=$sDifRefPanel,popvalue=sRefType,disable=iModeLock
		PopupMenu sDegAxis win=$sDifRefPanel,popvalue=sDegAxis,disable=iModeLock
		PopupMenu sDegPosition win=$sDifRefPanel,popvalue=sDegPosition,disable=iModeLock
		if(stringmatch(sRefMode,"Tags"))
			PopupMenu sTagType win=$sDifRefPanel,popvalue=sTagType,disable=iModeLock
			PopupMenu sRefPosition win=$sDifRefPanel,disable=iModeLock,popvalue=sRefPosition
			PopupMenu sWhereToTag win=$sDifRefPanel,disable=iModeLock,popvalue=sWhereToTag
			PopupMenu sAddMarkers win=$sDifRefPanel,disable=iModeLock,popvalue=sAddMarkers
		else
			PopupMenu sIntLog win=$sDifRefPanel,popvalue=sIntLog,disable=iModeLock
			PopupMenu sIntAxis win=$sDifRefPanel,disable=iModeLock,popvalue=sIntAxis
			PopupMenu sIntPosition win=$sDifRefPanel,popvalue=sIntPosition,disable=iModeLock
		endif
	endif
	
	
	
	//update what is checked
	//get list of all refrences in folder
	string sAllRefs = DiffractionRefs_GetRefNames("all")
	string sAllPeakRefs = DiffractionRefs_GetRefNames("peaks")
	string sAllProfileRefs = DiffractionRefs_GetRefNames("profile")
	string sRefsToShow 
	if(stringmatch(sRefType,"Peaks"))
		sRefsToShow = sAllPeakRefs
	elseif(stringmatch(sRefType,"Profile"))
		sRefsToShow = sAllProfileRefs
	endif
	int iRef = 0
	string sThisRef = ""
	string sRefsAlreadyAdded = ""
	if(strlen(sName)>0)
		sRefsAlreadyAdded = COMBI_GetPluginString(sPluginName,"sRefsAdded",sName)
	endif
	if(stringmatch(sRefMode,"New"))
		sRefsAlreadyAdded = ""
	endif
	do
		sThisRef = stringfromlist(iRef,sRefsToShow)
		if(iRef<itemsinlist(sRefsToShow))
			if(whichlistitem(sThisRef,sRefsAlreadyAdded)==-1)//not yet added
				CheckBox $sThisRef win=$sDifRefPanel,value=0
			else //already added
				CheckBox $sThisRef win=$sDifRefPanel,value=1
			endif
		endif
		iRef+=1
	while(iRef<itemsinlist(sRefsToShow))
	
end

//this function makes the panel
function DiffractionRefs_MainPanel()
	//get users current folder to return to
	string sTheCurrentUserFolder = GetDataFolder(1) 
	
	//make sure folder exist
	newdatafolder/O root:COMBIgor:DiffractionRefs
	
	//get Plugin name and project name
	string sProject = COMBI_GetGlobalString("sPluginProject", "COMBIgor")
	
	//panel building
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")

	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z DiffractionRefPanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z DiffractionRefPanel
	
	COMBI_PluginReady(sPluginName)
	//get global wave
	wave/T twGlobals = $"root:Packages:COMBIgor:Plugins:COMBI_"+sPluginName+"_Globals"
	
			
	//check for graphs
	int bGraphs = 0
	int bPlotExisits = 0
	string sName = ""
	string sTopGraphName = COMBI_GetPluginString(sPluginName,"sTopGraphName","COMBIgor")
	if(itemsInList(winlist("*",";","WIN:1"))>0)// there are plots
		bGraphs = 1
		if(whichListItem(sTopGraphName,winlist("*",";","WIN:1"))!=-1)
			bPlotExisits = 1
			sName = GetUserData(sTopGraphName,"","RefInfo")
			if(strlen(sName)==0)
				sName = DiffractionRefs_AddAPlot(sName=sTopGraphName)
			endif
		else
			sTopGraphName = ""
		endif
	else
		sTopGraphName = ""
	endif
		
	//needed variables	
	string sAction //append or new
	string sRefType // profile or peak list
	string sRefMode //bars, sticks, or color bar
	string sRefPosition //bars, sticks, or color bar
	string sSoftwavePref // type of ref manager 
	string sDegAxis 
	string sIntAxis 
	string sDegPosition
	string sIntPosition
	string sIntLog
	string sTagType
	string sWhereToTag
	string sAddMarkers
	
	//int panel if first time
	if(stringmatch(COMBI_GetPluginString(sPluginName,"sRefMode","COMBIgor"),"NAG"))
		COMBI_GivePluginGlobal(sPluginName,"sTopGraphName","","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sRefMode","New","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sRefType","Profile","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sRefPosition","top","COMBIgor")	
		COMBI_GivePluginGlobal(sPluginName,"sDegAxis","Q","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sDegPosition","bottom","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sIntAxis","Fraction of Max","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sIntPosition","left","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sIntLog","Log","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sTagType","HKL","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sWhereToTag","Left Axis Max","COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sAddMarkers","Yes","COMBIgor")
	endif
	
	if(strlen(sName)>0)
		//get from this plot ref info
		sRefType = COMBI_GetPluginString(sPluginName,"sRefType",sName)
		sRefMode = COMBI_GetPluginString(sPluginName,"sRefMode",sName)
		sRefPosition = COMBI_GetPluginString(sPluginName,"sRefPosition",sName)	
		sDegAxis = COMBI_GetPluginString(sPluginName,"sDegAxis",sName)
		sIntAxis = COMBI_GetPluginString(sPluginName,"sIntAxis",sName)
		sDegPosition = COMBI_GetPluginString(sPluginName,"sDegPosition",sName)
		sIntPosition = COMBI_GetPluginString(sPluginName,"sIntPosition",sName)
		sIntLog = COMBI_GetPluginString(sPluginName,"sIntLog",sName)
		sTagType = COMBI_GetPluginString(sPluginName,"sTagType",sName)
		sWhereToTag = COMBI_GetPluginString(sPluginName,"sWhereToTag",sName)
		sAddMarkers = COMBI_GetPluginString(sPluginName,"sAddMarkers",sName)
		//put on panel
		COMBI_GivePluginGlobal(sPluginName,"sRefType",sRefType,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sRefMode",sRefMode,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sRefPosition",sRefPosition,"COMBIgor")	
		COMBI_GivePluginGlobal(sPluginName,"sDegAxis",sDegAxis,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sIntAxis",sIntAxis,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sDegPosition",sDegPosition,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sIntPosition",sIntPosition,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sIntLog",sIntLog,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sTagType",sTagType,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sWhereToTag",sWhereToTag,"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,"sAddMarkers",sAddMarkers,"COMBIgor")
	else
		sRefType = COMBI_GetPluginString(sPluginName,"sRefType","COMBIgor")
		sRefMode = COMBI_GetPluginString(sPluginName,"sRefMode","COMBIgor")
		sRefPosition = COMBI_GetPluginString(sPluginName,"sRefPosition","COMBIgor")	
		sDegAxis = COMBI_GetPluginString(sPluginName,"sDegAxis","COMBIgor")
		sIntAxis = COMBI_GetPluginString(sPluginName,"sIntAxis","COMBIgor")
		sDegPosition = COMBI_GetPluginString(sPluginName,"sDegPosition","COMBIgor")
		sIntPosition = COMBI_GetPluginString(sPluginName,"sIntPosition","COMBIgor")
		sIntLog = COMBI_GetPluginString(sPluginName,"sIntLog","COMBIgor")
		sTagType = COMBI_GetPluginString(sPluginName,"sTagType","COMBIgor")
		sWhereToTag = COMBI_GetPluginString(sPluginName,"sWhereToTag","COMBIgor")
		sAddMarkers = COMBI_GetPluginString(sPluginName,"sAddMarkers","COMBIgor")
	endif
	
	//make panel
	int iPanelW = 300
	int iYValue = 10
	//to track with window
	variable vYValue = 1
	int iWL = 10
	int iWT = 10
	if(strlen(sTopGraphName)>0)
		GetWindow/Z $sTopGraphName wsize
		iWL = V_right
		iWT = V_top
	else
		iWL = vWinLeft
		iWT = vWinTop
	endif
	
	string sPanelName
	if(strlen(sName)>0)
		NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/HOST=$sTopGraphName/EXT=0/W=(0,0,iPanelW,vYValue)/N=$sDifRefPanel as "Diffraction References Plugin"
		sPanelName = sTopGraphName+"#"+sDifRefPanel
	else
		NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(iWL,iWT,iWL+iPanelW,iWT+vYValue)/N=$sDifRefPanel as "Diffraction References Plugin"	
		sPanelName = sDifRefPanel
	endif

	vYValue+=15
	SetDrawLayer UserBack
	SetDrawEnv fname = sFont
	SetDrawEnv textxjust = 0,textyjust = 1
	SetDrawEnv fsize = 12
	SetDrawEnv save
	
	//Graph Row
	SetDrawEnv textxjust = 1, fstyle= 1 ,save
	SetDrawEnv dash= 3,linethick= 2.00
	DrawLine 5,vYValue-10,iPanelW-5,vYValue-10
	DrawText 150,vYValue, "Diffraction Plot Information"; vYValue+=20
	SetDrawEnv dash= 3,linethick= 2.00
	DrawLine 5,vYValue-10,iPanelW-5,vYValue-10;vYValue+=5
	
	//buttons to get and release plots
	button btGetPlotInfo,title="Get Top Plot",appearance={native,All},pos={25,vYValue-10},size={112,20},proc=DiffractionRefs_DoAction,font=sFont,fstyle=1,fColor=(65535/2,65535,65535),fsize=12
	button btFreePlot,title="Release Plot",appearance={native,All},pos={162,vYValue-10},size={112,20},proc=DiffractionRefs_DoAction,font=sFont,fstyle=1,fColor=(65535/2,65535,65535),fsize=12

	vYValue+=20
	
	if(strlen(sName)>0)//add additonal plot information
		SetDrawEnv textxjust = 2, fstyle= 1 ,save
		DrawText 75,vYValue, "Name: "; vYValue+=20
		DrawText 75,vYValue, "Ref Mode: "; vYValue+=20
		SetDrawEnv textxjust = 0, fstyle= 0 ,save; vYValue-=40
		DrawText 75,vYValue, sTopGraphName; vYValue+=20
		DrawText 75,vYValue, sRefMode; vYValue+=20
	endif
	
	SetDrawEnv dash= 3,linethick= 2.00
	DrawLine 5,vYValue,iPanelW-5,vYValue;vYValue+=10
		
	//to lock out previosuly used waves into the same settings
	int iModeLock = 0
	if(strlen(sName)>0)
		if(COMBI_GetPluginNumber(sPluginName,"iTotalRefsAdded",sName)>0)
			iModeLock = 2
		endif 
	endif
	
	//Plot optinos Row
	SetDrawEnv textxjust = 1, fstyle= 1 ,save
	DrawText 150,vYValue, "Refrence Plot Options"; vYValue+=20
	SetDrawEnv dash= 3,linethick= 2.00
	DrawLine 5,vYValue-10,iPanelW-5,vYValue-10; vYValue+=5
	SetDrawEnv textxjust = 2, fstyle= 1 ,save

	if(stringmatch("Tags",sRefMode))
		DrawText 75,vYValue, "Mode: "
		DrawText 187,vYValue, "as"; vYValue+=20
		DrawText 75,vYValue, "Tag: ";
		DrawText 187,vYValue, "at"; vYValue+=20
		DrawText 75,vYValue, "On: "; vYValue+=20
		DrawText 75,vYValue, "Markers?"; vYValue+=20
		DrawText 75,vYValue, "Ind. Axis: "
		DrawText 187,vYValue, "on"
	elseif(stringmatch("Inspect",sRefMode))
		DrawText 75,vYValue, "Mode: "; vYValue+=20
	else
		DrawText 75,vYValue, "Mode: "
		DrawText 187,vYValue, "as"; vYValue+=20
		DrawText 75,vYValue, "Int. Axis: "
		DrawText 187,vYValue, "on"; vYValue+=20
		DrawText 75,vYValue, "Int. Scale: "; vYValue+=20
		DrawText 75,vYValue, "Ind. Axis: "
		DrawText 187,vYValue, "on"
	endif
	
	if(stringmatch("Tags",sRefMode))
		vYValue-=80
	elseif(stringmatch("Inspect",sRefMode))
		vYValue-=20
	else
		vYValue-=60
	endif	
	
	SetDrawEnv textxjust = 0, fstyle= 0 ,save
	
	PopupMenu sRefMode,popvalue=sRefMode,pos={114,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="Append;Tags;New;Inspect",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
	if(!stringmatch("Inspect",sRefMode))
		vYValue-=20
		if(!stringmatch("Tags",sRefMode))
			PopupMenu sRefType,popvalue=sRefType,pos={225,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="Profile;Peaks",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
			PopupMenu sIntAxis,pos={114,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="Intensity;Fraction of max",proc=DiffractionRefs_UpdateGlobal,popvalue=sIntAxis
			PopupMenu sIntPosition,popvalue=sIntPosition,pos={225,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="left;right;top;bottom;color",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
			PopupMenu sIntLog,popvalue=sIntLog,pos={114,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="Log;Linear",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
		else
			PopupMenu sRefType,popvalue=sRefType,pos={225,vYValue-8},mode=1,disable=2,bodyWidth=80,value="Profile;Peaks",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
			PopupMenu sTagType,popvalue=sTagType,pos={114,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="HKL;Name;None",proc=DiffractionRefs_UpdateGlobal
			PopupMenu sRefPosition,popvalue=sRefPosition,pos={225,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="Left;Right;Top;Bottom",proc=DiffractionRefs_UpdateGlobal; vYValue+=20	
			PopupMenu sWhereToTag,popvalue=sWhereToTag,pos={225,vYValue-8},mode=1,disable=iModeLock,bodyWidth=190,value="Trace;Left Axis Max;Left Axis Min;Left Zero;Right Axis Max;Right Axis Min;Right Zero;Top Axis Max;Top Axis Min;Top Zero;Bottom Axis Max;Bottom Axis Min;Bottom Zero",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
			PopupMenu sAddMarkers,popvalue=sAddMarkers,pos={225,vYValue-8},mode=1,disable=iModeLock,bodyWidth=190,value="Yes;No",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
		endif
		PopupMenu sDegAxis,popvalue=sDegAxis,pos={114,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="TwoTheta;Q",proc=DiffractionRefs_UpdateGlobal
		PopupMenu sDegPosition,popvalue=sDegPosition,pos={225,vYValue-8},mode=1,disable=iModeLock,bodyWidth=80,value="left;right;top;bottom;color",proc=DiffractionRefs_UpdateGlobal; vYValue+=20
	endif
	
	//refrences
	vYValue+=10
	SetDrawEnv textxjust = 1, fstyle = 1, save
	SetDrawEnv dash= 3,linethick= 2.00
	DrawLine 5,vYValue-10,iPanelW-5,vYValue-10
	DrawText 150,vYValue, "Diffraction Refrences"; vYValue+=20
	SetDrawEnv dash= 3,linethick= 2.00
	DrawLine 5,vYValue-10,iPanelW-5,vYValue-10;vYValue+=5
	SetDrawEnv fstyle = 0, save
	
	//add peaks and profile buttons
	button btLoadProfile,title="Load Profile",appearance={native,All},pos={25,vYValue-10},size={112,20},proc=DiffractionRefs_DoAction,font=sFont,fstyle=1,fColor=(65535/2,65535,65535),fsize=12
	button btLoadPeaks,title="Load Reflections",appearance={native,All},pos={162,vYValue-10},size={112,20},proc=DiffractionRefs_DoAction,font=sFont,fstyle=1,fColor=(65535/2,65535,65535),fsize=12

	vYValue+=20
	
	//show refrences?
	//get list of all refrences in folder
	string sAllRefs = DiffractionRefs_GetRefNames("all")
	string sAllPeakRefs = DiffractionRefs_GetRefNames("peaks")
	string sAllProfileRefs = DiffractionRefs_GetRefNames("profile")
	string sAllBothRefs = ""
	int iPeakRef
	for(iPeakRef=0;iPeakRef<itemsinlist(sAllPeakRefs);iPeakRef+=1)
		if(WhichListItem(stringfromlist(iPeakRef,sAllPeakRefs),sAllProfileRefs)!=-1)
			sAllBothRefs+=(stringfromlist(iPeakRef,sAllPeakRefs)+";")
		endif
	endfor
	string sRefsToShow 
	if(stringmatch(sRefType,"Peaks"))
		sRefsToShow = sAllPeakRefs
	elseif(stringmatch(sRefType,"Profile"))
		sRefsToShow = sAllProfileRefs
	endif
	int iRef = 0
	string sThisRef = ""
	string sRefsAlreadyAdded = ""
	if(strlen(sName)>0)
		sRefsAlreadyAdded = COMBI_GetPluginString(sPluginName,"sRefsAdded",sName)
	endif
	if(stringmatch(sRefMode,"New"))
		sRefsAlreadyAdded = ""
	elseif(stringmatch("Inspect",sRefMode))
		sRefsAlreadyAdded = ""
		sRefsToShow = sAllBothRefs
	endif
	do
		sThisRef = stringfromlist(iRef,sRefsToShow)
		if(iRef<itemsinlist(sRefsToShow))
			if(whichlistitem(sThisRef,sRefsAlreadyAdded)==-1)//not yet added
				CheckBox $sThisRef fsize=12,pos={25,vYValue-5},proc=DiffractionRefs_UpdateRefbox,size={100,20},title=sThisRef, value=0,userdata=sName
			else //already added
				CheckBox $sThisRef fsize=12,pos={25,vYValue-5},proc=DiffractionRefs_UpdateRefbox,size={100,20},title=sThisRef, value=1,userdata=sName
			endif
		endif
		iRef+=1
		
		sThisRef = stringfromlist(iRef,sRefsToShow)
		if(iRef<itemsinlist(sRefsToShow))
			if(whichlistitem(sThisRef,sRefsAlreadyAdded)==-1)//not yet added
				CheckBox $sThisRef fsize=12,pos={175,vYValue-5},proc=DiffractionRefs_UpdateRefbox,size={100,20},title=sThisRef, value=0,userdata=sName
			else //already added
				CheckBox $sThisRef fsize=12,pos={175,vYValue-5},proc=DiffractionRefs_UpdateRefbox,size={100,20},title=sThisRef, value=1,userdata=sName
			endif
		endif
		iRef+=1
		vYValue+=20
	while(iRef<itemsinlist(sRefsToShow))

	//resize
	if(strlen(sName)>0)
		movesubWindow/W=$sPanelName fnum=(0,0,iPanelW,vYValue)
	else
		moveWindow/W=$sPanelName iWL,iWT,iWL+iPanelW,iWT+vYValue
	endif
	
	
end


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Ref Info waves and their functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//return a list of all refrences with profiles or peaks
function/S DiffractionRefs_GetRefNames(sType)
	string sType//profile, peaks, or all
	
	//get ref folders
	string sTheCurrentUserFolder = GetDataFolder(1)
	setdatafolder root:COMBIgor:DiffractionRefs:
	string sAllRefFolders = StringByKey("FOLDERS", DataFolderDir(1))
	sAllRefFolders = replacestring(",",sAllRefFolders,";")
	
	//loop all and look for profile and peak list
	int iRef
	string sAllPeaks = ""
	string sAllProfiles = ""
	for(iRef=0;iRef<itemsinlist(sAllRefFolders);iRef+=1)
		setdatafolder $stringfromlist(iRef,sAllRefFolders)
		if(itemsinlist(WaveList(stringfromlist(iRef,sAllRefFolders)+"_Peaks", ";",""))>0)
			sAllPeaks+=stringfromlist(iRef,sAllRefFolders)+";"
		endif
		if(itemsinlist(WaveList(stringfromlist(iRef,sAllRefFolders)+"_Profile", ";",""))>0)
			sAllProfiles+=stringfromlist(iRef,sAllRefFolders)+";"
		endif
		setdatafolder root:COMBIgor:DiffractionRefs:
	endfor
	
	//to return
	setdatafolder $sTheCurrentUserFolder
	if(stringmatch(sType,"profile"))
		return sAllProfiles
	elseif(stringmatch(sType,"peaks"))
		return sAllPeaks
	elseif(stringmatch(sType,"all"))
		return sAllRefFolders
	endif
	
end

//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 0
	GetWindow/Z DiffractionRefPanel wsize
	vWinLeft = V_left
	vWinTop = V_top
	KillWindow/Z DiffractionRefPanel


//makes refinfo wave with initial vlaues from the top graph ad returns the refrence to it
function/S DiffractionRefs_AddAPlot([sName])
	string sName
	
	//current folder
	string sTheCurrentUserFolder = GetDataFolder(1)
	
	//get plot to ref
	string sTopGraph
	if(itemsinlist(WinList("*",";","WIN:1"))==0)//no windows
		return ""
	endif
	
	//default input
	if(paramIsDefault(sName))
		sTopGraph = stringfromlist(0,WinList("*",";","WIN:1"))//top window
	else //name given
		if(whichListItem(sName,WinList("*",";","WIN:1"))!=-1)
			sTopGraph = sName//input name
		else
			sTopGraph = stringfromlist(0,WinList("*",";","WIN:1"))//top window
		endif
	endif
	
	// bring window to front
	DoWindow/F $sTopGraph
	
	//globals
	wave/T wGlobals = root:Packages:COMBIgor:Plugins:COMBI_DiffractionRefs_Globals
	
	//if already exist in the globals
	if(FindDimLabel(wGlobals,1,sTopGraph)!=-2)
		return sTopGraph
	endif
	
	//mark window as intialized
	SetWindow $sTopGraph,userdata(RefInfo)=sTopGraph
		
	//Initialize Diffraction ref options
	COMBI_GivePluginGlobal(sPluginName,"sRefMode","Append",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sRefType","Profile",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sRefPosition","top",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sRefsAdded","",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"iTotalRefsAdded","0",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sName",sTopGraph,sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sIntAxis","Fraction of max",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sDegAxis","Q",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sIntPosition","left",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sDegPosition","bottom",sTopGraph)
	COMBI_GivePluginGlobal(sPluginName,"sIntLog","Log",sTopGraph)	
	COMBI_GivePluginGlobal(sPluginName,"sTagType","HKL",sTopGraph)	
	COMBI_GivePluginGlobal(sPluginName,"sWhereToTag","Left Axis Max",sTopGraph)	
	COMBI_GivePluginGlobal(sPluginName,"sAddMarkers","Yes",sTopGraph)	
	
	//set hook function to kill the ref infor wave when the window is killed
	SetWindow $sTopGraph,hook(kill)=DiffractionRefs_KillRefInfo

	//return to current folder
	setdatafolder $sTheCurrentUserFolder
	
	return sTopGraph
end


//function to kill wave after the plot is killed
function DiffractionRefs_KillRefInfo(s)
	STRUCT WMWinHookStruct &s
	if(s.eventCode==2)//window being killed
		//delete the column from the ref globals wave
		wave/T wGlobals = root:Packages:COMBIgor:Plugins:COMBI_DiffractionRefs_Globals
		string sWinName = s.winName
		string sName = GetUserData(sWinName,"", "RefInfo")
		int iC2Delete = FindDimLabel(wGlobals,1,sName)
		DeletePoints/M=1 iC2Delete, 1, wGlobals
		//remove active sTopGraph, if so
		if(stringmatch(sName,Combi_GetPluginString(sPluginName, "sTopGraphName","COMBIgor")))
			COMBI_GivePluginGlobal(sPluginName,"sTopGraphName","","COMBIgor")
		endif
	endif
end


//this function clears a plot so new things can be done to it.
Function DiffractionRefs_ResetPlotOptions(sName)
	string sName

	//clear user data
	string sOldName = GetUserData(sName,"", "RefInfo")
	SetWindow $sName,userdata(RefInfo)=""
	
	//change globals wave
	wave/T wGlobals = root:Packages:COMBIgor:Plugins:COMBI_DiffractionRefs_Globals
	int iCol2Clear = FindDimLabel(wGlobals,1,sName)
	if(iCol2Clear>=0)
		DeletePoints/M=1 iCol2Clear, 1, wGlobals
	endif
	//if old names
	if(!stringmatch(sName,sOldName))
		if(iCol2Clear>=0)
			DeletePoints/M=1 iCol2Clear, 1, wGlobals
		endif
	endif
	
End

Function DiffractionRefs_InspectRef(sRefName)
	string sRefName
	
	//font
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	
	//get waves
	wave/Z/T wRefPeaksSimp = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Peaks_Simplified"
	wave/Z wRefPeaks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Peaks"
	wave/Z wRefTags = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Tags"
	wave/Z wRefProfile = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile"
	
	//Plot Profile
	Killwindow/Z $"Inspect_"+sRefName
	Display/K=1/N=$"Inspect_"+sRefName/L/B wRefProfile[][%FracMaxIntensity]/TN=$sRefName vs wRefProfile[][%Q_2PiPerAng] as "XRD Ref "+sRefName
	AppendToGraph/W=$"Inspect_"+sRefName/R/T wRefProfile[][%FracMaxIntensity]/TN=$sRefName+"_H" vs wRefProfile[][%Q_2PiPerAng]
	Label left "Fraction of Max Intensity"
	Label bottom "Scattering Vector Magnitude (2π/Å)"
	ModifyGraph log(left)=1,nticks(bottom)=10,minor(bottom)=1, font=sFont
	SetAxis left 0.001,*
	SetAxis bottom wRefProfile[1][%Q_2PiPerAng],wRefProfile[(dimsize(wRefProfile,0)-1)][%Q_2PiPerAng]
	ModifyGraph mode=7,usePlusRGB=0,hbFill=4,rgb=(0,0,0)
	
	//append peaks points
	AppendToGraph/W=$"Inspect_"+sRefName wRefTags[][%FracMaxIntensity]/TN=$sRefName+"_Tags" vs wRefTags[][%Q_2PiPerAng]
	ModifyGraph/W=$"Inspect_"+sRefName mode($sRefName+"_Tags")=3,marker($sRefName+"_Tags")=19,msize($sRefName+"_Tags")=4,useMrkStrokeRGB($sRefName+"_Tags")=1
	ModifyGraph/W=$"Inspect_"+sRefName width=800,height=200,gfSize=12,standoff(bottom)=0,font=sFont

	//Add Peaks draw environemetn
	SetDrawEnv/W=$"Inspect_"+sRefName gstart,gname=$sRefName,save
	SetDrawEnv/W=$"Inspect_"+sRefName xcoord=bottom,ycoord=left,linethick= 2.00,fname=sFont,save
	
	//loop peaks to draw	
	int iPeak
	int iMaxTagLength=0
	for(iPeak=0;iPeak<dimsize(wRefPeaksSimp,0);iPeak+=1)
		string sTagText = wRefPeaksSimp[iPeak][%HKLList]
		string sTagName = sRefName+"_HKL_"+num2str(iPeak)
		Tag/O=0/N=$sTagName/F=0/B=1/I=1/A=RC/X=-1.00/Y=0.00/L=1 $sRefName+"_Tags", iPeak, sTagText
		iMaxTagLength = max(iMaxTagLength,strlen(sTagText))
	endfor

	//add more ticks for TT
	DiffractionRefs_TickTransform(sRefName)
	
	//format top
	Execute "ModifyGraph userticks(top)={:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Q2TTTicks,:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Q2TTLables},standoff(top)=0"
	Label top "Diffraction Angle (degree)"
	
	//format right
	Execute "ModifyGraph userticks(right)={:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Frac2IntTicks,:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Frac2IntLables}"
	ModifyGraph/W=$"Inspect_"+sRefName log(right)=1
	SetAxis/W=$"Inspect_"+sRefName right 0.001,1
	
	//genral
	ModifyGraph/W=$"Inspect_"+sRefName standoff=1
	Label/W=$"Inspect_"+sRefName right "Intensity"
	
end

//to make tick transform waves
function DiffractionRefs_TickTransform(sRefName)
	string sRefName
	
	//get stuff
	wave/Z wRefProfile = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Profile"	
	NVAR vIntMax = $"root:COMBIgor:DiffractionRefs:"+sRefName+":vIntMax"
	int iQMax = ceil(wRefProfile[(dimsize(wRefProfile,0)-1)][%Q_2PiPerAng])
	int iTTMax = ceil(wRefProfile[(dimsize(wRefProfile,0)-1)][%TwoTheta])
	int iQMin = floor(wRefProfile[1][%Q_2PiPerAng])
	int iTTMin = floor(wRefProfile[1][%TwoTheta])
	
	//make waves
	int iTicksTT = (ceil((iTTMax-iTTMin)/10)*10)+1
	Make/O/N=(iTicksTT) $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Q2TTTicks"	
	Make/O/N=(iTicksTT,2)/T $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Q2TTLables"	
	wave wQ2TTTicks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Q2TTTicks"
	wave/T wQ2TTLables = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Q2TTLables"	
	SetDimLabel 1,1,$"Tick Type",wQ2TTLables
	int iIntLables = 31
	Make/O/N=(iIntLables,2)/T $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Frac2IntLables"	
	Make/O/N=(iIntLables) $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Frac2IntTicks"
	wave wFrac2IntTicks = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Frac2IntTicks"
	wave/T wFrac2IntLables = $"root:COMBIgor:DiffractionRefs:"+sRefName+":"+sRefName+"_Frac2IntLables"
	SetDimLabel 1,1,$"Tick Type",wFrac2IntLables
	
	
	
	//populate Q-2-TT Waves
	int iTT
	int iTTOI = -1
	int iTTTick = 0
	iTTMin = floor(iTTMin/5)*5
	iTTMax = ceil(iTTMax/5)*5
	for(iTT=iTTMin;iTT<=iTTMax;iTT+=1)
		//find the TT index
		int iTTi
		for(iTTi=1;iTTi<dimsize(wRefProfile,0);iTTi+=1)
			variable vTT_pre = wRefProfile[iTTi-1][%TwoTheta]
			variable vTT_post = wRefProfile[iTTi][%TwoTheta]
			if(iTT==vTT_pre)
				iTTOI = iTTi-1
				break
			elseif(iTT==vTT_post)
				iTTOI = iTTi
				break
			elseif((iTT>vTT_pre)&&(iTT<vTT_post))
				if(abs(iTT-vTT_pre)<abs(iTT-vTT_post))
					iTTOI = iTTi-1
				else
					iTTOI = iTTi
				endif
			endif
		endfor
		if(iTTOI==-1||iTTOI==dimsize(wRefProfile,0))//not found, outside the range
			continue
		else
			//ticks (Q for this TT)
			wQ2TTTicks[iTTTick] = wRefProfile[iTTOI][%Q_2PiPerAng]
			if(mod(iTT,5)==0)//lable
				wQ2TTLables[iTTTick][0] = num2str(iTT)
				wQ2TTLables[iTTTick][1] = "Major"
			else
				wQ2TTLables[iTTTick][1] = "Minor"
				wQ2TTLables[iTTTick][0] = ""
			endif
			iTTTick+=1
		endif
		
	endfor	
	
	//populate the int 2 frac waves
	int iFInt
	int iOM
	int iExtra
	int iSigFigs = 2
	for(iFInt=0;iFInt<31;iFInt+=1)
		if(mod(iFInt,10)==0)
			iOM = (iFInt/10)-3
			string sLable
			sprintf sLable, "%.3G", ((10^iOM)*vIntMax)
			wFrac2IntLables[iFInt][0] = sLable
			wFrac2IntLables[iFInt][1] = "Major"
			wFrac2IntTicks[iFInt] = (10^iOM)
		else
			iOM = Floor(iFInt/10)-3
			iExtra = iFInt-(10*Floor(iFInt/10))
			wFrac2IntTicks[iFInt] = (10^iOM)*iExtra
			wFrac2IntLables[iFInt][0] = ""
			wFrac2IntLables[iFInt][1] = "Minor"
		endif
	endfor	

end
