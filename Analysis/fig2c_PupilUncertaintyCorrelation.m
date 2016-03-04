function [] = fig2c_PupilUncertaintyCorrelation()
% using the timewindow that is indicated in the regression timecourse plot,
% show the shape of the pupil vs motionstrength pattern

global mypath;

% get all data
data = readtable(sprintf('%s/Data/CSV/2ifc_data_allsj.csv', mypath));
warning('error', 'stats:LinearModel:RankDefDesignMat'); % stop if this happens
subjects = 1:27; % for this analysis, use all SJ!

nbins       = 6; % bin in 5 to have comparable plots to the difficulty version?
data.xval   = abs(data.motionstrength);
data.rpebin = nan(size(data.xval));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAKE OVERVIEW OF THE PUPIL UNCERTAINTY CORRELATION FOR ALL THESE DIFFERENT FIELDS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fields      = {'decision_pupil'};
for f = 1:length(fields),
    
    grandavg.(fields{f}).data = nan(length(subjects), 2, nbins);
    
    for sj = subjects,
        
        data = readtable(sprintf('%s/Data/CSV/2ifc_data_sj%02d.csv', mypath, sj));
        
        % normalization etc
        data.motionstrength = (abs(data.motionstrength));
        
        % project RT out of the pupil
        data.decision_pupilClean = projectout(data.decision_pupil, zscore(log(data.rt + 0.1)));
        
        % loop over error and correct
        cors = [0 1];
        for corr = cors,
            
            % FIT BETAS ON THE FULL MODEL, NOT BINNED
            trls = find(data.subjnr == sj & data.correct == corr);
            
            % include RT as a regressor
            mdl = fitlm([zscore(data.motionstrength(trls)) zscore(log(data.rt(trls)+0.1))],  ...
                zscore(data.(fields{f})(trls)));
            
            % SAVE BETAS FOR THIS PARTICIPANT
            grandavg.(fields{f}).regline(find(sj==subjects), find(corr==cors), :) = ...
                mdl.Coefficients.Estimate;
            
            % RATHER THAN DISCRETE CATEGORIES, BIN BY motionenergy
            clear trls;
            trls = find(data.subjnr==sj & data.correct==corr);
            
            % get the mean pupil dilation out
            [grandavg.xMean(find(sj==subjects), find(corr==cors), :), ...
                grandavg.(fields{f}).data(find(sj==subjects), find(corr==cors), :), ...
                grandavg.xStd(find(sj==subjects), find(corr==cors), :), ...
                grandavg.(fields{f}).wgt(find(sj==subjects), find(corr==cors), :)] = ...
                divideintobins(data.motionstrength(trls), data.(fields{f})(trls), nbins);
        end
    end
    
    % PLOT
    % use nice shades of red and green
    colors = cbrewer('qual', 'Set1', 8);
    cols = colors([1 3], :);
    
    % slopes
    slopes       = [grandavg.(fields{f}).regline(:, 1, 2) grandavg.(fields{f}).regline(:, 2, 2)];
    [~, pval(1), ~, stat] = ttest(slopes(:, 1), 0, 'tail', 'both');
    bf10 = t1smpbf(stat.tstat,27);
    [~, pval(2), ~, stat] = ttest(slopes(:, 2), 0, 'tail', 'both');
    bf10 = t1smpbf(stat.tstat,27);
    [~, pval(3), ~, stat] = ttest(slopes(:,1), slopes(:,2));
    bf10 = t1smpbf(stat.tstat,27);
    
    hold on;
    for co = 1:2,
        
        % use double error bars
        h = ploterr(squeeze(mean(grandavg.xMean(:, co, :))), ...
            squeeze(nanmean(grandavg.(fields{f}).data(:, co, :))), ...
            squeeze(nanstd(grandavg.xMean(:, co, :))) / sqrt(length(subjects)), ...
            squeeze(nanstd(grandavg.(fields{f}).data(:, co, :))) / sqrt(length(subjects)), ...
            'k-',  'abshhxy', 0);
        
        set(h(1), 'color', cols(co, :), ...
            'markerfacecolor', cols(co, :),  'markersize', 12, 'marker', '.');
        set(h(2), 'color', cols(co, :) + 0.05);
        set(h(3), 'color', cols(co, :) + 0.05);
    end
    
    if f == length(fields),
        xlabel('Evidence');
    else
        set(gca, 'xticklabel', []);
    end
    
    xlim([-0.2 5.6]); set(gca, 'xtick', 0:2.75:5.5, 'xticklabel',  {'weak', 'medium', 'strong'});
    ylim([0.15 0.65]); set(gca, 'ytick', 0.2:0.2:0.8);
    ylabel('Pupil response (z)');
    axis square;
    
    % make a barplot
    subplot(4,4,6);
    hold on;
    bar(1, mean(slopes(:, 1)), 'facecolor', cols(1, :), 'edgecolor', 'none', 'barwidth', 0.8);
    bar(2, mean(slopes(:, 2)), 'facecolor', cols(2, :), 'edgecolor', 'none', 'barwidth', 0.8);
    h = ploterr(1:2, mean(slopes), [], std(slopes)/ sqrt(length(subjects)), 'k.', 'abshhxy', 0);
    set(h(1), 'marker', 'none');

    mysigstar([1], [0.02 0.02], pval(1));
    mysigstar([2], [-0.02 -0.02], pval(2));
    mysigstar([1 2], [0.05 0.05], pval(3));
    axis square;
    
    xlim([0.1 4.5]); set(gca, 'tickdir', 'out', 'xtick', 1:2, 'xticklabel', ...
        [] , 'ydir', 'normal', 'xticklabelrotation', 0, 'ytick', [-0.05 0 0.05]);
    ylim([-0.06 0.05]);
    
    box off; axis square;
    if f == length(fields),
        set(gca, 'xtick', 1:2, 'xticklabel', {'Error', 'Correct'});
    else
        set(gca, 'xtick', 1:2, 'xticklabel', []);
    end
    % add sigstars
    ylabel('Beta weights (a.u.)');
    
end
set(gca, 'xcolor', 'k', 'ycolor', 'k');
savefast(sprintf('%s/Data/GrandAverage/grandavg_pupil_uncertainty.mat', mypath), 'grandavg');

end
