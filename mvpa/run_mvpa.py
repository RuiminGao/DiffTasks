import os
import sys
import pickle
import numpy as np
import pandas as pd
from datetime import datetime
from scipy.stats import pearsonr
import mvpa2.suite as mvpa
from sklearn.linear_model import LogisticRegression
from mvpa2.clfs.skl.base import SKLLearnerAdapter
from mvpa2.datasets import dataset_wizard
from tqdm import tqdm

# Global configs
data_dir = '/nese/mit/group/evlab/u/ruiminga/DiffTasks/mvpa_2025/'
data_date = '20251029'
K = 5
classifiers = ['kNN', 'sklearn_logistic_reg', 'SVM', 'Correlation']

def get_subjects(system):
    info = pd.read_csv('../behavioral_analysis_2025/qc/sessions4toolbox.csv')
    info['UID'] = info['UID'].astype(str)
    required = ["langloc_DiffTasks_1", "langloc_DiffTasks_2", "langloc_DiffTasks_3", "langloc_DiffTasks_4", "spatialFIN"]
    return info.dropna(subset=required)['UID'].values

def load_data(system, normalize='none'):
    try:
        ds = mvpa.h5load(os.path.join(data_dir, system, 'byblock_level_estimates_SPMmat_{}.hdf5'.format(data_date)))
    except:
        try:
            with open(os.path.join(data_dir, system, 'byblock_level_estimates_SPMmat_{}.pckl'.format(data_date)), 'rb') as f:
                ds = pickle.load(f)
        except:
            sys.exit("Cannot load data. Please run 'prepare_dataset.py'")
    ds.samples[np.isnan(ds.samples)] = 0
    if normalize == 'run':
        ds.sa['subj_run_task'] = ["{}_{}_{}".format(subj, sess, task)
                                  for subj, sess, task in zip(ds.sa['subject'], ds.sa['session'], ds.sa['task'])]
        mvpa.zscore(ds, chunks_attr='subj_run_task')
    elif normalize == 'pattern':
        ds.samples -= np.mean(ds.samples, axis=1, keepdims=True)
        ds.samples /= np.std(ds.samples, axis=1, keepdims=True)
        
    return ds

def get_data(subjects, tasks, conditions):
    return ds[{'subject': subjects, 'task': tasks, 'condition': conditions}]

def split_data(data, train, test):
    data.sa['runtype'] = [
        'train' if (t, c, s, b) in train else 'test' if (t, c, s, b) in test else ''
        for c, t, s, b in zip(data.sa['condition'], data.sa['task'], data.sa['session'], data.sa['block'])
    ]
    return data

def correlation_classifier(data, target):
    train, test = data[data.sa.runtype == 'train'], data[data.sa.runtype == 'test']
    labels = np.unique(data.sa[target])
    avg = {l: train[train.sa.targets == l].samples.mean(axis=0) for l in labels}
    pred, confusion = [], np.zeros((len(labels), len(labels)), int)
    for i, sample in enumerate(test.samples):
        p = max(avg, key=lambda k: pearsonr(sample, avg[k])[0])
        pi, oi = list(labels).index(p), list(labels).index(test.sa.targets[i])
        confusion[pi, oi] += 1
        pred.append(p)
    acc = 1. * np.trace(confusion) / test.shape[0]
    return acc, {'y_true': list(test.sa.targets), 'y_pred': pred}

def classify(data, target, clf_name):
    data.sa['targets'] = data.sa[target]
    if clf_name == 'Correlation':
        return correlation_classifier(data, target)
    if clf_name == 'kNN':
        clf = mvpa.kNN(k=data.shape[0] - 1, voting='majority', dfx=mvpa.one_minus_correlation)
    elif clf_name == 'sklearn_logistic_reg':
        clf = SKLLearnerAdapter(LogisticRegression(max_iter=1e6, solver='liblinear', C=0.001))
    else:
        clf = mvpa.LinearCSVMC()
    train = dataset_wizard(data.samples[data.sa.runtype == 'train'], data.sa.targets[data.sa.runtype == 'train'])
    test = data.samples[data.sa.runtype == 'test']
    clf.train(train)
    pred = clf.predict(test)
    acc = np.mean(pred == data.sa.targets[data.sa.runtype == 'test'])
    return acc, {'y_true': list(data.sa.targets[data.sa.runtype == 'test']), 'y_pred': pred}

