/*==============================================================================

				Article "Testing the Superstar Hypothesis"
				
					by Alexander Schiersch, Caroline Stiel
			DIW Berlin (German Institute for Economic Research)
				
				published in: Journal of Applied Economics
						Vol. 25, Issue 1, pp. 583-603

*=============================================================================*/

* Start Logfile
* --------------
cap log close
log using "$log/05_TFPestimation.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "05_TFPestimation.do"
Content: Estimates TFP at firm level
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v22, 09.08.2019
--------------------------------------------------------------------------------

uses : "$data\panel-ACF-final.dta"
saves: "$data\OMEGA22.dta"

results for tables/figures in article: Table B1

File structure
--------------
1) Define global & locals 
2) Define second stage programs
3) Load and prepare data
	3.1 Clean data
	3.2 Generate NACE-classification WZ_A38
	3.3 Outlier detection
	3.4 Define dependent and independent variables
	3.5 Quadratic terms and first-order interaction variables
	3.6 Create sector dummies
	3.7 Create dummies for legal form
	3.8 Create dummies for region (Bundesland/federal state)
	3.9 Clean for missing values in control variables
4) Structural Estimation of Total Factor Productivity (ACF Approach)
	4.1 Prepare data before loop 
	4.2 Loop through industies p
5) Full productivity distribution of entire sample
6) Summarize results by industry

==============================================================================*/

 * Clear memory
 * ------------
 clear
 program drop _all
 set more off
 
 
*******************************************************************************
**					Start													   
*******************************************************************************

*===============================================================================
* 1) Define global & locals 		
*===============================================================================

* produce descriptive statistics yes/no
* -------------------------------------
global DESCR 0

* check significance of dummy coefficients after first-stage OLS
* ---------------------------------------------------------------
global CHECK 1

* limit the analysis to a certain period
* --------------------------------------
global STARTJAHR 1993
global ENDJAHR 2016

* define the range of 2-digit industries considered
* -------------------------------------------------
global START 10
global END 96

* define variables for data selection (NOMISS) for descriptive statistics
* -----------------------------------------------------------------------
global DESCRVAR Y L K S M BLAND* JURIST* SEKTOR*
global DESCRVAR2 Y L K M BLAND* JURIST* SEKTOR*

* define instrument set for first stage (OLS)
* -------------------------------------------
global FIRST BLAND* JURIST2 JURIST3 L LL LK LM K KK KM M MM SEKTOR*
	 
* define instrument set for second stage (GMM)
* --------------------------------------------
global INSTR1 L K 
global INSTR2 lag_L K 


*===============================================================================
* 2) Define second stage programs
*===============================================================================

capture program drop LAWMOT
program LAWMOT
	version 11
	syntax varlist if, at(name)
	quietly{
		tempvar omega omega_lag omega_hat
		generate double `omega' = PHI_hat -  L*`at'[1,1] - K*`at'[1,2]  `if'
		generate double `omega_lag' = lag_PHI_hat - lag_L*`at'[1,1] - lag_K*`at'[1,2] `if'
		regress `omega' `omega_lag' 
		predict `omega_hat', xb
		replace `varlist' = `omega'-`omega_hat' `if'	
	}
end


*===============================================================================
* 3) Load and prepare data 							   
*===============================================================================

* load data
* ---------
use "$data\panel-ACF-final.dta", clear

* number of observations
* ----------------------
display _N


*===============================================================================
* 3.1 Clean data 				
*===============================================================================


* drop all obs with missing WZ_new_2
* ----------------------------------
cap noi drop if WZ_new_2==.
cap noi drop if missing(WZ_new_2)

* select time period
* -------------------
rename jahr year
drop if year<$STARTJAHR
drop if year>$ENDJAHR 

* do the key variables have missing values?
* ----------------------------------------
count if year==.
count if idnum ==.

* rename variable to avoid confusion with ln(.)
* ---------------------------------------------
rename L Labour
label variable Labour "total number of employees"
rename M Material 
label variable Material "intermediate goods and services, constant prices"
rename K_PIM Capital
label variable Capital "capital stock, constant prices"

