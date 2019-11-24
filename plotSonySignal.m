clear
close all

% initialise
addpath('../AggScreening/auxiliary/')

% set analysis parameters
foldername = '10991122';
legends = {'no worm','DA609','N2'};
frameInterval = 1;
derivativeSmoothWindow = 30;

%% raw signal
% load signal
load(['/Volumes/behavgenom$/Serena/bioluminescence/Sony/' foldername '/signal.mat'],'signal');
% plot raw signal
rawSignalFig = figure;
plot(signal)
legend(legends)
title ('raw signal')
xlabel('minutes')
ylabel('rawSignal (a.u.)')

%% normalised signal
% normalise signal to starting value
signal = signal./signal(1,:);
% normalise signal against no worm control (ROI1)
signal = signal./signal(:,1);
% plot normalised signal
normalisedSignalFig = figure;
plot(signal)
legend(legends)
title ('normalised signal')
xlabel('minutes')
ylabel('normalisedSignal')

%% signal derivative
dYdT = takeSignalDerivative(signal',frameInterval,derivativeSmoothWindow);
signalDerivativeFig = figure; 
plot(dYdT')
legend(legends)
title ('signal derivative')
xlabel('minutes')
ylabel('change in signal (a.u./min)')

%% export figures
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',20,...
    'LineWidth',3);

figurename = ['/Users/sding/Desktop/forshow/' foldername '_'];
exportfig(rawSignalFig ,[figurename 'raw.eps'],exportOptions)
exportfig(normalisedSignalFig,[figurename 'normalised.eps'],exportOptions)
exportfig(signalDerivativeFig,[figurename 'derivative.eps'],exportOptions)

%% local function

%% function to calculate signal derivative (identical to plotSignalTimeSeries_realExp local function)
function dYdT = takeSignalDerivative(signal,frameInterval,derivativeSmoothWindow)

% get change in signal
signalShiftWindow = zeros(size(signal,1),derivativeSmoothWindow); % generate zero pad
signalStart = [signalShiftWindow signal]; % zero pad
signalEnd = [signal signalShiftWindow]; % zero pad
signalDiff = signalEnd - signalStart; % take signal difference
signalDiff = signalDiff(:,[derivativeSmoothWindow+1:end-derivativeSmoothWindow]); % remove the padded signal
%
frameRate = 1/frameInterval;
dT = derivativeSmoothWindow/frameRate; % time step in minutes
dYdT = signalDiff/dT; % dYdT to be plotted, in the unit of min^-1
end