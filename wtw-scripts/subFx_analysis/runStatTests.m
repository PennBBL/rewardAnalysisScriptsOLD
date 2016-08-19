function [] = runStatTests(data)
% subfunction to run stats by group and print results
% Input:
%   results is a struct array with a field for each variable to be tested.
%     Each of these is in turn a struct with a field for each participant
%     group. Each group field holds a data matrix with 2 columns (block A
%     and B) and a row for each subject.

% labels for data columns within a single group
% (elements 2-3 are unused if there is only one block)
dataLabels = {'bk1', 'bk2', 'bkDiff'};

grpNames = fieldnames(data);
nGrps = length(grpNames);
for g = 1:nGrps
    thisGrp = grpNames{g};
    grpDataMat = data.(thisGrp);
    grpData.(thisGrp){1} = grpDataMat(:,1); % block 1 data
    if size(grpDataMat,2)>1 % if there are 2 blocks
        grpData.(thisGrp){2} = grpDataMat(:,2); % block 2 data
        grpData.(thisGrp){3} = grpDataMat(:,2) - grpDataMat(:,1); % difference, block 2 - block 1
    end

    % descriptive stats and tests on just one group
    fprintf('  %s group only:\n',thisGrp);
    for i = 1:length(grpData.(thisGrp))
        % deal with the possibility of missing cases
        grpData.(thisGrp){i} = grpData.(thisGrp){i}(~isnan(grpData.(thisGrp){i}));
        % descriptive statistics
        fprintf('    %s: n = %d, median = %1.2f, IQR = %1.2f to %1.2f\n',...
            dataLabels{i},length(grpData.(thisGrp){i}),...
            median(grpData.(thisGrp){i}),prctile(grpData.(thisGrp){i},[25,75]));
        % for the difference, test against zero
        if i==3
            fprintf('      signed-rank p = %1.4f\n',signrank(grpData.(thisGrp){i}));
        end
    end % loop over up to 3 data columns
end % loop over subject groups

% independent-samples comparisons between groups
for grpIdx1 = 1:(nGrps-1)
    for grpIdx2 = (grpIdx1+1):nGrps
        fprintf('  %s vs. %s:\n',grpNames{grpIdx1},grpNames{grpIdx2})
        for i = 1:length(grpData.(grpNames{grpIdx1}))
            rs_p = ranksum(grpData.(grpNames{grpIdx1}){i},grpData.(grpNames{grpIdx2}){i});
            [ks_h, ks_p, ks_stat] = kstest2(grpData.(grpNames{grpIdx1}){i},grpData.(grpNames{grpIdx2}){i});
            fprintf('    %s: rank-sum p = %1.4f; k-s p = %1.4f (k-s stat = %1.2f)\n',...
                dataLabels{i},rs_p,ks_p,ks_stat);
        end
    end
end
    

end % function runStatTests