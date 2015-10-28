function out = age2bin(age,bins)

nbins = numel(bins);
for i = 1:nbins
    if age < bins(i)
        out = i;
        return
    end
end
out = nbins + 1;
end