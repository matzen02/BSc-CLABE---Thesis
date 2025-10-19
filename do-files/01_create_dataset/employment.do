clear
*******************************************************************************
*
*     Create employment data set 01/25/20 
*
*******************************************************************************
*
global country Austria Belgium Bulgaria Switzerland Cyprus Czechia Germany Denmark EuroareaEA111999EA122001 Euroarea12countries Euroarea19countries Euroarea20countries Estonia Greece Spain EuropeanUnion15countries1 EuropeanUnion27countriesf EuropeanUnion28countries Finland France Croatia Hungary Ireland Iceland Italy Liechtenstein Lithuania Luxembourg Latvia Montenegro NorthMacedonia Malta Netherlands Norway Poland Portugal Romania Serbia Sweden Slovenia Slovakia UnitedKingdom

***** Total Employment *****
import excel using "C:\Users\matti\PycharmProjects\Formatting Document\total empl.xlsx", sheet(Sheet 1) cellrange(A10:AR60) firstrow clear
foreach i in $country {
if "`i'" != "Denmark" & "`i'" != "France" & "`i'" != "Norway" {
qui replace `i' = "" if `i' == ":" 
qui destring `i', replace
}
}
gather $country, variable(country) value(total_employment) 

tempfile total_employment
save "`total_employment'", replace



***** Manufacturing Employment *****
import excel using "C:\Users\matti\PycharmProjects\Formatting Document\total empl.xlsx", sheet(Sheet 4) cellrange(A10:AR60) firstrow clear
foreach i in $country {
if "`i'" != "Denmark" & "`i'" != "France" & "`i'" != "Norway" {
qui replace `i' = "" if `i' == ":" 
qui destring `i', replace
}
}
gather $country, variable(country) value(manufacturing_employment) 



***** merge with Total Employment dataset *****
merge 1:1 country GEO using "`total_employment'"
drop _merge

*rename countries
replace country="Czech Republic" if country=="Czechia"
replace country="Germany" if country=="Germanyuntil1990formerterri"
replace country="United Kingdom" if country=="UnitedKingdom"
replace country="Slovak Republic" if country=="Slovakia"
rename GEO year

label var total_employment "Total employment domestic concept (thousand persons)"
label var manufacturing_employment "Manufacturing employment domestic concept (thousand persons)"
label var country "Country name"

rename manufacturing_employment empman
rename total_employment emptot

destring year,replace
merge m:1 country using "names"
tab country if _merge==1
drop if _merge!=3
drop _merge
save "employment.dta",replace