* select WZ (class of economic activity)
* --------------------------------------
drop if WZ_new_2 <$START
drop if WZ_new_2 >$END

* Check number of observations after dropping of observations
* -----------------------------------------------------------
display _N


*===============================================================================
* 3.2 Generate NACE-classification WZ_A38
*===============================================================================

quietly{

* Generate new WZ-classification based on A38 (Unterabschnitte)
* -------------------------------------------------------------
gen str8 WZ_A38=""
replace WZ_A38 = "CA" if WZ_new_2 >=10 & WZ_new_2 <=12
replace WZ_A38 = "CB" if WZ_new_2 >=13 & WZ_new_2 <=15
replace WZ_A38 = "CC" if WZ_new_2 >=16 & WZ_new_2 <=18
replace WZ_A38 = "CD/CE/CF" if WZ_new_2 >=19 & WZ_new_2 <=21
replace WZ_A38 = "CG" if WZ_new_2 >=22 & WZ_new_2 <=23
replace WZ_A38 = "CH" if WZ_new_2 >=24 & WZ_new_2 <=25
replace WZ_A38 = "CI/CJ" if WZ_new_2 ==26 | WZ_new_2 ==27
replace WZ_A38 = "CK" if WZ_new_2 ==28
replace WZ_A38 = "CL" if WZ_new_2 >=29 & WZ_new_2 <=30
replace WZ_A38 = "CM" if WZ_new_2 >=31 & WZ_new_2 <=33
replace WZ_A38 = "D" if WZ_new_2 ==35
replace WZ_A38 = "E" if WZ_new_2 >=36 & WZ_new_2 <=39
replace WZ_A38 = "F" if WZ_new_2 >=41 & WZ_new_2 <=43
replace WZ_A38 = "G45" if WZ_new_2 ==45
replace WZ_A38 = "G46" if WZ_new_2 ==46
replace WZ_A38 = "G47" if WZ_new_2 ==47
replace WZ_A38 = "H49-51" if WZ_new_2 >=49 & WZ_new_2 <=51
replace WZ_A38 = "H52/53" if WZ_new_2 >=52 & WZ_new_2 <=53
replace WZ_A38 = "I55" if WZ_new_2 ==55
replace WZ_A38 = "I56" if WZ_new_2 ==56
replace WZ_A38 = "JA" if WZ_new_2 >=58 & WZ_new_2 <=60
replace WZ_A38 = "JB/JC" if WZ_new_2 >=61 & WZ_new_2 <=63
replace WZ_A38 = "K" if WZ_new_2 >=64 & WZ_new_2 <=66
replace WZ_A38 = "L" if WZ_new_2 ==68
replace WZ_A38 = "MA" if WZ_new_2 >=69 & WZ_new_2 <=71
replace WZ_A38 = "MB" if WZ_new_2 ==72
replace WZ_A38 = "MC" if WZ_new_2 >=73 & WZ_new_2 <=75
replace WZ_A38 = "N" if WZ_new_2 >=77 & WZ_new_2 <=82
replace WZ_A38 = "O/P" if WZ_new_2 >=84 & WZ_new_2 <=85
replace WZ_A38 = "Q" if WZ_new_2 >=86 & WZ_new_2 <=88
replace WZ_A38 = "R" if WZ_new_2 >=90 & WZ_new_2 <=93
replace WZ_A38 = "S" if WZ_new_2 >=94 & WZ_new_2 <=96


* Recode aggregate level (WZ on NACE level A38) in such a way that each class 
* has enough observations to comply with IAB's confidentiality restrictions
* -------------------------------------------------------------------------
replace WZ_A38 = "D/E" if WZ_new_1=="D" | WZ_new_1=="E"
replace WZ_A38 = "I" if WZ_new_1=="I"
replace WZ_A38 = "J" if WZ_A38=="JA" | WZ_A38=="JB/JC"
replace WZ_A38 = "M" if WZ_A38=="MA" | WZ_A38=="MB" | WZ_A38=="MC"

tab WZ_A38, mi

label variable WZ_A38 "WZ2008 Klassifikation A38 Unterabschnitte"

* select variables
* -----------------
keep idnum year WZ_new_1 WZ_new_2 WZ_A38 fstate_d legfo_d SALES ///
	 Labour Capital VA Material WL ecross_c sizegr_d

	
* end quietly loop
}

