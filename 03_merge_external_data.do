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
log using "$log/03_merge_external_data.log", replace

/*------------------------------------------------------------------------------
IAB project name: "Determinanten des Beschäftigungswachstums in kleinsten und 
				   kleinen Unternehmen"
File name: "03_merge_external_data.do"
Content: Data preparation III: Merge external data
Authors: Alexander Schiersch (DIW Berlin), Caroline Stiel (DIW Berlin)
Version: v04, 26.06.2021
--------------------------------------------------------------------------------

uses:  "$orig/fdz1243_vgr_daten_gesamt_1991-2017.dta", "$data/panel-ACF-basic.dta"
saves: "$data/panel-ACF-ext.dta"

File structure
--------------
1) Load and clean external VGR data
	1.1 Prepare 2-digit VGR data
	1.2 Prepare 1-digit VGR data
2) Prepare IAB data
	2.1 Prepare 2-digit IAB data
	2.2 Prepare 1-digit IAB data
	2.3 Did all observation receive a NACE code? (based on br09_d)
3) Match VGR data to IAB data (2 digit)
	3.1 Match via WZ_new_2 (based on wz08)
	3.2 Match remaining observations using WZ_br_2 (based on br09_d)
4) Match VGR data to IAB data (1 digit)
	4.1 Match via WZ_new_1 (based on wz08)
	4.2 Match remaining observations using WZ_br_1 (based on br09_d)
5) Replace 2-digit VGR data with 1-digit VGR data

==============================================================================*/

set more off

* Version
version 14


********************************************************************************
* 			Start							 
******************************************************************************** 

********************************************************************************
* 					1) Load and clean external VGR data
********************************************************************************

* Select relevant years
*----------------------
use "$orig/fdz1243_vgr_daten_gesamt_1991-2017.dta", clear
keep if year>=1992 & year<=2017
save "$data/VGR_data_1991-2017.dta", replace


* ------------------------------------------------------------------------------
* 1.1) Prepare 2-digit VGR data	
* ------------------------------------------------------------------------------

* load STATA-file
* ----------------
use "$data/VGR_data_1991-2017.dta", clear

* clear data
* -----------
keep WZ_new_2 year /// identifier
	 CPI_VGR I_GEI_VGR I_SOFTP_VGR I_RDP_VGR BAV_GEI_VGR BAV_SOFTP_VGR /// deflators GER
	 BAV_RDP_VGR NAV_GEI_VGR NAV_SOFTP_VGR NAV_RDP_VGR ///
	 BAV_VGR BAV_AUS_VGR /// deflators 2-digit
	 BAV_BAU_VGR BAV_SON_VGR KL_ratio_nom_VGR KL_ratio_real_VGR K_DEPR_VGR ///
	 I_TP_VGR I_AUS_VGR I_BAU_VGR I_SON_VGR MP_VGR GOP_VGR VAP_VGR

	 
sort WZ_new_2 year

* temporary save
* ---------------
save "$data/external_data_2digit_temp.dta", replace


* ------------------------------------------------------------------------------
* 1.2) Prepare 1-digit VGR data	
* ------------------------------------------------------------------------------

* load STATA-file
* ----------------
use "$data/VGR_data_1991-2017.dta", clear

* clear data
* -----------
keep WZ_new_1 year /// identifier
	 CPI_VGR I_GEI_VGR I_SOFTP_VGR I_RDP_VGR BAV_GEI_VGR BAV_SOFTP_VGR /// deflators GER
	 BAV_RDP_VGR NAV_GEI_VGR NAV_SOFTP_VGR NAV_RDP_VGR ///
	 BAV_VGR_1digit BAV_AUS_VGR_1digit BAV_BAU_VGR_1digit BAV_SON_VGR_1digit /// deflators 1-digit
	 KL_ratio_nom_VGR_1digit KL_ratio_real_VGR_1digit K_DEPR_VGR_1digit ///
	 I_TP_VGR_1digit I_AUS_VGR_1digit I_BAU_VGR_1digit I_SON_VGR_1digit ///
	 MP_VGR_1digit GOP_VGR_1digit VAP_VGR_1digit LCOST_VGR_1digit


