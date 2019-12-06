clear
close all

%% signal taken every minute on Sony camera

% initialise
saveResults = false;
plotSingleExp = false;

if plotSingleExp
    foldername = '10191128'; % '10191114','10691120','10991122','11191125','10191128'
else
    plotPooled5Exp = true;
end

addpath('../AggScreening/auxiliary/')

% set analysis parameters
legends = {'no worm','DA609','N2'};
frameInterval = 1;
signalSmoothWindow = 30;
derivativeSmoothWindow = 10;

%% export figures
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',20,...
    'LineWidth',3);

if plotSingleExp
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
    
    %% save and export
    if saveResults
        figurename = ['/Volumes/behavgenom$/Serena/bioluminescence/Sony/plots/' foldername '_'];
        exportfig(rawSignalFig ,[figurename 'raw.eps'],exportOptions)
        exportfig(normalisedSignalFig,[figurename 'normalised.eps'],exportOptions)
        exportfig(signalDerivativeFig,[figurename 'derivative.eps'],exportOptions)
    end
end

%% plot pooled reps

if plotPooled5Exp
    
    load(['/Volumes/behavgenom$/Serena/bioluminescence/Sony/rawSignal_pooled_5reps.mat'],'rawSignal_pooled_5reps');
    rawSignal_pooled_5reps = rawSignal_pooled_5reps(:,1:380);
    
    % plot raw signal
    % all reps
    rawSignalFig = figure; plot(rawSignal_pooled_5reps')
    legend({'no worm','DA609','N2','no worm','DA609','N2','no worm','DA609','N2','no worm','DA609','N2'})
    title('all')
    % individual reps
%     figure; plot(rawSignal_pooled_5reps(1:3,:)')
%     legend({'no worm','DA609','N2'})
%     title('exp101')
%     figure; plot(rawSignal_pooled_5reps(4:6,:)')
%     legend({'no worm','DA609','N2'})
%     title('exp102')
%     figure; plot(rawSignal_pooled_5reps(7:9,:)')
%     legend({'no worm','DA609','N2'})
%     title('exp103')
%     figure; plot(rawSignal_pooled_5reps(10:12,:)')
%     legend({'no worm','DA609','N2'})
%     title('exp104')
%     figure; plot(rawSignal_pooled_5reps(13:15,:)')
%     legend({'no worm','DA609','N2'})
%     title('exp105')
    
    % smooth signal over the specied window
    rawSignal_pooled_5reps_smooth = smoothdata(rawSignal_pooled_5reps,2,'movmedian',signalSmoothWindow);
    
    %% normalise signal to starting values
    normSignal_pooled_5reps = rawSignal_pooled_5reps_smooth./rawSignal_pooled_5reps_smooth(:,1);
    controlNormSignal = normSignal_pooled_5reps([1,4,7,10,13],:);
    DA609NormSignal = normSignal_pooled_5reps([2,5,8,11,14],:);
    N2NormSignal = normSignal_pooled_5reps([3,6,9,12,15],:);
    
    % normalise signal to control
    controlNormSignal = controlNormSignal./controlNormSignal;
    DA609NormSignal = DA609NormSignal./controlNormSignal;
    N2NormSignal = N2NormSignal./controlNormSignal;
    
    % plot smoothed, normalised data
    normalisedSignalFig = figure; hold on
    H(1) = shadedErrorBar([],DA609NormSignal,{@median,@std},{'r'},1);
    H(2) = shadedErrorBar([],N2NormSignal,{@median,@std},{'b'},1);
    H(3) = shadedErrorBar([],controlNormSignal,{@median,@std},{'k'},1);
    xlabel('minutes')
    ylabel('normalised signal')
    mainLineHandles = [H(1).mainLine,H(2).mainLine,H(3).mainLine];
    legend(mainLineHandles,{'DA609','N2','no worm'})
    
    %% plot signal derivative
    
    % take derivative
    controldYdT = takeSignalDerivative(controlNormSignal,frameInterval,derivativeSmoothWindow);
    DA609dYdT = takeSignalDerivative(DA609NormSignal,frameInterval,derivativeSmoothWindow);
    N2dYdT = takeSignalDerivative(N2NormSignal,frameInterval,derivativeSmoothWindow);
    
    % plot
    signalDerivativeFig = figure; hold on
    T(1) = shadedErrorBar([],DA609dYdT,{@median,@std},{'r'},1);
    T(2) = shadedErrorBar([],N2dYdT,{@median,@std},{'b'},1);
    T(3) = shadedErrorBar([],controldYdT,{@median,@std},{'k'},1);
    legend(legends)
    xlabel('minutes')
    ylabel('d/dt n.bioluminescence (x10^{-3}/min)')
    mainLineHandles = [T(1).mainLine,T(2).mainLine,T(3).mainLine];
    legend(mainLineHandles,{'DA609','N2','no worm'})
    % display feeding rates
    display(['DA609 to N2 feeding rate is ' num2str(DA609dYdT(30:150)/N2dYdT(30:150)) ' between 0.5 and 2.5 hours of the experiment'])
    
    %% save and export
    if saveResults
        figurename = ['/Volumes/behavgenom$/Serena/bioluminescence/Sony/plots'];
        exportfig(rawSignalFig,[figurename 'raw.eps'],exportOptions)
        exportfig(normalisedSignalFig,[figurename 'normalised.eps'],exportOptions)
        exportfig(signalDerivativeFig,[figurename 'derivative.eps'],exportOptions)
    end
    
end

%% local function

%% function to calculate signal derivative (identical to plotSignalTimeSeries_realExp local function)
function dYdT = takeSignalDerivative(signal,frameInterval,derivativeSmoothWindow)

% get change in signal over a time window specied by derivativeSmoothWindow
signalShiftWindow = zeros(size(signal,1),derivativeSmoothWindow); % generate zero pad
signalStart = [signalShiftWindow signal]; % zero pad
signalEnd = [signal signalShiftWindow]; % zero pad
signalDiff = signalEnd - signalStart; % take signal difference
signalDiff = signalDiff(:,[derivativeSmoothWindow+1:end-derivativeSmoothWindow]); % remove the padded signal

% convert dT to be in the unit of per minute
frameRate = 1/frameInterval;
dT = derivativeSmoothWindow/frameRate; % time step in minutes
dYdT = signalDiff/dT; % dYdT to be plotted, in the unit of min^-1
end

