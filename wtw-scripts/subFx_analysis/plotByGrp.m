function []  = plotByGrp(vblName,data,par1,par2)
% subfunction to plot AUC (or another variable) by participant group
% Inputs:
%   vblName: string identifying the variable being plotted
%   data: struct with data for just one variable
%       a field for each group, holding a subjects x blocks matrix
%   par1: parameters specific to the current variable
%   par2: additional (non-variable-specific) parameters
% up to 3 separate plots are created:
%   original datapoints by group and block
%   boxplots by group and block
%   boxplots of block differences by group (if the number of blocks is 2)

% basic parameters
grpNames = fieldnames(data);
nGrps = length(grpNames);
nBks = par2.nBks;

% set up plot colors according to the distribution names in each group
plotColor_hp = (50+[0, 100, 0])./255; % green (high persistence)
plotColor_lp = (50+[80, 0, 100])./255; % purple (low persistence)
plotColor = cell(nGrps,nBks);
for g = 1:nGrps
    grpName = grpNames{g};
    for b = 1:nBks
        bkDist = par2.distribs.(grpName){b};
        if ismember(bkDist,{'unif', 'scale_1_20'})
            plotColor{g,b} = plotColor_hp;
        elseif ismember(bkDist,{'gpTrunc', 'scale_1.5_30'})
            plotColor{g,b} = plotColor_lp;
        elseif ismember(bkDist,{'Unif'})
            plotColor{g,b} = [0,0,0.5];
        elseif ismember(bkDist,{'GP'})
            plotColor{g,b} = [1,0,0];
        elseif ismember(bkDist,{'discrete1'})
            plotColor{g,b} = [0,0,0];
        else
            error('Distribution name %s is unrecognized.',bkDist);
        end
    end
end

% open a fresh figure window
if isempty(get(0,'CurrentFigure')), figure(1);
else figure(double(gcf)+1);
end

boxRaw = []; % initialize
boxDiff = []; % initialize
for g = 1:nGrps
    grpName = grpNames{g};
    grpY = data.(grpName); % a column for each block
    grpN = size(grpY,1);
    grpX_offset = smartJitter(grpY,0.03,0.25); % args: data, xMargin, yMargin
    grpX_grpCtr = g*ones(grpN,1);
    switch nBks
        case 1, grpX_ctr = grpX_grpCtr;
        case 2, grpX_ctr = [grpX_grpCtr-0.25, grpX_grpCtr+0.25];
        otherwise, error('Unexpected number of blocks');
    end
    grpX = grpX_ctr + grpX_offset;
    % plot all datapoints
    % first plot connecting lines if there are 2 blocks
    if nBks==2
        plot(grpX',grpY','-','Color',0.5*[1,1,1],'LineWidth',1); % connecting lines for each subject
        hold on;
    end
    % plot the datapoints for each block
    legend_h = nan(nBks,1);
    for b = 1:nBks
        legend_h(b) = plot(grpX(:,b),grpY(:,b),'.','MarkerSize',16,'Color',plotColor{g,b});
        hold on;
    end
    % set up data for boxplots: col1 has data, col2 has grouping variable
    boxRaw = [boxRaw; [grpY(:), grpX_ctr(:)]]; %#ok<AGROW>
    if nBks==2
        boxDiff = [boxDiff; [grpY(:,2) - grpY(:,1), grpX_grpCtr]]; %#ok<AGROW>
    end
    
end % loop over groups

% plot formatting (individual datapoints)
set(gca,'Box','off','FontSize',16,'XTick',1:nGrps,'XTickLabel',grpNames,'XLim',[0.5, nGrps+0.5]);
% legend(legend_h,'Block A','Block B','Location','SouthEast');
xlabel('Group');
title(vblName,'Interpreter','none');
if isfield(par1,'ylabel'), ylabel(par1.ylabel); end
% add a small buffer above the max y value; plot a line at max y
if isfield(par1,'yLim')
    set(gca,'YLim',par1.yLim+[0,0.5]);
    xLim = get(gca,'XLim');
    plot(xLim,par1.yLim(2)*[1,1],'--','Color',0.8*[1,1,1],'LineWidth',2);
    ch = get(gca,'Children');
    set(gca,'Children',[ch(2:end); ch(1)]); % move the zero line to the back
end

% boxplot - raw data
figure(double(gcf)+1);
boxColors = plotColor'; % blocks in rows, groups in columns
boxColors = cell2mat(boxColors(:));
boxplot(boxRaw(:,1),boxRaw(:,2),'boxstyle','filled',...
    'colorgroup',boxRaw(:,2),'colors',boxColors);
hold on;
nBoxes = nBks*nGrps;
box1_x = (nBks+1)/2;
set(gca,'Box','off','FontSize',16,'XTick',box1_x:nBks:(nBoxes+1),'XTickLabel',grpNames);
xlabel('Group');
title(vblName,'Interpreter','none');
if isfield(par1,'ylabel'), ylabel(par1.ylabel); end
if isfield(par1,'yLim')
    set(gca,'YLim',par1.yLim+[0,0.5]);
    % add a small buffer above the max y value; also put a line at max y
    if isfield(par1,'yLim'), set(gca,'YLim',par1.yLim+[0,0.5]); end
    xLim = get(gca,'XLim');
    plot(xLim,par1.yLim(2)*[1,1],'--','Color',0.8*[1,1,1],'LineWidth',2);
    ch = get(gca,'Children');
    set(gca,'Children',[ch(2:end); ch(1)]); % move the zero line to the back
end

% boxplot - block differences (only if the number of blocks equals 2)
if nBks==2
    figure(double(gcf)+1);
    boxplot(boxDiff(:,1),boxDiff(:,2),'boxstyle','filled','colors','k');
    hold on;
    set(gca,'Box','off','FontSize',16,'XTick',1:nGrps,'XTickLabel',grpNames);
    xlabel('Group');
    title(vblName,'Interpreter','none');
    if isfield(par1,'ylabel'), ylabel(par1.ylabel); end
    % ylim is not applied to the differences, but a line is placed at zero
    xLim = get(gca,'XLim');
    plot(xLim,[0,0],'--','Color',0.8*[1,1,1],'LineWidth',2);
    ch = get(gca,'Children');
    set(gca,'Children',[ch(2:end); ch(1)]); % move the zero line to the back
end

end % function