* rename variables
* ----------------
rename CPI_VGR CPI_VGR_1digit
rename I_GEI_VGR I_GEI_VGR_1digit
rename I_SOFTP_VGR I_SOFTP_VGR_1digit
rename I_RDP_VGR I_RDP_VGR_1digit
rename BAV_GEI_VGR BAV_GEI_VGR_1digit
rename BAV_SOFTP_VGR BAV_SOFTP_VGR_1digit
rename BAV_RDP_VGR BAV_RDP_VGR_1digit
rename NAV_GEI_VGR NAV_GEI_VGR_1digit
rename NAV_SOFTP_VGR NAV_SOFTP_VGR_1digit
rename NAV_RDP_VGR  NAV_RDP_VGR_1digit
 
sort WZ_new_1 year

* drop duplicates
* ----------------
duplicates drop WZ_new_1 year, force

* temporary save
* ----------------
save "$data/external_data_1digit_temp.dta", replace



********************************************************************************
* 					2) Prepare IAB data
********************************************************************************

* Notes: Adapts IAB industry data to official NACE classification in VGR

* load IAB data
* -------------
use "$data/panel-ACF-basic.dta", clear


*-------------------------------------------------------------------------------
* 2.1) Prepare NACE-2-digit IAB data
* ------------------------------------------------------------------------------


if $WZ08==1{
* Create 2-digit NACE based on wz_08 (5-digit)
* --------------------------------------------
tostring wz08, gen(wz08_str)

replace wz08_str = "0" + wz08_str if length(wz08_str)==4
gen WZ_new_2= substr(wz08_str,1,2)
destring WZ_new_2, replace

label variable WZ_new_2 "WZ-Klassifikation ab 2008 2-digit (based on wz08)"

* Number of valid obs per industry
tab WZ_new_2, mi


// Number of valid obs per group
bysort WZ_new_2: egen N_WZ_new_2 = count(WZ_new_2)

}


* Create 2-digit NACE based on industry information
* --------------------------------------------------
gen WZ_br_2 = .
replace WZ_br_2 = 16 if br09_d==6 	| br00_d==6 	| br93_d==13
replace WZ_br_2 = 22 if br09_d==8 	| br00_d==8 	| br93_d==4
replace WZ_br_2 = 23 if br09_d==9 	| br00_d==9 	| br93_d==5
replace WZ_br_2 = 24 if br09_d==10 	| br00_d==10 	| br93_d==6
replace WZ_br_2 = 25 if br09_d==11 	| br00_d==12 	| br93_d==7
replace WZ_br_2 = 26 if br09_d==12 	| br00_d==16 	| br00_d==17 | br93_d==11 | br93_d==12
replace WZ_br_2 = 27 if br09_d==13 	
replace WZ_br_2 = 28 if br09_d==14 	| br00_d==13 	| br93_d==8
replace WZ_br_2 = 30 if 			  br00_d==15 	| br93_d==10
replace WZ_br_2 = 33 if br09_d==17 
replace WZ_br_2 = 38 if 			  br00_d==11 
replace WZ_br_2 = 43 if br09_d==19 	| br00_d==20 	| br93_d==18
replace WZ_br_2 = 45 if br09_d==20  | br00_d==21
replace WZ_br_2 = 46 if br09_d==21  | br00_d==22
replace WZ_br_2 = 47 if br09_d==22  | br00_d==23
replace WZ_br_2 = 61 if 			  br00_d==25
replace WZ_br_2 = 63 if 			  br00_d==28
replace WZ_br_2 = 64 if 			  br00_d==26 	| br93_d==21
replace WZ_br_2 = 65 if 			  br00_d==27 	| br93_d==22
replace WZ_br_2 = 68 if br09_d==27 	| br00_d==31
replace WZ_br_2 = 69 if br09_d==28  | br00_d==30 	| br93_d==29
replace WZ_br_2 = 70 if br09_d==29  
replace WZ_br_2 = 71 if br09_d==30 					| br93_d==30
replace WZ_br_2 = 72 if br09_d==31  | br00_d==29
replace WZ_br_2 = 73 if 							  br93_d==32
replace WZ_br_2 = 75 if br09_d==33  
replace WZ_br_2 = 77 if br09_d==34	| br00_d==32 	| br93_d==34
replace WZ_br_2 = 78 if br09_d==35 	
replace WZ_br_2 = 85 if br09_d==37 	| br00_d==34 	| br93_d==26
replace WZ_br_2 = 86 if 							  br93_d==28 
replace WZ_br_2 = 87 if 							  br93_d==24 
replace WZ_br_2 = 95 if br09_d==40 	
replace WZ_br_2 = 96 if br09_d==41 	| br00_d==38 	| br93_d==25
replace WZ_br_2 = 94 if br09_d==42	| br00_d==39 	| br93_d==36 | br93_d==37
replace WZ_br_2 = 84 if br09_d==43 	| br00_d==41 	| br93_d==39 | br93_d==40 | br93_d==41
replace WZ_br_2 = 97 if 			  br00_d==40 	| br93_d==38

