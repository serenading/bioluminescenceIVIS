clear
close all

%% script plots bioluminescence signal acquired on the IVIS spectrum and plots signal over time.
% Signal is measured by Living Image 4.3.1 software (photons/sec/cm^2/sr;),

%% set up
saveResults = false;
baseDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/';
% set analysis parameters
expNs = [4,5]; % vector of time series experiment number, i,e. 2 or [1:3].
yVarName = 'TotalFlux_p_s_'; %'AvgRadiance_p_s_cm__sr_' or 'TotalFlux_p_s_'. These are matlab friendly named using readtable function.
groupVars = {'bacDays','bacType','bacInoc','wormGeno'}; %'wormNum'
normaliseSignal = true;
dYdTSmoothWindow = 10;

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

% initialise
addpath('../AggScreening/auxiliary/')

signalFig = figure; hold on
pooledSignalFig = figure; hold on
diffFig = figure; hold on
pooledDiffFig = figure; hold on

%% go through each expN

for expCtr = 1:numel(expNs)
    expN = expNs(expCtr);
    
    %% extract info from metadata
    [directories,expID,numROI,frameRate,bacWormInfo,groupID] = getMetadata_RealExp(baseDir,expN,groupVars);
    % bacWormInfo can be a table instead, with groupVars as the heading
    
    %% get signal (horizontally concatenates the two-part series if a second part exists)
    signal = [];
    for dirCtr = 1:numel(directories)
        directory = directories{dirCtr};
        signal = [signal, getLivingImageSignal(directory,numROI,yVarName)];
    end
    assert(size(signal,1) == numROI,'signal should be a [numROI x numFrames] matrix')
    
    % vertically concatenate signal and other information across different expN 
    if  expCtr == 1
        signalCat = signal;
        bacWormInfoCat = bacWormInfo;
        groupIDCat = groupID;
        numROICat = numROI;
        expIDCat = ['expN' num2str(expN)];
    else
        signalCat = vertcat(signalCat, signal);
        bacWormInfoCat = vertcat(bacWormInfoCat, bacWormInfo);
        groupIDCat = vertcat(groupIDCat, groupID);
        numROICat = numROICat+numROI;
        expIDCat = [expIDCat 'expN' num2str(expN)];
    end
    
    % rename concatenated variables for simplicity
    signal = signalCat;
    bacWormInfo = bacWormInfoCat;
    groupID = groupIDCat;
    numROI = numROICat;
    if numel(expNs)>1
        expID = expIDCat;
    end
end

%% process signal

% normalise all signal as a fraction of starting signal
if normaliseSignal
    signal = normaliseSignalToStart(signal);
    signal = normaliseSignalToControl(signal,groupID); % controls have groupID=0
end

% calculate signal derivative
% signalSmooth = smoothdata(signal,1,'gaussian',20);
dYdT = takeSignalDerivative(signal,frameRate,dYdTSmoothWindow);
% calculating time to half max 

%% plot and format

% get varLegends, a legend array containing metadata info that's unique to some replicates. 
% This legend array subsequently gets used to generate legends for appropriate plots
varLegends = generateVarLegends(bacWormInfo,numROI,groupVars);

% Fig 1: plain signal plot
colorMap = parula(numROI);
legends = cell(1,numROI);
for ROICtr = 1:numROI
    set(0,'CurrentFigure',signalFig)
    plot(signal(ROICtr,:),'Color',colorMap(ROICtr,:))
    legends{ROICtr} = ['R' num2str(ROICtr) '_' varLegends{ROICtr}];
end
legend(legends,'Location','Eastoutside','Interpreter','none')
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*frameRate) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylabel('normalisedSignal')
else
    ylabel(yVarName)
end
title(expID,'Interpreter','none')

% Fig 2: shadedErrorBar for pooling replicates
pooledColors = {'b','r','k','g','c'};
set(0,'CurrentFigure',pooledSignalFig)
mainLineHandles = [];
% get indices for the desired groupID
uniqueGroupIDs = unique(groupID,'stable');
for groupCtr = 1:numel(uniqueGroupIDs)
    groupInd = groupID == uniqueGroupIDs(groupCtr);
    % only use shadedErrorBar if there are more than 1 replicate
    if nnz(groupInd)>1
        % plot shaded error bar
        H(groupCtr) = shadedErrorBar([],signal(groupInd,:),{@median,@std},pooledColors{groupCtr},1);
        mainLineHandles = [mainLineHandles H(groupCtr).mainLine];
    % otherwise use simple plot
    else
        H2 = plot(signal(groupInd,:),'Color',pooledColors{groupCtr});
        mainLineHandles = [mainLineHandles H2];
    end
