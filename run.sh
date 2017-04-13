

echo -e "Extract sub-LTS\n" 
time perl extract_sublts.pl input/msqueue23.aut

# echo -e "\nComplete graph by adding '(init_state, trans_num, state_num)'"
time perl produce_lts.pl output/sublts.dat
