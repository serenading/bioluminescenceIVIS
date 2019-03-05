function signal = getLivingImageSignal(directory,numROI,varName)

[ROIMeasurementList, ~] = dirSearch([directory 'measurements/'],'.txt');
assert(length(ROIMeasurementList) == numROI,'numROI incorrectly specified');
% go through each ROI measurement .txt file
for ROICtr = numROI:-1:1
    filename = ROIMeasurementList{ROICtr};
    signalTable = readtable(filename,'ReadVariableNames',1,'delimiter','\t');
    if isa(signalTable.(varName),'double')
        signal(ROICtr,:) = signalTable.(varName);
    else
        warning('N/A values exist for some measurements')
    end
end

end