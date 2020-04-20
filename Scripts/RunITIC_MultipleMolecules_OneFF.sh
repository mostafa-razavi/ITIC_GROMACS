#!/bin/bash
source /usr/local/gromacs/bin/GMXRC
CD=${PWD}

molecules_array="C3 C4 C5"
Nproc=$(nproc)
select="all"

Forcefield_name="TraPPE-GMX"
Forcefield_ext="trappe-itic-razavi-gmx"
force_field_path="$HOME/Git/ITIC_GROMACS/Forcefields/trappeua.ff/forcefield.itp"

config_filename="TC_RC14_LF_BR_2NS-4NS_LINCS8.config"
gmx_exe_address="$HOME/Git/GROMACS/gromacs-2018.1/build/bin/gmx"

#============Plots Settings=============
LitsatExt="$Forcefield_ext trappe-itic-razavi"
LitsatLabel="$Forcefield_name TraPPE-GOMC"
ITIC_trhozures_filename="trhozures.res TraPPE.res"
ITIC_trhozures_label="$LitsatLabel"
trimZ="no-trimZ" 
trimU="yes-trimU"

#======================================
rm -rf ${CD}/COMMANDS.parallel
molecules_array=($molecules_array)
for molec in "${molecules_array[@]}"
do 
    mkdir ${CD}/${molec}
    cd ${CD}/${molec}
    if [ "$select" == "all" ]; then
        select_itic_points="all"
    else
        select_itic_points=$(cat $HOME/Git/TranSFF/SelectITIC/${molec}_${select}.trho)
    fi
    bash $HOME/Git/ITIC_GROMACS/Scripts/RunITIC_GROMACS_Parallel.sh $molec $force_field_path $config_filename "$select_itic_points" $gmx_exe_address no-override no
    cat COMMANDS.parallel >> ${CD}/COMMANDS.parallel
    cd $CD
done

parallel --jobs $Nproc < COMMANDS.parallel

for molec in "${molecules_array[@]}"
do 
    cd ${CD}/${molec}
    
    ITIC_file_name=$(ls $CD/${molec}/Files/*.itic)
    MW=$(grep "MW:" ${ITIC_file_name} | awk '{ print $2}')

       # Run excl 
    bash $HOME/Git/ITIC_GROMACS/Scripts/RerunITIC_GROMACS_Parallel.sh $molec 50 $Nproc $gmx_exe_address #bash $HOME/Git/ITIC_GROMACS/Scripts/RunExcl_GROMACS_Parallel.sh $molec 50 $Nproc 500000

       # Get averages
    rm -rf EnergyOut/ *.res
    bash $HOME/Git/ITIC_GROMACS/Scripts/GromacsRdr.sh nvt_pr
    bash $HOME/Git/ITIC_GROMACS/Scripts/GromacsRdr.sh nvt_excl

       # Generate trhozures.res
    python3.6 $HOME/Git/ITIC_GROMACS/Scripts/generate_trhozures.py $MW nvt_pr.avg nvt_excl.avg nvt_pr.std  nvt_excl.std | tee trhozures.res;

       # Plot
    bash $HOME/Git/TranSFF/Scripts/ITIC/ITIC.sh $molec trhozures.res ${molec}.${Forcefield_ext}
    bash $HOME/Git/TranSFF/Scripts/ITIC/plot_vle_comparison.sh $molec "$LitsatExt" "$LitsatLabel" ${molec}_vle.png
    bash $HOME/Git/TranSFF/Scripts/ITIC/plot_zures.sh $molec "$ITIC_trhozures_filename" "$ITIC_trhozures_label"
done

