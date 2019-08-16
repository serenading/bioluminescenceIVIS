clear
close all

%% script works with 5HT treatment and control videos (40 worms) to
% extract features for each of the strains of interest based on downsampled pixel data (options to show downsampled frame and make video);

wormNum = 40; % 40 or 10 or 15
drugTx = 'none'; % 'none' or '5HT'
group = 'postExposure'; % 'acclimitisation' or 'postExposure'
date = 20190731; %20190731 or 20190803
frameRate = 25; % frames per second
pixelToMicron = 10; % 1 pixel is 10 microns

addpath('../AggScreening/auxiliary/')
addpath('../AggScreening/')
acFig = figure; hold on

%% read metadata and find the relevant filenames
metadata = readtable('/Volumes/behavgenom$/Serena/bioluminescence/Phenix/metadata_biolumDrugFeeding.csv');
expRowLogInd = strcmp(metadata.drug_type,drugTx) & metadata.worm_number == wormNum & strcmp(metadata.group,group) & metadata.date_yyyymmdd == date;
filenames = metadata.filename(expRowLogInd);

sampleFrameEveryNSec = 5; % use multiples of 0.04 (= 1 frame/s at 25 fps). 0.32 = 3 frames/s
sampleEveryNPixel = 8;
maxLag = 1200; % maximum lag time in seconds; currently do not set maxLag > 900s, as script extracts frames from twice the duration so the final frame has a full lag time.
yscale = 'linear';
yLabel = 'correlation coefficient';
xLabel = 'lag (frames)';
figTitle = 'video auto correlation';
xLim = [0 maxLag/sampleFrameEveryNSec];

