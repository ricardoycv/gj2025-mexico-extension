function plot_bvar_irfs_altspec_compar(settings_bvar_baseline_altspecs,Alt_collection,figurepath,savename)

shockvarname_num   = size(settings_bvar_baseline_altspecs.shockvarname_toplot,2);
depvarnameplot_num = size(settings_bvar_baseline_altspecs.irfvarname_toplot,1);
currfig            = gobjects(depvarnameplot_num,shockvarname_num);
altspecs           = fieldnames(Alt_collection.IRFs);
altspecs_num       = length(altspecs);
linespecvec        = [{'r-o'},{'b-s'},{'m-x'},{'g-v'},{'r -+'},{'b-v'}];


for j=1:depvarnameplot_num
    
    irfpoint_determine_ylims = nan(settings_bvar_baseline_altspecs.irfhor_toplot+1,shockvarname_num,2);
    for s=1:shockvarname_num
        irfpoint_determine_ylims(:,s,1) = Alt_collection.IRFs.baseline.lower90(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j);
        irfpoint_determine_ylims(:,s,2) = Alt_collection.IRFs.baseline.upper90(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j);
    end
    irfpoint_determine_ylims(:,setdiff(1:shockvarname_num,settings_bvar_baseline_altspecs.shocks_common_yaxis),:) = NaN;
    ylims_common = [min(min(irfpoint_determine_ylims(:,:,1)))-0.1*abs(min(min(irfpoint_determine_ylims(:,:,1))));max(max(irfpoint_determine_ylims(:,:,2)))+0.1*abs(max(max(irfpoint_determine_ylims(:,:,2))))];

    for s=1:shockvarname_num

        % currfig(j,s) = figure('Position', [200 200 525 300], 'Visible', 'on');
        currfig(j,s) = figure('Position', [200 200 525 300], 'Visible', 'off');
        FaceAlphaValue = 0.2;
        steps = 0:settings_bvar_baseline_altspecs.irfhor_toplot;
        patch([steps fliplr(steps)],[Alt_collection.IRFs.baseline.lower90(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j)' flipud(Alt_collection.IRFs.baseline.upper90(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j))'],'b','FaceAlpha',FaceAlphaValue-0.1,'EdgeColor','none')
        patch([steps fliplr(steps)],[Alt_collection.IRFs.baseline.lower68(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j)' flipud(Alt_collection.IRFs.baseline.upper68(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j))'],'b','FaceAlpha',FaceAlphaValue,'EdgeColor','none')
        hold on
        plot(0:settings_bvar_baseline_altspecs.irfhor_toplot,Alt_collection.IRFs.baseline.point(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j),'k','LineWidth',3)
        hold on
        plot(0:settings_bvar_baseline_altspecs.irfhor_toplot,zeros(settings_bvar_baseline_altspecs.irfhor_toplot+1,1),'k','LineWidth',1)
        box off
        xlim([0 settings_bvar_baseline_altspecs.irfhor_toplot])
        ylim(ylims_common)
        set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot])
        %         title(settings_bvar_baseline_altspecs.irfvarname(j,2),'Interpreter','Latex','fontsize',22)
        
        lspeccounter = 1;
        for k=1:altspecs_num
            hold on
            eval(['currspec = altspecs{k};'])
            if strcmp(currspec,'baseline')==0
                eval(['currirf = Alt_collection.IRFs.',currspec,'.point(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j);'])
                hl = plot(0:settings_bvar_baseline_altspecs.irfhor_toplot,currirf,linespecvec{1,lspeccounter},'LineWidth',1.5);
                hl(1).MarkerSize=3;
            lspeccounter = lspeccounter + 1;
            end
        end


        if s==1
            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot])
            exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',settings_bvar_baseline_altspecs.irfvarname{j,1},'_',settings_bvar_baseline_altspecs.shockvarname{s}),'_novartitle_',savename,'.pdf']);
            ylabel(settings_bvar_baseline_altspecs.irfvarname(j,2),'Interpreter','Latex','fontsize',22)
        else
            set(gca,'fontsize',16,'xtick',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot])
            ylabel(settings_bvar_baseline_altspecs.irfvarname(j,2),'Interpreter','Latex','fontsize',22)
            exportgraphics(currfig(j,s),[figurepath,strcat('\irf_bvar_',settings_bvar_baseline_altspecs.irfvarname{j,1},'_',settings_bvar_baseline_altspecs.shockvarname{s}),'_',savename,'_vartitle.pdf']);
            ylabel('')
            set(gca,'fontsize',16,'ytick',[],'yticklabel',[],'xtick',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot],'xticklabel',[0:ceil(settings_bvar_baseline_altspecs.irfhor_toplot/3):settings_bvar_baseline_altspecs.irfhor_toplot])
        end
        exportgraphics(gca,[figurepath,strcat('\irf_bvar_',settings_bvar_baseline_altspecs.irfvarname{j,1},'_',settings_bvar_baseline_altspecs.shockvarname{s}),'_',savename,'.pdf']);

        % pause
        close

        % save legend
        if s==1 && j==1
            figure('Position', [200 200 525 300], 'Visible', 'off');
            % figure('Position', [200 200 525 300]);
            b(1) = plot(0:settings_bvar_baseline_altspecs.irfhor_toplot,Alt_collection.IRFs.baseline.point(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j),'k','LineWidth',3);
            legendstring = Alt_collection.title.baseline;
            lspeccounter = 1;
            for k=1:altspecs_num-1
                hold on
                eval(['currspec = altspecs{k};'])
                if strcmp(currspec,'baseline')==0
                    eval(['currirf = Alt_collection.IRFs.',currspec,'.point(1:settings_bvar_baseline_altspecs.irfhor_toplot+1,s,j);'])
                    b(lspeccounter+1) = plot(0:settings_bvar_baseline_altspecs.irfhor_toplot,currirf,linespecvec{1,lspeccounter},'LineWidth',1.5);
                    b(lspeccounter+1).MarkerSize=3;
                    lspeccounter = lspeccounter + 1;
                    eval(['legendstring = [legendstring, {Alt_collection.title.',altspecs{k},'}];'])
                end
            end
            if altspecs_num>2
                legend(b(1:lspeccounter),legendstring,'Location','SouthOutside', 'EdgeColor',[0.999999 0.999999 0.999999],'FontSize',10,'Orientation','horizontal','NumColumns',floor(altspecs_num/2));
            else
                legend(b(1:lspeccounter),legendstring,'Location','SouthOutside', 'EdgeColor',[0.999999 0.999999 0.999999],'FontSize',10,'Orientation','horizontal','NumColumns',altspecs_num);
            end
            exportgraphics(gca,[figurepath,strcat('\irf_bvar_legend_',savename,'.pdf')]);
        end

    end
end
