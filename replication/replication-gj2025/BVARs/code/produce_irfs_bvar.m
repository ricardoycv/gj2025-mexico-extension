
function IRFs = produce_irfs_bvar(settings_bvar,varnames,data,timevec)

IRFs_point    = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname),size(settings_bvar.irfvarname,1));
IRFs_upper90  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname),size(settings_bvar.irfvarname,1));
IRFs_lower90  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname),size(settings_bvar.irfvarname,1));
IRFs_upper68  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname),size(settings_bvar.irfvarname,1));
IRFs_lower68  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname),size(settings_bvar.irfvarname,1));

% need to load shock distribution in case this is chosen for estimation
switch settings_bvar.shocks_point_vs_dist
    case 'dist'
        load([settings_bvar.W_dist.path,'\',settings_bvar.W_dist.name])
        W_posterior_dist = shock_dist.W;
    case 'point'
        W_posterior_dist = [];
end

parfor j=1:size(settings_bvar.irfvarname,1)

    addendovar  = length(setdiff(settings_bvar.irfvarname(j,1),settings_bvar.endovarname));
    yraw        = nan(size(data,1),1+size(settings_bvar.endovarname,2)+addendovar);
    for jj=1:size(settings_bvar.endovarname,2)
        yraw(:,1+jj) = data(:,strmatch(settings_bvar.endovarname(1,jj),varnames,'exact'));
    end
    if addendovar==1
        yraw(:,end) = data(:,strmatch(settings_bvar.irfvarname(j,1),varnames,'exact'));
    end
    switch settings_bvar.detspec
        case 'const'
            wraw = ones(size(yraw,1),1);
            detnum = 1;
        case 'ttrend'
            wraw = [ones(size(yraw,1),1), [1:length(yraw)]'];
            detnum = 2;
    end

    IRFs_point_temp    = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname));
    IRFs_upper90_temp  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname));
    IRFs_lower90_temp  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname));
    IRFs_upper68_temp  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname));
    IRFs_lower68_temp  = nan(settings_bvar.irfhor+1,length(settings_bvar.shockvarname));
    
    for i=1:length(settings_bvar.shockvarname)
        
        y = yraw;
        y(:,1) = data(:,strmatch(settings_bvar.shockvarname(1,i),varnames,'exact'));
        if settings_bvar.shocks_point_vs_dist=="dist"
            raw_surprises = [];
            for ii=1:size(settings_bvar.W_dist.surprname,2) 
                raw_surprises(:,ii) = data(:,strmatch(settings_bvar.W_dist.surprname(1,ii),varnames,'exact'));
            end
        end

        if settings_bvar.covid==1
            y(data(:,strmatch('coviddummy_0320',varnames,'exact'))==1,1) = 0; 
            if settings_bvar.shocks_point_vs_dist=="dist"
                raw_surprises(data(:,strmatch('coviddummy_0320',varnames,'exact'))==1,:) = 0;
            end
        end
        if settings_bvar.covidfull==1
            y(data(:,strmatch('coviddummy_full',varnames,'exact'))==1,1) = 0; 
            if settings_bvar.shocks_point_vs_dist=="dist"
                raw_surprises(data(:,strmatch('coviddummy_full',varnames,'exact'))==1,:) = 0;
            end
        end
        if settings_bvar.taptantr==1
            y(data(:,strmatch('taptantdum',varnames,'exact'))==1,1) = 0; 
            if settings_bvar.shocks_point_vs_dist=="dist"
                raw_surprises(data(:,strmatch('taptantdum',varnames,'exact'))==1,:) = 0;
            end
        end

        % Impose sample and remove missings from data
        if settings_bvar.shocks_point_vs_dist=="point"
            newData = cat(2,y,wraw);
            raw_surprises_num = 0;
        elseif settings_bvar.shocks_point_vs_dist=="dist"
            newData = cat(2,y,wraw,raw_surprises);
            raw_surprises_num = size(settings_bvar.W_dist.surprname,2) ;
        end
        earlydrop                                             = strmatch(settings_bvar.mindate,timevec,'exact');
        latedrop                                              = strmatch(settings_bvar.maxdate,timevec,'exact');
        newData([1:earlydrop-1,latedrop+1:size(newData,1)],:) = [];
        newData(any(isnan(newData),2),:)                      = [];
        y                                                     = newData(:,1:end-detnum-raw_surprises_num); % endogenous variable
        w                                                     = newData(:,end-detnum-raw_surprises_num+1:end-raw_surprises_num); % control variables and lags
        if settings_bvar.shocks_point_vs_dist=="dist"
            raw_surprises = newData(:,end-raw_surprises_num+1:end);
        end
    
        % Estimate VAR and obtain IRFs
        warning('off','all');
        switch settings_bvar.shocks_point_vs_dist
            case 'point'
                res         = VAR_dummyobsprior(y,w,settings_bvar.ndraws,settings_bvar.prior,0);
            case 'dist'
                shockmatch  = i; 
                res         = VAR_shock_dist1(y(:,2:end),w,settings_bvar.ndraws,settings_bvar.prior,raw_surprises,W_posterior_dist(:,shockmatch,:),0);
        end
        warning('on','all');
        N           = 1+size(settings_bvar.endovarname,2)+addendovar;
        irfs_draws  = NaN(N,N,settings_bvar.irfhor+1,settings_bvar.ndraws);
        for ii = 1:settings_bvar.ndraws
            betadraw             = res.beta_draws(1:end-size(w,2),:,ii);
            sigmadraw            = res.sigma_draws(:,:,ii);
            response             = impulsdtrf(reshape(betadraw',N,N,settings_bvar.prior.lags), chol(sigmadraw), settings_bvar.irfhor+1);
            irfs_draws(:,:,:,ii) = response;
        end
    
        irfpos = size(irfs_draws,1);
        if addendovar==0
            irfpos = 1+strmatch(settings_bvar.irfvarname(j,1),settings_bvar.endovarname,'exact');
        end
        IRFs_point_temp(:,i)    = squeeze(quantile(irfs_draws(irfpos,1,:,:),0.5,4));
        IRFs_upper90_temp(:,i)  = squeeze(quantile(irfs_draws(irfpos,1,:,:),0.9,4));
        IRFs_lower90_temp(:,i)  = squeeze(quantile(irfs_draws(irfpos,1,:,:),0.1,4));
        IRFs_upper68_temp(:,i)  = squeeze(quantile(irfs_draws(irfpos,1,:,:),0.68,4));
        IRFs_lower68_temp(:,i)  = squeeze(quantile(irfs_draws(irfpos,1,:,:),0.32,4));

    end

    IRFs_point(:,:,j)    = IRFs_point_temp;
    IRFs_upper90(:,:,j)  = IRFs_upper90_temp;
    IRFs_lower90(:,:,j)  = IRFs_lower90_temp;
    IRFs_upper68(:,:,j)  = IRFs_upper68_temp;
    IRFs_lower68(:,:,j)  = IRFs_lower68_temp;

end

IRFs.point   = IRFs_point;
IRFs.upper90 = IRFs_upper90;
IRFs.lower90 = IRFs_lower90;
IRFs.upper68 = IRFs_upper68;
IRFs.lower68 = IRFs_lower68;
