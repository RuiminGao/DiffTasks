import os
import pandas as pd

# Path to .cat files
sessions_pth = '../../behavioral_analysis_2025/qc/sessions4toolbox.csv'
sessions_info = pd.read_csv(sessions_pth)
cols = [f'langloc_DiffTasks_{i}' for i in range(1, 7)]

sessions = set()
for _, row in sessions_info.iterrows():
    for col in cols:
        col_value = row[col]
        if pd.notna(col_value) and col_value != "NA": 
            sessions.add(f"{row['UID']}_{col_value}_PL2017")

subject_dir = "/mindhive/evlab/u/Shared/SUBJECTS"
new_para_dir = "/mindhive/evlab/u/Shared/PARAS/langloc_DiffTasks_byblock/"


expts = ['langloc_DiffTasks_1', 'langloc_DiffTasks_2','langloc_DiffTasks_3',
    'langloc_DiffTasks_4', 'langloc_DiffTasks_5', 'langloc_DiffTasks_6']

for sub in sessions:
  subdir = f"/mindhive/evlab/u/Shared/SUBJECTS/{sub}"
  for expt in cols:
    if not os.path.exists(f"{subdir}/firstlevel_{expt}"):
      continue

    # check if the expt is present
    if not os.path.exists(f"{subdir}/modelfiles_{expt}_byblock.cfg"):
        print(expt+" not found for " + sub)
        continue

    # read the cat file
    catfile = os.path.join(subject_dir, sub, (sub+'_'+expt+'.cat'))
    try:
        f = open(catfile)
    except:
        try:
            print("Could not open " + catfile)
            print("Trying the version without PL2017")
            catfile2 = os.path.join(subject_dir, sub, (sub.replace("_PL2017", "")+"_"+expt+".cat"))
            f = open(catfile2)
        except:
            try:
                print("Could not open " + catfile2)
                print("Trying the version without subject ID")
                session_ = sub.replace("_PL2017", "")[4:]
                if "2022" in session_:
                    session_ = session_.replace("FED_", "FED")
                    print(session_)
                catfile3 = os.path.join(subject_dir, sub, session_+"_"+expt+".cat")
                f = open(catfile3)
            except: 
                print("Could not open " + catfile3)
                print(f"{sub} {expt} FAILED, continue...")
                continue
   
    with f:
        lines = [line.rstrip() for line in f]
    
    # change the para path
    output = ""
    for line in lines:
        if line.startswith("#path"):
            output+=("#path " + new_para_dir + "\n")
        else:
            output+=(line + "\n")

    catfile_write = os.path.join(subject_dir, sub, (sub+"_"+expt+"_byblock.cat"))
    with open(catfile_write, 'w') as f:
        f.write(output)

