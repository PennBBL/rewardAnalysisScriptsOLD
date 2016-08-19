function [] = anGrp()
% analyze results of a wtw experiment

%%% CONFIGURATION SETTINGS %%%
% (these may later be moved out to a separate config file)

% settings part I: which study to analyze
% exptName = 'qtask_mdd';
% exptName = 'qtask_trc';
% exptName = 'qtask_ftd';
% exptName = 'qtask_vmpfc';  %%% edit loadData_vmpfc.m to control whether session 1 or 2 is analyzed
% exptName = 'qtask_upmc';
% exptName = 'wtw_discrete';
% exptName = 'wtw_info';
 exptName = 'wtw_implicit'; %%% only block 2 is loaded
% exptName = 'wtw_work1';

% settings part II: which analyses to conduct
plotIndivs = false; % pause with a plot of each subject's data

% defaults
runTest.AUC = true;
runTest.AUC_after1s = true;
runTest.AUC_2ndHalf = false;
runTest.AUC_after1s_2ndHalf = false;
runTest.FastQuits = true;
runTest.TotalEarnings = true;
runTest.BlockDuration = true;
runTest.RunningWTW = true;
runTest.RT = false;

%%% END OF CONFIGURATION SETTINGS %%%




% set path to subfunctions
addpath('subFx_analysis');
addpath('subFx_load');

% determine which experiment is being analyzed
fprintf('\n========================\n');
fprintf('Experiment: %s\n',exptName);
fprintf('========================\n\n');
switch exptName
    case 'qtask_mdd'
        loadFx = @loadData_mdd;
        truncPt = 16; % time in s up to which survival curves are computed
        runTest.fieldsForTxtOutput = {'AUC_after1s'};
        runTest.AUC_2ndHalf = true;
        runTest.AUC_after1s_2ndHalf = true;
    case 'qtask_trc'
        loadFx = @loadData_trc;
        truncPt = 16; % time in s up to which survival curves are computed
    case 'qtask_ftd'
        loadFx = @loadData_ftd;
        truncPt = 16;
        blockSec = 420;
        % runTest.BlockDuration = false; % not loading the necessary data (so far)
        runTest.FastQuits = false; % not relevant b/c of different interface
        runTest.TotalEarnings = false; % not meaningful b/c of eprime bug
        runTest.AUC_2ndHalf = true;
    case 'qtask_vmpfc'
        loadFx = @loadData_vmpfc;
        truncPt = 20;
        blockSec = 720; % 12-min blocks
        runTest.FastQuits = false; % not relevant b/c of different interface
        runTest.AUC_2ndHalf = true;
    case 'qtask_upmc'
        loadFx = @loadData_upmc;
        truncPt = 20; % discrete distribution: 1, 2, 3, or 20 s. 
        blockSec = 300;
        runTest.AUC_2ndHalf = false;
        runTest.RunningWTW = true;
        runTest.TotalEarnings = true;
        runTest.BlockDuration = false;
        runTest.FastQuits = true;
        runTest.fieldsForTxtOutput = {'AUC_after1s', 'TotalEarnings'};
    case 'wtw_discrete'
        loadFx = @loadData_wtwDiscrete;
        truncPt = 20;
        runTest.FastQuits = false;
        runTest.AUC_after1s = false;
    case 'wtw_implicit'
        loadFx = @loadData_implicit;
        truncPt = 20;
        runTest.FastQuits = false;
        runTest.AUC_after1s = false;
        runTest.RT = true;
    case 'wtw_info'
        loadFx = @loadData_wtwInfo;
        truncPt = 30;
        runTest.FastQuits = false;
        runTest.AUC_after1s = false;
    case 'wtw_work1'
        loadFx = @loadData_work1;
        truncPt = 20;
        runTest.FastQuits = false;
        runTest.AUC_after1s = false;
    otherwise
        error('Experiment name %s is unrecognized.',exptName);
end

% load data
%   grpData is a struct with an element for each subject
%   some fields hold header information (.id, .grpID, etc)
%   the .trialData field holds another struct, with an element for each
%       block and a field for each trialwise variable
grpData = loadFx();

% examine the assignment of subjects to groups
grpIDs = {grpData(:).grpID};
grpNames = unique(grpIDs);
nGrps = length(grpNames);
for g = 1:nGrps
    gName = grpNames{g};
    grpIdx.(gName) = find(strcmp(gName,grpIDs));
    grpN.(gName) = length(grpIdx.(gName));
    fprintf('%s group: n = %d\n',gName,grpN.(gName));
end

% initialize header parameters
earningsUnits = '';
nBks = [];

