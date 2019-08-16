function [plateIDs, plateIDSignals] = separateSignalByPlateID_peptoneGrowthExp(signal)

%% INPUT:
% signal: Nx4 signal matrix as calculated using getLivinImageSignal_growthExp.m

%% OUTPUTS:
% plateID: a string array containing unique plateID's in the format of bacDate_repID (i.e. 20190219_1).
% plateIDSignal: a cell array the length of plateID, each containing an Nx4 matrix in the format of the input signal matrix for that particular plateID.

%% FUNCTION

% load data
repIDs = signal(:,2);
signals = signal(:,3);
bacAges = signal(:,4);
peptones = signal(:,5);
ROIs = signal(:,6);

% find uniques
uniqueRepIDs = unique(repIDs);
uniqueROIs = unique(ROIs);
uniquePeps = unique(peptones);

% generate labels
repIDLabels = {'1','2','3'};
ROILabels = {'L','M','S'};
pepLabels = {'RP','LP','NP'};
plotType = {':','-.','-'}; % for plate size
plotColor = {'b','r','k'}; % for peptone level

%% find number of unique plateID's
% initialise
numPlateIDs = 9;
plateIDs = strings(1,numPlateIDs);
plateIDSignals = cell(1,numPlateIDs);
plateIDCtr = 1;

%
for pepCtr = 1:numel(uniquePeps)
    peptone = uniquePeps(pepCtr);
    for ROICtr = 1:numel(uniqueROIs)
        ROI = uniqueROIs(ROICtr);
        %         for repCtr = 1:numel(uniqueRepIDs)
        %             repID = uniqueRepIDs(repCtr);
        % find rowInd
        rowInd = find(ROIs == ROI & peptones == peptone);% & repIDs == repID);
        % write values
        plateIDs{plateIDCtr} = [pepLabels{pepCtr} '_' ROILabels{ROICtr}];% '_' num2str(repID)];
        plateIDSignals{plateIDCtr}{:,1} = signals(rowInd);
        plateIDSignals{plateIDCtr}{:,2} = bacAges(rowInd);
        plateIDSignals{plateIDCtr}{:,3} = plotColor{peptone};
        plateIDSignals{plateIDCtr}{:,4} = plotType{ROI};
        % update plateIDCtr
        plateIDCtr = plateIDCtr + 1;
        %end
    end
end