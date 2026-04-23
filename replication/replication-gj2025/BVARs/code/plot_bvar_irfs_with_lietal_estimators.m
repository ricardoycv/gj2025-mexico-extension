
function plot_bvar_irfs_with_lietal_estimators(settings_bvar,generalpath,figurepath,varnames,data,timevec,depvarname_lietal,IRFs,savename)

% Estimation using Li, Plagborg-Moller and Wolf replication files (BVAR, VAR, BCVAR, LP, SLP)
eval(['cd ''',strcat(generalpath,'\Matlab subroutines\Estimation routines Li et al\'),''''])
settings_lietal.mindate = settings_bvar.mindate;
settings_lietal.maxdate = settings_bvar.maxdate;
% settings are taken from https://github.com/dake-li/lp_var_simul/blob/master/DFM/Settings/shared.m
% shared settings
settings_lietal_shockvarname = settings_bvar.shockvarname;
settings_lietal_depvarname   = depvarname_lietal;
settings_lietal_estimmethods = [{'VAR'},{'SLP'};... %,{'BVAR'},{'BCLP'},{'BCVAR'}
                                {'OLS VAR'},{'SLP'}]; %,{'BVAR'},{'BC-LP'},{'BC-VAR'}

for k=1:length(settings_lietal_estimmethods)
    eval(['IRFs_lietal_',settings_lietal_estimmethods{1,k},' = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname),length(settings_lietal_depvarname));'])
end

parfor k=1:length(settings_lietal_depvarname)

    % This is done here in order to make a parfor loop possible with structures
    settings_lietal                                    = struct();
    settings_lietal.mindate                            = settings_bvar.mindate;
    settings_lietal.maxdate                            = settings_bvar.maxdate;
    settings_lietal.est                                = struct();
    settings_lietal.est.IRF_hor                        = settings_bvar.irfhor+1;
    settings_lietal.est.n_lags_max                     = 12; %max(settings_bvar.P_own,settings_bvar.P_controls); % maximaum lags to be considered for optimal lag length selection
    settings_lietal.est.est_n_lag                      = 1; % estimate optimal lag order?
    settings_lietal.est.est_n_lag_BIC                  = 0; % if optimal lag is determined, use BIC?
    settings_lietal.est.n_lags_fix                     = 12; % 3; %max(settings_bvar.P_own,settings_bvar.P_controls); % if optimal lag order is not selected, how many lags to include?
    settings_lietal.est.est_normalize_var_pos          = NaN; %strmatch('tb_rate_1y_eop',controlsname,'exact');
    settings_lietal.est.with_shock                     = 1;
    settings_lietal.est.recursive_shock                = NaN;
    settings_lietal.est.with_IV                        = 0;
    settings_lietal.est.normalize_with_shock_std_dev   = 1;

    IRFs_lietal_LP_temp    = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname));
    IRFs_lietal_BCLP_temp  = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname));
    IRFs_lietal_SLP_temp   = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname));
    IRFs_lietal_VAR_temp   = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname));
    IRFs_lietal_BCVAR_temp = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname));
    IRFs_lietal_BVAR_temp  = nan(settings_bvar.irfhor+1,length(settings_lietal_shockvarname));

    settings_lietal_controlsname_temp = settings_bvar.endovarname;
    if strmatch(settings_lietal_depvarname{k,1},settings_lietal_controlsname_temp,'exact')
        settings_lietal_controlsname_temp(:,strmatch(settings_lietal_depvarname{k,1},settings_lietal_controlsname_temp,'exact')) = [];
    end
    settings_lietal.est.IRF_response_var_pos = length(settings_lietal_controlsname_temp)+1;

    for j=1:length(settings_lietal_shockvarname)

        data_sim = struct();
        data_sim.data_shock = data(:,strmatch(settings_lietal_shockvarname{1,j},varnames,'exact'));
        if settings_bvar.covid==1
            data_sim.data_shock(data(:,strmatch('coviddummy_0320',varnames,'exact'))==1,1) = 0; %  | data(:,strmatch('coviddummy_0420',varnames,'exact'))==1
        end
        if settings_bvar.taptantr==1
            data_sim.data_shock(data(:,strmatch('taptantdum',varnames,'exact'))==1,1) = 0; 
        end
        data_sim.data_y     = nan(size(data,1),length(settings_lietal_controlsname_temp)+1);
        for s=1:length(settings_lietal_controlsname_temp)
            data_sim.data_y(:,s) = data(:,strmatch(settings_lietal_controlsname_temp{s},varnames,'exact'));
        end
        data_sim.data_y(:,end) = data(:,strmatch(settings_lietal_depvarname{k,1},varnames,'exact'));
        % Impose sample
        earlydrop = strmatch(settings_lietal.mindate,timevec,'exact');
        latedrop  = strmatch(settings_lietal.maxdate,timevec,'exact');
        data_sim.data_shock([1:earlydrop-1,latedrop+1:size(data_sim.data_shock,1)],:) = [];
        data_sim.data_y([1:earlydrop-1,latedrop+1:size(data_sim.data_y,1)],:)         = [];
        
        if ~isempty(strmatch('LP',settings_lietal_estimmethods(1,:),'exact'))
            % OLS local projections
            bias_corrected                                     = 0;
            IRF_lp = LP_est(data_sim,settings_lietal,bias_corrected);
            IRFs_lietal_LP_temp(:,j) = IRF_lp;
        end

        if ~isempty(strmatch('BCLP',settings_lietal_estimmethods(1,:),'exact'))
            % Herbst-Johansen bias-corrected local projections
            settings_lietal.est.est_n_lag                      = 1; % estimate optimal lag order?
            settings_lietal.est.est_n_lag_BIC                  = 0; % if optimal lag is determined, use BIC?
            settings_lietal.est.n_lags_fix                     = 3; %max(settings_bvar.P_own,settings_bvar.P_controls); % if optimal lag order is not selected, how many lags to include?
            bias_corrected                                     = 1;
            IRF_lp = LP_est(data_sim,settings_lietal,bias_corrected);
            IRFs_lietal_BCLP_temp(:,j) = IRF_lp;
        end

        if ~isempty(strmatch('SLP',settings_lietal_estimmethods(1,:),'exact'))
            % Smooth LPs
            settings_lietal.est.lambdaRange     = [0.001:0.005:0.021, 0.05:0.1:1.05, 2:1:19, 20:20:100, 200:200:2000]; % cross validation grid, scaled up by T
            settings_lietal.est.irfLimitOrder   = 2;
            settings_lietal.est.CV_folds        = 5;
            addpath(strcat(generalpath,'\Matlab subroutines\Estimation routines Li et al\LP_Penalize'))
            IRF_slp = LP_shrink_est(data_sim,settings_lietal);
            IRFs_lietal_SLP_temp(:,j) = IRF_slp;
            rmpath(strcat(generalpath,'\Matlab subroutines\Estimation routines Li et al\LP_Penalize'))
        end

        if ~isempty(strmatch('VAR',settings_lietal_estimmethods(1,:),'exact'))
            % OLS VAR
            bias_corrected_lietal                   = 0;
            settings_lietal.est.res_autocorr_nlags  = 2;
            IRF_var = SVAR_est(data_sim,settings_lietal,bias_corrected_lietal);
            IRFs_lietal_VAR_temp(:,j) = IRF_var;
        end

        if ~isempty(strmatch('BCVAR',settings_lietal_estimmethods(1,:),'exact'))
            % Bias-corrected OLS VAR
            bias_corrected_lietal = 1;
            IRF_bcvar = SVAR_est(data_sim,settings_lietal,bias_corrected_lietal);
            IRFs_lietal_BCVAR_temp(:,j) = IRF_bcvar;
        end

        if ~isempty(strmatch('BVAR',settings_lietal_estimmethods(1,:),'exact'))
            % Bayesian VAR
            settings_lietal.est.posterior_ndraw = 100;
            settings_lietal.est.prior.towards_random_walk = 0;
            settings_lietal.est.prior.tight_overall = 0.04;
            settings_lietal.est.prior.tight_nonown_lag = 0.25;
            settings_lietal.est.prior.decay_power = 2;
            settings_lietal.est.prior.tight_exogenous = 1e5;
            IRF_bvar = BVAR_est(data_sim,settings_lietal);
            IRFs_lietal_BVAR_temp(:,j) = IRF_bvar;
        end

    end

    IRFs_lietal_LP(:,:,k)    = IRFs_lietal_LP_temp;
    IRFs_lietal_BCLP(:,:,k)  = IRFs_lietal_BCLP_temp;
    IRFs_lietal_SLP(:,:,k)   = IRFs_lietal_SLP_temp;
    IRFs_lietal_VAR(:,:,k)   = IRFs_lietal_VAR_temp;
    IRFs_lietal_BCVAR(:,:,k) = IRFs_lietal_BCVAR_temp;
    IRFs_lietal_BVAR(:,:,k)  = IRFs_lietal_BVAR_temp;

end
for k=1:length(settings_lietal_estimmethods)
    eval(['IRFs_lietal.',settings_lietal_estimmethods{1,k},' = IRFs_lietal_',settings_lietal_estimmethods{1,k},';'])
end
% eval(['cd ''',strcat(generalpath,'\'),''''])
% save(strcat(generalpath,'\temp\smoothed_lps_lietal.mat'),'IRFs_lietal','settings_lietal')


for k=1:length(settings_lietal_depvarname)

    depvarname_baseline_pos = strmatch(settings_lietal_depvarname{k,1},settings_bvar.irfvarname(:,1),'exact');
    if isempty(depvarname_baseline_pos)
        error(['No IRFs for ''', settings_lietal_depvarname{k,1},''' estimated in the baseline'])
    end

    irfpoint_determine_ylims = nan((2+length(settings_lietal_estimmethods))*(settings_bvar.irfhor_toplot+1),size(settings_lietal_shockvarname,2));
    for j=1:size(settings_lietal_shockvarname,2)
        shockvarvarname_baseline_pos = strmatch(settings_lietal_shockvarname{j},settings_bvar.shockvarname,'exact');
        irfpoint_determine_ylims(1:2*(settings_bvar.irfhor_toplot+1),j) = [IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos);...
            IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos)];
        for s=1:length(settings_lietal_estimmethods)
            eval(['irfpoint_determine_ylims((2+s-1)*(settings_bvar.irfhor_toplot+1)+1:(2+s)*(settings_bvar.irfhor_toplot+1),j) = IRFs_lietal_',settings_lietal_estimmethods{1,s},'(1:settings_bvar.irfhor_toplot+1,j,k);'])
        end
    end
    irfpoint_determine_ylims(:,setdiff(1:size(settings_lietal_shockvarname,2),settings_bvar.shocks_common_yaxis),:) = NaN;
    ylims_common = [min(min(irfpoint_determine_ylims))-0.1*abs(min(min(irfpoint_determine_ylims)));max(max(irfpoint_determine_ylims))+0.1*abs(max(max(irfpoint_determine_ylims)))];

    for j=1:length(settings_lietal_shockvarname)
        shockvarvarname_baseline_pos = strmatch(settings_lietal_shockvarname{j},settings_bvar.shockvarname,'exact');

        if ~isempty(depvarname_baseline_pos)
            figure('Position', [200 200 525 300], 'Visible', 'off');
            FaceAlphaValue = 0.2;
            steps = 0:settings_bvar.irfhor_toplot;
            patch([steps fliplr(steps)],[IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos)' flipud(IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos))'],'b','FaceAlpha',FaceAlphaValue-0.1,'EdgeColor','none')
            patch([steps fliplr(steps)],[IRFs.lower68(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos)' flipud(IRFs.upper68(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos))'],'b','FaceAlpha',FaceAlphaValue,'EdgeColor','none')
            hold on
            l1 = plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos),'k','LineWidth',3,'DisplayName','Baseline SLP');
            hold on
            linespecvec  = [{'-o'},{'-s'},{'-v'},{'-x'},{'-+'}];
            colorspecmat = [[0.8500 0.3250 0.0980]; [0 0.4470 0.7410]; [0.4940 0.1840 0.5560]; [0.4660 0.6740 0.1880]; [0.9290 0.6940 0.1250]];
            legendvec = '[';
            for s=1:length(settings_lietal_estimmethods)
                eval(['l',num2str(s+1),'= plot(0:settings_bvar.irfhor_toplot,IRFs_lietal_',settings_lietal_estimmethods{1,s},'(1:settings_bvar.irfhor_toplot+1,j,k),''',linespecvec{1,s},''',''LineWidth'',1.5,''Color'',[',num2str(colorspecmat(s,:)),'],''MarkerEdgeColor'',[',num2str(colorspecmat(s,:)),'],''DisplayName'',''',settings_lietal_estimmethods{2,s},''');'])
                eval(['l',num2str(s+1),'(1).MarkerSize=3;']);
                legendvec = strcat(legendvec,' l',num2str(s));
            end
            legendvec = strcat(legendvec,']');
            l7 = plot(0:settings_bvar.irfhor_toplot,zeros(settings_bvar.irfhor_toplot+1,1),'k','LineWidth',1);
            box off
            xlim([0 settings_bvar.irfhor_toplot])
            ylim(ylims_common)

            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
            if j==1
                set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
                exportgraphics(gca,[strcat(figurepath,'\irf_complietal_',settings_lietal_depvarname{k,1},'_',settings_lietal_shockvarname{j}),'_novartitle_',savename,'.pdf']);
                ylabel(settings_lietal_depvarname(k,2),'Interpreter','Latex','fontsize',22)
            else
                set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
                ylabel(settings_lietal_depvarname(k,2),'Interpreter','Latex','fontsize',22)
                exportgraphics(gca,[strcat(figurepath,'\irf_complietal_',settings_lietal_depvarname{k,1},'_',settings_lietal_shockvarname{j}),'_vartitle_',savename,'.pdf']);
                ylabel('')
                set(gca,'fontsize',16,'ytick',[],'yticklabel',[],'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
            end
            exportgraphics(gca,[strcat(figurepath,'\irf_complietal_',settings_lietal_depvarname{k,1},'_',settings_lietal_shockvarname{j}),'_',savename,'.pdf']);

            hleg = legend('location','best');
            eval(['legend(',legendvec,',''location'',''best'');'])
            hleg = legend('boxoff');
            title(['Response of ',settings_lietal_depvarname{k,2},' to ',settings_lietal_shockvarname{j}])
            close

            % Draw legend
            if k==1 && j==1
                figure('Position', [200 200 525 300], 'Visible', 'off');
                b(1) = plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockvarvarname_baseline_pos,depvarname_baseline_pos),'k','LineWidth',3,'DisplayName','Baseline SLP');
                legendstring = 'Baseline';
                lspeccounter = 1;
                for s=1:size(settings_lietal_estimmethods,2)
                    hold on
                    eval(['b(',num2str(s+1),')= plot(0:settings_bvar.irfhor_toplot,IRFs_lietal_',settings_lietal_estimmethods{1,s},'(1:settings_bvar.irfhor_toplot+1,j,k),''',linespecvec{1,s},''',''LineWidth'',1.5,''Color'',[',num2str(colorspecmat(s,:)),'],''MarkerEdgeColor'',[',num2str(colorspecmat(s,:)),'],''DisplayName'',''',settings_lietal_estimmethods{2,s},''');'])
                    eval(['b(',num2str(s+1),').MarkerSize=3;']);
                    lspeccounter = lspeccounter + 1;
                    eval(['legendstring = [legendstring, settings_lietal_estimmethods(2,s)];'])
                end
                legend(b(1:lspeccounter),legendstring,'Location','SouthOutside', 'EdgeColor',[0.999999 0.999999 0.999999],'FontSize',10,'Orientation','horizontal','NumColumns',1+size(settings_lietal_estimmethods,2));
                exportgraphics(gca,[figurepath,strcat('\irf_litetalirfs_legend_',savename,'.pdf')]);
            end

        end
    end
end

eval(['cd ''',strcat(generalpath,'\'),''''])