% loop over groups
for g = 1:nGrps
    gName = grpNames{g};
    gN = grpN.(gName);
    gIdx = grpIdx.(gName);
    
    % initialize the group-specific sequence of distributions
    distribs.(gName) = {};
    
    % loop over subjects within a group
    for s = 1:gN
        
        % indexing note:
        %   s is this subject's index within the group
        %   sIdx is this subject's index in grpData (the entire sample)
        sIdx = gIdx(s);
        id = grpData(sIdx).id;
        allIDs.(gName){s,1} = id; % store IDs in a struct that parallels the results struct
        
        % keep track of some header parameters
        % (expected to be the same for all subjects)
        % 1. number of blocks -- same for all groups
        if isempty(nBks)
            nBks = grpData(sIdx).nBks;
        else
            assert(nBks==grpData(sIdx).nBks,'inconsistent numbers of blocks');
        end
        % 2. earnings units -- same for all groups
        if isempty(earningsUnits)
            earningsUnits = grpData(sIdx).earningsUnits;
        else
            assert(strcmp(earningsUnits,grpData(sIdx).earningsUnits),...
                'inconsistent earningsUnits');
        end
        % 3. list of distribution names -- may differ by group
        if isempty(distribs.(gName))
            distribs.(gName) = grpData(sIdx).distribs;
        else
            try
                assert(all(strcmp(distribs.(gName),grpData(sIdx).distribs)),...
                    'inconsistent distribution names in group %s',gName);
            catch ME
                disp(getReport(ME));
                keyboard;
            end
        end
        
        % initialize data structures for this subject
        kmsc = cell(1,nBks);
        kmsc_con = cell(1,nBks);
        kmsc_2ndHalf = cell(1,nBks);
        kmsc_con_2ndHalf = cell(1,nBks);
        blockAUC = cell(1,nBks);
        blockAUC_con = cell(1,nBks);
        blockAUC_2ndHalf = cell(1,nBks);
        blockAUC_con_2ndHalf = cell(1,nBks);
        
        % loop over blocks within a subject
        for b = 1:nBks
            
            % trial data for the current block
            bkTrials = grpData(sIdx).trialData(b);
            
            % calculate the kaplan-meier survival curve
            if runTest.AUC
                [kmsc{b}, blockAUC{b}] = qtask_kmSurvival(bkTrials,truncPt);
                results.AUC.(gName)(s,b) = blockAUC{b}; % store in output struct
                resultsSC.KMSC.(gName){s,b} = kmsc{b};
            end
            
            % constrained k-m survival curve imposing a minimum wait time
            if runTest.AUC_after1s
                minWait = 1;
                [kmsc_con{b}, blockAUC_con{b}] = qtask_kmSurvival(bkTrials,truncPt,minWait);
                results.AUC_after1s.(gName)(s,b) = blockAUC_con{b}; % store in output struct
                resultsSC.KMSC_after1s.(gName){s,b} = kmsc_con{b};
            end
            
            % calculate k-m curve using only the 2nd half of the block
            if runTest.AUC_2ndHalf || runTest.AUC_after1s_2ndHalf
                % identify the nominal block duration
                bkNomDur = floor(bkTrials.latency(1)) + bkTrials.clockTime(1);
                % index trials w/ onsets later than the nominal halfway-pt
                idx2ndHalf = (bkTrials.startTime>(bkNomDur/2));
                % create a version of the block data w/ only these trials
                fnames = fieldnames(bkTrials);
                for f = 1:length(fnames)
                    fNow = fnames{f};
                    bkTrials_2ndHalf.(fNow) = bkTrials.(fNow)(idx2ndHalf);
                end
            end
            if runTest.AUC_2ndHalf
                % run the analysis as above
                [kmsc_2ndHalf{b}, blockAUC_2ndHalf{b}] = qtask_kmSurvival(bkTrials_2ndHalf,truncPt);
                results.AUC_2ndHalf.(gName)(s,b) = blockAUC_2ndHalf{b}; % store in output struct
            end
            if runTest.AUC_after1s_2ndHalf
                % run the constrained analysis as above
                minWait = 1;
                [kmsc_con_2ndHalf{b}, blockAUC_con_2ndHalf{b}] = qtask_kmSurvival(bkTrials_2ndHalf,truncPt,minWait);
                results.AUC_after1s_2ndHalf.(gName)(s,b) = blockAUC_con_2ndHalf{b}; % store in output struct
            end

            % calculate the number of immediate quits
            % Using a criterion of 100ms matching the cognition paper
            if runTest.FastQuits
                isFastQuit = bkTrials.outcomeQuit & bkTrials.latency<0.1;
                results.FastQuits.(gName)(s,b) = sum(isFastQuit);
            end

            % calculate the total earnings in this block
            if runTest.TotalEarnings
                priorPay = bkTrials.totalEarned(1) - bkTrials.payoff(1); % earnings _before_ the first trial
                finalPay = bkTrials.totalEarned(end);
                results.TotalEarnings.(gName)(s,b) = finalPay - priorPay;
            end
            
            % estimate the duration of the block in seconds
            % (this will generally be an underestimate, based on the final
            % outcome time)
            if runTest.BlockDuration
                results.BlockDuration.(gName)(s,b) = bkTrials.outcomeTime(end);
            end
            
            % get reward RT as a function of delay
            if runTest.RT
                % obtain median RTs
                [medRTs, delayVals, rhoVal] = qtask_RT(bkTrials);
                % record the rho value
                resultsRT.rhoVal.(gName){b}(s,1) = rhoVal;
                % check that delay values match the other subjects in this
                % group and block
                if ~isfield(resultsRT,'delayVals') || ~isfield(resultsRT.delayVals,gName)
                    resultsRT.delayVals.(gName){b} = delayVals; % initialize
                else
                    assert(numel(resultsRT.delayVals.(gName){b})==numel(delayVals) && ...
                        all(resultsRT.delayVals.(gName){b}==delayVals),'RT delay values mismatch')
                end
                % record the median RTs
                resultsRT.medRTs.(gName){b}(s,:) = medRTs;
                
            end
            
        end % loop over blocks
        
        % running WTW (across multiple blocks if applicable)
        if runTest.RunningWTW
            sData = grpData(sIdx).trialData;
            if isfield(grpData(sIdx),'blockDuration') % use block length info from datafile if available
                blockSec = grpData(sIdx).blockDuration;
            end
            results_runningWTW.(gName)(s,:) = runningWtw(sData,blockSec,truncPt)';
        end
        
        % plot individual data if requested (using external subfunction)
        if plotIndivs && runTest.AUC
            if ~runTest.AUC_after1s % placeholders if constrained AUC analysis isn't being run
                blockAUC_con{1} = nan;
                kmsc_con = [];
            end
            fprintf('\n\nSubject %s (%s)\n',id,gName);
            for b = 1:nBks
                fprintf('  Bk %d: AUC = %1.2f, constrained AUC = %1.2f\n',...
                    b,blockAUC{b},blockAUC_con{b});
            end
            createIndivPlots(id,gName,grpData(sIdx).trialData,kmsc,kmsc_con);
            input('Press ENTER to continue.');
        end
        
    end % loop over subjects
