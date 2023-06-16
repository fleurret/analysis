function [mAM, mNAM, cAM, cNAM] = mas(data,targetTrials,omitnan)
% dp = neurometric_dprime(data,targetTrials,[omitnan])
% 
% Computes a neurometric d' comparing data samples where targetTrials is true
% vs where it is false.
% 
% Inputs:
%   data    ...     d' will be computed for each column of the matrix. If
%                   data is a vector, then one d' will becomputed for the
%                   entire vector.
%   targetTrials .... 1xN logical vector with N being the same length as
%                     the number of columns in data if it is a matrix, or
%                     the number of elements in data if data is a vector.
%                     True values indicate positive cases (signal
%                     presented) and false values indicate negative cases
%                     (no signal or reference signal presented).
%   omitnan     ... 1x1 logical determines if the calculations should or
%                   should not ignore NaN values. default = true
% 
% formula:  dp = 2.*(mT - mF) ./ (sT + sF);
% 
%   where 'T' are the samples identified in targetTrials, and 'F' are the
%   samples not identified in targetTrials. 'm' is the mean, 's' is the
%   standard deviation of 'T' or 'F'
% 
% 
% DJS 2021
% edited RY 6/12/2023

narginchk(2,3);

nanflag = 'omitnan';
if nargin == 3 && ~omitnan
    nanflag = 'includenan';
end

if isvector(data)
    data = data(:)';
end

assert(isequal(size(data,2),length(targetTrials)),'epa:metric:neurometric_dprime:UnequalSizes', ...
    'size(data,2) must equal length(targetTrials)')

mAM = mean(data(:,targetTrials),nanflag);
mNAM = mean(data(:,~targetTrials),nanflag);

sAM = std(data(:,targetTrials),nanflag);
sNAM = std(data(:,~targetTrials),nanflag);

cAM = mAM/sAM;
cNAM = mNAM/sNAM;
