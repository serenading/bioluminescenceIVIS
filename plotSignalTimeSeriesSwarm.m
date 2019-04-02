directory = '/Volumes/behavgenom$/Serena/IVIS/timeSeries/20190315/';
numROI = 1;
varName = 'AvgRadiance_p_s_cm__sr_';
signal = getLivingImageSignal(directory,numROI,varName);
figure; plot(signal)
xTick = get(gca, 'XTick');
set(gca,'XTick',xTick','XTickLabel',xTick*60/10) % rescale x-axis for according to acquisition frame rate
xlabel('t (min)')