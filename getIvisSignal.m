function [signal,lumTiffStack] = getIvisSignal(directory,numROI,numFrames,binFactor,matchROI)

[lumFileList, ~] = dirSearch(directory,'luminescent.TIF');
[darkFileList, ~] = dirSearch(directory,'AnalyzedClickInfo.txt');
% [darkFileList, ~] = dirSearch(directory,'readbiasonly.TIF');
assert(length(lumFileList) == length(darkFileList),'luminescence vs. dark charge file numbers do not match');
sampleImage = imread(lumFileList{1});
% load or create ROI masks
if matchROI
    % use ROI coordinates from LivingImage measurement files
    [ROIMeasurementList, ~] = dirSearch([directory 'measurements/'],'.txt');
    assert(length(ROIMeasurementList) == numROI,'numROI incorrectly specified');
    frameDims = size(sampleImage);
    % go through each ROI measurement .txt file
    for ROICtr = numROI:-1:1
        filename = ROIMeasurementList{ROICtr};
        signalTable = readtable(filename,'ReadVariableNames',1,'delimiter','\t');
        % get circular ROI coordinates
        ROIx = signalTable.Xc_pixels_(1)/binFactor;
        ROIy = signalTable.Yc_pixels_(1)/binFactor;
        ROIr = signalTable.Width_pixels_(1)/binFactor;
        % generate ROI mask
        ROImask(:,:,ROICtr) = createCirclesMask([frameDims(1),frameDims(2)],[ROIx ROIy],ROIr);
    end 
else
    % load or free draw ROI's
    if exist(fullfile(directory,'ROImask.mat'),'file')
        load(fullfile(directory,'ROImask.mat'),'ROImask')
    else
        % draw ROI masks from the first image
        sampleFig = figure;imshow(sampleImage,[]);
        for ROICtr = numROI:-1:1
            disp(['draw ROI ' num2str(ROICtr)])
            ROImask(:,:,ROICtr) = roipoly; % roipoly function requires manual selection of ROI from the sample image
            assert(sum(sum(ROImask(:,:,ROICtr)))>0,['ROI ' num2str(ROICtr) ' contains no pixel']) % check that ROI contains pixels
        end
        disp('all ROIs drawn')
        save([directory 'ROImask.mat'],'ROImask')
    end
end

% create luminescence TIFF stack and subtract dark charge background
for frameCtr = numFrames:-1:1
    % read background level from text file
    analyzedClickInfo = readtable(darkFileList{frameCtr},'delimiter','\t');
    biasInd = find(arrayfun(@(x) strcmp(x,'Read Bias Level:'), analyzedClickInfo{:,1}));
    biasLevel = str2double(analyzedClickInfo{biasInd(1),2});
    % read frame and subtract background
    currentFrame = imread(lumFileList{frameCtr}); % uint16
%     if size(currentFrame,1) ==480
%         currentFrame = imresize(currentFrame,0.5);
%     end
    lumTiffStack(:,:,frameCtr) = currentFrame-biasLevel;
%     darkTiffStack(:,:,frameCtr) = imread(darkFileList{frameCtr});
%     lumTiffStack(:,:,frameCtr) = lumTiffStack(:,:,frameCtr)-darkTiffStack(:,:,frameCtr);
end

% go through each ROI to apply mask and extract signal
for ROICtr = numROI:-1:1
    %ROImask= imresize(ROImask(:,:,ROICtr),0.5);%%%%%%%
    %maskedTiffStack = lumTiffStack.*uint16(ROImask)%(:,:,ROICtr));
    maskedTiffStack = lumTiffStack.*uint16(ROImask(:,:,ROICtr));
    signal(ROICtr,:) = squeeze(sum(sum(maskedTiffStack,1),2));
end
end