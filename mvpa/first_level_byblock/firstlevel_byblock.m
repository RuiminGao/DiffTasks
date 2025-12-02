function [] = firstlevel_byblock(sub)

addpath /om/group/evlab/software/conn
conn_module el init

disp(['Running firstlevel_byblock for ' sub])

expts = {'langloc_DiffTasks_1', 'langloc_DiffTasks_2', 'langloc_DiffTasks_3', ...
    'langloc_DiffTasks_4', 'langloc_DiffTasks_5'};

for ex = 1:length(expts)
    expt = [expts{ex} '_byblock'];
    cat_file = fullfile('/mindhive/evlab/u/Shared/SUBJECTS', sub, [sub '_' expt '.cat']);
    firstlevel_dir = fullfile('/mindhive/evlab/u/Shared/SUBJECTS', sub, ['firstlevel_' expt]);

    % Check if firstlevel directory exists
    if isfolder(firstlevel_dir)
        disp(['Skipping ' expt ' for subject ' sub ': firstlevel directory already exists.'])
        continue
    end

    % Test if cat file exists
    if ~isfile(cat_file)
        disp(['No cat file found for ' expt])
        continue
    end

    % Run first level analysis if conditions are met
    firstlevel_PL2017(sub, expt);
end
