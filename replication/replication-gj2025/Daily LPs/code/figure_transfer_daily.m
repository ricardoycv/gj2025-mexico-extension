
function figure_transfer_daily(sourcefolder,destinationfolder)

% Figure 1: mpact-day US financial market effects of one-standard-deviation Fed policy shocks
foldername = 'Figure 1';
figurelist = [{'irfj_lps_impact_effects_irs_smallscale_baseline.pdf'}];
copy_figure(figurelist,sourcefolder,destinationfolder,foldername)

% Figure 2: Impact-day effects of US monetary policy shocks on global interest rates, equity prices and exchange rates
foldername = 'Figure 2';
figurelist=[{'irfj_lps_impact_effects_spillovers_paneldailyimpact.pdf'}];
copy_figure(figurelist,sourcefolder,destinationfolder,foldername)

% Figure B.1: Robustness for daily US financial market impact effects of the LSAP shocks
foldername = 'Figure B1';
figurelist=[{'irfj_lps_impact_effects_irs_smallscale_lsapeffectss_samplesplit.pdf'}];
copy_figure(figurelist,sourcefolder,destinationfolder,foldername)

% Figure B.2: Daily impact effects on global interest rates, stock prices and exchange rates (using post-GFC LSAP shocks)
foldername = 'Figure B2';
figurelist=[{'irfj_lps_impact_effects_spillovers_paneldailyimpact_lsappostgfc.pdf'}];
copy_figure(figurelist,sourcefolder,destinationfolder,foldername)







