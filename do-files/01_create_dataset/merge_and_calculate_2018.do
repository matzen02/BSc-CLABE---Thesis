clear
*******************************************************************************
*
* Merge gdpdata, ctax, diesel price, and employment data and do calculations  01/25/20 
*
*******************************************************************************
*
*********************************************************
* merge gdpdata, ctax, energy price, and employment data
*********************************************************
*
use gdpdata, clear

merge 1:1 ID year using ctax_CTI
drop _merge
erase gdpdata.dta
erase ctax_CTI.dta
merge 1:1 ID year using emission_2018
drop _merge
erase emission_2018.dta
merge 1:1 ID year using employment
drop _merge
erase employment.dta
sort country year
*
drop if inlist(ID,"DEW","EA19","EU28","OECDE","OEU")
drop if country==""
order country ID year
sort ID year
drop ID_2digit 
desc
*
*********************************************************
*  Work on merged data set
*********************************************************
*
* extend share of emissions to earlier dates
cap drop x99=.
sort ID year
by ID: egen x99 = max(share19)
replace share19 = x99
replace share19 = 0 if share19==.
drop x99
*
*********************************************************
*  Create OECD- and FSU-wide growth rates: gdp, gdppc, emptot, empman
*********************************************************
*
sort ID year
egen cnum = group(ID)
xtset cnum year

foreach yy of varlist rgdp rgdppc  empman emptot  emission_ctsectors {	
 gen l`yy' = ln(`yy')
 gen dl`yy' = 100*D.l`yy'
}
label var dlrgdp   "Real GDP annual growth rate (percent)"
label var dlrgdppc "Real GDPPC annual growth rate (percent)"
label var dlemptot "Total employment annual growth rate (percent)"
label var dlempman "Manufacturing employment annual growth rate (percent)" 
label var dlemission_ctsectors "CO2 from fuel consumption in road transport, commercial and institutional sector and by households, annual growth rate (percent)" 
*
*********************************************************
*  Create ctax related variables working with merged gdp and ctax data
*********************************************************
*
replace rate_CTI_LCU = 0 if rate_CTI_LCU==.
gen ctax = (rate_CTI_LCU>0)
 label var ctax "= 1 if carbon tax in effect"
sort ID year
by ID: egen ctaxever = max(ctax)
 label var ctaxever "carbon tax in any year"

* Create deflator which is GDP deflator, adjusted for exchange rate conversion 
*   for countries switching to the Euro in-sample, normalized to 2018 = 100 
*   Also adjust nominal LCU tax rate and receipts to be in Euros at conversion rate
gen rate_LCU_adj = rate_CTI_LCU
gen x99 = .
 replace x99 = pgdp if year==2018
by ID: egen pindex = max(x99)
 replace pindex = 100*pgdp/pindex
* Estonia: EUR 1 = 15.6466 Estonian kroonid, 1/1/2011, https://ec.europa.eu/info/business-economy-euro/euro-area/euro/eu-countries-and-euro/estonia-and-euro_en
*           tax rate in Euros starting 2011, revenues always in Euros 
replace pindex = pindex*15.6466 if (ID=="EST")*(year<2011)
replace rate_LCU_adj = rate_LCU_adj/15.6466 if (ID=="EST")*(year<2011)
* Finland: 1 = 5.94573 mk, 1/1/2002, https://ec.europa.eu/info/business-economy-euro/euro-area/euro/eu-countries-and-euro/finland-and-euro_en
*     both tax rate and revenues are in Finmarks through 1999, in Euros 2000+
replace pindex = pindex*5.94573 if (ID=="FIN")*(year<2000)
replace rate_LCU_adj = rate_LCU_adj/5.94573 if (ID=="FIN")*(year<2000) /* Finland carbon tax rates denoted in Euros in 2000 and 2001 although not yet officially adopted */

* Latvia: 1 = 0.702804 Latvian lat, 1/1/2014, https://ec.europa.eu/info/business-economy-euro/euro-area/euro/eu-countries-and-euro/latvia-and-euro_en
*     both tax rate and revenues are in LVL through 2013, in Euros 2014+
replace pindex = pindex*0.702804 if (ID=="LVA")*(year<2014)
replace rate_LCU_adj = rate_LCU_adj/0.702804 if (ID=="LVA")*(year<2014)

