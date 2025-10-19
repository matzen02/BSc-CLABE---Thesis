/*******************************************************************************
* File Name: CreateTables
* 
* Principal investigators: James Stock and Gilbert Metcalf
* Compiled by: Gib Metcalf 
*
* Last revised: Feb 25, 2022
*
* Description: Constructs tables for the Metcalf Stock AEJ:M paper
*
*  All tables are stored in folder out
********************************************************************************/

clear all
pause on
*** SET DIRECTORY HERE:
cd "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Raw data\Analysis" //for windows
*
capture log using CreateTables.log, replace 
****************************************************************************************
*	Table 1 
****************************************************************************************
use ctax_AEJM_mio, clear
list ID ctaxyear rater* IntRevRec share19 if year==2022 & ctaxever
*	for 2018 revenue, download data from WB Carbon Pricing Dashboard at
*	 https://carbonpricingdashboard.worldbank.org
*
***************************************************************************************
*	Table 2 & 3
*		Table 2 starts in column A
*		Table 3 strats in column H
***************************************************************************************
putexcel set "Tables.xlsx", replace
putexcel A1 = "Table 2"
putexcel A4 = "Full Sample"
putexcel A5 = "LP"
putexcel A7 = "SVAR"
putexcel A9 = "Revenue Recycling Countries"
putexcel A10 = "LP"
putexcel A12 = "SVAR"
putexcel A14 = "Large Carbon Tax Countries"
putexcel A15 = "LP"
putexcel A17 = "SVAR"
putexcel A19 = "Scandinavian Countries"
putexcel A20 = "LP"
putexcel A22 = "SVAR"
putexcel B3 = "GDP"
putexcel C3 = "GDP per capita"
putexcel D3 = "Total Employment"
putexcel E3 = "Manufacturing Employment"
putexcel F3 = "Emissions"
*
putexcel H1 = "Table 3"
putexcel H4 = "Full Sample"
putexcel H7 = "SVAR"
putexcel H9 = "Revenue Recycling Countries"
putexcel H12 = "SVAR"
putexcel H14 = "Large Carbon Tax Countries"
putexcel H17 = "SVAR"
putexcel H19 = "Scandinavian Countries"
putexcel H22 = "SVAR"
putexcel I3 = "GDP"
putexcel J3 = "GDP per capita"
putexcel K3 = "Total Employment"
putexcel L3 = "Manufacturing Employment"
putexcel M3 = "Emissions"
global none ""
global YE "i.year"
global IrfCirf = "IRF"
global xvars "rater_LCU_USD18sw" 

* ----- Set main run parameters ----------------
global p = 8       // number of horizons (years), also number of lags in DL specifications
global pplot = 6   // number of horizons for IRF plot
global lplags = 4  // number of lags in LP specifications, also number of lags of controls in all specifications (0,...,lplags-1)
global svlags = 4  // number of lags in SVAR specifications
local p $p
global dllags `p'
local lplags $lplags
local svlags $svlags

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

keep if tin(1985,2018)
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

/*******************************************************************************************
*	Number crunching follows for Tables 2 & 3; Note - code is the same used for creating figures
*	Loop first on $yvars and then on $smpl.  For each iteration (20 in all), first do the LP
*	and then do the SVAR.  
*		rn  - row number for test statistic
*		cl  -  column letter for Table 2
*		cl3 - column letter for Table 3
*/
******************************************************************************************	
global yvars "lrgdp"  "lrgdppc" "lemptot" "lempman" "lemission_ctsectors" 
global smpl  "EU+" "EU+RR1" "CT10sw" "SCA"
global speclist "L" "D"
*
*	Iterating over dependent variables (columns of table)
*
foreach y in "$yvars"  {
  local rn = 5
  global y "`y'"
  if "`y'" == "lrgdp" {
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global controls "YE" 
  global cl "B"
  global cl3 "I"
 }
* 
if "`y'" == "lrgdppc" {
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global controls "YE" 
  global cl "C"
  global cl3 "J"
}
*
if "`y'" == "lemptot" {
  global cvarsLP "L(1/`lplags').dlrgdp L(1/`lplags').dlpgdp L(1/`lplags').dlempman"
  global controls "YE" 
  global cl "D"
  global cl3 "K"
}

