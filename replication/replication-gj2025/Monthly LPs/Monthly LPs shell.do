global generalpath_monthlylps "${superpath}\Monthly LPs"
global datapath_monthlylps "${generalpath_monthlylps}\Data monthly LPs"
global figurepath_monthlylps "${generalpath_monthlylps}\Figures monthly LPs"
global irfspathname_monthlylps "${generalpath_monthlylps}\Monthly LPs IRFs estimates"
capture shell rmdir "${figurepath_monthlylps}" /s /q
mkdir "${figurepath_monthlylps}"
capture shell rmdir "${irfspathname_monthlylps}" /s /q
mkdir "${irfspathname_monthlylps}"
********************************************************************************



********************************************************************************
// Load data
use "${datapath_monthlylps}\Georgiadis_Jarocinski_2025_replication_dataset_monthly_lps_with_shocks.dta", clear



********************************************************************************
// Monthly LP specification
global lp_controls "lip_exus_pw lip_us tb_rate_1y ebp"
global lp_shock "cmp ofg lsap dfg"
global lp_depvar "lip" 
global lp_controlslag 1
global lp_ownlag 1
global lp_hor 36 
global mindate "1991m1" 
global maxdate "2024m6"
global plotmaxhor = 36
global plothorstep = 12
global tradexp_rnum = 1 // Number of alternative specifications for trade exposure index
global finexp_rnum = 6 // number of alternative specifications of financial exposure index
		
			
// Generate interactions between monetary policy shocks and trade/financial exposure indices		
foreach cc of varlist cmp ofg lsap dfg {
	replace `cc' = 0 if time==tm(2020m3) // zero out COVID outbreak
	sum `cc'
	replace `cc' = (`cc'-`r(mean)')/`r(sd)'
    gen `cc'_tradexp_bl = `cc'*tradexp_bl
    gen `cc'_finexp_bl = `cc'*finexp_bl
	forvalues dd=1(1)$finexp_rnum	{
		gen `cc'_finexp_r`dd' = `cc'*finexp_r`dd'
	}
	forvalues dd=1(1)$tradexp_rnum	{
		gen `cc'_tradexp_r`dd' = `cc'*tradexp_r`dd'
	}
} 


