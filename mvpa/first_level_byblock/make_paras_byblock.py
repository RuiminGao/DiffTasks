# Anna Ivanova, Jan 2021

# Changes standard langloc para files (2 conditions, S and N)
# to para files with block-specific estimates

import os

para_dir_read = '/mindhive/evlab/u/Shared/PARAS/langloc_DiffTasks'
para_dir_write = '/mindhive/evlab/u/Shared/PARAS/langloc_DiffTasks_byblock'

filenames = os.listdir(para_dir_read)

for fname in filenames:
    with open(os.path.join(para_dir_read,fname)) as f:
        para = f.read()
    para = para.replace("\n \n", "\n\n").split("\n\n")
    #print(para)

    output = ""
    names = ""

    # update onsets
    countS = 1
    countN = 1
    count = 1
    onsets = [l.rstrip() for l in para[0].split("\n")]
    for line in onsets:
        if line.startswith('#'):
            output += (line + "\n")
            continue
        num = ' ' + str(count)
        if line.endswith('1'):
            output += line.replace(' 1', num)
            names += ('S_'+ str(countS) + ' ')
            countS+=1
        else:
            output += line.replace(' 2', num)
            names += ('N_' + str(countN) + ' ')
            countN+=1
        output+="\n"
        count+=1
   
    # update names
    output+= "\n#names\n"
    output+= names
    output+="\n\n"

    # update durations
    #print(para[2])
    [_, dur] = para[2].rstrip("\n").split("\n")
    dur = dur.rstrip()
    dur_new = (dur + ' ') * (countS-1)
    output+= "#durations\n"
    output+= dur_new
 
    with open(os.path.join(para_dir_write,fname), 'w') as f:
        f.write(output)
    
