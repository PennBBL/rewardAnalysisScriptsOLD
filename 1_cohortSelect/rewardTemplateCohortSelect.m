IMAGES = 120;
NUMDX = 3;
NAGEBINS = 5;
BBLIDS = 1;
SCANIDS = 2;
AGECOL = 3;
SEX = 4;
DIAGNOSIS = 8;

% Select a cohort for the reward template

fullComplement = fopen('../input/rewardCohort.csv');
qaComplement = fopen('../input/rewardScan_qa.csv');

fullComplement = textscan(fullComplement, '%s%s%s%s%s%s%s%s%s%s%s%s%s','delimiter',',');
qaComplement = textscan(qaComplement,'%s%s','delimiter',',');

% Convert scan IDs in QA information to numeric
scanids = qaComplement{1};
buffer = zeros(size(scanids));
for i = 1:numel(scanids)
    buffer(i) = str2double(scanids{i});
end
qaComplement{1} = buffer;

% Determine age bins
ages = fullComplement{AGECOL};
buffer = zeros(size(ages));
for i = 1:numel(ages)
    buffer(i) = str2double(ages{i});
end
ages=buffer;
agebins = quantile(ages,NAGEBINS-1);

% Generate cell array of subject IDs/scan IDs
balance = 2 * NUMDX * NAGEBINS;
sample = struct();
for i = 1:balance
    cmd = strcat('sample.g',num2str(i),' = [];');
    eval(cmd);
end

% Iterate through all subjects and place them in the correct category
bblids = fullComplement{BBLIDS};
scanids = fullComplement{SCANIDS};
sexes = fullComplement{SEX};
dxs = fullComplement{DIAGNOSIS};
for i = 2:numel(fullComplement{BBLIDS})
    bblid = str2double(bblids{i});
    scanid = str2double(scanids{i});
    sex = str2double(sexes{i});
    dx = diagnosis2num(dxs{i});
    agebin = age2bin(ages(i),agebins);
    col = sex * NUMDX * NAGEBINS + dx * NAGEBINS + agebin;
    if qaChk(scanid,qaComplement) && (dx ~= -1)
        cmd = strcat('sample.g',num2str(col),'=[sample.g',num2str(col),';[bblid,scanid]];');
        eval(cmd);
    end
end

% Determine number of subjects in each sample category
nsubj = zeros(balance,1);
for i = 1:balance
    cmd = strcat('nsubj(i) = size(sample.g',num2str(i),',1);');
    eval(cmd);
end

% Run through categories in order from fewest to most available subjects
[~,order] = sort(nsubj);
cohort = zeros(balance,ceil(IMAGES/balance),2);
for i = 1:balance
    cmd = strcat('curgroup = sample.g',num2str(i),';');
    eval(cmd);
    numIn = 0;
    while numIn < ceil(IMAGES/balance)
        if (isempty(curgroup))
            fprintf('Group %d is data-deficient\n',i);
            break
        end
        cursubj = curgroup(1,:);
        % Ensure that the same subject isn't included twice at multiple
        % timepoints
        alreadyIn = numel(find(cohort(:,:,1)==cursubj(1)));
        if alreadyIn==0
            numIn = numIn + 1;
            cohort(i,numIn,:) = cursubj;
        else
            fprintf('%d is already in the cohort\n',cursubj(1));
        end
        curgroup(1,:) = [];
    end
end
fprintf('%d unique subject IDs selected for inclusion\n',(numel(unique(cohort)))/2);
fprintf('The selected cohort is stored in the variable "cohort"\n');