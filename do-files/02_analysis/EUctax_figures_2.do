************************************************************
*  EUctax_figures_2.do          
*     IRFS and CIRFs of carbon tax on various variables
************************************************************
*
global none ""
global YE "i.year"
*------------------------------------------------------------------------------------------------*
* Program to compute IRF for VAR(svlags) wrt first variable shock, given estimated coefficients in b
* Syntax program var2irf svlags p    where svlags = number of VAR lags and p = number of horizons 
*-------------------------------------------------------------------------------------------------*
cap program drop varirf
program varirf
 local svlags = `1' // first argument is svlags
 local p = `2'      // second argument is VAR lag length
 local pp1 = `p'+1
 local k0 = 2*`svlags'
 mat A0 = [1, 0 \ -b[1,`k0'+1], 1]
 mat A0inv = inv(A0)
 mat BLR = A0inv
 local ki = 1
 forvalues i = 1/`svlags' {
   mat A`i' = b[1,`ki'..`ki'+1] \ b[1,`k0'+`ki'+1..`k0'+`ki'+2]
   mat B`i' = A0inv*A`i'
   mat BLR = BLR - B`i'
   local ki = `ki'+2
 }
 mat BLRinv = inv(BLR)
 sca theta21lr = BLRinv[2,1]
 mat eps1 = A0inv*[1 \ 0]
 mat vtheta1 = J(2,`svlags',0) , eps1
 forvalues j = 2/`pp1' {
  mat xj = J(2,1,0) 
   forvalues i = 1/`svlags' {
    mat xj = xj + B`i'*vtheta1[1..2,colsof(vtheta1)-`i'+1]
   }
   mat vtheta1 = vtheta1, xj
 }
 mat theta1_var = vtheta1[1..2,`svlags'+1..colsof(vtheta1)]'
end
******************************************************************************************
*	End program definition
******************************************************************************************

use "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Raw data\Analysis\ctax_AEJM_mio.dta", clear

**********************************************************************************
* Create variables and save to temporary dta file for various figure constructions
**********************************************************************************
gen ctaxno = (ctaxyear==.)
gen ctaxpre = (year<ctaxyear)*(1-ctaxno)
gen rater_LCU_USD18sw = rater_LCU_USD18*share19
label var rater_LCU_USD18sw "Carbon tax rate (real, 2018 USD) wtd by coverage share"
* Dolphin et al effective carbon price
gen ecp2018sw = ecp_ghg_tax_usd_2018 // easier name to use and suffix triggers share weighting counterfactual
label var ecp2018sw "Emissions-weighted carbon price (2013 GHG, 2018 USD) (Dolphin et al)" 

keep if tin(1985,2023)
*
replace rater_LCU_USD18sw = 0 if rater_LCU_USD18sw==.
* drop the few observations (eastern Europe) with emissions data before 1990

foreach yy in "emission_ctsectors" {    
	replace `yy' = . if year<1990
	replace l`yy' = . if year<1990
}
*
*
* real GDP price index, 2018 = 1, and real GDP inflation
*
cap drop cnum
cap drop cdum
egen cnum = group(ID)
cap drop pindex 
cap drop infgdp
cap drop x99
sort ID year
gen x99 = .
 replace x99 = pgdp if year==2018
by ID: egen pindex = max(x99)
 replace pindex = 100*pgdp/pindex
xtset cnum year
gen dlpgdp = 100*ln(pindex/L.pindex)

save ctax_gdp_tmp, replace
************************************************************
*	Figures to be created are listed in figlist
************************************************************
global figlist "3a 3b 4a 4b 5a 5b 6a 6b 7a 7b 8a 8b 9a 9b 10a 10b 11a 11b 12a 12b 13a 13b 14a 14b A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15"
foreach fig in $figlist {
global keepdetails = 0 // keeps information needed for figure A4 if equal to 1
global fig "`fig'"	
use ctax_gdp_tmp, clear 
* ----- Set main run parameters ----------------
global p = 8       // number of horizons (years), also number of lags in DL specifications
global pplot = 6   // number of horizons for IRF plot
global lplags = 4  // number of lags in LP specifications, also number of lags of controls in all specifications (0,...,lplags-1)
global svlags = 4  // number of lags in SVAR specifications
local p $p
global dllags `p'
local lplags $lplags
local svlags $svlags
**************************************************************
* Call file to define figure elements for paper
**************************************************************
*	
* Figure 3
* IRF for GDP growth a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "3a" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" "D"
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "3b" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
  global keepdetails = 1
 }
*
* Figure 4	
* IRF for GDP growth a-bivariate LP restricted; b-bivariate SVAR restricted
*
if "`fig'" == "4a" {
  global yvars "lrgdp" 
  global cvarsLP ""
  global nvar 2
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "4b" {
  global yvars "lrgdp" 
  global cvarsLP ""
  global nvar 2
  global LP = 0
  global SVAR = 1 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*
* Figure 5	
* CIRF for GDP  a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "5a" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "5b" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure 6
* IRF for total employment growth a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "6a" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "6b" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 } 
*
* Figure 7	
* CIRF for total employment  a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "7a" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "7b" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 } 
*	
* Figure 8
* IRF for manufacturing employment growth a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "8a" {
  global yvars "lempman" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlrgdp"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "8b" {
  global yvars "lempman" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlrgdp"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*
* Figure 9	
* CIRF for manufacturing employment  a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "9a" {
  global yvars "lempman" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlrgdp"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "9b" {
  global yvars "lempman" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlrgdp"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* Figure 10	
* CIRF for emissions a-Unrestricted(L); b-Restricted(D); LP regression
*
if "`fig'" == "10a" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "10b" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 } 
*	
* Figure 11
* IRF for Revenue Recycling Countries a-gdp growth; b-total employment; LP regression
*
if "`fig'" == "11a" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  keep if (ctaxever==0) | (IntRevRec>=0.5)
  drop if ID=="LIE"
  global smple "EU+RR1"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "11b" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  keep if (ctaxever==0) | (IntRevRec>=0.5)
  drop if ID=="LIE"
  global smple "EU+RR1"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure 12
* IRF for Non-Revenue Recycling Countries a-gdp growth; b-total employment; LP regression
*
if "`fig'" == "12a" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  keep if (ctaxever==0) | (IntRevRec<=0.5)
  drop if ID=="LIE"
  global smple "EU+RR0"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "12b" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  keep if (ctaxever==0) | (IntRevRec<=0.5)
  drop if ID=="LIE"
  global smple "EU+RR0"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 } 
