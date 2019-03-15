clear
close all

% set analysis variables
numReps = 3; % 3 by default
dilutionFactors = [10 4 2];
exposure = 12; % [1 3 6 12]; % use 1
expDate = 20190312; % yyyymmdd
session = 'pm'; % 'am' or 'pm'
saveResults = false;

% suppress specific warning messages associated with the text file format
warning off MATLAB:table:ModifiedAndSavedVarnames 
warning off MATLAB:handle_graphics:exceptions:SceneNode

% load metadata and signal measurement file
metadata = readtable('/Volumes/behavgenom$/Serena/IVIS/serialDilution/metadata_IVIS_serialDilution.xls');
mFilename = ['/Volumes/behavgenom$/Serena/IVIS/serialDilution/' num2str(expDate) session '/measurements.txt'];
signalTable = readtable(mFilename,'ReadVariableNames',1,'delimiter','\t');
varName = 'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';

% set figure export options
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',30,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',25,...
    'LineWidth',3);

% create figure
addpath('../AggScreening/auxiliary/')
serialDilutionSignalFig = figure; hold on

% go through each dilution
for dilutionCtr = 1:numel(dilutionFactors)
    dilutionFactor = dilutionFactors(dilutionCtr);
    wells = getWellROIs(expDate,session,dilutionFactor);
    %% get signal
    % find image with the correct exposure
    metadataRowIdx = find(metadata.Exposure_sec == exposure & metadata.date == expDate & strcmp(metadata.session, session));
    imageNumber = metadata.imageNumber{metadataRowIdx};
    % linearise wells matrix by row
    numInSeries = size(wells,1);
    wells = reshape(wells',1,[]);
    % pre-allocate
    signal = NaN(1,numel(wells));
    % extract signal
    for wellCtr = numel(wells):-1:1
        well = wells(wellCtr);
        signalTableRowIdx = find(strcmp(signalTable.ImageNumber,imageNumber) & strcmp(signalTable.ROI, ['ROI ' num2str(well)]));
        assert(numel(signalTableRowIdx) == 1, 'More than one imageNumber/ROI combinations found')
        signal(wellCtr) = signalTable.(varName)(signalTableRowIdx);
    end
    % turn signal back into numInSeries x numReps format (same as how wells
    % are originally specified)
    signal = reshape(signal,[numReps,numInSeries])';
    % plot each replicate as an individual line
    xVals = 1:numInSeries;
    for repCtr = 1:numReps
        subplot(1,numel(dilutionFactors),dilutionCtr)
        hold on
        plot(xVals,signal(:,repCtr),'-x')
    end
    xAxisLabels = strings(1,numInSeries);
    % generate x-axis labels
    for seriesCtr = 1:numInSeries
        xAxisLabels(seriesCtr) = [num2str(dilutionFactor) ' -' num2str(seriesCtr-1)];
    end
    xticks(xVals)
    xticklabels(xAxisLabels)
    xlabel('dilution')
    ylabel(varName)
    ylim([0 11e7])
    title(['Dilution factor ' num2str(dilutionFactor)])
end

% export figure
figurename = ['results/serialDilution/signalLivingImage_' num2str(expDate) session '_exp' num2str(exposure) 's'];
if saveResults
    exportfig(serialDilutionSignalFig,[figurename '.eps'],exportOptions)
end