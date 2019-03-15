clear
% close all

%% script plots bioluminescence signal acquired on the IVIS spectrum, 
% of bacteria that have been inoculated lengths of days (i.e. number of days).
% Signal is measured by Living Image 4.3.1 software.

%% set up
% set analysis parameters
baseDir = '/Volumes/behavgenom$/Serena/IVIS/growthExp/';
numROI = 9;
varName = 'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';
% filter signal options 
repIDsToKeep = []; % [] by default to keep all. [repID1,repID4:repID7] to subselect plate replicates for analysis
bacDatesToDrop = [];%[20190228:20190312]; % [] by default to exclude none. [yyyymmdd, yyyymmmdd:yyyymmdd] to ignore experiments with bacteria inoculated on a particular date
expDatesToDrop = [20190306:20190308]; % [] by default to exclude none. [yyyymmdd] to ignore experiments collected on a particular date
ROIsToDrop = []; % [] by default to exclude none. [ROInumber] to ignore experiments from a particular ROI
separateSignalWeek = true;
separateSignalPlateID = true;
% plotting and export options
YAxisLimit = [0 8e7];
saveResults = false;
% set figure export options
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',30,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',25,...
    'LineWidth',3);

% initialise
addpath('../AggScreening/auxiliary/')
daysOfInoculationBoxPlot = figure;
if separateSignalPlateID
    growthCourseLinePlot = figure; hold on
end

% suppress specific warning messages associated with the text file format
warning off MATLAB:table:ModifiedAndSavedVarnames
warning off MATLAB:handle_graphics:exceptions:SceneNode

%% get signal
% get overall signal matrix
signal = getLivingImageSignal_growthExp(baseDir,numROI,varName);
% get n numbers for each inoculation length for the overall signal matrix
uniqueBacDays = unique(signal(:,4));
for uniqueBacDayCtr = numel(uniqueBacDays):-1:1
    nNumberBacDays(uniqueBacDayCtr) = sum(signal(:,4) == uniqueBacDays(uniqueBacDayCtr));
end

%% filter and separate signal as specified
% filter signal as specified
signal = filterLivingImageSignal_growthExp(signal,repIDsToKeep,expDatesToDrop,bacDatesToDrop,ROIsToDrop);
% separate signal plots based on week of growth
if separateSignalWeek
    weeklySignal = separateSignalByWeek(signal);
end
% separate signal plots based on each plate ID
if separateSignalPlateID
    [plateIDs, plateIDSignals,numUniqueBacDates] = separateSignalByPlateID(signal);
end
    
%% plot and format days of inoculation box plot
set(0,'CurrentFigure',daysOfInoculationBoxPlot)
if separateSignalWeek
    numWeeks = numel(weeklySignal);
    for weekCtr = 1:numWeeks
        set(0,'CurrentFigure',daysOfInoculationBoxPlot)
        subplot(1,numWeeks,weekCtr)
        boxplot(weeklySignal{weekCtr}(:,1),weeklySignal{weekCtr}(:,2))
        title(['Week ' num2str(weekCtr)])
        xlabel('days of inoculation')
        ylabel(varName)
        ylim(YAxisLimit)
        hold on
    end
else
    boxplot(signal(:,3),signal(:,4))
    xlabel('days of inoculation')
    ylabel(varName)
    ylim(YAxisLimit)
end

% export figure
figurename = 'results/growthExp/signalLivingImage';
if separateSignalWeek
    figurename = [figurename '_weekly'];
end
if saveResults
    exportfig(daysOfInoculationBoxPlot,[figurename '.eps'],exportOptions)
end

%% optional: signal time course by plate ID plot
if separateSignalPlateID
    set(0,'CurrentFigure',growthCourseLinePlot)
    colorMap = parula(numUniqueBacDates);
    for plateIDCtr = 1:numel(plateIDs)
        colorGroupID = plateIDSignals{plateIDCtr}(1,5);
        set(0,'CurrentFigure',growthCourseLinePlot)
        plot(plateIDSignals{plateIDCtr}(:,4),plateIDSignals{plateIDCtr}(:,3),'Color',colorMap(colorGroupID,:))
    end
    xlabel('days of inoculation')
    ylabel(varName)
    ylim(YAxisLimit)
    legend(plateIDs,'Interpreter','none','Location','Eastoutside')
    % export figure
    figurename = 'results/growthExp/signalLivingImage_byPlateID';
    if saveResults
        exportfig(growthCourseLinePlot,[figurename '.eps'],exportOptions)
    end
end

warning on verbose