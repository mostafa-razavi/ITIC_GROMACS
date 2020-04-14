#!bin/bash
# This script runs the ITIC simulations in parallel using GROMACS.
# Example:
#	bash ~/Git/ITIC_GROMACS/Scripts/RunITIC_GROMACS_Parallel.sh C5 /home/mostafa/Git/ITIC_GROMACS/Forcefields/trappeua.ff/forcefield.itp LJTC_rc14_2ns_4ns.config "all" gmx no-override yes 9
set -e
CD=${PWD}
source /usr/local/gromacs/bin/GMXRC

molecule=$1										# E.g. C1, C2, C4, C12, etc
force_field_file=$2								# E.g. C2_TraPPE-UA.par (in Forcefileds_path) or /path/to/file/TraPPE-UA.par
config_filename=$3								# A file containing GOMC settings (a list of key value pairs e.g. Potential	FSHIFT\n LRC false)
Trho_rhoT_pairs_array=$4						# "all" or pairs of temperature/density (for IT) and density/temperatures (for IC) that we want to run, e.g. 360.00/0.6220 or 0.6220/95.00
gmx_exe_address=$5								# "gmx"
NmolecOverride=$6								# Nmolec or no-override
should_run=$7									# "yes" or "no" (lower case)

#===== Number of CPU cores to use ===== 
Nproc=$(nproc)
if [ "$8" != "" ]; then Nproc="$8"; fi

#========Paths================
ScriptsDir="$HOME/Git/ITIC_GROMACS/Scripts"
ConfigDir="$HOME/Git/ITIC_GROMACS/Config"
MoleculesDir="$HOME/Git/ITIC_GROMACS/Molecules"
ForcefieldsDir="$HOME/Git/ITIC_GROMACS/Forcefields"

#===== Simulation Parameters =====
config_file="$HOME/Git/ITIC_GROMACS/Config/${config_filename}"

dt=$(grep -R "^dt" $config_file | awk '{print $3}')
nsteps_eq=$(grep -R "nsteps_eq" $config_file | awk '{print $3}')
nsteps_pr=$(grep -R "nsteps_pr" $config_file | awk '{print $3}')
out_freq=$(grep -R "out_freq" $config_file | awk '{print $3}')
vdwtype=$(grep -R "vdwtype" $config_file | awk '{print $3}')
DispCorr=$(grep -R "DispCorr" $config_file | awk '{print $3}')
vdwmodifier=$(grep -R "vdw-modifier" $config_file | awk '{print $3}')
rvdw=$(grep -P "rvdw " $config_file | awk '{print $3}')
rvdwswitch=$(grep -R "rvdw-switch" $config_file | awk '{print $3}')
coulombtype=$(grep -R "coulombtype" $config_file | awk '{print $3}')
rcoulomb=$(grep -R "rcoulomb" $config_file | awk '{print $3}')
rlist=$(grep -R "rlist" $config_file | awk '{print $3}')
genvel_eq=$(grep -R "gen-vel_eq" $config_file | awk '{print $3}')
genvel_pr=$(grep -R "gen-vel_pr" $config_file | awk '{print $3}')
continuation_eq=$(grep -R "continuation_eq" $config_file | awk '{print $3}')
continuation_pr=$(grep -R "continuation_pr" $config_file | awk '{print $3}')
continuation_pr=$(grep -R "continuation_pr" $config_file | awk '{print $3}')
lincsorder=$(grep -R "lincs-order" $config_file | awk '{print $3}')


#===== Generate Files folder =====
if [ -e "$CD/Files" ]; then echo "Files directory exists. Exiting..."; exit; else mkdir $CD/Files; fi

cp $ConfigDir/nvt.mdp $CD/Files/nvt.mdp