def perform_mvpa(data, label):
    acc, stats = {}, {}
    for clf in classifiers:
        a, s = classify(data, label, clf)
        acc[clf], stats[clf] = a, s
    return acc, stats

def run_mvpa_classification(subjects, label, generalize_across, output_dir, output_file_name):
    acc_df, stat_df = [], []
    label_values = ['V1', 'V2', 'V3'] if label == 'condition' else ['S', 'N']
    total = [(s, i) for s in ['SESSION01', 'SESSION02'] for i in range(1, 9)]
    for subj in tqdm(subjects):
        for lv in label_values:
            others = [x for x in label_values if x != lv]
            for k in range(K):
                d = get_data([subj], ['V1', 'V2', 'V3'], ['S', 'N'])
                if generalize_across:
                    if label == 'condition':
                        train = [(t, c, s, i) for t in others for c in ['S','N'] for ii, (s, i) in enumerate(total) if ii % K != k]
                        test  = [(lv, c, s, i) for c in ['S','N'] for ii, (s, i) in enumerate(total) if ii % K == k]
                    else:
                        train = [(t, c, s, i) for t in ['V1','V2','V3'] for c in others for ii, (s, i) in enumerate(total) if ii % K != k]
                        test  = [(t, lv, s, i) for t in ['V1','V2','V3'] for ii, (s, i) in enumerate(total) if ii % K == k]
                else:
                    if label == 'condition':
                        train = [(lv, c, s, i) for c in ['S','N'] for ii, (s, i) in enumerate(total) if ii % K != k]
                        test  = [(lv, c, s, i) for c in ['S','N'] for ii, (s, i) in enumerate(total) if ii % K == k]
                    else:
                        train = [(t, lv, s, i) for ii, (s, i) in enumerate(total) if ii % K != k for t in ['V1','V2','V3']]
                        test  = [(t, lv, s, i) for ii, (s, i) in enumerate(total) if ii % K == k for t in ['V1','V2','V3']]
                d = split_data(d, train, test)
                acc, stat = perform_mvpa(d, label)
                for clf in classifiers:
                    acc_df.append([subj, lv, k, clf, acc[clf]])
                    stat_df.append([subj, lv, k, clf, list(stat[clf]['y_true']), list(stat[clf]['y_pred'])])

    pd.DataFrame(acc_df, columns=['Subject', 'TestGroup', 'Split', 'Classifier', 'Accuracy']).to_csv(
        os.path.join(output_dir, output_file_name), index=False)
    pd.DataFrame(stat_df, columns=['Subject', 'TestGroup', 'Split', 'Classifier', 'Y_True', 'Y_Pred']).to_csv(
        os.path.join(output_dir, output_file_name.replace('.csv', '_details.csv')), index=False)

if __name__ == '__main__':
    if not os.path.exists('Data'):
        os.makedirs('Data')
    dir_path = 'Data'
    for normalize in ['pattern']:
        for SYSTEM in ['Lang_RH']:
            ds = load_data(SYSTEM, normalize=normalize)
            subjects = get_subjects(SYSTEM)

            run_mvpa_classification(subjects, label='condition', generalize_across=True,
                output_dir=dir_path,
                output_file_name='mvpa_{}_conditions_cross_{}.csv'.format(SYSTEM, normalize))

            run_mvpa_classification(subjects, label='task', generalize_across=True,
                output_dir=dir_path,
                output_file_name='mvpa_{}_tasks_cross_{}.csv'.format(SYSTEM, normalize))

            run_mvpa_classification(subjects, label='condition', generalize_across=False,
                output_dir=dir_path,
                output_file_name='mvpa_{}_conditions_same_{}.csv'.format(SYSTEM, normalize))

            run_mvpa_classification(subjects, label='task', generalize_across=False,
                output_dir=dir_path,
                output_file_name='mvpa_{}_tasks_same_{}.csv'.format(SYSTEM, normalize))