* Figure 13	
* CIRF for emissions a-RR1; b-RR0; LP regression
*
if "`fig'" == "13a" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
   keep if (ctaxever==0) | (IntRevRec>=0.5)
  drop if ID=="LIE"
  global smple "EU+RR1"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "13b" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
   keep if (ctaxever==0) | (IntRevRec<=0.5)
  drop if ID=="LIE"
  global smple "EU+RR0"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 } 
* Figure 14	
* large carbon tax countries  a-lrgdp IRF; b-emissions CIRF; LP regression
*
if "`fig'" == "14a" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if ctaxever
  cap drop x99 
  egen x99 = max(rater_LCU_USD18sw), by(ID)
  gen CT10sw = (x99>=10)
  keep if CT10sw
  global smple "CT10sw"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
* 
if "`fig'" == "14b" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if ctaxever
  cap drop x99 
  egen x99 = max(rater_LCU_USD18sw), by(ID)
  gen CT10sw = (x99>=10)
  keep if CT10sw
  global smple "CT10sw"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure A5
* IRF for GDP growth: no YE, Unrestricted(L)
*
if "`fig'" == "A5" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "none" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure A6
* IRF for total employment growth: no YE, Unrestricted(L)
*
if "`fig'" == "A6" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "none" 
  global xvars "rater_LCU_USD18sw" 
 } 
*	
* Figure A7
* IRF for manufacturing employment growth: no YE, Unrestricted(L)
*
if "`fig'" == "A7" {
  global yvars "lempman" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlemptot"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "none" 
  global xvars "rater_LCU_USD18sw" 
 }
