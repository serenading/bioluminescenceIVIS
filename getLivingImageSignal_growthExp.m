function signal = getLivingImageSignal_growthExp(baseDir,numROI,varName)

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
metadata = readtable([baseDir 'metadata_IVIS_growthExp.xls']);
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
% go through each row of metadata
for imageCtr = 1:size(metadata,1)
    % load the appropriate measurements.txt file
    expDate = metadata.expDate(imageCtr);
    mFileName = fullfile(baseDir,num2str(expDate),'measurements.txt');
    mSignalTable = readtable(mFileName,'ReadVariableNames',1,'delimiter','\t');
    % extract imageNumber
    imageNumber = metadata.imageNumber{imageCtr};
    % go through each ROI
    for ROICtr = 1:numROI
        % get bacteria inoculate date
        metaROIColIdx = find(strcmp(metadata.Properties.VariableNames,['sample_bac_date_' num2str(ROICtr)]));
        bacDate = metadata{imageCtr,metaROIColIdx};
        % get the row index for signal matrix
        signalRowIdx = (imageCtr-1)*numROI+ROICtr;
        % ignore NaN entries for bacteria inoculation date i.e. ROI on images that we don't care about
        if ~isnan(bacDate)
            % write bacDate into the first column
            signal(signalRowIdx,1) = bacDate;
            % write repID into the second column
            signal(signalRowIdx,2) = metadata.repID(imageCtr);
            % find the row index for the measurement file that match both metadata imageNumber and ROI number
            mRowIdx  = find(cellfun(@(x) strcmp(x,['ROI ' num2str(ROICtr)]), mSignalTable.ROI) & ...
                cellfun(@(x) strcmp(x, imageNumber), mSignalTable.ImageNumber));
            if numel(mRowIdx)==0
                warning(['no mRowIdx found for ROICtr = ' num2str(ROICtr) ', imageCtr = ' num2str(imageCtr)]);
            end
            % write signal value into the third column
            signal(signalRowIdx,3) = mSignalTable.(varName)(mRowIdx);
            % write the age of the bacteria (i.e. days since inoculation) into the fourth column
            signal(signalRowIdx,4) = datenum(num2str(expDate),'yyyymmdd')- datenum(num2str(bacDate),'yyyymmdd');
            if signal(signalRowIdx,4) > 30 % probably error in date entry
                warning(['possible date entry error in metadata file: expDate is ' num2str(expDate) ' and bacDate is ' num2str(bacDate)])
            end
            % keep track of the row index, ROI index, and experimental date from metadata file
            signal(signalRowIdx,5) = imageCtr;
            signal(signalRowIdx,6) = ROICtr;
            signal(signalRowIdx,7) = expDate;
        end
    end
end

%% remove NaN entries from signal matrix
signal = signal(~isnan(signal));
signal = reshape(signal,numel(signal)/numSignalCols,numSignalCols);