# Return a counterexample trace (or all traces) for two states <sa, sb> in
# given LTS if there are connected with a tau transition and not 1-trace equivalent

import os, sys, re
from collections import defaultdict
from pprint import pprint 

def process_file(file):
    trans = defaultdict(dict)
    with open(file, 'rt') as f:
        lines = (line.strip() for line in f)
        pat = re.compile(r'(\d+), (.*), (\d+)')
        
        for line in lines:
            m = pat.search(line)
            if m:
                pre, act, suc = m.group(1), m.group(2), m.group(3)
                trans[pre][suc] = act 
        return trans


def     

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit("Forget to specify files")
    else:
        process_file(sys.argv[1])

