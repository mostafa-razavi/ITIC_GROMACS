

molec="$1"

bash ~/Git/TranSFF/Scripts/ITIC/ITIC.sh $molec GromacsRdr.res ${molec}.trappegmx-itic-razavi
bash ~/Git/TranSFF/Scripts/ITIC/plot_vle_comparison.sh $molec "trappegmx-itic-razavi trappe-itic-razavi" "TraPPE-GMX TraPPE-GOMC" ${molec}_vle.png
bash ~/Git/TranSFF/Scripts/ITIC/plot_zures.sh $molec "GromacsRdr.res TraPPE.res" "TraPPE-GMX TraPPE-GOMC" ${molec}_zures.png