* The following industries could not be matched:

* NACE 2-digit for industry 1, 2, 3, 23, 24, 26, 38, 39
* -----------------------------------------------------
/* Industries mainly correspond to NACE 1-digit A, B, D/E, H, J, K, Q, R. 
Leave WZ_br_2 empty and replace later by VGR NACE-1-digit WZ_new_1.

* For the others
* ---------------
Approximate NACE by most important subgroup as measured by the number of firms in 
the Statistical Year Book 2016, Section 20 [Strukturdaten der Unternehmen 2014].
*/

* NACE 2-digit for industry 4: Nahrungs- und Genussmittel (WZ 10-12)
* ------------------------------------------------------------------------
* most relevant subgroup: Herstellung von Nahrungs- und Futtermitteln (WZ 10)
replace WZ_br_2 = 10 if br09_d==4 	| br00_d==3 | br93_d==16

* NACE 2-digit for industry 5: Textilien, Lederwaren, Schuhe (WZ 13-15)
* -------------------------------------------------------------------------
* most relevant subgroup: Herstellung von Textilien (WZ 13)
replace WZ_br_2 = 13 if br09_d==5 	| br00_d==4 | br93_d==15

* NACE 2-digit for industries Papier, Druckerzeugnisse (WZ 17-18)
* --------------------------------------------------------------------------
* most relevant subgroup: Druckerei (WZ 17)
replace WZ_br_2 = 18 if  			  br00_d==5 | br93_d==14

* NACE 2-digit for industry 7: Chemie, Pharmazie, Kokerei (WZ 19-21)
* --------------------------------------------------------------------------
* most relevant subgroup: Chemische Industrie (WZ 20)
replace WZ_br_2 = 20 if br09_d==7 	| br00_d==7 | br93_d==3

* NACE 2-digit for industry 15: KFZ und sonstiger Fahrzeugbau (WZ 29-30)
* --------------------------------------------------------------------------
* most relevant subgroup: Herstellung von KFZ und -Teilen (WZ 29)
replace WZ_br_2 = 29 if br09_d==15 	| br00_d==14 | br93_d==9

* NACE 2-digit for industry 16: Moebel und sonstige Waren (WZ 31-32)
* --------------------------------------------------------------------------
* most relevant subgroup: Herstellung sonstiger Waren(WZ 32)
replace WZ_br_2 = 32 if br09_d==16 | br00_d==18

* NACE 2-digit for industry 18: Hoch- und Tiefbau (WZ 41-42)
* --------------------------------------------------------------------------
* most relevant subgroup: Hochbau (WZ 31)
replace WZ_br_2 = 41 if br09_d==18 	| br00_d==19 | br93_d==17

* NACE 2-digit for industry 25: Beherbergung und Gastronomie (WZ 55-56)
* --------------------------------------------------------------------------
* most relevant subgroup: Gastronomie (WZ 56)
replace WZ_br_2 = 56 if br09_d==25 	| br00_d==33 | br93_d==23

* NACE 2-digit for industry 32: Werbung, Marktforschung, Design, etc. (WZ 73-74)
* -----------------------------------------------------------------------------
* most relevant subgroup: sonstige Tätigkeiten (WZ 74)
replace WZ_br_2 = 74 if br09_d==32 

* NACE 2-digit for industry 36: Reise/Wach- und Sicherheit/Gartenbau (WZ 79-82)
* -----------------------------------------------------------------------------
* most relevant subgroup: Gebäudebetreuung u. Garten/-Landschaftsbau (WZ 81)
replace WZ_br_2 = 81 if br09_d==36

label variable WZ_br_2 "WZ-Klassifikation ab 2008 2-digit (based on Branchenvariablen)"

* overview NACE codes
* ---------------------
tab WZ_br_2, mi

// number of obs per group
bysort WZ_br_2: egen N_WZ_br_2 = count(WZ_br_2)

sort idnum jahr



*-------------------------------------------------------------------------------
* 2.2) Prepare NACE 1-digit IAB data
*-------------------------------------------------------------------------------

