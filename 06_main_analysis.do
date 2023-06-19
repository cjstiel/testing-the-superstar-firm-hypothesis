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
log using "$log/06_main_analysis.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "06_main_analysis.do"
Content: Tests hypothesis from Autor et al. 2017 NBER WP No. 23396
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v30/v43, 12.08.2019/23.06.2021
--------------------------------------------------------------------------------

uses: "$data\OMEGA22.dta"

results for tables/figures in article: Table 1, Table 2, Table 3, Table B2, 
										Fig2, Fig C1

File structure
--------------
1) Load TFP estimates
2) Generate additional variables
3) Prepare verification of compliance with confidentiality restrictions
4) Summary statistics (inputs/outputs) 	
5) Estimate relationship between TFP and labor share/value added by industry
	5.1 Estimate correlation between TFP and labor share
	5.2 Estimate correlation between TFP and firm size	(value added)
	5.3 Estimate correlation between TFP and market share
	5.4 Estimate correlation between TFP and material share
6) Estimate relationship between labor share and CR20 (industry level)
	6.1 In levels
	6.2 In 5-year-differences 
7) Summary statistics (data for additional figures)
	7.1 Details WZ_A38
	7.2 NACE 1 and higher

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

*===============================================================================
* 1) Load productivity estimates
*===============================================================================

* load data
* ---------
use "$data/OMEGA22.dta", clear
display _N

* drop firms without TFP estimates
* -------------------------------
drop if OMEGAIND38 ==.

* drop outliers
* -------------
* drop all firms without labour share, with negative labour share or labour
* shares beyond q99
drop if LShare_D0==1 | LShare_D99==1 | L_Share==. | L_Share==0 | VA<0
display _N

label variable OMEGAIND38 "Total factor productivity (ACF approach) WZ A38"
label variable WZ_new_1 "WZ2008 Klassifikation: 1-Steller"
label variable WZ_new_2 "WZ2008 Klassifikation: 2-Steller"
label variable WZ_A38 "WZ2008 Klassifikation: A38 (Unterabschnitte)"


*===============================================================================
* 2) Generate additional variables										
*===============================================================================

*-----------------------------------------*
* firm-level market share
*-----------------------------------------*

bysort WZ_A38 year:  egen sum_VA_A38 = sum(VA)
gen mk_shareA38 = VA/sum_VA_A38
label variable mk_shareA38 "firm-level market share in industry (A38) value added, constant prices"


*---------------------------
* firm-level material share
* --------------------------

gen M_Share = Material/SALES
label variable M_Share "firm-level material expenditure over sales, constant prices"

*---------------
* squared TFP
* --------------

gen OMEGAIND38_sq = OMEGAIND38*OMEGAIND38
label variable OMEGAIND38_sq "squared total factor productivity (ACF approach) WZ A38"

* ------------------
* log inputs/outputs
* ------------------

gen ln_L = ln(Labour)
label variable ln_L "log number of employees"
gen ln_VA = ln(VA)
label variable ln_VA "log value added, constant prices"


*-------------------------------------------------------------------------------
* Aggregate market share of top-20-firms per year and industry
*-------------------------------------------------------------------------------

* sort and count
gsort WZ_A38 year -mk_shareA38
bysort WZ_A38 year: gen RUNNERA38=_n

* identify top 20 firms in terms of market share by industry and year
gen HELP_CR20 = 0
replace HELP_CR20 = 1 if RUNNERA38<=20

* calculate concentration measure CR20 per year and industry (levels)
bysort WZ_A38 year HELP_CR20: egen CR20_A38 = total(mk_shareA38)
replace CR20_A38 = 0 if HELP_CR20==0
label variable CR20_A38 "aggregated market share of top 20 firms per industry and year"

* log concentration measure CR20 per year and industry
gen ln_CR20 = ln(CR20_A38)
label variable ln_CR20 "log aggregated market share of top 20 firms per industry and year"

gsort WZ_A38 year -mk_shareA38


*---------------------------------------------
* calculate labor share by industry and year  
*---------------------------------------------

* labor share by industry WZ38 (Levels)
bysort WZ_A38 year: egen sum_WL_A38=sum(WL)
gen L_S_A38 = sum_WL_A38/sum_VA_A38
label variable L_S_A38 "average labour share per WZ A38 industry and year"

* labor share by industry WZ38 (Logs)
gen ln_LS   = ln(L_S_A38)
label variable ln_LS "log average labour share per WZ A38 industry and year"


