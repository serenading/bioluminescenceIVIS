directory = '/Volumes/behavgenom$/Serena/IVIS/growthExp/20190314';
files = dir(directory);
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags);
% Print folder names to command window.
names = '';
for k = 1 : length(subFolders)
    names = [names subFolders(k).name newline];
    % fprintf(subFolders(k).name,'\n')
  %fprintf(subFolders(k).name newline);
end
names