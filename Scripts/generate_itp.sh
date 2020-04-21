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


IFS='_' read -ra site_sig_eps_n_array <<< "$site_sig_eps_n"
for i in $(seq 0 $(echo "${#site_sig_eps_n_array[@]}-1" | bc)) 
do
    IFS='-' read -ra sitesigepsn_array <<< "${site_sig_eps_n_array[i]}"
    

    if [ "$LJ_or_BUCK" == "LJ" ]; then
        sitesigepsn_array[1]=$(echo "scale=15; ${sitesigepsn_array[1]}*0.1" | bc | awk '{printf "%f", $0}')                                     # A to nm
        sitesigepsn_array[2]=$(echo "scale=15; ${sitesigepsn_array[2]}/120.272443230099" | bc | awk '{printf "%f", $0}')                        # K to kJ/mol
    elif [ "$LJ_or_BUCK" == "BUCK" ]; then
        rmin=${sitesigepsn_array[1]}
        eps=${sitesigepsn_array[2]}
        alpha=${sitesigepsn_array[3]}
        # Convert rmin, eps, and alpha set to A, B, and C
        sitesigepsn_array[1]=$(echo "scale=15; 6*$eps/($alpha-6)*e($alpha)*0.008314462811444" | bc -l | awk '{printf "%f", $0}')                 # A [kJ/mol] = 6*eps[K]/(alpha-6)*exp(alpha)*0.008314462811444
        sitesigepsn_array[2]=$(echo "scale=15; $alpha/$rmin * 10" | bc | awk '{printf "%f", $0}')                                                # B [1/nm] = alpha/rmin[A] * 10
        sitesigepsn_array[3]=$(echo "scale=15; $eps*$alpha*($rmin)^6/($alpha-6) * 0.008314462811444 / (10)^6" | bc | awk '{printf "%f", $0}')    # C [kJ/mol*nm^6] = eps[K]*alpha*rmin[A]^6/(alpha-6) * 0.008314462811444 / 10^6
    fi
    sed -i "s/some_nbp1_${sitesigepsn_array[0]}/${sitesigepsn_array[1]}/g" $cooked_itp_file_path
    sed -i "s/some_nbp2_${sitesigepsn_array[0]}/${sitesigepsn_array[2]}/g" $cooked_itp_file_path
    sed -i "s/some_nbp3_${sitesigepsn_array[0]}/${sitesigepsn_array[3]}/g" $cooked_itp_file_path
done

sed -i '/some_nbp/d' $cooked_itp_file_path

echo $all_sites_string $cooked_itp_file_path