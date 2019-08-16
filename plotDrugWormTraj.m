close all
clear

%% set parameters

timeToPlot = [20 40]; % starting and finishing minute of the hour-long recording to plot traj for. Maximally [0 60]
wormNum = 40; % 40 or 10 or 15
drugTx = 'none'; % 'none' or '5HT'
group = 'postExposure'; % 'acclimitisation' or 'postExposure'
frameRate = 25; % frames per second
pixelToMicron = 10; % 1 pixel is 10 microns

exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',20,...
    'LineWidth',5);

addpath('../AggScreening/auxiliary/')

%% read metadata and find the relevant filenames
metadata = readtable('/Volumes/behavgenom$/Serena/bioluminescence/Phenix/metadata_biolumDrugFeeding.csv');
expRowLogInd = strcmp(metadata.drug_type,drugTx) & metadata.worm_number == wormNum & strcmp(metadata.group,group);
filenames = metadata.filename(expRowLogInd);

%% go through each file
for fileCtr = 1:numel(filenames)
    % initialise figure
    thisFig = figure; hold on
    % get file name
    filename = filenames{fileCtr};
    filename_skel = strrep(strrep(filename,'MaskedVideos','Results'),'.hdf5','_skeletons.hdf5');
    % read data
    trajData = h5read(filename_skel,'/trajectories_data');
    foodContourCoords = h5read(filename_skel,'/food_cnt_coord');
    % find worm indices that fall within the sampling time window
    validFrames = timeToPlot*frameRate*60; 
    validFramesLogInd = trajData.frame_number>= validFrames(1) & trajData.frame_number<= validFrames(2);
    validWorms = unique(trajData.worm_index_joined(validFramesLogInd));
    % go through each worm index
    for wormCtr = 1:numel(validWorms)
        wormIdx = validWorms(wormCtr);
        validWormLogInd = trajData.worm_index_joined == wormIdx;
        % get centroid coordinates
        coord_x = trajData.coord_x(validWormLogInd); 
        coord_y = trajData.coord_y(validWormLogInd);
        disp(['worm ' num2str(wormCtr) ' out of ' num2str(numel(validWorms)) ' plotted'])
        % plot centroid traj
        plot(coord_y,coord_x)
    end
    % plot food contour and format plot
    plot(foodContourCoords(1,:),foodContourCoords(2,:),'k--')
    xlim([0 2000])
    ylim([0 2000])
    axis equal
    xTick = get(gca, 'XTick');
    set(gca,'XTick',xTick','XTickLabel',xTick*pixelToMicron/1000); % rescale x-axis to convert from pixel to mm
    yTick = get(gca, 'YTick');
    set(gca,'YTick',yTick','YTickLabel',yTick*pixelToMicron/1000); % rescale y-axis to convert from pixel to mm
    xlabel('distance (mm)')
    ylabel('distance (mm)')
    % save figure
    id = strsplit(filename,'/');
    id = id{end};
    id = strsplit(id,'.');
    id = id{1};
    figurename = ['results/5HTBFTraj/' id '_' num2str(timeToPlot(1)) 'to' num2str(timeToPlot(2)) 'min'];
    savefig(thisFig, [figurename '.fig'])
    exportfig(thisFig,[figurename '.eps'],exportOptions)
end