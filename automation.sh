#!/bin/bash

echo -e "\n:... extracting sub LTS from big LTS"
if [ ! -f "output/msbig21.aut" ]; then 
    perl extract_sub_lts.pl input/invis_MS_23_big.aut > output/msbig21.aut
fi

echo ":... add des information"
perl produce_lts.pl output/msbig21.aut 
mv output/msbig21.aut_lts.aut output/msbig21.aut

echo ":... converting graph to BCG format"
bcg_io output/msbig21.aut output/msbig21.bcg

echo ":... do branching bisimulation"
bcg_min -branching -class output/class21.txt output/msbig21.bcg output/msqo21.bcg

echo ":... info about quotient graph"
bcg_info output/msqo21.bcg

echo ":... converting graph to AUT format"
bcg_io output/msqo21.bcg output/msqo21.aut

echo ":...  check information about big AUT"
#perl lts_info.pl output/msbig21.aut

# add ms class 
for i in 1025 1103 444 672 748 817 967 
do 
    echo -ne $i " : "
    cat output/class21.txt | grep -w $i | cut -d '=' -f 1
    equiv=$( cat output/msclass23.txt | grep -w $i | cut -d '=' -f 1 )
    echo $equiv 
done 

echo ":...done" 
