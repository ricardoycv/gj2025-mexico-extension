% Normalize the Markov chain of a Bayesian structural model
% Y = U*C
% Use pairwise correlations between shock draws and reference shock

[T, N, ndraws] = size(chain.shocks);
chain_normalized.W = nan(N, N, ndraws);
chain_normalized.Q = nan(T, N, ndraws);
chain_normalized.shock_effects = nan(N, N, ndraws);
chain_normalized.shocks = nan(T, N, ndraws);
chain_normalized.t_v = nan(N, ndraws);

shocks_ref = shocks_ref*P';

norderswaps = 0;
for i = 1:ndraws
    shocks = chain.shocks(:,:,i);

    Ptr = zeros(N);
    CC = corr(shocks,shocks_ref);
    for n = 1:N
        [~, indmax] = max(abs(CC),[],"all");
        Ptr(indmax) = sign(CC(indmax));
        [row,col] = ind2sub([N,N],indmax);
        CC(row,:) = 0;
        CC(:,col) = 0;
    end
    P = Ptr';
    if not(isequal(P*Ptr,eye(N)))
        error("P not orthogonal")
    end
    norderswaps = norderswaps + not(isequal(P,eye(N)));
    
    chain_normalized.W(:,:,i) = chain.W(:,:,i)*Ptr;
    chain_normalized.Q(:,:,i) = chain.Q(:,:,i)*abs(Ptr);
    chain_normalized.shocks(:,:,i) = chain.shocks(:,:,i)*Ptr;
    chain_normalized.shock_effects(:,:,i) = P*chain.shock_effects(:,:,i);
    chain_normalized.shock_effects1s(:,:,i) = P*chain.shock_effects1s(:,:,i);
    chain_normalized.t_v(:,i) = abs(P)*chain.t_v(:,i);
end
fprintf('norderswaps = %d\n',norderswaps)
