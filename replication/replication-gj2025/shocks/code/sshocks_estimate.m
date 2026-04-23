% Estimate Y = UC, U heteroskedastic
% where
% Y - observable data, i.i.d.
% U - i.i.d. normal with R variance regimes
% C - matrix with the impacts
% We will actually estimate W in YW = U, then recover C = inv(W)
%
% Gibbs sampler, data augmentation
% Depends: draw_W_given_QYpriorw (-> nlogcondpw_priorw, logmvnpdf_varfact),
%          normalize1.m, timing_message.m

% Assumes the following are defined:
% prior
% gssettings
% Y
% normalize (struct)
% pathout


[T, N] = size(Y);

% Starting values

W = chol(cov(Y))\eye(N); W = 0.1*eye(N);
Q = ones(T,N);
if prior.t.v ~= 0
    t_v = prior.t.va .* prior.t.vb;
else
    t_v = NaN;
end 

kappa = 3; % scalar in the importance sampler variance of f

% options for draw_W_given_QY
draw_W_options = optimoptions(@fminunc, Display="off", Algorithm="trust-region",...
    SpecifyObjectiveGradient=true, HessianFcn="objective");

% Initialize the chain
chain.W = nan(N, N, gssettings.ndraws);
chain.Q = nan(T, N, gssettings.ndraws);
chain.shock_effects = nan(N, N, gssettings.ndraws);
chain.shock_effects1s = nan(N, N, gssettings.ndraws);
chain.shocks = nan(T, N, gssettings.ndraws);
chain.t_v = nan(N, gssettings.ndraws);
chain.accepted = 0;

nalldraws = gssettings.burnin + gssettings.ndraws*gssettings.saveevery;
fprintf('All draws: %d, burnin: %d, save every: %d, saved draws: %d\n', nalldraws, gssettings.burnin, gssettings.saveevery, gssettings.ndraws)
timing_start = datetime('now');

for draw = 1:nalldraws
    U = Y*W;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % draw Q
    % two cases: Regimes or Student-t
    if prior.t.v == 0
        % draw Q for regimes
        for r = 1:prior.regimes.num
            Ur = U(prior.regimes.ind{r},:);
            Tr = size(Ur,1);
            par1 = 0.5*(prior.regimes.v + Tr);
            par2 = 2*(prior.regimes.v + sum(Ur.^2)).^(-1);
            Qr = gamrnd(par1, par2);
            Q(prior.regimes.ind{r},:) = repmat(Qr, Tr, 1);
        end
    else
        % draw Q for Student-t
        V = repmat(t_v, T, 1);
        Q = gamrnd(0.5*(V+1), 2*(U.^2 + V).^(-1));

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % now also draw t_v
        for n = 1:N
            if isnan(prior.t.v(n))
                t_v(n) = draw_v_given_Q(Q(:,n), t_v(n), prior.t.va(n), prior.t.vb(n));
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % draw W
    [W, accepted] = draw_W_given_QYpriorw(Q, Y, W, prior.Wmean, prior.Wprec, kappa, draw_W_options);
    chain.accepted = chain.accepted + accepted;

    % after burnin 1) fix the order and signs of shocks and 2) reduce kappa
    if draw==gssettings.burnin
        %P = normalize1(inv(W), normalize.vrange, normalize.ivars);
        %W = W*P';
        kappa = 1;
    end

    % store the draw
    if draw>gssettings.burnin && ~rem(draw-gssettings.burnin, gssettings.saveevery)
        ii = (draw - gssettings.burnin)/gssettings.saveevery;
        chain.W(:,:,ii) = W;
        chain.Q(:,:,ii) = Q;
        chain.shocks(:,:,ii) = Y*W;
        chain.shock_effects(:,:,ii) = W\eye(N);
        chain.shock_effects1s(:,:,ii) = diag(std(chain.shocks(:,:,ii)))*chain.shock_effects(:,:,ii);        
        chain.t_v(:,ii) = t_v;
    end

    if draw==1000 || ~rem(draw, gssettings.reportevery)
        disp(timing_message(draw, nalldraws, timing_start))
        fprintf('Acceptance rate: %.4f\n', chain.accepted/draw)
    end

