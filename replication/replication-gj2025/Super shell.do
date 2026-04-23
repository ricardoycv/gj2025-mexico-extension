clear
clear matrix
clear mata
set maxvar 10000
net install freqconv, replace from(https://www.haver.com/stata)
ssc install xtscc


//-------------------------> SPECIFY HERE PATH IN WHICH REPLICATION PACKAGE IS STORED:
global superpath "H:\Gerencia de Investigación Monetaria\RCV\Papers\Extension_Choques_Informacion\GJ 2025 JIE replication" 

*global superpath "P:\ECB business areas\DGI\IPA\Personal folders\Georgiadis\Research\US MP normalization\GJ 2025 JIE replication"

// (1) Estimate monetary policy shocks, merge shocks with daily and monthly macro-financial data for later etsimation of local projections and BVARs
do "${superpath}\Shocks\Shocks shell.do" 

// (2) Estimate daily local projections (Figures 1, 2, B.1 and B.2)
do "${superpath}\Daily LPs\Daily LPs shell.do" 

// (3) Estimate BVARs (Figures 3-10, 15, B.3-B.6, and B.8)
cd "${superpath}\BVARs" 
! matlab -r "run('BVARs_shell.m'); quit"

// (4) Estimate monthly panel local projections (Figures 11-14)
do "${superpath}\Monthly LPs\Monthly LPs shell.do" 

// (5) Produce descriptive statistics for Figures B.7 and B.9
do "${superpath}\Descriptive charts\Descriptive charts shell.do" 