* Slovenia: EUR 1 = SIT 239.64, 1/1/2007, https://ec.europa.eu/info/business-economy-euro/euro-area/euro/eu-countries-and-euro/slovenia-and-euro_en
*           tax rate in Euros starting 2007, revenues in Euros starting 2000
replace pindex = pindex*239.64 if (ID=="SVN")*(year<2007)
replace rate_LCU_adj =rate_LCU_adj/239.64 if (ID=="SVN")*(year<2007)
 label var pindex "LCU price index (GDP deflator, adjusted for Euro entry, 2018=100)"
 label var rate_LCU_adj "Carbon tax rate (nominal, LCU, adjusted Euro entry)"
*
* rebase US GDP deflator to 2018, create exchange rate and PPP in 2018
replace x99 = .
 replace x99 = igdp16 if year==2018
by ID: egen igdp18 = max(x99)
 replace igdp18 = 100*igdp16/igdp18
 label var igdp18 "US GDP deflator rebased to 2018"

replace x99 = .
 replace x99 = ppp if year==2018
by ID: egen ppp18 = max(x99)
 label var ppp18 "PPP in 2018"

* Real carbon tax rate, local currency, 2018 LCUs
gen rater_LCU = rate_CTI_LCU/(pindex/100)
 label var rater_LCU "Carbon tax rate (real, LCU, 2018 LCU)"

* Real carbon tax rate, 2018 USD, PPP conversion
gen rater_LCU_USD18 = rater_LCU/ppp18
 label var rater_LCU_USD18 "Carbon tax rate (real, LCU, 2018 USD @ PPP)"
 
* convert Dolphin's 2015 USD rates to 2018 USD rates
**************************
*  Drop the ecp_co2 variables in emissions 
**************************
replace x99 = .
 replace x99 = igdp15 if year==2018
by ID: egen igdp18_15 = max(x99)
 label var igdp18_15 "US GDP deflator of 2018 (base: 2015)"

replace ecp_ghg_tax_usd_2015 =0 if ecp_ghg_tax_usd_2015==.
gen ecp_ghg_tax_usd_2018 = ecp_ghg_tax_usd_2015*igdp18_15/100
label var ecp_ghg_tax_usd_2018 "Emissions (2013 GHG) weighted carbon tax, 2018 USD" 
drop ecp_ghg_tax_usd_2015
*
*
* First year of carbon tax
cap drop cnum
egen cnum = group(ID)
su cnum, d
local cnummax = r(max)
dis `cnummax'
gen ctaxyear = .
gen c99 = .
 replace c99 = ctax*year if ctax==1
forvalues i = 1/`cnummax' {
 qui su c99 if cnum==`i', d
 qui replace ctaxyear = r(min) if cnum==`i'
}
label var ctaxyear "First year of carbon tax (else missing)"
drop c99 cnum
*
*********************************************************
* Dummy variables for Europe ETS participants and other country groups
*********************************************************
gen EU = 0
 replace EU = 1 if inlist(ID,"AUT","BEL","BGR","CYP","CZE","DEU","DNK","ESP") 
 replace EU = 1 if inlist(ID,"EST","FIN","FRA","GBR","GRC","HRV","HUN","IRL") 
 replace EU = 1 if inlist(ID,"ISL","ITA","LTU","LUX","LVA","MLT","NLD","NOR")
 replace EU = 1 if inlist(ID,"POL","PRT","ROU","SVK","SVN","SWE","LIE" )

* label var EU "member of EU ETS"
gen EU2 = EU
 replace EU2 = 1 if ID=="CHE"
 label var EU2 "EU plus Iceland, Norway, Switzerland"
drop EU  

gen SCA = inlist(ID,"NOR","SWE","DNK","FIN")
 label var SCA "Norway, Sweden, Denmark, Finland"
*
sort ID year
label var year "Year"
cap drop x99
cap drop y99
keep if EU2

label var lemission_ctsectors "log(emission_ctsectors)"
label var lempman "log(manufactoring employment)"
label var lemptot "log(total employment)"
label var lrgdp "log real gdp"
label var lrgdppc "log real per capita gdp"
aorder
order country ID year
keep country ID year IntRevRec share19 emission_ctsectors ecp_ghg_tax_usd_2018 /// 
  lrgdp dlrgdp lrgdppc dlrgdppc lempman dlempman lemptot dlemptot lemission_ctsectors /// 
  dlemission_ctsectors ctaxever rater_LCU_USD18 EU2 SCA ctaxyear pgdp 
*
save analysis/ctax_AEJM,replace



