
function Plot_daily_impact_panel(irfsdatapath,filename,figurepath,shockvar,savename,lagtoplot,samexaxis)


[data,strings]  = xlsread([irfsdatapath,'\',filename{1}]);
vars            = strings(1,:);
for i=2:length(filename)
    [data_temp,strings_temp]  = xlsread([irfsdatapath,'\',filename{i}]);
    data = [data, data_temp];
    vars = [vars, strings_temp];
end

gov10yyields_label = [ {'tb_rate_10y'},{'US'};...
    {'fgovy10y'},{'AEs'}];
ecs_label = [ {'ectreas_10y_us'},{'US'};...
    {'fec10'},{'AEs'}];
tp_label = [ {'tptreas_10y_us'},{'US'};...
    {'ftp10'},{'AEs'}];
equity_label = [{'lsp500'},{'US'};...
    {'lfstockp'},{'AEs'}];
fx_label = [{'lffxusd'},{'USD vs AEs'}];

xl = nan(size(shockvar,2),2);
resgroups = [{'gov10yyields'},{'ecs'},{'tp'},{'equity'},{'fx'}];
figure('Position', [200 0 1500 500])
for s=1:size(shockvar,2)
    for j=1:length(resgroups)
        eval(['vec_',resgroups{j},' = nan(size(',resgroups{j},'_label,1),1);']);
        eval(['vec_',resgroups{j},'_signif = nan(size(',resgroups{j},'_label,1),1);'])
        eval(['lengthlabel = size(',resgroups{j},'_label,1);'])
        for i=1:lengthlabel
            eval(['testexist = strmatch(strcat(''irfj_'',',resgroups{j},'_label(i,1),''_'',''',shockvar{1,s},'''),vars,''exact'');'])
            if ~isempty(testexist)
                eval(['lowerpos90 = strmatch(strcat(''irfj_'',',resgroups{j},'_label(i,1),''_'',''',shockvar{1,s},'_l90''),vars,''exact'');'])
                eval(['upperpos90 = strmatch(strcat(''irfj_'',',resgroups{j},'_label(i,1),''_'',''',shockvar{1,s},'_u90''),vars,''exact'');'])
                irfpoint = data(:,testexist);
                irflower90 = data(:,lowerpos90);
                irfupper90 = data(:,upperpos90);
                eval(['vec_',resgroups{j},'(i,1) = irfpoint(1+lagtoplot,1);'])
                eval(['vec_',resgroups{j},'_signif(i,1) = 1;'])
                cb_upper = irfupper90(1+lagtoplot,1);
                cb_lower = irflower90(1+lagtoplot,1);
                if cb_upper>0 & cb_lower<0
                    eval(['vec_',resgroups{j},'_signif(i,1) = 0;'])
                end
            else
                eval(['vec_',resgroups{j},'(i,1) = 0;'])
                eval(['vec_',resgroups{j},'_signif(i,1) = 0;'])
            end
        end
    end    
    vec_results        = [1; vec_gov10yyields; nan(1,1); 1; vec_ecs; nan(1,1); 1; vec_tp; nan(1,1); 1; vec_equity/10; nan(1,1); 1; vec_fx/10];
    vec_results_label  = [{'\textbf{10-Y yields} (pp)'}; gov10yyields_label(:,2); {'\textbf{Expect. comp.} (pp)'}; ecs_label(:,2); {'\textbf{Term premia} (pp)'}; tp_label(:,2); {'\textbf{Equity (/10)} (\%)'}; equity_label(:,2); {'\textbf{FX (/10)} (\%)'}; fx_label(:,2)];
    vec_results_signif = [nan(1,1); vec_gov10yyields_signif; nan(2,1); vec_ecs_signif; nan(2,1); vec_tp_signif; nan(2,1); vec_equity_signif; nan(2,1); vec_fx_signif];
    yticklocations = [1:length(vec_results)];
    yticklocations(:,isnan(flipud(vec_results))) = [];
    clr = [nan(1,3);...
        repmat([0,0,255],size(gov10yyields_label,1),1);...
        nan(2,3);...
        repmat([0,255,0],size(ecs_label,1),1);...
        nan(2,3);...
        repmat([0,0,0],size(tp_label,1),1);...
        nan(2,3);...
        repmat([0,220,255],size(equity_label,1),1);...
        nan(2,3);...
        repmat([255,255,0],size(fx_label,1),1)]/255;
    clr(vec_results_signif==0,:) = 255*ones(sum(vec_results_signif==0),3);
    vec_results(vec_results==1,:) = NaN;

    subplot(1,size(shockvar,2),s)
    b = barh(flipud(vec_results),'facecolor', 'flat');
    b.CData = flipud(clr);
    if s==1
        set(gca,'ytick',yticklocations,'yticklabels',flipud(vec_results_label),'Fontsize',16,'TickLabelInterpreter','latex')
    else
        set(gca,'ytick',[],'Fontsize',16,'TickLabelInterpreter','latex')
    end
    title(shockvar{2,s},'Interpreter','Latex','Fontsize',23)
    box off
    xl(s,:) = xlim;

end
if samexaxis
    for s=1:size(shockvar,2)
        subplot(1,size(shockvar,2),s)
        xlim([min(xl(:,1)),max(xl(:,2))])
    end
end
exportgraphics(gcf,[figurepath,'\irfj_lps_impact_effects_spillovers_',savename,'.pdf']);
