clear
close all

%% script combines all the luminescent.tif files from individual frame folders of a time series sequence,
% rescales using min and max intensity of the sequence, and makes a .mp4 movie

expDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20191122/SD20191122211653_SEQ';
%expDir2 = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20191121/SD20191122063328_SEQ';

% get list of frame folders
framesList = dir([expDir,'/SD2019*']);
for i = numel(framesList):-1:1
    idxGood(i) = framesList(i).isdir;
end
framesList = framesList(idxGood);

% check to see if a second directory exists
bool = exist('expDir2','var');
if bool
    framesList2 = dir([expDir2,'/SD2019*']);
    for i = numel(framesList2):-1:1
        idxGood2(i) = framesList2(i).isdir;
    end
    framesList2 = framesList2(idxGood2);
    % concatenate framesList
    framesList = vertcat(framesList,framesList2);
end
    
% make a full framestack
frameStack = zeros(480, 480, numel(framesList), 'uint16');
for i = 1:numel(framesList)
    img = imread([framesList(i).folder,'/',framesList(i).name,'/luminescent.TIF']);
    frameStack(:,:,i) = img;
end

% get the max and min values of the full frame stack for rescaling
minval = min(frameStack(:));
frameStack = frameStack-minval;
maxval = single(prctile(frameStack(:),99.99)); % use 99.99 percentile (instead of max) to avoid hot pixels
display([minval maxval])

% make video (just for visualisation)
videoName = strsplit(expDir,'/');
videoName = videoName{end};
vo = VideoWriter(videoName,'MPEG-4');
vo.FrameRate = 15;
open(vo);

for i = 1:size(frameStack,3)
    img = frameStack(:,:,i);
    img = single(img)/maxval; % convert image to float. After dividing the value will be between [0 1].
    img = 255*img; % re-scale value to between [0 255].
    img = uint8(img); % convert to uint8 for screen display
    writeVideo(vo,img);
end

close(vo)

% open directory containing the video
!open .
