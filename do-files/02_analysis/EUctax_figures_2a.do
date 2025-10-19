********************************************
*  EUctax_figures_2a.do           JS 10/10/21
*    Figure A4: Own-IRF for ctax with SE plot
*********************************************
local frun "lrgdp_rater_LCU_USD18sw_LP_D_V5_YE_EU+"
use data\\`frun'_shockmat, clear
desc
tsset h

gen shockcum = shockmat9
 replace shockcum = shockcum[_n-1] + shockmat9[_n] in 2/l
gen theta11cum = theta11
 replace theta11cum = theta11cum[_n-1] + theta11[_n] in 2/l
gen theta21cum = theta21
 replace theta21cum = theta21cum[_n-1] + theta21[_n] in 2/l

*tsline theta11 theta11cum
mkmat vtheta11*, mat(vtheta11)
mat scum = J(9,9,0)
forvalues i = 1/9 {
	forvalues j = `i'/9 {
		mat scum[`i',`j'] = 1
	}
}
mat vtheta11cum = scum'*vtheta11*scum

gen vtheta11 = 0
gen vtheta11cum = 0
forvalues i = 1/9 {
	replace vtheta11 = vtheta11[`i',`i'] in `i'/`i'
	replace vtheta11cum = vtheta11cum[`i',`i'] in `i'/`i'
}
gen seea = sqrt(vtheta11)
gen bbba = theta11
gen seeb = sqrt(vtheta11cum)
gen bbbb = theta11cum
gen lagno = h
gen zero = 0
gen one = 1

foreach s in "a" "b" {
 qui gen cil95`s' = bbb`s' - 1.96*see`s'
 qui gen cil67`s' = bbb`s' - see`s'
 qui gen ciu67`s' = bbb`s' + see`s'
 qui gen ciu95`s' = bbb`s' + 1.96*see`s'
}

twoway  (rarea cil67a ciu67a lagno, fcolor(red%60) lcolor(white)) ///
        (rarea cil95a ciu95a lagno, fcolor(red%30) lcolor(white)) ///
        (line bbba zero lagno, lc(cranberry black)) ///
        (rarea cil67b ciu67b lagno, fcolor(ebblue%60) lcolor(white)) ///
        (rarea cil95b ciu95b lagno, fcolor(ebblue%30) lcolor(white)) ///
        (line bbbb one lagno, lc(ebblue black)), ///
		note("67% and 95% confidence bands. Includes 4 lags of all regressors.") ///
	    ytitle("$/ton") legend(off) xtitle("")

global fout "CC:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Figures\Fig_A4.$figtype"
graph export $fout, replace
erase data\\`frun'_shockmat.dta