*===============================================================================
* 3.3 Outlier detection 			 										   
*===============================================================================

sort WZ_A38 year 

* Drop all observations with labor shares <0 or beyond the q99
* -------------------------------------------------------------
gen L_Share = WL/VA
label variable L_Share "firm-level labour share in value added, constant prices"

tabstat L_Share, stat(N min p5 p50 mean p95 p99 max sd) save
display _N

cap noi matrix define STAT = r(StatTotal)
cap noi scalar define LShare99 = STAT[7,colnumb(STAT,"L_Share")]
cap noi display LShare99

* LShare > q99
* ------------
count if L_Share > LShare99 & L_Share!=.
gen LShare_D99 = 0
replace LShare_D99 = 1 if L_Share > LShare99 & L_Share!=.
tab LShare_D99, mi

* LShare < 0
* ------------
count if L_Share < 0 & L_Share!=.
count if L_Share == 0 & L_Share!=.
count if L_Share == 0 & WL==0 & Labour!=0

gen LShare_D0 = 0
replace LShare_D0 = 1 if L_Share < 0 & L_Share!=.
tab LShare_D0, mi


* Replace VA=. for LShare==., LShare> q99, LShare<0
* -------------------------------------------------
count if VA==.
replace VA=. if (LShare_D99==1 | LShare_D0==1)
count if VA==.

* number of observations after dropping outliers
* ----------------------------------------------
display _N

sort idnum year


*===============================================================================
* 3.4 Define dependent and independent variables 							   
*===============================================================================

quietly{

* define panel structure
* ----------------------
xtset idnum year

* log dependent variable
* ----------------------
cap gen Y = ln(VA) 
label variable Y "Log value added, constant prices [EUR]"

* log independent variables
* -------------------------
cap count if Labour <=0
cap gen L = ln(Labour)
label variable L "Log total number of employees"

cap count if Material <=0
cap gen M = ln(Material)
label variable M "Log intermediate goods and services, constant prices [EUR]"

cap count if Capital <=0
cap gen K = ln(Capital) 
label variable K "Log capital stock, constant prices [EUR]"

sort idnum year

* end quietly loop
} 


*===============================================================================
* 3.5 Create quadratic terms and first-order interaction variables 			   
*===============================================================================

quietly{
foreach w of varlist L K M {
	foreach s of varlist L K M {
		di "Check whether variable `w'`s' exists ..."
	    cap confirm variable `s'`w'
		*di _rc
		if _rc!=0{
			di ""	
			di "Variable `w'`s' does not exists - Creating variable `w'`s'"
			di ""
			cap gen `w'`s'=`w'*`s'
		}
		cap confirm variable `s'`w'
		*di _rc
		if _rc==0 & `w'!=`s'{
	      di ""	
		  di "Variable `w'`s' not created because variable `s'`w' already exists"
		  di ""
		}
	}
}

* end quietly loop
} 


*===============================================================================
* 3.6 Create sector dummies 												   
*===============================================================================

