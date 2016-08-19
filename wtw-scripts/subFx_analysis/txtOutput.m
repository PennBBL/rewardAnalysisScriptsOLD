function [] = txtOutput(exptName,whichFields,allIDs,results)
% Writes subject-level summary statistics to tab-delimited text files.
% The same results are also saved in a matfile. 
%
% Inputs:
%   exptName (string): experiment name
%   whichFields (cell array of strings): which data fields from the 
%       results struct are to be written as text output
%   allIDs: struct with a field for each subgroup, each holding a cell 
%       array of subject IDs.
%   results: struct with a field for each summary statistic, which in turn
%       holds a field for each subgroup, containing a nSubjects-by-nBlocks
%       matrix of summary statistics.
%
% Notes:
% -> This function is called by anGrp.m.
% -> A separate text file is saved for each element in whichFields and for
%       each block of the experiment.
% -> Each output file only contains one summary statistic from one 
%       experimental block. This is the 3rd column of the output file
%       (column 1 is subject ID and column 2 is group name).

% location of files to be written
exptDir = fullfile('txt_output',exptName);
if ~exist(exptDir,'dir'), mkdir(exptDir); end

% check dimensions of the inputs
grpNames = fieldnames(allIDs);
nGrps = numel(grpNames);
nFields = numel(whichFields);
nBlocks = size(results.(whichFields{1}).(grpNames{1}),2);

% loop over files to write (fields and blocks)
for fIdx = 1:nFields
    thisField = whichFields{fIdx};
    for bk = 1:nBlocks
        
        % initialize matfile output
        dOut = struct([]);
        
        % a file will be written for each field and each block
        % construct the filename
        fname = fullfile(exptDir,thisField);
        if nBlocks>1, fname = sprintf('%s_block%d',fname,bk); end
        fnameMat = [fname,'.mat'];
        fname = [fname,'.txt']; %#ok<AGROW>
        % open the file to write
        fid = fopen(fname,'w');
        
        % loop over groups and subjects to write data to the file
        for gIdx = 1:nGrps
            thisGroup = grpNames{gIdx};
            n = numel(allIDs.(thisGroup)); % number of subject IDs in this group
            assert(size(results.(thisField).(thisGroup),1)==n,...
                'Data matrix mismatches the number of IDs');
            for sIdx = 1:n % subject index within group
                thisID = allIDs.(thisGroup){sIdx};
                thisDatum = results.(thisField).(thisGroup)(sIdx,bk);
                fprintf(fid,'%s\t%s\t%1.3f\n',thisID,thisGroup,thisDatum);
            end % loop over subjects
            % matfile output
            dOut(1).(thisGroup).id = allIDs.(thisGroup);
            dOut(1).(thisGroup).(thisField) = results.(thisField).(thisGroup)(:,bk);
        end % loop over groups
        
        % close the file
        fclose(fid);
        
        % save the matfile
        save(fnameMat,'-struct','dOut');
        
    end % loop over blocks
end % loop over fields




