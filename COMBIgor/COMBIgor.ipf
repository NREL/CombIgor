#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3

// Description/Summary of Procedure File
// This file is designed to initialize COMBIgor in Igor 7
// Version History
// V1: Kevin Talley _ May 2018 : COMBIgor_2.0 Original

// Description of functions within:
// COMBI : Initialize COMBIgor

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Include Statements below ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------Functions Below  ------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function COMBI_Mount()

	if(strlen(FunctionList("COMBI", ";", "KIND:2" ))>0)
		DoAlert/T="Remove COMBIgor?",1,"Do you want to remove the COMBIgor package? Doing so won't remove data."
		if(V_flag==1)
			COMBI_Dismount()
			return -1
		endif
	endif
	
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Menu\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Data\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Library\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Prefs\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Instruments\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Plugins\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Display\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Load\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Manage\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Main\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_MetaData\""
	Execute/P/Q/Z "COMPILEPROCEDURES  "
	Execute/P/Q/Z "COMBI()"
	
end

function COMBI_Dismount()
	
	DoAlert/T="COMBIgor Unloaded" 1,"Do you really want to say goodbye to COMBIgor?"
	if(V_flag==2)
		return -1
	endif
	Execute/P/Q/Z "COMBI_KillAllAddOns()"
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Menu\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Data\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Library\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Prefs\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Instruments\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Plugins\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Display\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Load\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Manage\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Main\""
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_MetaData\""
	Execute/P/Q/Z "COMPILEPROCEDURES  "
	DoAlert/T="COMBIgor Unloaded" 0,"Thanks for using COMBIgor!"
end


// Although the following is a submenu it behaves like main menu.
Menu "Data"
	Submenu "Packages"
		"COMBIgor" ,/Q, COMBI_Mount()
	End
End

function CompileCOMBIgor()
	Execute/P/Q/Z "DELETEINCLUDE \"COMBI_Main\""
	Execute/P/Q/Z "INSERTINCLUDE \"COMBI_Main\""
	Execute/P/Q/Z "COMPILEPROCEDURES  "
end