quietly{
* sector dummies 2-digit industry
forvalues p = $START/$END{	
		cap  gen SEKTOR`p'=0
		quietly replace SEKTOR`p'=1 if WZ_new_2==`p'
		// For IAB: Number of valid obs per group
		bysort SEKTOR`p': egen N_SEKTOR`p' = count(SEKTOR`p')
		cap count if SEKTOR`p'==.
}

* Note: By construction, there are no missings in SEKTOR*. Observations with
* missings in "WZ_new_2" will have zeros in all SEKTOR*.
* Furthermore, in the regression by 2-digit-industry, the SEKTOR-dummy will
* work as the intercept.

* end quietly loop
}

*===============================================================================
* 3.7 Create dummies for legal form 										   *
*===============================================================================

quietly{
* Does the legal form variable have missing values?
tab legfo_d, mi

* define legal form dummies
gen JURIST1 = 0
gen JURIST2 = 0
gen JURIST3 = 0 

label variable JURIST1 "Personenges. und Einzelun."
label variable JURIST2 "Kapitalgesellschaften"
label variable JURIST3 "Sonstiges"
sort idnum year

replace JURIST1=1 if legfo_d==1 | legfo_d==2
replace JURIST2=1 if legfo_d==3 | legfo_d==4
replace JURIST3=1 if legfo_d==5 | legfo_d==6

// For IAB: Number of valid obs per group
bysort JURIST1: egen N_JURIST1 = count(JURIST1)
bysort JURIST2: egen N_JURIST2 = count(JURIST2)
bysort JURIST3: egen N_JURIST3 = count(JURIST3)

tab JURIST1, mi
tab JURIST2, mi
tab JURIST3, mi

cap count if JURIST1==.
cap count if JURIST2==.
cap count if JURIST3==.

* clean
cap  drop legfo_d

* Note: By construction, there are no missings in JURIST*. Observations with 
* missing in 'legfo_d' will have zeros in all JURIST*.

* end quietly loop
}

*===============================================================================
* 3.8 Create dummies for region (Bundesland/federal state) 								   
*===============================================================================

quietly{
* Does the federal state variable have missing values?
tab fstate_d, mi

forvalues p = 2/16{

	cap  gen BLAND`p'=0
	quietly replace BLAND`p'=1 if fstate_d==`p'
	// For IAB: number of valid obs per group
	bysort BLAND`p': egen N_BLAND`p' = count(BLAND`p')
	count if BLAND`p'==.
}
* clean
cap  drop fstate_d

* Note: By construction, there are no missings in BLAND*. Observations with 
* missing in 'fstate_d' will have zeros in all BLAND*.
* Schleswig-Holstein (BLAND==1)is the reference category.

* end quietly loop
}



*===============================================================================
* 3.9 Clean for missing values in control variables				   
*===============================================================================

quietly{
* Does ln(Material) have missing values?
* -----------------------------------------
cap count if Material<=0
gen HELP_M = 0
replace HELP_M=1 if Material<=0


* Indicator for obs with ln(Material)==. in previous year
* -------------------------------------------------------
sort idnum year
gen HELP_next = L.HELP_M
tab HELP_next, mi


* How often does ln(Material)==. in t-1 occur (lag_PHI_hat does not exist) while
* the NOMISS_condition is fulfilled in current year t (PHI_hat exists)?
* ------------------------------------------------------------------------------
cap count if (HELP_next==1) & (Y!=. &  L.Y!=. &  L!=. &  L.L!=. &  K!=. &  L.K!=. &  M!=. &  WZ_A38!="")

* end quietly loop
}


*===============================================================================
* 4) Structural Estimation of Total Factor Productivity (ACF Approach) 		   
*===============================================================================

/* Estimates the production function for each industry as a Cobb-Douglas function
with 1 output (value added) and two inputs (labor, capital) using the Generalized
Method of Moments (GMM).

Value added =  "Geschäftsvolumen im Vorjahr" (bvole_c) 
				- "Anteil Vorleistungen i.V." (revsp_c) 
				* "Geschäftsvolumen i.V." (bvole_c)
Labor = "Anzahl der Beschäftigten insgesamt im Vorjahr" (decnub_c)
Capital was estimated with the PPI method using the variables "Gesamtinvestitionen 
im Vorjahr" (insuml_c) and "Anteil der Erweiterungsinvestitionen (inexpa_c)" 


Level of aggregation:
---------------------
All variables (e.g., value added, capital, labor) are calculated at the firm
level. The structural estimation is carried out at the industry level, i.e.
regressions are run separately for each industry and include all firms that
belong to this industry.

Industries are defined at the NACE A38 level following the German Federal 
Statistical Office ("Unterabschnitte/Buchstaben 2-Steller"). 

The industries are called

CA CB CC CD/CE/CF CG CH CI/CJ CK CL CM D E F G45 G46 G47 H49-51 H52/53 I JA 
JB/JC K L MA MB MC N O/P Q R S
*/


*===============================================================================
* 4.1 Prepare data before loop
*===============================================================================

quietly{
    
* clear estimation table memory
* -----------------------------
eststo clear

* create OMEGA
* -------------
gen OMEGA=.
label variable OMEGA "Total factor productivity (ACF approach) firm-level"

gen lag_OMEGA=.

gen OMEGAIND38=.
label variable OMEGAIND38 "Total factor productivity (ACF approach) per WZ 1-digit"

* create test statistics
* ----------------------
gen Hansen = .
label variable Hansen "Hansen test statistic"

gen Hansen_DF = .
label variable Hansen_DF "Hansen test statistic"

gen Hansen_P = .
label variable Hansen_P "Hansen p-value"

gen Hansen_CONV = .
label variable Hansen_CONV "Hansen convergence status"

gen Hansen_No=.
label variable Hansen_No "Hansen test number of observations"

* set row equal to one
* ---------------------
local row 1

*===============================================================================
* 4.2 Start loop through industies p 
*===============================================================================

* start loop (p- industry)
* ------------------------
local WZA38 "CA CB CC CD/CE/CF CG CH CI/CJ CK CL CM D/E F G45 G46 G47 H49-51 H52/53 I J K L M N O/P Q R S " 

foreach p of local WZA38{
	
	display " "
	display "------------------------------------------------------------------------" 
	display " "
	display " Structural estimation of the production function in industry `p' "
	display " " 
	display "------------------------------------------------------------------------"  
	display " "

	*-----------------------------------*
	* Clean memory before each new turn *
	*-----------------------------------*	
	keep idnum year WZ_new_1 WZ_new_2 WZ_A38 Y OMEGA* $FIRST Hansen* ///
		 ecross_c sizegr_d WL VA Labour Material Capital L_Share LShare_D99 LShare_D0
		 
	scalar drop _all
	xtset idnum year
	
	cap drop Y_hat 
	cap drop PHI_hat

	*-------------------------*
	* Create nomiss  variable *
	*-------------------------*

	* Notes: L.M==. is a condition for obtaining lag_PHI even though L.M does 
	* not show up in the regression itself. Without L.M, we cannot calculate
	* PHI for the previous year and do not have lag_PHI_hat for the current year.
	* Consequently, sample sizes would differ between the 1st and the 2nd stage.

	cap  gen NOMISS=1
	cap  replace NOMISS=0 if Y==. | L.Y==. | L==. | L.L==. | K==. | L.K==. ///
				| M==. | L.M==. | WZ_A38==""						
	
	display "Number of observations in industry `p'"
	count if NOMISS==1 & WZ_A38=="`p'"
	
	if (r(N) <50) {
		display "Less than 50 observations in industry `p'"
		display "Stop estimation and select next industry."
		continue
	}
	
	*---------------------*
	* first stage -  OLS  *
	*---------------------*
	
	display " "
    display "------------------------------------------------------------------------"  
    display " First stage OLS, industry: `p' "
	display "------------------------------------------------------------------------"  
	display " "
	
	
	* Run OLS for the SUBSET of observations in industry p where all 
	* inputs/outputs of the production function and their first lag are 
	* non-missing
	
	cap reg Y $FIRST if WZ_A38=="`p'" & NOMISS==1, noomitted
	
	*--------------------------------------*
	* first stage - check coefficients 	   *
	*--------------------------------------*
	
	
	display " "
    display "------------------------------------------------------------------------"  
    display " First stage: check significance of FE coefficients, industry: `p' " 
	display "------------------------------------------------------------------------"  
	display " "
	
	*save coefficients into a matrix
	cap matrix define COEFF = e(b)

		
		* Check p-value of BLAND dummies: If insignificant at p<0.1, set to zero	
		forvalues w = 2/16{
			cap scalar define COEFF_BLAND`w'   = COEFF[1,colnumb(COEFF,"BLAND`w'")]
			
			if $CHECK==1{
				if COEFF_BLAND`w'!=0{
				cap test BLAND`w'=0
					if r(p)>0.1 {
					cap display " change "
					cap scalar define COEFF_BLAND`w'   = 0
					}			
				}
				cap display "The coeff for COEFF_BLAND`w' is " 
				cap display COEFF_BLAND`w'
			}
		}
		
		
		* Check p-value of JURIST dummies: If insignificant at p<0.1, set to zero
		forvalues w = 2/3{
			cap scalar define COEFF_RECHT`w'   = COEFF[1,colnumb(COEFF,"JURIST`w'")]
			
			if $CHECK==1{
				if COEFF_RECHT`w'!=0{
				cap test JURIST`w'=0
					if r(p)>0.1 {
					cap display " change "
					cap scalar define COEFF_RECHT`w'   = 0
					}			
				}
				cap display "The coeff for COEFF_RECHT`w' is " 
				cap display COEFF_RECHT`w'
			}
		}
		
		
		* Check p-value of SEKTOR dummies: If insignificant at p<0.1, set to zero
		forvalues w = 10/95{
			cap scalar define COEFF_SEKTOR`w'   = COEFF[1,colnumb(COEFF,"SEKTOR`w'")]
			if $CHECK==1{
				if COEFF_SEKTOR`w'!=0{
				cap test SEKTOR`w'=0
					if r(p)>0.1 {
					cap display " change "
					cap scalar define COEFF_SEKTOR`w'   = 0
					}			
				}
				cap display "The coeff for COEFF_SEKTOR`w' is " 
				cap display COEFF_SEKTOR`w'
			}
		}		
		
						
		*-------------------------------*
		* first stage - caluclating Phi *
		*-------------------------------*
		display " "
		display "------------------------------------------------------------------------"  
		display " First stage, predicting PHI_hat: industry `p'"
		display "------------------------------------------------------------------------"  
		display " "
		
		* predicting Phi 
		cap predict PHI_hat, xb 
		cap gen PHI_hat2=PHI_hat
		
		* Substract the inputs from Phi whose coefficients were identified
		* in the first stage and are NOT optimized in the second stage.
		
		display " "
		display "------------------------------------------------------------------------"  
		display " First stage: adjusting Phi-BLAND, industry: `p' "
		display "------------------------------------------------------------------------"  
		display " "
		
		* adjusting Phi - BLAND
		forvalues w = 2/16{		
			quietly replace PHI_hat = PHI_hat - COEFF_BLAND`w'*BLAND`w'
		}
		
		display " "
		display "------------------------------------------------------------------------"  
		display " First stage: adjusting Phi-RECHT, industry: `p' " 
		display "------------------------------------------------------------------------"  
		display " "
		
		* adjusting Phi - RECHT
		forvalues w = 2/3{
		
			quietly replace PHI_hat = PHI_hat - COEFF_RECHT`w'*JURIST`w'
		}
		
		display " "
		display "------------------------------------------------------------------------"  
		display " First stage: adjusting Phi-SEKTOR, industry: `p' " 
		display "------------------------------------------------------------------------"  
		display " "
		
		* adjusting Phi - SEKTOR
		forvalues w = 10/95{
		
			quietly replace PHI_hat = PHI_hat - COEFF_SEKTOR`w'*SEKTOR`w'
		}
		
				
		*------------------------------*
		* second stage - creating lags *
		*------------------------------*
		display " "
		display "------------------------------------------------------------------------"  
		display " First stage, creating lags; industry `p'"
		display "------------------------------------------------------------------------"  
		display " "
		
		* first lags
		display "lag_Phi"
		cap gen lag_PHI_hat = L.PHI_hat
		display "lag_K"
		cap gen lag_K = L.K
		display "lag_L"
		cap gen lag_L = L.L
			
		* second lags
		display "lag2_Phi"
		cap gen ll_PHI_hat = L.lag_PHI_hat
		display "lag2_K"
		cap gen ll_K = L.lag_K
		display "lag2_L"
		cap gen ll_L = L.lag_L
		
		*--------------------------------*
		* second stage - starting values *
		*--------------------------------*
		
		display " "
		display "------------------------------------------------------------------------"  
		display " Second stage starting values, industry: `p'"
		display "------------------------------------------------------------------------"  
		display " "
		
		
		* normal routine
		* --------------
		* compute starting values for GMM by regressing adjusted Phi on left inputs
		cap reg PHI_hat $INSTR1 if WZ_A38=="`p'" & NOMISS==1
		
		* save starting values
		cap matrix define coeff_start = e(b)
		cap scalar define coeff_L = coeff_start[1,colnumb(coeff_start,"L")]
		cap scalar define coeff_K = coeff_start[1,colnumb(coeff_start,"K")]
		cap scalar define coeff_KK = coeff_start[1,colnumb(coeff_start,"LL")]
		cap scalar define coeff_LL = coeff_start[1,colnumb(coeff_start,"KK")]
		cap scalar define coeff_LK = coeff_start[1,colnumb(coeff_start,"LK")]
								
	
		*---------------------------*
		* second stage - estimation *
		*---------------------------*
		
		display " "
		display "------------------------------------------------------------------------"  
		display " Second stage GMM, industry:  `p'"
		display "------------------------------------------------------------------------"  
		display " "
		
		
		* check NOMISS
		*local p "CA"
		di " Fahlzahl von Beobachtungen ohne lag_PHI_hat aber mit NOMISS==1 : "
		count if WZ_A38=="`p'" & lag_PHI_hat==. & NOMISS==1
		
		* Run GMM
		cap eststo, title("NACE"`p'): gmm LAWMOT ///
			if WZ_A38=="`p'" & NOMISS==1, ///
			nequations(1) parameters(beta_L beta_K) ///
			instruments($INSTR1) twostep ///
			from (beta_L "coeff_L" beta_K "coeff_K") ///
			technique(gn) conv_maxiter(50) 
		
		* save coefficients from the law of motion
		cap matrix define coeff2 = e(b)
		*cap  matrix list coeff2
		
		* save coefficients from the production function
		cap scalar define coeff_L_est = coeff2[1,1]
		cap scalar define coeff_K_est = coeff2[1,2]	
		
		* save parameters from Hansen test
		cap replace Hansen_No=e(N) if WZ_A38 =="`p'"
		cap replace Hansen=e(J) if WZ_A38 =="`p'"
		cap replace Hansen_DF=e(J_df) if WZ_A38 =="`p'"
		
		* conduct Hansen test
		cap estat overid
		
		* save Hansen test output
		cap replace Hansen_P=r(J_p) if WZ_A38 =="`p'"
		cap replace Hansen_CONV=e(converged) if WZ_A38 =="`p'"
		
		
		*-------------------------------------*
		* second stage - compute productivity *
		*-------------------------------------*
		
		* calculate firm-level productivity (omega) within industry p
		cap replace OMEGA=PHI_hat2-L*coeff_L_est-coeff_K_est*K
		
		display " "
		display "------------------------------------------------------------------------"  
		display " Estimated firm-level TFP in industry: `p'"
		display "------------------------------------------------------------------------"  
		display " "
		
		* display productivity distribution in industry p
		tabstat    OMEGA if WZ_A38 =="`p'", by(year) stat(N mean p1 p5 p10 p25 p50 p75 p90 p95 p99 sd)  columns(statistics) 
		
		*-------------------------------------------*
		* save productivity values in entire sample *
		*-------------------------------------------*

		display "Add firm-level estimates for omega to full dataset"
		cap replace OMEGAIND38=OMEGA if WZ_A38=="`p'"
		display "Set firm-level estimates to zero in prep for next industry"
		cap replace OMEGA=.


		
}

*end quietly loop	
} 

*==============================================================================*
* 5) Display full productivity distribution of entire sample
*==============================================================================*		

* Average productivity (TFP) by industry 
* --------------------------------------
tabstat    OMEGAIND38, by(WZ_A38) stat(N mean p50 sd)  columns(statistics)


* For IAB: Number of valid obs per group
* --------------------------------------
bysort WZ_A38: egen N_OMEGAIND38 = count(OMEGAIND38)
table WZ_A38, contents (mean N_OMEGAIND38)



*==============================================================================*
* 6) Summarize results by industry		
*==============================================================================*

/*
Regression results for each industry (letters CA till S) are summarized in the
subsequent tables.
beta_l : regression coefficient for labor
beta_k : regression coefficient for capital
Observations: Number of observations
*/

* summary of GMM results (coefficients) per industry WZ A38
* ----------------------------------------------------------
esttab est1 est2 est3 est4 est5 est6 est7, b se brackets mlabels(,titles) label title(Results from the GMM estimation for each sector) compress
esttab est8 est9 est10 est11 est12 est13 est14, b se brackets mlabels(,titles) label title(Results from the GMM estimation for each sector) compress
esttab est15 est16 est17 est18 est19 est20 est21, b se brackets mlabels(,titles) label title(Results from the GMM estimation for each sector) compress
esttab est22 est23, b se brackets mlabels(,titles) label title(Results from the GMM estimation for each sector) compress
esttab est24 est25 est26 est27, b se brackets mlabels(,titles) label title(Results from the GMM estimation for each sector) compress

* summary of Hansen test statistics per industry WZ A38
* ------------------------------------------------------
/* The following table summarizes additional test results from the GMM estimation.
In particular, we report the HANSEN-tests for each industry, which tests for 
overidentifying restrictions.

Hence, values are identical for all firms within an industry.

Hansen: test statistics
Hansen_P: p-value that null hypothesis can be rejected
Hansen_DF: degrees of freedom
Hansen_CONV: convergence (1=yes, 0=no)
Hansen_No: number of observations
*/

tabstat Hansen_No Hansen_P Hansen_DF Hansen_CONV if Hansen!=., by(WZ_A38) stat(max)

// For IAB: number of valid obs per group
bysort Hansen: egen N_Hansen= count(Hansen)
bysort Hansen_P: egen N_Hansen_P= count(Hansen_P)
bysort Hansen_DF: egen N_Hansen_DF= count(Hansen_DF)
bysort Hansen_CONV: egen N_Hansen_CONV= count(Hansen_CONV)
bysort Hansen_No: egen N_Hansen_No= count(Hansen_No)

table WZ_A38, contents (mean N_Hansen mean N_Hansen_P mean N_Hansen_DF mean N_Hansen_CONV mean N_Hansen_No)

sort idnum year


* Summarize missing values in regression variables
* -------------------------------------------------
	cap  gen NOMISS=1
	cap  replace NOMISS=0 if Y==. | L.Y==. | L==. | L.L==. | K==. | L.K==. ///
	                             | M==. |L.M==.| WZ_A38==""						

cap tab NOMISS
label variable NOMISS "indicator of valid WZ_A38 and no missing values in regression variables"


* ==============================================================================
* Clean and save
* ==============================================================================


* clean
* -----
keep idnum year OMEGAIND38 WZ_A38 WZ_new_1 WZ_new_2 NOMISS Hansen* ecross_c ///
	 sizegr_d L_Share VA WL Capital Material Labour LShare_D99 LShare_D0


* save estimates
* ---------------
save  "$data\OMEGA22.dta", replace


********************************************************************************
*** End 
cap noi log close
********************************************************************************