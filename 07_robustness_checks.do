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
log using "$log/07_robustness_checks.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "07_robustness_checks.do"
Content: Tests hypothesis from Autor et al. 2017 NBER WP No. 23396
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v46, 30.06.2021
--------------------------------------------------------------------------------

uses: "$data\OMEGA23.dta", "$data\OMEGA24.dta"

results for tables/figures in article: Table B3

File structure
--------------
1) Load TFP and markup estimates
2) Generate additional variables
3) Prepare verification of compliance with confidentiality restrictions
4) Estimate relationship between TFP and controls by industry
	4.1 Estimate correlation between TFP and labor share
	4.2 Estimate correlation between TFP and firm size	(value added)
	4.3 Estimate correlation between TFP and market share
	4.4 Estimate correlation between TFP and material share
	4.5 Estimate correlation between TFP and markup
5) Summary statistics (data for additional figures)

==============================================================================*/

*--------------*
* Clear memory *
*--------------*
clear
program drop _all
set more off
 
 
*******************************************************************************
**					Start													   
*******************************************************************************

if $JoSua==0 global REPS 10
if $JoSua==1 global REPS 1999

*==============================================================================*
* 					1) Data Preparation	
*==============================================================================*

*==============================================================================*
* 1.1) Load productivity and markup estimates
*==============================================================================*

* load TFP estimates
* -------------------
use "$data/OMEGA23.dta", clear
display _N

* load markup estimates
* ----------------------
merge 1:1 idnum year using "$data/OMEGA24.dta", keepusing (idnum year MARKUP_m)
drop _merge


* drop firms without TFP estimates
* -------------------------------
cap noi drop if OMEGAIND38 ==.
display _N

* drop outliers
* -------------
* drop all firms without labour share, with negative labour share or labour
* shares beyond q99
cap noi drop if LShare_D0==1 | LShare_D99==1 | L_Share==. | L_Share==0 | VA<0
cap noi display _N

label variable OMEGAIND38 "Total factor productivity (ACF approach) WZ A38"
label variable WZ_new_1 "WZ2008 Klassifikation: 1-Steller"
label variable WZ_new_2 "WZ2008 Klassifikation: 2-Steller"
label variable WZ_A38 "WZ2008 Klassifikation: A38 (Unterabschnitte)"


*==============================================================================*
* 				2) Generate additional variables
*==============================================================================*

*-----------------------------------------
* firm-level market share
*-----------------------------------------

bysort WZ_A38 year:  egen sum_VA_A38 = sum(VA)
gen mk_shareA38 = VA/sum_VA_A38
label variable mk_shareA38 "firm-level market share in industry (A38) value added, constant prices"

*---------------------------
* firm-level material share
* --------------------------

gen M_Share = Material/SALES
label variable M_Share "firm-level material expenditure over sales, constant prices"


*-----------------------------------------
* firm-level markup
*-----------------------------------------

* Are there negative markups?
* -------------------------
tab WZ_A38 if MARKUP_m <0

* How many valid markup estimates?
* ---------------------------------
cap noi gen MARKUP_clean = MARKUP_m
count if MARKUP_m != .


*-------------------------------------
* TFP clean of markup
* ------------------------------------
gen OMEGA_cMu = OMEGAIND38 - ln(MARKUP_m)
label variable OMEGA_cMu "TFP cleaned of markup (Andrews et al. 2016)"


* Correlation between markups and TFPs
* ------------------------------------
pwcorr OMEGA_cMu MARKUP_m, sig
pwcorr OMEGAIND38 MARKUP_m, sig
pwcorr OMEGAIND38 OMEGA_cMu, sig

* Are there negative TFPs?
* ------------------------
count if OMEGA_cMu<0
count if OMEGAIND38<0


*-------------------------------------
* squared TFP (normal/revenue-based)
* ------------------------------------
gen OMEGAIND38_sq = OMEGAIND38*OMEGAIND38
label variable OMEGAIND38_sq "squared total factor productivity (ACF approach) WZ A38"


*-------------------------------------
* squared TFP (clean of markup)
* ------------------------------------
gen OMEGAcMu_sq = OMEGA_cMu*OMEGA_cMu
label variable OMEGAcMu_sq "squared TFP cleaned of markup (Andrews et al. 2016)"


*==============================================================================*
* 2.3 Log inputs/outputs
*==============================================================================*

gen ln_L = ln(Labour)
label variable ln_L "log number of employees"
gen ln_VA = ln(VA)
label variable ln_VA "log value added, constant prices"


*-------
* clean 
*-------

cap noi drop HELP* sum* RUNNER*

*----------------
* temporary save 
*----------------

compress
save "$data/panel-results.dta", replace


*===============================================================================
* 3) Prepare verification of compliance with confidentiality restrictions
*===============================================================================