if "`y'" == "lempman" {
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlrgdp"
  global controls "YE" 
  global cl "E"
  global cl3 "L"
}

if "`y'" == "lemission_ctsectors" {
  global cvarsLP "L(1/`lplags').dlemptot L(1/`lplags').dlpgdp L(1/`lplags').dlempman L(1/`lplags').dlrgdp"
  global controls "YE" 
  global cl "F"
  global cl3 "M"
}
*
*	Iterating over sub-samples (rows of table)
*
 foreach smp in "$smpl"  {
 	global smple "`smp'"
	use ctax_gdp_tmp, clear
	if "`smp'" == "EU+"  {
		keep if EU2
		drop if ID=="LIE"
	}
	if "`smp'" == "EU+RR1"	 {
		keep if EU2
		drop if ID=="LIE"
		keep if (ctaxever==0) | (IntRevRec>=0.5)
	}
	if "`smp'" == "CT10sw"	{
		keep if ctaxever
		cap drop x99
		egen x99 = max(rater_LCU_USD18sw), by(ID)
		gen CT10sw = (x99>=10)
		keep if CT10sw
	}
	if "`smp'" == "SCA"		{
		keep if SCA
	}
	
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
local DS = ""
mat xpath0 = J(`pp1',1,1) // real carbon tax path

local x "$xvars"
if strmatch("`x'","*sw") sca swfac = 0.3
sca rateinit = 40
mat xpath = rateinit*xpath0 
global xsheet "`x'"

*
*	main code here: do LP and write T.2; do SVAR and write T.2 and T.3
*	
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
 *   global est "LP"
   mat theta11 = J(`pp1',1,1)
   sca fgc = .
   sca pgc = .
   local controls $controls 
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
*	code taken from lin_tabfig
*
mat B = I(`p'+1)
forvalues h = 1/`p' {
 forvalues i = 1/`h' {
  mat B[`h'+1,`i'] = theta11[`h'-`i'+2,1]'
 }
}
mat Binv = inv(B)
mat epsx = Binv*xpath*swfac
* (ii) compute IRF and its covariance matrix wrt the x shocks
mat shockmat = I(`pp1')
forvalues i = 1/`pp1' {
 forvalues j = `i'/`pp1' {
  mat shockmat[`i',`j'] = epsx[`j'-`i'+1,1]
 }
}
mat irf = shockmat'*theta21
mat virf = shockmat'*vtheta21*shockmat
sca tlr = irf[rowsof(irf),1]/sqrt(virf[rowsof(irf),rowsof(irf)])    // t statistic for Table 2, LP 
sca plr = chi2tail(1,tlr*tlr)     									// p-value 
qui putexcel $cl`rn' = tlr,  nformat(###.00)
local rn = `rn'+1
qui putexcel $cl`rn' = plr,  nformat(###.00)
local rn = `rn'+1
*														
*
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
   global est "SV"
   global svlags `svlags'
   local controls $controls 

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
   if "`spec'" == "L" {								// report SVAR test statistic for Table 2 
    sca tlrvar = theta21lrhat/sqrt(vlr)				// this is the t value we report for SVAR in Table 2
    sca plrvar = chi2tail(1,tlrvar*tlrvar)			// this is the pvalue we report for SVAR in Table 2
    qui putexcel $cl`rn' = tlrvar,  nformat(###.00)
	local rn = `rn' + 1
    qui putexcel $cl`rn' = plrvar,  nformat(###.00)
	local rn = `rn' - 1
	}
*  Table 3 Granger causality test (no feedback from y to x)
if "`spec'" == "D"   {
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
   sca pgc = chi2tail(`svlags',fgc)					// p-value for F stat
   sca fgc = fgc/`svlags'							// F stat for Table 3
   qui putexcel $cl3`rn' = fgc,  nformat(###.00)
   local rn = `rn' + 1
   qui putexcel $cl3`rn' = pgc,  nformat(###.00)
}   // spec D
}  // spec
local rn = `rn'+2  
 }  // smp 
}   // yvars 
putexcel save
erase ctax_gdp_tmp.dta
log close
