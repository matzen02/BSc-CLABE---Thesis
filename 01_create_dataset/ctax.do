clear
*******************************************************************************
*
*     Create carbon tax data set 01/25/20 
*		Edited, 2/12/22, G. Metcalf
*
*******************************************************************************
*
***************************** create ctax.dta **********************************
global EUctax CHE DNK ESP EST FIN FRA GBR IRL ISL LVA NOR POL PRT SVN SWE LIE

* read in the degree to which carbon tax revenues were initially intended to reduce existing tax rates
import excel using "data\raw_data\WB_CarbonTaxData.xlsx", sheet(CTaxDetails) cellrange(A2:U19) first case(l) clear 
replace country="United Kingdom" if country=="UK"
rename revenuerecyclingvariable IntRevRec
label var IntRevRec "Fraction of carbon tax revenues initially earmarked for tax reduction"
keep country IntRevRec
merge 1:1 country using data/names
drop if _merge!=3
drop _merge ID_2digit
tempfile IntRevRec
save "`IntRevRec'", replace

* create share tempfile 
import excel using "data\raw_data\WB_CarbonTaxData.xlsx",sheet(share) first clear 
gather $EUctax, variable(ID) value(share) 
label var share "share of jurisdiction's GHG emissions covered by tax"
tempfile share
save "`share'", replace

* read in carbon tax rate in local currency
import excel using "data\raw_data\WB_CarbonTaxData.xlsx",sheet(rate_LCU) cellrange(A2:Q32) first clear 
gather $EUctax, variable(ID) value(rate_CTI_LCU) 
label var rate_CTI_LCU "Carbon tax rate from WB CTI (nominal local currency)"
tempfile rate_CTI_LCU
save "`rate_CTI_LCU'", replace

* read in Dolphin's emissions-weighted carbon tax (national, US states, canadian provinces and territories)
import delimited "data\raw_data/ECP_tax_2013.csv",clear
label var ecp_ghg_tax_usd_2015 "Emissions (2013 GHG) weighted carbon tax, 2015 USD" 
drop ecp_co2_tax_usd_2015
replace country="Yemen" if country=="Yemen, Rep."
merge m:1 country using "data/names"
foreach i in $EUctax{
list country _merge if ID=="`i'" & _merge!=3
} // Dolphin didn't record tax for Liechtenstein
drop if _merge!=3
drop _merge

* merge
merge 1:1 ID year using "`share'"
drop _merge
merge 1:1 ID year using "`rate_CTI_LCU'"
drop _merge
merge m:1 ID using "`IntRevRec'"
drop _merge

*
* share of emissions covered by ctax in 2019
sort ID year
by ID: egen share19 = max(share)
replace share19 = 0 if share19 == .
 label var share19 "share GHG emissions covered by tax in 2019"
*
* save ctax data
sort ID year
label var ID "3-digit country code"
save data/ctax_CTI, replace