if $WZ08==1{
* Create NACE 1-digit based on wz_08 (5-digit)
* --------------------------------------------
gen WZ_new_1=""
replace WZ_new_1= "A" if WZ_new_2 >=1 & WZ_new_2 <= 5
replace WZ_new_1= "B" if WZ_new_2 >=5 & WZ_new_2 < 10
replace WZ_new_1= "C" if WZ_new_2 >=10 & WZ_new_2 <= 33
replace WZ_new_1= "D" if WZ_new_2 ==35
replace WZ_new_1= "E" if WZ_new_2 >=36 & WZ_new_2 <= 39
replace WZ_new_1= "F" if WZ_new_2 >=41 & WZ_new_2 <= 43
replace WZ_new_1= "G" if WZ_new_2 >=45 & WZ_new_2 <= 47
replace WZ_new_1= "H" if WZ_new_2 >=49 & WZ_new_2 <= 53
replace WZ_new_1= "I" if WZ_new_2 >=55 & WZ_new_2 <= 56
replace WZ_new_1= "J" if WZ_new_2 >=58 & WZ_new_2 <= 63
replace WZ_new_1= "K" if WZ_new_2 >=64 & WZ_new_2 <= 66
replace WZ_new_1= "L" if WZ_new_2 ==68
replace WZ_new_1= "M" if WZ_new_2 >=69 & WZ_new_2 <= 75
replace WZ_new_1= "N" if WZ_new_2 >=77 & WZ_new_2 <= 82
replace WZ_new_1= "O" if WZ_new_2 ==84
replace WZ_new_1= "P" if WZ_new_2 ==85
replace WZ_new_1= "Q" if WZ_new_2 >=86 & WZ_new_2 <= 88
replace WZ_new_1= "R" if WZ_new_2 >=90 & WZ_new_2 <= 93
replace WZ_new_1= "S" if WZ_new_2 >=94 & WZ_new_2 <= 96
replace WZ_new_1= "T" if WZ_new_2 >=97 & WZ_new_2 <= 98
replace WZ_new_1= "U" if WZ_new_2 ==99

label variable WZ_new_1 "Wirtschaftszweig Klassifikation 2008 1-Steller (based on wz08)"

* overview NACE 1-digit
* ----------------------
tab WZ_new_1, mi

// number of obs per group
bysort WZ_new_1: egen N_WZ_new_1 = count(WZ_new_1)
}


* Create 2-digit NACE based on industry information
* --------------------------------------------------
gen WZ_br_1 =""
replace WZ_br_1 = "A" if br09_d== 1 				| br00_d== 1 				| br93_d==1
replace WZ_br_1 = "B" if br09_d== 2 
replace WZ_br_1 = "C" if (br09_d>=4 & br09_d<=17) 	| (br00_d>=3 & br00_d<=18) 	| (br93_d>=3 & br93_d<=16)
replace WZ_br_1 = "D" if br09_d==3 					| br00_d== 2				| br93_d==2
replace WZ_br_1 = "E" if br00_d== 11 				| br00_d== 36 				| br93_d==33
replace WZ_br_1 = "F" if (br09_d>=18 & br09_d<=19) 	| (br00_d>=19 & br00_d<=20) | (br93_d>=17 & br93_d<=18)
replace WZ_br_1 = "G" if (br09_d>=20 & br09_d<=22) 	| (br00_d>=21 & br00_d<=23) | br93_d==19
replace WZ_br_1 = "H" if br09_d==23 				| br00_d==24 				| br93_d==20
replace WZ_br_1 = "I" if br09_d==25 				| br00_d==33 				| br93_d==23
replace WZ_br_1 = "J" if br09_d==24 				| br00_d==25 |br00_d==28	| br93_d==27
replace WZ_br_1 = "K" if br09_d==26 				| br00_d==26 | br00_d==27 	| br93_d==21 | br93_d==22
replace WZ_br_1 = "L" if br09_d==27 				| br00_d==31 				| br93_d==31
replace WZ_br_1 = "M" if (br09_d>=28 & br09_d<=33) 	| (br00_d>28 & br00_d<=30) | br93_d==29 | br93_d==30 | br93_d==32
replace WZ_br_1 = "N" if (br09_d>=34 & br09_d<=36) 	| br00_d==32 				| br93_d==35 | br93_d==34
replace WZ_br_1 = "O" if br09_d==43 				| br00_d==41 				| (br93_d>=39 & br93_d<=41)
replace WZ_br_1 = "P" if br09_d==37 				| br00_d==34 				| br93_d==26
replace WZ_br_1 = "Q" if br09_d==38 				| br00_d==35 				| br93_d==28 | br93_d==24
replace WZ_br_1 = "R" if br09_d==39 				| br00_d==37 
replace WZ_br_1 = "S" if (br09_d>=40 & br09_d<=42) 	| (br00_d>=38 & br00_d<=39) | (br93_d>=36 & br93_d<=37) | br93_d==25
replace WZ_br_1 = "T" if 							  br00_d==40 				| br93_d==38
label variable WZ_br_1 "Wirtschaftszweig Klassifikation 2008 1-Steller (based on Branchenvariable)"

