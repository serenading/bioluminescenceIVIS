clear
close all

%% script plots bioluminescence signal acquired on the IVIS spectrum, 
% and plots signal over time for selected ROI's.
% Signal is measured either by Living Image 4.3.1 software (plotLivingImageSignal = true; photos/sec/cm^2/sr; local function 2),
% or measured directly from exported tiff's (plotLivingImageSignal = false; arbitrary units; local function 3).

%% set up
% set analysis parameters
baseDir = '/Volumes/behavgenom$/Serena/IVIS/timeSeries/';
date = '20190311'; % string in yyyymmdd format
numROI = 9;
plotLivingImageSignal = true; % true: signal measured with LivingImage software; false: signal measured from tiff's
if plotLivingImageSignal
    varName = 'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';
else
    varName = 'signal (a.u.)';
    matchROI = true;
    exportTiffStack = false;
end
pixeltocm =1920/13.2; % 1920 pixels is 13.2 cm
binFactor = 4;
saveResults = true;

% suppress specific warning messages associated with the text file format
warning off MATLAB:table:ModifiedAndSavedVarnames
warning off MATLAB:handle_graphics:exceptions:SceneNode

% set figure export options
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',30,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',25,...
    'LineWidth',3);

% extract info from metadata 
[directory,bacDays,wormGeno,frameRate,numFrames] = getMetadata(baseDir,date,numROI);

% initialise
addpath('../AggScreening/auxiliary/')
colorMap = parula(numROI);
signalFig = figure; hold on

%% get signal
if plotLivingImageSignal
    signal = getLivingImageSignal(directory,numROI,varName);
else
    [signal,lumTiffStack] = getIvisSignal(directory,numROI,numFrames,binFactor,matchROI);
end

%% plot and format
legends = cell(1,numROI);
for ROICtr = 1:numROI
    set(0,'CurrentFigure',signalFig)
    plot(signal(ROICtr,:),'Color',colorMap(ROICtr,:))
    legends{ROICtr} = ['R' num2str(ROICtr) ', D' num2str(bacDays(ROICtr)) ', ' wormGeno{ROICtr}];
end
legend(legends)
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*60/frameRate) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
ylabel(varName)
if plotLivingImageSignal
    ylim([0 2.5e8])
    if strcmp(date,'20190311')
        ylim([1e7 4e7])
    end
else
    ylim([0 2.5e7])
end

%% export figure
figurename = ['results/timeSeries/' date '_signal'];
if plotLivingImageSignal
    figurename = [figurename 'LivingImage'];
end
if saveResults
    exportfig(signalFig,[figurename '.eps'],exportOptions)
end

%% export tiff stack if it doesn't exist
if ~plotLivingImageSignal && exportTiffStack
    tiffStackname = strsplit(figurename,filesep);
    tiffStackname = [directory tiffStackname{2} '.tiff'];
    if ~exist(tiffStackname,'file')
        for frameCtr = 1:numFrames
            imwrite(lumTiffStack(:,:,frameCtr),tiffStackname, 'WriteMode','append','Compression','none'); % 'Compression','lzw' for lossless compression
        end
    end
end
