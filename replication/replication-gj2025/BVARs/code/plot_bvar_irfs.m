function plot_bvar_irfs(settings_bvar,IRFs,figurepath,savename)

shockvarname_num   = size(settings_bvar.shockvarname_toplot,2);
depvarnameplot_num = size(settings_bvar.irfvarname_toplot,1);
currfig            = gobjects(depvarnameplot_num,shockvarname_num);

parfor j=1:depvarnameplot_num
    
    depvarpos = strmatch(settings_bvar.irfvarname_toplot(j,1),settings_bvar.irfvarname(:,1),'exact');
    irfpoint_determine_ylims = nan(settings_bvar.irfhor_toplot+1,shockvarname_num,2);
    for s=1:shockvarname_num
        shockpos = strmatch(settings_bvar.shockvarname_toplot(1,s),settings_bvar.shockvarname,'exact');
        irfpoint_determine_ylims(:,s,1) = IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos);
        irfpoint_determine_ylims(:,s,2) = IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos);
    end
    irfpoint_determine_ylims(:,setdiff(1:shockvarname_num,settings_bvar.shocks_common_yaxis),:) = NaN;
    ylims_common = [min(min(irfpoint_determine_ylims(:,:,1)))-0.1*abs(min(min(irfpoint_determine_ylims(:,:,1))));max(max(irfpoint_determine_ylims(:,:,2)))+0.1*abs(max(max(irfpoint_determine_ylims(:,:,2))))];

    for s=1:shockvarname_num
        
        shockpos = strmatch(settings_bvar.shockvarname_toplot(1,s),settings_bvar.shockvarname,'exact');
        % currfig(j,s) = figure('Position', [200 200 525 300], 'Visible', 'on');
        currfig(j,s) = figure('Position', [200 200 525 300], 'Visible', 'off');
        FaceAlphaValue = 0.2;
        steps = 0:settings_bvar.irfhor_toplot;
        patch([steps fliplr(steps)],[IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos)' flipud(IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos))'],'b','FaceAlpha',FaceAlphaValue-0.1,'EdgeColor','none')
        patch([steps fliplr(steps)],[IRFs.lower68(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos)' flipud(IRFs.upper68(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos))'],'b','FaceAlpha',FaceAlphaValue,'EdgeColor','none')
        hold on
        plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos),'k','LineWidth',2)
        hold on
        plot(0:settings_bvar.irfhor_toplot,zeros(settings_bvar.irfhor_toplot+1,1),'k','LineWidth',1)
        box off
        xlim([0 settings_bvar.irfhor_toplot])
        ylim(ylims_common)
        set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
        if s==1
            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
            exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',settings_bvar.irfvarname{depvarpos,1},'_',settings_bvar.shockvarname{shockpos}),'_novartitle_',savename,'.pdf']);
            ylabel(settings_bvar.irfvarname(depvarpos,2),'Interpreter','Latex','fontsize',22)
        else
            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
            ylabel(settings_bvar.irfvarname(depvarpos,2),'Interpreter','Latex','fontsize',22)
            exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',settings_bvar.irfvarname{depvarpos,1},'_',settings_bvar.shockvarname{shockpos}),'_vartitle_',savename,'.pdf']);
            ylabel('')
            set(gca,'fontsize',16,'ytick',[],'yticklabel',[],'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
        end
        exportgraphics(gca,[figurepath,strcat('\irf_bvar_',settings_bvar.irfvarname{depvarpos,1},'_',settings_bvar.shockvarname{shockpos}),'_',savename,'.pdf']);
        close

    end
end