*-------
* clean 
*-------

drop HELP* sum* RUNNER*

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
bysort WZ_A38: egen N_CR20 = count(CR20_A38)
bysort WZ_A38: egen N_LShare = count(L_Share)
bysort WZ_A38: egen N_Labour = count(Labour)
bysort WZ_A38: egen N_Capital = count(Capital)
bysort WZ_A38: egen N_Material = count(Material)
bysort WZ_A38: egen N_Sales = count(SALES)
bysort WZ_A38: egen N_MShare = count(M_Share)
bysort WZ_A38: egen N_lnL = count(ln_L)
bysort WZ_A38: egen N_lnVA = count(ln_VA)

table WZ_A38, contents (mean N_LShare mean N_WL mean N_VA mean N_mkshare)
table WZ_A38, contents (mean N_Labour mean N_Capital mean N_Sales mean N_Material)
table WZ_A38, contents (mean N_CR20 mean N_lnL mean N_lnVA mean N_MShare)


*===============================================================================
* 4) Summary statistics (inputs/outputs) 		
*===============================================================================

gen Capital_mio = Capital/10^6
label variable Capital_mio "capital stock in mio EUR, constant prices"
gen Material_mio = Material/10^6
label variable Material_mio "intermediate goods an services in mio EUR, constant prices"
gen VA_mio = VA/10^6
label variable VA_mio "value added in mio EUR, constant prices"
gen Lohnsumme = WL/10^6

* Labour: employees, Capital: capital stock, VA: value added
tabstat Labour Capital_mio Material_mio VA_mio if OMEGAIND38!=., stat(N min p1 p5 p25 p50 mean p75 p95 p99 max sd) columns(statistics)

* L_Share: wage share in value added
* mk_shareA38: firm-level market share in industry's total value added
* Lohnsumme: wage sum
tabstat L_Share mk_shareA38 Lohnsumme if OMEGAIND38!=., stat(N min p1 p5 p25 p50 mean p75 p95 p99 max sd)columns(statistics)

* concentration measure CR20 by industry
table WZ_A38, contents (mean CR20_A38)

* clean
drop Lohnsumme


*===============================================================================
* 5) Estimate relationship between TFP and Labour Share/Value Added per WZA38  
*===============================================================================

* define variable to store deciles
gen tfp_pct38 = .
label variable tfp_pct38 "Deciles of TFP-ACF per industry WZA38"

