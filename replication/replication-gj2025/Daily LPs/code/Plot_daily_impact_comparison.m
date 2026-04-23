
function Plot_daily_impact_comparison(irfsdatapath,filename,figurepath,shockvar,savename,lagtoplot,samexaxis)


[data{1},strings{1}]  = xlsread([irfsdatapath,'\',filename{1}]);
vars{1}               = strings{1}(1,:);
for i=2:length(filename)
    [data{i},strings{i}]  = xlsread([irfsdatapath,'\',filename{i}]);
    vars{i}                 = strings{i}(1,:);
end

irs_label = [{'tb_rate_3m'},{'3M-TB rate'};...
    {'tb_rate_1y'},{'1Y-TB rate'};...
    {'tb_rate_2y'},{'2Y-TB rate'};...
    {'tb_rate_5y'},{'5Y-TB rate'};...
    {'tb_rate_10y'},{'10Y-TB rate'}];
ecs_label = [{'ectreas_1y_us'},{'1Y-EC'};...
    {'ectreas_2y_us'},{'2Y-EC'};...
    {'ectreas_5y_us'},{'5Y-EC'};...
    {'ectreas_10y_us'},{'10Y-EC'}];
tps_label = [{'tptreas_2y_us'},{'2Y-TP'};...
    {'tptreas_5y_us'},{'5Y-TP'};...
    {'tptreas_10y_us'},{'10Y-TP'}];
equity_label = [{'lsp500'},{'S\&P 500 (/10)'}];

xl = nan(size(shockvar,2),2);
resgroups = [{'tps'},{'irs'},{'ecs'},{'equity'}];
figure('Position', [200 200 400*size(shockvar,2) 550])
for s=1:size(shockvar,2)
    for j=1:length(resgroups)
        eval(['vec_',resgroups{j},' = nan(size(',resgroups{j},'_label,1),1);']);
        eval(['vec_',resgroups{j},'_signif = nan(size(',resgroups{j},'_label,1),1);'])
        eval(['lengthlabel = size(',resgroups{j},'_label,1);'])
        for i=1:lengthlabel
            eval(['testexist = strmatch(strcat(''irfj_'',',resgroups{j},'_label(i,1),''_'',''',shockvar{1,s},'''),vars{s},''exact'');'])
            if ~isempty(testexist)
                eval(['lowerpos90 = strmatch(strcat(''irfj_'',',resgroups{j},'_label(i,1),''_'',''',shockvar{1,s},'_l90''),vars{s},''exact'');'])
                eval(['upperpos90 = strmatch(strcat(''irfj_'',',resgroups{j},'_label(i,1),''_'',''',shockvar{1,s},'_u90''),vars{s},''exact'');'])
                irfpoint = data{s}(:,testexist);
                irflower90 = data{s}(:,lowerpos90);
                irfupper90 = data{s}(:,upperpos90);
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
    
    vec_results = [vec_irs; nan(2,1); vec_ecs; nan(2,1); vec_tps; nan(2,1); vec_equity/10];
    vec_results_label = [irs_label(:,2); ecs_label(:,2); tps_label(:,2); equity_label(:,2)];
    vec_results_signif = [vec_irs_signif; nan(2,1); vec_ecs_signif; nan(2,1); vec_tps_signif; nan(2,1); vec_equity_signif];
    yticklocations = [1:length(vec_results)];
    yticklocations(:,isnan(flipud(vec_results))) = [];
    clr = [repmat([0,0,255],size(irs_label,1),1);...
        nan(2,3);...
        repmat([0,255,0],size(ecs_label,1),1);...
        nan(2,3);...
        repmat([0,0,0],size(tps_label,1),1);...
        nan(2,3);...
        repmat([0,220,255],size(equity_label,1),1)]/255;
    clr(vec_results_signif==0,:) = 255*ones(sum(vec_results_signif==0),3);
    
    
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
exportgraphics(gcf,[figurepath,'\irfj_lps_impact_effects_irs_smallscale_',savename,'.pdf']);

