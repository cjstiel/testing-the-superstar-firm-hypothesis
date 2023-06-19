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
log using "$log/04_create_variables.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "04_create_variables.do"
Content: Data preparation IV: Create variables
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v03, 08.06.2021
--------------------------------------------------------------------------------

uses:  "$data/panel-ACF-ext.dta"
saves: "$data/panel-ACF-final.dta"


File structure
--------------
 1) Material
 2) Sales
 3) Labor
	3.1 Wage bill
	3.2 Labor productivity
	3.3 Number of employees without tenure
	3.4 Number of employees by education/qualification level
	3.5 Number of employees by contract type
	3.6 Additional work force
 4) Investments / Capital
	4.1 Investments
	4.2 Capital stock

 
==============================================================================*/

set more off

* Version
version 14


********************************************************************************
* 			Start							 
******************************************************************************** 

* load data
* ---------
use "$data/panel-ACF-ext.dta", clear

* define missing values
* ----------------------
mvdecode _all, mv(-9 -8 -1 -2)



********************************************************************************
* 1) Material	
********************************************************************************


* Expenditure for intermediate goods and services (nominal)
* ---------------------------------------------------------
gen M_nom = M_share/100 * SALES_nom
label variable M_nom "intermediate goods and services, current prices (nominal) [EUR]"
sort idnum jahr

* Expenditure for intermediate goods and services (deflated)
* ----------------------------------------------------------
gen M = M_nom/MP_VGR
label variable M "intermediate goods and services, constant prices [EUR]"
sort idnum jahr


********************************************************************************
* 2) Sales
********************************************************************************


* Sales (deflated)
* ---------------
gen SALES = SALES_nom/GOP_VGR
label variable SALES "sales, constant prices [EUR]"
sort idnum jahr

* Value added (deflated)
* ----------------------
gen VA = SALES - M
label variable VA "value added, constant prices [EUR]"
sort idnum jahr


********************************************************************************
* 	3) Labor
********************************************************************************

*-------------------------------------------------------------------------------
* 3.1 Wage bill
*-------------------------------------------------------------------------------

* Average wage per year based on monthly wage (nominal)
* -----------------------------------------------------
gen WL_nom = wsum_c*12
label variable WL_nom "total yearly wage sum, based on wage sum in month June, current prices [EUR]"
sort idnum jahr

* Average wage per year based on monthly wage (deflated)
* -----------------------------------------------------
gen WL = WL_nom/LCOST_VGR_1digit
label variable WL "total yearly wage sum, based on wage sum in month June, constant prices [EUR]"
sort idnum jahr

*-------------------------------------------------------------------------------
* 3.2 Labor productivity
*-------------------------------------------------------------------------------

* labor productivity (based on deflated values)
* ----------------------------------------------
gen YL = VA / L
label variable YL "Arbeitsproduktivitaet (value added / labour)"
sort idnum jahr

*-------------------------------------------------------------------------------
* 3.3 Number of employees without tenure
*-------------------------------------------------------------------------------

gen Anteil_befr = empft_c/decnua_c
gen Anteil2_befr = empft_c/emptq1_c
gen Anteil3_befr = empft_c/empt_c

label variable Anteil_befr "Anteil befristet Beschäftigte an allen Beschäftigten Q1"
label variable Anteil2_befr "Anteil befristet Beschäftigte an allen Beschäftigten Q26"
label variable Anteil3_befr "Anteil befristet Beschäftigte an allen Beschäftigten Q26 Summe"

tabstat Anteil_befr Anteil2_befr Anteil3_befr, stats(n min p1 p25 p50 mean p75 p99 max) columns(statistics)


*-------------------------------------------------------------------------------
* 3.4 Number of employees by education/qualification level
*-------------------------------------------------------------------------------

gen Anteil_eB = empls_c/empt_c /* einfache Tätigkeiten, keine Berufsausbildung erforderlich*/
label variable Anteil_eB "Anteil Besch. mit einfacher Tätigkeiten an Gesamtbeschäftigung"

gen Anteil_qBL = empska_c/empt_c /* qual. Tätigkeiten, Berufsausbildung (Lehre) erforderlich*/
label variable Anteil_qBL "Anteil Besch. mit qual. Tätigkeiten (Lehre) an Gesamtbeschäftigung"

gen Anteil_qBU = empct_c/empt_c /* qual. Tätigkeiten, Uniabschluss erforderlich*/
label variable Anteil_qBU "Anteil Besch. mit qual. Tätigkeiten (Uni) an Gesamtbeschäftigung"

gen Anteil_Inh = empot_c/empt_c /* Tätige Inhaber*/
label variable Anteil_Inh "Anteil tätige Inhaber an Gesamtbeschäftigung"

gen Anteil_Bea = appcst_c/empt_c /*Beamtenanwärter*/
label variable Anteil_Bea "Anteil Beamtenanwärter an Gesamtbeschäftigung"

gen Anteil_Azu = appt_c/empt_c /*Azubis*/
label variable Anteil_Azu "Anteil Azubis an Gesamtbeschäftigung"

