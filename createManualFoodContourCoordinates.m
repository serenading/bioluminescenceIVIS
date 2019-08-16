%% get list of MaskedVideo files from metadata
T = readtable('/Volumes/behavgenom$/Serena/bioluminescence/Phenix/metadata_biolumDrugFeeding.csv');
filenames = T.filename;

% loop through each file
for fileCtr = 1:numel(filenames)
    filename = filenames{fileCtr};
   
%     %% get the first frame for manual annotation of food contours
%     % read first full image from the MaskedVideo
%     fullData = h5read(filename,'/full_data');
%     firstFullImage = fullData(:,:,1);
%     % save first image
%     filenameSplit = strsplit(filename,'/');
%     imageFileName1 = filenameSplit{end-1};
%     imageFileName2 = filenameSplit{end};
%     imageFileName2 = strrep(imageFileName2,'.hdf5','.jpg');
%     imageFileName = ['/Volumes/behavgenom$/Serena/bioluminescence/Phenix/firstFullImage/manualFoodContourImages/' imageFileName1 '__' imageFileName2];
%     imwrite(firstFullImage,imageFileName);
% end

%% manual annotation of food contours.
% use VGG http://www.robots.ox.ac.uk/~vgg/software/via/via.html to draw and export food contour.
% Add xyr coordinates to metadata file manually.

%% create food contour coordinates in the dimension of [2,n] and write to skeletons file
skelFilename = strrep(strrep(filename,'MaskedVideos','Results'),'.hdf5','_skeletons.hdf5');
try
    foodCntCoords = h5read(skelFilename,'/food_cnt_coord');
catch ME
    % if the coordinates don't already exist
    if strcmp(ME.identifier,'MATLAB:imagesci:h5read:libraryError')
        % create food contour coordinates
        x = T.food_cnt_x(fileCtr);
        y = T.food_cnt_y(fileCtr);
        r = T.food_cnt_r(fileCtr);
        th = 0:pi/50:2*pi;
        xunit = r * cos(th) + x;
        yunit = r * sin(th) + y;
        foodCntCoords = vertcat(xunit, yunit);
        % write food contour coordinates to skeletons file
        h5create(skelFilename,'/food_cnt_coord',size(foodCntCoords),'Datatype','double');
        h5write(skelFilename,'/food_cnt_coord',double(foodCntCoords));
    end
end
end
%% delete featuresN files and re-run features calculation.