end % loop over groups

% report information about the distribution names in each group
fprintf('\nTiming distribution names:\n');
for g = 1:nGrps
    gName = grpNames{g};
    fprintf('  %s:\n    ',gName);
    for b = 1:nBks
        fprintf('Block %d = %s; ',b,distribs.(gName){b});
    end
    fprintf('\n');    
end % loop over groups

% if requested, save subject-level summary statistics to text files
if isfield(runTest,'fieldsForTxtOutput') && ~isempty(runTest.fieldsForTxtOutput)
    txtOutput(exptName,runTest.fieldsForTxtOutput,allIDs,results);
end
        
%%% for each variable stored as a field in "results", plot and run stats.
% each of these variables has one value for each subject-x-block

% common (across variables) plotting parameters
params.common.nBks = nBks;
params.common.distribs = distribs;
% variable-specific plotting parameters
% y-axis labels
params.AUC.ylabel = 'Seconds';
params.AUC_after1s.ylabel = 'Seconds';
params.AUC_2ndHalf.ylabel = 'Seconds';
params.AUC_after1s_2ndHalf.ylabel = 'Seconds';
params.FastQuits.ylabel = 'Number of trials';
params.TotalEarnings.ylabel = earningsUnits;
params.BlockDuration.ylabel = 'Seconds';
% y-axis ranges
params.AUC.yLim = [0, truncPt];
params.AUC_after1s.yLim = [0, truncPt];
params.AUC_2ndHalf.yLim = [0, truncPt];
params.AUC_after1s_2ndHalf.yLim = [0, truncPt];

% loop over the variables to be tested
close all;
vblNames = fieldnames(results);
for v = 1:length(vblNames)
    
   vName = vblNames{v};
   fprintf('\nTests on %s:\n',vblNames{v});
   
   % plot
   plotByGrp(vName,results.(vName),params.(vName),params.common);
   
   % stats
   runStatTests(results.(vName));
   
end % loop over variables

% separate plotting function for running WTW
if runTest.RunningWTW
    runningWtw_plot(results_runningWTW,blockSec,truncPt);
end

% separate plotting function for full survival curves
scFields = {'KMSC', 'KMSC_after1s'};
for i = 1:numel(scFields)
    thisField = scFields{i};
    if isfield(resultsSC,thisField)
        plotGroupSC(thisField,resultsSC.(thisField),truncPt);
    end
end

end % main function














