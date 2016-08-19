function [kmsc, auc, kmsc_grid] = qtask_kmSurvival(trials,truncPt,minWait)
% estimate willingness to wait using kaplan-meier estimator
%
% Inputs:
%   trials: struct array containing one subject's data (see below)
%   truncPt: maximum value for survival curves
%       (set to be common to both conditions)
%   minWait: (OPTIONAL) only consider trials lasting longer than minWait s
%       (assesses willingness to persist after having already started
%       waiting). 
%
% Outputs:
%   kmsc: this subject's survival curve (col1=x, col2=f)
%   auc: area under the curve (scalar)
%   kmsc_grid: a version of the survival curve read out at a standard grid
%     of x values, for averaging survival curves across subjects.
%
% JTM, 2012-08-16
% modified 2013-04-24


% settings for survival curves
scGrid = 1:truncPt; % grid of x values for kmsc_grid
truncPt = scGrid(end); % maximum value for survival curves

% extract the relevant variables
%   "latency" contains trial-by-trial waiting times
%   "isWin" indicates which trials to treat as censored (because, when the
%       reward is delivered, we do not know how much longer the participant
%       would have been willing to wait). 
latency = trials.latency;
isWin = trials.outcomeWin;

% at this point, may restrict which trials are considered
if nargin<3 || isempty(minWait) % if no value for minWait was supplied
    minWait = 0; % use all trials
end
% determine whether trials are being excluded
trialsUsed = true(size(latency)); % initialize as using all trials
if minWait>0
    % fprintf('*** considering ONLY trials begun on large outcome\n');
    trialsUsed = trials.latency > minWait;
    if ~any(trialsUsed) % if there are no trials, return nans
        kmsc = [[0; truncPt], [nan; nan]];
        auc = nan;
        kmsc_grid = nan(size(scGrid));
        return;
    end
end
latency = latency(trialsUsed);
isWin = isWin(trialsUsed);

% calculate the kaplan-meier function
[kmF, kmX] = ecdf(latency,'censoring',isWin,'function','survivor');

% make some modifications to the survival function for comparability across
% participants.
% modification #1: set first x-coord to 0
% (first fx value is always 1; this ensures the curve starts at 0,1)
kmX(1) = 0;
% modification #2: extend the fx
% it now ends at the latest quit time
% extend (with the same value) to the latest reward time (i.e., the
% latest time when a point is censored) if later.
latestWin = max(latency(isWin));
if kmX(end)<latestWin
    kmX(end+1,1) = latestWin;
    kmF(end+1,1) = kmF(end);
end
% modification #3: set the maximum x value so it's the same for all
% subjects
if kmX(end)<truncPt && kmF(end)==0 % if the curve hits zero before truncation point
    % extend the zero value to the truncation point
    kmX(end+1,1) = truncPt;
    kmF(end+1,1) = 0;
elseif kmX(end)<truncPt && kmF(end)>0
    % if the curve ends before truncation point without hitting
    % zero; i.e., the longest latency is censored, while still
    % being below the truncation point.
    % in this case, we have no information about willingness to
    % wait beyond this point. in practice, this will rarely occur
    % and the values involved will be small.
    % arbitrarily assume the subject would have waited the full
    % time on the censored trial.
    % (may want a warning message for this)
    % fprintf('\twarning: latest point censored at %1.2f sec\n',kmX(end));
    % fprintf('\textending wtw rate of %1.2f from %1.2f sec to %1.2f sec\n',kmF(end),kmX(end),truncPt);
    kmX(end+1,1) = truncPt;
    kmF(end+1,1) = kmF(end);
else % if the curve extends beyond the truncation point
    % index the point that will become the last point of the curve
    lastPt = find(kmX>truncPt,1,'first'); 
    kmX((lastPt+1):end) = [];
    kmF((lastPt+1):end) = [];
    kmX(end) = truncPt;
end

% store x and f values in a single 2-column matrix for output
kmsc = [kmX, kmF];

% obtain the area under the survival curve
% for point n (n = 2:N), we add (x_n - x_(n-1)) * y_(n-1)
% basic principle: in between adjacent points x1 and x2, the 
% function holds at the value associated with x1. 
auc = 0;
for i = 2:length(kmX)
    auc = auc + (kmX(i)-kmX(i-1))*kmF(i-1);
end

% resample the survival curve for averaging
% for each "grid" point, take the function value associated with the
% next earlier X value (same principle as above)
nGridPoints = length(scGrid);
kmsc_grid = nan(nGridPoints,2); % col1 = x, col2 = f
for i = 1:nGridPoints
    gridVal = scGrid(i);
    nextEarlierX = find(kmX<=gridVal,1,'last');
    fVal = kmF(nextEarlierX);
    kmsc_grid(i,:) = [gridVal, fVal];
end


        
 



