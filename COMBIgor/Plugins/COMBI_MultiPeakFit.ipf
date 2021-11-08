#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// Version History
// V1: Kevin Talley _ April 2020 : Original Example Plugin based on work by Allison Mis



///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Constants Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Static StrConstant sPluginName = "MultiPeakFit"
Static StrConstant sPackageFolder = "root:Packages:COMBIgor:Plugins:MultiPeakFit:"
Static StrConstant sPackageGlobals = "root:Packages:COMBIgor:Plugins:COMBI_MultiPeakFit_Globals"
Static StrConstant sVersion = "1.0"

Static StrConstant sPanelWaves= "FWHM_LB_Panel;FWHM_UB_Panel;FWHM_Ep_Panel;FWHM_Panel;Pos_LB_Panel;Pos_UB_Panel;Pos_Ep_Panel;Pos_Panel;Amp_LB_Panel;Amp_UB_Panel;Amp_Ep_Panel;Amp_Panel;GFrac_LB_Panel;GFrac_UB_Panel;GFrac_Ep_Panel;GFrac_Panel;Tags_Panel"


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Menu Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This builds the drop-down menu for this plugin
Menu "COMBIgor"
	SubMenu "Plugins"
		 "Multi Peak Fitting",/Q, COMBI_MultiPeakFit()
	end
end

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//this function makes waves to hold fit informmation from the panel.
function MultiPeakFit_MakePanelWaves(iPeaks)
	int iPeaks
	int iPeak
	for(iPeak=0;iPeak<itemsInList(sPanelWaves);iPeak+=1)
			NewDataFolder/O $sPackageFolder+"PanelWaves"
			Make/O/N=(iPeaks)/T $sPackageFolder+"PanelWaves:"+stringfromlist(iPeak,sPanelWaves)
	endfor
	Make/O/N=(1,iPeaks,2) $sPackageFolder+"PanelWaves:PanelTraces"
end

