#!/bin/bash
# This script generates GROMACS itp file from on a given string (e.g. CH3-3.8-120-12_CH2-4.0-58-12_CH1-4.7-13.5-12_CT-6.4-5-12) 
#   
# Syntax of the second argument: site types are separated by "_" and non-bonded parameters (nbp) are separated by "-". First part is always the site name
# Note that the site_sig_eps_n could contain site types that do not exist in the molecule. This feature helps in simultaneous optimization of multiple molecules.
#   e.g, CT does not exists in IC5 molecule (see the following example)
#
# Example: 
# bash ~/Git/ITIC_GROMACS/Scripts/generate_itp.sh IC5 CH3-3.8-120-12_CH2-4.0-58-12_CH1-4.7-13.5-12_CT-6.4-5-12 /home/mostafa/Git/ITIC_GROMACS/Forcefields/TraPPE-raw/forcefield.itp ~/myProjects/

molec_name=$1
site_sig_eps_n=$2       # E.g. CH3a-3.8-123-12_CH3b-3.8-120-12_CH2-4.0-58-12_CH1-4.7-13.5-12_CT-6.4-5-12
raw_itp_path=$3         # The address of a itp file that contains some_nbp{1,2 or 3}}_{sitename} strings
cooked_itp_folder=$4
LJ_or_BUCK=$5           # Lennard-Jones or Buckingham?

sites_array=($(grep ATOM ~/Git/TranSFF/Molecules/$molec_name/$molec_name.top | awk '{print $3}'))
all_sites_string=""
IFS='_' read -ra site_sig_eps_n_array <<< "$site_sig_eps_n"
for i in $(seq 0 $(echo "${#site_sig_eps_n_array[@]}-1" | bc)) 
do
    site_string=""
    IFS='-' read -ra sitesigepsn_array <<< "${site_sig_eps_n_array[i]}"

    search_var="${sitesigepsn_array[0]}"
    for item in "${sites_array[@]}"; do
        if [ "$item" == "$search_var" ]; then 
            for j in $(seq 0 $(echo "${#sitesigepsn_array[@]}-1" | bc)) 
            do
                site_string="${site_string}-${sitesigepsn_array[j]}"
            done 
        site_string=${site_string:1}
        all_sites_string="${all_sites_string}_${site_string}"
        break
        fi
    done
done
all_sites_string="${all_sites_string:1}"

#itp_file_name=${all_sites_string}.itp

cooked_itp_file_path="$cooked_itp_folder/ffnonbonded.itp"

cp $raw_itp_path $cooked_itp_file_path

site_array=()
sig_array=()
eps_array=()
alpha_array=()

IFS='_' read -ra site_sig_eps_n_array <<< "$site_sig_eps_n"
for i in $(seq 0 $(echo "${#site_sig_eps_n_array[@]}-1" | bc)) 
do
    IFS='-' read -ra sitesigepsn_array <<< "${site_sig_eps_n_array[i]}"
    

    if [ "$LJ_or_BUCK" == "LJ" ]; then
        sig=$(echo "scale=15; ${sitesigepsn_array[1]}*0.1" | bc | awk '{printf "%f", $0}')                                     # A to nm
        eps=$(echo "scale=15; ${sitesigepsn_array[2]}/120.272443230099" | bc | awk '{printf "%f", $0}')                        # K to kJ/mol

        site=${sitesigepsn_array[0]}
        sig=${sitesigepsn_array[1]}
        eps=${sitesigepsn_array[2]}

        sed -i "s/some_nbp1_${site}/$sig/g" $cooked_itp_file_path
        sed -i "s/some_nbp2_${site}/$eps/g" $cooked_itp_file_path

    elif [ "$LJ_or_BUCK" == "BUCK" ]; then

        site=${sitesigepsn_array[0]}
        sig=${sitesigepsn_array[1]}
        eps=${sitesigepsn_array[2]}
        alpha=${sitesigepsn_array[3]}

        site_array=( "${site_array[@]}" "$site" )
        sig_array=( "${sig_array[@]}" "$sig" )
        eps_array=( "${eps_array[@]}" "$eps" )
        alpha_array=( "${alpha_array[@]}" "$alpha" )

        # Convert sig, eps, and alpha set to A, B, and C
        tmp=$(python3.6 $HOME/Git/ITIC_GROMACS/Scripts/Buckingham_get_rmin-A-B-C.py $sig $eps $alpha)
        A_coef=$(echo "$tmp" | awk '{print$2}')
        B_coef=$(echo "$tmp" | awk '{print$3}')
        C_coef=$(echo "$tmp" | awk '{print$4}')

        sed -i "s/some_nbp1_${site}/$A_coef/g" $cooked_itp_file_path
        sed -i "s/some_nbp2_${site}/$B_coef/g" $cooked_itp_file_path
        sed -i "s/some_nbp3_${site}/$C_coef/g" $cooked_itp_file_path
    fi
done


# Apply combining rules for cross-inteactions
for i in $(seq 0 $(echo "${#site_array[@]}-1" | bc))
do
    for j in $(seq $((i+1)) $(echo "${#site_array[@]}-1" | bc))
    do
        sig1=${sig_array[i]}
        sig2=${sig_array[j]}

        eps1=${eps_array[i]}
        eps2=${eps_array[j]}

        alpha1=${alpha_array[i]}
        alpha2=${alpha_array[j]}

        combined_sigma=$(echo "scale=15; ($sig1+$sig2)/2" | bc -l | awk '{printf "%f", $0}')                 
        combined_epsilon=$(echo "scale=15; sqrt($eps1*$eps2)" | bc -l | awk '{printf "%f", $0}')                 
        combined_alpha=$(echo "scale=15; sqrt($alpha1*$alpha2)" | bc -l | awk '{printf "%f", $0}') 
                        
        # Convert sig, eps, and alpha set to A, B, and C
        tmp=$(python3.6 $HOME/Git/ITIC_GROMACS/Scripts/Buckingham_get_rmin-A-B-C.py $combined_sigma $combined_epsilon $combined_alpha)
        A_coef=$(echo "$tmp" | awk '{print$2}')
        B_coef=$(echo "$tmp" | awk '{print$3}')
        C_coef=$(echo "$tmp" | awk '{print$4}')

        sed -i "s/some_cnbp1_${site_array[i]}-some_cnbp1_${site_array[j]}/$A_coef/g" $cooked_itp_file_path
        sed -i "s/some_cnbp2_${site_array[i]}-some_cnbp2_${site_array[j]}/$B_coef/g" $cooked_itp_file_path
        sed -i "s/some_cnbp3_${site_array[i]}-some_cnbp3_${site_array[j]}/$C_coef/g" $cooked_itp_file_path
    done
done

sed -i '/some_nbp/d' $cooked_itp_file_path
sed -i '/some_cnbp/d' $cooked_itp_file_path


echo $all_sites_string $cooked_itp_file_path
