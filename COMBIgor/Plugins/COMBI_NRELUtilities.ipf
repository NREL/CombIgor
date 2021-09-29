#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Menu "COMBIgor"
	SubMenu "Plugins"
		SubMenu "NREL Utilities"
			 "(Cleaning Data"
			 "Remove Zero or Below",/Q, COMBI_NREL_Utilities_RemoveNegatives()
			 "-"
			 "(Library Manipulation"
			 "Rotate by 180 degree",/Q, COMBI_NREL_Utilities_Flip180()
			 "-"
			 "(Data Manipulation"
			 "TwoTheta-Q",/Q, COMBI_NREL_Utilities_CalcScattering()
		end
	end
end

//returns a list of descriptors for each of the globals used to define loading
Function/S NRELUtilities_Descriptions(sGlobalName)
	string sGlobalName
	wave/T twGlobals = $"root:Packages:COMBIgor:Instruments:COMBI_NRELUtilities_Globals"
	string sReturnstring =""
	strswitch(sGlobalName)
		case "FischerXRF":
			sReturnstring = "Fischer XRF"
			break
		case "InInstrumentMenu":
			twGlobals[1][0] = "Yes"
			break
		case "OnAccessPanel":
			twGlobals[2][0] = "No"
			break
		default:
			sReturnstring =  ""
			break
	endswitch
	twGlobals[0][0] = sReturnstring
	return sReturnstring
end



//by kevin talley
function COMBI_NREL_Utilities_RemoveNegatives()
	//choose Project
	string sProject = COMBI_ChooseProject()
	if(strlen(sProject)==0)
		return -1
	endif
	//choose library
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//choose wave type (Scalar or Vector)
	string sType = COMBI_StringPrompt("Scalar","Dimension","Scalar;Vector","","Data Dimension?")
	if(stringmatch(sType,"CANCEL"))
		return -1
	endif
	string sWave2OperateOn
	if(stringmatch(sType,"Scalar"))
		sWave2OperateOn = COMBI_DataTypePrompt(sProject,"Select Data Type!","Data:",0,0,0,1,sLibraries=sLibrary)
	elseif(stringmatch(sType,"Vector"))
		sWave2OperateOn = COMBI_DataTypePrompt(sProject,"Select Data Type!","Data:",0,0,0,2,sLibraries=sLibrary)
	endif
	if(stringmatch(sWave2OperateOn,"CANCEL"))
		return -1
	endif
	wave w2OperateOn = $COMBI_DataPath(sProject,1)+sLibrary+":"+sWave2OperateOn
	//operate
	int iSample, iVector
	if(stringmatch(sType,"Scalar"))
		for(iSample=0;iSample<dimsize(w2OperateOn,0);iSample+=1)
			if(w2OperateOn[iSample]<=0)
				w2OperateOn[iSample]=nan
			endif
		endfor
	elseif(stringmatch(sType,"Vector"))
		for(iSample=0;iSample<dimsize(w2OperateOn,0);iSample+=1)
			for(iVector=0;iVector<dimsize(w2OperateOn,1);iVector+=1)
				if(w2OperateOn[iSample][iVector]<=0)
					w2OperateOn[iSample][iVector]=nan
				endif
			endfor
		endfor
	endif	
end

//by kevin talley
function COMBI_NREL_Utilities_Flip180()
	//choose Project
	string sProject = COMBI_ChooseProject()
	if(strlen(sProject)==0)
		return -1
	endif
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	//choose library
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//choose wave type (Scalar or Vector)
	string sType = COMBI_StringPrompt("Scalar","Dimension","Scalar;Vector","","Data Dimension?")
	if(stringmatch(sType,"CANCEL"))
		return -1
	endif
	string sWave2OperateOn
	if(stringmatch(sType,"Scalar"))
		sWave2OperateOn = COMBI_DataTypePrompt(sProject,"Select Data Type!","Data:",0,0,0,1,sLibraries=sLibrary)
	elseif(stringmatch(sType,"Vector"))
		sWave2OperateOn = COMBI_DataTypePrompt(sProject,"Select Data Type!","Data:",0,0,0,2,sLibraries=sLibrary)
	endif
	if(stringmatch(sWave2OperateOn,"CANCEL"))
		return -1
	endif
	wave w2OperateOn = $COMBI_DataPath(sProject,1)+sLibrary+":"+sWave2OperateOn
	//operate
	duplicate w2OperateOn,root:PreRotated//duplicate the wave
	wave wOriginal = root:PreRotated
	int iCols = COMBI_GetGlobalNumber("vTotalColumns",sProject)
	int iRows = COMBI_GetGlobalNumber("vTotalRows",sProject)
	int iSamples = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	int iOCol,iORow,iCol,iRow,iSample,iOSample
	for(iOSample=0;iOSample<iSamples;iOSample+=1)
		iORow = wMappingGrid[iOSample][%Row]//original Row
		iOCol = wMappingGrid[iOSample][%Column]//original Column
		iRow = iRows - iORow + 1//new row
		iCol = iCols - iOCol + 1//new Column
		for(iSample=0;iSample<iSamples;iSample+=1)
			if(wMappingGrid[iSample][%Row]==(iRow)&&wMappingGrid[iSample][%Column]==(iCol))//find new sample index
				if(stringmatch(sType,"Scalar"))
					w2OperateOn[iSample] = wOriginal[iOSample]
				elseif(stringmatch(sType,"Vector"))
					w2OperateOn[iSample][] = wOriginal[iOSample][q]
				endif
			endif
		endfor
	endfor
	killwaves wOriginal//delete original copy
end

function COMBI_NREL_Utilities_CalcScattering()
	//choose Project
	string sProject = COMBI_ChooseProject()
	if(strlen(sProject)==0)
		return -1
	endif
	wave wMappingGrid = $"root:COMBIgor:"+sProject+":MappingGrid"
	//choose library
	string sLibrary = COMBI_LibraryPrompt(sProject,"Select Library!","Library:",0,0,0,1)
	if(stringmatch(sLibrary,"CANCEL"))
		return -1
	endif
	//choose wave type (Scalar or Vector)
	string sWave2OperateOn = COMBI_DataTypePrompt(sProject,"Select Data Type!","Data:",0,0,0,2,sLibraries=sLibrary)
	if(stringmatch(sWave2OperateOn,"CANCEL"))
		return -1
	endif
	wave w2OperateOn = $COMBI_DataPath(sProject,1)+sLibrary+":"+sWave2OperateOn
	//type to make
	variable vWavelength = 1.54
	string sType = COMBI_StringPrompt("TwoTheta","Make:","TwoTheta;Q","","Make What?")
	if(stringmatch(sType,"CANCEL"))
		return -1
	elseif(stringmatch(sType,"TwoTheta"))
		Combi_AddDataType(sProject,sLibrary,"TwoTheta_deg",2,iVDim=dimsize(w2OperateOn,1))
		wave wNewTT = $Combi_DataPath(sProject,2)+sLibrary+":TwoTheta_deg"
		wNewTT[][] = 360*asin((w2OperateOn[p][q]*vWavelength)/(4*Pi))/Pi
	elseif(stringmatch(sType,"Q"))
		Combi_AddDataType(sProject,sLibrary,"Q_2PiPerAng",2,iVDim=dimsize(w2OperateOn,1))
		wave wNewQ = $Combi_DataPath(sProject,2)+sLibrary+":Q_2PiPerAng"
		wNewQ = 4*Pi*Sin(w2OperateOn[p][q]/2)/vWavelength
	endif
	



end