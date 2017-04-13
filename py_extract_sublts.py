#!/usr/bin/python
# Created by Gaoang@i, 01_21_2016 

import os, sys, re
from json import dumps 

def update_global_trans(): 
    """Processing the input file, and store the transitions into global_trans"""

    if len(sys.argv) < 2:
        print 'No file was specified'
        sys.exit() 

    global_trans = {} # store transitions 
    with open(sys.argv[1]) as fh:
        line = "open file: " + sys.argv[1] 
        while line:
            if re.match(r'des', line): 
                line = fh.readline().replace('"', '').strip() 
                continue 

            m = re.search(r"(\d+), (.*), (\d+)", line)

            if m is not None: 
                (pre, act, suc) = m.group(1,2,3) 
                trans = {suc : act}
                if pre in global_trans:
                    global_trans[pre].update(trans)
                else:
                    global_trans[pre] = trans                
            else: 
                print "%-40s  %4s" % (line, " -- not transition")

            line = fh.readline().replace('"', '').strip() 
    return global_trans 

def extract_lts():
    pass 
 

def one_thread_multiple_branch():
    """ whether there exists a state that leads two actions 
    belonging to the same thread  """

    trans = update_global_trans()
    state_branch = {} 

    for pre in sorted(trans.iterkeys(), key = int):
        for suc in sorted(trans[pre].iterkeys(), key = int):
            act = trans[pre][suc] 
            if not re.match(r'call|ret', act, re.I):  # we are only interested in tau trans 
                # print pre + " " + suc + " " + act
                m = re.search(r'\!(\d+)$', act)       # catch thread id 

                if not m:  
                    # tid for CCAS is among the action rather than in the end 
                    m = re.search(r'cons \((\d+),', act, re.I)
                if m: 
                    tid = m.group(1) 
                    if pre in state_branch and tid in state_branch[pre]:
                        state_branch[pre][tid] += 1 
                        if state_branch[pre][tid] > 1: 
                            # with more than 1 branch for the same thread 
                            print pre, suc, act
                    else:
                        tmp_hash = {}.fromkeys([tid], 1) 
                        state_branch[pre] = tmp_hash 
                else: 
                    print act 
                    print 'Regrex failed' 
    # print dumps(state_branch, indent = 2) 
                


if __name__ == '__main__':
    one_thread_multiple_branch() 
    #print dumps(trans, indent=2, sort_keys=True)
    
