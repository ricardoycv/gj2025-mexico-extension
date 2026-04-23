%% Report the mcmc chain for a Bayesian model Y = U*C
% Variables assumed to exist:
% mychain, prior, pathout, mypref, ynames

[Nshocks, N, ndraws] = size(mychain.shock_effects);
if ~exist("mypref","var")
    mypref = "";
end
if ~exist("shocknames","var")
    shocknames = "u" + (1:N);
end

pos = [5, 1, 11*N^.6, 8*Nshocks^.6];

% W -> trace plot
fh = figure(Units="centimeters", Position=pos);
for ss = 1:N
    for vv = 1:N
        x = squeeze(mychain.W(vv, ss, :));
        subplot(N, N, sub2ind([N,N], ss, vv))
        plot(x)
        if ss==1, ylabel(ynames(vv), Interpreter="none", FontWeight="bold"), end
        if vv==1, title(shocknames(ss), FontWeight="bold"), end
    end
end
sgtitle("Trace plots of W")
exportgraphics(fh, pathout+mypref+"W_trace.pdf")


% shock_effects -> trace plot, autocorr, histograms
fh = figure(Units="centimeters", Position=pos);
for ss = 1:Nshocks
    for vv = 1:N
        x = squeeze(mychain.shock_effects(ss, vv, :));
        subplot(Nshocks, N, sub2ind([N,Nshocks], vv, ss))
        plot(x)
        yline(0)
        if ss==1, title(ynames(vv), Interpreter="none", FontWeight="bold"), end
        if vv==1, ylabel(shocknames(ss), FontWeight="bold"), end
    end
end
sgtitle('Trace plots of shock effects')
exportgraphics(fh, pathout+mypref+"shock_effects_trace.pdf")

fh = figure(Units="centimeters", Position=pos);
for ss = 1:Nshocks
    for vv = 1:N
        x = squeeze(mychain.shock_effects(ss, vv, :));
        subplot(Nshocks, N, sub2ind([N,Nshocks], vv, ss))
        autocorr(x, 'NumLags', min(100,fix(ndraws/5)))
        ylabel(ynames(vv), Interpreter="none", FontWeight="bold")
        title(shocknames(ss), FontWeight="bold")
    end
end
sgtitle('Autocorrelation of draws of shock effects')

fh = figure(Units="centimeters", Position=pos);
for ss = 1:Nshocks
    for vv = 1:N
        x = squeeze(mychain.shock_effects(ss, vv, :));
        subplot(Nshocks, N, sub2ind([N,Nshocks], vv, ss))
        histogram(x)
        if ss==1, title(ynames(vv), Interpreter="none", FontWeight="bold"), end
        if vv==1, ylabel(shocknames(ss), FontWeight="bold"), end
    end
end
sgtitle("Histograms of shock effects")
exportgraphics(fh, pathout+mypref+"shock_effects_hist.pdf")


% Student-t shocks: degrees of freedom v
if not(prior.t.v == 0)
    fh = figure;
    plot(mychain.t_v');
    sgtitle('Trace plot of t v')
    exportgraphics(fh, pathout+mypref+"t_v_trace.pdf")

    fh = figure;
    t = tiledlayout("flow");
    for n = 1:Nshocks
        nexttile
        hold on
        h = histogram(mychain.t_v(n,:), Normalization="pdf");
        x = 0:0.01:4;
        plot(x, gampdf(x, prior.t.va(n), prior.t.vb(n)))
        title("Histogram of t_v" + n, Interpreter="none")
    end
    exportgraphics(fh, pathout+mypref+"t_v_hist.pdf")
end

% Heteroskedastic shocks: shock standard deviation (Q^-.5) by regime
if prior.regimes.num
    if prior.regimes.num<=3
        pos1 = [5, 1, 22, 6];
    else
        pos1 = pos;
    end
    fh = figure(Units="centimeters", Position=pos1);
    tiledlayout("flow")
    for n = 1:Nshocks
        nexttile
        hold on
        for r = 1:prior.regimes.num
            t1 = find(prior.regimes.ind{r},1);
            x = squeeze(mychain.Q(t1,n,:).^(-0.5));
            plot(x)
        end
        legend(string(prior.regimes.names))
        title(sprintf("std(%s)", shocknames(n)))
    end
    exportgraphics(fh, pathout+mypref+"shock_std_trace.pdf")

    fh = figure(Units="centimeters", Position=pos1);
    tiledlayout("flow")
    for n = 1:Nshocks
        nexttile
        hold on
        % find the common BinWidth
        temp = nan(prior.regimes.num,1);
        for r = 1:prior.regimes.num
            t1 = find(prior.regimes.ind{r},1);
            x = squeeze(mychain.Q(t1,n,:).^(-0.5));
            [~, edges] = histcounts(x);
            temp(r) = edges(2)-edges(1);
        end
        BinWidth = mean(temp);
        % actual plot
        for r = 1:prior.regimes.num
            t1 = find(prior.regimes.ind{r},1);
            x = squeeze(mychain.Q(t1,n,:).^(-0.5));
            histogram(x, BinWidth=BinWidth)
        end
        legend(string(prior.regimes.names))
        title(sprintf("std(%s)", shocknames(n)))
    end
    exportgraphics(fh, pathout+mypref+"shock_std_hist.pdf")
end


shocks_med = median(mychain.shocks,3);
Gols = shocks_med\Y;
R2_ols = (sum((shocks_med*Gols).^2)./sum(Y.^2))';
if isfield(mychain, "Rsquared"), R2_mean = mean(mychain.Rsquared,2); else R2_mean = nan(N,1); end
disp(table(R2_mean, R2_ols, RowNames=ynames))

% Save shocks and errors
tab_shocks = [tab(:,1) array2table(round(shocks_med,5), VariableNames=shocknames)];
writetable(tab_shocks, pathout+"U.csv")
tab_errors = [tab(:,1) array2table(round(Y-shocks_med*Gols,5), VariableNames="e"+ynames)];
writetable(tab_errors, pathout+"E.csv")

% Nice plot of shock effects
shock_effects_med = median(mychain.shock_effects, 3);
shock_effects_l = quantile(mychain.shock_effects, .1, 3);
shock_effects_u = quantile(mychain.shock_effects, .9, 3);
%[fh, varminmax] = plot_resp1(diag(std(Fm))*Gm, diag(std(Fm))*Gl, diag(std(Fm))*Gu, ymaturities, ynames);
[fh, varminmax] = plot_resp1(shock_effects_med, shock_effects_l, shock_effects_u, ymaturities, ynames);
exportgraphics(fh, pathout+"shock_effects.pdf")

% Nice plot of shock effects
shock_effects1s_med = median(mychain.shock_effects1s, 3);
shock_effects1s_l = quantile(mychain.shock_effects1s, .1, 3);
shock_effects1s_u = quantile(mychain.shock_effects1s, .9, 3);
%[fh, varminmax] = plot_resp1(diag(std(Fm))*Gm, diag(std(Fm))*Gl, diag(std(Fm))*Gu, ymaturities, ynames);
[fh, varminmax] = plot_resp1(shock_effects1s_med, shock_effects1s_l, shock_effects1s_u, ymaturities, ynames);
exportgraphics(fh, pathout+"shock_effects1s.pdf")

