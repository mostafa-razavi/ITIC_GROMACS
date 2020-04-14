#!/bin/bash
RunOrRerun=$1
source /usr/local/gromacs/bin/GMXRC
term[0]="Density"
term[1]="Angle"
term[2]="Ryckaert"
term[3]="LJ (SR)"
term[4]="Disper. corr."
term[5]="Coulomb (SR)"
term[6]="Potential"
term[7]="Kinetic En."
term[8]="Total Energy"
term[9]="Conserved En."
term[10]="Temperature"
term[11]="Pres. DC"
term[12]="Pressure"
term[13]="Constr. rmsd"
term[14]="Vir XX"
term[15]="Vir XY"
term[16]="Vir XZ"
term[17]="Vir YX"
term[18]="Vir YY"
term[19]="Vir YZ"
term[20]="Vir ZX"
term[21]="Vir ZY"
term[22]="Vir ZZ"
term[23]="Pres XX"
term[24]="Pres XY"
term[25]="Pres XZ"
term[26]="Pres YX"
term[27]="Pres YY"
term[28]="Pres YZ"
term[29]="Pres ZX"
term[30]="Pres ZY"
term[31]="Pres ZZ"
term[32]="SurfTen"
term[33]="T System"
CD=${PWD}

gmx_exe_address="$HOME/Git/GROMACS/gromacs-2020.1/build/bin/gmx"

if [ "$RunOrRerun" == "run" ]
then
	edrFile="nvt_pr.edr"
	RunOrRerun="run"
elif [ "$RunOrRerun" == "rerun" ]
then
	edrFile="nvt_rerun.edr"
	RunOrRerun="rerun"
fi

for fol in I*/*/*; do 
	cd $fol
	$gmx_exe_address energy -f $edrFile < $HOME/Git/ITIC_GROMACS/Config/properties.inp | tee $RunOrRerun.out 
	cd $CD
done

#read -p "Pause"

mkdir -p EnergyOut
for i in $(seq 1 1 33)
do
	grep -R "${term[$i]}" I*/*/*/$RunOrRerun.out | tee  EnergyOut/$i.$RunOrRerun
	sed -i "s/${term[$i]}//g" EnergyOut/$i.$RunOrRerun
	sed -i "1i${term[$i]}" EnergyOut/$i.$RunOrRerun
done

cd EnergyOut
for i in $(seq 1 1 33)
do
	cat $i.$RunOrRerun | awk '{print $2}' > $i.$RunOrRerun.trim
done

rm -rf 0.$RunOrRerun.trim

cat  3.$RunOrRerun | awk '{print $1}' | cut -d "/" -f 1 >  3.$RunOrRerun.1
cat  3.$RunOrRerun | awk '{print $1}' | cut -d "/" -f 2 >  3.$RunOrRerun.2
cat  3.$RunOrRerun | awk '{print $1}' | cut -d "/" -f 3 >  3.$RunOrRerun.3

paste 3.$RunOrRerun.1 3.$RunOrRerun.2 3.$RunOrRerun.3 > 0.$RunOrRerun

while read p; do
	if [ $(echo $p | awk '{print $1}') == "IT" ]
	then
		echo $p | awk '{print $3}' >> 0.$RunOrRerun.trim
	elif [ $(echo $p | awk '{print $1}') == "IC" ]
	then
		echo $p | awk '{print $2}' >> 0.$RunOrRerun.trim
	else
		echo "Density" >> 0.$RunOrRerun.trim
	fi
done < 0.$RunOrRerun

paste 10.$RunOrRerun.trim 0.$RunOrRerun.trim 12.$RunOrRerun.trim 8.$RunOrRerun.trim 7.$RunOrRerun.trim 6.$RunOrRerun.trim 3.$RunOrRerun.trim 4.$RunOrRerun.trim 5.$RunOrRerun.trim 1.$RunOrRerun.trim 2.$RunOrRerun.trim > $RunOrRerun.res
rm *.trim
for i in $(seq 1 1 33)
do
	term[$i]=$(echo ${term[$i]} | sed 's/ //g')
done
heading="${term[10]} ${term[0]} ${term[12]} ${term[8]} ${term[7]} ${term[6]} ${term[3]} ${term[4]} ${term[5]} ${term[1]} ${term[2]}"
sed -i '1d' $RunOrRerun.res
sed -i "1i$heading" $RunOrRerun.res
cd $CD
mv EnergyOut/$RunOrRerun.res .

