global superpath "H:\Gerencia de Investigación Monetaria\RCV\Papers\Extension_Choques_Informacion\GJ 2025 JIE replication" 
global generalpath_dailylps "${superpath}\Daily LPs"
global datapath_dailylps "${generalpath_dailylps}\Data daily LPs"
global statapath_dailylps "${generalpath_dailylps}\Stata subroutines"
global irfspathname_dailylps "${generalpath_dailylps}\Daily LPs IRFs estimates"
capture shell rmdir "${irfspathname_dailylps}" /s /q
mkdir "${irfspathname_dailylps}"
********************************************************************************


********************************************************************************
// Load data
use "$datapath_dailylps\Georgiadis_Jarocinski_2025_replication_dataset_daily_lps_with_shocks.dta", clear
********************************************************************************


************************* Time-series local projections for Figures 1 and B.1
global lp_depvar "tb_rate_3m tb_rate_1y tb_rate_2y tb_rate_5y tb_rate_10y ectreas_1y_us ectreas_2y_us ectreas_5y_us ectreas_10y_us tptreas_2y_us tptreas_5y_us tptreas_10y_us lsp500 fgovy10y_ca lfstockp_ca lfneer_ca lffxusd_ca fgovy10y_uk fgovy10y_se fgovy10y_jp fgovy10y_au fgovy10y_de lfstockp_uk lfneer_uk lfstockp_se lfneer_se lfstockp_de lfneer_de lfstockp_jp lfneer_jp lfstockp_au lfneer_au ftp10_us fec10_us ftp10_ca fec10_ca ftp10_uk fec10_uk ftp10_de fec10_de ftp10_se fec10_se ftp10_jp fec10_jp ftp10_au fec10_au lffxusd_uk lffxusd_se lffxusd_jp lffxusd_au lffxusd_de lfneer_us lfneer_us_ae"
global lp_controlslag 1
global lp_ownlag 1
global lp_hor 0
global mindate  "1jan1991" 
global maxdate  "30jun2024"

foreach cc of global lp_depvar	{ // this is because newey/xtscc cannot handle missings in the dataset
	ipolate `cc' time, gen(`cc'_intpol)
	drop `cc'
	rename `cc'_intpol `cc'	
}
foreach cc in cmp ofg lsap dfg	{ // standardise shocks for non-zero values
	sum `cc' if `cc'!=0
	replace `cc' = (`cc'-`r(mean)')/`r(sd)' if `cc'!=0
}
gen lsapp08 = lsap
replace lsapp08 = 0 if time_td<td(1jan2008)
save "${datapath_dailylps}\daily_data_for_panellps.dta", replace


// LPs for baseline
global lp_shock "cmp ofg lsap dfg"
global lp_controls ""
global contemp_controls "" 
global savename "baseline"
do "${statapath_dailylps}\estimate_lps.do"

// LPs for LSAPs set to 0 pre 2008
global lp_shock "lsapp08" 
global lp_controls ""
global contemp_controls "" 
global savename "baseline_lsappostgfc"
do "${statapath_dailylps}\estimate_lps.do"
********************************************************************************


************************* Panel local projections
use "${datapath_dailylps}\daily_data_for_panellps.dta", clear
global lp_depvar_panel "fgovy10y lfstockp ftp10 fec10 lffxusd"
global lp_depvar_timeseries "lsp500 tb_rate_10y ectreas_10y_us tptreas_10y_us lfneer_us lfneer_us_ae"
global lp_shock "cmp ofg lsap dfg"
global lp_controls ""
global contemp_controls ""
global savename "panel_lps_aes"
do "${statapath_dailylps}\estimate_panellps.do"

use "${datapath_dailylps}\daily_data_for_panellps.dta", clear
global lp_depvar_panel "fgovy10y lfstockp ftp10 fec10 lffxusd"
global lp_depvar_timeseries "lsp500 tb_rate_10y ectreas_10y_us tptreas_10y_us lfneer_us lfneer_us_ae"
global lp_shock "cmp ofg lsapp08 dfg"
global lp_controls ""
global contemp_controls "" 
global savename "panel_lps_aes_lsappostgfc"
do "${statapath_dailylps}\estimate_panellps.do"

*erase "${datapath_dailylps}\daily_data_for_panellps.dta"
*erase "${datapath_dailylps}\Georgiadis_Jarocinski_2025_replication_dataset_daily_lps_with_shocks.dta"
********************************************************************************


************************** Call Matlab and generate figures based on impact effect estimates
cd "${generalpath_dailylps}\Matlab subroutines\"
shell matlab -r "Generate_figures_daily_LPs; quit" 
********************************************************************************