% set default parameters
useIntensityMask = true;
useOnFoodMask = false;
useMovementMask = true;
phaseRestrict = true; % phaseRestrict cuts out the first 15 min of each video
pixelToMicron = 10; % 10 microns per pixel, read by pixelsize = double(h5readatt(filename,'/trajectories_data','microns_per_pixel?))
dims = [2048 2048]; % can be read by the following but slow: fileInfo = h5info(maskedVideoFileName); dims = fileInfo.Datasets(2).Dataspace.Size; %[2048,2048,num]
showFrame = false;

% set eps export options
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',30,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',25,...
    'LineWidth',3);

% % generate colormap for plotting each strain
% colorMap = distinguishable_colors(10);

%% go through each file
for fileCtr = 1:numel(filenames)
    clusterVisFig = figure; hold on
    filename = strrep(strrep(filenames{fileCtr},'MaskedVideos','OldResults'),'.hdf5','_skeletons.hdf5');
    %filename = '/Volumes/behavgenom$/Serena/bioluminescence/Phenix/Results/postExposure/20190803_biolumDrugFeeding/5HT_10worm_Ch1_03082019_195105_skeletons.hdf5';
    %filename = '/Volumes/behavgenom$/Serena/bioluminescence/Phenix/Results/postExposure/20190803_biolumDrugFeeding/noDrug_10worm_Ch2_03082019_195105_skeletons.hdf5';
    
    %% calculate feature
    trajData = h5read(filename,'/trajectories_data');
    frameRate = double(h5readatt(filename,'/plate_worms','expected_fps'));
    foodContourCoords = h5read(filename,'/food_cnt_coord');
    maskedVideoFileName = strrep(strrep(filename,'OldResults','MaskedVideos'),'_skeletons.hdf5','.hdf5');
    if useOnFoodMask
        %% generate onfood binary mask
        onFoodMask = poly2mask(foodContourCoords(2,:),foodContourCoords(1,:),dims(1),dims(2)); % transposes foodContourCoords to match image coordinate system
        % dilate mask to include pixels immediately outside the mask
        structuralElement = strel('disk',64); % dilate foodpatch by 64 pixels = 640 microns, about half a worm length
        onFoodMaskDilate = imdilate(onFoodMask,structuralElement);
        % get the overall area of food patch in micron squared
        overallArea = nnz(onFoodMaskDilate)*pixelToMicron^2;
    end
    %% sample frames
    if phaseRestrict
        startFrameNum = frameRate*60*20; % cuts out the first 15 minutes
    else
        startFrameNum = 0;
    end
    endFrameNum = maxLag*frameRate*2 + startFrameNum; % sample twice as many frames to generate maskedImageStack
    if endFrameNum > max(trajData.frame_number)
        endFrameNum = max(trajData.frame_number);
    end
    numFrames = floor(numel(startFrameNum:endFrameNum)/frameRate/sampleFrameEveryNSec);
    sampleFrames = startFrameNum:sampleFrameEveryNSec*frameRate:endFrameNum;
    plotColors = parula(numFrames); % for visualisation over time
    
    %% go through each frame to generate downsampled frames
    tic
    maskedImageStack = true(numel(1:sampleEveryNPixel:dims(1)),numel(1:sampleEveryNPixel:dims(2)),numFrames);
    if showFrame
        originalImageStack = NaN(numel(1:sampleEveryNPixel:dims(1)),numel(1:sampleEveryNPixel:dims(2)),numFrames);
    end
    for frameCtr = 1:numFrames
        % load the frame
        imageFrame = h5read(maskedVideoFileName,'/mask',[1,1,double(sampleFrames(frameCtr))],[dims(1),dims(2),1]);
        maskedImage = imageFrame;
        % apply various masks to get binary image of worm/nonworm pixels
        if useIntensityMask
            % generate binary segmentation based on black/white contrast
            maskedImage = maskedImage>0 & maskedImage<70;
        end
        if useOnFoodMask
            % generate binary segmentation based on on/off mask
            maskedImage = maskedImage & onFoodMaskDilate;
        end
        % downsample masked image
        downsampleMaskedImage = maskedImage(1:sampleEveryNPixel:dims(1),1:sampleEveryNPixel:dims(2));
        % add downsampled image to image stack
        maskedImageStack(:,:,frameCtr) = downsampleMaskedImage;
        % generate downsampled, unmasked frame for side by side masking comparison
        if showFrame
            intensityMaskedImageFrame = imageFrame>0 & imageFrame<70;
            originalImageStack(:,:,frameCtr) = intensityMaskedImageFrame(1:sampleEveryNPixel:dims(1),1:sampleEveryNPixel:dims(2));
        end
        disp([num2str(frameCtr) '/' num2str(numFrames) ' processed'])
    end
    % generate no movement mask
    movementMask = std(maskedImageStack,0,3)>0;
    % pre-allocate 2D maskedImage stack and frame standard deviation matrix
    maskedImageStack2D = NaN(size(maskedImageStack,1)*size(maskedImageStack,2),size(maskedImageStack,3)); % npixels by time
    numStartingFrames = floor(numFrames/2);
    frameStd = NaN(1,numFrames);
    % go through each frame
    for frameCtr = 1:5:numFrames %%%%%%
        % apply movement mask
        if useMovementMask
            maskedImageStack(:,:,frameCtr) = maskedImageStack(:,:,frameCtr) & movementMask;
        end
        % display frame
        if showFrame
            set(0,'CurrentFigure',sampleFrameFig)
            imshow([originalImageStack(:,:,frameCtr) maskedImageStack(:,:,frameCtr)])
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % plot visualisation over time
        binaryImage = maskedImageStack(:,:,frameCtr);
        blobBoundaries = bwboundaries(binaryImage,8,'noholes');
        % plot individual blob boundaries
        set(0,'CurrentFigure',clusterVisFig), hold on
        for blobCtr = 1:numel(blobBoundaries)
            fill(blobBoundaries{blobCtr}(:,1)*pixelToMicron,blobBoundaries{blobCtr}(:,2)*pixelToMicron,plotColors(frameCtr,:),'edgecolor','none')
            alpha 0.5
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % check that the frame isn't all 1's by preallocation default
        assert (nnz(maskedImageStack(:,:,frameCtr)) < size(maskedImageStack(:,:,frameCtr),1)*size(maskedImageStack(:,:,frameCtr),2),...
            ['Frame ' num2str(frameCtr) ' has all true pixels by pre-allocation default. Something is wrong'])
        % write frame to 2D maskedImageStack
        currentImage = maskedImageStack(:,:,frameCtr);
        maskedImageStack2D(:,frameCtr) = currentImage(:) - mean(currentImage(:));
        % calculate standard deviation
        frameStd(frameCtr) = std(maskedImageStack2D(:,frameCtr));
        disp([num2str(frameCtr) '/' num2str(numFrames) ' processed'])
    end
    toc
    tic
    % plot food boundary
    set(0,'CurrentFigure',clusterVisFig), hold on
%     th = 0:pi/50:2*pi;
%     xunit = rcoords(fileCtr) * cos(th) + xcoords(fileCtr);
%     yunit = rcoords(fileCtr) * sin(th) + ycoords(fileCtr);
%     plot(yunit,xunit,'k--');
    axis equal
    xlim([0 2000])
    ylim([0 2000])
    filesplit = strsplit(filename,'/');
    title(filesplit{end},'Interpreter','none')
    colorbar
    % calculate feature
    ac{fileCtr} = calculateImageAutocorrelation(maskedImageStack2D,frameStd);
    toc
    
    % %% plot features
    y = nanmean(ac{fileCtr},1)';
    x = 0:numel(y)-1; x = x';
    set(0,'CurrentFigure',acFig)
    plot(x,y)%'Color',colorMap{fileCtr})
end

    
% save
%save(['results/Phenix/autocorrelation/autocorr_' drugTx '_' num2str(wormNum) '_' group '.mat'],'ac','filenames')