import numpy as np
import glob
from surfer import Brain, io
from mayavi import mlab
import matplotlib.pyplot as plt
import os

# Adjusting deprecated numpy types
np.float = float
np.int = int
np.object = object
np.bool = bool

data_folder = 'Data/sample'
figures_folder = '/Users/rgao76/Documents/DiffTasks/overlap_2025/Figures'
data = {}

for f in glob.glob(data_folder + '/surf_lh_*langloc*.nii'):
    # filename: <subjectid>_<task>.nii
    subjectid, task = f.split('/')[-1][8:].split('_', 1)
    task = f"V{task.split('.')[0].split('_')[-1]}"
    subjectid = int(subjectid)
    data[subjectid] = data.get(subjectid, {})
    data[subjectid][task] = io.read_scalar_data(f)

UIDs = [707, 845, 838]

# Define the plotting task order and new names
plot_tasks = ['V1', 'V2', 'V3', 'V6', 'V4', 'V5']
task_labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']

fig, axs = plt.subplots(len(UIDs)+1, 7, figsize=(20, len(UIDs) * 3+0.5), dpi=150, constrained_layout=True,
                        width_ratios=[0.1, 1, 1, 1, 1, 1, 1], height_ratios=[1,3,3,3])
fig.patch.set_facecolor('black')

cortex_color = [(0.7, 0.7, 0.7), (0.8, 0.8, 0.8)]

# Plot each subject
for uid_i, UID in enumerate(UIDs):
    axs[uid_i+1, 0].text(0.5, 0.5, f"P{uid_i+1}", ha='center', va='center', fontsize=32, color='white')
    axs[uid_i+1, 0].axis('off')

    for plot_i, task in enumerate(plot_tasks):
        ax = axs[uid_i+1, plot_i+1]

        if task in data[UID]:
            dat = data[UID][task]
            dat = (np.asarray(dat) != 0).astype(float)

            my_fig = mlab.figure(figure=f"fig_{UID}", bgcolor=(0, 0, 0))
            brain = Brain("cvs_avg35_inMNI152", "lh", "inflated", figure=my_fig, background="black", alpha=1, title=UID, cortex=cortex_color)
            brain.show_view('lateral')
            brain.add_overlay(dat, .01, 5, name=task)
            brain.hide_colorbar()
            img = mlab.screenshot(antialiased=True)
            mlab.close(my_fig)
            ax.imshow(img)
        else:
            ax.text(0.5, 0.5, "N/A", ha='center', va='center', transform=ax.transAxes, fontsize=32, color='gray')

        # Zoom and clean axes
        xlim = ax.get_xlim()
        ylim = ax.get_ylim()
        zoom_factor = 0.1
        ax.set_xlim(xlim[0] + (xlim[1] - xlim[0]) * zoom_factor, xlim[1] - (xlim[1] - xlim[0]) * zoom_factor)
        ax.set_ylim(ylim[0] + (ylim[1] - ylim[0]) * zoom_factor, ylim[1] - (ylim[1] - ylim[0]) * zoom_factor)
        ax.axis('off')

# Header labels
axs[0, 0].axis('off')
for idx, label in enumerate(task_labels):
    ax = axs[0, idx+1]
    ax.text(0.5, 0.5, label, ha='center', va='center', fontsize=32, color='white')
    ax.axis('off')

plt.tight_layout()
plt.savefig(f'{figures_folder}/overlap_sample.png', dpi=150)
