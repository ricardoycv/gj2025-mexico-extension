function P = normalize1(G, vrange, ivars)
% PURPOSE: Reorder the rows of G and flip their signs according to a rule.
% INPUTS:
% G - matrix to reorder and flip, Nr x Nc
% vrange - column numbers: after reordering and flipping the average of
%          these columns will be positive in each row
% ivars - Nr column numbers: after reordering and flipping
%    the first row will have the maximum entry for ivars(1)
%    the second row will have the maximum entry for ivars(2), etc.
% OUTPUT:
% P - the matrix that reorders the rows of C and flips their signs
% so that P*G will satisfy:
% 1) The average of vrange of each row is positive
% 2) Each consecutive diagonal element is as large as possible

% 1) Flip signs so he average of vrange of each row is positive
P = diag(sign(mean(G(:,vrange),2)));

% if ivars<Nr, complete it by repeating the last variable
for i = 1:(size(G,1)-length(ivars))
    ivars(end+1) = ivars(end);
end

% 2) Reorder, so row n has the largest value of irow(n) variable
idx = [];
temp = P*G;
for n = ivars
    [~, i] = max(temp(:,n));
    idx = [idx, i];
    temp(i,:) = -inf;
end
P = P(idx,:);