tabstat Anteil_eB Anteil_qBL Anteil_qBU Anteil_Inh Anteil_Bea Anteil_Azu, stats(n min p1 p25 p50 mean p75 p99 max) columns(statistics)


*-------------------------------------------------------------------------------
* 3.5 Number of employees by contract type
*-------------------------------------------------------------------------------

* Note: These employees are part of the distribution by education level. They
* do not count as additional employees.
gen Anteil_mini = empmt_c/empt_c /*geringfügig Beschäftigte*/
label variable Anteil_mini "Anteil geringfügig Beschäftigte an Gesamtbeschäftigung"

gen Anteil_midi = empm2t_c/empt_c /* Midijobber*/
label variable Anteil_midi "Anteil Midijobber an Gesamtbeschäftigung"

tabstat Anteil_mini Anteil_midi, stats(n min p1 p25 p50 mean p75 p99 max) columns(statistics)


*-------------------------------------------------------------------------------
* 3.6 Additional work force
*-------------------------------------------------------------------------------

gen Anteil_1eur = empm1t_c/empt_c /* 1-Euro-Jobber*/
label variable Anteil_1eur "1-Euro-Jobber im Verhältnis zur Gesamtbeschäftigung (zusätzliches Personal!)"

gen Anteil_fM = addfl_c/empt_c /* freie Mitarbeiter*/
label variable Anteil_fM "freie Mitarbeiter im Verhältnis zur Gesamtbeschäftigung (zusätzliches Personal!)"

gen Anteil_LA = addaw_c/empt_c /* Leiharbeiter*/
label variable Anteil_LA "Leiharbeiter im Verhältnis zur Gesamtbeschäftigung (zusätzliches Personal!)"

gen Anteil_Prak = addint_c/empt_c /* Praktikanten*/
label variable Anteil_Prak "Praktikanten im Verhältnis zur Gesamtbeschäftigung (zusätzliches Personal!)"

tabstat Anteil_1eur Anteil_fM Anteil_LA Anteil_Prak, stats(n min p1 p25 p50 mean p75 p99 max) columns(statistics)



********************************************************************************
* 4) Investments / Capital
********************************************************************************


*-------------------------------------------------------------------------------
* 4.1) Investments					
*-------------------------------------------------------------------------------


* Deflate total investments
* ----------------------------------
replace I_nom = 0 if ininvf_b == 1
gen I = I_nom/I_TP_VGR
label variable I "investments, constant prices [EUR]"
sort idnum jahr

* Deflated net (additional) investments
* --------------------------------------
gen I_net = I_share_erw/100*I
label variable I_net "net investments, constant prices [EUR]"
sort idnum jahr

* Deflate replacement investments
* -------------------------------
gen I_re = I-I_net
label variable I_re "replacement investments, constant prices [EUR]"
sort idnum jahr


*-------------------------------------------------------------------------------
* 4.2) Capital stock
*-------------------------------------------------------------------------------

* Step 1: calculate initial capital stock K_0
* --------------------------------------------
* Type 1: Using capital-labor ration from VGR
bysort idnum (jahr): gen K_PIM_a = L*KL_ratio_nom_VGR if _n==1

* Type 2: Based on average replacement investments and industry-specific depreciation rate
bysort idnum (jahr): egen I_re_av = mean(I_re)
bysort idnum (jahr): gen K_PIM_b = I_re_av/K_DEPR_VGR if _n==1
drop I_re_av

* mean of both types (only if_n==1 valid)
egen K_PIM = rowmean(K_PIM_a K_PIM_b)
drop K_PIM_a K_PIM_b


* Step 2: Apply Perpetual Inventory Method (PIM)
* ----------------------------------------------
/* Append panel by generating all IT-time combinations to avoid gaps in 
investments time series which stop PIM.*/
gen Iorig = 1
tsset idnum jahr
tsfill
bysort idnum: carryforward K_DEPR_VGR, replace

* Set investments temporarily to zero if missing
gen temp_I=I
replace temp_I=0 if temp_I==.

* Calculate capital stock in each year
bysort idnum (jahr): replace K_PIM = (1-K_DEPR_VGR)*K_PIM[_n-1] + temp_I if _n>=2
label variable K_PIM "capital stock, constant prices [EUR]"
sort idnum jahr

* Step 3: Set capital stock = 0 to missing
* -----------------------------------------
replace K_PIM=. if K_PIM==0


* Step 4: set capital stock in last observation year to mkssing
* -----------------------------------------------------------------------
/* Reason: In 2017 investments are no longer observed (part of 2018 
questionnaire) and temp_I=0 through all IDs. */
replace K_PIM=. if jahr==2017


* clean
* ------
drop if Iorig==.
drop Iorig temp_I


*==============================================================================*
* 							CLEAN and SAVE DATA
*==============================================================================*

cap noi erase "$data/panel-ACF-ext.dta"

compress
save "$data/panel-ACF-final.dta", replace

*==============================================================================*
* 							END
cap log close
*==============================================================================*
