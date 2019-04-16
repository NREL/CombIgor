#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "COMBIgor"
	"Install Package",/Q,InstallCOMBIgor()
end

Function InstallHDF5()

	//version check?
	string sIgorVersion = stringbykey("IGORVERS",IgorInfo(0))
	if(str2num(sIgorVersion)<8)
		DoAlert/T="Incorrect Igor version",0,"Sorry, Igor 8+ required"
		return  -1
	endif
	
	//check for 64 bit?
	string sIgorKind = stringbykey("IGORKIND",IgorInfo(0))
	if(!stringmatch(sIgorKind,"*64*"))
		DoAlert/T="Incorrect Igor version",0,"Sorry, Igor 64 bit required"
		return  -1
	endif
	
	string sTheUSerFiles = SpecialDirPath("Igor Pro User Files",0,0,0)
	string sTheXOPFolder = sTheUserFiles + "Igor Extensions (64-bit)"
	string sTheIgorFolder = sTheUserFiles + "Igor Procedures"
	string sTheIgorMainFolder = SpecialDirPath("Igor Application",0,0,0)
	
	string sWantedBrowserFile = sTheIgorMainFolder + "WaveMetrics Procedures:File Input Output:"+"HDF5 Browser.ipf"
	string sBrowserAlias2Make = sTheIgorFolder+":HDF5 Browser.ipf"
	CreateAliasShortcut/O/Z=2 sWantedBrowserFile as sBrowserAlias2Make
	
	string sWantedXOPFile = sTheIgorMainFolder + "More Extensions (64-bit):File Loaders:"+"HDF5-64.xop"
	string sXOPAlias2Make = sTheXOPFolder+":HDF5-64.xop"
	CreateAliasShortcut/O/Z=2 sWantedXOPFile as sXOPAlias2Make
	
	//string sWantedXOPFolder = sTheIgorMainFolder+"More Extensions (64-bit):File Loaders:"
	//CreateAliasShortcut/O/Z=2 sWantedXOPFolder+"HDF5-64.xop" as "HDF5-64.xop"
end

