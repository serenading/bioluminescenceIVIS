function signal = getLivingImageSignal_growthExp(baseDir,numROI,varName)

%% function generates a Nx4 matrix, where 
% column 1 contains bacteria inoculate date,
% column 2 contains replicate ID,
% column 3 contains signal readout,
% column 4 contains the age of bacteria (days of inoculation on solid media).

% INPUTS:
% baseDir: string, path to base directory.
% numROI: scalar, number of ROI contained in the the images. Default = 9.
% varName: string, the variable name associated with the measurement files. Use 'AvgRadiance_p_s_cm__sr_' % or 'TotalFlux_p_s_'.

% OUTPUT:
% signal: Nx4 matrix, double precision.

%% prep work 
% load metadata 
metadata = readtable([baseDir 'metadata_IVIS_growthExp.xls']);
% initialise signal matrix (each row is a plate, each column is number of days since inoculation)
signal = NaN(numROI*size(metadata,1),4); 

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
            % write signal value into the third column
            signal(signalRowIdx,3) = mSignalTable.(varName)(mRowIdx);
            % write the age of the bacteria (i.e. days of inoculation) into the fourth column
            signal(signalRowIdx,4) = datenum(num2str(expDate),'yyyymmdd')- datenum(num2str(bacDate),'yyyymmdd');
        end
    end
end

%% remove NaN entries from signal matrix
signal = signal(~isnan(signal));
signal = reshape(signal,numel(signal)/4,4);