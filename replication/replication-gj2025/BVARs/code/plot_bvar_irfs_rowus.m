
function plot_bvar_irfs_rowus(settings_bvar,depvarname_rowus,IRFs,figurepath,savename)

currfig          = gobjects(size(depvarname_rowus,1),size(settings_bvar.shockvarname,2));
shockvarname_num = size(settings_bvar.shockvarname_toplot,2);
steps            = 0:settings_bvar.irfhor_toplot;

parfor j=1:size(depvarname_rowus,1)
    
    depvarpos_row = strmatch(depvarname_rowus(j,1),settings_bvar.irfvarname,'exact');
    depvarpos_us  = strmatch(depvarname_rowus(j,2),settings_bvar.irfvarname,'exact');
       
    irfpoint_determine_ylims = nan(settings_bvar.irfhor_toplot+1,2*size(settings_bvar.shockvarname,2),2);
    for s=1:shockvarname_num
        shockpos = strmatch(settings_bvar.shockvarname_toplot(1,s),settings_bvar.shockvarname,'exact');
        irfpoint_determine_ylims(:,[s, size(settings_bvar.shockvarname,2)+s],1) = [IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row), IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_us)];
        irfpoint_determine_ylims(:,[s, size(settings_bvar.shockvarname,2)+s],2) = [IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row), IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_us)];
    end
    irfpoint_determine_ylims(:,setdiff(1:shockvarname_num,settings_bvar.shocks_common_yaxis),:) = NaN;
    ylims_common = [min(min(irfpoint_determine_ylims(:,:,1)))-0.1*abs(min(min(irfpoint_determine_ylims(:,:,1))));max(max(irfpoint_determine_ylims(:,:,2)))+0.1*abs(max(max(irfpoint_determine_ylims(:,:,2))))];

    for s=1:shockvarname_num
        shockpos = strmatch(settings_bvar.shockvarname_toplot(1,s),settings_bvar.shockvarname,'exact');
                currfig(j,s) = figure('Position', [200 200 525 300], 'Visible', 'on');
        % currfig(j,s) = figure('Position', [200 200 525 300], 'Visible', 'off');
        FaceAlphaValue = 0.2;
        patch([steps fliplr(steps)],[IRFs.lower90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row)' flipud(IRFs.upper90(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row))'],'b','FaceAlpha',FaceAlphaValue-0.1,'EdgeColor','none')
        patch([steps fliplr(steps)],[IRFs.lower68(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row)' flipud(IRFs.upper68(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row))'],'b','FaceAlpha',FaceAlphaValue,'EdgeColor','none')
        hold on
        plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row),'k','LineWidth',3)
        hold on
        hl = plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_us),'-s','Color',[0.466 0.674 0.188],'LineWidth',1.5,'MarkerEdgeColor',[0.466 0.674 0.188]);
        hl(1).MarkerSize=4;
        hold on
        plot(0:settings_bvar.irfhor_toplot,zeros(settings_bvar.irfhor_toplot+1,1),'k','LineWidth',1)
        box off
        xlim([0 settings_bvar.irfhor_toplot])
        ylim(ylims_common)
        set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
        if s==1
            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
            exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',depvarname_rowus{j,4},'_',settings_bvar.shockvarname{shockpos}),'_rowus_novartitle_',savename,'.pdf']);
            ylabel(depvarname_rowus{j,3},'Interpreter','Latex','fontsize',22)
        else
            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
            ylabel(depvarname_rowus{j,3},'Interpreter','Latex','fontsize',22)
            exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',depvarname_rowus{j,4},'_',settings_bvar.shockvarname{shockpos}),'_rowus_vartitle_',savename,'.pdf']);
            ylabel('')
            set(gca,'fontsize',16,'ytick',[],'yticklabel',[],'xtick',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar.irfhor_toplot/3):settings_bvar.irfhor_toplot])
        end
        exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',depvarname_rowus{j,4},'_',settings_bvar.shockvarname{shockpos}),'_rowus_',savename,'.pdf']);
        close

        % Draw legend
        if s==1 && j==1
            figure('Position', [200 200 525 300], 'Visible', 'off');
            b1 = plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_row),'k','LineWidth',3);
            hold on
            b2 = plot(0:settings_bvar.irfhor_toplot,IRFs.point(1:settings_bvar.irfhor_toplot+1,shockpos,depvarpos_us),'-s','Color',[0.466 0.674 0.188],'LineWidth',1.5,'MarkerEdgeColor',[0.466 0.674 0.188]);
            legend([b1,b2],{'RoW','US'},'Location','SouthOutside','EdgeColor',[0.999999 0.999999 0.999999],'FontSize',10,'Orientation','horizontal','NumColumns',2);
            exportgraphics(gca,[figurepath,strcat('\irf_row_us_legend_',savename,'.pdf')]);
            close
        end
        
    end

end