*
* Figure A8	
* CIRF for emissions: no YE, Unrestricted(L) 
*
if "`fig'" == "A8" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "L" 
  global controls "none" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure A9
* IRF for GDP growth: Excluding SCA, Restricted(D)
*
if "`fig'" == "A9" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
   drop if SCA
  global smple "EU+xSCA"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure A10
* IRF for total employment growth: Excluding SCA, Restricted(D)
*
if "`fig'" == "A10" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
   drop if SCA
  global smple "EU+xSCA"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure A11
* IRF for GDP growth: SCA, Restricted(D)
*
if "`fig'" == "A11" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if SCA
  global smple "SCA"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 }
*	
* Figure A12
* IRF for total employment growth: SCA, Restricted(D)
*
if "`fig'" == "A12" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if SCA
  global smple "SCA"
  global speclist "D" 
  global controls "YE" 
  global xvars "rater_LCU_USD18sw" 
 } 
*	
* Figure A13
* IRF for GDP growth using Dolphin tax rates, Restricted(D)
*
if "`fig'" == "A13" {
  global yvars "lrgdp" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "ecp2018sw" 
 } 
*	
* Figure A14
* IRF for total employment growth using Dolphin tax rates, Restricted(D)
*
if "`fig'" == "A14" {
  global yvars "lemptot" 
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global nvar 5
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "IRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "ecp2018sw" 
 } 
* Figure A15	
* CIRF for emissions using Dolphin tax rates, Restricted(D)
*
if "`fig'" == "A15" {
  global yvars "lemission_ctsectors" 
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global nvar 6
  global LP = 1
  global SVAR = 0 
  global IrfCirf = "CIRF"
  keep if EU2
  drop if ID=="LIE"
  global smple "EU+"
  global speclist "D" 
  global controls "YE" 
  global xvars "ecp2018sw" 
 } 
* -------------------------------------------------------------------------------------
************************************************************
* set panel
************************************************************
xtset cnum year
local smple "$smple"
cap drop ydum*
tab year, gen(ydum)
cap drop cdum*
tab ID, gen(cdum)
local nc = r(r)
*
local lplagsm1 = `lplags'-1
local pm2 = `p'-2
local pm1 = `p'-1
local pp1 = `p'+1

