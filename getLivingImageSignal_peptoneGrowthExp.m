function signal = getLivingImageSignal_peptoneGrowthExp(baseDir,numROI,varName)

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


%% prep work 
% load metadata 
metadata = readtable([baseDir 'metadata_IVIS_peptoneGrowthExp.xlsx']);
% check that imageNumber column of metadata is in ascending order (because
% this is manually pasted into the metadata file so errors may occur)
imageNumberSorted = sort(metadata.imageNumber);
if ~isequal(imageNumberSorted,metadata.imageNumber)
    warning('ImageNumbers are not in ascending order. Errors during manual entry into the metadata file.')
end
% get bacteria inoculation date
bacDate = unique(metadata.sample_bac_date);
if numel(bacDate) ~=1
    warning('More than one bacteria inoculation dates found')
end
% initialise signal matrix (each row is a plate, each column is number of days since inoculation)
numSignalCols = 7;
signal = NaN(numROI*size(metadata,1),numSignalCols); 

%% extract metadata info and signal
signalRowIdx = 1;
expDates = unique(metadata.expDate);
% go through each imaging day
for expDateCtr = 1:numel(expDates)
    expDate = expDates(expDateCtr);
    bacAge = datenum(num2str(expDate),'yyyymmdd')- datenum(num2str(bacDate),'yyyymmdd');
    mFileName = fullfile(baseDir,num2str(expDate),'measurements.txt');
    mSignalTable = readtable(mFileName,'ReadVariableNames',1,'delimiter','\t');
    imageNumbers = unique(mSignalTable.ImageNumber);
    for imageCtr = 1:numel(imageNumbers)
        imageNumber = imageNumbers(imageCtr);
        for ROICtr = 1:numROI
            % write column 1: bacteria inoculation date
            signal(signalRowIdx,1) = bacDate;
            % find the row index for the metadata file to get repID
            metaRowIdx = find(cellfun(@(x) strcmp(x, imageNumber), metadata.imageNumber));
            % write column 2: repID
            signal(signalRowIdx,2) = metadata.repID(metaRowIdx);
            % find the row index for the measurement file that match both metadata imageNumber and ROI number
            mRowIdx  = find(cellfun(@(x) strcmp(x,['ROI ' num2str(ROICtr)]), mSignalTable.ROI) & ... 
            cellfun(@(x) strcmp(x, imageNumber), mSignalTable.ImageNumber));
            % write column 3: signal
            try
            signal(signalRowIdx,3) = mSignalTable.(varName)(mRowIdx);
            catch
                disp([imageNumber ' metadata entry or measurements.txt error'])
            end
            % write column 4: the age of the bacteria (i.e. days since inoculation)
            signal(signalRowIdx,4) = datenum(num2str(expDate),'yyyymmdd')- datenum(num2str(bacDate),'yyyymmdd');
            if signal(signalRowIdx,4) > 30 % probably error in date entry
                warning(['possible date entry error in metadata file: expDate is ' num2str(expDate) ' and bacDate is ' num2str(bacDate)])
            end
            % keep track of the row index, ROI index, and experimental date from metadata file
            if imageCtr <=3
                pepType = 1; % regular peptone
            elseif imageCtr <=6
                pepType = 2; % low peptone
            elseif imageCtr <=9
                pepType = 3; % no peptone
            end
            signal(signalRowIdx,5) = pepType;
            signal(signalRowIdx,6) = ROICtr;
            signal(signalRowIdx,7) = expDate;
            % update signal matrix row counter
            signalRowIdx = signalRowIdx + 1;
        end
    end
end