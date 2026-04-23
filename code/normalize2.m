function P = normalize2(G, vrange, ivars, ymaturities)
% PURPOSE: Reorder the rows of G and flip their signs according to a rule.
% INPUTS:
% G - matrix to reorder and flip, Nr x Nc
% vrange - column numbers: after reordering and flipping the average of
%          these columns will be positive in each row
% ivars - Nr column numbers: after reordering and flipping
%    the first row will have the maximum entry for ivars(1)
%    the second row will have the maximum entry for ivars(2), etc.
% ymaturities - maturities of the variables, here used to identify SP500
%               (assumed to be the first variable with maturity NaN)
% OUTPUT:
% P - the matrix that reorders the rows of C and flips their signs
% so that P*G will satisfy:
% 1) The average of vrange of each row is positive
% 2) Each consecutive diagonal element is as large as possible
% 3) BUT the most positive entry for SP500 will be in the fourth row
%    (or last, if there are less than four rows)
% DEPENDS: normalize1.m
N = size(G,1);
P1 = normalize1(G, vrange, ivars);

% identify SP500
istock = find(isnan(ymaturities), 1);
% let the shock that moves SP500 up be the fourth

% find the maximum response of sp500
PG = P1*G;
[~,maxIdx] = max(PG(:,istock));

% build shock order
sorder = 1:N;

% drop the shock with max sp500 from sorder
sorder(maxIdx) = [];

% reattach this shock at the fourth position
% or last if less than 4 positions
if length(sorder)<4
    sorder = [sorder, maxIdx];
else
    sorder = [sorder(1:3), maxIdx, sorder(4:end)];
end

% create row permutation matrix
P2 = eye(N);
P2 = P2(sorder,:);

P = P2*P1;