//This function is run when the user selects the Plugin from the COMBIgor drop down menu once activated.
function COMBI_MultiPeakFit()

	//name for plugin panel
	string sWindowName=sPluginName+"_Panel"
	
	string sProject// name of COMBIgor project of interest
	string sLibrary// name of COMBIgor library of interest
	string sDepData// name of 2D wave containing dependant (y) data
	string sIndData// name of 2D wave containing independant (x) data
	
	string sXPosList// list of peak Centers in the independant data, separated by ';' 
	string sFWHMList// FHWM corresponding to each peak Center given in sXPosList, separated by ';' 
	string sAmpList// Amplitude corresponding to each peak Center given in sXPosList, separated by ';' 
	string sGFracList// Fraction Gaussian corresponding to each peak Center given in sXPosList, separated by ';' 
	string sXPosUBList// list of peak Center Tolerance for , separated by ';' 
	string sFWHMUBList// FHWM Tolerance corresponding to each peak Center given in sXPosList, separated by ';' 
	string sAmpUBList// Amplitude Tolerance corresponding to each peak Center given in sXPosList, separated by ';' 
	string sGFracUBList// Fraction Gaussian upper bound corresponding to each peak Center given in sXPosList, separated by ';' 
	string sXPosLBList// list of peak Center lower bound for , separated by ';' 
	string sFWHMLBList// FHWM lower bound corresponding to each peak Center given in sXPosList, separated by ';' 
	string sAmpLBList// Amplitude lower bound corresponding to each peak Center given in sXPosList, separated by ';' 
	string sGFracLBList// Fraction Gaussian lower bound corresponding to each peak Center given in sXPosList, separated by ';' 
	string sXPosEpList// list of peak Center episilon , separated by ';' 
	string sFWHMEpList// FHWM episilon corresponding to each peak Center given in sXPosList, separated by ';' 
	string sAmpEpList// Amplitude episilon corresponding to each peak Center given in sXPosList, separated by ';' 
	string sGFracEpList// Fraction Gaussian episilon corresponding to each peak Center given in sXPosList, separated by ';' 
	string sPeakTagList//names of all the peaks
	string sBKGRDOrder // poly order for background fit
	
	string sAmpScaleType// 0(default) for no scaled values, 1 for scale by max amp in library
	string sYScale//Linear or Log?
	string sPeaksPlotting// Plot option for adding peaks to the plot below
	string sTraceMode// Plot option for how refs are formatted
	
	variable vSampleStart// first sample in active range
	variable vSampleEnd// last sample in active range
	variable vWindowSize// number of points peak can be (+/-) from given x index Center; defaults to 10
	variable vFWHMGuess// initial guess for FWHM in pseudo-voigt fit; defaults to 4 points
	variable vGFracsGuess// initial guess for Gaussian vs Lorentzian weighting in pseudo-voigt fit; defaults to .5
	variable vEpsPoly// epsilon wave value for polynomial background terms in pseudo-voigt fit; defaults to 1e-9
	variable vEpsAmp// epsilon wave value for peak amplitude terms in pseudo-voigt fit; defaults to 1e-6
	variable vEpsFWHM// epsilon wave value for FWHM terms in pseudo-voigt fit; defaults to 1e-7
	variable vEpsCenter// epsilon wave value for peak location terms in pseudo-voigt fit; defaults to 1e-7
	variable vEpsGFracs// epsilon wave value for Gaussian vs Lorentzian weighting in pseudo-voigt fit; defaults to 1e-9
	variable vBgScaleLocation// wave index of intensity value to use to scale background area
	variable vDepMax// Max Dependant Data Value in the library
	variable vDepMin// Min Dependant Data Value in the library
	variable vIndMax// Max Independant Data Value in the library
	variable vIndMin// Min Independant Data Value in the library
	variable vPeaksToFit// the total number of peaks to fit. 
	
	int bMakeBackgroundTrace// a vector data set
	int bMakeFullFitTrace// a vector data set
	int bMakeTracePerPeak// a vector data set, one fore each peak, A trace of the fit
	int bMakeResidualsTrace// a vector data set, one fore each peak, A trace of the the fit - the data 
	int bMakePercentResidualsTrace// a vector data set, one fore each peak, A trace of the the (fit - the data)/data*100 
	int bOutputPosScalars// a scalar data set, one fore each peak, Center of the peak in X
	int bOutputAmpScalars// a scalar data set, one fore each peak, amplitude of the peak in Y
	int bOutputFWHMScalars// a scalar data set, one fore each peak, FWHM of the peak in X
	int bOutputGFracScalars// a scalar data set, one fore each peak, GFrac of the peak
	int bOutputPosScalarsErr// a scalar data set, one fore each peak, Center of the peak in X
	int bOutputAmpScalarsErr// a scalar data set, one fore each peak, amplitude of the peak in Y
	int bOutputFWHMScalarsErr// a scalar data set, one fore each peak, FWHM of the peak in X
	int bOutputGFracScalarsErr// a scalar data set, one fore each peak, GFrac of the peak
	int bOutputGOFScalars// a scalar data set, goodness of fit for the whole fit
	int bOutputPeakAreaScalars// a scalar data set, one fore each peak, area of the peak
	int bMakePlots// a plot of the raw data plus the fits. 
	int bSeeResiduals// a plot of the fit residuals. 
	
	//check if initialized, get starting values if so, initialize if not	
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")))//not yet initialized
		//globals inital values
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_ChooseProject(),"COMBIgor")
		//make data folder
		string sNewFolder = sPackageFolder[0,(strlen(sPackageFolder)-2)]
		NewDataFolder/O $sNewFolder
	endif
	//get the project
	sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	
	//if first time for this project, initialize values
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sProject)))
		COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,sProject)
		COMBI_GivePluginGlobal(sPluginName,"sLibrary","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vSampleStart","1",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vSampleEnd",COMBI_GetGlobalString("vTotalSamples",sProject),sProject)
		COMBI_GivePluginGlobal(sPluginName,"sDepData","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sIndData","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosUBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpUBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracUBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosLBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpLBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracLBList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosEpList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpEpList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracEpList","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sPeakTagList","",sProject)	
		COMBI_GivePluginGlobal(sPluginName,"vWindowSize","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vFWHMGuess","",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vGFracsGuess","0.5",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vEpsPoly","1E-9",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vEpsAmp","1E-6",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vEpsFWHM","1E-7",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vEpsCenter","1E-7",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vEpsGFracs","1E-9",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vBgScaleLocation","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpScaleType","None",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vDepMax","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vDepMin","inf",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vIndMax","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vIndMin","inf",sProject)
		COMBI_GivePluginGlobal(sPluginName,"vPeaksToFit","0",sProject)	
		COMBI_GivePluginGlobal(sPluginName,"sYScale","Linear",sProject)	
		COMBI_GivePluginGlobal(sPluginName,"sPeaksPlotting","Initial",sProject)	
		COMBI_GivePluginGlobal(sPluginName,"sTraceMode","Dots",sProject)	
		COMBI_GivePluginGlobal(sPluginName,"bMakeBackgroundTrace","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bMakeFullFitTrace","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bMakeTracePerPeak","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bMakeResidualsTrace","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputPosScalars","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputAmpScalars","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputFWHMScalars","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputGFracScalars","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputPosScalarsErr","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputAmpScalarsErr","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputFWHMScalarsErr","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputGFracScalarsErr","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputGOFScalars","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bOutputPeakAreaScalars","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bMakePlots","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bMakePercentResidualsTrace","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"bSeeResiduals","0",sProject)
		COMBI_GivePluginGlobal(sPluginName,"sBKGRDOrder","3",sProject)
				
	endif
	
	// data waves
	string sSubProject
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	sDepData = COMBI_GetPluginString(sPluginName,"sDepData",sProject)
	sIndData = COMBI_GetPluginString(sPluginName,"sIndData",sProject)
	vSampleStart = COMBI_GetPluginNumber(sPluginName,"vSampleStart",sProject)
	vSampleEnd = COMBI_GetPluginNumber(sPluginName,"vSampleEnd",sProject)
	wave/Z wXWave = $COMBI_DataPath(COMBI_GetPluginString(sPluginName,"sProject",sProject),2)+COMBI_GetPluginString(sPluginName,"sLibrary",sProject)+":"+COMBI_GetPluginString(sPluginName,"sIndData",sProject)
	wave/Z wYWave = $COMBI_DataPath(COMBI_GetPluginString(sPluginName,"sProject",sProject),2)+COMBI_GetPluginString(sPluginName,"sLibrary",sProject)+":"+COMBI_GetPluginString(sPluginName,"sDepData",sProject)
	if(waveExists(wYWave)&&WaveExists(wXWave))//data exist,must be fully defined
		string sFolder2Check
		if(stringmatch(COMBI_GetPluginString(sPluginName,"sProject",sProject),COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")))
			sFolder2Check = sProject+"-"+sLibrary+"-"+sDepData+"-"+sIndData
		else
			sFolder2Check = sProject
		endif
		if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sFolder2Check)))//not defined before, new
			sSubProject = sProject+"-"+sLibrary+"-"+sDepData+"-"+sIndData
			//mark sample range
			COMBI_GivePluginGlobal(sPluginName,"vSampleStart",num2str(vSampleStart),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vSampleEnd",num2str(vSampleEnd),sSubProject)
			//find extremes
			vDepMax = Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Max")
			vDepMin = Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Min")
			vIndMax = Combi_Extremes(sProject,2,sIndData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Max")
			vIndMin = Combi_Extremes(sProject,2,sIndData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Min")
			variable vIndRange = vIndMax - vIndMin
			variable vDepRange = vDepMax-vDepMin
			COMBI_GivePluginGlobal(sPluginName,"vIndRange",num2str(vIndRange),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vDepRange",num2str(vDepRange),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vDepMax",num2str(vDepMax),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vDepMin",num2str(vDepMin),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vIndMax",num2str(vIndMax),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vIndMin",num2str(vIndMin),sSubProject)
			//get scaling
			COMBI_GivePluginGlobal(sPluginName,"vDeltaX",num2str(wXWave[(vSampleStart-1)][1]-wXWave[(vSampleStart-1)][0]),sSubProject)
			//default values for fitting
			vWindowSize = 10*(wXWave[(vSampleStart-1)][1]-wXWave[(vSampleStart-1)][0])
			vFWHMGuess = 5*(wXWave[(vSampleStart-1)][1]-wXWave[(vSampleStart-1)][0])
			vBgScaleLocation  = wXWave[(vSampleStart-1)][0]
			COMBI_GivePluginGlobal(sPluginName,"vWindowSize",num2str(vWindowSize),sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vFWHMGuess",num2str(vFWHMGuess),sSubProject)	
			COMBI_GivePluginGlobal(sPluginName,"vBgScaleLocation",num2str(vBgScaleLocation),sSubProject)		
			//set others 
			COMBI_GivePluginGlobal(sPluginName,"sProject",sProject,sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sLibrary",sLibrary,sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sDepData",sDepData,sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sIndData",sIndData,sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sXPosList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sFWHMList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sAmpList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sGFracList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sXPosUBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sAmpUBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sGFracUBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sXPosLBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sAmpLBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sGFracLBList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sXPosEpList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sAmpEpList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sGFracEpList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sPeakTagList","",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vGFracsGuess","0.5",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vEpsPoly","1E-9",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vEpsAmp","1E-6",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vEpsFWHM","1E-7",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vEpsCenter","1E-7",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vEpsGFracs","1E-9",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sAmpScaleType","None",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"vPeaksToFit","0",sSubProject)	
			COMBI_GivePluginGlobal(sPluginName,"sYScale","Linear",sSubProject)	
			COMBI_GivePluginGlobal(sPluginName,"sPeaksPlotting","Initial",sSubProject)	
			COMBI_GivePluginGlobal(sPluginName,"sTraceMode","Dots",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bMakeBackgroundTrace","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bMakeFullFitTrace","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bMakeTracePerPeak","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bMakeResidualsTrace","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputPosScalars","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputAmpScalars","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputFWHMScalars","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputGFracScalars","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputPosScalarsErr","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputAmpScalarsErr","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputFWHMScalarsErr","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputGFracScalarsErr","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputGOFScalars","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bOutputPeakAreaScalars","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bMakePlots","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bMakePercentResidualsTrace","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"bSeeResiduals","0",sSubProject)
			COMBI_GivePluginGlobal(sPluginName,"sBKGRDOrder","3",sSubProject)
		endif
		sSubProject = sFolder2Check
		COMBI_GivePluginGlobal(sPluginName,"sProject",sSubProject,"COMBIgor")
		sProject = COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
		
	else
		sSubProject = sProject
	endif
	
	//get project values
	sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)
	sDepData = COMBI_GetPluginString(sPluginName,"sDepData",sSubProject)
	sIndData = COMBI_GetPluginString(sPluginName,"sIndData",sSubProject)
	vSampleStart = COMBI_GetPluginNumber(sPluginName,"vSampleStart",sSubProject)
	vSampleEnd = COMBI_GetPluginNumber(sPluginName,"vSampleEnd",sSubProject)
	sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
	sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
	sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
	sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
	sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
	sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
	sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
	sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
	sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
	sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
	sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
	sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
	sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
	sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
	sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
	sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
	sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
	vWindowSize = COMBI_GetPluginNumber(sPluginName,"vWindowSize",sSubProject)
	vFWHMGuess = COMBI_GetPluginNumber(sPluginName,"vFWHMGuess",sSubProject)
	vGFracsGuess = COMBI_GetPluginNumber(sPluginName,"vGFracsGuess",sSubProject)
	vEpsPoly = COMBI_GetPluginNumber(sPluginName,"vEpsPoly",sSubProject)
	vEpsAmp = COMBI_GetPluginNumber(sPluginName,"vEpsAmp",sSubProject)
	vEpsFWHM = COMBI_GetPluginNumber(sPluginName,"vEpsFWHM",sSubProject)
	vEpsCenter = COMBI_GetPluginNumber(sPluginName,"vEpsCenter",sSubProject)
	vEpsGFracs = COMBI_GetPluginNumber(sPluginName,"vEpsGFracs",sSubProject)
	vBgScaleLocation = COMBI_GetPluginNumber(sPluginName,"vBgScaleLocation",sSubProject)
	sAmpScaleType = COMBI_GetPluginString(sPluginName,"sAmpScaleType",sSubProject)
	vDepMax = COMBI_GetPluginNumber(sPluginName,"vDepMax",sSubProject)
	vDepMin = COMBI_GetPluginNumber(sPluginName,"vDepMin",sSubProject)
	vIndMax = COMBI_GetPluginNumber(sPluginName,"vIndMax",sSubProject)
	vIndMin = COMBI_GetPluginNumber(sPluginName,"vIndMin",sSubProject)
	vDepRange = COMBI_GetPluginNumber(sPluginName,"vDepRange",sSubProject)
	vIndRange = COMBI_GetPluginNumber(sPluginName,"vIndRange",sSubProject)
	vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)
	sYScale = COMBI_GetPluginString(sPluginName,"sYScale",sSubProject)
	sPeaksPlotting = COMBI_GetPluginString(sPluginName,"sPeaksPlotting",sSubProject)
	sTraceMode = COMBI_GetPluginString(sPluginName,"sTraceMode",sSubProject)
	bMakeBackgroundTrace = COMBI_GetPluginNumber(sPluginName,"bMakeBackgroundTrace",sSubProject)
	bMakeFullFitTrace = COMBI_GetPluginNumber(sPluginName,"bMakeFullFitTrace",sSubProject)
	bMakeTracePerPeak = COMBI_GetPluginNumber(sPluginName,"bMakeTracePerPeak",sSubProject)
	bMakeResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakeResidualsTrace",sSubProject)
	bMakePercentResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakePercentResidualsTrace",sSubProject)
	bOutputPosScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	bOutputAmpScalars = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	bOutputFWHMScalars = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	bOutputGFracScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	bOutputPosScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	bOutputAmpScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	bOutputFWHMScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	bOutputGFracScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	bOutputGOFScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGOFScalars",sSubProject)
	bOutputPeakAreaScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPeakAreaScalars",sSubProject)
	bMakePlots = COMBI_GetPluginNumber(sPluginName,"bMakePlots",sSubProject)
	bSeeResiduals = COMBI_GetPluginNumber(sPluginName,"bSeeResiduals",sSubProject)
	sBKGRDOrder = COMBI_GetPluginString(sPluginName,"sBKGRDOrder",sSubProject)

	//get the globals wave for use in panel building, mainly set varaible controls
	wave/T twGlobals = $sPackageGlobals
	wave/T wMapping = $"root:COMBIgor:"+sProject+":MappingGrid"
	MultiPeakFit_MakePanelWaves(vPeaksToFit)
	MultiPeakFit_PopPanelWaves(sSubProject)//populate panel waves
	wave/T wFWHM = $sPackageFolder+"PanelWaves:FWHM_Panel"
	wave/T wPos = $sPackageFolder+"PanelWaves:Pos_Panel"
	wave/T wAmp = $sPackageFolder+"PanelWaves:Amp_Panel"
	wave/T wGFrac = $sPackageFolder+"PanelWaves:GFrac_Panel"
	wave/T wFWHM_UB = $sPackageFolder+"PanelWaves:FWHM_UB_Panel"
	wave/T wPos_UB = $sPackageFolder+"PanelWaves:Pos_UB_Panel"
	wave/T wAmp_UB = $sPackageFolder+"PanelWaves:Amp_UB_Panel"
	wave/T wGFrac_UB = $sPackageFolder+"PanelWaves:GFrac_UB_Panel"
	wave/T wFWHM_LB = $sPackageFolder+"PanelWaves:FWHM_LB_Panel"
	wave/T wPos_LB = $sPackageFolder+"PanelWaves:Pos_LB_Panel"
	wave/T wAmp_LB = $sPackageFolder+"PanelWaves:Amp_LB_Panel"
	wave/T wGFrac_LB = $sPackageFolder+"PanelWaves:GFrac_LB_Panel"
	wave/T wFWHM_Ep = $sPackageFolder+"PanelWaves:FWHM_Ep_Panel"
	wave/T wPos_Ep = $sPackageFolder+"PanelWaves:Pos_Ep_Panel"
	wave/T wAmp_Ep = $sPackageFolder+"PanelWaves:Amp_Ep_Panel"
	wave/T wGFrac_Ep = $sPackageFolder+"PanelWaves:GFrac_Ep_Panel"
	wave/T wTags = $sPackageFolder+"PanelWaves:Tags_Panel"
	wave wTraces = $sPackageFolder+"PanelWaves:PanelTraces"
	
	
	//make panel Center if old existed
	//kill if open already
	variable vWinLeft = 10
	variable vWinTop = 10
	//dimensions of panel
	variable vPanelHeight = 100
	variable vPanelWidth = 600
	string sAllWindows = WinList(sWindowName,";","")
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIGor")
	
	PauseUpdate; Silent 2// pause for building window...
	if(strlen(sAllWindows)>0)
		GetWindow/Z $sWindowName wsize
		vWinLeft = V_left
		vWinTop = V_top
		killwindow $sWindowName
	endif
	
	//make panel
	NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "MultiPeak Fitting"
	ModifyPanel/W=$sWindowName fixedSize=1
	SetDrawLayer/W=$sWindowName UserBack
	SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
	
	int iSample,iLibrary,iRow,iColumn,iLayer,iChunk
 	variable vYValue = 20
	
	//line
	SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 100,vYValue, "Select Data"
	SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 400,vYValue, "Options & Defaults"
	DrawLine 0,vYValue,50,vYValue
	DrawLine 150,vYValue,300,vYValue
	DrawLine 500,vYValue,600,vYValue
	DrawLine 200,vYValue,200,vYValue+120
	vYValue+=25
	
	//Project select
	DrawText/W=$sWindowName 70,vYValue, "Project:"
	PopupMenu sProject,pos={145,vYValue-10},mode=1,align=0,bodyWidth=120,value=COMBI_Projects(),proc=MultiPeakFit_UpdateGlobal,popvalue=COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
	vYValue+=20
	
	//Library select
	DrawText/W=$sWindowName 70,vYValue, "Library:"
	PopupMenu sLibrary,pos={145,vYValue-10},mode=1,align=0,bodyWidth=120,value=MultiPeakFit_DropList("Libraries"),proc=MultiPeakFit_UpdateGlobal,popvalue=sLibrary
	vYValue+=20
	
	//X Data select
	DrawText/W=$sWindowName 70,vYValue, "Data(y):"
	PopupMenu sDepData,pos={145,vYValue-10},mode=1,align=0,bodyWidth=120,value=MultiPeakFit_DropList("DataTypes"),proc=MultiPeakFit_UpdateGlobal,popvalue=sDepData
	vYValue+=20
	
	//Y Data select
	DrawText/W=$sWindowName 70,vYValue, "Data(x):"
	PopupMenu sIndData,pos={145,vYValue-10},mode=1,align=0,bodyWidth=120,value=MultiPeakFit_DropList("DataTypes"),proc=MultiPeakFit_UpdateGlobal,popvalue=sIndData
	vYValue+=20
	
	////Sample range
	DrawText/W=$sWindowName 70,vYValue, "Samples:"
	DrawText/W=$sWindowName 135,vYValue, " - "
	SetVariable vSampleStart, title=" ",pos={72,vYValue-10},size={50,50},fsize=12,live=0,font=sFont,value=twGlobals[%vSampleStart][%$sSubProject]
	SetVariable vSampleEnd, title=" ",pos={142,vYValue-10},size={50,50},fsize=12,live=0,font=sFont,value=twGlobals[%vSampleEnd][%$sSubProject]	
	int iFirstSample = str2num(twGlobals[%vSampleStart][%$sSubProject])
	int iLastSample = str2num(twGlobals[%vSampleEnd][%$sSubProject])
	vYValue+=20
	
	//col3
	vYValue-=100
	
	DrawText/W=$sWindowName 480,vYValue, "Amp(ε):"
	SetVariable vEpsAmp, title=" ",pos={482,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vEpsAmp][%$sSubProject];vYValue+=20
	
	DrawText/W=$sWindowName 480,vYValue, "BKGD(ε):"
	SetVariable vEpsPoly, title=" ",pos={482,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vEpsPoly][%$sSubProject];vYValue+=20

	DrawText/W=$sWindowName 480,vYValue, "Center(ε):"
	SetVariable vEpsCenter, title=" ",pos={482,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vEpsCenter][%$sSubProject];vYValue+=20
	
	DrawText/W=$sWindowName 480,vYValue, "FWHM(ε):"
	SetVariable vEpsFWHM, title=" ",pos={482,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vEpsFWHM][%$sSubProject];vYValue+=20
	
	DrawText/W=$sWindowName 480,vYValue, "GFrac(ε):"
	SetVariable vEpsGFracs, title=" ",pos={482,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vEpsGFracs][%$sSubProject];vYValue+=20
		
	//col2
	vYValue-=100
	
	DrawText/W=$sWindowName 290,vYValue, "Scale Type:"
	PopupMenu sAmpScaleType,pos={343,vYValue-10},mode=1,align=0,bodyWidth=100,value="None;Library Max Normalized;Sample Max Normalized;Scale;Shift",proc=MultiPeakFit_UpdateGlobal,popvalue=sAmpScaleType;vYValue+=20		
	
	if(stringmatch(sAmpScaleType,"Scale")||stringmatch(sAmpScaleType,"Shift"))
		DrawText/W=$sWindowName 290,vYValue, "@ X = "
		SetVariable vBgScaleLocation, title=" ",pos={292,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vBgScaleLocation][%$sSubProject];
	endif
	vYValue+=20

	DrawText/W=$sWindowName 290,vYValue, "Center(+/-):"
	SetVariable vWindowSize, title=" ",pos={292,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vWindowSize][%$sSubProject];vYValue+=20
	
	DrawText/W=$sWindowName 290,vYValue, "FWHM:"
	SetVariable vFWHMGuess, title=" ",pos={292,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vFWHMGuess][%$sSubProject];vYValue+=20
	
	DrawText/W=$sWindowName 290,vYValue, "GFrac:"
	SetVariable vGFracsGuess, title=" ",pos={292,vYValue-10},size={100,50},fsize=12,live=0,font=sFont,value=twGlobals[%vGFracsGuess][%$sSubProject];vYValue+=20
	
	//plot of data
	if(waveExists(wYWave)&&WaveExists(wXWave))
		killwindow/Z $sWindowName#DataPlot
		//line
		vYValue+=5
		SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 300,vYValue, "Data To Fit"
		DrawLine 0,vYValue,250,vYValue
		DrawLine (vPanelWidth-250),vYValue,vPanelWidth,vYValue
		vYValue+=25
		//plotting options
		DrawText/W=$sWindowName 70,vYValue, "Y Scale:"
		PopupMenu sYScale,pos={123,vYValue-10},mode=1,align=0,bodyWidth=100,value="Linear;Log",proc=MultiPeakFit_UpdateGlobal,popvalue=sYScale		
		DrawText/W=$sWindowName 280,vYValue, "Peak Plotting:"
		PopupMenu sPeaksPlotting,pos={333,vYValue-10},mode=1,align=0,bodyWidth=100,value="Initial;Center Window;FWHM Window;Markers;None",proc=MultiPeakFit_UpdateGlobal,popvalue=sPeaksPlotting
		DrawText/W=$sWindowName 480,vYValue, "Trace Mode:"
		PopupMenu sTraceMode,pos={533,vYValue-10},mode=1,align=0,bodyWidth=100,value="Dots;Lines;Both",proc=MultiPeakFit_UpdateGlobal,popvalue=sTraceMode;vYValue+=20		
		vYValue-=10
		//plot first trace
		Display/HOST=$sWindowName/W=(0,vYValue,vPanelWidth,vYValue+300)/N=DataPlot wYWave[iFirstSample][]/TN=$"Sample"+num2str(iFirstSample) vs wXWave[iFirstSample][]
		SetWindow $sWindowName activeChildFrame=0
		string sColor = COMBI_GetUniqueColor(1,(vSampleEnd-vSampleStart+1),sColorTheme="BlueRedGreen256")
		Execute "ModifyGraph/W="+sWindowName+"#DataPlot rgb(Sample"+num2str(iFirstSample)+")="+sColor
		SetAxis/W=$sWindowName#DataPlot bottom vIndMin-(0.05*vIndRange),vIndMax+(0.05*vIndRange)
		SetAxis/W=$sWindowName#DataPlot left vDepMin,vDepMax
		
		for(iSample=(iFirstSample+1);iSample<=iLastSample;iSample+=1)
			AppendToGraph/W=$sWindowName#DataPlot wYWave[iSample][]/TN=$"Sample"+num2str(iSample) vs wXWave[iSample][]
			sColor = COMBI_GetUniqueColor((iSample-iFirstSample+1),(vSampleEnd-vSampleStart+1),sColorTheme="BlueRedGreen256")
			Execute "ModifyGraph/W="+sWindowName+"#DataPlot rgb(Sample"+num2str(iSample)+")="+sColor
		endfor
		if(stringmatch(sYScale,"Log"))
			if(vDepMin>0)
				ModifyGraph log(left)=1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
			endif
		endif
		if(stringmatch(sTraceMode,"Dots"))
			ModifyGraph/W=$sWindowName#DataPlot mode=2
		elseif(stringmatch(sTraceMode,"Lines"))
			ModifyGraph/W=$sWindowName#DataPlot mode=0
		elseif(stringmatch(sTraceMode,"Both"))
			ModifyGraph/W=$sWindowName#DataPlot mode=4,marker=19,msize=1,lsize=0.5
		endif
		Label/W=$sWindowName#DataPlot left sDepData+" \u"
		Label/W=$sWindowName#DataPlot bottom sIndData+" \u"
		ModifyGraph/W=$sWindowName#DataPlot margin(left)=50,margin(bottom)=50,margin(right)=20,margin(top)=50,gbRGB=(65535.,65535.,65535.),wbRGB=(61166,61166,61166),gFont=sFont,gfsize=12
		ModifyGraph/W=$sWindowName#DataPlot grid=0,mirror=2,fsize=12,lblMargin=5,gridStyle=5,gridRGB=(34952,34952,34952),tick=1,mirror=1,highTrip=1,notation=1,nticks(bottom)=10,minor(bottom)=1
		//set cursor
		Cursor/C=(65535,0,0)/W=$sWindowName#DataPlot/A=1/H=1/P/F/L=0/N=0/T=1 A $"Sample"+num2str(iFirstSample) 0.025,0.05
		vYValue+=320
		SetActiveSubwindow $sWindowName 
		
		//add peaks to the plot
		int iPeak
		for(iPeak=0;iPeak<dimsize(wPos,0);iPeak+=1)		
			variable vIntTop = str2num(wAmp_UB[iPeak])
			variable vIntBottom = str2num(wAmp_LB[iPeak])
			variable vInt = str2num(wAmp[iPeak])
			variable vPosLeft = str2num(wPos_LB[iPeak])
			variable vPosRight =	str2num(wPos_UB[iPeak])
			variable vPos =	str2num(wPos[iPeak])
			variable vFWHMLeft = vPos-str2num(wFWHM[iPeak])
			variable vFWHMRight = vPos+str2num(wFWHM[iPeak])
			variable vFWHMLeftUB = vPos-str2num(wFWHM_UB[iPeak])/2 
			variable vFWHMRightUB = vPos+str2num(wFWHM_UB[iPeak])/2
			variable vFWHMLeftLB = vPos-str2num(wFWHM_LB[iPeak])/2 
			variable vFWHMRightLB = vPos+str2num(wFWHM_LB[iPeak])/2
			
			vIntTop = min(vIntTop,vDepMax)
			vIntBottom = max(vIntBottom,vDepMin)
			vPosLeft = max(vPosLeft,vIndMin)
			vPosRight = min(vPosRight,vIndMax)		
			vFWHMLeft = min(vFWHMLeft,vIndMax)	
			vFWHMRight = min(vFWHMRight,vIndMax)	
			vFWHMLeftUB = min(vFWHMLeftUB,vIndMax)	
			vFWHMRightUB = min(vFWHMRightUB,vIndMax)	
			vFWHMLeftLB = min(vFWHMLeftLB,vIndMax)	
			vFWHMRightLB = min(vFWHMRightLB,vIndMax)	
			
			
			//Center Window;FWHM Window;Amp Window;All;Markers;None
			if(stringmatch(sPeaksPlotting,"Center Window"))
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,dash= 2,fillpat= 1,fillbgc=(65535,0,0,16384),fillfgc=(65535,0,0,16384)
				DrawRect/W=$sWindowName#DataPlot vPosLeft,vIntBottom,vPosRight,vIntTop
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,textxjust= 1,fname=sFont,textrot= 90
				DrawText/W=$sWindowName#DataPlot str2num(wPos[iPeak]),vIntTop,"  "+wTags[iPeak]
			
			elseif(stringmatch(sPeaksPlotting,"FWHM Window"))
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,dash= 2,fillpat= 1,fillbgc=(2,39321,1,16384),fillfgc=(2,39321,1,16384)
				DrawRect/W=$sWindowName#DataPlot vFWHMLeft,vIntBottom,vFWHMRight,vIntTop
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,textxjust= 1,fname=sFont,textrot= 90
				DrawText/W=$sWindowName#DataPlot str2num(wPos[iPeak]),vIntTop,"  "+wTags[iPeak]
						
			elseif(stringmatch(sPeaksPlotting,"Markers"))
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,textrgb= (0,0,0),textxjust= 1,textyjust= 1,fsize= 10
				DrawText/W=$sWindowName#DataPlot vPos,vInt,"\\W5018"
				//name
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,textxjust= 1,fname=sFont,textrot= 45
				DrawText/W=$sWindowName#DataPlot vPos,vInt,"  "+wTags[iPeak]
				//vert lines
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,linefgc= (0,0,0), dash= 2
				DrawLine/W=$sWindowName#DataPlot vPos,vIntTop,vPos,vIntBottom
				//hoz line
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,linefgc= (0,0,0), dash= 2
				DrawLine/W=$sWindowName#DataPlot vPosLeft,vInt,vPosRight,vInt
				
			elseif(stringmatch(sPeaksPlotting,"Initial"))
				//make display wave
				AppendToGraph/W=$sWindowName#DataPlot/L/B wTraces[][iPeak][1]/TN=$wTags[iPeak] vs wTraces[][iPeak][0]
				string sThisPeakColor = COMBI_GetUniqueColor(iPeak+1,vPeaksToFit,sColorTheme="Rainbow")
				ModifyGraph/W=$sWindowName#DataPlot mode($wTags[iPeak])=7,hbFill($wTags[iPeak])=5
				Execute "ModifyGraph/W="+sWindowName+"#DataPlot rgb("+wTags[iPeak]+")="+sThisPeakColor
				
				//name
				SetDrawEnv/W=$sWindowName#DataPlot xcoord= bottom,ycoord= left,textxjust= 1,fname=sFont,textrot= 90
				DrawText/W=$sWindowName#DataPlot vPos,vInt,"  "+wTags[iPeak]
				
			endif
		endfor
		
		if(vPeaksToFit==0)//buttons on first panel
			//line
			SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 300	,vYValue, "Peak Details"
			DrawLine 0,vYValue,250,vYValue
			DrawLine 350,vYValue,600,vYValue
			vYValue+=20
			
			//help
			SetDrawEnv textxjust=1,fstyle=2,fsize= 10;DrawText 300,vYValue, "Use the buttons below here to add a peak from the cursor, or from a XRD reference."
			vYValue+=40
			
			//Add Peak button
			button bAddPeak,title="From Cursor",appearance={native,All},pos={60,vYValue-25},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12	

			//add from ref	
			if(COMBI_CheckForPlugin("DiffractionRefs")==1)
				button bFromRef,title="Add From Ref",appearance={native,All},pos={240,vYValue-25},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			else
				button bFromRef,title="Add From Ref",disable=2,appearance={native,All},pos={240,vYValue-25},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			endif
			
			button bFromLib,title="From Previous",appearance={native,All},pos={420,vYValue-25},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12

			
			
		endif
		
		//resize first panel
		moveWindow/W=$sWindowName vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vYValue

		
		//transition to second panel
		sWindowName = "MultiPeakFitPeakDefs"
		vWinLeft = vWinLeft+vPanelWidth
		vWinTop = vWinTop
		vPanelWidth = 820
		vPanelHeight = 60
		sAllWindows = WinList(sWindowName,";","")
		if(strlen(sAllWindows)>1)
			GetWindow/Z $sWindowName wsize
			vWinLeft = V_left
			vWinTop = V_top
			KillWindow/Z $sWindowName
		endif
		
		if(vPeaksToFit>0)
			
			//make panel for peak definition
			NewPanel/K=(COMBI_GetGlobalNumber("vKillOption","COMBIgor"))/W=(vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vPanelHeight)/N=$sWindowName as "Peak Definitions"
			ModifyPanel/W=$sWindowName fixedSize=1
			SetDrawLayer/W=$sWindowName UserBack
			SetDrawEnv/W=$sWindowName fname = sFont, textxjust = 2,textyjust = 1, fsize = 12, save
			vYValue = 15
			
			//help
			SetDrawEnv textxjust=1,fstyle=2,fsize= 10;DrawText 350,vYValue, "Use the buttons below here to add, remove, or update peaks."
			vYValue+=20
	
			//Add Peak button
			button bAddPeak,title="From Cursor",appearance={native,All},pos={40,vYValue-10},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12	
			//update Peak button
			button bUpdatePeaks,title="Update Peaks",appearance={native,All},pos={190,vYValue-10},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12	
			//Remove a peak button
			button bRemovePeak,title="Remove Peak",appearance={native,All},pos={340,vYValue-10},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12	
			//add from ref	
			if(COMBI_CheckForPlugin("DiffractionRefs")==1)
				button bFromRef,title="Add From Ref",appearance={native,All},pos={490,vYValue-10},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			else
				button bFromRef,title="Add From Ref",disable=2,appearance={native,All},pos={490,vYValue-10},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			endif
			//add from another library 
			button bFromLib,title="From Previous",appearance={native,All},pos={640,vYValue-10},size={120,20},proc=MultiPeakFit_Button,font=sFont,fstyle=1,fColor=(21845,21845,21845),fsize=12
			vYValue+=20
			
			//line
			SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 400	,vYValue, "Peak Details"
			DrawLine 0,vYValue,360,vYValue
			DrawLine 460,vYValue,vPanelWidth,vYValue
			vYValue+=20
			
			//help
			SetDrawEnv textxjust=1,fstyle=2,fsize= 10;DrawText 410,vYValue, "If you change these values, you must click \"Update Peaks\" above to store the changes. The changes will be relfecting in the plot on the other panel then."
			vYValue+=20
			
			SetDrawEnv/W=$sWindowName fstyle= 1,textxjust=1;DrawText/W=$sWindowName 60 ,vYValue, "Name"
			SetDrawEnv/W=$sWindowName textrgb= (65535,0,0),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 182.5,vYValue, "Center"
			SetDrawEnv/W=$sWindowName textrgb= (65535,0,0),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 265,vYValue, "ε"
			SetDrawEnv/W=$sWindowName textrgb= (2,39321,1),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 355,vYValue, "FWHM"
			SetDrawEnv/W=$sWindowName textrgb= (2,39321,1),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 440,vYValue, "ε"
			SetDrawEnv/W=$sWindowName textrgb= (0,0,655350),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 530,vYValue, "Amp"
			SetDrawEnv/W=$sWindowName textrgb= (0,0,655350),fstyle= 1,textxjust=1;DrawText/W=$sWindowName   612.5,vYValue, "ε"
			SetDrawEnv/W=$sWindowName textrgb= (65535,0,65535),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 705,vYValue, "GFraction"
			SetDrawEnv/W=$sWindowName textrgb= (65535,0,65535),fstyle= 1,textxjust=1;DrawText/W=$sWindowName 787.5,vYValue, "ε"
			vYValue+=20
		
			//make peak reads
			variable vXbump = -5
			for(iPeak=0;iPeak<dimsize(wPos,0);iPeak+=1)
				//name
				SetVariable $"Tag_"+num2str(iPeak), title=" ",pos={10,vYValue-10},size={100,40},fsize=10,live=0,font=sFont,value=wTags[iPeak],frame=1
				//pos
				SetVariable $"Center_LB_"+num2str(iPeak), title=" ",pos={vXbump+123,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wPos_LB[iPeak],frame=1
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 165+vXbump,vYValue-2, "<"
				SetVariable $"Center_"+num2str(iPeak), title=" ",pos={vXbump+167,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wPos[iPeak],frame=1,valueColor=(65535,0,0)
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 211+vXbump,vYValue-2, "<"
				SetVariable $"Center_UB_"+num2str(iPeak), title=" ",pos={vXbump+211,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wPos_UB[iPeak],frame=1
				SetVariable $"Center_Ep_"+num2str(iPeak), title=" ",pos={vXbump+250,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wPos_Ep[iPeak],frame=1

				//FWHM
				vXbump+=175
				SetVariable $"FWHM_LB_"+num2str(iPeak), title=" ",pos={vXbump+123,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wFWHM_LB[iPeak],frame=1
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 165+vXbump,vYValue-2, "<"
				SetVariable $"FWHM_"+num2str(iPeak), title=" ",pos={vXbump+167,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wFWHM[iPeak],frame=1,valueColor=(2,39321,1)
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 211+vXbump,vYValue-2, "<"
				SetVariable $"FWHM_UB_"+num2str(iPeak), title=" ",pos={vXbump+211,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wFWHM_UB[iPeak],frame=1
				SetVariable $"FWHM_Ep_"+num2str(iPeak), title=" ",pos={vXbump+250,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wFWHM_Ep[iPeak],frame=1

				//Amp
				vXbump+=175
				SetVariable $"Amp_LB_"+num2str(iPeak), title=" ",pos={vXbump+123,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wAmp_LB[iPeak],frame=1
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 165+vXbump,vYValue-2, "<"
				SetVariable $"Amp_"+num2str(iPeak), title=" ",pos={vXbump+167,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wAmp[iPeak],frame=1,valueColor=(0,0,655350)
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 211+vXbump,vYValue-2, "<"
				SetVariable $"Amp_UB_"+num2str(iPeak), title=" ",pos={vXbump+211,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wAmp_UB[iPeak],frame=1
				SetVariable $"Amp_Ep_"+num2str(iPeak), title=" ",pos={vXbump+250,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wAmp_Ep[iPeak],frame=1

				//GFrac
				vXbump+=175
				SetVariable $"GFrac_LB_"+num2str(iPeak), title=" ",pos={vXbump+123,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wGFrac_LB[iPeak],frame=1
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 165+vXbump,vYValue-2, "<"
				SetVariable $"GFrac_"+num2str(iPeak), title=" ",pos={vXbump+167,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wGFrac[iPeak],frame=1,valueColor=(65535,0,65535)
				SetDrawEnv textxjust=1;DrawText/W=$sWindowName 211+vXbump,vYValue-2, "<"
				SetVariable $"GFrac_UB_"+num2str(iPeak), title=" ",pos={vXbump+211,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wGFrac_UB[iPeak],frame=1
				SetVariable $"GFrac_Ep_"+num2str(iPeak), title=" ",pos={vXbump+250,vYValue-10},size={40,40},fsize=10,live=0,font=sFont,value=wGFrac_Ep[iPeak],frame=1

				vYValue+=20
				vXbump = -5
			endfor
			
			DrawLine 0,vYValue,820,vYValue
			vYValue+=10
			
			//BKGRD order
			SetDrawEnv textxjust=1,fstyle=1,fsize= 10;DrawText 150,vYValue, "Background Poly Order"
			vYValue+=10
			PopupMenu sBKGRDOrder,pos={150,vYValue},mode=1,align=0,bodyWidth=100,value="None;0;1;2;3;4;5",proc=MultiPeakFit_UpdateGlobal,popvalue=sBKGRDOrder
			
				
			//fit button
			SetDrawEnv textxjust=1,fstyle=2,fsize= 10,textrgb=(65535,0,0);DrawText 710,vYValue-10, "When all peaks are ready!"
			SetDrawEnv textxjust=1,fstyle=2,fsize= 10,textrgb=(0,0,0);DrawText 450,vYValue-10, "If not all peaks are in all sampes"
			vYValue+=10
			
			button bDefinePerSample, title="Peaks per sample ",appearance={native,All},pos={300,vYValue-10},size={140,20},proc=MultiPeakFit_Button,font=sFont,fsize=12,fstyle=3,fColor=(21845,21845,21845)
			button bDefinePeaksForSamples, title="Peaks for samples",appearance={native,All},pos={450,vYValue-10},size={140,20},proc=MultiPeakFit_Button,font=sFont,fsize=12,fstyle=3,fColor=(21845,21845,21845)
			button bDoFit,title="Do Fit",appearance={native,All},pos={640,vYValue-10},size={140,20},proc=MultiPeakFit_Button,font=sFont,fsize=12,fstyle=3,fColor=(65535,0,0)
			vYValue+=15
			
			DrawLine 0,vYValue,820,vYValue
			vYValue+=20
			//help
			SetDrawEnv textxjust=1,fstyle=2,fsize= 10;DrawText 410,vYValue, "The below check boxes control what data is produced when the fit converges."
			vYValue+=20
			
			
			//lines
			SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 60	,vYValue, "Visual"
			SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 303	,vYValue, "Vector Outputs"
			SetDrawEnv fstyle= 1,fsize= 14,textxjust= 1;DrawText 650	,vYValue, "Scalar Outputs"
			DrawLine 0,vYValue,25,vYValue
			DrawLine 100,vYValue,243,vYValue
			DrawLine 363,vYValue,590,vYValue
			DrawLine 710,vYValue,820,vYValue	
			DrawLine 116,vYValue,116,vYValue+100
			DrawLine 464,vYValue,464,vYValue+100
			vYValue+=20
			
			vXbump = 16 
			//add visual outputs
			CheckBox bMakePlots fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="See Each", value=bMakePlots; vYValue+=20
			CheckBox bSeeResiduals fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="+Residual", value=bSeeResiduals; vYValue+=20
			vXbump+=115;vYValue-=40
			
			//add output selections (vector Data)
			CheckBox bMakeBackgroundTrace fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Background", value=bMakeBackgroundTrace; vYValue+=20
			CheckBox bMakeTracePerPeak fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Each Peak", value=bMakeTracePerPeak; vYValue+=20
			vXbump+=115;vYValue-=40
			CheckBox bMakeFullFitTrace fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Full Fit", value=bMakeFullFitTrace; vYValue+=20
			CheckBox bMakeResidualsTrace fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Residuals", value=bMakeResidualsTrace; vYValue+=20
			vXbump+=115;vYValue-=40
			CheckBox bMakePercentResidualsTrace fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="% Residuals", value=bMakeResidualsTrace; vYValue+=20
			vXbump+=115;vYValue-=20
			
			//CheckBox bMakeBackgroundTrace fsize=12,pos={25,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Background", value=bMakeBackgroundTrace
			CheckBox bOutputPosScalars fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Center", value=bOutputPosScalars; vYValue+=20
			CheckBox bOutputPosScalarsErr fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Center σ", value=bOutputPosScalarsErr; vYValue+=20
			CheckBox bOutputAmpScalars fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Amplitude", value=bOutputAmpScalars; vYValue+=20
			CheckBox bOutputAmpScalarsErr fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Amplitude σ", value=bOutputAmpScalarsErr; vYValue+=20
			vXbump+=115;vYValue-=80
			CheckBox bOutputFWHMScalars fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="FWHM", value=bOutputFWHMScalars; vYValue+=20
			CheckBox bOutputFWHMScalarsErr fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="FWHM σ", value=bOutputFWHMScalarsErr; vYValue+=20
			CheckBox bOutputGFracScalars fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="GFraction", value=bOutputGFracScalars; vYValue+=20
			CheckBox bOutputGFracScalarsErr fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="GFraction σ", value=bOutputGFracScalarsErr; vYValue+=20
			vXbump+=115;vYValue-=80
			CheckBox bOutputPeakAreaScalars fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Area", value=bOutputPeakAreaScalars; vYValue+=20
			CheckBox bOutputGOFScalars fsize=12,pos={vXBump,vYValue-5},proc=MultiPeakFit_UpdateRefBox,size={100,20},title="Goodness of Fit", value=bOutputGOFScalars; vYValue+=20
			vYValue+=20
			vYValue+=20
			//resize 2nd panel
			moveWindow/W=$sWindowName vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vYValue

		endif
	else
		//resize first, no data to show in plot
		moveWindow/W=$sWindowName vWinLeft,vWinTop,vWinLeft+vPanelWidth,vWinTop+vYValue
	endif	
end

//function to define the peaks to fit for a sample
function MultiPeakFit_DefineSamplePeaks(sSubProject)
	string sSubProject
	
	string sProject = COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)
	string sDepData = COMBI_GetPluginString(sPluginName,"sDepData",sSubProject)
	string sIndData = COMBI_GetPluginString(sPluginName,"sIndData",sSubProject)
	variable vSampleStart = COMBI_GetPluginNumber(sPluginName,"vSampleStart",sSubProject)
	variable vSampleEnd = COMBI_GetPluginNumber(sPluginName,"vSampleEnd",sSubProject)
	string sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
	string sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
	string sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
	string sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
	string sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
	string sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
	string sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
	string sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
	string sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
	string sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
	string sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
	string sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
	string sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
	string sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
	string sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
	string sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
	string sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
	variable vWindowSize = COMBI_GetPluginNumber(sPluginName,"vWindowSize",sSubProject)
	variable vFWHMGuess = COMBI_GetPluginNumber(sPluginName,"vFWHMGuess",sSubProject)
	variable vGFracsGuess = COMBI_GetPluginNumber(sPluginName,"vGFracsGuess",sSubProject)
	variable vEpsPoly = COMBI_GetPluginNumber(sPluginName,"vEpsPoly",sSubProject)
	variable vEpsAmp = COMBI_GetPluginNumber(sPluginName,"vEpsAmp",sSubProject)
	variable vEpsFWHM = COMBI_GetPluginNumber(sPluginName,"vEpsFWHM",sSubProject)
	variable vEpsCenter = COMBI_GetPluginNumber(sPluginName,"vEpsCenter",sSubProject)
	variable vEpsGFracs = COMBI_GetPluginNumber(sPluginName,"vEpsGFracs",sSubProject)
	variable vBgScaleLocation = COMBI_GetPluginNumber(sPluginName,"vBgScaleLocation",sSubProject)
	string sAmpScaleType = COMBI_GetPluginString(sPluginName,"sAmpScaleType",sSubProject)
	variable vDepMax = COMBI_GetPluginNumber(sPluginName,"vDepMax",sSubProject)
	variable vDepMin = COMBI_GetPluginNumber(sPluginName,"vDepMin",sSubProject)
	variable vIndMax = COMBI_GetPluginNumber(sPluginName,"vIndMax",sSubProject)
	variable vIndMin = COMBI_GetPluginNumber(sPluginName,"vIndMin",sSubProject)
	variable vDepRange = COMBI_GetPluginNumber(sPluginName,"vDepRange",sSubProject)
	variable vIndRange = COMBI_GetPluginNumber(sPluginName,"vIndRange",sSubProject)
	variable vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)
	string sYScale = COMBI_GetPluginString(sPluginName,"sYScale",sSubProject)
	string sPeaksPlotting = COMBI_GetPluginString(sPluginName,"sPeaksPlotting",sSubProject)
	string sTraceMode = COMBI_GetPluginString(sPluginName,"sTraceMode",sSubProject)
	int bMakeBackgroundTrace = COMBI_GetPluginNumber(sPluginName,"bMakeBackgroundTrace",sSubProject)
	int bMakeFullFitTrace = COMBI_GetPluginNumber(sPluginName,"bMakeFullFitTrace",sSubProject)
	int bMakeTracePerPeak = COMBI_GetPluginNumber(sPluginName,"bMakeTracePerPeak",sSubProject)
	int bMakeResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakeResidualsTrace",sSubProject)
	int bMakePercentResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakePercentResidualsTrace",sSubProject)
	int bOutputPosScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	int bOutputAmpScalars = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	int bOutputFWHMScalars = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	int bOutputGFracScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	int bOutputGOFScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGOFScalars",sSubProject)
	int bOutputPeakAreaScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPeakAreaScalars",sSubProject)
	int bMakePlots = COMBI_GetPluginNumber(sPluginName,"bMakePlots",sSubProject)
	int bOutputPosScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	int bOutputAmpScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	int bOutputFWHMScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	int bOutputGFracScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	int bSeeResiduals = COMBI_GetPluginNumber(sPluginName,"bSeeResiduals",sSubProject)
	
	string sPeaks2FitPerSample = COMBI_GetPluginString(sPluginName,"sPeaks2FitPerSample",sSubProject)
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	variable vTotalSamples  = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	int iSample
	int vSample
	int iPeak
		
	wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sIndData
	wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDepData
	
	string sSamplesToEdit = ""
	if(waveExists(wYWave)&&WaveExists(wXWave))//data exist,must be fully defined
		for(iSample=(vSampleStart-1);iSample<vSampleEnd;iSample+=1)
			sSamplesToEdit += "S"+num2str(iSample+1)+";"
		endfor
		sSamplesToEdit = COMBI_UserOptionSelect(sSamplesToEdit,"", sTitle="Samples to edit",sDescription="Select Samples")
		if(stringmatch("CANCEL",sSamplesToEdit))
			return -1
		endif
	else
		return -1
	endif 
	
	for(iSample=(vSampleStart-1);iSample<vSampleEnd;iSample+=1)
		vSample = iSample + 1
		if(whichlistItem("S"+num2str(vSample),sSamplesToEdit)==-1)
			continue
		endif
		string sWindowName = sProject+sLibrary+sDepData+sIndData+num2str(vSample)
		variable vDepSMax = Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSample)+";"+num2str(vSample)+"; ; ; ; ","Max")
		variable vDepSMin = Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSample)+";"+num2str(vSample)+"; ; ; ; ","Min")
		variable vIndSMax = Combi_Extremes(sProject,2,sIndData,sLibrary,num2str(vSample)+";"+num2str(vSample)+"; ; ; ; ","Max")
		variable vIndSMin = Combi_Extremes(sProject,2,sIndData,sLibrary,num2str(vSample)+";"+num2str(vSample)+"; ; ; ; ","Min")
		variable vIndSRange = vIndSMax - vIndSMin
		
		killwindow/Z $sWindowName
		Display/L/B/W=(50,50,50+600,50+300)/N=$sWindowName wYWave[iSample][]/TN=$"Sample"+num2str(vSample) vs wXWave[iSample][]
		SetAxis/W=$sWindowName bottom vIndSMin-(0.05*vIndSRange),vIndSMax+(0.05*vIndSRange)
		SetAxis/W=$sWindowName left vDepSMin,vDepSMax
		ModifyGraph/W=$sWindowName mode=4,marker=19,msize=1,lsize=0.5
		Label/W=$sWindowName left sDepData+" \u"
		Label/W=$sWindowName bottom sIndData+" \u"
		ModifyGraph/W=$sWindowName width=600,height=300,rgb=(0,0,0)
		ModifyGraph/W=$sWindowName margin(left)=50,margin(bottom)=50,margin(right)=20,margin(top)=75,gbRGB=(65535.,65535.,65535.),wbRGB=(61166,61166,61166),gFont=sFont,gfsize=12
		ModifyGraph/W=$sWindowName grid=0,mirror=2,fsize=12,lblMargin=5,gridStyle=5,gridRGB=(34952,34952,34952),tick=1,mirror=1,highTrip=1,notation=1,nticks(bottom)=10,minor(bottom)=1

		if(stringmatch(sYScale,"Log"))
			if(vDepSMin>0)
				ModifyGraph/W=$sWindowName log(left)=1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
			endif
		endif
		
		//add peaks to the plot
		string sPreviousSelect = stringfromlist(iSample,sPeaks2FitPerSample,"$")
		for(iPeak=0;iPeak<vPeaksToFit;iPeak+=1)		
			variable vPosLeft = str2num(stringFromList(iPeak,sXPosLBList))
			variable vPosRight =	str2num(stringFromList(iPeak,sXPosUBList))
			if(str2num(stringfromlist(iPeak,sPreviousSelect))==1)
				SetDrawEnv/W=$sWindowName xcoord= bottom,dash= 2,fillpat= 1,fillbgc=(2,39321,1,16384),fillfgc=(2,39321,1,16384)
				DrawRect/W=$sWindowName vPosLeft,0,vPosRight,1
			elseif(str2num(stringfromlist(iPeak,sPreviousSelect))==0)
				SetDrawEnv/W=$sWindowName xcoord= bottom,dash= 2,fillpat= 1,fillbgc=(65535,0,0,16384),fillfgc=(65535,0,0,16384)
				DrawRect/W=$sWindowName vPosLeft,0,vPosRight,1
			endif
			SetDrawEnv/W=$sWindowName xcoord= bottom,textxjust= 1,fname=sFont,textrot= 90
			DrawText/W=$sWindowName str2num(stringFromList(iPeak,sXPosList)),-.02,"  "+stringfromlist(iPeak,sPeakTagList)
		endfor
		
		string sPeaks2FitHere = COMBI_UserOptionSelect(sPeakTagList,sPreviousSelect, sTitle="Sample "+num2str(vSample)+" Peaks",sDescription="Select Peaks to Fit")
		if(stringmatch("CANCEL",sPeaks2FitHere))
			Killwindow $sWindowName
			return -1
		endif
		Killwindow $sWindowName
		
		string sToAddBack = ""
		for(iPeak=0;iPeak<vPeaksToFit;iPeak+=1)	
			if(WhichListItem(stringfromlist(iPeak,sPeakTagList),sPeaks2FitHere)>=0)
				sToAddBack += "1;"
			else
				sToAddBack += "0;"
			endif
		endfor
		
		//replace in list
		sPeaks2FitPerSample = AddListItem(sToAddBack,RemoveListItem(iSample,sPeaks2FitPerSample,"$"),"$",iSample)
					
		//give back list
		COMBI_GivePluginGlobal(sPluginName,"sPeaks2FitPerSample",sPeaks2FitPerSample,sSubProject)

	endfor
	

	

end


//function to define the peaks to fit for a sample
function MultiPeakFit_DefinePeaksForSamples(sSubProject)
	string sSubProject
	
	string sProject = COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)
	string sDepData = COMBI_GetPluginString(sPluginName,"sDepData",sSubProject)
	string sIndData = COMBI_GetPluginString(sPluginName,"sIndData",sSubProject)
	variable vSampleStart = COMBI_GetPluginNumber(sPluginName,"vSampleStart",sSubProject)
	variable vSampleEnd = COMBI_GetPluginNumber(sPluginName,"vSampleEnd",sSubProject)
	string sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
	string sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
	string sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
	string sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
	string sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
	string sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
	string sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
	string sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
	string sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
	string sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
	string sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
	string sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
	string sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
	string sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
	string sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
	string sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
	string sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
	variable vWindowSize = COMBI_GetPluginNumber(sPluginName,"vWindowSize",sSubProject)
	variable vFWHMGuess = COMBI_GetPluginNumber(sPluginName,"vFWHMGuess",sSubProject)
	variable vGFracsGuess = COMBI_GetPluginNumber(sPluginName,"vGFracsGuess",sSubProject)
	variable vEpsPoly = COMBI_GetPluginNumber(sPluginName,"vEpsPoly",sSubProject)
	variable vEpsAmp = COMBI_GetPluginNumber(sPluginName,"vEpsAmp",sSubProject)
	variable vEpsFWHM = COMBI_GetPluginNumber(sPluginName,"vEpsFWHM",sSubProject)
	variable vEpsCenter = COMBI_GetPluginNumber(sPluginName,"vEpsCenter",sSubProject)
	variable vEpsGFracs = COMBI_GetPluginNumber(sPluginName,"vEpsGFracs",sSubProject)
	variable vBgScaleLocation = COMBI_GetPluginNumber(sPluginName,"vBgScaleLocation",sSubProject)
	string sAmpScaleType = COMBI_GetPluginString(sPluginName,"sAmpScaleType",sSubProject)
	variable vDepMax = COMBI_GetPluginNumber(sPluginName,"vDepMax",sSubProject)
	variable vDepMin = COMBI_GetPluginNumber(sPluginName,"vDepMin",sSubProject)
	variable vIndMax = COMBI_GetPluginNumber(sPluginName,"vIndMax",sSubProject)
	variable vIndMin = COMBI_GetPluginNumber(sPluginName,"vIndMin",sSubProject)
	variable vDepRange = COMBI_GetPluginNumber(sPluginName,"vDepRange",sSubProject)
	variable vIndRange = COMBI_GetPluginNumber(sPluginName,"vIndRange",sSubProject)
	variable vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)
	string sYScale = COMBI_GetPluginString(sPluginName,"sYScale",sSubProject)
	string sPeaksPlotting = COMBI_GetPluginString(sPluginName,"sPeaksPlotting",sSubProject)
	string sTraceMode = COMBI_GetPluginString(sPluginName,"sTraceMode",sSubProject)
	int bMakeBackgroundTrace = COMBI_GetPluginNumber(sPluginName,"bMakeBackgroundTrace",sSubProject)
	int bMakeFullFitTrace = COMBI_GetPluginNumber(sPluginName,"bMakeFullFitTrace",sSubProject)
	int bMakeTracePerPeak = COMBI_GetPluginNumber(sPluginName,"bMakeTracePerPeak",sSubProject)
	int bMakeResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakeResidualsTrace",sSubProject)
	int bMakePercentResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakePercentResidualsTrace",sSubProject)
	int bOutputPosScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	int bOutputAmpScalars = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	int bOutputFWHMScalars = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	int bOutputGFracScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	int bOutputGOFScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGOFScalars",sSubProject)
	int bOutputPeakAreaScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPeakAreaScalars",sSubProject)
	int bMakePlots = COMBI_GetPluginNumber(sPluginName,"bMakePlots",sSubProject)
	int bOutputPosScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	int bOutputAmpScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	int bOutputFWHMScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	int bOutputGFracScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	int bSeeResiduals = COMBI_GetPluginNumber(sPluginName,"bSeeResiduals",sSubProject)
	
	string sPeaks2FitPerSample = COMBI_GetPluginString(sPluginName,"sPeaks2FitPerSample",sSubProject)
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	variable vTotalSamples  = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	int iSample
	int vSample
	int iPeak
		
	wave/Z wXWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sIndData
	wave/Z wYWave = $COMBI_DataPath(sProject,2)+sLibrary+":"+sDepData
	
	string sSamplesToEdit = ""
	if(waveExists(wYWave)&&WaveExists(wXWave))//data exist,must be fully defined
		for(iSample=(vSampleStart-1);iSample<vSampleEnd;iSample+=1)
			sSamplesToEdit += "S"+num2str(iSample+1)+";"
		endfor
		sSamplesToEdit = COMBI_UserOptionSelect(sSamplesToEdit,"", sTitle="Samples to change",sDescription="Select Samples")
		if(stringmatch("CANCEL",sSamplesToEdit))
			return -1
		endif
	else
		return -1
	endif 
	
	string sWindowName = sProject+sLibrary+sDepData+sIndData
	
	killwindow/Z $sWindowName
	Display/L/B/W=(50,50,50+600,50+300)/N=$sWindowName 

	//add traces for sampeles to edit.
	for(iSample=(vSampleStart-1);iSample<vSampleEnd;iSample+=1)
		vSample = iSample + 1
		if(whichlistItem("S"+num2str(vSample),sSamplesToEdit)==-1)
			continue
		endif
		AppendToGraph/W=$sWindowName/L/B wYWave[iSample][]/TN=$"Sample"+num2str(vSample) vs wXWave[iSample][]
	endfor
	
	ModifyGraph/W=$sWindowName mode=4,marker=19,msize=1,lsize=0.5
	Label/W=$sWindowName left sDepData+" \u"
	Label/W=$sWindowName bottom sIndData+" \u"
	ModifyGraph/W=$sWindowName width=600,height=300,rgb=(0,0,0)
	ModifyGraph/W=$sWindowName margin(left)=50,margin(bottom)=50,margin(right)=20,margin(top)=75,gbRGB=(65535.,65535.,65535.),wbRGB=(61166,61166,61166),gFont=sFont,gfsize=12
	ModifyGraph/W=$sWindowName grid=0,mirror=2,fsize=12,lblMargin=5,gridStyle=5,gridRGB=(34952,34952,34952),tick=1,mirror=1,highTrip=1,notation=1,nticks(bottom)=10,minor(bottom)=1
	
	//add peaks to the plot
	string sPreviousSelect = stringfromlist(iSample,sPeaks2FitPerSample,"$")
	for(iPeak=0;iPeak<vPeaksToFit;iPeak+=1)		
		variable vPosLeft = str2num(stringFromList(iPeak,sXPosLBList))
		variable vPosRight =	str2num(stringFromList(iPeak,sXPosUBList))
		if(str2num(stringfromlist(iPeak,sPreviousSelect))==1)
			SetDrawEnv/W=$sWindowName xcoord= bottom,dash= 2,fillpat= 1,fillbgc=(2,39321,1,16384),fillfgc=(2,39321,1,16384)
			DrawRect/W=$sWindowName vPosLeft,0,vPosRight,1
		elseif(str2num(stringfromlist(iPeak,sPreviousSelect))==0)
			SetDrawEnv/W=$sWindowName xcoord= bottom,dash= 2,fillpat= 1,fillbgc=(65535,0,0,16384),fillfgc=(65535,0,0,16384)
			DrawRect/W=$sWindowName vPosLeft,0,vPosRight,1
		endif
		SetDrawEnv/W=$sWindowName xcoord= bottom,textxjust= 1,fname=sFont,textrot= 90
		DrawText/W=$sWindowName str2num(stringFromList(iPeak,sXPosList)),-.02,"  "+stringfromlist(iPeak,sPeakTagList)
	endfor
	
	string sPeaks2FitHere = COMBI_UserOptionSelect(sPeakTagList,sPreviousSelect, sTitle="Sample "+num2str(vSample)+" Peaks",sDescription="Select Peaks to Fit")
	if(stringmatch("CANCEL",sPeaks2FitHere))
		Killwindow $sWindowName
		return -1
	endif
	Killwindow $sWindowName
	
	string sToAddBack = ""
	for(iPeak=0;iPeak<vPeaksToFit;iPeak+=1)	
		if(WhichListItem(stringfromlist(iPeak,sPeakTagList),sPeaks2FitHere)>=0)
			sToAddBack += "1;"
		else
			sToAddBack += "0;"
		endif
	endfor
	
	for(iSample=(vSampleStart-1);iSample<vSampleEnd;iSample+=1)
		vSample = iSample + 1
		if(whichlistItem("S"+num2str(vSample),sSamplesToEdit)==-1)
			continue
		endif
		//replace in list
		sPeaks2FitPerSample = AddListItem(sToAddBack,RemoveListItem(iSample,sPeaks2FitPerSample,"$"),"$",iSample)
	endfor
				
	//give back list
	COMBI_GivePluginGlobal(sPluginName,"sPeaks2FitPerSample",sPeaks2FitPerSample,sSubProject)
	
end



//This function will update the globals when a drop-down is updated on the panel.
Function MultiPeakFit_UpdateGlobal(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName//name of control, should be also name of global being updated
	Variable popNum//number in list
	String popStr //value selected
	if(stringmatch("sProject",ctrlName))
		//special place for the project
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,"COMBIgor")
	elseif(stringmatch("sLibrary",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")),"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sDepData",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")),"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	elseif(stringmatch("sIndData",ctrlName))
		COMBI_GivePluginGlobal(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")),"COMBIgor")
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	else 
		//store the global in based on the name of the control sending it
		COMBI_GivePluginGlobal(sPluginName,ctrlName,popStr,COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	endif
	//reload panel
	COMBI_MultiPeakFit()
end

//This function is used to grab the info from the project to return in the pop-up menu.
Function MultiPeakFit_PopPanelWaves(sSubProject)
	string sSubProject
	int iPeak
	if(stringmatch("NAG",COMBI_GetPluginString(sPluginName,"sProject",sSubProject)))//not yet initialized
		return -1
	else

		wave wTraces = $sPackageFolder+"PanelWaves:PanelTraces"
		
		string sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
		string sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
		string sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
		string sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
		string sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
		string sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
		string sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
		string sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
		string sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
		string sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
		string sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
		string sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
		string sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
		string sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
		string sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
		string sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
		string sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
		variable vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)
		
		wave/T wFWHM = $sPackageFolder+"PanelWaves:FWHM_Panel"
		wave/T wPos = $sPackageFolder+"PanelWaves:Pos_Panel"
		wave/T wAmp = $sPackageFolder+"PanelWaves:Amp_Panel"
		wave/T wGFrac = $sPackageFolder+"PanelWaves:GFrac_Panel"
		wave/T wFWHM_UB = $sPackageFolder+"PanelWaves:FWHM_UB_Panel"
		wave/T wPos_UB = $sPackageFolder+"PanelWaves:Pos_UB_Panel"
		wave/T wAmp_UB = $sPackageFolder+"PanelWaves:Amp_UB_Panel"
		wave/T wGFrac_UB = $sPackageFolder+"PanelWaves:GFrac_UB_Panel"
		wave/T wFWHM_LB = $sPackageFolder+"PanelWaves:FWHM_LB_Panel"
		wave/T wPos_LB = $sPackageFolder+"PanelWaves:Pos_LB_Panel"
		wave/T wAmp_LB = $sPackageFolder+"PanelWaves:Amp_LB_Panel"
		wave/T wGFrac_LB = $sPackageFolder+"PanelWaves:GFrac_LB_Panel"
		wave/T wFWHM_Ep = $sPackageFolder+"PanelWaves:FWHM_Ep_Panel"
		wave/T wPos_Ep = $sPackageFolder+"PanelWaves:Pos_Ep_Panel"
		wave/T wAmp_Ep = $sPackageFolder+"PanelWaves:Amp_Ep_Panel"
		wave/T wGFrac_Ep = $sPackageFolder+"PanelWaves:GFrac_Ep_Panel"
		wave/T wTags = $sPackageFolder+"PanelWaves:Tags_Panel"
		
		int iSampleStart = COMBI_GetPluginNumber(sPluginName,"vSampleStart",sSubProject)-1
		int iSampleEnd = COMBI_GetPluginNumber(sPluginName,"vSampleEnd",sSubProject)-1
		wave/Z wXWave = $COMBI_DataPath(COMBI_GetPluginString(sPluginName,"sProject",sSubProject),2)+COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)+":"+COMBI_GetPluginString(sPluginName,"sIndData",sSubProject)
		wave/Z wYWave = $COMBI_DataPath(COMBI_GetPluginString(sPluginName,"sProject",sSubProject),2)+COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)+":"+COMBI_GetPluginString(sPluginName,"sDepData",sSubProject)
		if(waveexists(wXWave))
			redimension/N=(dimsize(wXWave,1),-1,-1) wTraces
		endif
		
		int iAdded = 0
		int iTrace = 0
		for(iPeak=0;iPeak<itemsinlist(sPeakTagList);iPeak+=1)
			if(strlen(stringfromlist(iPeak,sPeakTagList))==0)
				continue
			else
				wPos[iAdded] = stringfromlist(iPeak,sXPosList)
				wFWHM[iAdded] = stringfromlist(iPeak,sFWHMList)
				wAmp[iAdded] = stringfromlist(iPeak,sAmpList)
				wGFrac[iAdded] = stringfromlist(iPeak,sGFracList)
				wPos_UB[iAdded] = stringfromlist(iPeak,sXPosUBList)
				wFWHM_UB[iAdded] = stringfromlist(iPeak,sFWHMUBList)
				wAmp_UB[iAdded] = stringfromlist(iPeak,sAmpUBList)
				wGFrac_UB[iAdded] = stringfromlist(iPeak,sGFracUBList)
				wPos_LB[iAdded] = stringfromlist(iPeak,sXPosLBList)
				wFWHM_LB[iAdded] = stringfromlist(iPeak,sFWHMLBList)
				wAmp_LB[iAdded] = stringfromlist(iPeak,sAmpLBList)
				wGFrac_LB[iAdded] = stringfromlist(iPeak,sGFracLBList)
				wPos_Ep[iAdded] = stringfromlist(iPeak,sXPosEpList)
				wFWHM_Ep[iAdded] = stringfromlist(iPeak,sFWHMEpList)
				wAmp_Ep[iAdded] = stringfromlist(iPeak,sAmpEpList)
				wGFrac_Ep[iAdded] = stringfromlist(iPeak,sGFracEpList)
				wTags[iAdded] = stringfromlist(iPeak,sPeakTagList)
				iAdded+=1
				
				wave wFitParams = newfreeWave(4,4)
				wFitParams[0] = str2num(stringfromlist(iPeak,sXPosList))
				wFitParams[1] = str2num(stringfromlist(iPeak,sAmpList))
				wFitParams[2] = str2num(stringfromlist(iPeak,sFWHMList))
				wFitParams[3] = str2num(stringfromlist(iPeak,sGFracList))

				wTraces[][iTrace][0] = wXWave[iSampleStart][p]
				wTraces[][iTrace][1] = MultiPeakFit_PseudoVoigts(-1,wFitParams,wTraces[p][iTrace][0])
				iTrace+=1
			endif
		endfor
	endif
end

//This function is used to grab the info from the project to return in the pop-up menu.
Function/S MultiPeakFit_DropList(sOption)
	string sOption//what type of list to return in the popup menu
	
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject",COMBI_GetPluginString(sPluginName,"sProject","COMBIgor"))
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sProject)
	
	//for various options of drop list
	if(stringmatch(sOption,"Libraries"))//list of libraries 
		return Combi_TableList(sProject,1,"All","Libraries")
	elseif(stringmatch(sOption,"DataTypes"))//list of scalar data for the select library
		return Combi_TableList(sProject,2,sLibrary,"DataTypes")
	endif
End

//button to do something
Function MultiPeakFit_Button(ctrlName) : ButtonControl
	String ctrlName//name of button
	
	//get global values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
	
	//if button "bSomeAction" was pressed
	if(stringmatch("bAddPeak",ctrlName))
		MultiPeakFit_AddPeak(sProject)
		COMBI_MultiPeakFit()
	elseif(stringmatch("bRemovePeak",ctrlName))
		MultiPeakFit_RemovePeak(sProject)
		COMBI_MultiPeakFit()
	elseif(stringmatch("bUpdatePeaks",ctrlName))
		MultiPeakFit_UpdatePeaks(sProject)
		COMBI_MultiPeakFit()
	elseif(stringmatch("bFromRef",ctrlName))
		MultiPeakFit_AddPeaksFromRef(sProject)
		COMBI_MultiPeakFit()
	elseif(stringmatch("bDoFit",ctrlName))
	 	MultiPeakFit_UpdatePeaks(sProject)
		MultiPeakFit_DoFit(sProject)
		COMBI_MultiPeakFit()
	elseif(stringmatch("bDefinePerSample",ctrlName))
		MultiPeakFit_DefineSamplePeaks(sProject)
	elseif(stringmatch("bDefinePeaksForSamples",ctrlName))
		MultiPeakFit_DefinePeaksForSamples(sProject)
	elseif(stringmatch("bFromLib",ctrlName))
		MultiPeakFit_AddPeaksFromLib(sProject)
		COMBI_MultiPeakFit()
	endif
	
end


//example function used to do something, called by the button function. 
Function MultiPeakFit_SomeAction(sProject,sLibrary,sData)
	string sProject, sLibrary, sData 
	Print sProject
	Print sLibrary
	Print sData
end

//function to add a peak
function MultiPeakFit_AddPeak(sSubProject)
	string sSubProject
	
	//get project values
	variable vWindowSize = COMBI_GetPluginNumber(sPluginName,"vWindowSize",sSubProject)
	variable vFWHMGuess = COMBI_GetPluginNumber(sPluginName,"vFWHMGuess",sSubProject)
	variable vGFracsGuess = COMBI_GetPluginNumber(sPluginName,"vGFracsGuess",sSubProject)
	variable vEpsPoly = COMBI_GetPluginNumber(sPluginName,"vEpsPoly",sSubProject)
	variable vEpsAmp = COMBI_GetPluginNumber(sPluginName,"vEpsAmp",sSubProject)
	variable vEpsFWHM = COMBI_GetPluginNumber(sPluginName,"vEpsFWHM",sSubProject)
	variable vEpsCenter = COMBI_GetPluginNumber(sPluginName,"vEpsCenter",sSubProject)
	variable vEpsGFracs = COMBI_GetPluginNumber(sPluginName,"vEpsGFracs",sSubProject)
	variable vDepMax = COMBI_GetPluginNumber(sPluginName,"vDepMax",sSubProject)
	variable vDepMin = COMBI_GetPluginNumber(sPluginName,"vDepMin",sSubProject)
	variable vIndMax = COMBI_GetPluginNumber(sPluginName,"vIndMax",sSubProject)
	variable vIndMin = COMBI_GetPluginNumber(sPluginName,"vIndMin",sSubProject)
	variable vDepRange = COMBI_GetPluginNumber(sPluginName,"vDepRange",sSubProject)
	variable vIndRange = COMBI_GetPluginNumber(sPluginName,"vIndRange",sSubProject)
	
	//peak info from cursor
	string sCrsInfo = CsrInfo(A,"MultiPeakFit_Panel#DataPlot")
	variable vYFrac =  str2num(StringByKey("YPOINT",sCrsInfo))
	variable vXFrac =  str2num(StringByKey("POINT",sCrsInfo))
	GetAxis/Q/W=MultiPeakFit_Panel#DataPlot left
	variable vYVal
	if(str2num(StringByKey("log(x)",AxisInfo("MultiPeakFit_Panel#DataPlot","left"),"=",";"))==1)	
		variable vMaxLog = Log(V_max)
		variable vMinLog = Log(V_min)
		variable vOMRange = (vMaxLog-vMinLog)
		vYVal = 10^(vMinLog+((1-vYFrac)*vOMRange))
	else
		vYVal = V_max-(vYFrac*(V_max-V_min))
	endif
	GetAxis/Q/W=MultiPeakFit_Panel#DataPlot bottom
	variable vXVal = V_min+(vXFrac*(V_max-V_min))
	
	//get peak info from user
	variable vPos = vXVal
	variable vFWHM = vFWHMGuess
	variable vAmp = vYVal
	variable vGFrac = vGFracsGuess
	variable vPosUB = vPos+vWindowSize
	variable vFWHMUB = vFWHM*5
	variable vAmpUB = vAmp*1.1
	variable vGFracUB = 1
	variable vPosLB = vPos-vWindowSize
	variable vFWHMLB = vFWHM*.5
	variable vAmpLB = 0
	variable vGFracLB = 0
	variable vPosEp = vEpsCenter
	variable vFWHMEp = vEpsFWHM
	variable vAmpEp = vEpsAmp
	variable vGFracEp = vEpsGFracs

	string sPos = MultiPeakFit_TrimNumString(num2str(vXVal),3)
	string sFWHM = MultiPeakFit_TrimNumString(num2str(vFWHMGuess),3)
	string sAmp = MultiPeakFit_TrimNumString(num2str(vYVal),3)
	string sGFrac = MultiPeakFit_TrimNumString(num2str(vGFracsGuess),3)
	string sPosUB = MultiPeakFit_TrimNumString(num2str(vPos+vWindowSize),3)
	string sFWHMUB = MultiPeakFit_TrimNumString(num2str(vFWHM*5),3)
	string sAmpUB = MultiPeakFit_TrimNumString(num2str(vAmp*1.1),3)
	string sGFracUB = MultiPeakFit_TrimNumString(num2str(1),3)
	string sPosLB = MultiPeakFit_TrimNumString(num2str(vPos-vWindowSize),3)
	string sFWHMLB = MultiPeakFit_TrimNumString(num2str(vFWHM*.5),3)
	string sAmpLB = MultiPeakFit_TrimNumString(num2str(0),3)
	string sGFracLB = MultiPeakFit_TrimNumString(num2str(0),3)
	string sPosEp = MultiPeakFit_TrimNumString(num2str(vEpsCenter),3)
	string sFWHMEp = MultiPeakFit_TrimNumString(num2str(vEpsFWHM),3)
	string sAmpEp = MultiPeakFit_TrimNumString(num2str(vEpsAmp),3)
	string sGFracEp = MultiPeakFit_TrimNumString(num2str(vEpsGFracs),3)
	
	string sName = "P"+num2str(COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)+1)
	
	//add to string list for this dataproject
	COMBI_GivePluginGlobal(sPluginName,"sXPosList",COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)+";"+(sPos),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMList",COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)+";"+(sFWHM),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpList",COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)+";"+(sAmp),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracList",COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)+";"+(sGFrac),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosUBList",COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)+";"+(sPosUB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList",COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)+";"+(sFWHMUB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpUBList",COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)+";"+(sAmpUB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracUBList",COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)+";"+(sGFracUB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosLBList",COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)+";"+(sPosLB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList",COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)+";"+(sFWHMLB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpLBList",COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)+";"+(sAmpLB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracLBList",COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)+";"+(sGFracLB),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosEpList",COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)+";"+(sPosEp),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList",COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)+";"+(sFWHMEp),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpEpList",COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)+";"+(sAmpEp),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracEpList",COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)+";"+(sGFracEp),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sPeakTagList",COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)+";"+sName,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"vPeaksToFit",num2str(COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)+1),sSubProject)
	
	MultiPeakFit_ModSamples2Fit(sSubProject,sName,1,1)
end

function MultiPeakFit_ModSamples2Fit(sSubProject,sPeakTag,iAddOrSub,bDefaultState)
	string sSubProject,sPeakTag
	int iAddOrSub,bDefaultState
	
	int iSample
	int vSample
	int iPeak
	
	string sPeaks2FitPerSample = COMBI_GetPluginString(sPluginName,"sPeaks2FitPerSample",sSubProject)
	string sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
	variable vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)
	string sProject = COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
	variable vTotalSamples  = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	//firsttime?
	if(itemsInList(sPeaks2FitPerSample,"$")!=vTotalSamples||itemsInList(stringfromList(0,sPeaks2FitPerSample,"$"))!=vPeaksToFit)
		sPeaks2FitPerSample = ""
		for(iSample=0;iSample<vTotalSamples;iSample+=1)
			for(iPeak=0;iPeak<vPeaksToFit;iPeak+=1)	
				sPeaks2FitPerSample+="0;"
			endfor
			sPeaks2FitPerSample+="$"
		endfor
	endif

	//which peak is this?
	int iThisPeak = whichListItem(sPeakTag,sPeakTagList)
	
	for(iSample=0;iSample<vTotalSamples;iSample+=1)
		string sThisPeakOptions = StringFromList(iSample, sPeaks2FitPerSample, "$")
		sPeaks2FitPerSample = RemoveListItem(iSample,sPeaks2FitPerSample,"$")
		if(iAddOrSub==1)//add
			if(iThisPeak>=0)//already there?
				if(vPeaksToFit!=itemsinlist(sThisPeakOptions))
					sPeaks2FitPerSample+=num2str(bDefaultState)+";"
				endif
			else
				sThisPeakOptions+=num2str(bDefaultState)+";"
			endif		
		elseif(iAddOrSub==-1)//remove
			if(iThisPeak<0)//not there?
				return -1
			else
				sThisPeakOptions = RemoveListItem(iThisPeak,sThisPeakOptions)
			endif	
		endif
		sPeaks2FitPerSample = AddListItem(sThisPeakOptions,sPeaks2FitPerSample,"$",iSample)
	endfor
	
	//give back to combigor
	COMBI_GivePluginGlobal(sPluginName,"sPeaks2FitPerSample",sPeaks2FitPerSample,sSubProject)

end

function/S MultiPeakFit_TrimNumString(sStringNum,iSigFigs)
	string sStringNum
	int iSigFigs

	//format
	string s2Return 
	sprintf s2Return "%."+num2str(iSigFigs)+"G", str2num(sStringNum)
	
	//E?
	if(stringmatch(s2Return,"*E*"))
		int iE = strsearch(s2Return,"E",0)
		int iPosSign = strsearch(s2Return,"+",0)
		int iNegSign = strsearch(s2Return,"-",0)
		int iLen = strlen(s2Return)
		s2Return = s2Return[0,(iE-1)]+"e"+s2Return[(iE+1),(iLen-1)]
		//remove zero
		if(strsearch(s2Return,"0",iE)>0)
			s2Return = s2Return[0,(iE+1)]+s2Return[(iE+3)]
			iLen-=1
		endif
		if(iPosSign==(iE+1))//remove pos
			s2Return = s2Return[0,iE]+s2Return[(iE+2),(iLen-1)]
		endif
	endif
	
	//return result
	return s2Return
end

//function to edit a peak
function MultiPeakFit_UpdatePeaks(sSubProject)
	string sSubProject
	
	//get project values
	variable vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)

	//panel waves
	wave/T wFWHM = $sPackageFolder+"PanelWaves:FWHM_Panel"
	wave/T wPos = $sPackageFolder+"PanelWaves:Pos_Panel"
	wave/T wAmp = $sPackageFolder+"PanelWaves:Amp_Panel"
	wave/T wGFrac = $sPackageFolder+"PanelWaves:GFrac_Panel"
	wave/T wFWHM_UB = $sPackageFolder+"PanelWaves:FWHM_UB_Panel"
	wave/T wPos_UB = $sPackageFolder+"PanelWaves:Pos_UB_Panel"
	wave/T wAmp_UB = $sPackageFolder+"PanelWaves:Amp_UB_Panel"
	wave/T wGFrac_UB = $sPackageFolder+"PanelWaves:GFrac_UB_Panel"
	wave/T wFWHM_LB = $sPackageFolder+"PanelWaves:FWHM_LB_Panel"
	wave/T wPos_LB = $sPackageFolder+"PanelWaves:Pos_LB_Panel"
	wave/T wAmp_LB = $sPackageFolder+"PanelWaves:Amp_LB_Panel"
	wave/T wGFrac_LB = $sPackageFolder+"PanelWaves:GFrac_LB_Panel"
	wave/T wFWHM_Ep = $sPackageFolder+"PanelWaves:FWHM_Ep_Panel"
	wave/T wPos_Ep = $sPackageFolder+"PanelWaves:Pos_Ep_Panel"
	wave/T wAmp_Ep = $sPackageFolder+"PanelWaves:Amp_Ep_Panel"
	wave/T wGFrac_Ep = $sPackageFolder+"PanelWaves:GFrac_Ep_Panel"
	wave/T wTags = $sPackageFolder+"PanelWaves:Tags_Panel"
	
	string sXPosList = ""
	string sFWHMList = ""
	string sAmpList = ""
	string sGFracList = ""
	string sXPosUBList = ""
	string sFWHMUBList = ""
	string sAmpUBList = ""
	string sGFracUBList = ""
	string sXPosLBList = ""
	string sFWHMLBList = ""
	string sAmpLBList = ""
	string sGFracLBList = ""
	string sXPosEpList = ""
	string sFWHMEpList = ""
	string sAmpEpList = ""
	string sGFracEpList = ""
	string sPeakTagList = ""
	
	//UpdatePeakss
	int iPeak2Edit
	for(iPeak2Edit=0;iPeak2Edit<vPeaksToFit;iPeak2Edit+=1)
		sXPosList=AddListItem(wPos[iPeak2Edit], sXPosList, ";", inf)
		sFWHMList=AddListItem(wFWHM[iPeak2Edit], sFWHMList, ";", inf)
		sAmpList=AddListItem(wAmp[iPeak2Edit], sAmpList, ";", inf)
		sGFracList=AddListItem(wGFrac[iPeak2Edit], sGFracList, ";", inf)
		sXPosUBList=AddListItem(wPos_UB[iPeak2Edit], sXPosUBList, ";", inf)
		sFWHMUBList=AddListItem(wFWHM_UB[iPeak2Edit], sFWHMUBList, ";", inf)
		sAmpUBList=AddListItem(wAmp_UB[iPeak2Edit], sAmpUBList, ";", inf)
		sGFracUBList=AddListItem(wGFrac_UB[iPeak2Edit], sGFracUBList, ";", inf)
		sXPosLBList=AddListItem(wPos_LB[iPeak2Edit], sXPosLBList, ";", inf)
		sFWHMLBList=AddListItem(wFWHM_LB[iPeak2Edit], sFWHMLBList, ";", inf)
		sAmpLBList=AddListItem(wAmp_LB[iPeak2Edit], sAmpLBList, ";", inf)
		sGFracLBList=AddListItem(wGFrac_LB[iPeak2Edit], sGFracLBList, ";", inf)
		sXPosEpList=AddListItem(wPos_Ep[iPeak2Edit], sXPosEpList, ";", inf)
		sFWHMEpList=AddListItem(wFWHM_Ep[iPeak2Edit], sFWHMEpList, ";", inf)
		sAmpEpList=AddListItem(wAmp_Ep[iPeak2Edit], sAmpEpList, ";", inf)
		sGFracEpList=AddListItem(wGFrac_Ep[iPeak2Edit], sGFracEpList, ";", inf)
		
		sPeakTagList=AddListItem(wTags[iPeak2Edit], sPeakTagList, ";", inf)
	endfor
	
	//replace
	COMBI_GivePluginGlobal(sPluginName,"sXPosList",sXPosList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMList",sFWHMList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpList",sAmpList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracList",sGFracList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosUBList",sXPosUBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList",sFWHMUBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpUBList",sAmpUBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracUBList",sGFracUBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosLBList",sXPosLBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList",sFWHMLBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpLBList",sAmpLBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracLBList",sGFracLBList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosEpList",sXPosEpList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList",sFWHMEpList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpEpList",sAmpEpList,sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracEpList",sGFracEpList,sSubProject)
	
	COMBI_GivePluginGlobal(sPluginName,"sPeakTagList",sPeakTagList,sSubProject)
	
end

//function to remove a peak
function MultiPeakFit_RemovePeak(sSubProject)
	string sSubProject
	
	string sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
	string sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
	string sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
	string sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
	string sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
	string sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
	string sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
	string sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
	string sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
	string sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
	string sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
	string sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
	string sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
	string sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
	string sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
	string sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
	string sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
	
	//ask which to remove?
	string sPeaks2Remove = COMBI_UserOptionSelect(sPeakTagList,"", sTitle="Select Peak",sDescription="Select Peaks to Remove")
	
	int iPeak2Remove
	for(iPeak2Remove=0;iPeak2Remove<itemsinlist(sPeaks2Remove);iPeak2Remove+=1)
		string sThisPeak = stringfromlist(iPeak2Remove,sPeaks2Remove)
		int iListCenter = whichlistItem(sThisPeak,sPeakTagList)
		//add to string list for this dataproject
		MultiPeakFit_ModSamples2Fit(sSubProject,sThisPeak,-1,0)
		COMBI_GivePluginGlobal(sPluginName,"sXPosList",RemoveListItem(iListCenter,sXPosList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMList",RemoveListItem(iListCenter,sFWHMList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpList",RemoveListItem(iListCenter,sAmpList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracList",RemoveListItem(iListCenter,sGFracList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosUBList",RemoveListItem(iListCenter,sXPosUBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList",RemoveListItem(iListCenter,sFWHMUBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpUBList",RemoveListItem(iListCenter,sAmpUBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracUBList",RemoveListItem(iListCenter,sGFracUBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosLBList",RemoveListItem(iListCenter,sXPosLBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList",RemoveListItem(iListCenter,sFWHMLBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpLBList",RemoveListItem(iListCenter,sAmpLBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracLBList",RemoveListItem(iListCenter,sGFracLBList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sXPosEpList",RemoveListItem(iListCenter,sXPosEpList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList",RemoveListItem(iListCenter,sFWHMEpList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sAmpEpList",RemoveListItem(iListCenter,sAmpEpList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sGFracEpList",RemoveListItem(iListCenter,sGFracEpList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"sPeakTagList",RemoveListItem(iListCenter,sPeakTagList),sSubProject)
		COMBI_GivePluginGlobal(sPluginName,"vPeaksToFit",num2str(COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)-1),sSubProject)
		
		sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
		sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
		sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
		sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
		sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
		sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
		sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
		sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
		sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
		sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
		sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
		sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
		sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
		sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
		sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
		sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
		sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
		
	endfor	
	
end

//function to add a peaks from a ref
function MultiPeakFit_AddPeaksFromRef(sSubProject)
	string sSubProject
	variable vDepMax = COMBI_GetPluginNumber(sPluginName,"vDepMax",sSubProject)
	variable vDepMin = COMBI_GetPluginNumber(sPluginName,"vDepMin",sSubProject)
	variable vIndMax = COMBI_GetPluginNumber(sPluginName,"vIndMax",sSubProject)
	variable vIndMin = COMBI_GetPluginNumber(sPluginName,"vIndMin",sSubProject)
	variable vDepRange = COMBI_GetPluginNumber(sPluginName,"vDepRange",sSubProject)
	variable vIndRange = COMBI_GetPluginNumber(sPluginName,"vIndRange",sSubProject)
	variable vFWHMGuess = COMBI_GetPluginNumber(sPluginName,"vFWHMGuess",sSubProject)
	variable vGFracsGuess = COMBI_GetPluginNumber(sPluginName,"vGFracsGuess",sSubProject)
	variable vWindowSize = COMBI_GetPluginNumber(sPluginName,"vWindowSize",sSubProject)
	variable vEpsPoly = COMBI_GetPluginNumber(sPluginName,"vEpsPoly",sSubProject)
	variable vEpsAmp = COMBI_GetPluginNumber(sPluginName,"vEpsAmp",sSubProject)
	variable vEpsFWHM = COMBI_GetPluginNumber(sPluginName,"vEpsFWHM",sSubProject)
	variable vEpsCenter = COMBI_GetPluginNumber(sPluginName,"vEpsCenter",sSubProject)
	variable vEpsGFracs = COMBI_GetPluginNumber(sPluginName,"vEpsGFracs",sSubProject)
	
	string sAllRefs = MultiPeakFit_GetRefNames("peaks")
	//ask which one
	string sTheRef = COMBI_StringPrompt(stringfromlist(0,sAllRefs),"Refrence to Add:",sAllRefs,"These are the references I found with peak files loaded.","Select Reference")
	if(stringmatch(sTheRef,"CANCEL"))
		return -1
	endif
	wave/T wRef = $"root:COMBIgor:DiffractionRefs:"+sTheRef+":"+sTheRef+"_Peaks_Simplified"
	//choose center Centers
	string sCenterColumn = COMBI_StringPrompt("Q","Peak Centers:","Q;TwoTheta","","Peak Centers")
	if(stringmatch(sCenterColumn,"CANCEL"))
		return -1
	elseif(stringmatch(sCenterColumn,"Q"))
		sCenterColumn = "Q_2PiPerAng"
	endif
	//fractional intensity choice
	variable vFracIntThresh = COMBI_NumberPrompt(0.05,"Fraction of Mas Intensity Threshold","","Intensity Filter")
	if(numtype(vFracIntThresh)==2)
		return -1
	endif
	//add each to the existing project
	int iPeak
	for(iPeak=0;iPeak<dimsize(wRef,0);iPeak+=1)
		variable vPeakCenter = str2num(wRef[iPeak][%$sCenterColumn])
		if((vPeakCenter>vIndMin)&&(vPeakCenter<vIndMax))
			if(str2num(wRef[iPeak][%FracMaxIntensity])>vFracIntThresh)
				//get peak info from user
				variable vPos = str2num(wRef[iPeak][%$sCenterColumn])
				variable vFWHM = vFWHMGuess
				variable vAmp = vDepMin+(vDepMax-vDepMin)*str2num(wRef[iPeak][%FracMaxIntensity])
				variable vGFrac = vGFracsGuess
				variable vPosUB = vPos+vWindowSize
				variable vFWHMUB = vFWHM*5
				variable vAmpUB = vAmp*1.1
				variable vGFracUB = 1
				variable vPosLB = vPos-vWindowSize
				variable vFWHMLB = vFWHM*.5
				variable vAmpLB = 0
				variable vGFracLB = 0
				variable vPosEp = vEpsCenter
				variable vFWHMEp = vEpsFWHM
				variable vAmpEp = vEpsAmp
				variable vGFracEp = vEpsGFracs
				string sName = sTheRef+"_P"+wRef[iPeak][%PeakNumber]
				
				//add to string list for this dataproject
				COMBI_GivePluginGlobal(sPluginName,"sXPosList",COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vPos),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sFWHMList",COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vFWHM),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sAmpList",COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vAmp),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sGFracList",COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vGFrac),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sXPosUBList",COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vPosUB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList",COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vFWHMUB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sAmpUBList",COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vAmpUB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sGFracUBList",COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vGFracUB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sXPosLBList",COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vPosLB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList",COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vFWHMLB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sAmpLBList",COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vAmpLB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sGFracLBList",COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vGFracLB),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sXPosEpList",COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vPosEp),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList",COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vFWHMEp),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sAmpEpList",COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vAmpEp),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sGFracEpList",COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)+";"+MultiPeakFit_TrimNumString(num2str(vGFracEp),4),sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"sPeakTagList",COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)+";"+sName,sSubProject)
				COMBI_GivePluginGlobal(sPluginName,"vPeaksToFit",num2str(COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)+1),sSubProject)
	
				MultiPeakFit_ModSamples2Fit(sSubProject,sName,1,1)				
			endif
		endif
	endfor
end	

//function to add a peaks from a ref
function MultiPeakFit_AddPeaksFromLib(sSubProject)
	string sSubProject
	//get project values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)
	string sDepData = COMBI_GetPluginString(sPluginName,"sDepData",sSubProject)
	string sIndData = COMBI_GetPluginString(sPluginName,"sIndData",sSubProject)
	
	string sProjectList = ""
	
	wave/T wGlobals = root:Packages:COMBIgor:Plugins:COMBI_MultiPeakFit_Globals
	int iProject
	for(iProject=0;iProject<dimsize(wGlobals,1);iProject+=1)
		string sThisLabel = GetDimLabel(wGlobals,1,iProject)
		if(stringmatch(sThisLabel,"*"+sProject+"*"))//project matches
			if(stringmatch(sThisLabel,"*"+sDepData+"*"))//dep data matches
				if(stringmatch(sThisLabel,"*"+sIndData+"*"))//ind data matches
					if(!stringmatch(sThisLabel,"*"+sLibrary+"*"))//library doesn't match
						sProjectList += sThisLabel+";"
					endif
				endif
			endif
		endif
	endfor
	
	if(itemsInList(sProjectList)==0)
		return -1
	endif
	
	string sToUse = COMBI_StringPrompt("","Project to port peaks from:",sProjectList,"","Choose Project")
	if(stringmatch("CANCEL",sToUse))
		return -1
	endif
	
	//add to string list for this dataproject
	COMBI_GivePluginGlobal(sPluginName,"sXPosList",COMBI_GetPluginString(sPluginName,"sXPosList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMList",COMBI_GetPluginString(sPluginName,"sFWHMList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpList",COMBI_GetPluginString(sPluginName,"sAmpList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracList",COMBI_GetPluginString(sPluginName,"sGFracList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosUBList",COMBI_GetPluginString(sPluginName,"sXPosUBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMUBList",COMBI_GetPluginString(sPluginName,"sFWHMUBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpUBList",COMBI_GetPluginString(sPluginName,"sAmpUBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracUBList",COMBI_GetPluginString(sPluginName,"sGFracUBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosLBList",COMBI_GetPluginString(sPluginName,"sXPosLBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMLBList",COMBI_GetPluginString(sPluginName,"sFWHMLBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpLBList",COMBI_GetPluginString(sPluginName,"sAmpLBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracLBList",COMBI_GetPluginString(sPluginName,"sGFracLBList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sXPosEpList",COMBI_GetPluginString(sPluginName,"sXPosEpList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sFWHMEpList",COMBI_GetPluginString(sPluginName,"sFWHMEpList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sAmpEpList",COMBI_GetPluginString(sPluginName,"sAmpEpList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sGFracEpList",COMBI_GetPluginString(sPluginName,"sGFracEpList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"sPeakTagList",COMBI_GetPluginString(sPluginName,"sPeakTagList",sToUse),sSubProject)
	COMBI_GivePluginGlobal(sPluginName,"vPeaksToFit",COMBI_GetPluginString(sPluginName,"vPeaksToFit",sToUse),sSubProject)	
	COMBI_GivePluginGlobal(sPluginName,"sPeaks2FitPerSample",COMBI_GetPluginString(sPluginName,"sPeaks2FitPerSample",sToUse),sSubProject)	
	
end	


Function MultiPeakFit_UpdateRefBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	string sNewRefList
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			string sName = cba.ctrlName
			string sProject = COMBI_GetPluginString(sPluginName,"sProject","COMBIgor")
			COMBI_GivePluginGlobal(sPluginName,sName,num2str(checked),sProject)
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

//function to do the fit
function MultiPeakFit_DoFit(sSubProject)
	string sSubProject
	
	//get project values
	string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")

	//get project values
	string sProject = COMBI_GetPluginString(sPluginName,"sProject",sSubProject)
	string sLibrary = COMBI_GetPluginString(sPluginName,"sLibrary",sSubProject)
	string sDepData = COMBI_GetPluginString(sPluginName,"sDepData",sSubProject)
	string sIndData = COMBI_GetPluginString(sPluginName,"sIndData",sSubProject)
	string sBKGRDOrder = COMBI_GetPluginString(sPluginName,"sBKGRDOrder",sSubProject)
	variable vSampleStart = COMBI_GetPluginNumber(sPluginName,"vSampleStart",sSubProject)
	variable vSampleEnd = COMBI_GetPluginNumber(sPluginName,"vSampleEnd",sSubProject)
	string sXPosList = COMBI_GetPluginString(sPluginName,"sXPosList",sSubProject)
	string sFWHMList = COMBI_GetPluginString(sPluginName,"sFWHMList",sSubProject)
	string sAmpList = COMBI_GetPluginString(sPluginName,"sAmpList",sSubProject)
	string sGFracList = COMBI_GetPluginString(sPluginName,"sGFracList",sSubProject)
	string sXPosUBList = COMBI_GetPluginString(sPluginName,"sXPosUBList",sSubProject)
	string sFWHMUBList = COMBI_GetPluginString(sPluginName,"sFWHMUBList",sSubProject)
	string sAmpUBList = COMBI_GetPluginString(sPluginName,"sAmpUBList",sSubProject)
	string sGFracUBList = COMBI_GetPluginString(sPluginName,"sGFracUBList",sSubProject)
	string sXPosLBList = COMBI_GetPluginString(sPluginName,"sXPosLBList",sSubProject)
	string sFWHMLBList = COMBI_GetPluginString(sPluginName,"sFWHMLBList",sSubProject)
	string sAmpLBList = COMBI_GetPluginString(sPluginName,"sAmpLBList",sSubProject)
	string sGFracLBList = COMBI_GetPluginString(sPluginName,"sGFracLBList",sSubProject)
	string sXPosEpList = COMBI_GetPluginString(sPluginName,"sXPosEpList",sSubProject)
	string sFWHMEpList = COMBI_GetPluginString(sPluginName,"sFWHMEpList",sSubProject)
	string sAmpEpList = COMBI_GetPluginString(sPluginName,"sAmpEpList",sSubProject)
	string sGFracEpList = COMBI_GetPluginString(sPluginName,"sGFracEpList",sSubProject)
	string sPeakTagList = COMBI_GetPluginString(sPluginName,"sPeakTagList",sSubProject)
	variable vWindowSize = COMBI_GetPluginNumber(sPluginName,"vWindowSize",sSubProject)
	variable vFWHMGuess = COMBI_GetPluginNumber(sPluginName,"vFWHMGuess",sSubProject)
	variable vGFracsGuess = COMBI_GetPluginNumber(sPluginName,"vGFracsGuess",sSubProject)
	variable vEpsPoly = COMBI_GetPluginNumber(sPluginName,"vEpsPoly",sSubProject)
	variable vEpsAmp = COMBI_GetPluginNumber(sPluginName,"vEpsAmp",sSubProject)
	variable vEpsFWHM = COMBI_GetPluginNumber(sPluginName,"vEpsFWHM",sSubProject)
	variable vEpsCenter = COMBI_GetPluginNumber(sPluginName,"vEpsCenter",sSubProject)
	variable vEpsGFracs = COMBI_GetPluginNumber(sPluginName,"vEpsGFracs",sSubProject)
	variable vBgScaleLocation = COMBI_GetPluginNumber(sPluginName,"vBgScaleLocation",sSubProject)
	string sAmpScaleType = COMBI_GetPluginString(sPluginName,"sAmpScaleType",sSubProject)
	variable vDepMax = COMBI_GetPluginNumber(sPluginName,"vDepMax",sSubProject)
	variable vDepMin = COMBI_GetPluginNumber(sPluginName,"vDepMin",sSubProject)
	variable vIndMax = COMBI_GetPluginNumber(sPluginName,"vIndMax",sSubProject)
	variable vIndMin = COMBI_GetPluginNumber(sPluginName,"vIndMin",sSubProject)
	variable vDepRange = COMBI_GetPluginNumber(sPluginName,"vDepRange",sSubProject)
	variable vIndRange = COMBI_GetPluginNumber(sPluginName,"vIndRange",sSubProject)
	variable vPeaksToFit = COMBI_GetPluginNumber(sPluginName,"vPeaksToFit",sSubProject)
	string sYScale = COMBI_GetPluginString(sPluginName,"sYScale",sSubProject)
	string sPeaksPlotting = COMBI_GetPluginString(sPluginName,"sPeaksPlotting",sSubProject)
	string sTraceMode = COMBI_GetPluginString(sPluginName,"sTraceMode",sSubProject)
	int bMakeBackgroundTrace = COMBI_GetPluginNumber(sPluginName,"bMakeBackgroundTrace",sSubProject)
	int bMakeFullFitTrace = COMBI_GetPluginNumber(sPluginName,"bMakeFullFitTrace",sSubProject)
	int bMakeTracePerPeak = COMBI_GetPluginNumber(sPluginName,"bMakeTracePerPeak",sSubProject)
	int bMakeResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakeResidualsTrace",sSubProject)
	int bMakePercentResidualsTrace = COMBI_GetPluginNumber(sPluginName,"bMakePercentResidualsTrace",sSubProject)
	int bOutputPosScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	int bOutputAmpScalars = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	int bOutputFWHMScalars = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	int bOutputGFracScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	int bOutputGOFScalars = COMBI_GetPluginNumber(sPluginName,"bOutputGOFScalars",sSubProject)
	int bOutputPeakAreaScalars = COMBI_GetPluginNumber(sPluginName,"bOutputPeakAreaScalars",sSubProject)
	int bMakePlots = COMBI_GetPluginNumber(sPluginName,"bMakePlots",sSubProject)
	int bOutputPosScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputPosScalars",sSubProject)
	int bOutputAmpScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputAmpScalars",sSubProject)
	int bOutputFWHMScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputFWHMScalars",sSubProject)
	int bOutputGFracScalarsErr = COMBI_GetPluginNumber(sPluginName,"bOutputGFracScalars",sSubProject)
	int bSeeResiduals = COMBI_GetPluginNumber(sPluginName,"bSeeResiduals",sSubProject)
	string sPeaks2FitPerSample = COMBI_GetPluginString(sPluginName,"sPeaks2FitPerSample",sSubProject)
	
	//folder to hold fitting wave
	string sFitFolder = sPackageFolder+sProject+"_"+sLibrary+"_"+sDepData+"_"+sIndData
	variable vTotalSamples  = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	NewDataFolder/O $sFitFolder 
	string sFitInputs = sFitFolder+":FitInputs"
	Make/T/O/N=((vTotalSamples+17),vPeaksToFit) $sFitInputs
	wave/T wFitInputs = $sFitInputs
	int iPeak, iSample
	for(iPeak=0;iPeak<vPeaksToFit;iPeak+=1)
		SetDimLabel 1,iPeak,$stringfromlist(iPeak,sPeakTagList),wFitInputs
		//name
		SetDimLabel 0,0,Name,wFitInputs
		wFitInputs[0][iPeak] = stringfromlist(iPeak,sPeakTagList)
		//coef
		SetDimLabel 0,1,$"Pos",wFitInputs
		SetDimLabel 0,2,$"Amp",wFitInputs
		SetDimLabel 0,3,$"FWHM",wFitInputs
		SetDimLabel 0,4,$"GFrac",wFitInputs
		wFitInputs[1][iPeak] = stringfromList(iPeak,sXPosList)
		wFitInputs[2][iPeak] = stringfromList(iPeak,sAmpList)
		wFitInputs[3][iPeak] = stringfromList(iPeak,sFWHMList)
		wFitInputs[4][iPeak] = stringfromList(iPeak,sGFracList)
		//LB
		SetDimLabel 0,5,$"Pos_LB",wFitInputs
		SetDimLabel 0,6,$"Amp_LB",wFitInputs
		SetDimLabel 0,7,$"FWHM_LB",wFitInputs
		SetDimLabel 0,8,$"GFrac_LB",wFitInputs
		wFitInputs[5][iPeak] = stringfromList(iPeak,sXPosLBList)
		wFitInputs[6][iPeak] = stringfromList(iPeak,sAmpLBList)
		wFitInputs[7][iPeak] = stringfromList(iPeak,sFWHMLBList)
		wFitInputs[8][iPeak] = stringfromList(iPeak,sGFracLBList)
		//UB
		SetDimLabel 0,9,$"Pos_UB",wFitInputs
		SetDimLabel 0,10,$"Amp_UB",wFitInputs
		SetDimLabel 0,11,$"FWHM_UB",wFitInputs
		SetDimLabel 0,12,$"GFrac_UB",wFitInputs
		wFitInputs[9][iPeak] = stringfromList(iPeak,sXPosUBList)
		wFitInputs[10][iPeak] = stringfromList(iPeak,sAmpUBList)
		wFitInputs[11][iPeak] = stringfromList(iPeak,sFWHMUBList)
		wFitInputs[12][iPeak] = stringfromList(iPeak,sGFracUBList)
		//Ep
		SetDimLabel 0,13,$"Pos_Ep",wFitInputs
		SetDimLabel 0,14,$"Amp_Ep",wFitInputs
		SetDimLabel 0,15,$"FWHM_Ep",wFitInputs
		SetDimLabel 0,16,$"GFrac_Ep",wFitInputs
		wFitInputs[13][iPeak] = stringfromList(iPeak,sXPosEpList)
		wFitInputs[14][iPeak] = stringfromList(iPeak,sAmpEpList)
		wFitInputs[15][iPeak] = stringfromList(iPeak,sFWHMEpList)
		wFitInputs[16][iPeak] = stringfromList(iPeak,sGFracEpList)
		
		for(iSample=0;iSample<vTotalSamples;iSample+=1)
			SetDimLabel 0,17+iSample,$"S"+num2str(iSample+1),wFitInputs
			wFitInputs[17+iSample][iPeak] = stringfromlist(iPeak,stringfromlist(iSample,sPeaks2FitPerSample,"$"))
		endfor
	endfor
	
	
	MultiPeakFit_LibraryFit(wFitInputs,sProject,sLibrary,sDepData,sIndData,vSampleStart,vSampleEnd,sAmpScaleType,vBgScaleLocation,sBKGRDOrder,vEpsPoly,bMakeBackgroundTrace,bMakeFullFitTrace,bMakeTracePerPeak,bMakeResidualsTrace,bMakePercentResidualsTrace,bOutputPosScalars,bOutputAmpScalars,bOutputFWHMScalars,bOutputGFracScalars,bOutputGOFScalars,bOutputPeakAreaScalars,	bOutputPosScalarsErr,bOutputAmpScalarsErr,bOutputFWHMScalarsErr,bOutputGFracScalarsErr,bSeeResiduals,bMakePlots)	
	//print call line here
	
end	

Function MultiPeakFit_LibraryFit(wFitInputs,sProject,sLibrary,sDepData,sIndData,vSampleStart,vSampleEnd,sAmpScaleType,vBgScaleLocation,sBKGRDOrder,vEpsPoly,bMakeBackgroundTrace,bMakeFullFitTrace,bMakeTracePerPeak,bMakeResidualsTrace,bMakePercentResidualsTrace,bOutputPosScalars,bOutputAmpScalars,bOutputFWHMScalars,bOutputGFracScalars,bOutputGOFScalars,bOutputPeakAreaScalars,bOutputPosScalarsErr,bOutputAmpScalarsErr,bOutputFWHMScalarsErr,bOutputGFracScalarsErr,bSeeResiduals,bMakePlots)
	wave/T wFitInputs
	string sProject,sLibrary,sDepData,sIndData //source data
	variable vSampleStart,vSampleEnd // active sample range
	string sBKGRDOrder
	string sAmpScaleType// scaling
	variable vBgScaleLocation// sclaing @ x
	variable vEpsPoly // epslon value for the poly
	//output options
	int bMakeBackgroundTrace,bMakeFullFitTrace,bMakeTracePerPeak,bMakeResidualsTrace,bMakePercentResidualsTrace
	int bOutputPosScalars,bOutputAmpScalars,bOutputFWHMScalars,bOutputGFracScalars
	int bOutputGOFScalars,bOutputPeakAreaScalars
	int bOutputPosScalarsErr,bOutputAmpScalarsErr,bOutputFWHMScalarsErr,bOutputGFracScalarsErr 
	int bSeeResiduals,bMakePlots
	
	int iSample
	int vSample
	int iPeak
	int iPoint
	
	variable vTotalSamples  = COMBI_GetGlobalNumber("vTotalSamples",sProject)
	
	//data exist to fit?
	wave/Z wXWave = $COMBI_DataPath(COMBI_GetPluginString(sPluginName,"sProject",sProject),2)+COMBI_GetPluginString(sPluginName,"sLibrary",sProject)+":"+COMBI_GetPluginString(sPluginName,"sIndData",sProject)
	wave/Z wYWave = $COMBI_DataPath(COMBI_GetPluginString(sPluginName,"sProject",sProject),2)+COMBI_GetPluginString(sPluginName,"sLibrary",sProject)+":"+COMBI_GetPluginString(sPluginName,"sDepData",sProject)
	if(!waveExists(wYWave)||!WaveExists(wXWave))//data exist,must be fully defined
		DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit couldn't find the X-Y data and aborted"
		return -1
	endif
	
	//clean list?
	for(iPeak=0;iPeak<dimsize(wFitInputs,1);iPeak+=1)
		if(numtype(str2num(wFitInputs[%Pos][iPeak]))==2)
			DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in Center and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%FWHM][iPeak]))==2)
			DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in FWHM and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%Amp][iPeak]))==2)
			DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in Amp and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%GFrac][iPeak]))==2)
		 	DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in GFrac and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%Pos_Ep][iPeak]))==2)
			DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in Center Epsilon and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%FWHM_Ep][iPeak]))==2)
			DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in FWHM Epsilon and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%Amp_Ep][iPeak]))==2)
			DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in Amp Epsilon and aborted"
			return -1
		elseif(numtype(str2num(wFitInputs[%GFrac_Ep][iPeak]))==2)
			 DoAlert/T="Input Error",0,"MultiPeakFit_LibraryFit had a non-number input in GFrac Epsilon and aborted"
			return -1
		endif
	endfor
	
	variable vDepMax = Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Max")
	variable vDepMin = Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Min")
	variable vIndMax = Combi_Extremes(sProject,2,sIndData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Max")
	variable vIndMin = Combi_Extremes(sProject,2,sIndData,sLibrary,num2str(vSampleStart)+";"+num2str(vSampleEnd)+"; ; ; ; ","Min")
	variable vIndRange = vIndMax - vIndMin
	variable vDepRange = vDepMax-vDepMin
	
	//folder to hold fitting waves
	string sFitFolder = sPackageFolder+sProject+"_"+sLibrary+"_"+sDepData+"_"+sIndData
	NewDataFolder/O $sFitFolder 
	
	//folder to holde results
	string sLibraryFolder = Combi_DataPath(sProject,2)+sLibrary+":"
	string sDumbLibraryFolder = Combi_DataPath(sProject,2)+"FromMappingGrid:"
	string sPeakResultsFolder = sLibraryFolder+"Fit_"+sDepData+"_vs_"+sIndData
	string sNewDataName, sNewWave, sRealWavePath
	newdatafolder/O $sPeakResultsFolder
	sPeakResultsFolder+=":"
	
	
	//sAmpScaleType , vBgScaleLocation
	variable vSampleShift
	variable vSampleScale
	if(stringmatch(sAmpScaleType,"None"))
		vSampleShift = 0
		vSampleScale = 1
	elseif(stringmatch(sAmpScaleType,"Library Max Normalized"))
		vSampleShift = 0
		vSampleScale = 1/Combi_Extremes(sProject,2,sDepData,sLibrary," ; ; ; ; ; ","Max")
	elseif(stringmatch(sAmpScaleType,"Sample Max Normalized"))
		vSampleShift = 0
	elseif(stringmatch(sAmpScaleType,"Scale"))
		vSampleShift = 0
	elseif(stringmatch(sAmpScaleType,"Shift"))
		vSampleScale = 1
	endif
	
	variable vBKFCoefs
	if(stringmatch(sBKGRDOrder,"None"))
		vBKFCoefs = 0
	else
		vBKFCoefs = str2num(sBKGRDOrder)+1
	endif
		
	//fit active samples
	vSample = vSampleStart
	COMBI_ProgressWindow("sMULTIpeakfitProgress","Fitting in Progress","Fitting Peaks",(vSample-vSampleStart+1),(vSampleEnd-vSampleStart+1))
	for(vSample=vSampleStart;vSample<=vSampleEnd;vSample+=1)
		iSample = vSample-1

		//fitting waves
		string sCoefWave = sFitFolder+":Coef"+num2str(vSample)
		Make/D/O/N=(vBKFCoefs) $sCoefWave
		wave wCoef = $sCoefWave
		string sEpWave = sFitFolder+":Epsilon"+num2str(vSample)
		Make/O/N=(vBKFCoefs) $sEpWave
		wave wEp = $sEpWave
		string sConWave = sFitFolder+":Constraints"+num2str(vSample)
		Make/O/T/N=0 $sConWave
		wave/T wCons = $sConWave

		//waves of data 2 fit
		string sX2Fit = sFitFolder+":X2Fit"
		Make/O/N=(dimsize(wXWave,1)) $sX2Fit
		wave wX2Fit = $sX2Fit
		wX2Fit[] = wXWave[iSample][p]
		string sY2Fit = sFitFolder+":Y2Fit"
		Make/O/N=(dimsize(wYWave,1)) $sY2Fit
		wave wY2Fit = $sY2Fit
		wY2Fit[] = wYWave[iSample][p]
		string sBKG2Fit = sFitFolder+":BKG2Fit"
		Make/O/N=(dimsize(wYWave,1)) $sBKG2Fit
		wave wBKG2Fit = $sBKG2Fit
		wBKG2Fit[] = wYWave[iSample][p]
		string sDepDeriv = sFitFolder+":DepDeriv"
		Make/O/N=(dimsize(wYWave,1)-1) $sDepDeriv
		wave wDepDeriv = $sDepDeriv
		wDepDeriv[] = wYWave[iSample][p]
		string sDepDerivHist = sFitFolder+":DepDerivHist"
		Make/O/N=(101) $sDepDerivHist
		wave wDepDerivHist = $sDepDerivHist
		wDepDerivHist[] = 0
		SetScale/I x, 0, 100, wDepDerivHist
		string sRES = sFitFolder+":RES"
		Make/O/N=(dimsize(wYWave,1)) $sRES
		wave wRES = $sRES
		wRES[] = nan
		string sFIT = sFitFolder+":FIT"
		Make/O/N=(dimsize(wYWave,1)) $sFIT
		wave wFIT = $sFIT
		wFIT[] = nan
		string sErr = sFitFolder+":Err"
		Make/O/N=(dimsize(wYWave,0),2) $sErr
		wave wErr = $sErr
		wErr[][] = nan
		
		//scaling	
		int iScaleLoc = 0
		if(stringmatch(sAmpScaleType,"Sample Max Normalized"))
			vSampleScale = 1/Combi_Extremes(sProject,2,sDepData,sLibrary,num2str(vSample)+";"+num2str(vSample)+"; ; ; ; ","Max")
		elseif(stringmatch(sAmpScaleType,"Scale"))
			FindLevel/Q/P wX2Fit vBgScaleLocation
			iScaleLoc = V_LevelX
			vSampleScale =  (wYWave[(vSampleStart-1)][iScaleLoc])/(wYWave[iSample][iScaleLoc])
		elseif(stringmatch(sAmpScaleType,"Shift"))
			vSampleShift = wYWave[(vSampleStart-1)][iScaleLoc] - wYWave[iSample][iScaleLoc]
		endif
		
		//apply shift and scale
		wY2Fit[] = (wYWave[iSample][p]*vSampleScale)+vSampleShift
		
		//make data to find background
		int iData
		wBKG2Fit[] = wY2Fit[p]
		Smooth/B=2 3, wBKG2Fit
		for(iData=0;iData<dimsize(wDepDeriv,0);iData+=1)//take derivative
			wDepDeriv[iData] = ((wBKG2Fit[iData+1])-(wBKG2Fit[iData]))
		endfor
		wBKG2Fit[]=nan
		variable vThisMax = wavemax(wDepDeriv)
		variable vThisMin = wavemin(wDepDeriv)
		variable vThisRange = vThisMax-vThisMin
		for(iData=0;iData<dimsize(wDepDeriv,0);iData+=1)//make histograhm of derviatives
			variable vThisDeriv = wDepDeriv[iData]
			int iHistLoc = floor(((vThisDeriv-vThisMin)/vThisRange)*100)
			wDepDerivHist[iHistLoc]+=1
		endfor
		wave wDerivHistCoef = newfreeWave(4,4)
		CurveFit/Q/N=1 gauss, kwCWave=wDerivHistCoef, wDepDerivHist 
		variable vDerivMax = (wDerivHistCoef[2]+wDerivHistCoef[3])/100*vThisRange+vThisMin
		variable vDerivMin = (wDerivHistCoef[2]-wDerivHistCoef[3])/100*vThisRange+vThisMin
		for(iData=1;iData<dimsize(wDepDeriv,0);iData+=1)//take derivative
			if((vDerivMin<wDepDeriv[iData])&&(vDerivMax>wDepDeriv[iData]))
				wBKG2Fit[iData] = wY2Fit[iData]
			endif
		endfor
		
		int iLow, iHigh 
		//set the Amp to the nan in the wave in each FWHM window
		for(iPeak=0;iPeak<(dimsize(wFitInputs,1));iPeak+=1)
			if(str2num(wFitInputs[%$"S"+num2str(vSample)][iPeak])==1)
				FindLevel/Q/P wX2Fit str2num(wFitInputs[%Pos][iPeak])-str2num(wFitInputs[%FWHM][iPeak])
				iLow = V_LevelX
				FindLevel/Q/P wX2Fit str2num(wFitInputs[%Pos][iPeak])+str2num(wFitInputs[%FWHM][iPeak])
				iHigh = V_LevelX
				wBKG2Fit[iLow,iHigh] = nan
			endif
		endfor
		
		//inital Background fit
		if(!stringmatch(sBKGRDOrder,"None"))
			if(str2num(sBKGRDOrder)==0)
				wavestats/Q wBKG2Fit
				wCoef[0] = V_avg
				wEp[0] = vEpsPoly //epsilon
			elseif(str2num(sBKGRDOrder)==1)
				wave wBKGPoly = newfreeWave(4,2)
				Curvefit/Q/W=2/N=1 line,kwCWave=wBKGPoly,wBKG2Fit /X=wX2Fit
				wCoef[0,1] = wBKGPoly[p]
				wEp[0,1] = vEpsPoly //epsilon
			else
				wave wBKGPoly = newfreeWave(4,vBKFCoefs)
				Curvefit/Q/W=2/N=1 Poly vBKFCoefs,kwCWave=wBKGPoly,wBKG2Fit /X=wX2Fit
				wCoef[0,(vBKFCoefs-1)] = wBKGPoly[p]
				wEp[0,(vBKFCoefs-1)] = vEpsPoly //epsilon
			endif
		endif
		
			
		int iCon = 0
		string sPeakShortList = ""
		int vTotalPeaksShortList = 0
		int iCoef = vBKFCoefs
		
		for(iPeak=0;iPeak<dimsize(wFitInputs,1);iPeak+=1)
					
			variable vXPos = str2num(wFitInputs[%Pos][iPeak])
			variable vFWHM = str2num(wFitInputs[%FWHM][iPeak])
			variable vAmp = str2num(wFitInputs[%Amp][iPeak])
			variable vGFrac = str2num(wFitInputs[%GFrac][iPeak])
			variable vXPosUB = str2num(wFitInputs[%Pos_UB][iPeak])
			variable vFWHMUB = str2num(wFitInputs[%FWHM_UB][iPeak])
			variable vAmpUB = str2num(wFitInputs[%Amp_UB][iPeak])
			variable vGFracUB = str2num(wFitInputs[%GFrac_UB][iPeak])
			variable vXPosLB = str2num(wFitInputs[%Pos_LB][iPeak])
			variable vFWHMLB = str2num(wFitInputs[%FWHM_LB][iPeak])
			variable vAmpLB = str2num(wFitInputs[%Amp_LB][iPeak])
			variable vGFracLB = str2num(wFitInputs[%GFrac_LB][iPeak])
			variable vXPosEp = str2num(wFitInputs[%Pos_Ep][iPeak])
			variable vFWHMEp = str2num(wFitInputs[%FWHM_Ep][iPeak])
			variable vAmpEp = str2num(wFitInputs[%Amp_Ep][iPeak])
			variable vGFracEp = str2num(wFitInputs[%GFrac_Ep][iPeak])
			string sPeakTag = wFitInputs[0][iPeak]
			
			if(str2num(wFitInputs[%$"S"+num2str(vSample)][iPeak])==1)
				redimension/N=(dimsize(wCoef,0)+4) wCoef 
				redimension/N=(dimsize(wEp,0)+4) wEp 
				vTotalPeaksShortList+=1
				sPeakShortList+=sPeakTag+";"
				
				//Center
				wCoef[iCoef] = vXPos//initial guess for peak center
				wEp[iCoef] = vXPosEp//Ep for peak center
				if(numtype(vXPosLB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > "+num2str(vXPosLB)
					iCon+=1
				else
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > "+num2str(vIndMin)
					iCon+=1
				endif
				if(numtype(vXPosUB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(vXPosUB)
					iCon+=1
				else
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(vIndMax)
					iCon+=1
				endif
				
				//Amp
				iCoef+=1
				FindLevel/Q/P wX2Fit str2num(wFitInputs[%Pos][iPeak])-0.5*str2num(wFitInputs[%FWHM][iPeak])
				iLow = V_LevelX
				FindLevel/Q/P wX2Fit str2num(wFitInputs[%Pos][iPeak])+0.5*str2num(wFitInputs[%FWHM][iPeak])
				iHigh = V_LevelX
				wCoef[iCoef] = wavemax(wY2Fit,pnt2x(wY2Fit,iLow),pnt2x(wY2Fit,iHigh))-MultiPeakFit_PolyBG((vBKFCoefs-1),wCoef,str2num(wFitInputs[%Pos][iPeak]))
				wEp[iCoef] = vAmpEp//Ep for peak center
				if(numtype(vAmpLB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > "+num2str(vAmpLB)
					iCon+=1
				else
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > "+num2str(0)
					iCon+=1
				endif
				if(numtype(vAmpUB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(vAmpUB)
					iCon+=1
				else
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(vDepMax)
					iCon+=1
				endif
				
				//FWHM
				iCoef+=1
				wCoef[iCoef] = vFWHM//initial guess for peak fwhm
				wEp[iCoef] = vFWHMEp//Ep for peak center
				if(numtype(vFWHMLB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > "+num2str(vFWHMLB)
					iCon+=1
				else
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > 0"
					iCon+=1
				endif
				if(numtype(vFWHMUB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(vFWHMUB)
					iCon+=1
				else
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(0.5*vIndRange)
					iCon+=1
				endif
				
				//GFrac
				iCoef+=1
				wCoef[iCoef] = vGFrac//initial guess for peak fwhm
				wEp[iCoef] = vGFracEp//Ep for peak center
				if(numtype(vGFracLB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > "+num2str(vGFracLB)
					iCon+=1
				else 
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" > 0"
					iCon+=1
				endif
				if(numtype(vGFracUB)==0)
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < "+num2str(vGFracUB)
					iCon+=1
				else 
					redimension/N=(iCon+1) wCons
					wCons[iCon] = "K"+num2str(iCoef)+" < 1"
					iCon+=1
				endif
				
				iCoef+=1
			endif
		endfor
			
		//Do the fit
		
		if(vBKFCoefs==0)
			FuncFit/Q  MultiPeakFit_N_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		elseif(vBKFCoefs==1)
			FuncFit/Q  MultiPeakFit_0_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		elseif(vBKFCoefs==2)
			FuncFit/Q  MultiPeakFit_1_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		elseif(vBKFCoefs==3)
			FuncFit/Q  MultiPeakFit_2_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		elseif(vBKFCoefs==4)
			FuncFit/Q  MultiPeakFit_3_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		elseif(vBKFCoefs==5)
			FuncFit/Q  MultiPeakFit_4_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		elseif(vBKFCoefs==6)	
			FuncFit/Q  MultiPeakFit_5_PseudoVoigts wCoef wY2Fit /X=wX2Fit /D=wFIT /R=wRES /E=wEp /C=wCons
		endif
		wave wErrsFromFit  = W_Sigma
		variable vChiSq = V_chisq	
		
		if(bMakeBackgroundTrace)
			sNewDataName = "Fit_Bkgrd"
			if(!waveexists($sPeakResultsFolder+sNewDataName))
				Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,2,iVDim=dimsize(wFIT,0))
				MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
			endif
			wave wOUT = $sPeakResultsFolder+sNewDataName
			for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
				wOUT[iSample][iPoint] = MultiPeakFit_PolyBG((vBKFCoefs-1),wCoef,wX2Fit[iPoint])
			endfor
		endif
		if(bMakeFullFitTrace)
			sNewDataName = "AllPeaks_Fit"
			if(!waveexists($sPeakResultsFolder+sNewDataName))
				Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,2,iVDim=dimsize(wFIT,0))
				MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
			endif
			wave wOUT = $sPeakResultsFolder+sNewDataName
			for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
				wOUT[iSample][iPoint] = MultiPeakFit_PseudoVoigts((vBKFCoefs-1),wCoef,wX2Fit[iPoint])
			endfor
		endif
		if(bMakeTracePerPeak)
			for(iPeak=0;iPeak<vTotalPeaksShortList;iPeak+=1)
				iCoef = vBKFCoefs+(iPeak*4)//pos coef index
				wave wSinglePeak = newfreeWave(4,4)
				wSinglePeak[0,3] = wCoef[p+iCoef]
				sNewDataName = stringfromlist(iPeak,sPeakShortList)+"_Fit"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,2,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
					wOUT[iSample][iPoint] = SingPseudoVoigt(wSinglePeak,wX2Fit[iPoint])
				endfor
			endfor
		endif
		if(bMakeResidualsTrace)
			sNewDataName = "AllPeaks_Res"
			if(!waveexists($sPeakResultsFolder+sNewDataName))
				Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,2,iVDim=dimsize(wFIT,0))
				MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
			endif
			wave wOUT = $sPeakResultsFolder+sNewDataName
			for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
				wOUT[iSample][iPoint] = wY2Fit[iPoint] - MultiPeakFit_PseudoVoigts((vBKFCoefs-1),wCoef,wX2Fit[iPoint])
			endfor
		endif
		if(bMakePercentResidualsTrace)
			sNewDataName = "AllPeaks_Res_Percent"
			if(!waveexists($sPeakResultsFolder+sNewDataName))
				Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,2,iVDim=dimsize(wFIT,0))
				MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
			endif
			wave wOUT = $sPeakResultsFolder+sNewDataName
			for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
				wOUT[iSample][iPoint] = (wY2Fit[iPoint] - MultiPeakFit_PseudoVoigts((vBKFCoefs-1),wCoef,wX2Fit[iPoint]))/wY2Fit[iPoint]*100
			endfor
		endif
		if(bOutputGOFScalars)
			sNewDataName = "AllPeaks_ChiSq"
			if(!waveexists($sPeakResultsFolder+sNewDataName))
				Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
				MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
			endif
			wave wOUT = $sPeakResultsFolder+sNewDataName
			wOUT[iSample] = vChiSq
		endif
		
		int iPeakOut
		for(iPeakOut=0;iPeakOut<vTotalPeaksShortList;iPeakOut+=1)
			iCoef = vBKFCoefs+(iPeakOut*4)
			if(bOutputPosScalars)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_Center"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wCoef[iCoef]
			endif
			if(bOutputAmpScalars)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_Amp"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wCoef[iCoef+1]
			endif
			if(bOutputFWHMScalars)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_FWHM"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wCoef[iCoef+2]
			endif
			if(bOutputGFracScalars)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_GFrac"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wCoef[iCoef+3]
			endif
			if(bOutputPosScalarsErr)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_STDev_Center"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wErrsFromFit[iCoef]
			endif
			if(bOutputAmpScalarsErr)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_STDev_Amp"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wErrsFromFit[iCoef+1]
			endif
			if(bOutputFWHMScalarsErr)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_STDev_FWHM"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wErrsFromFit[iCoef+2]
			endif
			if(bOutputGFracScalarsErr )
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_STDev_GFrac"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wOUT[iSample] = wErrsFromFit[iCoef+3]
			endif
			if(bOutputPeakAreaScalars)
				sNewDataName = stringfromlist(iPeakOut,sPeakShortList)+"_Area"
				if(!waveexists($sPeakResultsFolder+sNewDataName))
					Combi_AddDataType(sProject,"FromMappingGrid",sNewDataName,1,iVDim=dimsize(wFIT,0))
					MoveWave $sDumbLibraryFolder+sNewDataName, $sPeakResultsFolder+sNewDataName
				endif
				wave wOUT = $sPeakResultsFolder+sNewDataName
				wave wSinglePeak = newfreeWave(4,4)
				wSinglePeak[0,3] = wCoef[p+iCoef]
				wOUT[iSample]=0
				for(iPoint=1;iPoint<dimsize(wX2Fit,0);iPoint+=1)
					variable vSome2Add = (SingPseudoVoigt(wSinglePeak,wX2Fit[iPoint])*(wX2Fit[iPoint]-wX2Fit[iPoint-1]))
					if(numtype(vSome2Add)==0)
						wOUT[iSample]+=vSome2Add
					endif
				endfor
			endif
		endfor
		
		PauseUpdate
		if(bMakePlots)
			string sFont = COMBI_GetGlobalString("sFontOption","COMBIgor")
			NewDataFolder/O root:Packages:COMBIgor:DisplayWaves
			string sDisplayWavePath = "root:Packages:COMBIgor:DisplayWaves:"+"Lib_"+sLibrary+"_MPFit_"+sDepData+"_vs_"+sIndData+"_S"+num2str(vSample)
			Make/O/N=((dimsize(wFIT,0)),(6+vTotalPeaksShortList)) $sDisplayWavePath
			wave wDisplay = $sDisplayWavePath
			wave wSinglePeak = newfreeWave(4,4)
			wSinglePeak[] = wCoef[p]		
			
			for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
				wDisplay[iPoint][0]=wX2Fit[iPoint]//x
				wDisplay[iPoint][1]=wY2Fit[iPoint]//raw y
				wDisplay[iPoint][2]=MultiPeakFit_PseudoVoigts((vBKFCoefs-1),wCoef,wX2Fit[iPoint])//whole fit y
				wDisplay[iPoint][3]=wY2Fit[iPoint]-MultiPeakFit_PseudoVoigts((vBKFCoefs-1),wCoef,wX2Fit[iPoint])//res y
				wDisplay[iPoint][4]=(wY2Fit[iPoint]-MultiPeakFit_PseudoVoigts((vBKFCoefs-1),wCoef,wX2Fit[iPoint]))/wY2Fit[iPoint]*100//res y percent
				if(vBKFCoefs==0)
					wDisplay[iPoint][5]=0
				elseif(vBKFCoefs==1)
					wDisplay[iPoint][5] = wCoef[0]
				elseif(vBKFCoefs==2)
					wDisplay[iPoint][5] = wCoef[0]+wCoef[1]*wX2Fit[iPoint]
				else
					wave wBKGPoly = newfreeWave(4,vBKFCoefs)
					wBKGPoly[0,(vBKFCoefs-1)] = wCoef[p]
					wDisplay[iPoint][5] = poly(wBKGPoly,wX2Fit[iPoint])
				endif
			endfor
			
			for(iPeak=0;iPeak<vTotalPeaksShortList;iPeak+=1)
				iCoef = vBKFCoefs+(iPeak*4)//pos coef index
				wSinglePeak[0,3] = wCoef[p+iCoef]
				for(iPoint=0;iPoint<dimsize(wX2Fit,0);iPoint+=1)
					wDisplay[iPoint][6+iPeak]=SingPseudoVoigt(wSinglePeak,wX2Fit[iPoint])+wDisplay[iPoint][5]
				endfor
			endfor
					
			string sWinName = COMBI_NewPlot("Lib_"+sLibrary+"_MPFit_"+sDepData+"_vs_"+sIndData+"_S"+num2str(vSample))
			string sThisPeakColor = "(65535,0,0)"
			SetWindow $sWinName,hook(kill)=MultiPeakFits_KillDisplayData
			SetWindow $sWinName,userdata(DisplayDataTag)=sDisplayWavePath	
			ModifyGraph/W=$sWinName width=600,height=300
			ModifyGraph/W=$sWinName margin(right)=150
			AppendToGraph/L/B/W=$sWinName wDisplay[][2]/TN=FIT vs wDisplay[][0]
			Execute "ModifyGraph/W="+sWinName+" rgb(FIT)="+sThisPeakColor
			ModifyGraph/W=$sWinName mode(FIT)=7,hbFill(FIT)=2
			for(iPeak=0;iPeak<vTotalPeaksShortList;iPeak+=1)
				sThisPeakColor = COMBI_GetUniqueColor(iPeak+2,vTotalPeaksShortList+2,sColorTheme="Rainbow")
				string sThisTraceName = stringfromlist(iPeak,sPeakShortList)
				AppendToGraph/L/B/W=$sWinName wDisplay[][iPeak+6]/TN=$sThisTraceName vs wDisplay[][0]
				ModifyGraph/W=$sWinName mode($sThisTraceName)=7,lsize($sThisTraceName)=1,usePlusRGB($sThisTraceName)=0,hbFill($sThisTraceName)=5
				Execute "ModifyGraph/W="+sWinName+" rgb("+sThisTraceName+")="+sThisPeakColor
			endfor
			sThisPeakColor = COMBI_GetUniqueColor(iPeak+1,vTotalPeaksShortList+2,sColorTheme="Rainbow")
			AppendToGraph/L/B/W=$sWinName wDisplay[][5]/TN=BKGRD vs wDisplay[][0]
			Execute "ModifyGraph/W="+sWinName+" rgb(BKGRD)="+sThisPeakColor
			ModifyGraph/W=$sWinName mode(BKGRD)=7,hbFill(BKGRD)=6
			AppendToGraph/L/B/W=$sWinName wDisplay[][1]/TN=Raw vs wDisplay[][0]
			ModifyGraph/W=$sWinName mode(Raw)=3,marker(Raw)=8,msize(Raw)=2,rgb(Raw)=(0,0,0),mrkThick(Raw)=1
			Legend/C/N=TraceLeg/F=0/A=RC/X=2.00/Y=0.00/E
			if(wavemin(wX2Fit)>0)
				ModifyGraph/W=$sWinName log(left)=1
			endif
			ModifyGraph/W=$sWinName mirror=1,nticks(bottom)=10,minor=1,fSize=12,font=sFont
			Label/W=$sWinName left sDepData
			Label/W=$sWinName bottom sIndData
			if(bSeeResiduals)
				//append residuals
				wave wThisRes = newfreeWave(4,dimsize(wX2Fit,0))
				wThisRes[] = wDisplay[p][3]
				wave wThisResPer = newfreeWave(4,dimsize(wX2Fit,0))
				wThisResPer[] = wDisplay[p][4]
				variable vMaxRes = max(abs(wavemax(wThisRes)),abs(wavemin(wThisRes)))
				variable vMaxResPer = max(abs(wavemax(wThisResPer)),abs(wavemin(wThisResPer)))
				ModifyGraph/W=$sWinName margin(top)=200, margin(left)=50
				Display/HOST=$sWinName/N=RES/W=(0,0,800,200)/L/T wDisplay[][3]/TN=Res vs wDisplay[][0]
				AppendToGraph/R/T/W=$sWinName+"#RES" wDisplay[][4]/TN=Res_Percent vs wDisplay[][0]
				ModifyGraph/W=$sWinName+"#RES" margin(right)=150, margin(left)=50,rgb(Res_Percent)=(0,0,65535)
				ModifyGraph/W=$sWinName+"#RES" mirror(top)=1,nticks(top)=10,minor=1,fSize=12,font=sFont, lblMargin(right)=90
				Label/W=$sWinName+"#RES" right "Percent (%)"
				Label/W=$sWinName+"#RES" left "Residual"
				ModifyGraph/W=$sWinName+"#RES" axRGB(left)=(65535,16385,16385),axRGB(right)=(0,0,65535),tlblRGB(left)=(65535,16385,16385),tlblRGB(right)=(0,0,65535),alblRGB(left)=(65535,16385,16385),alblRGB(right)=(0,0,65535)
				DrawLine/W=$sWinName+"#RES" 0,0.5,1,0.5
				SetAxis/W=$sWinName+"#RES" left -vMaxRes,vMaxRes
				SetAxis/W=$sWinName+"#RES" right -vMaxResPer,vMaxResPer
		
				setactiveSubwindow $sWinName
			endif 
			SetAxis left 1,100000
			•SetDrawEnv xcoord= rel,ycoord= rel,textxjust= 2,textyjust= 0;DrawText .95, .95,"\JCLibrary:\r"+sLibrary+"\r\rSample:\r "+num2str(vSample)
		endif	
		DoUpdate
		
		
		//progress if not first sample
		if((vSample-vSampleStart+1)!=1)
			COMBI_ProgressWindow("sMULTIpeakfitProgress","Fitting in Progress","Fitting Peaks",(vSample-vSampleStart+1),(vSampleEnd-vSampleStart+1))
		elseif(vSampleStart==vSampleEnd)
			COMBI_ProgressWindow("sMULTIpeakfitProgress","Fitting in Progress","Fitting Peaks",2,2)
		endif
		
	endfor
	KilldataFolder $sFitFolder
	ResumeUpdate
end

//function to kill wave after the plot is killed
function MultiPeakFits_KillDisplayData(s)
	STRUCT WMWinHookStruct &s
	if(s.eventCode==2)//window being killed
		//delete the column from the ref globals wave
		string sWinName = s.winName
		string sDisplayWavePath = GetUserData(sWinName,"", "DisplayDataTag")
		//delete traces from window
		string sAllTraces = TraceNameList(sWinName,";", 1 )
		int iTrace
		For(iTrace=0;iTrace<itemsinList(sAllTraces);iTrace+=1)
			string sThisTrace = stringFromList(iTrace,sAllTraces)
			RemovefromGraph/W=$sWinName/Z $sThisTrace
		endfor
		sAllTraces = TraceNameList(sWinName+"#RES",";", 1 )
		For(iTrace=0;iTrace<itemsinList(sAllTraces);iTrace+=1)
			sThisTrace = stringFromList(iTrace,sAllTraces)
			RemovefromGraph/W=$sWinName+"#RES"/Z $sThisTrace
		endfor
		wave wToKill = $sDisplayWavePath
		Killwaves/Z wToKill
	endif
end

function/S MultiPeakFit_GetRefNames(sType)
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

///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Fit Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


// Fitting function for an arbitrary number of pseudo-Voigt peaks + a cubic background
// Calculates number of peaks based on number of points in wFitParams input
// wFitParams is K0, K1, K2, K3, K4 ,n*(amp, Center, width, GFrac)
//
// input wFitParams: wave of initial guesses for the fit
// input x: independent value 
//
// output: y: dependant value at x

Function MultiPeakFit_N_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0))/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[0+(iPeak*4)]
		variable vAmp = wFitParams[1+(iPeak*4)]
		variable vFWHM = wFitParams[2+(iPeak*4)]
		variable vFracGauss = wFitParams[3+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	return vreturn
End

Function MultiPeakFit_0_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0)-1)/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[1+(iPeak*4)]
		variable vAmp = wFitParams[2+(iPeak*4)]
		variable vFWHM = wFitParams[3+(iPeak*4)]
		variable vFracGauss = wFitParams[4+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	vreturn += wFitParams[0] 
	
	return vreturn
End

Function MultiPeakFit_1_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0)-2)/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[2+(iPeak*4)]
		variable vAmp = wFitParams[3+(iPeak*4)]
		variable vFWHM = wFitParams[4+(iPeak*4)]
		variable vFracGauss = wFitParams[5+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	vreturn += wFitParams[0] + wFitParams[1]*x
	
	return vreturn
End

Function MultiPeakFit_2_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0)-3)/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[3+(iPeak*4)]
		variable vAmp = wFitParams[4+(iPeak*4)]
		variable vFWHM = wFitParams[5+(iPeak*4)]
		variable vFracGauss = wFitParams[6+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	vreturn += wFitParams[0] + wFitParams[1]*x + wFitParams[2]*x^2
	
	return vreturn
End

Function MultiPeakFit_3_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0)-4)/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[4+(iPeak*4)]
		variable vAmp = wFitParams[5+(iPeak*4)]
		variable vFWHM = wFitParams[6+(iPeak*4)]
		variable vFracGauss = wFitParams[7+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	vreturn += wFitParams[0] + wFitParams[1]*x + wFitParams[2]*x^2 + wFitParams[3]*x^3
	
	return vreturn
End

Function MultiPeakFit_4_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0)-5)/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[5+(iPeak*4)]
		variable vAmp = wFitParams[6+(iPeak*4)]
		variable vFWHM = wFitParams[7+(iPeak*4)]
		variable vFracGauss = wFitParams[8+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	vreturn += wFitParams[0] + wFitParams[1]*x + wFitParams[2]*x^2 + wFitParams[3]*x^3+wFitParams[4]*x^4
	
	return vreturn
End

Function MultiPeakFit_5_PseudoVoigts(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iNumPeaks = (DimSize(wFitParams,0)-6)/4
	
	// for each peak as determined by input fit parameters
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[6+(iPeak*4)]
		variable vAmp = wFitParams[7+(iPeak*4)]
		variable vFWHM = wFitParams[8+(iPeak*4)]
		variable vFracGauss = wFitParams[9+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	vreturn += wFitParams[0] + wFitParams[1]*x + wFitParams[2]*x^2 + wFitParams[3]*x^3+wFitParams[4]*x^4+wFitParams[5]*x^5
	
	return vreturn
End

Function SingPseudoVoigt(wFitParams, x) : FitFunc
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	variable vCenter = wFitParams[0]
	variable vAmp = wFitParams[1]
	variable vFWHM = wFitParams[2]
	variable vFracGauss = wFitParams[3]

	// add the gaussian terms
	vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
	// add the lorentzian terms
	vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	
	return vreturn
End

Function MultiPeakFit_PseudoVoigts(iOrder,wFitParams, x)
	int iOrder
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0
	int iBump = iOrder+1
	int iNumPeaks = (DimSize(wFitParams,0)-iBump)/4
	
	// for each peak as determined by input fit parameters
	
	for(iPeak=0; iPeak<iNumPeaks; iPeak+=1)
		variable vCenter = wFitParams[iBump+(iPeak*4)]
		variable vAmp = wFitParams[iBump+1+(iPeak*4)]
		variable vFWHM = wFitParams[iBump+2+(iPeak*4)]
		variable vFracGauss = wFitParams[iBump+3+(iPeak*4)]
		// add the gaussian terms
		vreturn += vFracGauss*vAmp*Exp( -4*Ln(2) *((x-vCenter)/vFWHM)^2 )
		// add the lorentzian terms
		vreturn += (1-vFracGauss)*vAmp*( 1 + (2*(x-vCenter)/vFWHM)^2 )^-1
	endFor
	
	// add in polynomial terms
	int iPoly
	for(iPoly=0;iPoly<=iOrder;iPoly+=1)
		vreturn += wFitParams[iPoly]*x^(iPoly)
	endfor
	
	return vreturn
End

Function MultiPeakFit_PolyBG(iOrder,wFitParams, x)
	int iOrder
	wave wFitParams
	variable x
	int iPeak
	variable vreturn=0

	// add in polynomial terms
	int iPoly
	for(iPoly=0;iPoly<=iOrder;iPoly+=1)
		vreturn += wFitParams[iPoly]*x^(iPoly)
	endfor
	
	return vreturn
End


///-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------- Plotting Functions Below Here -----------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MultiPeakFit_PlotVectorHeatMap(sProject,sLibrary,sDepData,sIndData,vSampleMin, vSampleMax)
	string sProject,sLibrary,sDepData,sIndData	
	variable vSampleMin, vSampleMax
	COMBIDisplay_Plot(sProject,"NewPlot","Vector",sLibrary,sIndData,"","Linear","Auto","Auto","Bottom","Scalar","FromMappingGrid","Sample","","Linear","Auto","Auto","Left","Vector",sLibrary,sDepData,"Log","Auto","Auto","YellowHot","","","","Linear","Auto","Auto",3,10,num2str(vSampleMin),num2str(vSampleMax),"All","All","All","All")
	ModifyGraph margin(left)=50,margin(bottom)=50,margin(top)=20,width=200,height=300
	ColorScale/C/N=zScaleLeg/B=1/X=-50.00/Y=0.00 tickLen=3.00
	ModifyGraph mirror=2,btLen=3,gbRGB=(0,0,0),msize=4
end

function MultiPeakFit_PlotSampleMap(sProject,sLibrary,sDepData,sIndData)
	string sProject,sLibrary,sDepData,sIndData	
   COMBIDisplay_Map(sProject,sLibrary,sDepData,"Linear","RedWhiteGreen"," ","-Linear","y(mm) vs x(mm)","Markers","None","*,*,*,*",16,"000000")
	Execute "ModifyGraph zColor(Linear)={:COMBIgor:"+sProject+":Data:"+sLibrary+":"+sDepData+",*,*,RedWhiteGreen,1}"
	ModifyGraph msize=6,useMrkStrokeRGB=1
end