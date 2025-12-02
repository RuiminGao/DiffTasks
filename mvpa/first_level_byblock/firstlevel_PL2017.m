%created 6/2/17 by msieg
%
%E.G. firstlevel_PL2017('408_FED_20160617a_3T2','langlocSN')


function firstlevel_PL2017(varargin)

subject = char(varargin(1));
expt = char(varargin(2));

% addpath('/om/group/evlab/software/evlab17') 
evlab17 init

%Get contrasts 
cd /mindhive/evlab/u/Shared/ANALYSIS
fid = fopen('contrasts_by_expt.txt');
cons = textscan(fid, '%s', 'Delimiter', '\n'); 
cons = cons{:};
f_expt = strmatch(expt,cons);
expt_cons = cons(f_expt(1)+1:f_expt(2)-1);

%If npmod
if length(varargin) > 2 & strmatch(varargin(3),'npmod');
    num_events = cell2mat(varargin(4));
    len_con = length(expt_cons);
    for i = 1:len_con;
        for j = 1:num_events;
            %modcon
            spl_con = strsplit(char(expt_cons(i)));
            con = char(spl_con(1));
            spl_con(1) = {[char(spl_con(1)) '_' sprintf('%02d',j)]};
            f_mod = find(mod(1:length(spl_con),2)==0);
            for k = 1:length(f_mod);
                spl_con(f_mod(k)) = {[char(spl_con(f_mod(k))) '_EVENT' sprintf('%02d',j)]};
            end;
            join_con = strjoin(spl_con);
            mod_cons(j+num_events*(i-1),1) = {join_con};
            
            %expt_con1
            expt_cons1(i,1) = {con};
            expt_cons1(i,j+1) = {strjoin(spl_con(2:end))};    
        end;       
        expt_cons2(i,1) = {strjoin(expt_cons1(i,:))};        
    end;   
    expt_cons=[expt_cons2; mod_cons];    
end;


    

%Get cat file name
cd(['/mindhive/evlab/u/Shared/SUBJECTS/' subject])
cat_file = ls(['*' expt '.cat']);

%Get preprocessing .mat output name
cd nii
p = pwd;
pp_files = dir([p '/evlab*mat']);
pp_files = {pp_files.name};
pp_file = char(pp_files(end));

cd ..

%Open and write modelfiles*.cfg
header1 = '#dataset';
space = ' ';
header2 = '#design';
header3 = '#model_name';
header4 = '#contrasts';
fid=fopen(strcat('modelfiles_',expt,'.cfg'),'w');

fprintf(fid, [ header1 '\n']);
fprintf(fid, ['/mindhive/evlab/u/Shared/SUBJECTS/' subject '/nii/' pp_file]);

fprintf(fid, [ space '\n']);
fprintf(fid, [ space '\n']);
fprintf(fid, [ header2 '\n']);
fprintf(fid, ['/mindhive/evlab/u/Shared/SUBJECTS/' subject '/' cat_file]);

fprintf(fid, [ space '\n']);
fprintf(fid, [ space '\n']);
fprintf(fid, [ header3 '\n']);
fprintf(fid, [expt '\n']);

fprintf(fid, [ space '\n']);
fprintf(fid, [ space '\n']);
fprintf(fid, [ header4]);
for i = 1:length(expt_cons);
fprintf(fid, [ space '\n']);
fprintf(fid, char(expt_cons(i,:)));
end;

fclose(fid);

%changed for om path 20200205 hopekean
%run firstlevel
% cd /om/group/evlab/software/evlab17/
evlab17_run_model(['/mindhive/evlab/u/Shared/SUBJECTS/' subject '/modelfiles_' expt '.cfg'],'pipeline_model_Default.cfg')

% cd /mindhive/evlab/u/Shared/ANALYSIS/

cd /nese/mit/group/evlab/u/ruiminga/DiffTasks/DiffTasks/mvpa_2025
end
