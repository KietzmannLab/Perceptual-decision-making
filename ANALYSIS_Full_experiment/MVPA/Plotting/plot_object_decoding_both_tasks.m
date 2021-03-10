function plot_object_decoding_both_tasks(subjects)
%PLOT_OBJECT_BOTH_TASKS Plot the results from object decoding, averaged over
%all participants for both tasks (categorization and distraction).
%
%Input: subject IDs
%
%Output: curve of decoding accuracies per timepoint, for two tasks

%% Paths
addpath(genpath('/home/agnek95/SMST/PDM_PILOT_2/ANALYSIS_Full_experiment/'));
results_dir = '/home/agnek95/SMST/PDM_FULL_EXPERIMENT/RESULTS/';
results_avg_dir = '/home/agnek95/SMST/PDM_FULL_EXPERIMENT/RESULTS_AVG/';

%% Preallocate
numConditions = 60;
numTimepoints = 200;
decoding_accuracies_all_subjects_cat = NaN(numel(subjects),numConditions,numConditions,numTimepoints);
decoding_accuracies_all_subjects_fix = NaN(numel(subjects),numConditions,numConditions,numTimepoints);

%% Loop: collect results from all subjects + plot each subject individually on the same plot
for subject = subjects
    subname = get_subject_name(subject);
    subject_results_dir = fullfile(results_dir,subname);
    load(fullfile(subject_results_dir,'svm_decoding_accuracy_categorization.mat'));
    decoding_accuracies_all_subjects_cat(subject,:,:,:) = decodingAccuracy_avg;
    load(fullfile(subject_results_dir,'svm_decoding_accuracy_fixation.mat'));
    decoding_accuracies_all_subjects_fix(subject,:,:,:) = decodingAccuracy_avg;
end   

%% Remove any NaN (for non-included subjects)
avg_over_conditions_all_subjects_cat = squeeze(nanmean(nanmean(nanmean(decoding_accuracies_all_subjects_cat,1),2),3));
avg_over_conditions_all_subjects_fix = squeeze(nanmean(nanmean(nanmean(decoding_accuracies_all_subjects_fix,1),2),3));

%% Plot the average of all subjects
figure(abs(round(randn*10))); %Random figure number
set(gcf, 'Position', get(0, 'Screensize'));
plot(avg_over_conditions_all_subjects_cat,'Linewidth',3);
hold on;
plot(avg_over_conditions_all_subjects_fix,'Linewidth',3);
hold on;
title = sprintf('Object decoding per timepoint for %d subjects',numel(subjects));
onset_time = 40; 
xticks(0:10:200);
legend_cell = {'Scene categorization','Distraction'};
plotting_parameters(title,legend_cell,onset_time,12,[0.75 0.7 0.1 0.1],'Decoding accuracy (%)');

%save the plot
saveas(gcf,fullfile(results_avg_dir,sprintf('svm_object_decoding_%d_subjects_both_tasks',numel(subjects)))); %save as matlab figure
saveas(gcf,fullfile(results_avg_dir,sprintf('svm_object_decoding_%d_subjects_both_tasks.svg',numel(subjects)))); %save as svg
close(gcf);    

end