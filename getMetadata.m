function [directory,bacDays,wormGeno,frameRate,numFrames,comment] = getMetadata(baseDir,date,numROI,growthExp)

% by default: not growthExp
if nargin<4
    growthExp = false;
end

% read metadata
if growthExp
    metadata = readtable([baseDir 'metadata_IVIS_growthExp.xls']);
else
    metadata = readtable([baseDir 'metadata_IVIS_timeSeries.xls']);
end
% find row index for the experiment
expRowIdx = find(strcmp(string(metadata.date),date));
% get directory name
subDirName = string(metadata.subDirName(expRowIdx));
directory = char(strcat(fullfile(baseDir,subDirName),filesep));
% get row indices to extract bacteria information
startBacDatesColIdx = find(strcmp(metadata.Properties.VariableNames,'sample_bac_date_1'));
endBacDatesColIdx = find(strcmp(metadata.Properties.VariableNames,['sample_bac_date_',num2str(numROI)]));
bacDates = string(table2array(metadata(expRowIdx,startBacDatesColIdx:endBacDatesColIdx)));
bacDays = datenum(date,'yyyymmdd')- datenum(bacDates,'yyyymmdd');
% get row indices to extract worm information
startWormGenoColIdx = find(strcmp(metadata.Properties.VariableNames,'sample_worm_geno_1'));
endWormGenoColIdx = find(strcmp(metadata.Properties.VariableNames,['sample_worm_geno_',num2str(numROI)]));
wormGeno = table2array(metadata(expRowIdx,startWormGenoColIdx:endWormGenoColIdx));
% get any existing comment
commentColIdx = find(strcmp(metadata.Properties.VariableNames,'comment'));
comment = table2array(metadata(expRowIdx,commentColIdx));
if strcmp(class(comment),'cell')
    if ~isempty(comment{1})
        comment = comment{1};
    end
else
    comment = '';
end
% get additional information
frameRate = 60/metadata.frameInterval_min(expRowIdx); % frames per hour
numFrames = metadata.numFrames(expRowIdx);

end