%function signal = getLivingImageSignal_peptoneGrowthExp(baseDir,numROI,varName)

%% function generates a Nx4 matrix, where 
% column 1 contains bacteria inoculate date,
% column 2 contains replicate ID,
% column 3 contains signal readout,
% column 4 contains the age of bacteria (days since inoculation on solid media),
% column 5 contains the corresponding row indedx of the metadata file,
% column 6 contains the corresponding ROI number from the metadata file.
% column 7 contains the correspoinding experimental date from the metadata file.

% INPUTS:
% baseDir: string, path to base directory.
% numROI: scalar, number of ROI contained in the the images. Default = 9.
% varName: string, the variable name associated with the measurement files. Use 'AvgRadiance_p_s_cm__sr_' % or 'TotalFlux_p_s_'.

% OUTPUT:
% signal: Nx7 matrix, double precision.
baseDir = '/Volumes/behavgenom$/Serena/IVIS/peptoneGrowth/';
numROI = 3;
varName = 'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';


%% prep work 
% load metadata 
metadata = readtable([baseDir 'metadata_IVIS_peptoneGrowthExp.xlsx']);
% check that imageNumber column of metadata is in ascending order (because
% this is manually pasted into the metadata file so errors may occur)
imageNumberSorted = sort(metadata.imageNumber);
if ~isequal(imageNumberSorted,metadata.imageNumber)
    warning('ImageNumbers are not in ascending order. Errors during manual entry into the metadata file.')
end

% initialise signal matrix (each row is a plate, each column is number of days since inoculation)
numSignalCols = 7;
signal = NaN(numROI*size(metadata,1),numSignalCols); 

%% extract metadata info and signal
% go through each imaging day
expDates = unique(metadata.expDate);
for expDateCtr = 1:numel(expDates)
    expDate = expDates(expDateCtr);
    bacAge = datenum(num2str(expDate),'yyyymmdd')- datenum(num2str(bacDate),'yyyymmdd');
    mFileName = fullfile(baseDir,num2str(expDate),'measurements.txt');
    mSignalTable = readtable(mFileName,'ReadVariableNames',1,'delimiter','\t');
    imageNumbers = unique(mSignalTable.ImageNumber);
 