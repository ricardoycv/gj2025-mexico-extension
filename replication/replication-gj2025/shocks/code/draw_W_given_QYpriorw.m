function [W, accepted, logacceptprob, w_mode] = draw_W_given_QYpriorw(Q, Y, W, Wmean, Wprec, kappa, options)
% PURPOSE: Draw W from p(W|Q,Y) in YW = U, where
% Q is a matrix that makes U Gaussian: U.*sqrt(Q) = Z~iid.N(0,1)
% Uses Metropolized Independence Sampler.
% INPUTS:
% Q - positive numbers, T x N 
% Y - data, T x N
% W - previous draw of W, N x N
% OUTPUT:
% W - draw from p(W|Q,Y) (could be the same as the last W)
% accepted - true/false
% logacceptprob - log of the acceptance probability used for accepting
% DEPENDS: nlogcondpw_priorw, logmvnpdf_varfact
%
% Marek Jarocinski, 2022-Apr, 2023-Feb

N = size(Q,2);

% set these options outside the function to speed up:
% options = optimoptions(@fminunc, 'Display','off', 'Algorithm','trust-region',...
%     'SpecifyObjectiveGradient',true, 'HessianFcn','objective');

% find the mode and hessian of p(W|Y,Q)
par0 = W(:);
fun = @(par) nlogcondpw_priorw(par, Y, Q, Wmean, Wprec);
[w_mode,~,~,~,~,hessian] = fminunc(fun, par0, options);

% set the parameters of the Gaussian proposal density f
f_mean = w_mode;
f_var_inv = 1/kappa*hessian;
try
    f_var_inv_chol = chol(f_var_inv);
    f_var_fact = f_var_inv_chol\eye(N^2);
catch
    [f_V,f_d] = eig(f_var_inv,'vector');
    cutoff = f_d(N)/100;
    f_d(f_d<cutoff) = cutoff;
    f_var_fact = f_V*diag(f_d.^-0.5);
end

% draw candidate from the Gaussian proposal density f
w_prime = f_mean + f_var_fact*randn(N^2,1);

% compute the probability of acceptance
% f_var = f_var_fact*f_var_fact';
% logfW = log(mvnpdf(W(:)', f_mean', f_var));
% logfW_prime = log(mvnpdf(w_prime', f_mean', f_var));
logfW = logmvnpdf_varfact(W(:), f_mean, f_var_fact);
logfW_prime = logmvnpdf_varfact(w_prime, f_mean, f_var_fact);

logcondpW = -nlogcondpw_priorw(W(:), Y, Q, Wmean, Wprec);
logcondpW_prime = -nlogcondpw_priorw(w_prime, Y, Q, Wmean, Wprec);

logacceptprob = logcondpW_prime - logcondpW + logfW - logfW_prime;

accepted = log(rand) < logacceptprob;
if accepted
    W = reshape(w_prime, N, N);
end

end