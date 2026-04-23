global generalpath_descriptives "${superpath}\Descriptive charts"
global datapath_descriptives "${generalpath_descriptives}\Data descriptive charts"
********************************************************************************


*********************************************************************************
// Figure B.7: Evolution of US holdings of foreign portfolio bond and equity
import delimited "$datapath_descriptives\slt_ticpub_UPDATE_TO_2024.csv", clear
replace country_name = strltrim(country_name)
replace country_name = strrtrim(country_name)
drop if country_code==16713 | country_code==19992 | country_code==34401 | country_code==39942 | country_code==49999 | country_code==59994 | country_code==69995 | country_code==79995 | country_code==99996 //| country_code==69906
gen AE=(country_name=="Austria" | country_name=="Belgium" | country_name=="Canada" | country_name=="Germany" | country_name=="Denmark" | country_name=="Spain" | country_name=="Finland" | country_name=="France" | country_name=="United Kingdom" | country_name=="Greece" | country_name=="Ireland" | country_name=="Italy" | country_name=="Japan" | country_name=="Luxembourg" | country_name=="Netherlands" | country_name=="Norway" | country_name=="Portugal" | country_name=="Sweden" | country_name=="Estonia" | country_name=="Latvia" | country_name=="Lithuania" | country_name=="Czech Republic" | country_name=="Korea" | country_name=="Slovak Republic" | country_name=="Slovenia" | country_name=="Australia" | country_name=="Switzerland" | country_name=="Cyprus" | country_name=="Hong Kong" | country_name=="Iceland" | country_name=="Malta"  | ///
	 country_name=="New Zealand" | country_name=="Singapore" | country_name=="Israel") 
gen SFC=(country_name=="Bermuda" | country_name=="British Virgin Islands" | country_name=="Cayman Islands" | country_name=="Netherlands Antilles" | country_name=="Curacao" | country_name=="Guernsey" | country_name=="Jersey" | country_name=="Liberia" | country_name=="Luxembourg" | country_name=="Netherlands" | country_name=="Malta" ///
 | country_name=="Mauritius" | country_name=="Panama" | country_name=="Ireland" | country_name=="Switzerland" | country_name=="Isle of Man" | country_name=="Marshall Islands") // see Bertaut, Curcuru, Bressler (2019, Globalization and the Geography of Capital Flows) 
gen EME = (AE==0 & SFC==0)
gen month = substr(date,6,2)
gen year = substr(date,1,4)
destring year month slt*, force replace 
gen time = ym(year,month)
format time %tm
drop *_esttrans *_valchg
gen countrygroup = "AE"
replace countrygroup = "SFC" if SFC==1
replace countrygroup = "EME" if EME==1
keep if month==12
collapse (sum) slt99*, by(countrygroup year)
keep year countrygroup slt99_us_for_bond slt99_us_for_stk
rename (slt99_us_for_bond slt99_us_for_stk) (bonds stocks)
replace bonds = bonds/1000
replace stocks = stocks/1000
reshape wide bonds stocks, i(year) j(countrygroup, string)
drop if year>2023
graph bar bondsAE stocksAE bondsEME stocksEME bondsSFC stocksSFC , over(year) stack scheme(s2mono) plotregion(margin(zero)) graphregion(color(white)) bar(1, color("red")) bar(2, color("orange")) bar(3, color("blue")) bar(4, color("ltblue")) bar(5, color("green")) bar(6, color("midgreen")) asyvars bargap(50) ytitle("Billion USD") legend(order(1 3 5 2 4 6) label(1 "AE bonds") label(2 "AE equity") label(3 "EME bonds") label(4 "EME equity") label(5 "Fin centre bonds") label(6 "Fin centre equity") size(medium) region(lcolor(white)) cols(3) symysize(medium) symxsize(huge)) xsize(8) scale(1.35)
capture shell rmdir "${superpath}\Figures paper\Figure B7" /s /q
mkdir "${superpath}\Figures paper\Figure B7"
graph export "${superpath}\Figures paper\Figure B7\stacked_barchart_ustics.eps", replace
*********************************************************************************


*********************************************************************************
// Figure B.9: Evolution of AE (EME) foreign assets (liabilities)
use "$datapath_descriptives\IMF_BoP_WDI_GDP.dta", clear
gen fdi_l_ngdp = fdi_l/ngdp*100
gen pfequ_l_ngdp = pfequ_l/ngdp*100
gen pfdebt_l_ngdp = pfdebt_l/ngdp*100
gen oi_l_ngdp = oi_l/ngdp*100
gen fdi_a_ngdp = fdi_a/ngdp*100
gen pfequ_a_ngdp = pfequ_a/ngdp*100
gen pfdebt_a_ngdp = pfdebt_a/ngdp*100
gen oi_a_ngdp = oi_a/ngdp*100
collapse (median) *_ngdp, by(countrygroup time) 
drop if time<2012
replace countrygroup = "AE assets" if countrygroup=="AE"
replace countrygroup = "EME liabilities" if countrygroup=="EME"
gen pfequ_ngdp = pfequ_a_ngdp
gen pfdebt_ngdp = pfdebt_a_ngdp
gen oi_ngdp = oi_a_ngdp
replace pfequ_ngdp = pfequ_l_ngdp if countrygroup == "EME liabilities"
replace pfdebt_ngdp = pfdebt_l_ngdp if countrygroup == "EME liabilities"
replace oi_ngdp = oi_l_ngdp if countrygroup == "EME liabilities"
graph bar pfequ_ngdp pfdebt_ngdp oi_ngdp, over(time) over(countrygroup, label(angle(90))) stack scheme(s2mono) plotregion(margin(zero)) graphregion(color(white)) bar(1, color("red")) bar(2, color("orange")) bar(3, color("blue")) bar(4, color("ltblue")) asyvars bargap(50) ytitle("% of GDP") legend(label(1 "PF equity") label(2 "PF debt") label(3 "Other investment") size(medium) region(lcolor(white)) cols(3) symysize(medium) symxsize(huge)) xsize(8) scale(1.35)
capture shell rmdir "${superpath}\Figures paper\Figure B9" /s /q
mkdir "${superpath}\Figures paper\Figure B9"
graph export "${superpath}\Figures paper\Figure B9\stacked_barchart_imfiip_ae_eme_relcountrygdp.eps", replace
*********************************************************************************

