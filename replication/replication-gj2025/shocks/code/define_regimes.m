function regimes = define_regimes(stringvar, printout)
% PURPOSE: Create structure 'regimes' based on a text variable
% INPUT:
% stringvar - T x 1 column of strings,
%             stringvar(t) is the regime of observation t
% OUTPUT:
% regimes.names - regime names
% regimes.num - number of regimes
% regimes.ind - 1 x regimes.num cell array with indicators of regimes

if iscell(stringvar)
    stringvar = string(stringvar);
end

if nargin<2
    printout = false;
end

regimes.names = unique(stringvar)';
regimes.num = length(regimes.names);
regimes.ind = cell(1, regimes.num);
for r = 1:regimes.num
    regimes.ind{r} = stringvar == regimes.names(r);
end

% display info
infotab = table(nan(regimes.num+1,1), Rownames=[regimes.names, "Total"], VariableNames="N.Obs");
for i = 1:regimes.num
    infotab{i,1} = sum(regimes.ind{i});
end
infotab{end,1} = sum(infotab{1:end-1,1});
if printout, disp(infotab), end

regimes.infotab = infotab;

