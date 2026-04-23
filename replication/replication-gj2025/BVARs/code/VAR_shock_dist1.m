function result = VAR_shock_dist1(y_fixed, w, n_draws, info, m, WWW, varargin)
% PURPOSE: Simulate the posterior distribution of the VAR parameters with Sims'
% style dummy observation prior. The function is based on VAR_dummyobsprior.m,
% see there for the detailed documentation of the inputs and the outputs.
% The present function is adapted to the case where the first variable(s)
% in the VAR is a generated regressor and has a distribution. The draws from
% this distribution are obtained as m*WWW(:,:,i) where i is the draw number.
% Conditionally on each draw of the generated regressor the function draws
% the parameters of the VAR and stores them in
% result.beta_draws - draws of the VAR coefficients,
% result.sigma_draws - draws of the innovation variance-covariance matrix.

[Tm, Nm] = size(m);
[~, Nshocks, ndrawsW] = size(WWW);
% Baseline y for the Minnesota/Sims prior construction
y = [m*mean(WWW,3), y_fixed];

[T,N] = size(y); % T is the length of the whole sample (including initial observations)
P = info.lags;
T = T-P; % now T is the length of the effective sample
K = P*N+size(w,2); % number of columns in X

% verbosity = 1;
if isempty(varargin)
    verbosity = 1;
else
    verbosity = varargin{1};
end
if verbosity
    disp(' ')
    disp('VAR_shock_dist')
    disp(['lags: ' num2str(info.lags)])
    disp("draws of W: " + ndrawsW)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRUCTION OF Yprior, Xprior, vprior FROM THE SUPPLIED info

% If Yprior, Xprior, vprior constructed outside of this function are
% supplied, then just copy the values.
% If not, then build Yprior, Xprior, vprior from the supplied
% hyperparameters.
if isfield(info,'dummyobs') % used supplied values
    Yprior = info.dummyobs.Y;
    Xprior = info.dummyobs.X;
    vprior = info.dummyobs.v;
else % build Yprior, Xprior, vprior from hyperparameters
    Yprior = [];
    Xprior = [];

    % Minnesota prior
    if isfield(info,'minnesota') && isfield(info.minnesota,'tightness')
        % default values if something not supplied
        if ~isfield(info.minnesota,'exog_std')
            info.minnesota.exog_std = 1e5;
        end
        if ~isfield(info.minnesota,'decay')
            info.minnesota.decay = 1;
        end

        if ~isfield(info.minnesota,'sigma')
            % compute sigma = standard errors from univariate autoregressions
            if ~isfield(info.minnesota,'sigma_data')
                % sigma is computed from univariate autoregressions on sigma_data
                % default: sigma_data is identical to the actual sample
                info.minnesota.sigma_data = y;
            end
            info.minnesota.sigma = zeros(1,N);
            if ~isfield(info.minnesota,'sigma_arlags')
                info.minnesota.sigma_arlags = ...
                    max(0,min(P, size(info.minnesota.sigma_data,1)-3)); 
                % when a very short sample is supplied use fewer lags
            end
            for n = 1:N
                yn = info.minnesota.sigma_data(:,n);
                [yn, ylagsn] = varlags(yn,info.minnesota.sigma_arlags);
                Xn = [ylagsn ones(size(yn))];
                bn = Xn \ yn;
                info.minnesota.sigma(n) = std(yn - Xn*bn);
            end
        end
        if isfield(info.minnesota,'sigma_factor')
            info.minnesota.sigma = info.minnesota.sigma .* info.minnesota.sigma_factor;
        end

        % prior for the coefficients
        % p(B|Sigma) = N(B0,Sigma ** Q )
        % decompose Q = W*W'
        % to implement the prior need dummy observations with
        % Yd = inv(W)*B0      Xd = inv(W)
        if ~isinf(info.minnesota.tightness)
            Winv = (1:P).^info.minnesota.decay;
            Winv = kron(Winv, info.minnesota.sigma ./ info.minnesota.tightness);
            Winv = [Winv, info.minnesota.exog_std^(-1)*ones(1,size(w,2)) ];
            Winv = diag(Winv);

            B0 = zeros(K,N);
            if ~isfield(info.minnesota,'mvector')
                info.minnesota.mvector = ones(1,N);
            elseif (length(info.minnesota.mvector) > N)
                warning('Minnesota prior: mvector too long, truncating'); %#ok<WNTAG>
            end
            B0(1:N,1:N) = diag(info.minnesota.mvector(1:N));

            Yprior = [Yprior; Winv*B0];
            Xprior = [Xprior; Winv];
        end
        
        % prior for the variance
        % p(Sigma) = IW(Sprior,vprior)
        % decompose Sprior = Z*Z'
        % to implement the prior need dummy observations with
        % Yd = Z'   Xd = 0
        % plus an improper prior
        % p(Sigma) = |Sigma|^-0.5(vprior+1)

        % default: vprior = N + 2
        if ~isfield(info.minnesota,'sigma_deg') 
            info.minnesota.sigma_deg = N + 2;
        end

        % Z = diag(sigma)*sqrt(vprior - N - 1)
        % this choice of Z ensures that 
        % E(Sigma) = Z*Z' / (vprior - N - 1) = diag(sigma.^2)
        if info.minnesota.sigma_deg == N + 1
            YSigma = diag(info.minnesota.sigma);
        else
            YSigma = diag(info.minnesota.sigma*sqrt(info.minnesota.sigma_deg - N - 1));
        end
        
        % if sigma_omega is specified, then override sigma_deg and YSigma
        % with the Dynare-style specification
        if isfield(info.minnesota,'sigma_omega')
            info.minnesota.sigma_deg = N*info.minnesota.sigma_omega + N;
            YSigma = diag(info.minnesota.sigma*sqrt(info.minnesota.sigma_omega));
        end

        Yprior = [Yprior; YSigma];
        Xprior = [Xprior; zeros(N,K)];

        if verbosity
            disp('Minnesota prior');
            disp(['Note: for a proper prior need sigma_deg > ' num2str(N-1)])
            disp(['Note: for E(Sigma) to exist need sigma_deg > ' num2str(N+1)])
            disp(info.minnesota)
        end
    end

    % Sims' dummy observations
    if isfield(info,'simsdummy')
        ybar = mean(y(1:P,:),1);
        if isfield(info.simsdummy,'oneunitroot') && info.simsdummy.oneunitroot>0
            Xprior = [Xprior; repmat(ybar,1,P)*info.simsdummy.oneunitroot, info.simsdummy.oneunitroot*w(P,:)];
            Yprior = [Yprior; ybar*info.simsdummy.oneunitroot];
        end
        if isfield(info.simsdummy,'oneunitrootc') && info.simsdummy.oneunitrootc>0
            Xprior = [Xprior; zeros(1,P*N) info.simsdummy.oneunitrootc*w(P,:)];
            Yprior = [Yprior; zeros(1,N)];
        end
        if isfield(info.simsdummy,'oneunitrooty') && info.simsdummy.oneunitrooty>0
            Xprior = [Xprior; repmat(ybar,1,P)*info.simsdummy.oneunitrooty 0*w(P,:)];
            Yprior = [Yprior; ybar*info.simsdummy.oneunitrooty];
        end
        if isfield(info.simsdummy,'nocointegration') && info.simsdummy.nocointegration(1)>0                
            temp = diag(ybar.*info.simsdummy.nocointegration);
            if isfield(info,'minnesota') && isfield(info.minnesota,'mvector')
                temp = temp(logical(info.minnesota.mvector),:);
            end
            Xprior = [Xprior; repmat(temp,1,P) zeros(size(temp,1),size(w,2))];
            Yprior = [Yprior; temp];
        end
        if verbosity
            disp('Sims dummy prior')
            disp(info.simsdummy)
        end
    end
    
    % determine the prior degrees of freedom of Sigma (vprior)
    if isfield(info,'minnesota')
        vprior = info.minnesota.sigma_deg;
    else
        % when no Minnesota prior, then 
        % a) assume the noninformative prior |Sigma|^-(N+1)/2
        % b) treat Sims dummy obs, if any, as a training sample
        vprior = size(Yprior,1) - K; % note that we lose K degrees of freedom because of B
    end