sed -i "s/some_dt/$dt/g" $CD/Files/nvt.mdp
sed -i "s/some_out_freq/$out_freq/g" $CD/Files/nvt.mdp
sed -i "s/some_vdwtype/$vdwtype/g" $CD/Files/nvt.mdp
sed -i "s/some_DispCorr/$DispCorr/g" $CD/Files/nvt.mdp
sed -i "s/some_vdwmodifier/$vdwmodifier/g" $CD/Files/nvt.mdp
sed -i "s/some_rvdw/$rvdw/g" $CD/Files/nvt.mdp
sed -i "s/some_rswitch/$rvdwswitch/g" $CD/Files/nvt.mdp
sed -i "s/some_coulombtype/$coulombtype/g" $CD/Files/nvt.mdp
sed -i "s/some_rcoulomb/$rcoulomb/g" $CD/Files/nvt.mdp
sed -i "s/some_rlist/$rlist/g" $CD/Files/nvt.mdp
sed -i "s/some_lincsorder/$lincsorder/g" $CD/Files/nvt.mdp

cp $CD/Files/nvt.mdp $CD/Files/nvt_eq.mdp
cp $CD/Files/nvt.mdp $CD/Files/nvt_pr.mdp

sed -i "s/some_genvel/$genvel_eq/g" $CD/Files/nvt_eq.mdp
sed -i "s/some_nsteps/$nsteps_eq/g" $CD/Files/nvt_eq.mdp
sed -i "s/some_continuation/$continuation_eq/g" $CD/Files/nvt_eq.mdp

sed -i "s/some_genvel/$genvel_pr/g" $CD/Files/nvt_pr.mdp
sed -i "s/some_nsteps/$nsteps_pr/g" $CD/Files/nvt_pr.mdp
sed -i "s/some_continuation/$continuation_pr/g" $CD/Files/nvt_pr.mdp

rm -rf $CD/Files/nvt.mdp

cp $MoleculesDir/${molecule}/${molecule}.itic $CD/Files
cp $MoleculesDir/${molecule}/${molecule}.pdb $CD/Files
cp $MoleculesDir/${molecule}/${molecule}.top $CD/Files
cp $ConfigDir/em_steep.mdp $CD/Files
cp $ConfigDir/em_l-bfgs.mdp $CD/Files

sed -i "s:some_forcefield_itp:$force_field_file:g" $CD/Files/${molecule}.top

#============== Function that returns 1 if the T_rho pair is selected 
isTrhoPairSelected () {
    local iRhoOrT
	path_string="$1"
	T_rho_array="$2"

	T_rho_array=($T_rho_array)

	IFS='/' read -ra IX_Y_Z <<< "$path_string"
	IT_or_IC=${IX_Y_Z[-3]}
	rho_or_T1=${IX_Y_Z[-2]}
	rho_or_T2=${IX_Y_Z[-1]}

	if [ "$IT_or_IC" == "IC" ]; then
		rho=$rho_or_T1
		T=$rho_or_T2
		pair="$rho/$T"
	fi
	if [ "$IT_or_IC" == "IT" ]; then
		rho=$rho_or_T2
		T=$rho_or_T1
		pair="$T/$rho"
	fi

	for iRhoOrT in $(seq 0 $(echo "${#T_rho_array[@]}-1" | bc))	# Loop from 0 to len(rho_array)-1
	do
		if [ "${T_rho_array[iRhoOrT]}" == "$pair" ]; then
			echo "found"
			exit
		fi
	done
}

