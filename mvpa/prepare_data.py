# Prepares MVPA data, stores in HDF5 and Pickle format
import os
import sys
import pickle
import h5py
import numpy as np
import pandas as pd
import scipy.io as sio
from datetime import datetime
from tqdm import tqdm
from nilearn.image import load_img, math_img
import mvpa2.suite as mvpa

save_pth = '/nese/mit/group/evlab/u/ruiminga/DiffTasks/mvpa_2025/'
if not os.path.exists(save_pth):
    os.makedirs(save_pth)
QUICK_CHECK = False

def get_mask(subj, session, task):
    sid = '{}_{}_PL2017'.format(subj, session)
    if SYSTEM == 'Lang':
        mask = '/mindhive/evlab/u/Shared/SUBJECTS/{}/firstlevel_langloc_DiffTasks_4/locT_0003_percentile-ROI-lev1534d2f6481735600ae7d49107198726_f2f281a0bb9ffa54f781c09b52273cdf.ROIs.nii'.format(sid)
        mask = math_img('(img < 6) & (img != 0)', img=load_img(mask))
    if SYSTEM == 'Lang_RH':
        mask = '/mindhive/evlab/u/Shared/SUBJECTS/{}/firstlevel_langloc_DiffTasks_4/locT_0003_percentile-ROI-lev1534d2f6481735600ae7d49107198726_f2f281a0bb9ffa54f781c09b52273cdf.ROIs.nii'.format(sid)
        mask = math_img('(img > 6) & (img < 12)', img=load_img(mask))
    elif SYSTEM == 'MD':
        mask = '/mindhive/evlab/u/Shared/SUBJECTS/{}/firstlevel_spatialFIN/locT_0003_percentile-ROI-lev85603954b0894e68c746d625a847e070.nii'.format(sid)
    else:  # DMN
        mask = '/mindhive/evlab/u/Shared/SUBJECTS/{}/firstlevel_spatialFIN/locT_0004_percentile-ROI-lev268c303b50c8d0776e48df0425d14a0d.nii'.format(sid)
    return mask

def get_contrast_filename(names, event, spm_path):
    idx = str(names.index(event) + 1).zfill(4)
    return spm_path[:-7] + 'con_{}.nii'.format(idx)

def read_mat_file(path):
    try:
        with h5py.File(path, 'r') as f:
            names = [''.join(chr(v[0]) for v in f[f['SPM/xCon/name'][i][0]].value)
                     for i in range(f['SPM/xCon/name'].shape[0])]
        return names
    except:
        try:
            mat = sio.loadmat(path, simplify_cells=True)
            return [c['name'] for c in mat['SPM']['xCon']]
        except:
            print("{} could not be read.".format(path))
            sys.exit(1)

def get_subjects(task=''):
    info = pd.read_csv('../behavioral_analysis_2025/qc/sessions4toolbox.csv')
    info['UID'] = info['UID'].astype(str)

    if SYSTEM == 'Lang' or SYSTEM == 'Lang_RH':
        valid = info[['langloc_DiffTasks_1', 'langloc_DiffTasks_2', 'langloc_DiffTasks_3', 'langloc_DiffTasks_4']].notnull().all(axis=1)
        session_col = 'langloc_DiffTasks_4'
    else:
        valid = info[['langloc_DiffTasks_1', 'langloc_DiffTasks_2', 'langloc_DiffTasks_3', 'spatialFIN']].notnull().all(axis=1)
        session_col = 'spatialFIN'

    filtered = info[valid]
    return list(zip(filtered['UID'], filtered['langloc_DiffTasks_{}'.format(task[-1])], filtered[session_col]))

def get_data(events, output, datatype):
    datasets = []
    for task in ['V1', 'V2', 'V3']:
        print('\nTASK: {}'.format(task))
        for subj, task_session, session in tqdm(get_subjects(task=task)):
            mask = get_mask(subj, session, task)
            spm_path = '/mindhive/evlab/u/Shared/SUBJECTS/{}_{}_PL2017/firstlevel_langloc_DiffTasks_{}_{}/SPM.mat'.format(
                subj, task_session, task[-1], datatype)

            spm_path = spm_path.replace('__', '_')  # sanitize double underscores if `datatype` is empty
            contrast_names = read_mat_file(spm_path)

            for event in events:
                if event not in contrast_names:
                    continue
                condition = event[-3]
                run = event[:9]
                block = int(event.split('_')[-1])
                contrast_file = get_contrast_filename(contrast_names, event, spm_path)

                if QUICK_CHECK:
                    assert os.path.exists(mask), 'Missing: {}'.format(mask)
                    assert os.path.exists(contrast_file), 'Missing: {}'.format(contrast_file)
                else:
                    ds = mvpa.fmri_dataset(samples=contrast_file, mask=mask)
                    ds.sa.update({'task': [task], 'condition': [condition], 'subject': [subj],
                                  'session': [run], 'block': [block]})
                    datasets.append(ds)

    if not QUICK_CHECK:
        fds = mvpa.vstack(datasets)
        output += '_20251029'
        out_dir = os.path.join(save_pth, SYSTEM)
        if not os.path.exists(out_dir):
            os.makedirs(out_dir)

        fds.save(os.path.join(out_dir, output + '.hdf5'))
        with open(os.path.join(out_dir, output + '.pckl'), 'wb') as f:
            pickle.dump(fds, f)

for SYSTEM in ['Lang_RH']:
    print('\nSYSTEM: {}'.format(SYSTEM))
    events = ['SESSION0{}_{}_{}'.format(run, c, b) for run in range(1, 3)
              for b in range(1, 9) for c in ['S', 'N']]
    get_data(events, output='byblock_level_estimates_SPMmat', datatype='byblock')
