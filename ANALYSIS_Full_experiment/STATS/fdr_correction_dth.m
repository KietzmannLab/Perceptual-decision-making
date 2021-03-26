function fdr_correction_dth(subjects,task,category)
%FDR_CORRECTION_DTH Perform permutation tests + FDR correction on the p-values to calculate the
%significance of the timepoints in the distance-to-hyperplane analysis.
%
%Input: subject IDs, with_stats (1 plot with stats, 0 plot without),
%category ('artificial', 'natural', 'average' or 'both')
%
%Output: 1xP vector of significance (1) or not (0), where P is the number
%of timepoints.
%
%
%% Paths
addpath(genpath('/home/agnek95/SMST/PDM_PILOT_2/ANALYSIS_Full_experiment/'));
results_dir = '/home/agnek95/SMST/PDM_FULL_EXPERIMENT/RESULTS/';

%% Get the distances from all subjects
task_name = get_task_name(task);
numTimepoints = 200;
numConditions = 60;
sorted_subjects = sort(subjects); %order by ID
distances = NaN(sorted_subjects(end),numConditions,numTimepoints);
RTs = NaN(numel(subjects),numConditions);

for subject = subjects
    subname = get_subject_name(subject);
    load(fullfile(results_dir,subname,sprintf('dth_pseudotrials_svm_decisionValues_%s.mat',task_name)));
    load(fullfile(results_dir,subname,sprintf('RTs_correct_trials_%s.mat',task_name)));
    distances(subject,:,:) = decisionValues_Avg;   
    RTs(subject,:) = normalize(RT_per_condition);
end

%% Get the median RTs and mean distances of all subjects for each condition 
medianRT = nanmedian(RTs,1);
mean_distances = squeeze(nanmean(distances,1)); %avg over subjects

%% Only keep the RTs and distances of the category for the analysis
if strcmp(category,'artificial')
    conditions = 1:30;
elseif strcmp(category,'natural')
    conditions = 31:60;
elseif strcmp(category,'average') || strcmp(category,'both')
    conditions = 1:60;
end

medianRT = medianRT(conditions);
mean_distances = mean_distances(conditions,:);

%% Calculate the true correlation value
t = 1:numTimepoints;
true_correlation = arrayfun(@(x) corr(mean_distances(:,x),medianRT','type','Spearman'),t);

                        %%%%% PERMUTATION TEST %%%%%
%% 1) Permute the objects' RTs 10 000 times and calculate the correlation at each timepoint
numPermutations = 10;% 10000;
all_correlations = NaN(numPermutations,numTimepoints);

for perm = 1:numPermutations %replace by parfor!
    permuted_RTs = medianRT(randperm(numel(medianRT)));
    all_correlations(perm,:) = arrayfun(@(x) corr(mean_distances(:,x),permuted_RTs','type','Spearman'),t);
end
keyboard;
%% 2) Calculate the p-value of the true value WRT the permuted samples
%histogram? and then check the value in the 95th percentile?
%calculate the b value: num of permutations larger than the ground truth 
p = NaN(numTimepoints,1);
for tp = 1:numTimepoints
    b = numel(find(all_correlations,tp) > true_correlation(tp)); %https://benediktehinger.de/blog/science/permutation-test-for-matlab/
    p(tp) = (b+1) / (numPermutations+1);
end
            %%%%% FDR CORRECTION: Benjamini-Hochberg procedure %%%%%
%% 1) Rank the p-values in ascending order & assign ranks
%% 2) Calculate the critical value for each p-value
%% 3) Cut off at the largest p-value that is smaller than its critical value

        
        
        
        
        
        
        
        
        
        
                        