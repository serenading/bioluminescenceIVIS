clear
%close all

% set analysis variables
numReps = 3; % 3 by default
dilutionFactors = [10 4 2];
exposure = 3; % [1 3 6 12]; % use 1
expDate = 20190307; % yyyymmdd
session = 'pm'; % 'am' or 'pm'
saveResults = false;

% suppress specific warning messages associated with the text file format
warning off MATLAB:table:ModifiedAndSavedVarnames 
warning off MATLAB:handle_graphics:exceptions:SceneNode

% load metadata and signal measurement file
metadata = readtable('/Volumes/behavgenom$/Serena/bioluminescence/IVIS/serialDilution/metadata_IVIS_serialDilution.xls');
mFilename = ['/Volumes/behavgenom$/Serena/bioluminescence/IVIS/serialDilution/' num2str(expDate) session '/measurements.txt'];
signalTable = readtable(mFilename,'ReadVariableNames',1,'delimiter','\t');
varName = 'TotalFlux_p_s_';%'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';

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
pooledFig = figure; hold on

% go through each dilution
for dilutionCtr = 3%1:numel(dilutionFactors)
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
        %subplot(1,numel(dilutionFactors),dilutionCtr)
        set(0,'CurrentFigure',serialDilutionSignalFig)
        hold on
        plot(xVals,signal(:,repCtr),'-x')
    end
    xAxisLabels = strings(1,numInSeries);
    % generate x-axis labels
    for seriesCtr = 1:numInSeries
        %xAxisLabels(seriesCtr) = [num2str(dilutionFactor) ' -' num2str(seriesCtr-1)];
        xAxisLabels(seriesCtr) = ['1e-' num2str(seriesCtr-1)];
    end
    xticks(xVals)
    xticklabels(xAxisLabels)
    xlabel('dilution')
    ylabel('signal (photons/s)')
    ylim([1e6 1e9])
        set(gca,'yscale','linear')
    set(gca,'xscale','log')
    title(['Dilution factor ' num2str(dilutionFactor)])
    
    % pooled plot 
    signal = fliplr(signal'); 
    set(0,'CurrentFigure',pooledFig)
    H = shadedErrorBar(1:size(signal,2),signal,{@median,@std},{'r-o','markerfacecolor','r'});
    set(gca,'xscale','linear')
    set(gca,'yscale','log')
    ylim([1e6 1e9])
    ylabel('signal (photons/s)')
    xlabel('dilution')
    xticklabels({'2e-7','2e-6','2e-5','2e-4','2e-3','2e-2','2e-1', '1'})
end

% export figure
figurename = ['results/serialDilution/signalLivingImage_' num2str(expDate) session '_exp' num2str(exposure) 's'];
if saveResults
    exportfig(serialDilutionSignalFig,[figurename '.eps'],exportOptions)
end