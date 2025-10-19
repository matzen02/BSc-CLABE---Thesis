*********************************************
*  EUctax_figures_3.do           
*    Nonlinear Estimation and IRFs for Appendix
*
*read in data
use "C:\Users\matti\OneDrive\Desktop\uni\thesis\0. replication file\164521-V1 (quello utile)\data\analysis\ctax_AEJM.dta", clear

************************************************************
* Create variables
************************************************************
gen ctaxno = (ctaxyear==.)
gen ctaxpre = (year<ctaxyear)*(1-ctaxno)
*
gen rater_LCU_USD18sw = rater_LCU_USD18*share19
 label var rater_LCU_USD18sw "Carbon tax rate (real, 2018 USD) wtd by coverage share"
 
keep if tin(1985,2018)
*
replace rater_LCU_USD18sw = 0 if rater_LCU_USD18sw==.
* drop the few countries (eastern Europe) with emissions data before 1990
foreach yy in  "emission_ctsectors" {
	replace `yy' = . if year<1990
	replace l`yy' = . if year<1990
}
*
save data/ctax_gdp_tmp, replace
* ----- Set main run parameters ----------------
global p = 8       // number of horizons (years), also number of lags in DL specifications
global pplot = 6   // number of horizons for IRF plot
global lplags = 4  // number of lags in LP specifications, also number of lags of controls in all specifications (0,...,lplags-1)
global speclist "L" // nonlinear specifications involve levels of tax rate or share-wtd tax rate
global controls "YE"      // set list of sets of control variables
global xvars "rater_LCU_USD18sw"  // WB tax rate, share-weighted

