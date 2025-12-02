
filename = 'spm_bcc_data.EffectSize.csv';
date = '20250711';
rootpath = '/nese/mit/group/evlab/u/ruiminga/DiffTasks/spcorr_DiffTasks';
basename = 'spcorr_';
output_dir = '/home/ruiminga/DiffTasks/spatial_correlation_2025/Data';
if ~exist(output_dir, 'dir')
    mkdir(output_dir)
end

restoredefaultpath; rehash toolboxcache

session_file = '/home/ruiminga/DiffTasks/behavioral_analysis_2025/qc/sessions4toolbox.csv';
session_info = readtable(session_file);

networks = {'language', 'MD', 'DMN'};
network_loc_tasks = {...
    {'langloc_DiffTasks_1', 'langloc_DiffTasks_2', 'langloc_DiffTasks_3', 'langloc_DiffTasks_4', 'langloc_DiffTasks_5', 'langloc_DiffTasks_6'},...
    {'spatialFIN'}, {'spatialFIN'}};
tasks = {'langloc_DiffTasks_1', 'langloc_DiffTasks_2', ...
    'langloc_DiffTasks_3', 'langloc_DiffTasks_4', 'langloc_DiffTasks_5',...
    'langloc_DiffTasks_6'};
labels = {'1', '2', 'All'};

for i=1:length(networks) % Network: language, MD, DMN
    network = networks{i};
    loc_tasks = network_loc_tasks{i};
    for j=1:length(loc_tasks) % Localizer task: langloc_DiffTasks_1, langloc_DiffTasks_2, ...
        loc_task = loc_tasks{j};
        for k=1:length(tasks) % Effect 1 task
            task1 = tasks{k};
            for m = 1:length(tasks) % Effect 2 task
                task2 = tasks{m};
                for n = 1:length(labels) % Label: 1, 2, All
                    label = labels{n};
                    target_dir = fullfile(rootpath, [basename network '_' loc_task '_' task1 '_' task2 '_' label '_' date]);
                    if exist(target_dir, 'dir')
                        session_info_thisanalysis = get_sessions(session_info, loc_task, task1, task2);
                        if height(session_info_thisanalysis) ~= 0
                            tbl = readtable(fullfile(target_dir,  filename));
                            for i = 1:height(tbl)
                                subjectIndex = tbl.Subject(i);
                                tbl.Subject(i) = session_info_thisanalysis.UID(subjectIndex);
                            end
                            output_pth = fullfile(output_dir, [network '_' loc_task '_' task1 '_' task2 '_' label '.csv']);
                            writetable(tbl, output_pth);
                        end
                    end
                end
            end
        end
    end
end

function [output_table] = get_sessions(input_table, loc_task, task1, task2)
    output_table = input_table(~strcmp(input_table{:,loc_task}, 'NA'),:);
    output_table = output_table(~strcmp(output_table{:,task1}, 'NA'),:);
    output_table = output_table(~strcmp(output_table{:,task2}, 'NA'),:);
end