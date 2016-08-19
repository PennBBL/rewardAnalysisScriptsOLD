function [grpData] = loadData_implicit()

%%% NB for now we are only loading block 2
%%% (block 1 did not involve persistence decisions)
%%% the data set is returned as if it contained just one block

% identify the datafiles to be loaded
dataDir = '~/Google Drive/wtw_discrete_implicit/data/';
d = dir(fullfile(dataDir,'wtw_discrete_implicit*.mat'));
dfnames = {d(:).name}';

%%% special step to remove an incomplete subject
dfnames(strcmp(dfnames,'wtw_discrete_implicit_BX8427_1.mat')) = [];

n = numel(dfnames);

% loop over subjects
for sIdx = 1:n
    
    % load and format this subject's data (subfunction below)
    dfile = dfnames{sIdx};
    subjData = loadData(fullfile(dataDir,dfile));
    
    % identify the group label
    switch subjData.cbal
        case 1, subjData.grpID = 'congruHPcb1';
        case 2, subjData.grpID = 'incongLPcb2';
        case 3, subjData.grpID = 'incongHPcb3';
        case 4, subjData.grpID = 'congruLPcb4';
        otherwise, error('unexpected cbal value');
    end
    
    % append this subject to group
    grpData(sIdx) = subjData; %#ok<AGROW>
    
end

end % main function



%%% subfunction to load and format one subject's data
function [subjData] = loadData(dfname)

% load the datafile
d = load(dfname);

% assess the number of blocks
nBks = numel(d.dataHeader.distribs);

% assess which trials are complete
% (there may be a partial data record for the last trial in a block, if
% time ran after the trial began but before the outcome was delivered)
isComplete = ~cellfun(@isempty,{d.trialData.outcomeTime}');

% put together output struct
subjData.id = d.dataHeader.id;
subjData.cbal = d.dataHeader.cbal;
subjData.nBks = nBks;
subjData.blockDuration = d.dataHeader.sessionDurationInMin*60; % nominal block length, converted to seconds
subjData.distribs = d.dataHeader.distribs;
subjData.earnings = d.trialData(end).totalEarned;
subjData.earningsUnits = 'cents';

% include fields for explicit judgment tasks
% subjData.explicit_gut = d.dataHeader.explicit_gut;
% subjData.explicit_dist = d.dataHeader.explicit_dist;

bkIdx = [d.trialData.blockNum]';
trialData = struct([]);
%%% unique for wtw_implicit:
%%% loading data for block 2 only (the free choice phase)
for b = 2 
    
    % identify trials belonging to this block (complete trials only)
    idx = (bkIdx==b & isComplete);
    
    % add data fields for trial-level variables
    trialData(b).trialNums = (1:sum(idx))';
    trialData(b).designatedWait = [d.trialData(idx).designatedWait]';
    trialData(b).outcomeWin = [d.trialData(idx).payoff]'>5;
    trialData(b).outcomeQuit = [d.trialData(idx).payoff]'<5;
    trialData(b).payoff = [d.trialData(idx).payoff]';
    trialData(b).startTime = [d.trialData(idx).initialTime]';
    trialData(b).rewardTime = [d.trialData(idx).rwdOnsetTime]';
    trialData(b).latency = [d.trialData(idx).latency]';
    trialData(b).rewardRT = trialData(b).latency - trialData(b).rewardTime;
    trialData(b).outcomeTime = [d.trialData(idx).outcomeTime]';
    trialData(b).totalEarned = [d.trialData(idx).totalEarned]';
    
end

%%% unique for wtw_implicit:
%%% return a data set with just one block, corresponding to block 2
%%% block 2 is the only free-choice phase
%%% (block 1 will be important later for RT analyses)
subjData.nBks = 1;
subjData.distribs(1) = [];
trialData(1) = trialData(2);
trialData(2) = [];

% add trialData to output
subjData.trialData = trialData;

end % subfunction loadData






