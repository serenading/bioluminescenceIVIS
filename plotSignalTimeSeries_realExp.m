clear
close all

%% script plots bioluminescence signal acquired on the IVIS spectrum and plots signal over time.
% Signal is measured by Living Image 4.3.1 software (photons/sec/cm^2/sr;),

%% set up
saveResults = false;
baseDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/';
% set analysis parameters
expNs = [15]; % vector of time series experiment number, i,e. 2 or [1:3].
yVarName = 'TotalFlux_p_s_'; %'AvgRadiance_p_s_cm__sr_' or 'TotalFlux_p_s_'. These are matlab friendly named using readtable function.
groupVars = {'bacDays','bacType','bacInoc','wormGeno','plateDrug'};%,',,'peptoneLevel'};%,'wormNum'}; %'wormNum'
normaliseSignal = true;
dYdTSmoothWindow = 10;
pooledColors = {'b','r','m','k'};
plotControl = true;

% suppress specific warning messages associated with the text file format
warning off MATLAB:table:ModifiedAndSavedVarnames
warning off MATLAB:handle_graphics:exceptions:SceneNode

% set figure export options
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',20,...
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
    [directories,expID,numROI,frameInterval,bacWormInfo,groupIDs,metadata] = getMetadata_RealExp(baseDir,expN,groupVars);
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
        groupIDCat = groupIDs;
        numROICat = numROI;
        expIDCat = ['expN' num2str(expN)];
    else
        signalCat = vertcat(signalCat, signal);
        bacWormInfoCat = vertcat(bacWormInfoCat, bacWormInfo);
        groupIDCat = vertcat(groupIDCat, groupIDs);
        numROICat = numROICat+numROI;
        expIDCat = [expIDCat 'expN' num2str(expN)];
    end
    
    % rename concatenated variables for simplicity
    signal = signalCat;
    bacWormInfo = bacWormInfoCat;
    groupIDs = groupIDCat;
    numROI = numROICat;
    if numel(expNs)>1
        expID = expIDCat;
    end
end

%% process signal

% normalise all signal as a fraction of starting signal
if normaliseSignal
    signal = normaliseSignalToStart(signal);
    if expN < 22 | expN >24 % expN 22-24 do not have control groups: zoomed in ROI A therefore no control
        signal = normaliseSignalToControl(signal,groupIDs,expN); % controls have groupID=0 or corresponding negative values
    end
end

if expN == 15
    signal = signal(:,1:2:end);
end
% calculate signal derivative
dYdT = takeSignalDerivative(signal,frameInterval,dYdTSmoothWindow);

% calculating time to half max signal

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
legend(legends,'Location','northeast','Interpreter','none')
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*frameInterval) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylabel('normalisedSignal')
else
    ylabel(yVarName)
end
title(expID,'Interpreter','none')

% Fig 2: shadedErrorBar for pooling replicates
set(0,'CurrentFigure',pooledSignalFig)
mainLineHandles = [];
% get indices for the desired groupID
uniqueGroupIDs = unique(abs(groupIDs),'stable');
for groupCtr = 1:numel(uniqueGroupIDs)
    groupInd = groupIDs == uniqueGroupIDs(groupCtr);
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
set(gca,'XTick',xTick','XTickLabel',xTick*frameInterval) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylabel('normalisedSignal')
else
    ylabel(yVarName)
end
title(expID,'Interpreter','none')
pooledLegends = unique(varLegends,'stable');
assert(numel(pooledLegends) == numel(unique(abs(groupIDs))),...
    ['Total ' num2str(numel(unique(groupIDs))) ' groupIDs but total ' num2str(numel(pooledLegends)) ' pooled legend labels']);
if ~plotControl
    if normaliseSignal % remove handle and legends for the control group if using controls to normalise signal
        groupIDLogInd = uniqueGroupIDs>0;
        groupIDInd = uniqueGroupIDs(groupIDLogInd);
        mainLineHandles = mainLineHandles(groupIDLogInd);
        pooledLegends = pooledLegends(groupIDInd);
    end
end
legend(mainLineHandles,pooledLegends,'Location','northeast','Interpreter','none')

% Fig 3: plot signal derivative 
for ROICtr = 1:numROI
    set(0,'CurrentFigure',diffFig)
    plot(1:length(dYdT(ROICtr,:)),dYdT(ROICtr,:),'Color',colorMap(ROICtr,:))
end
legend(legends,'Location','northeast','Interpreter','none')
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*frameInterval) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
ylabel(['change in ' yVarName 'smoothed over ' num2str(frameInterval*dYdTSmoothWindow) 'minutes'],'Interpreter','none')
title(expID,'Interpreter','none')

