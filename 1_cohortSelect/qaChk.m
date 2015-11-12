function out = qaChk(scanid,chkmat)

if isnan(scanid)
    out = 0;
    return
end

idx = find(chkmat{1}==scanid);
qaStatus = chkmat{2};
qaStatus = qaStatus{idx};

if strcmp(qaStatus,'QC_OK')
    out = 1;
else
    out = 0;
end