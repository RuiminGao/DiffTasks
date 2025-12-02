%% MEGA MROI SCRIPT - DEFINE fROIs AND ESTIMATE EFFECTS OF INTEREST
%
% localizer_task: 'language', 'MD', 'DMN'
% main_task_index: currently 1-6
%
% 2022-06-01: created by Anna Ivanova
% 2025-01-30: modified by Ruimin Gao for DiffTasks

function [] = mROI_mega_all(network, main_task_index)

    %% setup
    addpath(genpath('/om/group/evlab/software/spm12'))
    addpath(genpath('/om/group/evlab/software/spm_ss'))
    addpath /om/group/evlab/software/conn
    conn_module el init
    
    %% specify params
    date = '20250711';
    [parcel_file, loc_tasks, loc_contrasts] = define_network_params(network);
    
    main_tasks = {
        'langloc_DiffTasks_1', ...
        'langloc_DiffTasks_2', ...
        'langloc_DiffTasks_3', ...
        'langloc_DiffTasks_4', ...
        'langloc_DiffTasks_5', ...
        'langloc_DiffTasks_6', ...
        'spatialFIN'};
    main_contrasts_all = {
        {'S', 'N'}, ...
        {'S', 'N'}, ...
        {'S', 'N'}, ...
        {'S', 'N'}, ...
        {'S', 'N'}, ...
        {'S', 'N'}, ...
        {'H', 'E'}};
    main_task = main_tasks{main_task_index};
    main_contrasts = main_contrasts_all{main_task_index};
    
    %% get SPM files for all relevant participants
    data_dir = "/mindhive/evlab/u/Shared/SUBJECTS";
    
    session_file = '/home/ruiminga/DiffTasks/behavioral_analysis_2025/qc/sessions4toolbox.csv';
    session_info = readtable(session_file);

    for i=1:length(loc_tasks)
        loc_task = loc_tasks{i};
    
        % define SPM paths
        session_info_thisanalysis = get_sessions(session_info, loc_task, main_task);
        if height(session_info_thisanalysis)==0
            continue
        end
    
        subject_info_loc = [rowfun(@(x) sprintf("%03d", x), session_info_thisanalysis(:,"UID")),...
            session_info_thisanalysis(:,loc_task)];
        subjects_loc = rowfun(@(uid, session) make_spm_paths(data_dir, loc_task, uid, session),... 
            subject_info_loc, "OutputVariableNames", "SPMpath");
        spmfiles_loc = cellstr(subjects_loc.SPMpath');
    
        subject_info_main = [rowfun(@(x) sprintf("%03d", x), session_info_thisanalysis(:,"UID")),...
            session_info_thisanalysis(:,main_task)];
        subjects_main = rowfun(@(uid, session) make_spm_paths(data_dir, main_task, uid, session),... 
            subject_info_main, "OutputVariableNames", "SPMpath");
        spmfiles_main = cellstr(subjects_main.SPMpath');

        output_pth = ['/nese/mit/group/evlab/u/ruiminga/DiffTasks/mROI_' network '/' loc_task '_' main_task '_' date];
        
        % run the analysis
        ss=struct(...
                'swd', output_pth,...
                'EffectOfInterest_spm',{spmfiles_main},... 
                'Localizer_spm', {spmfiles_loc},...
                'EffectOfInterest_contrasts',{main_contrasts},...   
                'Localizer_contrasts',{loc_contrasts},...        
                'Localizer_thr_type',{{'percentile-ROI-level'}},...
                'Localizer_thr_p',[.1],... 
                'type','mROI',...
                'ManualROIs', parcel_file,...
                'overwrite', 1, ...
                'model',1,...                                      
                'ExplicitMasking', '', ...
                'estimation','OLS',...
                'ask','none');                                  
        if length(loc_contrasts)>1
            ss.Localizer_conjunction_type = 'max';
        end
    
        ss=spm_ss_design(ss);                                     
        ss=spm_ss_estimate(ss);
    end
    end
    
    
    %% SUPPORTING FUNCTIONS
    function [parcel_file, loc_tasks, loc_contrasts] = define_network_params(network)
    if strcmp(network, 'language')
        parcel_filepath = '/mindhive/evlab/u/Shared/ROIS_Nov2020/Func_Lang_LHRH_SN220';
        parcel_file = fullfile(parcel_filepath, 'allParcels_language.nii');  
        loc_tasks = {'langloc_DiffTasks_1', 'langloc_DiffTasks_2', 'langloc_DiffTasks_3', 'langloc_DiffTasks_4', 'langloc_DiffTasks_5', 'langloc_DiffTasks_6'};
        loc_contrasts = {'S-N'};
    elseif strcmp(network, 'MD') 
        parcel_filepath = '/mindhive/evlab/u/Shared/ROIS_Nov2020/Func_MD_LHRH_HE197';
        parcel_file = fullfile(parcel_filepath, 'MDfuncparcels_Apr2017.img');  
        loc_tasks = {'spatialFIN'};
        loc_contrasts = {'H-E'};
    elseif strcmp(network, 'DMN')
        parcel_filepath = '/mindhive/evlab/u/Shared/ROIS_Nov2020/Func_DMN_LHRH_EH197';
        parcel_file = fullfile(parcel_filepath, 'allParcels_DMN.img');
        loc_tasks = {'spatialFIN'};
        loc_contrasts = {'E-H'};
    else
        error('No such network: %s', network)
    end
    end
    
    
    function [spm_path] = make_spm_paths(data_dir, expt, uid, session)
    session = strcat(uid, '_', session{:}, '_PL2017');
    spm_path = fullfile(data_dir, session, ['firstlevel_' expt], 'SPM.mat');
    end
    
    
    function [output_table] = get_sessions(input_table, loc_task, main_task)
    output_table = input_table(~strcmp(input_table{:,loc_task}, 'NA'),:);
    output_table = output_table(~strcmp(output_table{:,main_task}, 'NA'),:);
    end

