clear
close all

expDir = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190808/SD20190808184425_SEQ';

% get list of frame folders
framesList = dir([expDir,'/SD2019*']);
for i = numel(framesList):-1:1
    idxGood(i) = framesList(i).isdir;
end
framesList = framesList(idxGood);

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

% make video
vo = VideoWriter('test','MPEG-4');
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