* Loop:
* Separate analysis by industry using industry aggregation level NACE WZA38
* -------------------------------------------------------------------------
* start loop (p- industry)
local WZA38 "CA CB CC CD/CE/CF CG CH CI/CJ CK CL CM D/E F G45 G46 G47 H49-51 H52/53 I J K L M N O/P Q R S " 

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

	
	*=======================================================================*
	* 5.1) Estimate correlation between TFP and Labor Share					*
	*=======================================================================*

	keep idnum year WZ_new_2 WZ_new_1 WZ_A38 OMEGAIND38 OMEGAIND38_sq ln_L ln_VA ///
		 VA mk_shareA38 L_Share tfp_pct38 N_* CR20_A38 ln_CR20 L_S_A38 ln_LS		
		
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
	
	* Run regression with linear specification 
	* ----------------------------------------
	* L_Share = firm-level wage share in value added by year
	* OMEGAIND38 = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS): areg L_Share OMEGAIND38 i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted

	
	* Run regression with squared specification 
	* ------------------------------------------
	* L_Share = firm-level wage share in value added by year
	* OMEGAIND38_sq = squared firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS): areg L_Share OMEGAIND38 OMEGAIND38_sq i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	*save coefficients into a matrix
	cap noi matrix define COEFF = e(b)
	cap noi scalar define beta1 = COEFF[1,colnumb(COEFF,"OMEGAIND38")]
	cap noi scalar define beta2 = COEFF[1,colnumb(COEFF,"OMEGAIND38_sq")]
	
	* Compute marginal effects (gamma = beta1 + 2*beta2*x) for p10, p50 and p90 quantiles
	* -----------------------------------------------------------------------------------
	*estimates quantiles (p10, p50, p90) of the TFP distribution of all firms in industry p
	_pctile OMEGAIND38 if WZ_A38=="`p'", p(10,50,90)
	scalar q10=r(r1)
	scalar q50=r(r2)
	scalar q90=r(r3)
	
	* detailed results for confidentiality compliance check
	tabstat OMEGAIND38 if WZ_A38=="`p'", stat(N min p10 p50 p90 max sd) 
		
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
	xtile tfp_pct = OMEGAIND38 if WZ_A38=="`p'", nq(10)
	cap noi replace tfp_pct38 = tfp_pct if WZ_A38=="`p'"
	
	* labor share distribution within TFP deciles
	tabstat L_Share if WZ_A38=="`p'", by(tfp_pct) stat(N min p10 p25 p50 mean p75 p90 max sd)  columns(statistics) format(%6.3f)
	
	

	*=======================================================================*
	* 5.2) Estimate correlation between TFP and Firm Size	(Value Added)	*
	*=======================================================================*

	display " "
	display "------------------------------------------------------------------------" 
	display " 4) Correlation between TFP and firm size in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	
	* Continuos regression
	* --------------------
	* ln_VA = logged firm-level value added by year
	* OMEGAIND38 = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS): areg ln_VA OMEGAIND38 i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted
	
	* value added distribution within TFP deciles
	* -------------------------------------------
	tabstat ln_VA if WZ_A38=="`p'", by(tfp_pct) stat(N min p10 p25 p50 mean p75 p90 max sd)  columns(statistics) format(%6.3f)
	

	
	*=======================================================================*
	* 5.3) Estimate correlation between TFP and Market Shares				*
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
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS):  areg mk_shareA38 OMEGAIND38 i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted

	
	*=======================================================================*
	* 5.4) Estimate correlation between TFP and Material Shares				*
	*=======================================================================*

	display " "
	display "------------------------------------------------------------------------" 
	display " 6) Correlation between TFP and material shares in industry `p' "
	display "------------------------------------------------------------------------"  
	display " "

	* Regression
	* ----------
	* M_Share = firm-level share of material in firm's value added by year
	* OMEGAIND38 = firm-level TFP by year
	* WZ_new_2 = NACE code at 2-digit level
	cap noi bootstrap, cluster(idnum) idcluster(newid) group(idnum) reps($REPS):  areg M_Share OMEGAIND38 i.WZ_new_2 if WZ_A38=="`p'", absorb(year) noomitted				
	
	*end loop
	
	}

*save 
save "$data/panel-results.dta", replace
	
	
*===============================================================================
* 6) Estimate relationship between Labour Share and CR20 by industry 	    	
*===============================================================================

*===============================================================================
* 6.1) In Levels
*===============================================================================

* load data
* ---------
use "$data/panel-results.dta", clear

* keep only relevant variables
* ----------------------------
keep year WZ_A38 mk_shareA38 CR20_A38 L_S_A38 ln_LS ln_CR20
gsort WZ_A38 year -mk_shareA38

/*
Notes: All firms within and industry and year have the same value for "Labour 
Share" (L_S_A38) and the concentration measure "CR20" (CR20_A38). Hence, drop
all duplicates such that only one observation by industry and year remains.*/

#delimit ;
collapse 	   
	   (first)
	   CR20_A38
	   L_S_A38
		ln_LS
		ln_CR20
       , by(WZ_A38 year);

#delimit cr

* encode WZ_A38
* -------------
encode WZ_A38, gen(HELP_WZ38)


* Regress industry-level labor share (L_S_A38) on industry-level concentration measure (CR20)
* ------------------------------------------------------------------------------
areg L_S_A38 CR20_A38 i.HELP_WZ38, absorb(year) noomitted vce(cluster HELP_WZ38)


* same as above, but logs on logs
* -------------------------------
areg ln_LS ln_CR20 i.HELP_WZ38, absorb(year) noomitted vce(cluster HELP_WZ38)




*===============================================================================
* 6.2) In 5-year-differences 
*===============================================================================

* load data
* ---------
use "$data/panel-results.dta", clear

* keep only relevant variables
* ----------------------------
keep year WZ_A38 mk_shareA38 CR20_A38 L_S_A38
gsort WZ_A38 year -mk_shareA38

/*
Notes: All firms within and industry and year have the same value for "Labour 
Share" (L_S_A38) and the concentration measure "CR20" (CR20_A38). Hence, drop
all duplicates such that only one observation by industry and year remains.*/

#delimit ;
collapse 	   
	   (first)
	   CR20_A38
	   L_S_A38

       , by(WZ_A38 year);

#delimit cr

