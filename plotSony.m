clear
close all

% initialise
addpath('../AggScreening/auxiliary/')
dc = readraw; % this is called once to allow reading ARW files as tiff images using matlab imread and imfinfo functions

% set analysis parameters
foldername = '10191114';
%foldername2 = '11091122';
binFactor = 8; % 8 for 8x8 binning, 1 for no binning

%% get dark images for background subtraction

% dark image taken with camera lid on
% darkImgLidOnFilename = '/Volumes/behavgenom$/Serena/bioluminescence/Sony/10191114_dark/KSS06962.ARW';
% darkImgLidOnImage = imread(darkImgLidOnFilename) ;% read in image
% info = imfinfo(darkImgLidOnFilename); % read image metadata

% dark image taken with camera lid off
darkImgLidOffFilename = '/Volumes/behavgenom$/Serena/bioluminescence/Sony/10191114_dark/KSS06963.ARW';
darkImgLidOffImage = imread(darkImgLidOffFilename);
%info = imfinfo(darkImgLidOffFilename); 

%% go through the image stack frame by frame to process image and extract signal

frameNames = rdir(['/Volumes/behavgenom$/Serena/bioluminescence/Sony/' foldername '/*.ARW']);
if exist('foldername2')
    frameNames2 = rdir(['/Volumes/behavgenom$/Serena/bioluminescence/Sony/' foldername2 '/*.ARW']);
    frameNames = vertcat(frameNames,frameNames2);
end
numFrames = numel(frameNames);

% pre-allocate signal matrix
signal = zeros(numFrames,3); % size of numROIs x numFrames

% initialise to make an image stack
frameStack = zeros(503, 753, numFrames, 'uint16');

% go through each image frame
for frameCtr = 1:numFrames
    frameName = frameNames(frameCtr).name; % get file name
    
    % read in image
    image_raw = imread(frameName);
    % subtract dark background for each channel
    image = image_raw - darkImgLidOffImage;
    % set minimum value to zero following background subtraction (if there are negative values)
    image(image<0) = 0;
    % set red channel (channel 1) to 0 because it is very noisy and bioluminescence is in green/blue channels
    image(:,:,1) = 0;
    % turn RGB image into grayscale
    image = rgb2gray(image);
    % bin image and apply median filter
    image = bin_matrix(image, binFactor,[],@median);
    
    % hand define each of the circular ROI using the first frame
    if frameCtr ==1
        figure;imshow(image,[]);%0 512]);
        ROImask1 = drawcircle;
        ROImask1 = createMask(ROImask1);
        disp('ROI1 complete')
        ROImask2 = drawcircle;
        ROImask2 = createMask(ROImask2);
        disp('ROI2 complete')
        ROImask3 = drawcircle;
        ROImask3 = createMask(ROImask3);
        disp('ROI3 complete')
        close
    end
    
    % extract signal
    signal(frameCtr,1) = sum(sum(image(ROImask1)));
    signal(frameCtr,2) = sum(sum(image(ROImask2)));
    signal(frameCtr,3) = sum(sum(image(ROImask3)));
    disp(['progress: ' num2str(frameCtr/numFrames*100) '% frames processed to create time series signal']) 

    % add image to frameStack
    frameStack(:,:,frameCtr) = image;
end

%% save signal and masks 

save(['/Volumes/behavgenom$/Serena/bioluminescence/Sony/' foldername '/signal.mat'],'signal');
save(['/Volumes/behavgenom$/Serena/bioluminescence/Sony/' foldername '/frameStack.mat'],'frameStack','ROImask1','ROImask2','ROImask3');

%% plot

figure;
plot(signal)
legend('no worm','DA609','N2')

%% video

% get the max and min values of the full frame stack for rescaling
minval = min(frameStack(:));
frameStack = frameStack-minval;
maxval = single(prctile(frameStack(:),99.99)); % use 99.99 percentile (instead of max) to avoid hot pixels
display([minval maxval])

% initialise to make video
vo = VideoWriter(foldername,'MPEG-4');
vo.FrameRate = 30;
open(vo);

% append each frame to video 
for i = 1:size(frameStack,3)
    img = frameStack(:,:,i);
    img = single(img)/maxval; % convert image to float. After dividing the value will be between [0 1].
    img = 255*img; % re-scale value to between [0 255].
    img = uint8(img); % convert to uint8 for screen display
    writeVideo(vo,img);
end

% close video object
close(vo)

% open directory containing the video
!open .