* overview NACE 1-digit
* ---------------------
tab WZ_br_1, mi

// number of obs per group
bysort WZ_br_1: egen N_WZ_br_1 = count(WZ_br_1)



*-------------------------------------------------------------------------------
* 2.3) Did all observation receive a NACE code? (based on br09_d)
* ------------------------------------------------------------------------------

* replace missing values in NACE 2-digit by NACE 1-digit
* -------------------------------------------------------
gen WZ_br_ko = WZ_br_2
tostring WZ_br_ko, replace
replace WZ_br_ko=WZ_br_1 if WZ_br_ko=="."

label variable WZ_br_ko "Wirtschaftszweig Klassifikation 2008 kombiniert (based on Branchenvariable)"

* overview NACE codes
* --------------------
tab WZ_br_ko, mi

// number of obs per group
bysort WZ_br_ko: egen N_WZ_br_ko = count(WZ_br_ko)

* Check if number of missings(WZ_br_ko) == missings(br09_d & br00_d & br93_d)
count if br09_d==. & br00_d==. & br93_d==.
count if WZ_br_ko=="."


sort idnum jahr


********************************************************************************
* 					3) Match VGR data to IAB data (2 digit)
********************************************************************************


rename jahr year

*-------------------------------------------------------------------------------
* 3.1) Match via WZ_new_2 (based on wz08)	
* ------------------------------------------------------------------------------

if $WZ08==1{
sort WZ_new_2 year
merge m:1 year WZ_new_2 using "$data/external_data_2digit_temp.dta"

* Delete unmatched VGR obs
* ------------------------
drop if _merge==2

* Save complete matching data set
* -------------------------------
save "$data/match_wz08_2digit_temp_all.dta", replace

* Save successful matches separately
* ----------------------------------
keep if _merge==3
drop _merge
save "$data/match_wz08_2digit_temp_m3.dta", replace



*-------------------------------------------------------------------------------
* 3.2) Match remaining observations using WZ_br_2 (based on br09_d)
* ------------------------------------------------------------------------------

* Select remaining observations
* ------------------------------
use "$data/match_wz08_2digit_temp_all.dta"
keep if _merge==1

drop _merge WZ_new_2 /// identifier
	 CPI_VGR I_GEI_VGR I_SOFTP_VGR I_RDP_VGR BAV_GEI_VGR BAV_SOFTP_VGR /// deflators GER
	 BAV_RDP_VGR NAV_GEI_VGR NAV_SOFTP_VGR NAV_RDP_VGR ///
	 BAV_VGR BAV_AUS_VGR /// deflators 2-digit
	 BAV_BAU_VGR BAV_SON_VGR KL_ratio_nom_VGR KL_ratio_real_VGR K_DEPR_VGR ///
	 I_TP_VGR I_AUS_VGR I_BAU_VGR I_SON_VGR MP_VGR GOP_VGR VAP_VGR
}


* Matche using WZ_br09_d
* -----------------------
rename  WZ_br_2 WZ_new_2
label variable WZ_new_2 "WZ2008 2-digit"
sort WZ_new_2 year
merge m:1 year WZ_new_2 using "$data/external_data_2digit_temp.dta"

* Delete unmatched VGR obs
* ------------------------
drop if _merge==2
drop _merge

* Append obs (matches + not matched) to successful matches via WZ_new_2
* ----------------------------------------------------------------------
if $WZ08==1{
cap noi append using "$data/match_wz08_2digit_temp_m3.dta", nolabel
}


********************************************************************************
* 					4) Match VGR data to IAB data (1 digit)
********************************************************************************

*-------------------------------------------------------------------------------
* 4.1) Match via WZ_new_1 (based on wz08)
*-------------------------------------------------------------------------------

