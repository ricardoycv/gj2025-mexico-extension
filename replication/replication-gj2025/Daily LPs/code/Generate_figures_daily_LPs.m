
clc
clear all
close all
restoredefaultpath


% % SPECIFY HERE PATH IN WHICH REPLICATION PACKAGE IS STORED:
% superpath = 'P:\ECB business areas\DGI\IPA\Personal folders\Georgiadis\Research\US MP normalization\GJ 2025 JIE replication';
% 
% generalpath = strcat(superpath,'\Daily LPs');
% irfsdatapath = strcat(generalpath,'\Daily LPs IRFs estimates');
% figurepath = strcat(generalpath,'\Figures daily LPs');
% addpath(strcat(generalpath,'\Matlab subroutines'))

cd ..\..
superpath    = pwd;
generalpath  = strcat(superpath,'\Daily LPs');
irfsdatapath = strcat(generalpath,'\Daily LPs IRFs estimates');
figurepath   = strcat(generalpath,'\Figures daily LPs');
matlabpath   = strcat(generalpath,'\Matlab subroutines');

eval(['cd ''',generalpath,' '' '])
mkdir(figurepath)
eval(['cd ''',matlabpath,''' '])



%% Figure 1: Impact-day US financial market effects of one-standard-deviation Fed policy shocks
filename = [{'lp_irfs_baseline.xlsx'}];
savename = 'baseline';
samexaxis= 1;
lagtoplot = 0;
shockvar = [{'cmp'},{'ofg'},{'lsap'},{'dfg'};...
            {'Conventional'},{'FG'},{'LSAP'},{'CBI'}];
Plot_daily_impact(irfsdatapath,filename,figurepath,shockvar,savename,lagtoplot,samexaxis)

%% Figure 2: Impact-day effects of US monetary policy shocks on global interest rates, equity prices and exchange rates
filename = [{'lp_irfs_panel_lps_aes.xlsx'}];
savename = 'paneldailyimpact';
samexaxis= 1;
lagtoplot = 0;
shockvar = [{'cmp'},{'ofg'},{'lsap'},{'dfg'};...
            {'Conventional'},{'FG'},{'LSAP'},{'CBI'}];
Plot_daily_impact_panel(irfsdatapath,filename,figurepath,shockvar,savename,lagtoplot,samexaxis)

%% Figure B.1: Robustness for daily US financial market impact effects of the LSAP shocks
filename = [{'lp_irfs_baseline.xlsx'},{'lp_irfs_baseline_lsappostgfc.xlsx'}];
savename = 'lsapeffectss_samplesplit';
lagtoplot = 0;
samexaxis = 1;
shockvar = [{'lsap'},{'lsapp08'};...
            {'Baseline'},{'Zero prior 2008'}];
Plot_daily_impact_comparison(irfsdatapath,filename,figurepath,shockvar,savename,lagtoplot,samexaxis)

%% Figure B.2: Daily impact effects on global interest rates, stock prices and exchange rates (using post-GFC LSAP shocks)
filename = [{'lp_irfs_panel_lps_aes_lsappostgfc.xlsx'}];
savename = 'paneldailyimpact_lsappostgfc';
samexaxis= 1;
lagtoplot = 0;
shockvar = [{'cmp'},{'ofg'},{'lsapp08'},{'dfg'};...
            {'Conventional'},{'FG'},{'LSAP'},{'CBI'}];
Plot_daily_impact_panel(irfsdatapath,filename,figurepath,shockvar,savename,lagtoplot,samexaxis)


%% Select and transfer shown in paper to Figure folder
sourcefolder = figurepath;
destinationfolder  = [superpath,'\Figures paper'];
figure_transfer_daily(sourcefolder,destinationfolder)
eval(['rmdir ''',figurepath,''' s '])
eval(['rmdir ''',irfsdatapath,''' s '])
