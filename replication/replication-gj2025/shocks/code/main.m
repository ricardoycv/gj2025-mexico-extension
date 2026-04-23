% Estimate Y = UC
clear all, close all
rng("default")
addpath("subroutines/")
pathout = "../results/";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data, define variables, maturities, regimes.
% Output: tab, ynames, ymaturities, prior.regimes

tab = readtable("../source_data/Y.csv");
tab.start.Format = "uuuu-MM-dd HH:mm";
fprintf('Data from %s to %s, T=%d\n', tab{1,1},tab{end,1},size(tab,1))

% define variables, maturities
ynames = ["ED1","TFUT02","TFUT10","SP500FUT"];
ymaturities = getMaturitiesJK(ynames);
Y = tab{:, ynames}*100;

prior.regimes = define_regimes(tab.EventType);

% save Y
writetable(tab(:,[tab.Properties.VariableNames{1} "EventType" ynames]), pathout+"Y.csv")

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bayesian estimation
sshocks_baseline_priors
sshocks_estimate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalization: identification is up to reordering and swapping signs, so
% ensure that each draw corresponds to same order and sign of the shocks

% Construct the reference point for the normalization
shock_effects_ref = chain.shock_effects(:,:,chain.reference_draw);
shocks_ref = chain.shocks(:,:,chain.reference_draw);
P = normalize2(xmode, 1:3, 1:4, ymaturities);
disp(P*shock_effects_ref)

% Normalize the chain (reorder and swap sign where needed)
sshocks_chain_normalize
mychain = chain_normalized;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reporting and saving the results 
sshocks_chain_report

% save shock distribution (it takes less space to save Y and the distribution of Ws)
shock_dist.y = tab(:,[tab.Properties.VariableNames{1} ynames]);
shock_dist.W = chain_normalized.W;
save(pathout+"shock_dist.mat", "shock_dist")

