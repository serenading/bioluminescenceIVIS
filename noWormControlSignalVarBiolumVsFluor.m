clear
close all

%% script generates box plots for plotting background signal of control (no worm) vs. worm feeding experiments.
% step 1: signal from the no worm control starting frame is extracted (starting signal)
% step 2: signal from the last 10 frames is extracted for each ROI (final signal)
% step 3: no bacteria background signal (no signal) is loaded and subtracted from all signal from 1 and 2
% step 4: final signal is divided by starting control signal

addpath('../AggScreening/auxiliary/')

exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',20,...
    'LineWidth',3);

saveResults = false;
bgSub = false;

%% GFP case
%% experiment 1/2
load('signalExpN7.mat','signal')
% get starting signal from no worm control
startingControl = signal(9,1);
% get signal from the final 10 frames
signalCat = signal(9,end-10:end); % control
signalCat = vertcat(signalCat, signal(1:3,end-10:end)); % DA609
signalCat = vertcat(signalCat, signal(4:6,end-10:end)); % N2
% generate grouping variable
groupVar = ones(1,1);
groupVar = vertcat(groupVar,2*ones(3,1));
groupVar = vertcat(groupVar,3*ones(3,1));
%% experiment 2/2
load('signalExpN8.mat','signal')
% get starting signal from no worm control
startingControl = vertcat(startingControl,signal(9,1));
% get signal from the final 10 frames
signalCat = vertcat(signalCat,signal(9,end-10:end)); % control
signalCat = vertcat(signalCat,signal(1:3,end-10:end)); % DA609
signalCat = vertcat(signalCat,signal(4:6,end-10:end)); % N2
% generate grouping variable
groupVar = vertcat(groupVar,ones(1,1));
groupVar = vertcat(groupVar,2*ones(3,1));
groupVar = vertcat(groupVar,3*ones(3,1));
%% process both experiments
if bgSub
% get no bacteria background signal
filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151607/measurements.txt';
T = readtable(filename,'ReadVariableNames',1,'delimiter','\t');
signalAll = T.TotalFlux_p_s_;
signalBackground = median(signalAll(1:8)); % pos 1-8 has plate with no worm
else
% don't subtract background
signalBackground = 0;
end
% get median starting signal
startingControl = median(startingControl) - signalBackground;
% get median signal from final 10 frames of each and normalise against starting control
signalCat = (median(signalCat,2)-signalBackground)/startingControl;
%% plot 
fluorFig = figure; 
boxplot(signalCat,groupVar,'BoxStyle','filled')
% change filled boxplot width
a = get(get(gca,'children'),'children');   % Get the handles of all the objects
t = get(a,'tag');   % List the names of all the objects 
idx=strcmpi(t,'box');  % Find Box objects
boxes=a(idx);          % Get the children you need
set(boxes,'linewidth',40); % Set width
%
set(gca,'XTickLabel',{'no worm','DA609','N2'})
ylabel('fraction of starting signal')
ylim([0.001 1.5])
set(gca,'yscale','log')
ax = gca;
ax.YGrid = 'on';
ax.MinorGridLineStyle = '-';
ax.MinorGridColor = [0.3,0.3,0.3];
rotation = 45; 
set(gca,'XTickLabelRotation',rotation);
%% export
if saveResults
exportfig(fluorFig, '/Users/sding/Dropbox/bioluminescence paper/figsForPaper/backgroundVar/haloVar_fluor_filled_noBgSub.eps',exportOptions)
end

%% bioluminescence case
%% experiment 1/2
load('signalExpN4.mat','signal')
% get starting signal from no worm control
startingControl = signal(9,1);
% get signal from the final 10 frames
signalCat = signal(9,end-10:end); % control
signalCat = vertcat(signalCat, signal(1:3,end-10:end)); % DA609
signalCat = vertcat(signalCat, signal(4:6,end-10:end)); % N2
% generate grouping variable
groupVar = ones(1,1);
groupVar = vertcat(groupVar,2*ones(3,1));
groupVar = vertcat(groupVar,3*ones(3,1));
%% experiment 2/2
load('signalExpN5.mat','signal')
% get starting signal from no worm control
startingControl = vertcat(startingControl,signal(9,1));
% get signal from the final 10 frames
signalCat = vertcat(signalCat,signal(9,end-10:end)); % control
signalCat = vertcat(signalCat,signal(1:3,end-10:end)); % DA609
signalCat = vertcat(signalCat,signal(4:6,end-10:end)); % N2
% generate grouping variable
groupVar = vertcat(groupVar,ones(1,1));
groupVar = vertcat(groupVar,2*ones(3,1));
groupVar = vertcat(groupVar,3*ones(3,1));
%% %% process both experiments
if bgSub
    % get no bacteria background signal
    filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151525/measurements.txt';
    T = readtable(filename,'ReadVariableNames',1,'delimiter','\t');
    signalAll = T.TotalFlux_p_s_;
    signalBackground = median(signalAll(1:8)); % pos 1-8 has plate with no worm
else
    signalBackground = 0;
end
% get median starting signal
startingControl = median(startingControl) - signalBackground;
% get median signal from final 10 frames of each and normalise against starting control
signalCat = (median(signalCat,2)-signalBackground)/startingControl;
%% plot 
biolumFig = figure; 
set(0,'CurrentFigure',biolumFig)
boxplot(signalCat,groupVar,'BoxStyle','filled')
% change filled boxplot width
a = get(get(gca,'children'),'children');   % Get the handles of all the objects
t = get(a,'tag');   % List the names of all the objects 
idx=strcmpi(t,'box');  % Find Box objects
boxes=a(idx);          % Get the children you need
set(boxes,'linewidth',40); % Set width
%
set(gca,'XTickLabel',{'no worm','DA609','N2'})
ylabel('fraction of starting signal')
ylim([0.001 1.5])
set(gca,'yscale','log')
ax = gca;
ax.YGrid = 'on';
ax.MinorGridLineStyle = '-';
ax.MinorGridColor = [0.3,0.3,0.3];
rotation = 45; 
set(gca,'XTickLabelRotation',rotation);

%% export
if saveResults
exportfig(biolumFig, '/Users/sding/Dropbox/bioluminescence paper/figsForPaper/backgroundVar/haloVar_biolum_filled_noBgSub.eps',exportOptions)
end