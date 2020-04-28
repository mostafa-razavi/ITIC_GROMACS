#!/bin/bash
CD=${PWD}
cd $CD
molec=$1
raw_top_file=$2 

#13C4E 1C4E 1C6E 1C8E 2M13C4E c-2C5E IC4E t-2C4E t-2C5E 15C6E 1C5E 1C7E c-2C4E C2EC3E
#22MH 33MH 23MB 22MB 22MP 25MH 2MH 34MH IC4 IC5 IC6 IC8 NP 


system=$(grep -w "$molec" $HOME/Git/TranSFF/Molecules/nicknames.txt | awk '{print$3}')


cp -r ~/Git/TranSFF/Molecules/${molec} .
cd $molec
unzip -qq ${molec}_Files.zip
files=($(ls Files))
cp Files/${files[0]}/*.psf .
psf_file=$(ls *.psf)

natoms_per_molec_plus_1=$(grep -m 1 " 2    " $psf_file | awk '{print$1}')
natoms_per_molec=$(echo "${natoms_per_molec_plus_1}-1" | bc)


grep -A ${natoms_per_molec} "NATOM" $psf_file | tail -n +2 > atoms.tmp

sites=$(cat atoms.tmp | awk '{print$6}')
sites=($sites)

mws=$(cat atoms.tmp | awk '{print$8}')
mws=($mws)


cp ${raw_top_file} ${molec}.top

sed -i "s/some__molec_name/$molec/g" ${molec}.top
sed -i "s/some__system_name/$system/g" ${molec}.top

for isite in $(seq 1 1 $(echo "${#sites[@]}" | bc ) )
do
    i=$(($isite-1))
    sed -i "s/some__site${isite}_name/${sites[i]}/g" ${molec}.top
    sed -i "s/some__mw${isite}_name/${mws[i]}/g" ${molec}.top
done

grep -A 10 "NBOND" $psf_file   > bonds.1.tmp
line_natoms_per_molec_plus_1=$(grep -m 1 -w "$natoms_per_molec_plus_1" bonds.1.tmp)
sed -n "/NBOND/,/${line_natoms_per_molec_plus_1}/p" bonds.1.tmp | tail -n +2 > bonds.2.tmp
sed -i "s/${natoms_per_molec_plus_1}.*//g" bonds.2.tmp


grep -A 10 "NTHETA" $psf_file    > angles.1.tmp 
line_natoms_per_molec_plus_1=$(grep -m 1 -w "$natoms_per_molec_plus_1" angles.1.tmp)
sed -n "/NTHETA/,/${line_natoms_per_molec_plus_1}/p" angles.1.tmp | tail -n +2 > angles.2.tmp
sed -i "s/${natoms_per_molec_plus_1}.*//g" angles.2.tmp

grep -A 10 "NPHI" $psf_file    > dihedrals.1.tmp 
line_natoms_per_molec_plus_1=$(grep -m 1 -w "$natoms_per_molec_plus_1" dihedrals.1.tmp)
sed -n "/NPHI/,/${line_natoms_per_molec_plus_1}/p" dihedrals.1.tmp | tail -n +2 > dihedrals.2.tmp
sed -i "s/${natoms_per_molec_plus_1}.*//g" dihedrals.2.tmp


sed -i -e "/some__bonds_line/r bonds.2.tmp" -e "/some__bonds_line/d" ${molec}.top
sed -i -e "/some__angles_line/r angles.2.tmp" -e "/some__angles_line/d" ${molec}.top
sed -i -e "/some__dihedrals_line/r dihedrals.2.tmp" -e "/some__dihedrals_line/d" ${molec}.top


sed -i "/some__/d" ${molec}.top
sed -i "s/ CH3 / CH3_C /g" ${molec}.top
sed -i "s/ CH2 / CH2_C /g" ${molec}.top
sed -i "s/ CH1 / CH_C  /g" ${molec}.top
sed -i "s/ CT / C_C   /g" ${molec}.top

rm -rf *.tmp *.psf Files *.zip