function signal = filterLivingImageSignal_growthExp(signal,repIDsToKeep,expDatesToDrop,bacDatesToDrop,ROIsToDrop)

% keepRepID: apply repID restriction
if ~isempty(repIDsToKeep)
    repIDs = signal(:,2);
    signalRestricted = [];
    for repIDCtr = 1:numel(repIDsToKeep)
        repIDToKeep = repIDsToKeep(repIDCtr);
        keepRepIDRowInd = find(repIDs == repIDToKeep);
        signalRestricted = vertcat(signalRestricted, signal(keepRepIDRowInd,:));
    end
    signal = signalRestricted;
end

% dropExpDate: drop experiments collected on designated dates
if ~isempty(expDatesToDrop)
    expDates = signal(:,7);
    for dropDateCtr = 1:numel(expDatesToDrop)
        expDateToDrop = expDatesToDrop(dropDateCtr);
        keepDateRowInd = find(expDates ~= expDateToDrop);
        signal = signal(keepDateRowInd,:);
        expDates = expDates(keepDateRowInd,:);
    end
end

% dropBacDate: drop experiments with bacteria inoculated from certain dates
if ~isempty(bacDatesToDrop)
    bacDates = signal(:,1);
    for dropDateCtr = 1:numel(bacDatesToDrop)
        bacDateToDrop = bacDatesToDrop(dropDateCtr);
        keepDateRowInd = find(bacDates ~= bacDateToDrop);
        signal = signal(keepDateRowInd,:);
        bacDates = bacDates(keepDateRowInd,:);
    end
end

% dropROI: drop experiments from specific ROI's
if ~isempty(ROIsToDrop)
    ROIs = signal(:,6);
    for dropROICtr = 1:numel(ROIsToDrop)
        ROIToDrop = ROIsToDrop(dropROICtr);
        keepROIRowInd = find(ROIs ~= ROIToDrop);
        signal = signal(keepROIRowInd,:);
        ROIs = ROIs(keepROIRowInd,:);
    end
end