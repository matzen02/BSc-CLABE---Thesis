clear
* Emissions data
*  https://ec.europa.eu/eurostat/databrowser/view/sdg_13_10/default/table?lang=en
global ID_2digit AT BE BG CH CY CZ DE DK EE EL ES EU27_2020 FI FR HR HU IE IS IT LT LU LV MT NL NO PL PT SE SI SK
foreach k in 2 6 21 31 32 {
import excel using "C:\Users\matti\PycharmProjects\Formatting Document\env_air_gge__custom_11832001_spreadsheet_corretto.xlsx", sheet(Sheet `k') cellrange(A10:AF49) firstrow clear  // CO2 from fuel combustion
drop RO
rename GEO year
destring year, replace 
 foreach i in $ID_2digit {
    if "`i'" != "HU"{
		replace `i' = "" if `i' == ":"
		destring `i',replace 
     }
	}
gather $ID_2digit, variable(ID_2digit) value(emission`k') 
tempfile emission`k'
save "`emission`k''", replace
}
	
use "`emission2'"
merge 1:1 ID_2digit year using  "`emission6'"
drop _merge
merge 1:1 ID_2digit year using  "`emission21'"
drop _merge
merge 1:1 ID_2digit year using  "`emission31'"
drop _merge
merge 1:1 ID_2digit year using  "`emission32'"
drop _merge
preserve
use names,clear
keep if ID_2digit!=""
tempfile names
save "`names'", replace 
restore
merge m:1 ID_2digit using "`names'" 
drop if _merge!=3 //LIE's emissions are missing
drop _merge 

label var year "year"
label var ID_2digit "2-digit country ID"
gen emission_ctsectors=emission21+emission31+emission32
label var emission_ctsectors "CO2 from fuel combustion in road transport, commercial, institutional, household sectors"

drop emission2 emission6 emission21 emission31 emission32

destring year, replace

save emission_2018,replace
