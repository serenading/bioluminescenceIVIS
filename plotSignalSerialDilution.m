%clear
%close all

% set analysis variables
numReps = 3; % 3 by default
dilutionFactors = [10 4 2];
exposure = 3; % [1 3 6 12]; % use 1
expDate = 20190312; % yyyymmdd 20190307 20190312 20190320
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
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',25,...
    'LineWidth',3);

% create figure
addpath('../AggScreening/auxiliary/')
serialDilutionSignalFig = figure; hold on
pooledFig = figure; hold on

% go through each dilution
conc = [2^-7 2^-6 2^-5 2^-4 2^-3 2^-2 2^-1 2^0]; % actual concentrations for 2 fold dilution series
for dilutionCtr = 3%1:numel(dilutionFactors)  % 3 is the 2 fold dilution series
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
    % H = shadedErrorBar(conc,signal,{@median,@std},{'r-o','markerfacecolor','r'});
    H = shadedErrorBar(1:size(signal,2),signal,{@median,@std},{'r-o','markerfacecolor','r'});
    set(gca,'xscale','linear')
    set(gca,'yscale','log')
    ylim([9e6 1e9])
    ylabel('bioluminescence (photons/s)')
    xlabel('dilution')
    xticklabels({'2^{-7}','2^{-6}','2^{-5}','2^{-4}','2^{-3}','2^{-2}','2^{-1}', '1'})
end

% % plot on log-log plot of normalised bioluminescence
% figure; H = shadedErrorBar(conc,normAll,{@median,@std},{'r-o','markerfacecolor','r'});
% ax = gca;
% set(gca,'yscale','log')
% set(gca,'xscale','log')
% ax.YGrid = 'on';
% ax.XGrid = 'on';
% ax.MinorGridLineStyle = '-';
% ax.MinorGridColor = [0.8,0.8,0.8];
% xlim([0.015 1])
% xlabel('concentration')
% ylabel('normalised bioluminescence')

% export figure
figurename = ['results/serialDilution/signalLivingImage_' num2str(expDate) session '_exp' num2str(exposure) 's'];
if saveResults
    exportfig(serialDilutionSignalFig,[figurename '.eps'],exportOptions)
end