/* Level of aggregation:
---------------------
All variables (e.g., value added, capital, labor) are calculated at the firm
level. The structural estimation is carried out at the industry level, i.e.
regressions are run separately for each industry and include all firms that
belong to this industry.

Industries are defined at the NACE A38 level following the German Federal 
Statistical Office ("Unterabschnitte/Buchstaben 2-Steller"). 

The industries are called

CA CB CC CD/CE/CF CG CH CI/CJ CK CL CM D E F G45 G46 G47 H49-51 H52/53 I JA 
JB/JC K L MA MB MC N O/P Q R S. 

The following statistics reports the number of firms by industry.*/

tab WZ_A38, mi


/*
The analysis uses unweighted data.
*/



***********************************************
* 			Aggregatsebene WZA38			  *
***********************************************

* Number of valid observations for each variable by industry 
* ----------------------------------------------------------
bysort WZ_A38: egen N_WL = count(WL)
bysort WZ_A38: egen N_VA = count(VA)
bysort WZ_A38: egen N_mkshare = count(mk_shareA38)
bysort WZ_A38: egen N_LShare = count(L_Share)
bysort WZ_A38: egen N_Material = count(Material)
bysort WZ_A38: egen N_Sales = count(SALES)
bysort WZ_A38: egen N_MShare = count(M_Share)
bysort WZ_A38: egen N_lnVA = count(ln_VA)
bysort WZ_A38: egen N_Mu = count(MARKUP_m)
bysort WZ_A38: egen N_TFP = count(OMEGA_cMu)

table WZ_A38, contents (mean N_LShare mean N_WL mean N_VA mean N_lnVA)
table WZ_A38, contents (mean N_MShare mean N_Sales mean N_Material)
table WZ_A38, contents (mean N_mkshare mean N_Mu mean N_TFP)


*==============================================================================*
* 4) Estimate relationship between TFP and various parameters per WZA38  *
*==============================================================================*

* define variable to store deciles
gen tfp_pct38 = .
label variable tfp_pct38 "Deciles of TFP-ACF per industry WZA38"

* Loop:
* Separate analysis by industry using industry aggregation level NACE WZA38
* -------------------------------------------------------------------------
* start loop (p- industry)
local WZA38 "CA CB CC CD/CE/CF CH CI/CJ CK CL CM D/E F G45 G46 G47 H49-51 H52/53 I J K L M N" 