end
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*frameRate) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylabel('normalisedSignal')
else
    ylabel(yVarName)
end
title(expID,'Interpreter','none')
pooledLegends = unique(varLegends,'stable');
assert(numel(pooledLegends) == numel(unique(groupID)),...
    ['Total ' num2str(numel(unique(groupID))) ' groupIDs but total ' num2str(numel(pooledLegends)) ' pooled legend labels']);
% if normaliseSignal % remove handle and legends for the control group if using controls to normalise signal
%     groupIDLogInd = uniqueGroupIDs~=0;
%     mainLineHandles = mainLineHandles(groupIDLogInd);
%     pooledLegends = pooledLegends(groupIDLogInd);
% end
legend(mainLineHandles,pooledLegends,'Location','Eastoutside','Interpreter','none')

% Fig 3: plot signal derivative 
for ROICtr = 1:numROI
    set(0,'CurrentFigure',diffFig)
    plot(1:length(dYdT(ROICtr,:)),dYdT(ROICtr,:),'Color',colorMap(ROICtr,:))
end
legend(legends,'Location','Eastoutside','Interpreter','none')
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*frameRate) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
ylabel(['change in ' yVarName 'per ' num2str(frameRate*dYdTSmoothWindow) 'minutes'],'Interpreter','none')
title(expID,'Interpreter','none')

% Fig 4: shadedErrorBar for pooling derivative replicates

set(0,'CurrentFigure',pooledDiffFig)
mainLineHandles = [];
% get indices for the desired groupID
uniqueGroupIDs = unique(groupID,'stable');
for groupCtr = 1:numel(uniqueGroupIDs)
    groupInd = groupID == uniqueGroupIDs(groupCtr);
    % only use shadedErrorBar if there are more than 1 replicate
    if nnz(groupInd)>1
        % plot shaded error bar
        H(groupCtr) = shadedErrorBar([],dYdT(groupInd,:),{@median,@std},pooledColors{groupCtr},1);
        mainLineHandles = [mainLineHandles H(groupCtr).mainLine];
    % otherwise use simple plot
    else
        H2 = plot(dYdT(groupInd,:),'Color',pooledColors{groupCtr});
        mainLineHandles = [mainLineHandles H2];
    end
end
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*frameRate) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylim([-0.25,0.1])
    ylabel(['change in normalised signal per ' num2str(frameRate*dYdTSmoothWindow) ' minutes'],'Interpreter','none')
else
    ylabel(['change in ' yVarName 'per ' num2str(frameRate*dYdTSmoothWindow) 'minutes'],'Interpreter','none')
end
title(expID,'Interpreter','none')
pooledLegends = unique(varLegends,'stable');
assert(numel(pooledLegends) == numel(unique(groupID)),...
    ['Total ' num2str(numel(unique(groupID))) ' groupIDs but total ' num2str(numel(pooledLegends)) ' pooled legend labels']);
% if normaliseSignal % remove handle and legends for the control group if using controls to normalise signal
%     groupIDLogInd = uniqueGroupIDs~=0;
%     mainLineHandles = mainLineHandles(groupIDLogInd);
%     pooledLegends = pooledLegends(groupIDLogInd);
% end
legend(mainLineHandles,pooledLegends,'Location','Eastoutside','Interpreter','none')

%% display median feeding rates over the first 4 hours
display(['npr-1 feeding rate is' num2str(median(H(1).mainLine.YData(1:40)))])

%% export figures
figurename = ['results/realExp/' expID];
if normaliseSignal
    figurename = [figurename '_normalised'];
end
pooledfigurename = [figurename '_pooled'];
difffigurename = [figurename '_derivative'];
diffMedianValName = [difffigurename '_medianVal'];
if saveResults
    exportfig(signalFig,[figurename '.eps'],exportOptions)
    exportfig(pooledSignalFig,[pooledfigurename '.eps'],exportOptions)
    exportfig(diffFig,[difffigurename '.eps'],exportOptions)
end


%% local functions 

%% function to extract metadata
function [directories,expID,numROI,frameRate,bacWormInfo,groupID] = getMetadata_RealExp(baseDir,expN,groupVars)

