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
log using "$log/01_merge_confidential_data.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "03_merge_confidential_data.do"
Content: Data preparation I: Merge dditional IAB data
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v03, 02.06.2021
--------------------------------------------------------------------------------

uses:  "$data/BP_panelgen_9317_v2.dta"
saves: "$data/panel-ACF-basic.dta"

==============================================================================*/


********************************************************************************
* 			Start							 
********************************************************************************

* load IAB firm panel data set
* -----------------------------
use "$data/BP_panelgen_9317_v2.dta", clear

* merge with data set on time-consistent NACE codes
* -------------------------------------------------
if $JoSua==1{
merge 1:1 idnum jahr using $orig/iabbp_9319_v1_bhp_7519_m06_wgen_w08_v1.dta, keepusing(w08_3_gen) 
drop if _merge == 2
drop _merge
rename w08_3_gen wz08
display _N
}

********************************************************************************
* Clean and save
********************************************************************************

compress
display _N
save "$data/panel-ACF-basic.dta", replace


********************************************************************************
* End
log close
********************************************************************************