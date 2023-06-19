/*==============================================================================

				Article "Testing the Superstar Hypothesis"
				
					by Alexander Schiersch, Caroline Stiel
			DIW Berlin (German Institute for Economic Research)
				
				published in: Journal of Applied Economics
						Vol. 25, Issue 1, pp. 583-603

*=============================================================================*/


* Start Logfile
* -------------
cap log close
log using "$log/master.log", replace


/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "00_master.do"
Content: Master file
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
--------------------------------------------------------------------------------

==============================================================================*/


********************************************************************************
* 			Start							 
********************************************************************************


* Define working area - 0: DIW-Stucture dataset 1: remote access to true data
* ---------------------------------------------------------------------------
global JoSua 1

/*
if $JoSua==0{
	global REP 4 // Define DIW settings, e.g. bootstrap replications
}

if $JoSua==1{
	global REP 100 // Define JoSua settings, e.g. bootstrap replications
}
*/


********************************************************************************


********************************************************************************
* 						1) Global settings
********************************************************************************

*------------------------------------------------------------------------------
* 1.1) STATA settings	
*------------------------------------------------------------------------------

clear

set more off			
*set linesize 120		// max. number of lines Internal Mode
set linesize 255		// max.number of lines Presentation/Publication Mode


*------------------------------------------------------------------------------
* 1.2) Data settings		
*------------------------------------------------------------------------------

* detailed WZ information available?
global WZ08 1

*------------------------------------------------------------------------------
* 1.3) Install missing packages	
*------------------------------------------------------------------------------

*fdzinstall carryforward
*fdzinstall estout

********************************************************************************
* 				2) Run programs
********************************************************************************

*------------------------------------------------------------------------------*
* 2.1) Data preparation					
*------------------------------------------------------------------------------*

* run IAB .do file to generate panel data set
* -------------------------------------------
*cap noi do "$prog\BP_panelgen_9317_v2_cs_20210602.do"	

* merge confidential data (zeitkonsistente Wirtschaftszweige)
* -----------------------------------------------------------				
*cap noi do "$prog\01_merge_confidential data.do"

* shift values from interview year to year of interest
* -----------------------------------------------------		
*cap noi do "$prog\02_shift values.do"			

* merge external data (price indices, depreciation rates etc.)
* -------------------------------------------------------------		
*cap noi do "$prog\03_merge_external_data.do"	

* create additional variables
* ----------------------------	
*cap noi do "$prog\04_create_variables.do"				


*------------------------------------------------------------------------------
* 2.2) TFP estimation		
*------------------------------------------------------------------------------

* TFP estimation using CD production function
* --------------------------------------------
*cap noi do "$prog\05_TFPestimation.do" 


*-------------------------------------------------------------------------------
* 2.3) Main analysis: test the superstar hypotheses		
*-------------------------------------------------------------------------------

* Tests the hypotheses/assumptions of Autor et al. 2017
*cap noi do "$prog\06_main_analysis.do"


*-------------------------------------------*
* 2.4) Robustness checks
*-------------------------------------------*

* TFP net of markup effects
* --------------------------
*cap noi do "$prog\07_robustness_checks.do"


********************************************************************************
* End of file
cap log close
********************************************************************************
