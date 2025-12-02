import os
import random
from pathlib import Path
from tqdm import tqdm

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
import seaborn as sns

from sklearn.decomposition import PCA
from nilearn.image import load_img, math_img
import mvpa2.suite as mvpa

# --- Configuration dicts ---------------------------------------------------

SYSTEM_CONFIG = {
    "Lang": {
        "data_date": "20250711",
        "hdf5_dir": "firstlevel_langloc_DiffTasks_4",
        "mask_name": (
            "locT_0003_percentile-ROI-lev1534d2f6481735600ae7d49107198726_"
            "f2f281a0bb9ffa54f781c09b52273cdf.ROIs.nii"
        ),
        "tmap_fname": "spmT_0003.nii"
    },
    "MD": {
        "data_date": "20250711",
        "hdf5_dir": "firstlevel_spatialFIN",
        "mask_name": "locT_0003_percentile-ROI-lev85603954b0894e68c746d625a847e070.nii",
        "tmap_fname": "spmT_0003.nii"
    }
}

COLOR_MAPS = {
    2: mcolors.ListedColormap(["#ff13f0", "#ffbd00"]),  # condition S, N
    3: mcolors.ListedColormap(["#606060", "#0000ff", "#00aaff"])  # tasks V1, V2, V3
}

def get_subjects_sessions(system):
    df = pd.read_csv('../behavioral_analysis_2025/qc/sessions4toolbox.csv', dtype={"UID": str})
    key = "langloc_DiffTasks_4" if system == "Lang" else "spatialFIN"
    cols = ["langloc_DiffTasks_1", "langloc_DiffTasks_2", "langloc_DiffTasks_3", "langloc_DiffTasks_4", "spatialFIN"]
    df = df.dropna(subset=cols)
    return df["UID"].tolist(), df[key].tolist()

def load_and_preprocess(system, normalize='none'):
    cfg = SYSTEM_CONFIG[system]
    h5path = (
        "/nese/mit/group/evlab/u/ruiminga/DiffTasks/"
        "mvpa_2025/{}/byblock_level_estimates_SPMmat_{}.hdf5"
        .format(system, cfg["data_date"])
    )
    ds = mvpa.h5load(h5path)
    ds.samples[np.isnan(ds.samples)] = 0
    if normalize == 'run':
        ds.sa['run_id'] = [
            "{}_{}_{}".format(subj, ses, task)
            for subj, ses, task in zip(ds.sa.subject, ds.sa.session, ds.sa.task)
        ]
        mvpa.zscore(ds, chunks_attr='run_id')
    elif normalize == 'pattern':
        ds.samples -= np.mean(ds.samples, axis=1, keepdims=True)
        ds.samples /= np.std(ds.samples, axis=1, keepdims=True)
        print("Max mean after normalization (should be ~0):", np.max(np.abs(np.mean(ds.samples, axis=1))))
    return ds

def load_roi_and_tmaps(system, subject, session):
    cfg = SYSTEM_CONFIG[system]
    base = Path(
        "/mindhive/evlab/u/Shared/SUBJECTS/{}_{}_PL2017".format(subject, session)
    ) / cfg["hdf5_dir"]
    # mask
    mask_img = load_img(str(base / cfg["mask_name"]))
    mask = math_img("(img < 6) & (img != 0)", img=mask_img) if system == "Lang" else mask_img
    # ROI and T datasets
    roi_ds = mvpa.fmri_dataset(str(base / cfg["mask_name"]), mask=mask).samples
    t_ds   = mvpa.fmri_dataset(str(base / cfg["tmap_fname"]), mask=mask).samples
    return roi_ds, t_ds

def plot_effect(system, ax, 
             legend=False, normalize='none'):
    ds = load_and_preprocess(system, normalize=normalize)
    # barplot: y=mean activation, x=task, hue=condition
    data = pd.DataFrame({
        'subject': ds.sa['subject'],
        'task': ds.sa['task'],
        'condition': ds.sa['condition'],
        'mean_activation': np.mean(ds.samples, axis=1)
    })
    data = data.groupby(['task', 'condition', 'subject']).mean().reset_index()
    sns.barplot(data=data, x='task', y='mean_activation', hue='condition', ax=ax, palette=["#ff13f0", "#ffbd00"], hue_order=['S','N'], order=['V1', 'V2', 'V3'])
    #sns.stripplot(data=data, x='task', y='mean_activation', hue='condition',
    #              ax=ax, dodge=True, alpha=0.5, jitter=True, color='black')
    if not legend:
        ax.legend_.remove()

if __name__ == "__main__":
    # switch to non-interactive backend
    plt.switch_backend('Agg')
    for normalize in ['none', 'run', 'pattern']:
        for system in ['Lang', 'MD']:
            fig, ax = plt.subplots(figsize=(2, 3), dpi=300, tight_layout=True)
            plot_effect(system, ax, legend=False, normalize=normalize)
            plt.ylim(-1, 2.5)
            plt.xlabel('')
            plt.ylabel('Effect size')
            out_pth = "Figures/effect_{}_{}.png".format(system, normalize)
            fig.savefig(out_pth, transparent=True)
            plt.close(fig)