end
disp(timing_message(draw, nalldraws, timing_start))
fprintf('chain.W(1,1,end)=%f\n', chain.W(1,1,end))

%% Construct the reference point for the normalization

% Find the most pronounced mode
xdraws = reshape(chain.shock_effects, [], gssettings.ndraws)';
% Fit a Gaussian Mixture Model (GMM)
gm = fitgmdist(xdraws, 4, RegularizationValue=0.01);  % Estimate number_of_modes
% Find the component with the largest weight (most frequently visited mode)
[~, maxIdx] = max(gm.ComponentProportion);
xmode = reshape(gm.mu(maxIdx, :), N, N);

% Find the draw that was closest to the most pronounced mode
d2 = mahal(gm, xdraws);
[~, ii] = min(d2(:,maxIdx));

chain.reference_draw = ii;


%% report the chain
fprintf('Acceptance rate: %.4f\n', chain.accepted/nalldraws)
fprintf('chain.W(1,1,end)=%f\n', chain.W(1,1,end))

pos = [5, 1, 11*N^.6, 8*N^.6];
fh = figure(Units="centimeters", Position=pos);
for ss = 1:N
    for vv = 1:N
        x = squeeze(chain.W(vv, ss, :));
        subplot(N, N, sub2ind([N,N], ss, vv))
        plot(x)
        yline(chain.W(vv, ss, chain.reference_draw))
        if ss==1, ylabel(ynames{vv}, 'Interpreter', 'none', 'FontWeight', 'bold'), end
        if vv==1, title(sprintf('u%d',ss), 'FontWeight', 'bold'), end
    end
end
sgtitle("Trace plots of W")
exportgraphics(fh, pathout + "W_trace.pdf")

fh = figure(Units="centimeters", Position=pos);
for ss = 1:N
    for vv = 1:N
        x = squeeze(chain.W(vv, ss, :));
        subplot(N, N, sub2ind([N,N], ss, vv))
        autocorr(x, 'NumLags', min(100,fix(gssettings.ndraws/5)))
        ylabel(ynames{vv}, 'Interpreter', 'none', 'FontWeight', 'bold')
        title(sprintf('u%d',ss), 'FontWeight', 'bold')
    end
end
sgtitle('Autocorrelation of draws of W')

fh = figure(Units="centimeters", Position=pos);
for ss = 1:N
    for vv = 1:N
        x = squeeze(chain.W(vv, ss, :));
        subplot(N, N, sub2ind([N,N], ss, vv))
        histogram(x)
        if ss==1, ylabel(ynames{vv}, 'Interpreter', 'none', 'FontWeight', 'bold'), end
        if vv==1, title(sprintf('u%d',ss), 'FontWeight', 'bold'), end
    end
end
sgtitle("Histograms of W")
exportgraphics(fh, pathout + "W_hist.pdf")


% Heteroskedastic shocks: shock standard deviation (Q^-.5) by regime
if prior.regimes.num
    fh = figure(Units="centimeters", Position=pos);
    tiledlayout("flow")
    for n = 1:N
        nexttile
        hold on
        for r = 1:prior.regimes.num
            t1 = find(prior.regimes.ind{r},1);
            x = squeeze(chain.Q(t1,n,:).^(-0.5));
            plot(x)
        end
        legend(string(prior.regimes.names))
        title("std" + num2str(n))
    end
    exportgraphics(fh, pathout+"shock_std_trace.pdf")

    fh = figure(Units="centimeters", Position=pos);
    tiledlayout("flow")
    for n = 1:N
        nexttile
        hold on
        for r = 1:prior.regimes.num
            t1 = find(prior.regimes.ind{r},1);
            x = squeeze(chain.Q(t1,n,:).^(-0.5));
            histogram(x)
        end
        legend(string(prior.regimes.names))
        title("std" + num2str(n))
    end
    exportgraphics(fh, pathout+"shock_std_hist.pdf")
end