if $WZ08==1{

sort WZ_new_1 year
merge m:1 year WZ_new_1 using "$data/external_data_1digit_temp.dta"

* Delete unmatched VGR obs
* ------------------------
drop if _merge==2

* Save complete matching data set
* -------------------------------
save "$data/match_wz08_1digit_temp_all.dta", replace

* Save successful matches separately
* ----------------------------------
keep if _merge==3
drop _merge
save "$data/match_wz08_1digit_temp_m3.dta", replace



*-------------------------------------------------------------------------------
* 4.2) Match remaining observations using WZ_br_1 (based on br09_d)
*-------------------------------------------------------------------------------

* Select remaining observations
* ------------------------------
use "$data/match_wz08_1digit_temp_all.dta"
keep if _merge==1


drop _merge WZ_new_1 /// identifier
	 CPI_VGR_1digit I_GEI_VGR_1digit I_SOFTP_VGR_1digit I_RDP_VGR_1digit BAV_GEI_VGR_1digit BAV_SOFTP_VGR_1digit /// deflators GER
	 BAV_RDP_VGR_1digit NAV_GEI_VGR_1digit NAV_SOFTP_VGR_1digit NAV_RDP_VGR_1digit ///
	 BAV_VGR_1digit BAV_AUS_VGR_1digit BAV_BAU_VGR_1digit BAV_SON_VGR_1digit /// deflators 1-digit
	 KL_ratio_nom_VGR_1digit KL_ratio_real_VGR_1digit K_DEPR_VGR_1digit ///
	 I_TP_VGR_1digit I_AUS_VGR_1digit I_BAU_VGR_1digit I_SON_VGR_1digit ///
	 MP_VGR_1digit GOP_VGR_1digit VAP_VGR_1digit LCOST_VGR_1digit
}

* Match using WZ_br09_d
* -----------------------
rename  WZ_br_1 WZ_new_1
sort WZ_new_1 year
merge m:1 year WZ_new_1 using "$data/external_data_1digit_temp.dta"
drop if _merge==2

drop _merge

* Append obs (matches + not matched) to successful matches via WZ_new_1
* ----------------------------------------------------------------------
if $WZ08==1{
cap noi append using "$data/match_wz08_1digit_temp_m3.dta", nolabel
}

rename year jahr


********************************************************************************
* 5) Replace 2-digit VGR data with 1-digit VGR data
********************************************************************************

* Replace all observations for which VGR information on 2-digit is unavailable
* (e.g., because WZ_new_2 = .) with VGR 1-digit information

foreach VARIABLE of varlist CPI_VGR I_GEI_VGR I_SOFTP_VGR I_RDP_VGR BAV_GEI_VGR BAV_SOFTP_VGR /// deflators GER
	 BAV_RDP_VGR NAV_GEI_VGR NAV_SOFTP_VGR NAV_RDP_VGR ///
	 BAV_VGR BAV_AUS_VGR /// deflators 2-digit
	 BAV_BAU_VGR BAV_SON_VGR KL_ratio_nom_VGR KL_ratio_real_VGR K_DEPR_VGR ///
	 I_TP_VGR I_AUS_VGR I_BAU_VGR I_SON_VGR MP_VGR GOP_VGR VAP_VGR {
	replace `VARIABLE' = `VARIABLE'_1digit if `VARIABLE'==.
	drop `VARIABLE'_1digit
}

* Number of observations with match in external VGR data
* -------------------------------------------------------
tabstat CPI_VGR I_TP_VGR MP_VGR GOP_VGR VAP_VGR K_DEPR_VGR KL_ratio_nom_VGR, stat(n)

* For comparison: total number of observations
* --------------------------------------------
display _N


*==============================================================================*
* 							CLEAN and SAVE DATA
*==============================================================================*

* delete temp-datasets
cap noi erase "$data/external_data_1digit_temp.dta"
cap noi erase "$data/external_data_2digit_temp.dta"

if $WZ08==1{
cap noi erase "$data/match_wz08_1digit_temp_m3.dta"
cap noi erase "$data/match_wz08_2digit_temp_m3.dta"
cap noi erase "$data/match_wz08_1digit_temp_all.dta"
cap noi erase "$data/match_wz08_2digit_temp_all.dta"
}

cap noi erase "$data/panel-ACF-basic.dta"
cap noi erase "$data/VGR_data_1991-2017.dta"

compress
save "$data/panel-ACF-ext.dta", replace


*==============================================================================*
* 							END
cap log close
*==============================================================================*