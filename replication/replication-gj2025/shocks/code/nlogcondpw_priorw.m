function [nlogp, grad, HH] = nlogcondpw_priorw(w, Y, Q, uW, Ginv)
% PURPOSE: Evaluate the negative log conditional posterior of w=vecW,
% -logp(w|Y,Q), as well as its gradient and Hessian.
% Assumes an informative prior p(vec(W)) = N(vec(uW), G)
[T,N] = size(Y);
W = reshape(w, N, N);

Z = Y*W.*sqrt(Q);
nlogp = -T*log(abs(det(W))) + 0.5*sum(sum(Z.^2));

if nargout > 1
    Winvtr = inv(W)';
    Zstar = Z.*sqrt(Q);
    temp = Y'*Zstar;
    grad = -T*Winvtr(:)' + temp(:)';
    
    if nargout > 2
        temp = [];
        for n = 1:N
            Ystar = Q(:,n).*Y;
            temp = blkdiag(temp, Ystar'*Y);
        end
        HH = T*commutation(N,N)*kron(Winvtr, Winvtr') + temp;
        HH = 0.5*(HH + HH');
    end
end

% add the prior
if nargin>3
    nlogp = nlogp + 0.5*(w-uW(:))'*Ginv*(w-uW(:));
    if nargout > 1
        grad = grad + (w-uW(:))'*Ginv;
        if nargout > 2
            HH = HH + Ginv;
        end
    end
end

end

function k = commutation(n, m)
% commutation(n, m) or commutation([n m])
% returns Magnus and Neudecker's commutation matrix of dimensions n by m
% Author: Thomas P Minka (tpminka@media.mit.edu)
% edited by Marek Jarocinski: shorten and make it independent of 'vec'
if nargin < 2
  m = n(2);
  n = n(1);
end
temp = eye(n);
k = reshape(kron(temp(:), eye(m)), n*m, n*m);
end