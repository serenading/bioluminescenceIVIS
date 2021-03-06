function weeklySignal = separateSignalByWeek(signal)

weeklyDates = [20190219 20190220 20190221 20190222;...
    20190226 20190227 20190228 20190301;
    20190305 20190306 20190307 20190308;
    20190312 20190313 20190314 20190315];
allSignal = signal(:,3);
daysOfInoculation = signal(:,4);

for weekCtr = 1:size(weeklyDates,1)
    weeklyInd = [];
    for dateCtr = 1:size(weeklyDates,2)
        weeklyInd = vertcat(weeklyInd,find(signal(:,1) == weeklyDates(weekCtr,dateCtr)));
    end
    weeklySignal{weekCtr} = [allSignal(weeklyInd) daysOfInoculation(weeklyInd)];
end