close all
clear

%% script reads in the pharyngeal pumping data collected on 20190730 (Serena lab book 2, p.83-86)
% and makes boxplots for on/off food conditions and different drug treatments.

% Author: @serenading
% Date: 20190802

% read in data
T = readtable('/Volumes/behavgenom$/Serena/bioluminescence/pumpingAssay.xlsx');
ppm = T.ppm;
group = T.group;

% create figure
ppmFig = figure; 

% off food subplot
subplot(1,2,1)
boxplot(ppm(1:25),group(1:25),'BoxStyle','filled');
rotation = 45; 
set(gca,'XTickLabelRotation',rotation);
set(gca,'XTickLabel',{'no drug','serotonin','naloxone'})
ylim([0 350])
ylabel('pumps per minute')
% change filled boxplot width
a = get(get(gca,'children'),'children');   % Get the handles of all the objects
t = get(a,'tag');   % List the names of all the objects 
idx=strcmpi(t,'box');  % Find Box objects
boxes=a(idx);          % Get the children you need
set(boxes,'linewidth',15); % Set width

% on food subplot
subplot(1,2,2)
boxplot(ppm(26:end),group(26:end),'BoxStyle','filled');
rotation = 45; 
set(gca,'XTickLabelRotation',rotation);
set(gca,'XTickLabel',{'no drug','serotonin','naloxone'})
ylim([0 350])
ylabel('pumps per minute')
% change filled boxplot width
a = get(get(gca,'children'),'children');   % Get the handles of all the objects
t = get(a,'tag');   % List the names of all the objects 
idx=strcmpi(t,'box');  % Find Box objects
boxes=a(idx);          % Get the children you need
set(boxes,'linewidth',15); % Set width
%

% set figure export options
exportOptions = struct('Format','eps2',...
    'Color','rgb',...
    'Width',20,...
    'Resolution',300,...
    'FontMode','fixed',...
    'FontSize',18,...
    'LineWidth',3);

% export figure
addpath('../AggScreening/auxiliary/')
figurename = '/Users/sding/Dropbox/bioluminescence paper/figsForPaper/drugPharyngealPumping_filled';
exportfig(ppmFig,[figurename '.eps'],exportOptions)

% two sample t-test, assuming normal distributions and unknown and unequal variances
offFoodNoDrugLogInd = group==1;
offFoodNoDrug = ppm(offFoodNoDrugLogInd);
offFood5HTLogInd = group==2;
offFood5HT = ppm(offFood5HTLogInd);
offFoodNLXLogInd = group==3;
offFoodNLX = ppm(offFoodNLXLogInd);
[h,p] = ttest2(offFoodNoDrug,offFood5HT,'Vartype','unequal');
disp(['p value is ' num2str(p) ' between offFoodNoDrug and offFood5HT'])
[h,p] = ttest2(offFoodNoDrug,offFoodNLX,'Vartype','unequal');
disp(['p value is ' num2str(p) ' between offFoodNoDrug and offFoodNLX'])

onFoodNoDrugLogInd = group==4;
onFoodNoDrug = ppm(onFoodNoDrugLogInd);
onFood5HTLogInd = group==5;
onFood5HT = ppm(onFood5HTLogInd);
onFoodNLXLogInd = group==6;
onFoodNLX = ppm(onFoodNLXLogInd);
[h,p] = ttest2(onFoodNoDrug,onFood5HT,'Vartype','unequal');
disp(['p value is ' num2str(p) ' between offFoodNoDrug and offFood5HT'])
[h,p] = ttest2(onFoodNoDrug,onFoodNLX,'Vartype','unequal');
disp(['p value is ' num2str(p) ' between onFoodNoDrug and onFoodNLX'])