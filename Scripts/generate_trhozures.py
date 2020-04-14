import numpy
import sys



MW = float(sys.argv[1])
#single_or_intra = sys.argv[2]
blocks_avg_filename = sys.argv[2]
#blocks_std_filename = sys.argv[4]
#if single_or_intra == "single":
#	single_avg_filename = sys.argv[5]
#	single_std_filename = sys.argv[6]


# Conversion factors and constants
atm_to_mpa = 0.101325
kcalmol_to_kjmol = 4.184
bar_to_mpa = 0.1
kelvin_to_kjmol = 0.0083
R_const = 8.31446261815324

blocks_avg = numpy.loadtxt(blocks_avg_filename, skiprows=1)
#blocks_std = numpy.loadtxt(blocks_std_filename, skiprows=1)

#if single_or_intra == "single":
#	single_avg = numpy.loadtxt(single_avg_filename, skiprows=1)
#	single_std = numpy.loadtxt(single_std_filename, skiprows=1)

#Temperature	Density	Pressure	TotalEnergy	KineticEn.	Potential	LJ(SR)	Disper.corr.	Coulomb(SR)	Angle	Ryckaert


T_K = blocks_avg[:,0]	# K
RHO_GCC = blocks_avg[:,1]	# g/ml
PRESSURE = blocks_avg[:,2]	# bar
#TOT_EN = blocks_avg[:,2]	# kJ/mol
#TOT_EN_std = blocks_std[:,2]
TOT_MOL =  [600,600,600,600,600,600,600,600,600,600,2400,2400,2400,2400,2400,2400,2400,2400,600,600,600,600,600,600,600,600]  #blocks_avg[:,12]
#PRESSURE_std = blocks_std[:,11] 
Z = PRESSURE * bar_to_mpa * MW / ( RHO_GCC  * R_const * T_K )
#Z_std = PRESSURE_std * bar_to_mpa * MW / ( RHO_GCC  * R_const * T_K )
Z_std =  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  #blocks_avg[:,12]
Ures_std =  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  #blocks_avg[:,12]

#if single_or_intra == "single":
#	T_K_single = single_avg[:,0]
#	TOT_EN_single = single_avg[:,2]

#	Uig = []
#	for Temp in T_K:
#		index = numpy.where(T_K_single == Temp)[0][0]
	#	Uig.append(TOT_EN_single[index])
		
	#Ures = ( TOT_EN - Uig * TOT_MOL )* kelvin_to_kjmol * 1e3 / TOT_MOL / R_const / T_K 
	#Ures_std = ( TOT_EN_std ) * kelvin_to_kjmol * 1e3 / TOT_MOL / R_const / T_K 

#elif single_or_intra == "intra":
#EN_INTRA_B = blocks_avg[:,5] 
#EN_INTRA_NB = blocks_avg[:,6]
#EN_INTRA_B_std = blocks_std[:,5] 
#EN_INTRA_NB_std = blocks_std[:,6]
POTENTIAL = blocks_avg[:,5] 

Ures=(POTENTIAL)/8.314/T_K/TOT_MOL*1000

#Ures = ( POTENTIAL ) * kelvin_to_kjmol * 1e3 / TOT_MOL / R_const / T_K 
#Ures_std = ( TOT_EN_std ) * kelvin_to_kjmol * 1e3 / TOT_MOL / R_const / T_K

print('T_K RHO_GCC Z Z_std Ures Ures_std N')
for i in range(0, len(T_K)):
	print(T_K[i], RHO_GCC[i], Z[i], Ures[i], Z_std[i], Ures_std[i], TOT_MOL[i])