% Fig 4: shadedErrorBar for pooling derivative replicates
set(0,'CurrentFigure',pooledDiffFig)
mainLineHandles = [];
% get indices for the desired groupID
uniqueGroupIDs = unique(abs(groupIDs),'stable');
for groupCtr = 1:numel(uniqueGroupIDs)
    groupInd = groupIDs == uniqueGroupIDs(groupCtr);
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
set(gca,'XTick',xTick','XTickLabel',xTick*frameInterval) % rescale x-axis for according to acquisition frame rate
xlabel('minutes')
if normaliseSignal
    ylabel('d/dt normalised signal (minute^{-1})')
else
    ylabel(['change in ' yVarName 'smoothed over ' num2str(frameInterval*dYdTSmoothWindow) 'minutes'],'Interpreter','none')
end
title(expID,'Interpreter','none')
pooledLegends = unique(varLegends,'stable');
assert(numel(pooledLegends) == numel(unique(abs(groupIDs))),...
    ['Total ' num2str(numel(unique(groupIDs))) ' groupIDs but total ' num2str(numel(pooledLegends)) ' pooled legend labels']);
if ~plotControl
    if normaliseSignal % remove handle and legends for the control group if using controls to normalise signal
        groupIDLogInd = uniqueGroupIDs>0;
        groupIDInd = uniqueGroupIDs(groupIDLogInd);
        mainLineHandles = mainLineHandles(groupIDLogInd);
        pooledLegends = pooledLegends(groupIDInd);
    end
end
legend(mainLineHandles,pooledLegends,'Location','northeast','Interpreter','none')

%% display median feeding rates over the first 4 hours (this is just before N2 typically runs out of food)

if expN > 3 & expN < 9 | expN >9 & expN <13 % for genotype experiments (4-8) and for drug experiments (10-12)
    for groupCtr = 1:numel(pooledLegends)
        % display feeding rate calculated from derivatives from the first 4
        % hours of experiments
        display([pooledLegends{groupCtr} ' feeding rate is ' num2str(median(mainLineHandles(groupCtr).YData(1:4*60/frameInterval)))])
    end
end

%% export figures
figurename = ['results/realExp/' expID];
if normaliseSignal
    figurename = [figurename '_normalised'];
end
pooledSignalfigurename = [figurename '_pooled'];
difffigurename = [figurename '_derivative'];
pooledDifffigurename = [figurename '_derivative_pooled'];
if saveResults
    exportfig(signalFig,[figurename '.eps'],exportOptions)
    exportfig(pooledSignalFig,[pooledSignalfigurename '.eps'],exportOptions)
    exportfig(diffFig,[difffigurename '.eps'],exportOptions)
    exportfig(pooledDiffFig,[pooledDifffigurename '.eps'],exportOptions)
end


%% local functions 

%% function to extract metadata
function [directories,expID,numROI,frameInterval,bacWormInfo,groupIDs,metadata] = getMetadata_RealExp(baseDir,expN,groupVars)

% read metadata
metadata = readtable([baseDir 'metadata_IVIS_realExp.xls']);
% find logical indices for the experiment
expLogInd = metadata.expN == expN;
% find number of ROI
numROI = numel(unique(metadata.ROI(expLogInd)));
% get directory names. There should only be 1 or 2 directory names,
% depending on whether over 99 frames are acquired for the experiment on
% the IVIS via the batch sequence option
date = unique(metadata.date_yyyymmdd(expLogInd)); % this date is the experiment date
subDirName = unique(metadata.subDirName(expLogInd));
assert(numel(date) == 1, 'More than one experiment dates found for this experiment number');
if expN == 25
    baseDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/TimeSeries/';
end
for subDirCtr = numel(subDirName):-1:1
    directories{subDirCtr} = char(strcat(fullfile(baseDir,num2str(date),char(subDirName{subDirCtr}),filesep)));
end
assert(numel(directories)==1|numel(directories)==2,'There should only be 1 or 2 subDirName for this experiment number')
% generate expID (date+subDirName) as a unique identifier for saving outputs; 
% always use the first subDirName if more than one exists
dirSplit = strsplit(directories{1},'/');
expID = [dirSplit{end-2} '_' dirSplit{end-1}];
% get frame rate
frameInterval = unique(metadata.frameInterval_min(expLogInd)); % frames per minute
assert(numel(frameInterval)==1, 'There should be only one frame interval found for this experiment number. Check metadata.');
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
            date = datenum(char(metadata.date_yyyymmdd(expLogInd & metadata.ROI == ROICtr)),'yyyymmdd');
            bacDate = datenum(char(metadata.bacDate(expLogInd & metadata.ROI == ROICtr)),'yyyymmdd');
            bacWormInfo{ROICtr,varCtr} = [num2str(date-bacDate)...
                'dayOldBac'];
        elseif strcmp(groupVar,'wormNum')
            bacWormInfo{ROICtr,varCtr} = [num2str(metadata.(groupVar)(expLogInd & metadata.ROI == ROICtr)) 'worms'];
        elseif strcmp(groupVar,'bacVol_uL')
            bacWormInfo{ROICtr,varCtr} = [num2str(metadata.(groupVar)(expLogInd & metadata.ROI == ROICtr))];
        else
            bacWormInfo{ROICtr,varCtr} = char(metadata.(groupVar)(expLogInd & metadata.ROI == ROICtr));
        end
    end
end
% extract groupID, which are manually assigned to ROI's for grouping replicates together
groupIDs = metadata.groupID(expLogInd);
end

%% function to normalise signal against the control (no worm) value
function signal = normaliseSignalToControl(signal,groupIDs,expN)

% there are two ways of assigning control groupIDs. 1) Assign 0 to the control group if
% all ROI's are to be normalised to a single control signal. 2) Multiple controls exist
% and different ROI's are to be normalised against different controls (i.e. drug experiment).
% In this case assign -1 to group 1 and -2 to group 2, where group 1 ROI's are to be normalised
% against -1, group 2 ROI's against -2, and so on. No 0 should be contained
% in the second case.

