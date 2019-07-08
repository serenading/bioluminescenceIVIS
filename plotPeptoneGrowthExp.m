clear
close all

%% script plots bioluminescence signal acquired on the IVIS spectrum, 
% of bacteria that have been inoculated lengths of days (i.e. number of days).
% Signal is measured by Living Image 4.3.1 software.

%% set up
% set analysis parameters
baseDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/peptoneGrowth/';
numROI = 3;
varName = 'TotalFlux_p_s_';%'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';
% plotting and export options
colorMap = parula(numROI);
% if strcmp(varName,'TotalFlux_p_s_')
%     YAxisLimit = [];
% elseif strcmp(varName,'AvgRadiance_p_s_cm__sr_')
%     YAxisLimit = [0 14e7];
% end
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
growthCourseLinePlot = figure; hold on

% suppress specific warning messages associated with the text file format
warning off MATLAB:table:ModifiedAndSavedVarnames
warning off MATLAB:handle_graphics:exceptions:SceneNode

%% get signal
% get overall signal matrix
signal = getLivingImageSignal_peptoneGrowthExp(baseDir,numROI,varName);
[plateIDs, plateIDSignals] = separateSignalByPlateID_peptoneGrowthExp(signal);
    
%% plot 
set(0,'CurrentFigure',growthCourseLinePlot)
for plateIDCtr = 1:numel(plateIDs)
    signals = plateIDSignals{plateIDCtr}{:,1};
    days = plateIDSignals{plateIDCtr}{:,2};
    signals = reshape(signals,[3,numel(signals)/3]);
    days = reshape(days,[3,numel(days)/3]);
    set(0,'CurrentFigure',growthCourseLinePlot)
    %boxplot(plateIDSignals{plateIDCtr}{:,2},plateIDSignals{plateIDCtr}{:,1},'Colors',unique(plateIDSignals{plateIDCtr}{:,3})
    %plot(mean(days,1),mean(signals,1),unique(plateIDSignals{plateIDCtr}{:,4}),'Color',unique(plateIDSignals{plateIDCtr}{:,3}))
    errorbar(mean(days,1),mean(signals,1),std(signals,1),unique(plateIDSignals{plateIDCtr}{:,4}),'Color',unique(plateIDSignals{plateIDCtr}{:,3}));
end
xlabel('days of inoculation')
ylabel(varName)
%ylim(YAxisLimit)
legend(plateIDs,'Interpreter','none','Location','Eastoutside')
% export figure
figurename = 'results/peptoneGrowthExp/signalLivingImage_byPlateID';
if saveResults
    exportfig(growthCourseLinePlot,[figurename '.eps'],exportOptions)
end