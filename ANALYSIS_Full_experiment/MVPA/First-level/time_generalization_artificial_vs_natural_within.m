function time_generalization_artificial_vs_natural_within(subject,task) 
%TIME_GENERALIZATION_ARTIFICIAL_VS_NATURAL_WITHIN Perform category decoding
%(artificial vs natural) using the SVM classifier,
%in a time-generalized manner (trained & tested on all timepoints),
%on data from one task.
%
%Input: subject ID, task (1=categorization, 2=fixation)
%
%Output: PxP vector of accuracies in %, where P is the number of timepoints. 
%
%% Set-up prereqs
%add paths
addpath(genpath('/scratch/agnek95/PDM/DATA/DATA_FULL_EXPERIMENT'));
addpath(genpath('/home/agnek95/SMST/PDM_PILOT_2/ANALYSIS_Full_experiment/'));
addpath('/home/agnek95/OR/TOOLBOX/MVNN/MEG_SVM_decoding_MVNN'); %MVNN toolbox
addpath(genpath('/home/agnek95/OR/ANALYSIS/DECODING/libsvm')); %libsvm toolbox
addpath('/home/agnek95/OR/ANALYSIS/DECODING'); %MVNN function
addpath('/home/agnek95/OR/TOOLBOX/fieldtrip-20190224');
ft_defaults;

%subject and task name string
subname = get_subject_name(subject);
task_name = get_task_name(task); 

%check if there's a directory for that subject, otherwise create one
results_dir = '/home/agnek95/SMST/PDM_FULL_EXPERIMENT/RESULTS';
if ~isfolder(fullfile(results_dir,subname))
    mkdir(results_dir,subname);
end
 
%% Prepare data
data_dir = sprintf('/scratch/agnek95/PDM/DATA/DATA_FULL_EXPERIMENT/%s/',subname);
load(fullfile(data_dir,sprintf('timelock_%s',task_name))); %eeg
load(fullfile(data_dir,sprintf('preprocessed_behavioural_data_%s',task_name)));

%only keep the trials with a positive RT & correct response
timelock_triggers = timelock.trialinfo(behav.RT>0 & behav.points==1); %triggers
timelock_data = timelock.trial(behav.RT>0 & behav.points==1,:,:); %actual data

%% Downsample from 5ms/timepoint to 20ms
numResampledTps = 50; 
numTimepointsOld = size(timelock_data,3);
steps_per_tp = numTimepointsOld/numResampledTps; %number of old timepoints to average over to obtain one new timepoint 
size_data = size(timelock_data);
downsampled_timelock_data = NaN([size_data(1:2), numResampledTps]);
i = 1;
for tp=1:numResampledTps
    downsampled_timelock_data(:,:,tp) = squeeze(mean(timelock_data(:,:,i:i+steps_per_tp-1),3));
    i = i+steps_per_tp;
end 

%% Define the required variables
numConditions = 60;
num_categories = 2; %categories to decode
num_conditions_per_category = numConditions/num_categories;
numTimepoints = size(timelock_data,3); %number of timepoints
numPermutations=100; 

%minimum number of trials per scene
[numTrials, ~] = min_number_trials(timelock_triggers, numConditions); 

%Preallocate 
decodingAccuracy=NaN(numPermutations,numTimepoints,numTimepoints);

%% Decoding
rng('shuffle');
for perm = 1:numPermutations
    tic   
    disp('Creating the data matrix');
    data = create_data_matrix(numConditions,timelock_triggers,numTrials,timelock_data);

    disp('Performing MVNN');
    data = multivariate_noise_normalization(data); %returns: numConditions x numTrials x numElectrodes x numTimepoints
      
    disp('Split into artificial and natural');
    data_artificial = data(1:num_conditions_per_category,:,:,:);
    data_natural = data(num_conditions_per_category+1:end,:,:,:);
       
    disp('Average over trials');
    data_artificial_avg = squeeze(mean(data_artificial,2));
    data_natural_avg = squeeze(mean(data_natural,2));
    
    disp('Permute the conditions (scenes)');
    conditions_order = randperm(num_conditions_per_category)';
    data_artificial_avg = data_artificial_avg(conditions_order,:,:);
    data_natural_avg = data_natural_avg(conditions_order,:,:);
    
    disp('Put both categories into one matrix');
    data_both_categories = NaN([num_categories,size(data_artificial_avg)]);
    data_both_categories(1,:,:,:) = data_artificial_avg;
    data_both_categories(2,:,:,:) = data_natural_avg;
    
    disp('Split into bins of scenes');
    numScenesPerBin = 5;
    [bins,numBins] = create_pseudotrials(numScenesPerBin,data_both_categories);
    num_bins_testing = 3;  
    testing_conditions = (numScenesPerBin*num_bins_testing)+1:numScenesPerBin*numBins;
    
    for tp1 = 1:numTimepoints 
        disp('Split into training and testing');
        training_data = [squeeze(bins(1,1:end-num_bins_testing,:,tp1)); squeeze(bins(2,1:end-num_bins_testing,:,tp1))]; %train on half of the bins                 
        labels_train  = [ones(numBins-num_bins_testing,1);2*ones(numBins-num_bins_testing,1)]; %one label for each pseudotrial
        
        disp('Train the SVM');
        train_param_str= '-s 0 -t 0 -b 0 -c 1 -q'; %look up the parameters online if needed
        model=svmtrain_01(labels_train,training_data,train_param_str); 
        
        for tp2 = 1:numTimepoints
            disp('Test the SVM');
            testing_data  = [squeeze(data_both_categories(1,testing_conditions,:,tp2)); squeeze(data_both_categories(2,testing_conditions,:,tp2))];
            labels_test   = [ones(numel(testing_conditions),1);2*ones(numel(testing_conditions),1)];   
            [~, accuracy, ~] = svmpredict(labels_test,testing_data,model);
            decodingAccuracy(perm,tp1,tp2)=accuracy(1);         
        end
    end   
    toc
end

%% Save the decoding accuracy
decodingAccuracy_avg = squeeze(mean(decodingAccuracy,1)); %average over permutations
save(fullfile(results_dir,subname,sprintf('time_gen_svm_artificial_vs_natural_decoding_accuracy_%s.mat',task_name)),'decodingAccuracy_avg');

