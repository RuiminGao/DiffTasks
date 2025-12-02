
filename = 'spm_ss_mROI_data.csv';
date = '20250711';
rootpath = '/nese/mit/group/evlab/u/ruiminga/DiffTasks';
basename = 'mROI_';
output_dir = '/home/ruiminga/DiffTasks/effect_estimation_2025/Data';
if ~exist(output_dir, 'dir')
    mkdir(output_dir)
end

networks = {'language', 'MD', 'DMN'};
network_loc_tasks = {{'langloc_DiffTasks_1', 'langloc_DiffTasks_2', 'langloc_DiffTasks_3', 'langloc_DiffTasks_4', 'langloc_DiffTasks_5', 'langloc_DiffTasks_6'},...
    {'spatialFIN'}, {'spatialFIN'}};
main_tasks = {'langloc_DiffTasks_1', 'langloc_DiffTasks_2', ...
    'langloc_DiffTasks_3', 'langloc_DiffTasks_4', 'langloc_DiffTasks_5',...
    'langloc_DiffTasks_6', 'spatialFIN'};

for i=1:length(networks)
    network = networks{i};
    loc_tasks = network_loc_tasks{i};
    for j=1:length(loc_tasks)
        loc_task = loc_tasks{j};
        for k=1:length(main_tasks)
            main_task = main_tasks{k};
            target_dir = fullfile(rootpath, [basename network], [loc_task '_' main_task '_' date]);
            if exist(target_dir, 'dir')
                copyfile(fullfile(target_dir,  filename),...
                 fullfile(output_dir, [network '_' loc_task '_' main_task '.csv']));
            end
        end
    end
end