* encode WZ_A38
* -------------
encode WZ_A38, gen(HELP_WZ38)

* calculate 5-year lags
* ---------------------
xtset HELP_WZ38 year
gen l5_CR20 = L5.CR20_A38
gen l5_LS   = L5.L_S_A38

* 5-year-differences
* -------------------
gen delta_CR20 = CR20_A38 - l5_CR20
gen delta_LS   = L_S_A38  - l5_LS 


* regress labor share on concentration measure in 5-year differences
* ------------------------------------------------------------------
areg delta_LS delta_CR20 i.HELP_WZ38, absorb(year) noomitted vce(cluster HELP_WZ38)



*===============================================================================
* 		7) Data for summary statistics (Figures)	   
*===============================================================================

* load data
* ---------
use "$data/panel-results.dta", clear

*===============================================================================
* 7.1 Details WZ_A38					  
*===============================================================================

gen tfp_pctDet = .
label variable tfp_pctDet "Deciles of TFP-ACF per detailed industries"

* Energy
* ------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pctD1 = OMEGAIND38 if WZ_new_1=="D", nq(10)
cap noi replace tfp_pctDet = tfp_pctD1 if WZ_new_1=="D"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="D", by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="D", by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)


* Water etc.
* ----------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pctD2 = OMEGAIND38 if WZ_new_1=="E", nq(10)
cap noi replace tfp_pctDet = tfp_pctD2 if WZ_new_1=="E"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="E", by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="E", by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)


* WZ A38: JA (TV, media, print etc.)
* -----------------------------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90).
cap noi xtile tfp_pctD3 = OMEGAIND38 if WZ_new_2>=58 & WZ_new_2<=60, nq(10)
cap noi replace tfp_pctDet = tfp_pctD3 if WZ_new_2>=58 & WZ_new_2<=60

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_2>=58 & WZ_new_2<=60, by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_2>=58 & WZ_new_2<=60, by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)

* WZ A38: JB (IT & telecommunications)
* ------------------------------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pctD4 = OMEGAIND38 if WZ_new_2>=61 & WZ_new_2<=63, nq(10)
cap noi replace tfp_pctDet = tfp_pctD4 if WZ_new_2>=61 & WZ_new_2<=63

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_2>=61 & WZ_new_2<=63, by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_2>=61 & WZ_new_2<=63, by(tfp_pctDet) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)

	
	
*===============================================================================
* 7.2 NACE 1 and higher	  
*===============================================================================

gen tfp_pctAgg = .
label variable tfp_pctAgg "Deciles of TFP-ACF per aggregated industries"


* Manufacturing (C)
* -----------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct2 = OMEGAIND38 if WZ_new_1=="C", nq(10)
cap noi replace tfp_pctAgg = tfp_pct2 if WZ_new_1=="C"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="C", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="C", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
	
	
* Utilities and Transport (D, E, H)
* ---------------------------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct3 = OMEGAIND38 if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H" , nq(10)
cap noi replace tfp_pctAgg = tfp_pct3 if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="D" | WZ_new_1=="E" | WZ_new_1=="H", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)


* Trade (G)
* ---------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct4 = OMEGAIND38 if WZ_new_1=="G", nq(10)
cap noi replace tfp_pctAgg = tfp_pct4 if WZ_new_1=="G"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="G", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="G", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)


* Construction (F)
* ----------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct5 = OMEGAIND38 if WZ_new_1=="F", nq(10)
cap noi replace tfp_pctAgg = tfp_pct5 if WZ_new_1=="F"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="F", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="F", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
	
	
* Services (I, J, M, N)
* ---------------------
* Calculate TFP deciles (p10, p20, p30, p40, p50, p60, p70, p80, p90)
cap noi xtile tfp_pct8 = OMEGAIND38 if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N", nq(10)
cap noi replace tfp_pctAgg = tfp_pct8 if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N"

* VA and labour share distribution within TFP deciles
cap noi tabstat L_Share if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)
cap noi tabstat ln_VA if WZ_new_1=="I" | WZ_new_1=="J" | WZ_new_1=="M" | WZ_new_1=="N", by(tfp_pctAgg) stat(N min p10 p25 p50 mean p75 p90 max sd) format(%6.3f)


*===============================================================================
* Clean and save															   
*===============================================================================


cap erase "$data/panel-results.dta"

********************************************************************************
*** End 
cap noi log close
********************************************************************************