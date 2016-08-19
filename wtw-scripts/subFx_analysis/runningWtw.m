function [wtwTimeseries] = runningWtw(sData,blockSec,ceilValue)
% calculates a running estimate of willingness to wait over time, for one
% subject's data.
%
% Input:
%   sData is a struct with an element per block
%       (if there are multiple blocks, this fx will concatenate the data)
%   totalSec is block duration in seconds (assumed to be the same for each block)
%   ceilValue is also in seconds
%
% Output:
%   wtwTimeseries is a column vector with one value per second
%
% approach is as follows:
% (1) we assume wtw stays the same from trial to trial unless we observe a
% decision that indicates otherwise
% (2) for quit trials, assume wtw equals the trial duration.
% (3) for win trials, assume wtw equals the greater of either the trial
% duration or the previous wtw
% (4) cap wtw at a value common to both conditions
% (5) initialize wtw at zero?
%   should instead set initial wtw to the longest trial duration up to and
%   including the first quit?
% (6) timepoints at the end are set to the value left from the final
% completed trial. (if they are treated as missing, then the plot seems to
% show a large shift at the end which is entirely artifactual)
% 
% this will be measured as a function of time (seconds) rather than trials,
% to give a clearer picture of what subjects were doing over the course of
% the experiment. So, in cases where subjects wait longer than previously
% expected, the greater estimated wtw applies during the entire length of the trial. 
% 
% there is a risk that the distribution itself will partly determine
% results, especially due to #3. there is also a risk of an artificial
% initial trajectory due to #5. 



% initialize
nBks = length(sData);
totalSec = blockSec*nBks;
wtwTimeseries = nan(totalSec,1);
wtw = 0;
time = 0;

% loop over blocks
for b = 1:nBks
    
    % pull this block's trialwise data
    nTrials = length(sData(b).latency);
    latency = sData(b).latency;
    isWin = sData(b).outcomeWin;
    outcomeTime = sData(b).outcomeTime;
    
    % for later blocks, represent outcome time cumulatively from the
    % beginning of the first block
    outcomeTime = outcomeTime + (b-1)*blockSec;
    bkEnd = b*blockSec;
    
    % estimate wtw at each trial
    for t = 1:nTrials
        
        % for wins, take max going back to last quit
        if ~isWin(t) || latency(t)>wtw
            % reset wtw if this is a quit or a later-than-expected win
            % (no change if it is a win earlier than wtw)
            wtw = latency(t);
        end
        
        % apply wtw to this trial's time epoch
        try
        epochEnd = min(outcomeTime(t),bkEnd); % go no later than the end of the block
        epochEnd = round(epochEnd);
        wtwTimeseries((time+1):epochEnd) = wtw;
        catch ME
            disp(getReport(ME));
            keyboard;
        end
        time = epochEnd;

    end % loop over trials
    
    % final wtw value carries through till the end of the block
    wtwTimeseries((time+1):bkEnd) = wtw;
    
end % loop over blocks

% apply ceiling value
wtwTimeseries = min(wtwTimeseries,ceilValue);

    
   

    
    
return;
% everything below is related to group-level stuff -- stats and plots
    
    
    
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


% plot results
totalMin = totalSec/60;
% final size will be 1" tall, 1"/5min wide - scaled by 2 here.
% axDims = 2*[72*totalMin/5, 72];
% set(gcf,'Units','points','Position',[100, 100, axDims(1)+2*72, axDims(2)+2*72]);
% set(gca,'Units','points','Position',[72, 72, axDims(1), axDims(2)]);

hold on; % plots can be drawn incrementally with repeated calls

plotVal = nanmean(wtwAll);
% n should be the same for all timepoints
plotN = sum(~isnan(wtwAll)); 
plotError = nanstd(wtwAll)./sqrt(plotN);
h = ciplot(plotVal-plotError,plotVal+plotError,(1:totalSec)./60,'b');
set(h,'FaceAlpha',0.25,'LineStyle','none');
h2 = plot((1:totalSec)./60,plotVal,'b-','LineWidth',2);

% output handles to plotted line and confidence band
hOut = [h2, h];

set(gca,'Box','off','FontSize',16,'YLim',[0, 16],'YGrid','on','XLim',[0, totalMin],'XTick',0:2:totalMin);
xlabel('Time elapsed (min)');
ylabel('WTW (sec)');
hold off;

% TO SAVE AS EPS:
% execute the following, then restore transparency in illustrator.
% set(gcf,'Renderer','painters');






