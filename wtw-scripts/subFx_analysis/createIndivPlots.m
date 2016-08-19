function [] = createIndivPlots(id,grpName,trials,kmsc,kmsc_con)
% subfunction to plot one subject's data
    
nBks = length(trials);
plotColor{1} = (50+[0, 100, 0])./255; % green (block A)
plotColor{2} = (50+[80, 0, 100])./255; % purple (block B)

% plot trial data
figure(1);
clf;
for b = 1:nBks
    subplot(1,nBks,b);
    titleStr = sprintf('%s (%s), Bk %d',id,grpName,b);
    ssPlot(trials(b),titleStr); % external subfunction
end

% plot survival curves
figure(2);
clf;
for b = 1:nBks
    % unconstrained survival curve
    subplot(1,2,1);
    titleStr = sprintf('%s (%s): KM',id,grpName);
    h = qtask_plotKm(kmsc{b},titleStr);
    set(h,'Color',plotColor{b});
    hold on;
    % constrained survival curve IF supplied
    if ~isempty(kmsc_con)
        subplot(1,2,2);
        titleStr = sprintf('%s (%s): Constrained KM',id,grpName);
        h = qtask_plotKm(kmsc_con{b},titleStr);
        set(h,'Color',plotColor{b});
        hold on;
    end
end
if nBks==2, legend('Block 1','Block 2','Location','SouthWest'); end
    
end % subfunction createIndivPlots