*************************************************************************
*	Figures to be created are listed in figlist
*************************************************************************
*
*
global figlist "A16a A16b A17a A17b A18a A18b A19a A19b A20a A20b A21a A21b A22a A22b A23a A23b A24a A24b"
foreach fig in $figlist {
global fig "`fig'"
use data/ctax_gdp_tmp, clear
keep if EU2
drop if ID=="LIE"
global smple "EU+"

************************************************************
* set panel
************************************************************
cap drop cnum
cap drop cdum
egen cnum = group(ID)
xtset cnum year
local smple "$smple"
tab year, gen(ydum)
tab ID, gen(cdum)
local nc = r(r)
*
* Figure A16
* NL-IRF for GDP growth a-$20 increase; b-$100 increase - xx 
*
if "`fig'" == "A16a" {
  local y "lrgdp" 
  global nlspec "xx" // include square of share-weighted carbon tax
sca ctx = 20
sca swfac = 0.3
cap drop xnl
gen xnl = rater_LCU_USD18sw*rater_LCU_USD18sw	
mat tfac = J(1,2,0)
mat tfac[1,1] = ctx*swfac
mat tfac[1,2] = (ctx*swfac)*(ctx*swfac)
 }
* 
if "`fig'" == "A16b" {
 local y "lrgdp" 
 global nlspec "xx" // include square of share-weighted carbon tax
 sca ctx = 100
sca swfac = 0.3
cap drop xnl
gen xnl = rater_LCU_USD18sw*rater_LCU_USD18sw	
mat tfac = J(1,2,0)
mat tfac[1,1] = ctx*swfac
mat tfac[1,2] = (ctx*swfac)*(ctx*swfac)
 }
*
* Figure A17
* NL-IRF for total employment growth a-$20 increase; b-$100 increase - xx 
*
if "`fig'" == "A17a" {
  local y "lemptot" 
  global nlspec "xx" // include square of share-weighted carbon tax
sca ctx = 20
sca swfac = 0.3
cap drop xnl
gen xnl = rater_LCU_USD18sw*rater_LCU_USD18sw	
mat tfac = J(1,2,0)
mat tfac[1,1] = ctx*swfac
mat tfac[1,2] = (ctx*swfac)*(ctx*swfac)
 }
* 
if "`fig'" == "A17b" {
 local y "lemptot" 
 global nlspec "xx" // include square of share-weighted carbon tax
 sca ctx = 100
sca swfac = 0.3
cap drop xnl
gen xnl = rater_LCU_USD18sw*rater_LCU_USD18sw	
mat tfac = J(1,2,0)
mat tfac[1,1] = ctx*swfac
mat tfac[1,2] = (ctx*swfac)*(ctx*swfac)
 }
*
* Figure A18
* NL-IRF for emissions growth a-$20 increase; b-$100 increase - xx 
*
if "`fig'" == "A18a" {
  local y "lemission_ctsectors" 
  global nlspec "xx" // include square of share-weighted carbon tax
sca ctx = 20
sca swfac = 0.3
cap drop xnl
gen xnl = rater_LCU_USD18sw*rater_LCU_USD18sw	
mat tfac = J(1,2,0)
mat tfac[1,1] = ctx*swfac
mat tfac[1,2] = (ctx*swfac)*(ctx*swfac)
 }
* 
if "`fig'" == "A18b" {
 local y "lemission_ctsectors" 
 global nlspec "xx" // include square of share-weighted carbon tax
 sca ctx = 100
sca swfac = 0.3
cap drop xnl
gen xnl = rater_LCU_USD18sw*rater_LCU_USD18sw	
mat tfac = J(1,2,0)
mat tfac[1,1] = ctx*swfac
mat tfac[1,2] = (ctx*swfac)*(ctx*swfac)
 }
*
* Figure A19
* NL-IRF for GDP growth a-10% coverage; b-50% coverage - xs 
*
if "`fig'" == "A19a" {
  local y "lrgdp" 
  global nlspec "xs" // include interaction: share^2 x carbon tax
sca shtx = .1
cap drop xnl
gen xnl = rater_LCU_USD18sw*share19	
mat tfac = J(1,2,0)
mat tfac[1,1] = 40*0.1
mat tfac[1,2] = (40*0.1)*(0.1)
 }
* 
if "`fig'" == "A19b" {
 local y "lrgdp" 
 global nlspec "xs" // include interaction: share^2 x carbon tax
sca shtx = .5
cap drop xnl
gen xnl = rater_LCU_USD18sw*share19	
mat tfac = J(1,2,0)
mat tfac[1,1] = 40*0.5
mat tfac[1,2] = (40*0.5)*(0.5)
} 
*
* Figure A20
* NL-IRF for total employment growth a-10% coverage; b-50% coverage - xs 
*
if "`fig'" == "A20a" {
  local y "lemptot" 
  global nlspec "xs" // include interaction: share^2 x carbon tax
sca shtx = .1
cap drop xnl
gen xnl = rater_LCU_USD18sw*share19	
mat tfac = J(1,2,0)
mat tfac[1,1] = 40*0.1
mat tfac[1,2] = (40*0.1)*(0.1)
 }
* 
if "`fig'" == "A20b" {
 local y "lemptot" 
 global nlspec "xs" // include interaction: share^2 x carbon tax
sca shtx = .5
cap drop xnl
gen xnl = rater_LCU_USD18sw*share19	
mat tfac = J(1,2,0)
mat tfac[1,1] = 40*0.5
mat tfac[1,2] = (40*0.5)*(0.5)
}
*
* Figure A21
* NL-IRF for emissions growth a-10% coverage; b-50% coverage - xs 
*
if "`fig'" == "A21a" {
  local y "lemission_ctsectors" 
  global nlspec "xs" // include interaction: share^2 x carbon tax
sca shtx = .1
cap drop xnl
gen xnl = rater_LCU_USD18sw*share19	
mat tfac = J(1,2,0)
mat tfac[1,1] = 40*0.1
mat tfac[1,2] = (40*0.1)*(0.1)
 }
* 
if "`fig'" == "A21b" {
 local y "lemission_ctsectors" 
 global nlspec "xs" // include interaction: share^2 x carbon tax
sca shtx = .5
cap drop xnl
gen xnl = rater_LCU_USD18sw*share19	
mat tfac = J(1,2,0)
mat tfac[1,1] = 40*0.5
mat tfac[1,2] = (40*0.5)*(0.5)
}
*
* Figure A22
* NL-IRF for gdp growth a-10pct; b-90 pct coverage - xg 
*
if "`fig'" == "A22a" {
  local y "lrgdp" 
  global nlspec "xg" // include interaction: carbon tax x lagged real GDP growth
  mat tfac = J(1,2,0)
  cap drop xnl
  	gen xnl = rater_LCU_USD18sw*L.dlrgdp
	mat tfac[1,1] = [40, 40*(-.5403519)]
 }
* 
if "`fig'" == "A22b" {
 local y "lrgdp" 
 global nlspec "xg" // include interaction: carbon tax x lagged real GDP growth
 mat tfac = J(1,2,0)
 cap drop xnl
  	gen xnl = rater_LCU_USD18sw*L.dlrgdp
 mat tfac[1,1] = [40, 40*5.091095]
}
*
* Figure A23
* NL-IRF for total employment growth a-10pct; b-90 pct coverage - xg 
*
if "`fig'" == "A23a" {
  local y "lemptot" 
  global nlspec "xg" // include interaction: carbon tax x lagged real GDP growth
  mat tfac = J(1,2,0)
  cap drop xnl
  	gen xnl = rater_LCU_USD18sw*L.dlrgdp
	mat tfac[1,1] = [40, 40*(-.5403519)]
 }
* 
if "`fig'" == "A23b" {
 local y "lemptot" 
 global nlspec "xg" // include interaction: carbon tax x lagged real GDP growth
 mat tfac = J(1,2,0)
 cap drop xnl
  	gen xnl = rater_LCU_USD18sw*L.dlrgdp
 mat tfac[1,1] = [40, 40*5.091095]
}
*
* Figure A24
* NL-IRF for emissions growth a-10pct; b-90 pct coverage - xg 
*
if "`fig'" == "A24a" {
  local y "lemission_ctsectors" 
  global nlspec "xg" // include interaction: carbon tax x lagged real GDP growth
  mat tfac = J(1,2,0)
  cap drop xnl
  	gen xnl = rater_LCU_USD18sw*L.dlrgdp
	mat tfac[1,1] = [40, 40*(-.5403519)]
 }
* 
if "`fig'" == "A24b" {
 local y "lemission_ctsectors" 
 global nlspec "xg" // include interaction: carbon tax x lagged real GDP growth
 mat tfac = J(1,2,0)
 cap drop xnl
  	gen xnl = rater_LCU_USD18sw*L.dlrgdp
 mat tfac[1,1] = [40, 40*5.091095]
}
************************************************************
* IRFs
*    Frameworks: DL, LP, panel VAR 
*    X vbles: real rate equal-wtd (rrate) and share19-wtd (rratesw)
*    Various controls
************************************************************
local p $p
global dllags `p'
local lplags $lplags
local lplagsm1 = `lplags'-1
local pm2 = `p'-2
local pm1 = `p'-1
local pp1 = `p'+1
global none ""
global YE "i.year"
cap drop lagno
gen lagno = _n-1
label var lagno "Lag"

 global spec "L"
 local DS = ""
 mat xpath0 = J(`pp1',1,1) // real carbon tax path
 
  cap erase "out\irfs_`y'_`smple'_`spec'_6.xlsx"
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
 *    1. HAC SEs not needed, these are HR (Montiel Olea- Plagborg Moller (2019))
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
   global est "LP"
   mat theta11 = J(`pp1',1,1)
   mat irf_lin = J(`pp1',5,0)
   mat irfse_lin = J(`pp1',5,0)
   mat irf_nl = J(`pp1',5,0)
   mat irfse_nl = J(`pp1',5,0)
   sca fgc = .
   sca pgc = .
   foreach controls in $controls {
    sca irfno = irfno+dirfno
    mat theta21 = J(`pp1',2,0)
    cap drop e99*
    forvalues h = 0/`p' {
     local hp1 = `h'+1
      reg F`h'.d`y' `x' L(1/`lplags').`x' L(1/`lplags').d`y' $`controls' cdum*, r // linear benchmark
		lincom tfac[1,1]*`x'
		mat irf_lin[`hp1',1] = r(estimate)
		mat irfse_lin[`hp1',1] = r(se)
		
        reg F`h'.d`y' `x' xnl L(1/`lplags').`x' L(1/`lplags').xnl L(1/`lplags').d`y' $`controls' cdum*, r // nonlinear version
		lincom tfac[1,1]*`x' + tfac[1,2]*xnl
		mat irf_nl[`hp1',1] = r(estimate)
		mat irfse_nl[`hp1',1] = r(se)
    } // loop horizons
	global controls `controls'
	global nlags "`lplags'"
	mat list irf_lin
	mat list irf_nl
	mat irf_lin_m1 = irf_lin - irfse_lin
	mat irf_lin_p1 = irf_lin + irfse_lin
	mat irf_nl_m1 = irf_nl - irfse_nl
	mat irf_nl_p1 = irf_nl + irfse_nl
	mat irf_lin_m2 = irf_lin - 1.96*irfse_lin
	mat irf_lin_p2 = irf_lin + 1.96*irfse_lin
	mat irf_nl_m2 = irf_nl - 1.96*irfse_nl
	mat irf_nl_p2 = irf_nl + 1.96*irfse_nl
	foreach mm in "irf_lin" "irfse_lin" "irf_nl" "irfse_nl" "irf_lin_m1" "irf_lin_p1" "irf_nl_m1" "irf_nl_p1" "irf_lin_m2" "irf_lin_p2" "irf_nl_m2" "irf_nl_p2" {
		cap drop `mm'*
		svmat `mm', names(`mm')
	}
	local lab: variable label `x'
local nlspec "NL$nlspec"
		if "$nlspec" == "xx" {
			local ct = ctx
			local sh = swfac
			local tnote "Nonlinear LP: square of share-weighted carbon tax."	
		}
		if "$nlspec" == "xs" {
			local ct = 40
			local sh = shtx
			local tnote "Nonlinear LP: includes coverage share interacted with share-weighted carbon tax."
		}
		if "$nlspec" == "xg" {
			local ct = 40
			local sh = 0.3
			local tnote "Nonlinear LP: lagged GDP growth interacted with share-weighted carbon tax."
		}
	    twoway	(rarea irf_lin_m21 irf_lin_p21 lagno in 1/`pp1', fcolor(cranberry%30) lc(cranberry%10)) ///
				(rarea irf_lin_m11 irf_lin_p11 lagno in 1/`pp1', fcolor(cranberry%60) lc(cranberry%30)) ///
				(line irf_lin1 lagno in 1/`pp1', lc(cranberry)) ///
				(rarea irf_nl_m21 irf_nl_p21 lagno in 1/`pp1', fcolor(ebblue%30) lc(ebblue%10)) ///
				(rarea irf_nl_m11 irf_nl_p11 lagno in 1/`pp1', fcolor(ebblue%60) lc(ebblue%30)) ///
				(line irf_nl1 lagno in 1/`pp1', lc(ebblue)), name(ct1, replace) legend(off) ///
				note("Levels specification estimated by LP with `lplags' lags. Bands are 67% and 95% confidence bands." "`tnote'") 
		global fout "Fig_`fig'.$figtype"
		graph export $fout, replace
	}
  } // loop controls
 *
} //Loop x
erase ctax_gdp_tmp.dta

