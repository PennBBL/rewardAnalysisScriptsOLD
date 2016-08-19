function [] = plotGroupSC(label,scData,truncPt)
% plots group-averaged survival curves
%
% Inputs:
%   label: a string used for plot titles
%   scData: a struct array with a field for each participant group, each
%       containing a subjects-x-blocks cell array. Each element of the cell
%       array holds a 2-column matrix (col1 = x values, col2 = survival
%       function values). 
%   truncPt: scalar, maximum time in seconds for which survival curves were
%       computed.

grpNames = fieldnames(scData);
nGrps = numel(grpNames);
tGrid = 0:0.05:truncPt; % for resampling survival curves
hazGrid = 2:2:(truncPt-1); % bin centers for empirical hazard function
    % bin width = 2s (set below)
    % note: 0-1s period omitted; this will reflect immediate quits
plotColors = {'b', 'r', 'c', 'm'}; % colors assigned in order to participant groups
kmData = struct([]);


%%% compute resampled survival curves
% loop over participant groups
for gIdx = 1:nGrps
    thisGrp = grpNames{gIdx};
    nBks = size(scData.(thisGrp),2);
    nSubjects = size(scData.(thisGrp),1);
    
    % loop over blocks of the experiment
    for bIdx = 1:nBks
        
        % initialize data storage array
        kmData(bIdx).(thisGrp) = nan(nSubjects,numel(tGrid));
        
        % loop over subjects
        for sIdx = 1:nSubjects
            
            % get this subject's raw kaplan-meier survival curve
            km = scData.(thisGrp){sIdx,bIdx};
            
            % go point-by-point in the output grid
            km_resamp = nan(size(tGrid));
            for tIdx = 1:numel(tGrid)
                tVal = tGrid(tIdx);
                whichPoint = find(km(:,1)<=tVal,1,'last');
                km_resamp(tIdx) = km(whichPoint,2);
            end
            
            % store the results
            kmData(bIdx).(thisGrp)(sIdx,:) = km_resamp;
            
            % also compute empirical hazard functions
            empirHaz = nan(size(hazGrid));
            for tIdx = 1:numel(hazGrid)
                tVal = hazGrid(tIdx);
                binStartIdx = find(km(:,1)<=(tVal-1),1,'last'); % sc value 1s before bin center
                binStartVal = km(binStartIdx,2);
                binEndIdx = find(km(:,1)<=(tVal+1),1,'last'); % sc value 1s after bin center
                binEndVal = km(binEndIdx,2);
                % estimated probability of quitting during this bin
                % conditional on waiting till the start of the bin
                empirHaz(tIdx) = (binStartVal - binEndVal)/binStartVal;
            end
            
            % store the results
            hazData(bIdx).(thisGrp)(sIdx,:) = empirHaz;
            
        end % loop over subjects
        
    end % loop over blocks
    
end % loop over participant groups


%%% plot survival curves
% blocks are plotted separately; groups are plotted together on axes
figure(double(gcf)+1);
for bIdx = 1:nBks % assumes all groups have the same number of blocks
    subplot(1,nBks,bIdx);
    % plot groups one at a time
    h = nan(1,nGrps); % initialize dataseries handles
    grps_plotData = cell(1,nGrps); % initialize
    for gIdx = 1:nGrps
        thisGrp = grpNames{gIdx};
        
        % grab data and remove nans
        plotData = kmData(bIdx).(thisGrp);
        badRowIdx = any(isnan(plotData),2);
        plotData(badRowIdx,:) = []; % remove rows with nans
        
        grps_plotData{gIdx} = plotData; % store for use w/ p values below
        
        % compute summary stats to plot
        % mean +/- SEM
        plotCentral = mean(plotData);
        plotN = size(plotData,1);
        plotSEM = std(plotData)./sqrt(plotN);
        plotLo = plotCentral - plotSEM;
        plotHi = plotCentral + plotSEM;
        
%         % alternative: median with IQR
%         plotCentral = median(plotData);
%         plotLo = prctile(plotData,25);
%         plotHi = prctile(plotData,75);
        
        % plot the error band
        hErr = ciplot(plotLo,plotHi,tGrid,plotColors{gIdx});
        set(hErr,'FaceAlpha',0.25,'LineStyle','none');
        hold on;
        % plot the mean
        h(gIdx) = plot(tGrid,plotCentral,plotColors{gIdx},'LineWidth',2);
    end % loop over groups
    % format the axes
    set(gca,'Box','off','FontSize',16,'XLim',[0,truncPt],'YLim',[0,1]);
    xlabel('Elapsed time');
    ylabel('Survival rate');
    hL = legend(h,grpNames,'Location','NorthEast');
    set(hL,'Interpreter','none');
    titleText = sprintf('%s, Bk %d\n',label,bIdx);
    title(titleText,'Interpreter','none');
    
    % add a nominal p-value series (if there are 2 groups)
    if nGrps==2
        pSeries = nan(size(tGrid));
        for tIdx = 1:numel(tGrid)
            pSeries(tIdx) = ranksum(grps_plotData{1}(:,tIdx),grps_plotData{2}(:,tIdx));
        end
        plot(tGrid(pSeries<0.05),zeros(1,sum(pSeries<0.05)),'rd');
    end
    
end % loop over blocks


%%% plot empirical hazard functions
figure(double(gcf)+1);
for bIdx = 1:nBks % assumes all groups have the same number of blocks
    subplot(1,nBks,bIdx);
    % plot groups one at a time
    h = nan(1,nGrps); % initialize dataseries handles
    for gIdx = 1:nGrps
        thisGrp = grpNames{gIdx};
        
        % grab data and remove nans
        plotData = hazData(bIdx).(thisGrp);
        
        % compute summary stats to plot
        % mean +/- SEM
        plotMean = nanmean(plotData);
        plotN = sum(~isnan(plotData)); % a value for each column
        plotSEM = nanstd(plotData)./sqrt(plotN);
        
        % plot the mean + error bars
        h(gIdx) = errorbar(hazGrid,plotMean,plotSEM,'k.-','LineWidth',2,'MarkerSize',24);
        set(h(gIdx),'Color',plotColors{gIdx});
        hold on;
        
    end % loop over groups
    % format the axes
    set(gca,'Box','off','FontSize',16,'XLim',[0,truncPt]);
    xlabel('Bin center (s)');
    ylabel('Hazard rate for quitting');
    hL = legend(h,grpNames,'Location','NorthEast');
    set(hL,'Interpreter','none');
    titleText = sprintf('%s, Bk %d\n',label,bIdx);
    title(titleText,'Interpreter','none');

end % loop over blocks