% read metadata
metadata = readtable([baseDir 'metadata_IVIS_realExp.xls']);
% find logical indices for the experiment
expLogInd = metadata.expN == expN;
% find number of ROI
numROI = numel(unique(metadata.ROI(expLogInd)));
% get directory names. There should only be 1 or 2 directory names,
% depending on whether over 99 frames are acquired for the experiment on
% the IVIS via the batch sequence option
date = unique(metadata.date(expLogInd)); % this date is the experiment date
subDirName = unique(metadata.subDirName(expLogInd));
assert(numel(date) == 1, 'More than one experiment dates found for this experiment number');
for subDirCtr = numel(subDirName):-1:1
    directories{subDirCtr} = char(strcat(fullfile(baseDir,num2str(date),char(subDirName{subDirCtr}),filesep)));
end
assert(numel(directories)==1|numel(directories)==2,'There should only be 1 or 2 subDirName for this experiment number')
% generate expID (date+subDirName) as a unique identifier for saving outputs; 
% always use the first subDirName if more than one exists
dirSplit = strsplit(directories{1},'/');
expID = [dirSplit{end-2} '_' dirSplit{end-1}];
% get frame rate
frameRate = unique(metadata.frameInterval_min(expLogInd)); % frames per minute
assert(numel(frameRate)==1, 'There should be only one frame interval found for this experiment number. Check metadata.');
% use the first subDir dataset to extract subsequent info if more than one dataset is available
if numel(directories)>1 
    expLogInd = expLogInd & strcmp(metadata.subDirName, subDirName{1});
end
% generate bacteria and worm info cell according to grouping variables,
bacWormInfo = cell(numROI,numel(groupVars));
for ROICtr = numROI:-1:1
    for varCtr = 1:numel(groupVars)
        groupVar = groupVars{varCtr};
        if strcmp(groupVar,'bacDays')
            date = datenum(char(metadata.date(expLogInd & metadata.ROI == ROICtr)),'yyyymmdd');
            bacDate = datenum(char(metadata.bacDate(expLogInd & metadata.ROI == ROICtr)),'yyyymmdd');
            bacWormInfo{ROICtr,varCtr} = [num2str(date-bacDate)...
                'dayOldBac'];
        elseif strcmp(groupVar,'wormNum')
            bacWormInfo{ROICtr,varCtr} = [num2str(metadata.(groupVar)(expLogInd & metadata.ROI == ROICtr)) 'worms'];
        else
            bacWormInfo{ROICtr,varCtr} = char(metadata.(groupVar)(expLogInd & metadata.ROI == ROICtr));
        end
    end
end
% extract groupID, which are manually assigned to ROI's for grouping replicates together
groupID = metadata.groupID(expLogInd);
end

%% function to normalise signal against the control (no worm) value
function signal = normaliseSignalToControl(signal,groupID)

controlInd = groupID==0; % control plates are assigned groupID of 0
controlSignal = mean(signal(controlInd,:),1); % average control signals if multiple replicates exist
signal = signal./controlSignal; % normalise non-control signals against control signal
end

%% function to normalise signal to the starting value
function signal = normaliseSignalToStart(signal)

initialSignal = signal(:,1); % get starting signal (which isn't always the highest signal, unfortunately)
% signal(:,1) may not work when numROI ==1, in which case specify that case with if
signal = signal./initialSignal; % normalise signal against the starting value
end

%% function to calculate signal derivative
function dYdT = takeSignalDerivative(signal,frameRate,derivativeSmoothWindow)

% get change in signal
% dYSignal = diff(signal,1,2); % take first derivative in the second dimension
signalShiftWindow = zeros(size(signal,1),derivativeSmoothWindow);
signalStart = [signalShiftWindow signal];
signalEnd = [signal signalShiftWindow];
signalDiff = signalEnd - signalStart;
signalDiff = signalDiff(:,[derivativeSmoothWindow+1:end-derivativeSmoothWindow]);
% 
dT = 1/frameRate*derivativeSmoothWindow; % time step in minutes
dYdT = signalDiff/dT; % dYdT to be plotted
end

%% function to determine which variables are different between replicates and write to varLegends.
% this varLegends array gets used to generate subsequent legends for appropriate plots
function varLegends = generateVarLegends(bacWormInfo,numROI,groupVars)

varLegends = cell(1,numROI);
for varCtr = 1:numel(groupVars)
    varGroups = unique(bacWormInfo(:,varCtr));
    % if variable has more than one type of labels, then write the labels into a cell array
    if numel(varGroups)>1
        for ROICtr = 1:numROI
            if isempty(varLegends{ROICtr})
                varLegends(ROICtr) = strcat(varLegends(ROICtr),bacWormInfo(ROICtr,varCtr));
            else
                varLegends(ROICtr) = strcat(varLegends(ROICtr),'_',bacWormInfo(ROICtr,varCtr));
            end
        end
    end
end
end