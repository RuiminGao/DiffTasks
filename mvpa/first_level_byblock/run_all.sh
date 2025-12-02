#!/bin/bash
#SBATCH -t 01:00:00
#SBATCH --mem=8GB
#SBATCH -n 1
#SBATCH -p evlab
#SBATCH --array=0-60
#SBATCH -o Slurm/slurm-%A_%a.out

source /etc/profile.d/modules.sh
module load mit/matlab

# Read subjects using mapfile to preserve lines
mapfile -t subjects < <(
  awk -F, 'NR > 1 {
    for (i=2; i<=7; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", $i)  # trim whitespace
      if ($i != "" && $i != "NA") {
        print $1 "_" $i "_PL2017"
      }
    }
  }' ../../behavioral_analysis_2025/qc/sessions4toolbox.csv | sort -u
)


# Strip any leading/trailing whitespace or weird characters
sub=$(echo "${subjects[$SLURM_ARRAY_TASK_ID]}" | tr -d '\r' | xargs)

# Echo for debugging
echo "subject: '$sub'"

# Safe MATLAB call
matlab -nodisplay -r "try, firstlevel_byblock('${sub}'); catch ME, disp(getReport(ME)); exit(1); end; exit;"