Function InstallCOMBIgor()

	//version check?
	string sIgorVersion = stringbykey("IGORVERS",IgorInfo(0))
	if(str2num(sIgorVersion)<8)
		DoAlert/T="Incorrect Igor version",0,"Sorry, Igor 8+ required"
		return  -1
	endif
	
	//check for 64 bit?
	string sIgorKind = stringbykey("IGORKIND",IgorInfo(0))
	if(!stringmatch(sIgorKind,"*64*"))
		DoAlert/T="Incorrect Igor version",0,"Sorry, Igor 64 bit required"
		return  -1
	endif
	
	//install type?
	string sInstallType = "Folder"
	prompt sInstallType, "Install Type:",popup, "Folder;Alias"
	string sHelp = "Folder type will copy these files to the destination, Alias type will keep the folder in place and make an alias to them."
	Doprompt/HELP=sHelp "Choose Install Type",sInstallType
	if(V_Flag)
		return -1
	endif
	
	//get paths
	pathinfo home
	string sThisExpPath =  S_Path	
	string sTheUSerFiles = SpecialDirPath("Igor Pro User Files",0,0,0)
	string sTheUserFolder = sTheUserFiles + "User Procedures"
	string sTheIgorFolder = sTheUserFiles + "Igor Procedures"
	string sWantedFolder = sTheUserFolder + ":COMBIgor"
	string sTheDesktop = SpecialDirPath("Desktop",0,0,0)
	string sWantedAlais = sTheIgorFolder + ":COMBIgor.ipf"
	string sLoadPath = ""
	NewPath/Z/Q/O pUserPath, sTheUserFolder
	NewPath/Z/Q/O pCOMBIgorHome, sThisExpPath
	string sTheFolderName, sTheAliasName
	int bAlias = 0
	
	//get COMBIgor files if alias with COMBIgor in the name exists in the User procedures folder
	String sFolderList = IndexedFile(pUserPath, -1, "????")
	int vTotalThings = itemsinlist(sFolderList), iThisThing,  iTheCOMBIgorFolder = -1
	for(iThisThing=0;iThisThing<vTotalThings;iThisThing+=1)
		if(stringmatch(stringfromlist(iThisThing,sFolderList),"*Combigor*"))
			GetFileFolderInfo/P=pUserPath/Q stringfromlist(iThisThing,sFolderList)
			If(V_isAliasShortcut==1)
				sLoadPath = S_aliasPath
				iTheCOMBIgorFolder = iThisThing
				bAlias = 1
				sTheAliasName = stringfromlist(iThisThing,sFolderList)
			endif
		endif
	endfor
	
	//get folders if not alias, and a folder exist with COMBIgor in the name in the User procedures folder 
	if(iTheCOMBIgorFolder==-1)
		sFolderList = IndexedDir(pUserPath, -1,0)
		vTotalThings = itemsinlist(sFolderList)
		for(iThisThing=0;iThisThing<vTotalThings;iThisThing+=1)
			if(stringmatch(stringfromlist(iThisThing,sFolderList),"*Combigor*"))
				iTheCOMBIgorFolder = iThisThing
				sTheFolderName = stringfromlist(iTheCOMBIgorFolder,sFolderList)
				sLoadPath = sTheUserFolder+":"+stringfromlist(iTheCOMBIgorFolder,sFolderList)+":"
			endif
		endfor
	endif
	
	//check it was found by looking for COMBIgor.ipf inside.
	if(iTheCOMBIgorFolder!=-1)
		NewPath/Q/O pTestPath, sLoadPath
		string sAllProcedures = IndexedFile(pTestPath, -1, ".ipf")
		if(whichlistitem("COMBIgor.ipf",sAllProcedures)==-1)
			iTheCOMBIgorFolder=-1		
		endif
	endif
	
	InstallHDF5()

	//not in folder, make new files
	if(iTheCOMBIgorFolder==-1)	
		
		if(stringmatch(sInstallType,"Folder"))//folder type
			CopyFolder/I=0/O/Z=2 sThisExpPath as sWantedFolder 
			CreateAliasShortcut/O/Z=2 sWantedFolder+":COMBIgor.ipf" as sWantedAlais
			
		elseif(stringmatch(sInstallType,"Alias"))//alias instal type
			CreateAliasShortcut/O/Z=2 sThisExpPath as sWantedFolder
			CreateAliasShortcut/O/Z=2 sThisExpPath+"COMBIgor.ipf" as sWantedAlais
			
		endif
		
	else //something in folder already
		if(stringmatch(sInstallType,"Folder"))//folder type
			
			if(bAlias==1)
				DoAlert/T="Alais Found!",0,"Old Alias placed on Desktop."
				CreateAliasShortcut/O/Z=2 sLoadPath as sTheDesktop+sTheAliasName
				DeleteFile/P=pUserPath sTheAliasName
				CopyFolder/I=0/O/Z=2 sThisExpPath as sWantedFolder 
				CreateAliasShortcut/O/Z=2 sWantedFolder+":COMBIgor.ipf" as sWantedAlais
			
			else
				DoAlert/T="Data Protection!",0,"Old folder moved onto desktop. Delete at will, I don't want to delete any work on accident."
				CopyFolder/I=0/O/Z=2 sLoadPath as sTheDesktop+"OLD COMBIGOR FOLDER" 
				DeleteFolder/Z=1 sLoadPath
				CopyFolder/I=0/O/Z=2 sThisExpPath as sWantedFolder 
				CreateAliasShortcut/O/Z=2 sWantedFolder+":COMBIgor.ipf" as sWantedAlais
			
			endif	
		elseif(stringmatch(sInstallType,"Alias"))//alias instal type
		
			if(bAlias==1)
				DoAlert/T="Alais Found!",0,"Old Alias placed on Desktop."
				CreateAliasShortcut/O/Z=2 sLoadPath as sTheDesktop+sTheAliasName
				DeleteFile/P=pUserPath sTheAliasName
				CreateAliasShortcut/O/Z=2 sThisExpPath as sWantedFolder
				CreateAliasShortcut/O/Z=2 sThisExpPath+"COMBIgor.ipf" as sWantedAlais
		
			else
				DoAlert/T="Data Protection!",0,"Old folder moved onto desktop. Delete at will, I don't want to delete any work on accident."
				CopyFolder/I=0/O/Z=2 sLoadPath as sTheDesktop+"OLD COMBIGOR FOLDER" 
				DeleteFolder/Z=1 sLoadPath
				CreateAliasShortcut/O/Z=2 sThisExpPath as sWantedFolder
				CreateAliasShortcut/O/Z=2 sThisExpPath+"COMBIgor.ipf" as sWantedAlais
			
			endif
		endif
	endif
	
	
	
	
	KillWindow/Z InstructionWindow
	
	NewNotebook/N=InstructionWindow/W=(10,10,610,210)/F=0/K=1 as "Mounting Instructions"
	Notebook InstructionWindow text= "\r!COMBIGOR INSTALLED!\r\r"
	Notebook InstructionWindow text= "The COMBIgor package must be mounted each time it is to be used.\r"
	Notebook InstructionWindow text= "Mount COMBIgor at anytime,in any experiment:\r\t"
	Notebook InstructionWindow text= "Data > Packages > COMBIgor\r\r"
	Notebook InstructionWindow text= "Learn about COMBIgor once mounted:\r\t COMBIgor > Help\r"

end