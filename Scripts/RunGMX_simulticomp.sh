#!/bin/bash
CD=${PWD}

#============================== Get arguments ================================
site_sig_eps_nnn=$1 
prefix=$2
molecules_array=$3
raw_ff_path=$4  
datafile_keywords_string=$5 
gmx_exe_address=$6 
weights_file=$7
Nproc=${8}
ITIC_subset_name=$9 
config_filename=${10} 
LJ_or_BUCK=${11}

mkdir $CD/${prefix}_${site_sig_eps_nnn}
cd $CD/${prefix}_${site_sig_eps_nnn}

molecules_array=($molecules_array)
datafile_keywords=($datafile_keywords_string)

rm -rf $CD/${prefix}_${site_sig_eps_nnn}/COMMANDS.parallel
for molec in "${molecules_array[@]}"
do 
    mkdir $CD/${prefix}_${site_sig_eps_nnn}/${molec}
    cd $CD/${prefix}_${site_sig_eps_nnn}/${molec}

    if [ "$ITIC_subset_name" == "all" ]; then
        select_itic_points="all"
    else
        select_itic_points=$(cat $HOME/Git/TranSFF/SelectITIC/${molec}_${ITIC_subset_name}.trho)
    fi

    cp -r $raw_ff_path $CD/${prefix}_${site_sig_eps_nnn}/${molec}/temp
    cooked_itp_folder=$CD/${prefix}_${site_sig_eps_nnn}/${molec}/temp
    tmp=$(bash $HOME/Git/ITIC_GROMACS/Scripts/generate_itp.sh $molec $site_sig_eps_nnn ${raw_ff_path}/ffnonbonded.itp $cooked_itp_folder $LJ_or_BUCK)
    itp_file_name=$(echo $tmp | awk '{print $1}')

    mv $CD/${prefix}_${site_sig_eps_nnn}/${molec}/temp $CD/${prefix}_${site_sig_eps_nnn}/${molec}/$itp_file_name

    bash $HOME/Git/ITIC_GROMACS/Scripts/RunITIC_GROMACS_Parallel.sh $molec $CD/${prefix}_${site_sig_eps_nnn}/${molec}/$itp_file_name/forcefield.itp $config_filename "$select_itic_points" $gmx_exe_address no-override no
    cat COMMANDS.parallel >> $CD/${prefix}_${site_sig_eps_nnn}/COMMANDS.parallel
    cd $CD
done

parallel --jobs $Nproc < $CD/${prefix}_${site_sig_eps_nnn}/COMMANDS.parallel

i=-1
for molec in "${molecules_array[@]}"
do 
    i=$((i+1))
    cd $CD/${prefix}_${site_sig_eps_nnn}/${molec}
    
    ITIC_file_name=$(ls $CD/${prefix}_${site_sig_eps_nnn}/${molec}/Files/*.itic)
    MW=$(grep "MW:" ${ITIC_file_name} | awk '{ print $2}')

       # Run excl 
    bash $HOME/Git/ITIC_GROMACS/Scripts/RerunITIC_GROMACS_Parallel.sh $molec 50 $Nproc $gmx_exe_address
    

       # Get averages
    rm -rf $CD/${prefix}_${site_sig_eps_nnn}/${molec}/EnergyOut/ *.res
    bash $HOME/Git/ITIC_GROMACS/Scripts/GromacsRdr.sh nvt_pr
    bash $HOME/Git/ITIC_GROMACS/Scripts/GromacsRdr.sh nvt_excl

       # Generate trhozures.res
    python3.6 $HOME/Git/ITIC_GROMACS/Scripts/generate_trhozures.py $MW nvt_pr.avg nvt_excl.avg nvt_pr.std  nvt_excl.std | tee $CD/${prefix}_${site_sig_eps_nnn}/${molec}/trhozures.res;

       # Plot
        #bash $HOME/Git/TranSFF/Scripts/ITIC/ITIC.sh $molec trhozures.res ${molec}.${Forcefield_ext}
        #bash $HOME/Git/TranSFF/Scripts/ITIC/plot_vle_comparison.sh $molec "$LitsatExt" "$LitsatLabel" ${molec}_vle.png

    dsim_data_file="trhozures.res"
    true_data_file="${datafile_keywords[i]}_${ITIC_subset_name}.res"

    bash $HOME/Git/TranSFF/Scripts/ITIC/plot_zures_no-refprop.sh $molec "$dsim_data_file $true_data_file" "Simulation True" #$trimZ $trimU
done

i=-1
for molec in "${molecules_array[@]}"
do 
    i=$((i+1))
    MW=$(grep "MW:" $HOME/Git/ITIC_GROMACS/Molecules/${molec}/${molec}.itic | awk '{print $2}')
    true_data_file="$HOME/Git/TranSFF/Data/${molec}/${datafile_keywords[i]}_${ITIC_subset_name}.res"
    dsim_data_file="${CD}/${prefix}_${site_sig_eps_nnn}/${molec}/trhozures.res"
    score=$(python3.6 $HOME/Git/ITIC_GROMACS/Scripts/calc_sim_from_true_data_dev_rmsd_weighted.py $MW ${true_data_file} $dsim_data_file $weights_file) 
    echo $score > $CD/${prefix}_${site_sig_eps_nnn}/${molec}/${molec}.score
done


#============================== Compile score files ================================
rm -rf $CD/${prefix}_${site_sig_eps_nnn}/${prefix}.score
echo "molec Total_Score Z_score U^res_Score" >> $CD/${prefix}_${site_sig_eps_nnn}/${prefix}.score
for molec in "${molecules_array[@]}"
do 
    score=$(cat ${CD}/${prefix}_${site_sig_eps_nnn}/${molec}/${molec}.score)
    echo $molec $score >> $CD/${prefix}_${site_sig_eps_nnn}/${prefix}.score
done
cp $CD/${prefix}_${site_sig_eps_nnn}/${prefix}.score $CD/${prefix}.score
echo $CD/${prefix}_${site_sig_eps_nnn}/${prefix}.score


