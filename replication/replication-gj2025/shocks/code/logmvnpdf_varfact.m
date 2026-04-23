function logp = logmvnpdf_varfact(x, mean, varfact)
% Outputs log density of N(mean,varfact*varfact') evaluated at x
% INPUTS:
% x - Nx1 vector at which we evaluate the log density
% mean - Nx1
% varfact - NxN matrix such that varfact*varfact' = variance
%           e.g.: varfact = chol(variance,'lower')

N = length(x);

const = -0.5 * N * log(2*pi);

z = varfact\(x(:) - mean(:));

if istriu(varfact) || istril(varfact)
    logdetvar = 2 * sum(log(diag(varfact)));
else
    logdetvar = 2 * log(det(varfact));
end

logp = const - 0.5 * logdetvar  - 0.5 * sum(z.^2);

end
