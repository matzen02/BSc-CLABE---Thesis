* EUctax_IRF_CIRF_lin_tabfig.do   JS 11/24/19, 12/22/19, 1/3/20, 3/11/20...
*   called from EUctaxIRF_3.do
*   Writes excel spreadsheet of IRFs and SEs, creates and saves IRF plots
*   Input are coefficient-level IRFs, VCV matrix, and (for LP) X-variable IRFs for innovation
*   Outputs are IRFs for scaled carbon tax, and also CIRFs
*   Linear specifications only (so drops nonlinear parts of computation)
*
quietly
local figtype "pdf"
local y "$y"
local x "$x"
local est "$est"
 if "$est"=="SV" {
  local est "$est$svlags"
 }
local fig "$fig" 
local spec "$spec"
local nvar "V${nvar}"
local conts ${conts}
local smple "$smple"
local nlags $nlags
local p $p
local pplot $pplot
*local irftype "$irftype"
local pp1 = `p'+1
local rnse = 10 + `p' + 2
local rnsem1 = `rnse'-1
local rnf = `rnse' + `p' + 2
local rnfp1 = `rnf' + 1
local rnfp2 = `rnfp1' + 1
local rnfp3 = `rnfp2' + 1
*
* --------- Compute IRF wrt scaled shock and its VCV ------------
* Note: this works for all versions (DL, LP, SVAR) when the IRF is the effect of a 
*       one-time unit increase in x on a growth rate (growth of GDP) h periods hence
*       Method is to use the IRF of the rate wrt a rate shock to compute the rate shocks necessary
*       to yield a given carbon tax path (path of x), the "Sims" method. For DL this is trivial
*       and these calculations produce the one-time step up in X, with the shock being the initial deltax.
dis "++++++++++++++++++  $est  ++++++++++++++++++++"
mat list theta11
mat list theta21
* (i) compute the shocks to x that deliver the desired x path 
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
* save CT shocks and IRFs if details flag is on
if $keepdetails == 1 {
     preserve
		svmat shockmat
		keep if shockmat1 ~= .
		keep shockmat*
		gen obsno99 = -_n
		sort obsno99
		svmat theta11
		 rename theta111 theta11
		svmat theta21
		 rename theta211 theta21
		svmat vtheta11
		svmat vtheta21
		gen h = _n-1
		keep h shock* theta* vtheta*
		global fout8 "`y'_`x'_`est'_`spec'_`nvar'_`conts'_`smple'_shockmat.dta"
		save $fout8, replace
	restore
}

mat irf = shockmat'*theta21
mat virf = shockmat'*vtheta21*shockmat
*
* --------- Test of IRF = 0 ------------
 mat mf99 = irf'*inv(virf)*irf
 sca f99 = mf99[1,1]/`pp1'
 sca p99 = chi2tail(`pp1',`pp1'*f99)
* ----------- Compute CIRF and its VCV ----------------
mat mcum = I(`pp1')
forvalues i = 1/`pp1' {
 forvalues j = `i'/`pp1' {
  mat mcum[`i',`j'] = 1
 }
}
mat cirf = mcum'*irf
mat vcirf = mcum'*virf*mcum
mat seirf = vecdiag(cholesky(diag(vecdiag(virf))))'
mat secirf = vecdiag(cholesky(diag(vecdiag(vcirf))))'
*
cap drop lagno zero
gen lagno = _n-1
 label var lagno "Years after implementation"
gen zero = 0
*
local asciino = 65+2*(irfno-1) 
*
*   collect information and plot IRF or CIRF
*
foreach irftype in $IrfCirf {
 local asciino = `asciino' + 1
 if `asciino' <= 90 {
  local cn = char(`asciino')
 }
 else {
  local cn = "A"+char(`asciino'-26)
 }
 if "`irftype'" == "IRF" {
  mat bbb = irf
  mat see = seirf
  sca tlr = irf[rowsof(irf),1]/sqrt(virf[rowsof(irf),rowsof(irf)])    // t statistic for Table 2
 }
 else {
  mat bbb = cirf
  mat see = secirf
  sca tlr = cirf[rowsof(cirf),1]/sqrt(vcirf[rowsof(cirf),rowsof(cirf)])
 } 
 sca plr = chi2tail(1,tlr*tlr)     // p-value for Table 2
*
* plot IRF
 cap drop bb* se* ci*
 svmat bbb
 svmat see
 qui gen cil95 = bbb1 - 1.96*see1
 qui gen cil67 = bbb1 - see1
 qui gen ciu67 = bbb1 + see1
 qui gen ciu95 = bbb1 + 1.96*see1
 local fsw = "Equal-weighted."
  if strmatch("`x'","*sw") local fsw = "Share-weighted"
 local lab: variable label `x'
 local pplotp1 = `pplot'+1
 local irf_range = 4
 local dirf_range = 1
 if ("$y"=="lemitot")+("$y"=="lemih") + ("$y"=="lemission2")+("$y" == "lemission2pc") + ///
    ("$y"=="lemission6")+("$y"=="lemission6pc") + ///
	("$y"=="lemission_ctsectors")+("$y"=="lemission_ctsectorspc") {
  local irf_range = 10
  local dirf_range = 2.5
 } 
 if "`irftype'" == "IRF" {
  twoway (rarea cil67 ciu67 lagno in 1/`pplotp1', fcolor(red%60) lcolor(white)) ///
        (rarea cil95 ciu95 lagno in 1/`pplotp1', fcolor(red%30) lcolor(white)) ///
        (line bbb1 zero lagno in 1/`pplotp1', lc(cranberry black)), ///
	note("67% and 95% confidence bands. Includes `nlags' lags of all regressors.") ///
	ytitle("Percentage points") legend(off) xlabel(0(1)`pplot') ///
    yscale(range(-`irf_range'/`irf_range')) ylabel(-`irf_range'(`dirf_range')`irf_range') name("`irftype'_`est'_`spec'_`nvar'", replace)
 }
 else {
  local irf_range = 2*`irf_range'
  local dirf_range = 2*`dirf_range'
  twoway (rarea cil67 ciu67 lagno in 1/`pplotp1', fcolor(red%60) lcolor(white)) ///
        (rarea cil95 ciu95 lagno in 1/`pplotp1', fcolor(red%30) lcolor(white)) ///
        (line bbb1 zero lagno in 1/`pplotp1', lc(cranberry black)), ///
	note("67% and 95% confidence bands. Includes `nlags' lags of all regressors.") ///
	ytitle("Percentage points") legend(off) xlabel(0(1)`pplot') ///
    yscale(range(-`irf_range'/`irf_range')) ylabel(-`irf_range'(`dirf_range')`irf_range') name("`irftype'_`est'_`spec'_`nvar'", replace)
 }
 global fout "Fig_`fig'.$figtype"
 graph export $fout, replace
*
} //Loop irftype
noisily