signalCopy = signal;
uniqueGroupIDs = unique(abs(groupIDs),'stable');
% go through each subgroup 
for groupCtr = 1:numel(uniqueGroupIDs)
    % identify sub groupID
    groupID = uniqueGroupIDs(groupCtr);
    % identify the corresponding control group ID
    if nnz(groupIDs==0)>0 % first case, a control group of 0 exists and no negative value control groups are present
        assert(nnz(groupIDs<0)==0, 'Control groups should only contain 0 or negative values. Both are found. Error.')
        controlGroupID = 0;
    else % second case, no control group of 0 but there are negative value control groups for their corresponding groups
        assert(nnz(groupIDs<0)>0, 'Control groups should only contain 0 or negative values. Neither is found. Error.')
        controlGroupID = -groupID;
    end
    % get logical index for this subgroup
    groupSignalInd = abs(groupIDs)==groupID;
    % get logical index for control group
    controlInd = groupIDs==controlGroupID;
    % average control signals if multiple replicates exist
    controlSignal = mean(signal(controlInd,:),1);
    % replace signal for this subgroup with normalised version of it
    signalCopy(groupSignalInd,:) = signal(groupSignalInd,:)./controlSignal;
end
% rename concatenated signal
assert(size(signalCopy,1) == numel(groupIDs),'not all signal rows are retained after normalising against respective controls');
signal = signalCopy;
end

%% function to normalise signal to the starting value
function signal = normaliseSignalToStart(signal)

initialSignal = signal(:,1); % get starting signal (which isn't always the highest signal, unfortunately)
signal = signal./initialSignal; % normalise signal against the starting value
end

%% function to calculate signal derivative
function dYdT = takeSignalDerivative(signal,frameInterval,derivativeSmoothWindow)

% get change in signal
signalShiftWindow = zeros(size(signal,1),derivativeSmoothWindow); % generate zero pad
signalStart = [signalShiftWindow signal]; % zero pad
signalEnd = [signal signalShiftWindow]; % zero pad
signalDiff = signalEnd - signalStart; % take signal difference
signalDiff = signalDiff(:,[derivativeSmoothWindow+1:end-derivativeSmoothWindow]); % remove the padded signal
% 
frameRate = 1/frameInterval;
dT = derivativeSmoothWindow/frameRate; % time step in minutes
dYdT = signalDiff/dT; % dYdT to be plotted, in the unit of min^-1
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