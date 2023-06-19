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
log using "$log/02_shift_values.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "02_shift_values.do"
Content: Data preparation II: shift values to correct year
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v02, 25.02.2019
--------------------------------------------------------------------------------

uses:  "$data/panel-ACF-basic.dta"
saves: "$data/panel-ACF-basic.dta"

==============================================================================*/


/* Motivation: The majority of questions in the questionnaire are retrospective
relating to the previous year, i.e. firms are asked in 2014 about their value
added in 2013.  Hence, the the value added variable in 2014 stores the
value added of 2013 etc.*/

********************************************************************************
* 			Start							 
********************************************************************************


* load data set
* --------------
use "$data/panel-ACF-basic.dta", replace


* generate empty year 1992
* -------------------------
* total number of unique IDs
by idnum, sort: gen nvals = _n==1

* number of unique IDs in 1993
count if nvals==1 & jahr==1993

* duplicate year 1993 and relabel as year 1992
expand 2 if nvals==1 & jahr==1993, gen(Iexpand)
replace jahr=1992 if Iexpand==1
sort idnum jahr Iexpand

* Delete all values in 1992
quietly ds idnum jahr Iexpand, not // stores all variable names except 'idum jahr Iexpand' in r(varlist)
local toempty `r(varlist)' //stores 'r(varlist)' in a local
foreach var of local toempty{ 
local vartype: type `var'
if substr("`vartype'",1,3)=="str" {
replace `var' = "" if Iexpand == 1 // sets all variables from 'r(varlist)' to missing in year 1992
}
else { 
replace `var' = . if Iexpand == 1 // sets all variables from 'r(varlist)' to missing in year 1992
}
}


* generate all year-ID combinations
* ----------------------------------
* Notes: tsset & tfill generates all year-ID combinations to allow the shift of
* values in main variables for which no observation in previous year existed (e.g., 1992) 
gen Iorig=1
tsset idnum jahr
tsfill
sort idnum jahr


* generate new variables
* ----------------------
gen SALES_nom=bvole_c
gen SALES_type = bvtypa_d
gen SALES_export = reves_c
gen SALES_west = revsw_c
gen SALES_ost = revse_c
gen I_nom = insuml_c
gen I_share_erw = inexpa_c
gen M_share = revsp_c
gen L = decnub_c



* shift values to previous year
* -----------------------------
foreach var of varlist SALES_nom SALES_type SALES_export SALES_west SALES_ost I_nom M_share I_share_erw L{
bysort idnum (jahr): replace `var' = `var'[_n+1]
} 

* extend NACE code and industry to previous year if missing
* ----------------------------------------------------------
bysort idnum (jahr): replace br09_d = br09_d[_n+1] if br09_d==. & jahr>=2009
bysort idnum (jahr): replace br00_d = br00_d[_n+1] if br00_d==. & jahr>=2000 & jahr<2009
bysort idnum (jahr): replace br93_d = br93_d[_n+1] if br93_d==. & jahr>=1993 & jahr<2000

if $WZ08==1{
bysort idnum (jahr): replace wz08= wz08[_n+1] if wz08==.
} 


label variable SALES_nom "sales, current prices (nominal)"
label variable SALES_type "sales type (geschart t+1)"
label variable SALES_export "share foreign sales (%)"
label variable SALES_west "share sales alte Bundeslaender (%)"
label variable SALES_ost "share sales neue Bundeslaender (%)"
label variable I_nom "total investments, current prices (nominal)"
label variable I_share_erw "share expansion investments in total investments(%)"
label variable M_share "share intermediates in sales (%)"
label variable L "total number of employees"



* Delete all observations with missing values in main variables
* -------------------------------------------------------------
/* After the shifting routine, some year_ID observations have missing values 
throughout (no obs in subsequent year existed). Can be deleted.*/

drop if Iorig==. & SALES_nom==. & SALES_type==. & SALES_export==. & SALES_west==. & SALES_ost==. & I_nom==. & I_share_erw==. & M_share==.  & L==.

* clear
* ------
drop Iexpand Iorig nvals
sort idnum jahr


********************************************************************************
* Save and clean								 				 
********************************************************************************

compress
save "$data/panel-ACF-basic.dta", replace

********************************************************************************
* End of file	
log close							 				 
********************************************************************************