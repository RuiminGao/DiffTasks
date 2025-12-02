import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from nilearn.image import load_img, math_img
import numpy as np
import os
from tqdm import tqdm

def compute_overlap(data, roi, label1, label2=None):
    res = []
    if label2 is None or label1 == label2:
        for i, img1 in enumerate(data[label1]):
            for img2 in data[label1][i+1:]:
                img1_binary = (img1.get_fdata() == roi)
                img2_binary = (img2.get_fdata() == roi)
                dice_score = 2 * (img1_binary & img2_binary).sum() / (img1_binary.sum() + img2_binary.sum())
                res.append(dice_score)
    else:
        for img1 in data[label1]:
            for img2 in data[label2]:
                img1_binary = (img1.get_fdata() == roi)
                img2_binary = (img2.get_fdata() == roi)
                dice_score = 2 * (img1_binary & img2_binary).sum() / (img1_binary.sum() + img2_binary.sum())
                res.append(dice_score)
    return np.mean(res)

session_file = '../behavioral_analysis_2025/qc/sessions4toolbox.csv';
session_info = pd.read_csv(session_file)
subjects = session_info['UID'].astype(str).str.zfill(3).tolist()

data_subjects = {}
for sub in subjects:
    for task in range(1, 7):
        if not os.path.exists(f'Data/{sub}_langloc_DiffTasks_{task}.nii'):
            continue
        data_subjects[f'{sub}_{task}'] = [
            load_img(f'Data/{sub}_langloc_DiffTasks_{task}_1.nii'),
            load_img(f'Data/{sub}_langloc_DiffTasks_{task}_2.nii')
        ]

def compute_all_dc(rois, output_csv, data_subjects):
    dc = []
    for roi in rois:
        for s1_i in tqdm(range(len(subjects)), desc=f"Processing ROIs {rois}"):
            s1 = subjects[s1_i]
            for s2 in subjects[s1_i:]:
                for task1 in range(1, 7):
                    for task2 in range(1, 7):
                        f1 = f'Data/{s1}_langloc_DiffTasks_{task1}.nii'
                        f2 = f'Data/{s2}_langloc_DiffTasks_{task2}.nii'
                        if not os.path.exists(f1) or not os.path.exists(f2):
                            continue
                        dc.append([
                            roi, s1, s2, task1, task2,
                            compute_overlap(data_subjects, roi, f'{s1}_{task1}', f'{s2}_{task2}')
                        ])
    dc = pd.DataFrame(dc, columns=['ROI', 'Subject1', 'Subject2', 'Task1', 'Task2', 'DC'])
    dc['Task1'] = 'V' + dc['Task1'].astype(str)
    dc['Task2'] = 'V' + dc['Task2'].astype(str)
    dc['Subject_Type'] = dc['Subject1'] != dc['Subject2']
    dc['Subject_Type'] = dc['Subject_Type'].map({True: 'Between-subject', False: 'Within-subject'})
    dc['Task_Type'] = dc['Task1'] != dc['Task2']
    dc['Task_Type'] = dc['Task_Type'].map({True: 'Different-task', False: 'Same-task'})
    dc.to_csv(output_csv, index=False)

compute_all_dc([1,2,3,4,5], 'Data/all_data_LH.csv', data_subjects)
compute_all_dc([7,8,9,10,11], 'Data/all_data_RH.csv', data_subjects)
