clear

*******************************************************************************
*
*     Create GDP data set 01/25/20 
*  Updated 03/06/22 by Siddhi D.
*
*******************************************************************************
*

*
* create index2016 tempfile - US GDP deflator
import excel using "data\raw_data\OECD_GDP.xlsx",sheet(US gdp deflator (FRED)) case(lower) first clear 
keep year index2016 index2015
rename index2016 igdp16
rename index2015 igdp15
 label var igdp16 "US GDP deflator (2016=100)"
tempfile igdp16
save "`igdp16'", replace
*
* create OECD ppp tempfile
import excel using "data\raw_data\OECD_GDP.xlsx",sheet(OECD ppp) case(lower) first clear 
keep location time value
keep if location=="SWE"
replace location="LIE" if location=="SWE"
tempfile pppLIE
save "`pppLIE'", replace

import excel using "data\raw_data\OECD_GDP.xlsx",sheet(OECD ppp) case(lower) first clear 
keep location time value
drop if location=="LIE"
append using "`pppLIE'"
rename location ID
rename time year
rename value ppp
 label var ppp "Purchasing power parity (OECD)"
tempfile ppp
save "`ppp'", replace


* create real gdp-local currency tempfile

import excel using "data\raw_data\OECD_GDP.xlsx",sheet(GDP constant LCU) cellrange(A4:BK268) first clear
drop CountryName IndicatorName IndicatorCode
reshape long _, i(CountryCode) j(year)
rename (CountryCode year _) (ID year rgdp)
 label var rgdp "Real GDP, local currency"
tempfile rgdp
save "`rgdp'", replace

* create gdp deflator local currency tempfile
import excel using "data\raw_data\OECD_GDP.xlsx",sheet(GDP deflator) cellrange(A4:BK268) first clear
drop CountryName IndicatorName IndicatorCode
reshape long _, i(CountryCode) j(year)
rename (CountryCode year _) (location time value)

preserve
keep if location=="SWE"
replace location="LIE" if location=="SWE"
tempfile pgdpLIE
save "`pgdpLIE'", replace
restore 

drop if location=="LIE"
append using "`pgdpLIE'"
rename location ID
rename time year
rename value pgdp
 label var pgdp "GDP deflator, local currency"
tempfile pgdp
save "`pgdp'", replace
*
* create ngdp_usd (nominal GDP in current-year USD using WB PPP) tempfile
import excel using "data\raw_data\OECD_GDP.xlsx",sheet(OECD nominal gdp in USD (OECD)) case(lower) first clear 
keep location time value
rename location ID
rename time year
rename value ngdp_usd
 label var ngdp_usd "GDP, nominal USD"
tempfile ngdp_usd
save "`ngdp_usd'", replace
*
* create ngdppc_usd (nominal GDP pc in current-year USD using WB PPP) tempfile
import excel using "data\raw_data\OECD_GDP.xlsx",sheet(OECD nominal gdppc in USD(OECD)) case(lower) first clear 
keep location time value
rename location ID
rename time year
rename value ngdppc_usd
 label var ngdppc_usd "GDPPC, nominal USD"
tempfile ngdppc_usd
save "`ngdppc_usd'", replace


*
* Modified Gross National Income and CPI for Ireland
import excel using "data\raw_data\Irish Modified GNI.xlsx",sheet(data) case(lower) first clear 
keep id year cpi_irl gnim_irl
rename id ID
tempfile gnim_irl
save "`gnim_irl'", replace

* Mainland GDP for Norway
import excel using "data\raw_data\Norway_mainland_gdp.xlsx",sheet(tostata) case(lower) first clear 
gen pgdp_nor = 100*ngdp_nor/rgdp_nor
rename id ID
tempfile gdpm_nor
save "`gdpm_nor'", replace


* merge 
use "`igdp16'"
merge 1:m year using "`ppp'" 
 drop _merge
merge 1:1 ID year using "`rgdp'" 
 drop _merge
merge 1:1 ID year using "`pgdp'" 
 drop _merge
merge 1:1 ID year using "`ngdp_usd'"
 drop _merge
merge 1:1 ID year using "`ngdppc_usd'"
 drop _merge
merge 1:1 ID year using "`gnim_irl'" 
 drop _merge
merge 1:1 ID year using "`gdpm_nor'" 
 drop _merge
merge m:1 ID using "data/names" 
 drop if _merge==2
 drop _merge
*list ID year pgdp rgdp ppp if ID=="SWE"

gen pop = ngdp_usd/ngdppc_usd
 label var pop "population (millions)"
 
* Ireland: eliminate for intellectual property investment boom
*     (1) splice GDP (<=1995) and modified GNI using 1995 splice year
*     (2) replace pgdp with cpi
gen rgdp_wb = rgdp
 label var rgdp_wb "Real GDP growth, World Bank, unadjusted"
gen rgdp_x99 = rgdp
gen pgdp_x99 = pgdp
gen rgnim_irl = gnim_irl/cpi_irl
su rgdp if (ID=="IRL")*(year==1995)
 sca mrgdp95 = r(mean)
su rgnim_irl if (ID=="IRL")*(year==1995)
 sca mrgni95 = r(mean)
replace rgdp = (mrgdp95/mrgni95)*rgnim_irl if (ID=="IRL")*(year>=1995)
replace pgdp = cpi_irl if (ID=="IRL")
drop rgnim_irl gnim_irl cpi_irl rgdp_x99 pgdp_x99

* Norway: replace WB GDP with mainland GDP
replace rgdp = rgdp_nor if ID=="NOR"
replace pgdp = pgdp_nor if ID=="NOR"
drop rgdp_nor pgdp_nor ngdp_nor

* real gdp and gdppc in 2016 USD (current PPP conversion then US GDP deflator)
gen rgdp_usd = ngdp_usd/(igdp16/100)
 label var rgdp_usd "real GDP (USD)"
gen rgdppc_usd = ngdppc_usd/(igdp16/100)
 label var rgdppc_usd "real per capita GDP (2016 USD)"
* real GDP pc in real local currency
gen rgdppc = rgdp/(pop*1e6)
 label var rgdppc "Real GDP pc (real local currency)"
*list ID year  ngdp_usd ngdppc_usd rgdp_usd rgdppc_usd rgdppc pop r99 if ID=="USA"

* create OECD-wide GDP (OECD-wide GDP is in USD) (GDP is ex IRL)
cap drop x99
gen x99 = .
replace x99 = rgdp_usd if (ID=="OECD")
egen rgdp_oecd = mean(x99), by(year)
 label var rgdp_oecd "OECD-wide GDP (2016 USD)" 
replace x99 = .
 replace x99 = rgdppc_usd if (ID=="OECD")
egen rgdppc_oecd = mean(x99), by(year)
 label var rgdppc_oecd "OECD-wide GDP per capita (2016 USD)" 
drop x99
*

sort ID year
egen cnum = group(ID)
xtset cnum year
 gen dpgdp = D.pgdp
cap drop cnum*
sort ID year
save data/gdpdata, replace
*


