


preserve
clear
set obs ${lp_hor}
gen hor = _n
sort hor
save "$irfspathname_dailylps\lp_irfs_${savename}.dta", replace
restore
foreach depvar_curr of global lp_depvar	{
	
	forvalues h=0(1)$lp_hor	{	

		preserve
		foreach shockvar_curr of global lp_shock	{
						
			quietly newey f`h'.`depvar_curr' l(1/${lp_ownlag}).`depvar_curr' l(1/${lp_controlslag}).(${lp_controls}) ${contemp_controls} `shockvar_curr' if time_td>=td(${mindate}) & time_td<=td(${maxdate}), lag(5)
			gen irfj_`depvar_curr'_`shockvar_curr' = _b[`shockvar_curr']
			gen irfj_`depvar_curr'_`shockvar_curr'_u90 = _b[`shockvar_curr'] + 1.64*_se[`shockvar_curr']
			gen irfj_`depvar_curr'_`shockvar_curr'_l90 = _b[`shockvar_curr'] - 1.64*_se[`shockvar_curr']
			gen irfj_`depvar_curr'_`shockvar_curr'_u68 = _b[`shockvar_curr'] + _se[`shockvar_curr']
			gen irfj_`depvar_curr'_`shockvar_curr'_l68= _b[`shockvar_curr'] - _se[`shockvar_curr']
		}
		
		gen hor = `h'
		keep irfj* hor 
		collapse (mean) irf*, by(hor) 
		if `h'>0	{
			append using "$irfspathname_dailylps\temp_irfs.dta"
		}
		sort hor
		quietly save "$irfspathname_dailylps\temp_irfs.dta", replace
		restore
		display "Working on h=`h' for shock `shockvar_curr' on `depvar_curr'"
	}
	preserve
	use "$irfspathname_dailylps\temp_irfs.dta", clear
	* Old merge syntax problem
	*merge hor using "$irfspathname_dailylps\lp_irfs_${savename}.dta"
	merge 1:1 hor using "$irfspathname_dailylps\lp_irfs_${savename}.dta"
	drop _merge
	sort hor
	quietly save "$irfspathname_dailylps\lp_irfs_${savename}.dta", replace
	restore
}
preserve
use "$irfspathname_dailylps\lp_irfs_${savename}.dta", clear
export excel using "$irfspathname_dailylps\lp_irfs_${savename}.xlsx", firstrow(variables) replace
erase "$irfspathname_dailylps\lp_irfs_${savename}.dta"
erase "$irfspathname_dailylps\temp_irfs.dta"
restore