end

% add training sample prior
if isfield(info,'trspl') && numel(info.trspl)>0
    for i = 1:numel(info.trspl)
        if isfield(info.trspl(i),'y') && isfield(info.trspl(i),'Tsubj') && info.trspl(i).Tsubj>0
            [Ytr, Xtr] = varlags(info.trspl(i).y, P);
            Xtr = [Xtr info.trspl(i).w(P+1:end,:)]; % add the exogenous variable
            Ytr = Ytr * sqrt(info.trspl(i).Tsubj / size(Ytr,1)); % scaling
            Xtr = Xtr * sqrt(info.trspl(i).Tsubj / size(Ytr,1)); % scaling
            % add the training sample info to vprior, Yprior, Xprior
            vprior = vprior + info.trspl(i).Tsubj;
            Yprior = [Yprior; Ytr];
            Xprior = [Xprior; Xtr];
            if verbosity
                disp('Training sample prior');
                disp(info.trspl(i))
            end
        end
    end
end

% store the names of the variables if supplied
if isfield(info,'ynames'), result.ynames = info.ynames; end

% store the dummy observations
result.prior.info = info;
result.prior.Yprior = Yprior;
result.prior.Xprior = Xprior;
result.prior.vprior = vprior;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POSTERIOR SIMULATION

df = round(T + vprior); % posterior degrees of freedom
% allocate space for the posterior draws
result.beta_draws = nan(K,N,n_draws);
result.sigma_draws = nan(N,N,n_draws);

for draw = 1:n_draws
    % draw m
    y_draw = [m*WWW(:,:,randi(ndrawsW)) y_fixed];
    % data matrices
    [Y,X] = varlags(y_draw,P);
    X = [X w(P+1:end,:)]; % add the exogenous variables
    % stacked data
    Yst = [Yprior; Y];
    Xst = [Xprior; X];
    % parameters of the posterior
    Bst = Xst\Yst;
    Ust = Yst - Xst*Bst;
    Sst = Ust'*Ust;
    Sst_chol = chol(Sst)';
    XtXstinv_chol = chol((Xst'*Xst)\eye(K))';
    % draw Sigma from IW(Sst, df)
    temp = randn(df, N);
    Sigma_draw = Sst_chol/(temp'*temp)*Sst_chol';
    % draw B from N(Bst, kron(Sigma_draw, XtXst))
    B_draw = Bst + XtXstinv_chol*randn(K,N)*chol(Sigma_draw);
    % store
    result.beta_draws(:,:,draw) = B_draw;
    result.sigma_draws(:,:,draw) = Sigma_draw;
end

end % of VAR_dummyobsprior


% SUBFUNCTIONS
function [ynew,ylags] = varlags(y,P)
[T,N] = size(y);
ynew = y(P+1:end,:);
ylags = zeros(T-P,P*N);
for p = 1:P
    ylags(:,N*(p-1)+1:N*p) = y(P+1-p:T-p,:);
end
end