#========Isochores Settings=================
ITIC_file_name=$(ls $CD/Files/*.itic)

Tic1=$(grep "T_IC1:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Tic1=($Tic1)
Nic1=$(grep "NMOL_IC1:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic1=($Nic1)
   
Tic2=$(grep "T_IC2:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Tic2=($Tic2)
Nic2=$(grep "NMOL_IC2:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic2=($Nic2)

Tic3=$(grep "T_IC3:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Tic3=($Tic3)
Nic3=$(grep "NMOL_IC3:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic3=($Nic3)

Tic4=$(grep "T_IC4:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Tic4=($Tic4)
Nic4=$(grep "NMOL_IC4:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic4=($Nic4)

Tic5=$(grep "T_IC5:" ${ITIC_file_name} | awk '{ $1="";print $0}');  Tic5=($Tic5)
Nic5=$(grep "NMOL_IC5:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic5=($Nic5)

Tic6=$(grep "T_IC6:" ${ITIC_file_name} | awk '{ $1="";print $0}');  Tic6=($Tic6)
Nic6=$(grep "NMOL_IC6:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic6=($Nic6)

Tic7=$(grep "T_IC7:" ${ITIC_file_name} | awk '{ $1="";print $0}');  Tic7=($Tic7)
Nic7=$(grep "NMOL_IC7:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic7=($Nic7)

Tic8=$(grep "T_IC8:" ${ITIC_file_name} | awk '{ $1="";print $0}');  Tic8=($Tic8)
Nic8=$(grep "NMOL_IC8:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic8=($Nic8)

Tic9=$(grep "T_IC9:" ${ITIC_file_name} | awk '{ $1="";print $0}');  Tic9=($Tic9)
Nic9=$(grep "NMOL_IC9:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic9=($Nic9)

Tic10=$(grep "T_IC10:" ${ITIC_file_name} | awk '{ $1="";print $0}');  Tic10=($Tic10)
Nic10=$(grep "NMOL_IC10:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nic10=($Nic10)

rhosIC=$(grep "RHO_IC:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhosIC=($rhosIC)

#========Isotherm Settings==================

rhoIT1=$(grep "RHO_IT1:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT1=($rhoIT1)
Nit1=$(grep "NMOL_IT1:" ${ITIC_file_name} | awk '{ $1="";print $0}') ; Nit1=($Nit1)

rhoIT2=$(grep "RHO_IT2:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT2=($rhoIT2)
Nit2=$(grep "NMOL_IT2:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit2=($Nit2)

rhoIT3=$(grep "RHO_IT3:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT3=($rhoIT3)
Nit3=$(grep "NMOL_IT3:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit3=($Nit3)

rhoIT4=$(grep "RHO_IT4:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT4=($rhoIT4)
Nit4=$(grep "NMOL_IT4:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit4=($Nit4)

rhoIT5=$(grep "RHO_IT5:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT5=($rhoIT5)
Nit5=$(grep "NMOL_IT5:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit5=($Nit5)

rhoIT6=$(grep "RHO_IT6:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT6=($rhoIT6)
Nit6=$(grep "NMOL_IT6:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit6=($Nit6)

rhoIT7=$(grep "RHO_IT7:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT7=($rhoIT7)
Nit7=$(grep "NMOL_IT7:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit7=($Nit7)

rhoIT8=$(grep "RHO_IT8:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT8=($rhoIT8)
Nit8=$(grep "NMOL_IT8:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit8=($Nit8)

rhoIT9=$(grep "RHO_IT9:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT9=($rhoIT9)
Nit9=$(grep "NMOL_IT9:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit9=($Nit9)

rhoIT10=$(grep "RHO_IT10:" ${ITIC_file_name} | awk '{ $1="";print $0}'); rhoIT10=($rhoIT10)
Nit10=$(grep "NMOL_IT10:" ${ITIC_file_name} | awk '{ $1="";print $0}'); Nit10=($Nit10)

TsIT=$(grep "T_IT:" ${ITIC_file_name} | awk '{ $1="";print $0}'); TsIT=($TsIT)
   

#========Simulation Settings================

MW=$(grep "MW:" ${ITIC_file_name} | awk '{ print $2}')

#========Isochores==========================
rm -rf $CD/COMMANDS.parallel

i=0
if [ ! -d "IC" ] ; then mkdir IC/; fi
for rho in "${rhosIC[@]}"
	do
	k=-1
	i=$(($i+1))
	if [ "$i" -eq "1" ]; then Tic="${Tic1[@]}"; Nic="${Nic1[@]}"; fi
	if [ "$i" -eq "2" ]; then Tic="${Tic2[@]}"; Nic="${Nic2[@]}"; fi
	if [ "$i" -eq "3" ]; then Tic="${Tic3[@]}"; Nic="${Nic3[@]}"; fi
	if [ "$i" -eq "4" ]; then Tic="${Tic4[@]}"; Nic="${Nic4[@]}"; fi
	if [ "$i" -eq "5" ]; then Tic="${Tic5[@]}"; Nic="${Nic5[@]}"; fi
	if [ "$i" -eq "6" ]; then Tic="${Tic6[@]}"; Nic="${Nic6[@]}"; fi
	if [ "$i" -eq "7" ]; then Tic="${Tic7[@]}"; Nic="${Nic7[@]}"; fi
	if [ "$i" -eq "8" ]; then Tic="${Tic8[@]}"; Nic="${Nic8[@]}"; fi
	if [ "$i" -eq "9" ]; then Tic="${Tic9[@]}"; Nic="${Nic9[@]}"; fi
	if [ "$i" -eq "10" ]; then Tic="${Tic10[@]}"; Nic="${Nic10[@]}"; fi
	Nic=($Nic)
	for T in ${Tic} 
		do
		k=$(($k+1))

		mkdir -p $CD/IC/${rho}/${T}

		if [ "$NmolecOverride" == "no-override" ]; then 
			N=${Nic[k]}
		else
			N=$NmolecOverride
		fi
		L=$(echo "scale=15; e((1/3)*l($N*$MW/$rho/0.6022140857))*0.1 "   | bc -l)

		cp $CD/Files/${molecule}.pdb $CD/IC/${rho}/${T}
		cp $CD/Files/${molecule}.top $CD/IC/${rho}/${T}
		cp $CD/Files/em_steep.mdp $CD/IC/${rho}/${T}
		cp $CD/Files/em_l-bfgs.mdp $CD/IC/${rho}/${T}
		cp $CD/Files/nvt_eq.mdp $CD/IC/${rho}/${T}
		cp $CD/Files/nvt_pr.mdp $CD/IC/${rho}/${T}

		sed -i -e "s/some_Temperature/$T/g" $CD/IC/${rho}/${T}/nvt_eq.mdp
		sed -i -e "s/some_Temperature/$T/g" $CD/IC/${rho}/${T}/nvt_pr.mdp
		sed -i -e "s/Nmolec/$N/g" $CD/IC/${rho}/${T}/${molecule}.top

		line="source /usr/local/gromacs/bin/GMXRC; \
			cd $CD/IC/${rho}/${T}; \
			$gmx_exe_address insert-molecules -ci ${molecule}.pdb -nmol $N -try 100000 -box $L $L $L -o ${molecule}_box.gro; \
			$gmx_exe_address grompp -f em_steep.mdp -c ${molecule}_box.gro -p ${molecule}.top -o em_steep.tpr; \
			$gmx_exe_address mdrun -nt 1 -deffnm em_steep; \
			$gmx_exe_address grompp -f em_l-bfgs.mdp -c em_steep.gro -p ${molecule}.top -o em_l_bfgs.tpr -maxwarn 1; \
			$gmx_exe_address mdrun -nt 1 -deffnm em_l_bfgs; \
			$gmx_exe_address grompp -f nvt_eq.mdp -c em_l_bfgs.gro -p ${molecule}.top -o nvt_eq.tpr; \
			$gmx_exe_address mdrun -nt 1 -deffnm nvt_eq; \
			$gmx_exe_address grompp -f nvt_pr.mdp -c nvt_eq.gro -p ${molecule}.top -o nvt_pr.tpr; \
			$gmx_exe_address mdrun -nt 1 -deffnm nvt_pr;"

		if [ "$Trho_rhoT_pairs_array" == "all" ]; then
			echo "$line" >> $CD/COMMANDS.parallel
		else
			if [ "$(isTrhoPairSelected "$CD/IC/${rho}/${T}/" "$Trho_rhoT_pairs_array")" == "found" ]; then
				echo "$line" >> $CD/COMMANDS.parallel
			fi
		fi
	done
done

#========Isotherm===========================
j=0
if [ ! -d "IT" ] ; then mkdir IT/; fi
for T in "${TsIT[@]}" 
	do
	l=-1
	j=$(($j+1))

	if [ "$j" -eq "1" ]; then rhoIT="${rhoIT1[@]}";	Nit="${Nit1[@]}"; fi
	if [ "$j" -eq "2" ]; then rhoIT="${rhoIT2[@]}";	Nit="${Nit2[@]}"; fi
	if [ "$j" -eq "3" ]; then rhoIT="${rhoIT3[@]}"; Nit="${Nit3[@]}"; fi
	if [ "$j" -eq "4" ]; then rhoIT="${rhoIT4[@]}"; Nit="${Nit4[@]}"; fi
	if [ "$j" -eq "5" ]; then rhoIT="${rhoIT5[@]}";	Nit="${Nit5[@]}"; fi
	if [ "$j" -eq "6" ]; then rhoIT="${rhoIT6[@]}";	Nit="${Nit6[@]}"; fi
	if [ "$j" -eq "7" ]; then rhoIT="${rhoIT7[@]}"; Nit="${Nit7[@]}"; fi
	if [ "$j" -eq "8" ]; then rhoIT="${rhoIT8[@]}"; Nit="${Nit8[@]}"; fi
	if [ "$j" -eq "9" ]; then rhoIT="${rhoIT9[@]}"; Nit="${Nit9[@]}"; fi
	if [ "$j" -eq "10" ]; then rhoIT="${rhoIT10[@]}"; Nit="${Nit10[@]}"; fi
	Nit=($Nit)
	for rho in ${rhoIT} 
		do
		l=$(($l+1))
		mkdir -p $CD/IT/${T}/${rho}

		if [ "$NmolecOverride" == "no-override" ]; then 
			N=${Nit[l]}
		else
			N=$NmolecOverride
		fi
		L=$(echo "scale=15; e((1/3)*l($N*$MW/$rho/0.6022140857))*0.1 "   | bc -l)

		cp $CD/Files/${molecule}.pdb $CD/IT/${T}/${rho}
		cp $CD/Files/${molecule}.top $CD/IT/${T}/${rho}
		cp $CD/Files/em_steep.mdp $CD/IT/${T}/${rho}
		cp $CD/Files/em_l-bfgs.mdp $CD/IT/${T}/${rho}
		cp $CD/Files/nvt_eq.mdp $CD/IT/${T}/${rho}
		cp $CD/Files/nvt_pr.mdp $CD/IT/${T}/${rho}

		sed -i -e "s/some_Temperature/$T/g" $CD/IT/${T}/${rho}/nvt_eq.mdp
		sed -i -e "s/some_Temperature/$T/g" $CD/IT/${T}/${rho}/nvt_pr.mdp
		sed -i -e "s/Nmolec/$N/g" $CD/IT/${T}/${rho}/${molecule}.top

		line="source /usr/local/gromacs/bin/GMXRC; \
			cd $CD/IT/${T}/${rho}; \
			$gmx_exe_address insert-molecules -ci ${molecule}.pdb -nmol $N -box $L $L $L -o ${molecule}_box.gro; \
			$gmx_exe_address grompp -f em_steep.mdp -c ${molecule}_box.gro -p ${molecule}.top -o em_steep.tpr; \
			$gmx_exe_address mdrun -nt 1 -deffnm em_steep; \
			$gmx_exe_address grompp -f em_l-bfgs.mdp -c em_steep.gro -p ${molecule}.top -o em_l_bfgs.tpr -maxwarn 1; \
			$gmx_exe_address mdrun -nt 1 -deffnm em_l_bfgs; \
			$gmx_exe_address grompp -f nvt_eq.mdp -c em_l_bfgs.gro -p ${molecule}.top -o nvt_eq.tpr; \
			$gmx_exe_address mdrun -nt 1 -deffnm nvt_eq; \
			$gmx_exe_address grompp -f nvt_pr.mdp -c nvt_eq.gro -p ${molecule}.top -o nvt_pr.tpr; \
			$gmx_exe_address mdrun -nt 1 -deffnm nvt_pr;"

		if [ "$Trho_rhoT_pairs_array" == "all" ]; then
			echo "$line" >> $CD/COMMANDS.parallel
		else
			if [ "$(isTrhoPairSelected "$CD/IT/${T}/${rho}/" "$Trho_rhoT_pairs_array")" == "found" ]; then
				echo "$line" >> $CD/COMMANDS.parallel	
			fi
		fi
	done
done

if [ "$should_run" == "yes" ]; then
	parallel --jobs $Nproc < $CD/COMMANDS.parallel
	bash $ScriptsDir/GromacsRdr.sh
fi
