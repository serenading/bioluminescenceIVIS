function [plateIDs, plateIDSignals,numUniqueBacDates] = separateSignalByPlateID(signal)

%% INPUT:
% signal: Nx4 signal matrix as calculated using getLivinImageSignal_growthExp.m

%% OUTPUTS:
% plateID: a string array containing unique plateID's in the format of bacDate_repID (i.e. 20190219_1).
% plateIDSignal: a cell array the length of plateID, each containing an Nx4 matrix in the format of the input signal matrix for that particular plateID.

%% FUNCTION 

% load data
bacDates = signal(:,1);
repIDs = signal(:,2);
signals = signal(:,3);
bacAges = signal(:,4);

%% find number of unique plateID's
% initialise
numPlateIDs = numel(unique(bacDates.*repIDs));
plateIDs = strings(1,numPlateIDs);
plateIDSignals = cell(1,numPlateIDs);
groupingIDs = NaN(1,numPlateIDs);
plateIDCtr = 1;
groupingID = 1;

%% generate a list of plateID's and their associated signal/time values
% go through each unique inoculate date
uniqueBacDates = unique(bacDates);
numUniqueBacDates = numel(uniqueBacDates);
for bacDateCtr = 1:numUniqueBacDates
    bacDate = uniqueBacDates(bacDateCtr);
    % find row indices that match the inoculation date
    bacDateInd = find(bacDates == bacDate);
    % get replicate ID's
    bacRepIDs = repIDs(bacDateInd);
    uniqueBacRepIDs = unique(bacRepIDs);
    % go through each replicate ID
    for repIDCtr = 1:numel(uniqueBacRepIDs)
        repID = uniqueBacRepIDs(repIDCtr);
        % save plate ID
        plateIDs(plateIDCtr) = [num2str(bacDate) '_' num2str(repID)];
        % find row indices for that plate ID
        plateIDInd = find(bacDates == bacDate & repIDs == repID);
        % write values for this plateID
        numTimePoints = numel(plateIDInd);
        plateIDSignals{plateIDCtr} = NaN(numTimePoints,5);
        plateIDSignals{plateIDCtr}(:,1) = ones(numTimePoints,1)*bacDate;
        plateIDSignals{plateIDCtr}(:,2) = ones(numTimePoints,1)*repID;
        plateIDSignals{plateIDCtr}(:,3) = signals(plateIDInd);
        plateIDSignals{plateIDCtr}(:,4) = bacAges(plateIDInd);
        plateIDSignals{plateIDCtr}(:,5) = ones(numTimePoints,1)*groupingID;
        % update plateID counter
        plateIDCtr = plateIDCtr+1;
    end
    % update groupingID
    groupingID = groupingID+1;
end
end