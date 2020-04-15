#!/bin/bash
source /usr/local/gromacs/bin/GMXRC

edr_name=$1
edrFile="${edr_name}.edr"
gmx_exe_address="$HOME/Git/GROMACS/gromacs-2020.1/build/bin/gmx"

prop=( "Temperature" "Pressure" "Total Energy" "Potential" "LJ (SR)" "Disper. corr." "Coulomb (SR)" "Bond" "Angle" "Ryckaert")
fname=("Temperature" "Pressure" "TotalEnergy"  "Potential" "LJ_SR"   "DisperCorr"   "Coulomb_SR"   "Bond" "Angle" "Ryckaert")

CD=${PWD}

# echo -ne '1' | $gmx_exe_address energy -f nvt_pr.edr > energy_out.tmp 2>&1
# sed -n '/End your selection with an empty/,/Back Off! I just backed up/p' energy_out.tmp | tail +3 | head -n -3 > properties.tmp
#p1=$(cat properties.tmp | awk '{print$2}')
#p2=$(cat properties.tmp | awk '{print$4}')
#p3=$(cat properties.tmp | awk '{print$6}')
#p4=$(cat properties.tmp | awk '{print$8}')
#props=(${p1} ${p2} ${p3} ${p4})


mkdir -p EnergyOut
echo "Nmolec" > ${CD}/EnergyOut/Nmolec.out
for fol in I*/*/*; do 
	cd $fol
	if [ -e "$edrFile" ]; then	# If the ITIC point was simulated 
	$gmx_exe_address energy -f $edrFile < $HOME/Git/ITIC_GROMACS/Config/properties.inp | tee ${edr_name}.out
		grep -A1 -R "\[ molecules \]" *.top | tail -n1 | awk '{print$2}' >> ${CD}/EnergyOut/Nmolec.out
	fi
	cd $CD
done

for i in $(seq 0 1 $(echo "scale=1;${#prop[@]}-1" | bc))
do
	grep -R "${prop[i]}" I*/*/*/${edr_name}.out | tee  EnergyOut/${fname[i]}.${edr_name}
	sed -i "s/${prop[i]}//g" EnergyOut/${fname[i]}.${edr_name}
	sed -i "1i${prop[i]}" EnergyOut/${fname[i]}.${edr_name}
done

cd EnergyOut
for i in ${fname[@]}
do
	cat $i.${edr_name} | awk '{print $2}' > $i.${edr_name}.tmp_avg
	cat $i.${edr_name} | awk '{print $3}' > $i.${edr_name}.tmp_std
done

rm -rf Density.out.tmp_avg

cat  LJ_SR.${edr_name} | awk '{print $1}' | cut -d "/" -f 1 >  LJ_SR.${edr_name}.1
cat  LJ_SR.${edr_name} | awk '{print $1}' | cut -d "/" -f 2 >  LJ_SR.${edr_name}.2
cat  LJ_SR.${edr_name} | awk '{print $1}' | cut -d "/" -f 3 >  LJ_SR.${edr_name}.3

paste LJ_SR.${edr_name}.1 LJ_SR.${edr_name}.2 LJ_SR.${edr_name}.3 > Density.out
rm LJ_SR.${edr_name}.1 LJ_SR.${edr_name}.2 LJ_SR.${edr_name}.3

while read p; do
	if [ $(echo $p | awk '{print $1}') == "IT" ]
	then
		echo $p | awk '{print $3}' >> Density.out.tmp_avg
	elif [ $(echo $p | awk '{print $1}') == "IC" ]
	then
		echo $p | awk '{print $2}' >> Density.out.tmp_avg
	else
		echo "Density" >> Density.out.tmp_avg
	fi
done < Density.out
rm Density.out
mv Density.out.tmp_avg Density.out

paste ${fname[0]}.${edr_name}.tmp_avg Density.out ${CD}/EnergyOut/Nmolec.out ${fname[1]}.${edr_name}.tmp_avg ${fname[2]}.${edr_name}.tmp_avg ${fname[3]}.${edr_name}.tmp_avg ${fname[4]}.${edr_name}.tmp_avg ${fname[5]}.${edr_name}.tmp_avg ${fname[6]}.${edr_name}.tmp_avg ${fname[7]}.${edr_name}.tmp_avg ${fname[8]}.${edr_name}.tmp_avg ${fname[9]}.${edr_name}.tmp_avg > ${edr_name}.avg
paste ${fname[0]}.${edr_name}.tmp_std Density.out ${CD}/EnergyOut/Nmolec.out ${fname[1]}.${edr_name}.tmp_std ${fname[2]}.${edr_name}.tmp_std ${fname[3]}.${edr_name}.tmp_std ${fname[4]}.${edr_name}.tmp_std ${fname[5]}.${edr_name}.tmp_std ${fname[6]}.${edr_name}.tmp_std ${fname[7]}.${edr_name}.tmp_std ${fname[8]}.${edr_name}.tmp_std ${fname[9]}.${edr_name}.tmp_std > ${edr_name}.std

rm *.tmp_avg
rm *.tmp_std
for i in $(seq 1 1 33)
do
	prop[$i]=$(echo ${prop[$i]} | sed 's/ //g')
done

sed -i "s/\-\-/nan/g" $CD/EnergyOut/*	# Sometimes gmx energy produces "--" instead of a valid estimate of error. Here we replace it with nan


heading_avg="${fname[0]} Density Nmolec ${fname[1]} ${fname[2]} ${fname[3]} ${fname[4]} ${fname[5]} ${fname[6]} ${fname[7]} ${fname[8]} ${fname[9]}"
heading_std="${fname[0]}_std Density Nmolec ${fname[1]}_std ${fname[2]}_std ${fname[3]}_std ${fname[4]}_std ${fname[5]}_std ${fname[6]}_std ${fname[7]}_std ${fname[8]}_std ${fname[9]}_std"

sed -i '1d' ${edr_name}.avg
sed -i '1d' ${edr_name}.std
sed -i "1i$heading_avg" ${edr_name}.avg
sed -i "1i$heading_std" ${edr_name}.std

cd $CD
mv EnergyOut/${edr_name}.avg .
mv EnergyOut/${edr_name}.std .

