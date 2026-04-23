global superpath "H:\Gerencia de Investigación Monetaria\RCV\Papers\Extension_Choques_Informacion\GJ 2025 JIE replication" 

global generalpath_shocks "${superpath}\Shocks"
global datapath_dailylps "${superpath}\Daily LPs\Data daily LPs"
global datapath_bvars "${superpath}\BVARs\Data BVARs"
global datapath_monthlylps "${superpath}\Monthly LPs\Data monthly LPs"
capture shell rmdir "${generalpath_shocks}\results" /s /q
mkdir "${generalpath_shocks}\results"
********************************************************************************


********************************************************************************
// Call Matlab and estimate shocks at daily frequency (Matlab is running as batch in the background, takes about 15mins)
cd "${generalpath_shocks}\code\"
! matlab -batch "run('main.m')" 

*run in batch to make sure Stata waits until the shocks are estimated before executing the code that follows
********************************************************************************


********************************************************************************
// Merge estimated shocks with daily financial variables
* Problema: la funcion btime no está incluida en el paquete de replicación 
* y el código no jala. Voy a intentar reemplazarla

import delimited "${generalpath_shocks}\\results\U.csv", clear 
gen day = substr(start,9,2)
gen month = substr(start,6,2)
gen year = substr(start,1,4)
destring day month year, replace
/*
gen time = mdy(month,day,year)
format time %td
keep u* time
gen weekday = dow(time)
drop if weekday==0 | weekday==7
collapse (sum) u*, by(time)

tsset time 
gen time_td = time
format time_td %td
btime, replacetvar
*/

gen time_cal = mdy(month,day,year)
format time_cal %td
keep u* time_cal
gen weekday = dow(time_cal)
drop if weekday==0 | weekday==7
collapse (sum) u*, by(time_cal)
sort time_cal
rename time_cal time_td

keep if time_td>td(31dec1990) & time_td<td(1jul2024)
rename (u1 u2 u3 u4) (cmp ofg lsap dfg)
merge 1:1 time_td using "${datapath_dailylps}\Georgiadis_Jarocinski_2025_replication_dataset_daily_lps_without_shocks.dta"
drop _merge

tsset time

foreach cc in cmp ofg lsap dfg {
	replace `cc' = 0 if missing(`cc')
}
sort time
save "${datapath_dailylps}\Georgiadis_Jarocinski_2025_replication_dataset_daily_lps_with_shocks.dta", replace
********************************************************************************


********************************************************************************
// Aggregate estimated daily shocks and raw surprises to monthly frequency and merge with monthly macro-financial variables for BVARs
import delimited "${generalpath_shocks}\\results\U.csv", clear 
rename (u1 u2 u3 u4 start) (cmp ofg lsap dfg time)
replace time = substr(time,1,10)
gen date = date(time, "YMD")
format date %td
drop time
gen year = year(date) 
gen month = month(date)
collapse (sum) cmp ofg lsap dfg, by(year month)
gen time = ym(year,month)
format time %tm
keep time cmp ofg lsap dfg
sort time
merge 1:1 time using "${datapath_bvars}\Georgiadis_Jarocinski_2025_replication_dataset_bvars_without_shocks.dta"
foreach cc in cmp ofg lsap dfg {
	replace `cc' = 0 if missing(`cc')
}
drop _merge
sort time
preserve
import delimited "${generalpath_shocks}\source_data\Y.csv", clear 
rename (ed1 tfut02 tfut10 sp500fut) (surpr_ed1 surpr_tfut02 surpr_tfut10 surpr_sp500fut)
replace start = substr(start,1,10)
gen date = date(start, "YMD")
gen year = year(date) 
gen month = month(date)
gen time = ym(year,month)
format time %tm
collapse (sum) surpr_ed1 surpr_tfut02 surpr_tfut10 surpr_sp500fut, by(time)
sort time
save "${datapath_bvars}\temp.dta", replace
restore
merge 1:1 time using "${datapath_bvars}\temp.dta"
keep if _merge==3 | _merge==1
foreach cc in surpr_ed1 surpr_tfut02 surpr_tfut10 surpr_sp500fut {
	replace `cc' = 0 if missing(`cc')
}
drop _merge
sort time
order datestr, first 
order time, last
keep if time>tm(1990m12) & time<tm(2024m7)
export excel using "${datapath_bvars}\Georgiadis_Jarocinski_2025_replication_dataset_bvars_with_shocks.xlsx", firstrow(variables) replace
erase "${datapath_bvars}\temp.dta"

// Save distribution of coefficient estimates to BVAR folder 
copy "${generalpath_shocks}\\results\shock_dist.mat" "${datapath_bvars}\shock_dist.mat", replace 
********************************************************************************


********************************************************************************
// Aggregate estimated daily shocks to monthly frequency and merge with monthly macro-financial variables for monthly panel local projections
import delimited "${generalpath_shocks}\\results\U.csv", clear 
rename (u1 u2 u3 u4 start) (cmp ofg lsap dfg time)
replace time = substr(time,1,10)
gen date = date(time, "YMD")
format date %td
drop time
gen year = year(date) 
gen month = month(date)
collapse (sum) cmp ofg lsap dfg, by(year month)
gen time = ym(year,month)
format time %tm
keep time cmp ofg lsap dfg
sort time
merge 1:m time using "${datapath_monthlylps}\Georgiadis_Jarocinski_2025_replication_dataset_monthly_lps_without_shocks.dta"
foreach cc in cmp ofg lsap dfg {
	replace `cc' = 0 if missing(`cc')
}
drop _merge
keep if time>tm(1990m12) & time<tm(2024m7)
sort imfcode time
save "${datapath_monthlylps}\Georgiadis_Jarocinski_2025_replication_dataset_monthly_lps_with_shocks.dta", replace
********************************************************************************


********************************************************************************
// Delete all results associated with estimation of daily shocks
capture shell rmdir "${generalpath_shocks}\results" /s /q
********************************************************************************