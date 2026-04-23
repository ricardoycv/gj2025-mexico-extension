% Model Y = UC, U heteroskedastic or Student-t
% Baseline priors and Gibbs sampler settings

[T, N] = size(Y);

% prior for W
prior.Wmean = eye(N);
prior.Wprec = 1/(200^2)*eye(N^2);

% Prior for Student-t shocks
prior.t.v = 0; % 0: regimes, NaN's - estimate v, numbers - fixed val. of v
vmean = 2; vstd = 1; bet = vstd^2/vmean; alp = vmean/bet;
prior.t.va = repmat(alp, 1, N);
prior.t.vb = repmat(bet, 1, N);


% prior for variances in regimes
prior.regimes.v = 10;

gssettings.ndraws = 2000;
gssettings.burnin = 1000; 50000;
gssettings.saveevery = 50; 500;
gssettings.reportevery = 1e3;

