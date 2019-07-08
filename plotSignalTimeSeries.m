clear
close all

%% script plots bioluminescence signal acquired on the IVIS spectrum, 
% and plots signal over time for selected ROI's.
% Signal is measured either by Living Image 4.3.1 software (plotLivingImageSignal = true; photos/sec/cm^2/sr; local function 2),
% or measured directly from exported tiff's (plotLivingImageSignal = false; arbitrary units; local function 3).

%% set up
saveResults = false;
% set analysis parameters
baseDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/timeSeries/';
date = '20190704'; % string in yyyymmdd format
numROI = 9;
plotLivingImageSignal = true; % true: signal measured with LivingImage software; false: signal measured from tiff's
if plotLivingImageSignal
    varName = 'TotalFlux_p_s_'; %'AvgRadiance_p_s_cm__sr_'; % or 'TotalFlux_p_s_';
else
    varName = 'signal (a.u.)';
    matchROI = true;
    exportTiffStack = false;
    makeVid = true;
end
normaliseSignal = false;
poolReps = false;
if poolReps
   ROIInd = {[1:3],[4:6]}; % ROI numbers for replicates to be pooled
   pooledLegends = {'npr-1','N2'}; % label for what samples are pooled
   assert(numel(ROIInd) == numel(pooledLegends),'incorrect pooling labels specified for samples to be pooled') 
   pooledColors = {'b','r','k','g'};
end

pixeltocm =1920/13.2; % 1920 pixels is 13.2 cm
binFactor = 4;



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

if normaliseSignal
    %% normalise all signal as a fraction of starting signal
    initialSignal = signal(:,1);
    signal = signal./initialSignal;
    % % normalise signal against changes in control signal
    % controlSignal = signal(7:9,:);
    % controlSignalChange = mean(controlSignal-1,1);
    % signal = signal-controlSignalChange;
end

%% plot and format
legends = cell(1,numROI);
for ROICtr = 1:numROI
    set(0,'CurrentFigure',signalFig)
    if numROI ==1
        plot(signal(ROICtr,:),'Color','b')
    else
        plot(signal(ROICtr,:),'Color',colorMap(ROICtr,:))
    end
    legends{ROICtr} = ['R' num2str(ROICtr) ', D' num2str(bacDays(ROICtr)) ', ' wormGeno{ROICtr}];
end
legend(legends,'Location','Eastoutside')
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*60/frameRate) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylabel('normalisedSignal')
else
    ylabel(varName)
end
title(date)

% if plotLivingImageSignal
%     ylim([0 2.5e8])
%     if strcmp(date,'20190311')
%         ylim([1e7 4e7])
%     end
% else
%     ylim([0 2.5e7])
% end

% shadedErrorBar for pooling replicates
if poolReps
    pooledFig = figure; hold on
    set(0,'CurrentFigure',pooledFig)
    mainLineHandles = [];
    for sampleCtr = 1:numel(ROIInd)
        H(sampleCtr) = shadedErrorBar([],signal(ROIInd{sampleCtr},:),{@median,@std},pooledColors{sampleCtr},1);
        mainLineHandles = [mainLineHandles H(sampleCtr).mainLine];
    end
    xTick = get(gca, 'XTick');
    set(gca,'XTick',xTick','XTickLabel',xTick*60/frameRate) % rescale x-axis for according to acquisition frame rate
    xlabel('minutes')
    if normaliseSignal
        ylabel('normalisedSignal')
    else
        ylabel(varName)
    end
    ylim([0,1.2])
    title(date)
    legend(mainLineHandles,pooledLegends,'Location','Eastoutside')
end
    

%% export figure
if normaliseSignal
    figurename = ['results/timeSeries/' date '_signalNormalised'];
else
    figurename = ['results/timeSeries/' date '_signal'];
end
if plotLivingImageSignal
    figurename = [figurename 'LivingImage'];
end
if saveResults
    exportfig(signalFig,[figurename '.eps'],exportOptions)
    if poolReps
        figurename = [figurename '_pooled'];
        exportfig(pooledFig,[figurename '.eps'],exportOptions)
    end
end

%% export tiff stack if it doesn't exist
if ~plotLivingImageSignal
    tiffStackname = strsplit(figurename,filesep);
    if exportTiffStack
        tiffStackname = [directory tiffStackname{2} '.tiff'];
        if ~exist(tiffStackname,'file')
            for frameCtr = 1:numFrames
                imwrite(lumTiffStack(:,:,frameCtr),tiffStackname, 'WriteMode','append','Compression','none'); % 'Compression','lzw' for lossless compression
            end
        end
    elseif makeVid
        videoName = [directory tiffStackname{3}];
        if ~exist(videoName,'file')
            video = VideoWriter([videoName '.avi']);
            video.FrameRate = 60/frameRate*3; % frameRate in min/frame. video.FrameRate = 60/frameRate*3: 1s = 3hr (10800x speed up).
            open(video)
            for frameCtr = 1:numFrames
                % rescale current frame
                currentFrame = im2double(lumTiffStack(:,:,frameCtr))/double(max(max(max(lumTiffStack))))*65535;
                % append current frame
                writeVideo(video,currentFrame)
            end
            close(video)
        end
    end
end


%% local function for extracting metadata

function [directory,bacDays,wormGeno,frameRate,numFrames] = getMetadata(baseDir,date,numROI)

% read metadata
metadata = readtable([baseDir 'metadata_IVIS_timeSeries.xls']);
% find row index for the experiment
expRowIdx = find(strcmp(string(metadata.date),date));
% get directory name
subDirName = string(metadata.subDirName(expRowIdx));
directory = char(strcat(fullfile(baseDir,subDirName),filesep));
% get row indices to extract bacteria information
startBacDatesColIdx = find(strcmp(metadata.Properties.VariableNames,'sample_bac_date_1'));
endBacDatesColIdx = find(strcmp(metadata.Properties.VariableNames,['sample_bac_date_',num2str(numROI)]));
bacDates = string(table2array(metadata(expRowIdx,startBacDatesColIdx:endBacDatesColIdx)));
bacDays = datenum(date,'yyyymmdd')- datenum(bacDates,'yyyymmdd');
% get row indices to extract worm information
startWormGenoColIdx = find(strcmp(metadata.Properties.VariableNames,'sample_worm_geno_1'));
endWormGenoColIdx = find(strcmp(metadata.Properties.VariableNames,['sample_worm_geno_',num2str(numROI)]));
wormGeno = table2array(metadata(expRowIdx,startWormGenoColIdx:endWormGenoColIdx));
% get additional information
frameRate = 60/metadata.frameInterval_min(expRowIdx); % frames per hour
numFrames = metadata.numFrames(expRowIdx);

end