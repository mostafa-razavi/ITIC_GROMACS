#!bin/bash
CD=${PWD}
molec="$1"
nrexcl="$2"
Nproc="$3"
gmx_exe_address="$4"


rm -rf $CD/COMMANDS_excl.parallel

for fol in $CD/I*/*/*; do 
	rm -rf $fol/nvt_excl.*

	cp $fol/nvt_pr.mdp $fol/nvt_excl.mdp; 
	cp $fol/${molec}.top $fol/${molec}_excl.top; 

	# Change the nrexcl to a large number
	nrexcl_line=$(grep -A1 nrexcl $fol/${molec}_excl.top | tail -n1);
	molec_name=$(echo $nrexcl_line | awk '{print $1}'); 
	sed -i "s/$nrexcl_line/$molec_name     $nrexcl/g" $fol/${molec}_excl.top; 

	# Prepare parallel input file
	line="source /usr/local/gromacs/bin/GMXRC; \
	cd $fol; \
	$gmx_exe_address grompp -f nvt_excl.mdp -c nvt_eq.gro -p ${molec}_excl.top -o nvt_excl.tpr; \
	$gmx_exe_address mdrun -rerun nvt_pr.trr -nt 1 -deffnm nvt_excl;"

	echo "$line" >> $CD/COMMANDS_excl.parallel

done

parallel --jobs $Nproc < COMMANDS_excl.parallel