foreach spec in "$speclist" {
 global spec "`spec'"
 if "`spec'" == "L" {
  local DS = ""
  mat xpath0 = J(`pp1',1,1) // real carbon tax path
 }
 else {
  local DS = "D."
  mat xpath0 = 1 \ J(`p',1,0) // real carbon tax path
 }
*
foreach y in "$yvars"  {
 global y "`y'"
 cap erase "out\irfs_`y'_`smple'_`spec'_4.xlsx"
 *
 foreach x in "$xvars" {
  sca irfno = 0
  sca rateinit = 40
  sca swfac = 1
   if strmatch("`x'","*sw") sca swfac = 0.3
  mat xpath = rateinit*xpath0
  sca dirfno = 1
  global x "`x'"
  global xsheet "`x'"

 *-------------------------------------------------------------------------------------------
 *             LP estimation 
 *  Via individual regs with dummy variables 
 *  Notes on SE computation:
 *    1. HAC SEs not needed, these are HR (Montiel Olea- Plagborg Moller (2021))
 *    2. SEs computed for full covariance matrix of IRFs across regressions using
 *       x's*resids for different horizon regressions. The messiness below is because
 *       the different horizon regressions are computed over different samples, so VCV matrix
 *       must be computed for the overlapping data in each covariance matrix pair.
 *    3. It is easiest coding to use SUREG to estimate all equestions at once, unfortunately
 *       sureg estimates them all on the same sample which is the sample for longest-horizon
 *       thus it is inefficient relative to OLS one-at-a-time. For sureg implementation see
 *       EUctax_IRF_2.do ("LP estimation III")
 *-------------------------------------------------------------------------------------------
 *
 if $LP==1 {
   global est "LP"
   mat theta11 = J(`pp1',1,1)
   sca fgc = .
   sca pgc = .
   local controls $controls 
    sca irfno = irfno+dirfno
    mat theta21 = J(`pp1',1,0)
    cap drop e99*
    forvalues h = 0/`p' {
     local hp1 = `h'+1
      reg F`h'.d`y' L(0/`lplags').`DS'`x' L(1/`lplags').d`y' $cvarsLP ${`controls'} cdum*, r
     mat b98 = e(b)
     mat theta21[`hp1',1] = b98[1,1]
     * product of X projected off of controls * resids for VCV matrix
     local k = e(df_m)
     cap drop smpl`h' e`h' etax`h' zz`h' ey`h'
	 qui gen smpl`h' = e(sample)
	 qui predict e`h', resid
     qui reg F`h'.d`y' L(1/`lplags').`DS'`x' L(1/`lplags').d`y' $cvarsLP ${`controls'} cdum* if smpl`h', r
	 qui predict ey`h', resid
     qui reg `DS'`x' L(1/`lplags').`DS'`x' L(1/`lplags').d`y' $cvarsLP ${`controls'} cdum* if smpl`h', r
	 qui predict etax`h', resid
	 qui su etax`h' if smpl`h'
     gen zz`h' = (r(N)/(r(N)-1))*(e`h'*etax`h'/r(Var))/sqrt(r(N)-`k') if smpl`h'
*    IRF from rate shock to rate - for inverting rate path to shocks
*    Results are very insensitive to whether eqn is restricted to obs only once tax is initiated
	 cap drop u`h' zu`h'
     if `h'>0 {
      *qui areg F`h'.`DS'`x' L(0/`lplags').`DS'`x' L(1/`lplags').d`y' $cvarsLP ${`controls'}, absorb(cnum) vce(r)
      qui reg F`h'.`DS'`x' L(0/`lplags').`DS'`x' L(1/`lplags').d`y' $cvarsLP ${`controls'} cdum*, r
      mat b97 = e(b)
      mat theta11[`h'+1,1] = b97[1,1]
	  qui predict u`h', resid
 	  qui su etax`h' if smpl`h'
      gen zu`h' = (r(N)/(r(N)-1))*(u`h'*etax`h'/r(Var))/sqrt(r(N)-`k') if smpl`h'
     }
    } // end of loop over horizon
*   Compute covariance matrix over different subsamples for different horizon LP estimation
	mat vtheta21 = I(`p'+1)
	forvalues i = 0/`p' {
	 qui su zz`i'
	 mat vtheta21[`i'+1,`i'+1] = r(Var)
	 dis `i' "   " theta21[`i'+1,1] "   " sqrt(vtheta21[`i'+1,`i'+1])
	 local ip1 = `i'+1
	 forvalues j = `ip1'/`p' {
	  qui corr zz`i' zz`j', cov
	  mat vtheta21[`i'+1,`j'+1] = r(cov_12)
	  mat vtheta21[`j'+1,`i'+1] = r(cov_12)
	 }
    }
*   Compute covariance matrix over different subsamples for different horizon LP estimation
	mat vtheta11 = J(`p'+1,`p'+1,0)
	forvalues i = 1/`p' {
	 qui su zu`i'
	 mat vtheta11[`i'+1,`i'+1] = r(Var)
	 dis `i' "   " theta11[`i'+1,1] "   " sqrt(vtheta11[`i'+1,`i'+1])
	 local ip1 = `i'+1
	 forvalues j = `ip1'/`p' {
	  qui corr zu`i' zu`j', cov
	  mat vtheta11[`i'+1,`j'+1] = r(cov_12)
	  mat vtheta11[`j'+1,`i'+1] = r(cov_12)
	 }
    }
*
	global conts `controls'
	global nlags "`lplags'"
    do EUctax_IRF_CIRF_lin_fig
}
*-------------------------------------------------------------------------------------------
*  Panel SVAR(`svalgs')
*        Cholesky, no effect from dlrgdp to rrate within year
*        Unit effect normalization. Estimation by sureg to get full SEs (note these are homosk)
*        coefficient SEs from sureg are almost same as from xtreg, vce(conventional), presumably some df difference
*        IRF SEs from parametric bootstrap
*        Handles unbalanced panel, general controls 
*        Compatible syntax with LP and DP for lags, controls, irfs, irf-VCVs
*        
*-------------------------------------------------------------------------------------------
*
if $SVAR == 1 {
   global est "SV"
   global svlags `svlags'
   local controls $controls 

    sca irfno = irfno+dirfno
    local svlags $svlags
*
*   Estimate VAR(svlags) using SUREG
    global xylags ""
    forvalues i = 1/`svlags' {
	 global xylagsi "L`i'.`DS'`x' L`i'.d`y'"
     global xylags $xylags $xylagsi
	}
    sureg (`DS'`x' = $xylags cdum* $`controls') (d`y' = L0.`DS'`x' $xylags cdum* $`controls')
    mat b98 = e(b)
    mat v98 = e(V)
	local k0 = 2*`svlags'
	local k1 = (colsof(b98)-1)/2
	local k2 = `k1'+1
	local k3 = `k1'+2*`svlags'+1
    mat bhat = b98[1,1..`k0'] , b98[1,`k2'..`k3']
    mat vhat = (v98[1..`k0',1..`k0'] , v98[1..`k0',`k2'..`k3']) \ (v98[`k2'..`k3',1..`k0'] , v98[`k2'..`k3',`k2'..`k3'])
     mat vhatc = cholesky(vhat)
    mat b = bhat
	varirf `svlags' `p' /* program to compute IRF given VAR coeffs */
	mat theta11 = theta1_var[1..rowsof(theta1_var),1]
	mat theta21 = theta1_var[1..rowsof(theta1_var),2]
    mat theta1_varhat = theta1_var
	sca theta21lrhat = theta21lr
    *mat list theta1_varhat 
*
* Parametric bootstrap for SEs
   set seed 03122020
   local nbs = 1000
   local nparms = colsof(bhat)
   forvalues ibs = 1/`nbs' {
    mat zi = J(`nparms',1,0)
    forvalues i = 1/`nparms' {
     mat zi[`i',1] = rnormal()
    }
    mat b = (bhat' + vhatc*zi)'
	varirf `svlags' `p' /* program to compute IRF given VAR coeffs */
    mat theta1_varhati = theta1_var
    if `ibs'==1 {
     mat irf_bs = theta1_var[1..`p'+1,2]
	 mat theta21lr_bs = theta21lr
    }
    else {
     mat irf_bs = irf_bs , theta1_var[1..`p'+1,2]
	 mat theta21lr_bs = theta21lr_bs , theta21lr
    }
   }
*  compute VCV matrix from the boostrap draws of the IRF
   preserve
    mat irfs = irf_bs'
    svmat irfs
    corr irfs*, cov
    mat vtheta21 = r(C)
	mat tlrs = theta21lr_bs'
	svmat tlrs
	su tlrs1
	sca vlr = r(Var)
   restore
   sca tlrvar = .
   sca plrvar = .
   if "`spec'" == "L" {
    sca tlrvar = theta21lrhat/sqrt(vlr)
    sca plrvar = chi2tail(1,tlrvar*tlrvar)
   }
*  Granger causality test (no feedback from y to x)
   mat list bhat
   mat rr = J(`svlags',colsof(bhat),0)
   forvalues i = 1/`svlags' {
    local i2 = `i'+`i'
    mat rr[`i',`i2'] = 1
   }
   mat n99 = rr*(bhat')
   mat v99 = rr*vhat*(rr')
   mat f99 = n99'*inv(v99)*n99
   sca fgc = f99[1,1]	
   sca pgc = chi2tail(`svlags',fgc)		// p-value for F stat
   sca fgc = fgc/`svlags'				// F stat for Table 3
   
   global conts "`controls'"
   global nlags "`svlags'"
   do EUctax_IRF_CIRF_lin_fig
}
*-------------------------------------------------------------------------------------------
 } //Loop y
} //Loop x
} //Loop spec
} // loop rfig

erase ctax_gdp_tmp.dta

