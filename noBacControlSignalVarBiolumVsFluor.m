clear 
close all

% biolum (1s)
%filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151525/measurements.txt';
% GFPshort (1s, 465 exi 520 em)
%filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151607/measurements.txt';
% GFPlong (1s, 500 exi 540 em)
%filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151639/measurements.txt';

varFig = figure; 
signal = [];
groupVar = [];

% biolum (1s)
filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151525/measurements.txt';
T = readtable(filename,'ReadVariableNames',1,'delimiter','\t');
signalAll = T.TotalFlux_p_s_;
signalControl = signalAll(9); % pos 9 has no plate
signalTest = signalAll(1:8); % pos 1-8 has plate with no worm
signalNorm = signalTest;%/signalControl;
signal = vertcat(signal,signalNorm);
groupVar = vertcat(groupVar, ones(numel(signalNorm),1)*1);

% GFPshort (1s, 465 exi 520 em)
filename = '/Volumes/behavgenom$/Serena/bioluminescence/IVIS/realExp/20190813/SD20190813151607/measurements.txt';
T = readtable(filename,'ReadVariableNames',1,'delimiter','\t');
signalAll = T.TotalFlux_p_s_;
signalControl = signalAll(9); % pos 9 has no plate
signalTest = signalAll(1:8); % pos 1-8 has plate with no worm
signalNorm = signalTest;%/signalControl;
signal = vertcat(signal,signalNorm);
groupVar = vertcat(groupVar, ones(numel(signalNorm),1)*2);

% % output
% medianSignalNorm = median(signalNorm)
% stdSignalNorm = std(signalNorm)
% stdToMedianRatio = medianSignalNorm/stdSignalNorm

% plot
boxplot(signal,groupVar)
set(gca,'XTickLabel',{'biolum.','fluor.'});
ylim([-1e8 9e8])
yTick = get(gca, 'YTick');
set(gca,'YTick',yTick,'YTickLabel',yTick/1e8) % rescale y-axis to fit with the label
ylabel('signal (x10^8 photons/s)')

exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',25,...
    'LineWidth',3);
addpath('/Users/sding/Documents/AggScreening/auxiliary/')
exportfig(varFig,'backgroundVar.eps',exportOptions)