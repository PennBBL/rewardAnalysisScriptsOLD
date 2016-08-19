function [] = runningWtw_plot(wtwTimeseries,blockSec,ceilValue)
% plots results for willingness to wait over time. 
%
% input:
%   wtwTimeseries is a struct array, with a field named for each group
%     each field holds a subjects-by-time matrix for the subjects in that
%     group. the time dimension has one col per second, and spans all
%     blocks in multi-block versions of the experiment. 
%   blockSec (scalar), number of seconds per block
%   ceilValue will be the max on the y axis
%
% each group is a separate timeseries
% provisional strategy for comparisons:
%   each sequential pair of groups will be plotted together on one axis

grpNames = fieldnames(wtwTimeseries);
nGrps = length(grpNames);
nPlots = floor(nGrps/2); % 2 groups per plot

% identify block boundaries (if any)
nTmpts = size(wtwTimeseries.(grpNames{1}),2); % number of columns
assert(mod(nTmpts,blockSec)==0,'Uneven number of blocks.');
nBks = nTmpts./blockSec;
nBreaks = nBks - 1;
if nBreaks>0
    breakPts = (1:nBreaks).*blockSec;
    breakPts = breakPts./60; % axis will be in minutes
end

% loop over groups calculating the mean timeseries and standard error
for g = 1:nGrps
    gName = grpNames{g};
    d = wtwTimeseries.(gName);
    n = size(d,1);
    wtwMean.(gName) = mean(d)';
    wtwSEM.(gName) = std(d)'./sqrt(n);
end

% loop over plot windows
col = {[0,0,0.5], [1,0.1,0.1], [0,0,0]}; % line colors
for p = 1:nPlots
    nGrpsHere = 2;
    if (nGrps - 2*(p-1))==3, nGrpsHere = 3; end
    figure(double(gcf)+1);
    clf;
    totalMin = nTmpts/60;
    axDims = 2*[72*totalMin/5, 72];
    set(gcf,'Units','points','Position',[100, 100, axDims(1)+2*72, axDims(2)+2*72]);
    set(gca,'Units','points','Position',[72, 72, axDims(1), axDims(2)]);
    hold on;
    grp = cell(1,2);
    h = nan(2,2);
    for g = 1:nGrpsHere % for the 2 groups plotted in this window
        grp{g} = grpNames{2*(p-1)+g};
        h(g,1) = ciplot(wtwMean.(grp{g})-wtwSEM.(grp{g}),wtwMean.(grp{g})+wtwSEM.(grp{g}),...
            (1:nTmpts)./60,col{g});
        set(h(g,1),'FaceAlpha',0.25,'LineStyle','none');
        hold on;
        h(g,2) = plot((1:nTmpts)./60,wtwMean.(grp{g}),'-','LineWidth',2,'Color',col{g});
    end
    % block boundaries
    for i = 1:nBreaks
        plot(breakPts(i)*[1,1],[0,ceilValue],'k--','LineWidth',1);
    end
    % formatting
    set(gca,'Box','off','FontSize',16,'YLim',[0, ceilValue],'YGrid','on','XLim',[0, nTmpts/60],'XTick',0:2:(nTmpts/60));
    xlabel('Time elapsed (min)');
    ylabel('WTW (s)');
    lh = legend(h(:,2),grp);  
    set(lh,'Interpreter','none'); % to allow underscores in legend text
end % loop over plot windows

% could implement stats based on the code below.



% % linear trends
% % this will be run twice for expt 2 (full 20 mins, and 1st 10 mins only)
% timeInMin = (1:totalSec)'/60;
% X = [ones(size(timeInMin)), timeInMin];
% for iter = 1:2
%     
%     if iter==2 && totalSec==600, continue; end % for expt 1, skip 2nd iteration
%     switch iter
%         case 1, tmptIdx = 1:totalSec;
%         case 2, tmptIdx = 1:600; fprintf('\nFIRST 10 MINS ONLY:\n');
%     end
%     
%     % test of linear trends
%     fprintf('regression coefs for time (medians): \n');
%     for c = 1:nConds
%         cond = cNames{c};
%         for i = 1:n(c)
%             b = regress(wtwAll(i,tmptIdx)',X(tmptIdx,:));
%             coef(i,1) = b(2);
%         end
%         [p, h, stats] = signrank(coef);
%         testN = length(coef);
%         fprintf('%s median = %1.2f, signed-rank T = %1.2f, n = %d, p = %1.4f\n',...
%             cond,median(coef),stats.signedrank,testN,p);
%     end
%     % test differences in linear trends
%     compars = {[1, 2], [1, 3], [2, 3]};
%     for c = 1:nchoosek(nConds,2) % for each pairwise comparison
%         c1 = compars{c}(1);
%         c2 = compars{c}(2);
%         [p, h, stats] = ranksum(coef.(cNames{c1}),coef.(cNames{c2}));
%         testN1 = length(coef.(cNames{c1}));
%         testN2 = length(coef.(cNames{c2}));
%         fprintf('difference between groups %s and %s:\n',cNames{c1},cNames{c2});
%         fprintf('rank-sum R = %1.2f, n_%s = %d, n_%s = %d, p = %1.4f\n',...
%             stats.ranksum,cNames{c1},testN1,cNames{c2},testN2,p);
%         mwwtest_minU(coef.(cNames{c1}),coef.(cNames{c2}));
%     end
% end





