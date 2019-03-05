clear
close all

%% script plots bioluminescence signal acquired on the IVIS spectrum,
% and plots signal over time for selected ROI's.
% Signal is measured either by Living Image 4.3.1 software (plotLivingImageSignal = true; photos/sec/cm^2/sr; local function 2),
% or measured directly from exported tiff's (plotLivingImageSignal = false; arbitrary units; local function 3).

%% set up
% set analysis parameters
baseDir = '/Volumes/behavgenom$/Serena/IVIS/growthExp/';
numROI = 9;
plotLivingImageSignal = true; % true: signal measured with LivingImage software; false: signal measured from tiff's
if plotLivingImageSignal
    varName = 'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';
else
    varName = 'signal (a.u.)';
    matchROI = false;
end
pixeltocm =1920/13.2; % 1920 pixels is 13.2 cm
binFactor = 4;
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
colorMap = parula(numROI);
daysOfInoculationBoxPlot = figure;
growthCourseLinePlot = figure; hold on

%% get signal
if plotLivingImageSignal
    signal = getLivingImageSignal_growthExp(baseDir,numROI,varName);
% else
%     [signal,lumTiffStack] = getIvisSignal(directory,numROI,numReps,binFactor,matchROI);
end

%% plot and format
%
set(0,'CurrentFigure',daysOfInoculationBoxPlot)
boxplot(signal(:,3),signal(:,4))
xlabel('days of inoculation')
ylabel(varName)
ylim([0 8e7])
%
set(0,'CurrentFigure',growthCourseLinePlot)
% write new function to extract signal over days for unique date_ID combo

%% export figure
figurename = ['results/growthExp/' date '_signal_n' num2str(numReps)];
if plotLivingImageSignal
    figurename = [figurename 'LivingImage'];
end
if saveResults
    exportfig(daysOfInoculationBoxPlot,[figurename '.eps'],exportOptions)
end