foreach p of local WZA38{

	
	display " "
	display "========================================================================" 
	display " "
	display "				ESTIMATION FOR INDUSTRY `p' "
	display " "
	display "========================================================================"  
	display " "
	display "------------------------------------------------------------------------" 
	display " 3) Correlation between TFP and labor share in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	keep idnum year WZ_new_2 WZ_new_1 WZ_A38 OMEGA_cMu OMEGAcMu_sq ln_VA ///
	VA L_Share M_Share tfp_pct38 N_* mk_shareA38 MARKUP_m
		
	scalar drop _all
	xtset idnum year
	
	* Number of obs per industry
	display "Number of observations in industry `p'"
	count if WZ_A38=="`p'"
	
	if (r(N) <50) {
	display "Less than 50 observations in industry `p'"
	display "Stop estimation and select next industry."
	continue
	}
	
	*=======================================================================*
	* 4.1) Estimate correlation between TFP and Labor Share					*
	*=======================================================================*
	
	
	* Run regression with linear specification 
	* ----------------------------------------
	* L_Share = firm-level wage share in value added by year
	* OMEGA_cMu = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS): areg L_Share OMEGA_cMu i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	* Run regression with squared specification 
	* ------------------------------------------
	* L_Share = firm-level wage share in value added by year
	* OMEGAcMu_sq = squared firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS): areg L_Share OMEGA_cMu OMEGAcMu_sq i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	*save coefficients into a matrix
	cap noi matrix define COEFF = e(b)
	cap noi scalar define beta1 = COEFF[1,colnumb(COEFF,"OMEGA_cMu")]
	cap noi scalar define beta2 = COEFF[1,colnumb(COEFF,"OMEGAcMu_sq")]
	
	* Compute marginal effects (gamma = beta1 + 2*beta2*x) for p10, p50 and p90 quantiles
	* -----------------------------------------------------------------------------------
	*estimates quantiles (p10, p50, p90) of the TFP distribution of all firms in industry p
	cap noi _pctile OMEGA_cMu if WZ_A38=="`p'", p(10,50,90)
	cap noi scalar q10=r(r1)
	cap noi scalar q50=r(r2)
	cap noi scalar q90=r(r3)
	
	* detailed results for confidentiality compliance check
	cap noi tabstat OMEGA_cMu if WZ_A38=="`p'", stat(N min p10 p50 p90 max sd) 
		
	cap noi scalar define me10 = beta1 + 2*beta2*q10
	cap noi scalar define me50 = beta1 + 2*beta2*q50
	cap noi scalar define me90 = beta1 + 2*beta2*q90
	
	cap noi display " "
	cap noi display "Marginal effects of TFP on the labour share in industry `p'"
	cap noi display "-----------------------------------------------------------"
	cap noi display "Marginal effect at p10-quantile of the TFP distribution (all years):"
	cap noi display me10 
	cap noi display "Marginal effect at p50-quantile of the TFP distribution (all years):"
	cap noi display me50 
	cap noi display "Marginal effect at p90-quantile of the TFP distribution (all years):"
	cap noi display me90
	
	
	* decile analysis
	* ---------------
	* calculate deciles of the TFP distribution of all firms in industry p
	cap noi xtile tfp_pct = OMEGA_cMu if WZ_A38=="`p'", nq(10)
	cap noi replace tfp_pct38 = tfp_pct if WZ_A38=="`p'"
	
	* labor share distribution within TFP deciles
	*cap noi tabstat L_Share if WZ_A38=="`p'", by(tfp_pct) stat(N min p10 p25 p50 mean p75 p90 max sd)  columns(statistics) format(%6.3f)
	
	

	*=======================================================================*
	* 4.2) Estimate correlation between TFP and Firm Size	(Value Added)	*
	*=======================================================================*

	display " "
	display "------------------------------------------------------------------------" 
	display " 5) Correlation between TFP and firm size in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	
	* Continuos regression
	* --------------------
	* ln_VA = logged firm-level value added by year
	* OMEGA_cMu = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS): areg ln_VA OMEGA_cMu i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	
	* value added distribution within TFP deciles
	* -------------------------------------------
	cap noi tabstat ln_VA if WZ_A38=="`p'", by(tfp_pct) stat(N min p25 p50 mean p75 max sd)  columns(statistics) format(%6.3f)
	

	
	*=======================================================================*
	* 4.3) Estimate correlation between TFP and Market Shares				*
	*=======================================================================*
	
	display " "
	display "------------------------------------------------------------------------" 
	display " 5) Correlation between TFP and market shares in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	* Regression
	* ----------
	* mk_shareA38 = firm-level share of VA in total industry's value added by year
	* OMEGAIND38 = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS):  areg mk_shareA38 OMEGA_cMu i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	
	*=======================================================================*
	* 4.4) Estimate correlation between TFP and Material Shares				*
	*=======================================================================*

	display " "
	display "------------------------------------------------------------------------" 
	display " 5) Correlation between TFP and material shares in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	* Regression
	* ----------
	* M_Share = firm-level share of material in firm's value added by year
	* OMEGA_cMu = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS):  areg M_Share OMEGA_cMu i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted	
	
	*=======================================================================*
	* 4.5) Estimate correlation between TFP and Markup				*
	*=======================================================================*

	display " "
	display "------------------------------------------------------------------------" 
	display " 5) Correlation between TFP and markup in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	* Regression
	* ----------
	* MARKUP_m = firm-level markup by year
	* OMEGA_cMu = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS):  areg MARKUP_m OMEGA_cMu i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	*end loop
	}
	
	
	
*save 
save "$data/panel-results.dta", replace
	
	


*===============================================================================
* 		5) Data for summary statistics (Figures)	   
*===============================================================================


* load data
* ---------
use "$data/panel-results.dta", clear


gen tfp_pctAgg = .
label variable tfp_pctAgg "Deciles of TFP-ACF per aggregated industries"


* Manufacturing (C)
* -----------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct2 = OMEGA_cMu if WZ_new_1=="C", nq(10)
cap noi replace tfp_pctAgg = tfp_pct2 if WZ_new_1=="C"

* VA distribution within TFP deciles
cap noi tabstat ln_VA if WZ_new_1=="C", by(tfp_pctAgg) stat(N min p25 p50 mean p75 max sd) format(%6.3f)
	
	
* Utilities and Transport (D, E, H)
* ---------------------------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct3 = OMEGA_cMu if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H" , nq(10)
cap noi replace tfp_pctAgg = tfp_pct3 if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H"

* VA distribution within TFP deciles
cap noi tabstat ln_VA if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H", by(tfp_pctAgg) stat(N min p25 p50 mean p75 max sd) format(%6.3f)


* Trade (G)
* ---------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct4 = OMEGA_cMu if WZ_new_1=="G", nq(10)
cap noi replace tfp_pctAgg = tfp_pct4 if WZ_new_1=="G"

* VA distribution within TFP deciles
cap noi tabstat ln_VA if WZ_new_1=="G", by(tfp_pctAgg) stat(N min p25 p50 mean p75 max sd) format(%6.3f)

* Services (I, J, M, N)
* ---------------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct8 = OMEGA_cMu if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N", nq(10)
cap noi replace tfp_pctAgg = tfp_pct8 if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N"

* VA distribution within TFP deciles
cap noi tabstat ln_VA if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N", by(tfp_pctAgg) stat(N min p25 p50 mean p75 max sd) format(%6.3f)



*==============================================================================*
* Clean and save															   *
*==============================================================================*


cap erase "$data/panel-results.dta"

********************************************************************************
*** End 
cap noi log close
********************************************************************************