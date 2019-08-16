%% generate tiff stacks and make video
matchROI = true;
lumTiffStack = [];
metadata = readtable([baseDir 'metadata_IVIS_realExp.xls']);
for dirCtr = 1:numel(directories) % loop through each subDir
    directory = directories{dirCtr};
    % find numFrames and binFactor from metadata
    expInd = find(metadata.expN == expN);
    expIdx = expInd(numROI*(dirCtr-1)+1);
    numFrames = metadata.numFrames(expIdx);
    binFactor = metadata.LumBinning(expIdx);
    % generate luminescence tiffs
    [~,lumTiffs] = getIvisSignal(directory,numROI,numFrames,binFactor,matchROI);
    lumTiffStack = cat(3,lumTiffStack,lumTiffs);
end