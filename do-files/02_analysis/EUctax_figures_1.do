
*********************************************
*  EUctax_figures_1.do          
*     This file creates figures 1, 2, A1, A2, and A3
*		Note: Figures A1 - A3 are in the online appendix
*
*********************************************/
*read in data
use "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Raw data\Analysis\ctax_AEJM_mio.dta", clear
*
***** create variables to be used in regressions ***** 
* set panel
cap drop cnum
egen cnum = group(ID)
xtset cnum year
*
global figpath "figs"

************************************************************
* Data set restriction to EU
************************************************************
keep if (year>=1985)*(year<=2023) 
* ----- EU+ sample --------
keep if EU2
drop if ID=="LIE"
global smple "EU+"
*
local smple "$smple"
tab year, gen(ydum)
tab ID, gen(cdum) 
local nc = r(r)
cap drop cnum
egen cnum = group(ID)
gen obsno = _n
*
************************************************************
* Data values in 2018
************************************************************
format rater_LCU_USD18 %9.2f
format share19 %9.2f
*
************************************************************
* Carbon tax rate plot and event study plot
************************************************************
*
sort cnum year
xtset cnum year
*
global dlrgdp_lab "Real GDP, growth (annual %)"
global dlemptot_lab "Total employment, growth (annual %)"
global dlempman_lab "Employment in manufacturing, growth (annual %)"
global dlemission_ctsectors_lab "CO2 emissions from road transport, household, and commercial sectors (growth, annual %)"
*
gen rrate = rater_LCU_USD18
replace lemission_ctsectors=. if (year<1990)

local j = 0
foreach y of varlist dlrgdp dlemptot dlempman lemission_ctsectors  {
 local j = `j'+1
 local ylab "$`y'_lab"

 preserve
 keep if ctaxever==1
 keep ID year rrate ctaxever ctaxyear `y' 
 tab ID
 local nc = r(r)
 egen cnum = group(ID)
 gen eventdate = _n-7
 replace rrate = . if rrate==0
 reshape wide ID rrate ctaxever ctaxyear `y' eventdate, i(year) j(cnum)

 forvalues i = 1/`nc' {
   local shft = ctaxyear`i'[1]-year[1]-6
   qui gen `y'_shft`i' = `y'`i'[_n+`shft']
   qui su `y'_shft`i' in 2/6
   qui replace `y'_shft`i' = `y'_shft`i' - r(mean)
   
   local id99 = ID`i'[1]
   label var rrate`i' `id99'
   label var `y'_shft`i' `id99'
   }
 gen mnd = 0
 gen ssd = 0
 gen nd = 0
 forvalues s = 1/13 {
  forvalues i = 1/`nc' {
   if `y'_shft`i'[`s']~=. {
    qui replace mnd = mnd + `y'_shft`i' in `s'/`s'
    qui replace ssd = ssd + `y'_shft`i'*`y'_shft`i' in `s'/`s'
	qui replace nd = nd + 1 in `s'/`s'
   }
  }
 }
 replace mnd = mnd/nd
 gen vard = ssd/nd - mnd^2
 gen sed = sqrt(vard/nd)
 gen ci05 = mnd - 1.645*sed
 gen ci95 = mnd + 1.645*sed
 gen mn0 = (mnd[2]*nd[2]+mnd[3]*nd[3]+mnd[4]*nd[4]+mnd[5]*nd[5]+mnd[6]*nd[6])/(nd[2]+nd[3]+nd[4]+nd[5]+nd[6])
  qui replace mn0 = . in 8/l
 gen mn1 = (mnd[8]*nd[8]+mnd[9]*nd[9]+mnd[10]*nd[10]+mnd[11]*nd[11]+mnd[12]*nd[12])/(nd[8]+nd[9]+nd[10]+nd[11]+nd[12])
  qui replace mn1 = . in 1/6
/*
  +-----------------------------------------------------------------------------------------------+
  | ID1   ID2   ID3   ID4   ID5   ID6   ID7   ID8   ID9   ID10   ID11   ID12   ID13   ID14   ID15 |
  |-----------------------------------------------------------------------------------------------|
  | CHE   DNK   ESP   EST   FIN   FRA   GBR   IRL   ISL    LVA    NOR    POL    PRT    SVN    SWE |
  +-----------------------------------------------------------------------------------------------+
*/
*
************************************************************************************
*	Figure 1 - Real Carbon Tax Rates Over Time
************************************************************************************
if `j'==1 {
*
*  Figure 1a
*
 tsline rrate2 rrate5 rrate9 rrate11 rrate15 if tin(1990,2023), legend(cols(4)) tlabel(1990(5)2025) ///
     title(Real carbon tax rates) note("Real rate in local currency, normalized to 2022 USD") ///
	 legend(rows(1)) lp(l _ - l _ - l _ - l _ -)  
	 
	 graph export "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Figures\Fig_1a.$figtype", replace
 *
 *  Figure 1b
 *
 tsline rrate4 rrate5 rrate10 rrate12  if tin(1990,2023), legend(cols(4)) tlabel(1990(5)2025) ///
     title(Real carbon tax rates) note("Real rate in local currency, normalized to 2018 USD") ///
	 legend(rows(1)) lp(l _ - l _ - l _ - l _ -)
	 
	 graph export "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Figures\Fig_1b.$figtype", replace	 
 *
 *  Figure 1c
 *
 tsline rrate1 rrate3 rrate6 rrate7 rrate13 if tin(1990,2023), legend(cols(4)) tlabel(1990(5)2025) ///
     title(Real carbon tax rates) note("Real rate in local currency, normalized to 2018 USD") ///
	 legend(rows(1)) lp(l _ - l _ - l _ - l _ -)
	 
	 graph export "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Figures\Fig_1c.$figtype", replace

}
**********************************************************************
*	Figure 2 - GDP growth rate event study
*	Figure A1 - Total employment growth rate event study
*	Figure A2 - Manufacturing employment growth rate event study
*	Figure A3 - Emissions event study
********************************************************************** 
if `j'==1 {
	local figtitle "2"
}
else if `j'==2 {
	local figtitle "A1"
}
else if `j'==3 {
	local figtitle "A2"
}
else local figtitle "A3"
  twoway (line mn0 mn1 `y'_shft* eventdate1 in 2/12, lc(black = gs10 ..) lw(medthick = medium ..)) ///
       (rcapsym ci05 ci95 eventdate1 in 2/12, vertical m(X) mc(cranberry) lc(cranberry)) ///
	   (scatter mnd eventdate1 in 2/12, m(O) mc(cranberry) xline(0, lc(black) lp(_))), ///
	    title("`ylab'") subtitle("Before and after imposition of carbon tax") ///
		note("Deviated from country's pre-tax mean. Horizontal lines are pre/post means." "Dots and bars denote mean and 90% confidence interval by year.") ///
	    xtitle("Year from first imposition of carbon tax") xlabel(-5(1)5) legend(off) 
   graph export "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\Figures/Fig_`figtitle'.$figtype", replace
restore
}