// Figure 12: Evolution of the cross-country distribution of financial and trade exposure
preserve	
capture shell rmdir "${superpath}\Figures paper\Figure 12" /s /q
mkdir "${superpath}\Figures paper\Figure 12"
quietly xtscc f0.lip l(1/${lp_ownlag}).lip l(1/${lp_controlslag}).(${lp_controls}) cmp ofg lsap dfg finexp_bl tradexp_bl if time>tm(1991m5), fe
keep if e(sample)
foreach cc in finexp_bl tradexp_bl	{
	bysort time: egen `cc'_mean = mean(`cc')
	bysort time: egen `cc'_plower = pctile(`cc'), p(10)
	bysort time: egen `cc'_p50 = pctile(`cc'), p(50)
	bysort time: egen `cc'_pupper = pctile(`cc'), p(90)
}
collapse (mean) *_bl *_mean *_plower *_p50 *_pupper, by(year imfcode)
levelsof imfcode, local(allcountries)
local plotline_finexp ""
local plotline_tradexp ""
foreach cc of local allcountries	{
	local plotline_finexp = "`plotline_finexp'" + " (line finexp_bl year if year>1990 & year<2025 & imfcode==`cc', lpattern(solid) lcolor(black) lwidth(vthin) legend(off))"
	local plotline_tradexp = "`plotline_tradexp'" + " (line tradexp_bl year if year>1990 & year<2025 & imfcode==`cc', lpattern(solid) lcolor(black) lwidth(vthin) legend(off))"
}
display "`plotline_finexp'"
twoway `plotline_finexp' (line finexp_bl_p50 finexp_bl_plower finexp_bl_pupper year if year>1990 & year<2025, lpattern(dash..) lcolor(red..) lwidth(medthick..) scheme(s2mono) plotregion(margin(zero)) graphregion(color(white)) legend(off) ytitle("Financial exposure (index)") xtitle("") tlabel(1991(5)2021) xscale(range(1991 2024)) scale(2) xsize(4.5) ysize(3))
graph export "${superpath}\Figures paper\Figure 12\finexp_evol_overlay.pdf", replace
twoway `plotline_tradexp' (line tradexp_bl_p50 tradexp_bl_plower tradexp_bl_pupper year if year>1990 & year<2025, lpattern(dash..) lcolor(red..) lwidth(medthick..) scheme(s2mono) plotregion(margin(zero)) graphregion(color(white)) legend(off) ytitle("Trade exposure (index)") xtitle("") tlabel(1991(5)2021) xscale(range(1991 2024)) scale(2) xsize(4.5) ysize(3))
graph export "${superpath}\Figures paper\Figure 12\tradexp_evol_overlay.pdf", replace
restore

		
// Estimation of panel LPs			
preserve
clear
set obs ${lp_hor}
gen hor = _n
sort hor
save "$irfspathname_monthlylps\lp_irfs_countries.dta", replace
save "$irfspathname_monthlylps\lp_irfs_countries_ia.dta", replace
local rrcounter = $finexp_rnum + $tradexp_rnum
forvalues dd=1(1)`rrcounter'	{	
	save "$irfspathname_monthlylps\lp_irfs_countries_ia_r`dd'.dta", replace
}
restore
gen ip_availability = .
foreach shockvar_curr of global lp_shock	{
		
	foreach depvar_curr of global lp_depvar	{
		forvalues h=0(1)$lp_hor	{	
						
			quietly xtscc f`h'.lip l(1/${lp_ownlag}).lip l(1/${lp_controlslag}).(${lp_controls}) `shockvar_curr' if time>=tm(${mindate}) & time<=tm(${maxdate}) & !missing(tradexp_bl) & !missing(finexp_bl), fe
			replace ip_availability = e(sample)	
			
			quietly xtscc f`h'.`depvar_curr' l(1/${lp_ownlag}).`depvar_curr' l(1/${lp_controlslag}).(${lp_controls}) `shockvar_curr' if time>=tm(${mindate}) & time<=tm(${maxdate}) & !missing(tradexp_bl) & !missing(finexp_bl) & ip_availability, fe
			estimates store lp`h'
			preserve
			gen irf_`depvar_curr'_`shockvar_curr' = _b[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_u90 = _b[`shockvar_curr'] + 1.64*_se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_l90 = _b[`shockvar_curr'] - 1.64*_se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_u68 = _b[`shockvar_curr'] + _se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_l68= _b[`shockvar_curr'] - _se[`shockvar_curr']
			gen hor = `h'
			keep irf* hor 
			collapse (mean) irf*, by(hor) 
			if `h'>0	{
				append using "$irfspathname_monthlylps\temp_irfs_countries.dta"
			}
			sort hor
			quietly save "$irfspathname_monthlylps\temp_irfs_countries.dta", replace
			restore
						
			local lp_shock_local = "$lp_shock"
			local rem_shocks: list lp_shock_local - shockvar_curr
			quietly xtscc f`h'.`depvar_curr' l(1/${lp_ownlag}).`depvar_curr' l(1/${lp_controlslag}).(${lp_controls}) `shockvar_curr' `shockvar_curr'_finexp_bl `shockvar_curr'_tradexp_bl `rem_shocks' tradexp_bl finexp_bl if time>=tm(${mindate}) & time<=tm(${maxdate}) & ip_availability, fe
			estimates store lp`h'
			preserve
			gen irf_`depvar_curr'_`shockvar_curr'_ia_p = _b[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_ia_u90 = _b[`shockvar_curr'] + 1.64*_se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_ia_l90 = _b[`shockvar_curr'] - 1.64*_se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_ia_u68 = _b[`shockvar_curr'] + _se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_ia_l68 = _b[`shockvar_curr'] - _se[`shockvar_curr']
			gen irf_`depvar_curr'_`shockvar_curr'_ia_fe = _b[`shockvar_curr'_finexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_u90 = _b[`shockvar_curr'_finexp_bl] + 1.64*_se[`shockvar_curr'_finexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_l90 = _b[`shockvar_curr'_finexp_bl] - 1.64*_se[`shockvar_curr'_finexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_u68 =_b[`shockvar_curr'_finexp_bl] + _se[`shockvar_curr'_finexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_l68 = _b[`shockvar_curr'_finexp_bl] - _se[`shockvar_curr'_finexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_te = _b[`shockvar_curr'_tradexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_te_u90 = _b[`shockvar_curr'_tradexp_bl] + 1.64*_se[`shockvar_curr'_tradexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_te_l90 = _b[`shockvar_curr'_tradexp_bl] - 1.64*_se[`shockvar_curr'_tradexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_te_u68 =_b[`shockvar_curr'_tradexp_bl] + _se[`shockvar_curr'_tradexp_bl]
			gen irf_`depvar_curr'_`shockvar_curr'_ia_te_l68 = _b[`shockvar_curr'_tradexp_bl] - _se[`shockvar_curr'_tradexp_bl]
			gen hor = `h'
			keep irf* hor 
			collapse (mean) irf*, by(hor) 
			if `h'>0	{
				append using "$irfspathname_monthlylps\temp_irfs_countries_ia.dta"
			}
			sort hor
			quietly save "$irfspathname_monthlylps\temp_irfs_countries_ia.dta", replace
			restore
								
			local robcounter = 0
			forvalues dd=1(1)$finexp_rnum	{
				local robcounter = `robcounter' + 1
				local lp_shock_local = "$lp_shock"
				local rem_shocks: list lp_shock_local - shockvar_curr
				quietly xtscc f`h'.`depvar_curr' l(1/${lp_ownlag}).`depvar_curr' l(1/${lp_controlslag}).(${lp_controls}) `shockvar_curr' `shockvar_curr'_finexp_r`dd' `shockvar_curr'_tradexp_bl `rem_shocks' tradexp_bl finexp_r`dd' if time>=tm(${mindate}) & time<=tm(${maxdate}) & ip_availability, fe
				estimates store lp`h'
				preserve
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_p = _b[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_u90 = _b[`shockvar_curr'] + 1.64*_se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_l90 = _b[`shockvar_curr'] - 1.64*_se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_u68 = _b[`shockvar_curr'] + _se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_l68 = _b[`shockvar_curr'] - _se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_p = _b[`shockvar_curr'_finexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_u90 = _b[`shockvar_curr'_finexp_r`dd'] + 1.64*_se[`shockvar_curr'_finexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_l90 = _b[`shockvar_curr'_finexp_r`dd'] - 1.64*_se[`shockvar_curr'_finexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_u68 =_b[`shockvar_curr'_finexp_r`dd'] + _se[`shockvar_curr'_finexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_l68 = _b[`shockvar_curr'_finexp_r`dd'] - _se[`shockvar_curr'_finexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_p = _b[`shockvar_curr'_tradexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_u90 = _b[`shockvar_curr'_tradexp_bl] + 1.64*_se[`shockvar_curr'_tradexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_l90 = _b[`shockvar_curr'_tradexp_bl] - 1.64*_se[`shockvar_curr'_tradexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_u68 =_b[`shockvar_curr'_tradexp_bl] + _se[`shockvar_curr'_tradexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_l68 = _b[`shockvar_curr'_tradexp_bl] - _se[`shockvar_curr'_tradexp_bl]
				gen hor = `h'
				keep irf* hor 
				collapse (mean) irf*, by(hor) 
				if `h'>0	{
					append using "$irfspathname_monthlylps\temp_irfs_countries_ia_r`robcounter'.dta"
				}
				sort hor
				quietly save "$irfspathname_monthlylps\temp_irfs_countries_ia_r`robcounter'.dta", replace
				restore
			}
			forvalues dd=1(1)$tradexp_rnum	{
				local robcounter = `robcounter' + 1
				local lp_shock_local = "$lp_shock"
				local rem_shocks: list lp_shock_local - shockvar_curr
				quietly xtscc f`h'.`depvar_curr' l(1/${lp_ownlag}).`depvar_curr' l(1/${lp_controlslag}).(${lp_controls}) `shockvar_curr' `shockvar_curr'_finexp_bl `shockvar_curr'_tradexp_r`dd' `rem_shocks' tradexp_r`dd' finexp_bl if time>=tm(${mindate}) & time<=tm(${maxdate}) & ip_availability, fe
				estimates store lp`h'
				preserve
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_p = _b[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_u90 = _b[`shockvar_curr'] + 1.64*_se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_l90 = _b[`shockvar_curr'] - 1.64*_se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`robcounter'_u68 = _b[`shockvar_curr'] + _se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_r`dd'_l68 = _b[`shockvar_curr'] - _se[`shockvar_curr']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_p = _b[`shockvar_curr'_finexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_u90 = _b[`shockvar_curr'_finexp_bl] + 1.64*_se[`shockvar_curr'_finexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_l90 = _b[`shockvar_curr'_finexp_bl] - 1.64*_se[`shockvar_curr'_finexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_u68 =_b[`shockvar_curr'_finexp_bl] + _se[`shockvar_curr'_finexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_fe_r`robcounter'_l68 = _b[`shockvar_curr'_finexp_bl] - _se[`shockvar_curr'_finexp_bl]
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_p = _b[`shockvar_curr'_tradexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_u90 = _b[`shockvar_curr'_tradexp_r`dd'] + 1.64*_se[`shockvar_curr'_tradexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_l90 = _b[`shockvar_curr'_tradexp_r`dd'] - 1.64*_se[`shockvar_curr'_tradexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_u68 =_b[`shockvar_curr'_tradexp_r`dd'] + _se[`shockvar_curr'_tradexp_r`dd']
				gen irf_`depvar_curr'_`shockvar_curr'_ia_te_r`robcounter'_l68 = _b[`shockvar_curr'_tradexp_r`dd'] - _se[`shockvar_curr'_tradexp_r`dd']
				gen hor = `h'
				keep irf* hor 
				collapse (mean) irf*, by(hor) 
				if `h'>0	{
					append using "$irfspathname_monthlylps\temp_irfs_countries_ia_r`robcounter'.dta"
				}
				sort hor
				quietly save "$irfspathname_monthlylps\temp_irfs_countries_ia_r`robcounter'.dta", replace
				restore
			}
					
			display "Working on h=`h' for shock `shockvar_curr' on `depvar_curr'"
		}
					
		preserve
		use "$irfspathname_monthlylps\temp_irfs_countries.dta", clear
		merge 1:1 hor using "$irfspathname_monthlylps\lp_irfs_countries.dta"
		drop _merge
		sort hor
		quietly save "$irfspathname_monthlylps\lp_irfs_countries.dta", replace
		restore
		preserve
		use "$irfspathname_monthlylps\temp_irfs_countries_ia.dta", clear
		merge 1:1 hor using "$irfspathname_monthlylps\lp_irfs_countries_ia.dta"
		drop _merge
		sort hor
		quietly save "$irfspathname_monthlylps\lp_irfs_countries_ia.dta", replace
		restore
		
		local robcounter = $finexp_rnum + $tradexp_rnum
		forvalues dd=1(1)`robcounter'		{
			preserve
			use "$irfspathname_monthlylps\temp_irfs_countries_ia_r`dd'.dta", clear
			merge 1:1 hor using "$irfspathname_monthlylps\lp_irfs_countries_ia_r`dd'.dta"
			drop _merge
			sort hor
			quietly save "$irfspathname_monthlylps\lp_irfs_countries_ia_r`dd'.dta", replace
			restore
		}
		
	}
}
!del "${irfspathname_monthlylps}\temp*.dta"
erase "$datapath_monthlylps\Georgiadis_Jarocinski_2025_replication_dataset_monthly_lps_with_shocks.dta"


// Figure 11: Effects of US monetary policy shocks on RoW industrial production from panel local projections 
capture shell rmdir "${superpath}\Figures paper\Figure 11" /s /q
mkdir "${superpath}\Figures paper\Figure 11"
use "$irfspathname_monthlylps\lp_irfs_countries.dta", clear
gen zeroline = 0
drop if hor>${plotmaxhor}
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_cmp_l68 irf_lip_cmp_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_cmp_l90 irf_lip_cmp_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_cmp hor, plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("%") title("Conventional", size(vlarge)) lcolor(black) lpattern("solid") saving("$figurepath_monthlylps\lip_cmp.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_ofg_l68 irf_lip_ofg_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_ofg_l90 irf_lip_ofg_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_ofg hor, plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("%") title("Forward guidance", size(vlarge)) lcolor(black) lpattern("solid") saving("$figurepath_monthlylps\lip_ofg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_lsap_l68 irf_lip_lsap_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_lsap_l90 irf_lip_lsap_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_lsap hor, plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("%") title("LSAP", size(vlarge)) lcolor(black) lpattern("solid") saving("$figurepath_monthlylps\lip_lsap.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_dfg_l68 irf_lip_dfg_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_dfg_l90 irf_lip_dfg_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_dfg hor, plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("%") title("CBI", size(vlarge)) lcolor(black) lpattern("solid") saving("$figurepath_monthlylps\lip_dfg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
graph combine "$figurepath_monthlylps\lip_cmp.gph" "$figurepath_monthlylps\lip_ofg.gph" "$figurepath_monthlylps\lip_lsap.gph" "$figurepath_monthlylps\lip_dfg.gph", ycommon cols(4) xsize(12) ysize(2.5) scale(2.5) graphregion(color(white)) 
graph export "${superpath}\Figures paper\Figure 11\irf_plp_lip_combined.pdf", replace

// Figure 13: The role of financial and trade exposure for effects of US monetary policy shocks on RoW industrial production 
capture shell rmdir "${superpath}\Figures paper\Figure 13" /s /q
mkdir "${superpath}\Figures paper\Figure 13"
use "$irfspathname_monthlylps\lp_irfs_countries_ia.dta", clear
gen zeroline = 0
drop if hor>${plotmaxhor}
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_cmp_ia_fe_l68 irf_lip_cmp_ia_fe_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_cmp_ia_fe_l90 irf_lip_cmp_ia_fe_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_cmp_ia_fe hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Conventional", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_cmp.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_ofg_ia_fe_l68 irf_lip_ofg_ia_fe_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_ofg_ia_fe_l90 irf_lip_ofg_ia_fe_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_ofg_ia_fe hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Forward guidance", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_ofg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_lsap_ia_fe_l68 irf_lip_lsap_ia_fe_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_lsap_ia_fe_l90 irf_lip_lsap_ia_fe_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_lsap_ia_fe hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("LSAP", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_lsap.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_dfg_ia_fe_l68 irf_lip_dfg_ia_fe_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_dfg_ia_fe_l90 irf_lip_dfg_ia_fe_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_dfg_ia_fe hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("CBI", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_dfg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
graph combine "$figurepath_monthlylps\lip_cmp.gph" "$figurepath_monthlylps\lip_ofg.gph" "$figurepath_monthlylps\lip_lsap.gph" "$figurepath_monthlylps\lip_dfg.gph", ycommon cols(4) xsize(12) ysize(2.5) scale(2.5) graphregion(color(white)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_cmp_ia_te_l68 irf_lip_cmp_ia_te_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_cmp_ia_te_l90 irf_lip_cmp_ia_te_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_cmp_ia_te hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Conventional", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_cmp.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_ofg_ia_te_l68 irf_lip_ofg_ia_te_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_ofg_ia_te_l90 irf_lip_ofg_ia_te_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_ofg_ia_te hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Forward guidance", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_ofg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_lsap_ia_te_l68 irf_lip_lsap_ia_te_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_lsap_ia_te_l90 irf_lip_lsap_ia_te_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_lsap_ia_te hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("LSAP", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_lsap.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_dfg_ia_te_l68 irf_lip_dfg_ia_te_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_dfg_ia_te_l90 irf_lip_dfg_ia_te_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_dfg_ia_te hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("CBI", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_dfg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
graph combine "$figurepath_monthlylps\lip_cmp.gph" "$figurepath_monthlylps\lip_ofg.gph" "$figurepath_monthlylps\lip_lsap.gph" "$figurepath_monthlylps\lip_dfg.gph", ycommon cols(4) xsize(12) ysize(2.5) scale(2.5) graphregion(color(white))
foreach cc in cmp ofg lsap dfg {
	twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_`cc'_ia_fe_l68 irf_lip_`cc'_ia_fe_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_`cc'_ia_fe_l90 irf_lip_`cc'_ia_fe_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_`cc'_ia_fe hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Financial exposure", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_`cc'_fe.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
	twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (rarea irf_lip_`cc'_ia_te_l68 irf_lip_`cc'_ia_te_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_`cc'_ia_te_l90 irf_lip_`cc'_ia_te_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_`cc'_ia_te hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Trade exposure", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_`cc'_te.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
	graph combine "$figurepath_monthlylps\lip_`cc'_fe.gph" "$figurepath_monthlylps\lip_`cc'_te.gph", ycommon cols(2) xsize(6) ysize(2.5) scale(2.5) graphregion(color(white))
	graph export "${superpath}\Figures paper\Figure 13\irf_plp_lip_ia_`cc'_combined.pdf", replace
}


// Figure 14: Robustness checks for the role of financial and trade exposure for effects of US monetary policy shocks on RoW industrial production
capture shell rmdir "${superpath}\Figures paper\Figure 14" /s /q
mkdir "${superpath}\Figures paper\Figure 14"
use "$irfspathname_monthlylps\lp_irfs_countries_ia.dta", clear
local robcounter = $finexp_rnum + $tradexp_rnum
forvalues dd=1(1)`robcounter'		{
		merge 1:1 hor using "$irfspathname_monthlylps\lp_irfs_countries_ia_r`dd'.dta"
		drop _merge
		sort hor
}
gen zeroline = 0
drop if hor>${plotmaxhor}
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (connected irf_lip_cmp_ia_r*_p hor, msymbol("Dh" "X" "Oh" "V" "Sh" "Th" "+" "|") msize("small"..) mcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lpattern("dash_dot" "dash_dot" "dash" "dash" "longdash_dot" "longdash_dot" "shortdash_dot" "shortdash_dot")) (rarea irf_lip_cmp_ia_l68 irf_lip_cmp_ia_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_cmp_ia_l90 irf_lip_cmp_ia_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_cmp_ia_p hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Conventional", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_cmp.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (connected irf_lip_ofg_ia_r*_p hor, msymbol("Dh" "X" "Oh" "V" "Sh" "Th" "+" "|") msize("small"..) mcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lpattern("dash_dot" "dash_dot" "dash" "dash" "longdash_dot" "longdash_dot" "shortdash_dot" "shortdash_dot")) (rarea irf_lip_ofg_ia_l68 irf_lip_ofg_ia_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_ofg_ia_l90 irf_lip_ofg_ia_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_ofg_ia_p hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Forward guidance", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_ofg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (connected irf_lip_lsap_ia_r*_p hor, msymbol("Dh" "X" "Oh" "V" "Sh" "Th" "+" "|") msize("small"..) mcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lpattern("dash_dot" "dash_dot" "dash" "dash" "longdash_dot" "longdash_dot" "shortdash_dot" "shortdash_dot")) (rarea irf_lip_lsap_ia_l68 irf_lip_lsap_ia_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_lsap_ia_l90 irf_lip_lsap_ia_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_lsap_ia_p hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("LSAP", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_lsap.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (connected irf_lip_dfg_ia_r*_p hor, msymbol("Dh" "X" "Oh" "V" "Sh" "Th" "+" "|") msize("small"..) mcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lpattern("dash_dot" "dash_dot" "dash" "dash" "longdash_dot" "longdash_dot" "shortdash_dot" "shortdash_dot")) (rarea irf_lip_dfg_ia_l68 irf_lip_dfg_ia_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_dfg_ia_l90 irf_lip_dfg_ia_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_dfg_ia_p hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("CBI", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_dfg.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor}) ylabel(, nolabels)) 
graph combine "$figurepath_monthlylps\lip_cmp.gph" "$figurepath_monthlylps\lip_ofg.gph" "$figurepath_monthlylps\lip_lsap.gph" "$figurepath_monthlylps\lip_dfg.gph", ycommon cols(4) xsize(12) ysize(2.5) scale(2.5) graphregion(color(white)) 
foreach cc in cmp ofg lsap dfg {	
	twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (connected irf_lip_`cc'_ia_fe_r*_p hor, msymbol("Dh" "X" "Oh" "V" "Sh" "Th" "+" "|") msize("small"..) mcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lpattern("dash_dot" "dash_dot" "dash" "dash" "longdash_dot" "longdash_dot" "shortdash_dot" "shortdash_dot")) (rarea irf_lip_`cc'_ia_fe_l68 irf_lip_`cc'_ia_fe_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_`cc'_ia_fe_l90 irf_lip_`cc'_ia_fe_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_`cc'_ia_fe hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Financial exposure", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_`cc'_fe.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
	twoway (line zeroline hor, lcolor(black) lwidth(medthin)) (connected irf_lip_`cc'_ia_te_r*_p hor, msymbol("Dh" "X" "Oh" "V" "Sh" "Th" "+" "|") msize("small"..) mcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lcolor("gs2" "gs4" "gs6" "gs7" "gs8" "gs9" "gs11" "gs13") lpattern("dash_dot" "dash_dot" "dash" "dash" "longdash_dot" "longdash_dot" "shortdash_dot" "shortdash_dot")) (rarea irf_lip_`cc'_ia_te_l68 irf_lip_`cc'_ia_te_u68 hor, color(blue%30) lcolor(white%0)) (rarea irf_lip_`cc'_ia_te_l90 irf_lip_`cc'_ia_te_u90 hor, color(blue%10) lcolor(white%0)) (line irf_lip_`cc'_ia_te hor, scheme(s2mono) plotregion(margin(zero)) graphregion(color(white) margin(zero)) xtitle("") ytitle("pp") title("Trade exposure", size(vlarge)) lpattern("solid") saving("$figurepath_monthlylps\lip_`cc'_te.gph", replace) legend(off) nodraw ylab(, nogrid) xscale(range(0 ${plotmaxhor})) xlabel(0(${plothorstep})${plotmaxhor})) 
	graph combine "$figurepath_monthlylps\lip_`cc'_fe.gph" "$figurepath_monthlylps\lip_`cc'_te.gph", ycommon cols(2) xsize(6) ysize(2.5) scale(2.5) graphregion(color(white))
	graph export "${superpath}\Figures paper\Figure 14\irf_plp_lip_ia_`cc'_rob_combined.pdf", replace
}



shell rmdir "${figurepath_monthlylps}" /s /q
shell rmdir "${irfspathname_monthlylps}" /s /q
