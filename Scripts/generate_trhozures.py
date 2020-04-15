import numpy
import sys
import uncertainties as u


MW = float(sys.argv[1])
#single_or_intra = sys.argv[2]
prod_avg_filename = sys.argv[2]
excl_avg_filename = sys.argv[3]
prod_std_filename = sys.argv[4]
excl_std_filename = sys.argv[5]

#if single_or_intra == "single":
#	single_avg_filename = sys.argv[5]
#	single_std_filename = sys.argv[6]


# Conversion factors and constants
atm_to_mpa = 0.101325
kcalmol_to_kjmol = 4.184
bar_to_mpa = 0.1
kelvin_to_kjmol = 0.0083
R_const = 8.31446261815324

#Temperature Density Nmolec Pressure TotalEnergy Potential LJ_SR DisperCorr Coulomb_SR Bond Angle Ryckaert
prod_avg = numpy.genfromtxt(prod_avg_filename, skip_header=1, delimiter="\t", filling_values=0) #loadtxt(prod_avg_filename, skiprows=1, delimiter='\t')
excl_avg = numpy.genfromtxt(excl_avg_filename, skip_header=1, delimiter="\t", filling_values=0) #numpy.loadtxt(excl_avg_filename, skiprows=1, delimiter='\t' )

prod_std = numpy.genfromtxt(prod_std_filename, skip_header=1, delimiter="\t", filling_values=0) #loadtxt(prod_avg_filename, skiprows=1, delimiter='\t')
excl_std = numpy.genfromtxt(excl_std_filename, skip_header=1, delimiter="\t", filling_values=0) #numpy.loadtxt(excl_avg_filename, skiprows=1, delimiter='\t' )


T_K = prod_avg[:,0]	# K
RHO_GCC = prod_avg[:,1]	# g/ml
TOT_MOL = prod_avg[:,2] 
Pressure = prod_avg[:,3]	# bar
TotalEnergy = prod_avg[:,4] # kj/mol
Potential = prod_avg[:,5] # kj/mol
LJ_SR = prod_avg[:,6]	# kj/mol
DisperCorr = prod_avg[:,7]	# kj/mol
Coulomb_SR = prod_avg[:,8]	# kj/mol
Bond = prod_avg[:,9] # kj/mol
Angle = prod_avg[:,10] # kj/mol
Ryckaert = prod_avg[:,11] # kj/mol

T_K_std = prod_std[:,0]	# K
Pressure_std = prod_std[:,3]	# bar
TotalEnergy_std = prod_std[:,4] # kj/mol
Potential_std = prod_std[:,5] # kj/mol
LJ_SR_std = prod_std[:,6]	# kj/mol
DisperCorr_std = prod_std[:,7]	# kj/mol
Coulomb_SR_std = prod_std[:,8]	# kj/mol
Bond_std = prod_std[:,9] # kj/mol
Angle_std = prod_std[:,10] # kj/mol
Ryckaert_std = prod_std[:,11] # kj/mol

T_K_excl = excl_avg[:,0]	# K
RHO_GCC_excl = excl_avg[:,1]	# g/ml
TOT_MOL_excl = excl_avg[:,2] 
Pressure_excl = excl_avg[:,3]	# bar
TotalEnergy_excl = excl_avg[:,4] # kj/mol
Potential_excl = excl_avg[:,5] # kj/mol
LJ_SR_excl = excl_avg[:,6]	# kj/mol
DisperCorr_excl = excl_avg[:,7]	# kj/mol
Coulomb_SR_excl = excl_avg[:,8]	# kj/mol
Bond_excl = excl_avg[:,9] # kj/mol
Angle_excl = excl_avg[:,10] # kj/mol
Ryckaert_excl = excl_avg[:,11] # kj/mol

T_K_excl_std = excl_std[:,0]	# K
Pressure_excl_std = excl_std[:,3]	# bar
TotalEnergy_excl_std = excl_std[:,4] # kj/mol
Potential_excl_std = excl_std[:,5] # kj/mol
LJ_SR_excl_std = excl_std[:,6]	# kj/mol
DisperCorr_excl_std = excl_std[:,7]	# kj/mol
Coulomb_SR_excl_std = excl_std[:,8]	# kj/mol
Bond_excl_std = excl_std[:,9] # kj/mol
Angle_excl_std = excl_std[:,10] # kj/mol
Ryckaert_excl_std = excl_std[:,11] # kj/mol

Z = Pressure * bar_to_mpa * MW / ( RHO_GCC  * R_const * T_K )

#Pairwise = Potential - Bond - Angle - Ryckaert
#Pairwise_excl = Potential_excl - Bond_excl - Angle_excl - Ryckaert_excl
#IntraPairwise = Pairwise -  Pairwise_excl
#EBonded = Bond + Angle + Ryckaert
#Ures=(Potential - EBonded - IntraPairwise)/8.314/T_K/TOT_MOL*1000

# The above comments is equivalent to:
Ures=(Potential_excl - Bond_excl - Angle_excl - Ryckaert_excl)/8.314/T_K/TOT_MOL*1000

Z_std = []
Ures_std = []
for i in range(len(T_K)):
	u_T_K = u.ufloat(T_K[i], T_K_std[i])
	u_Pressure = u.ufloat(Pressure[i], Pressure_std[i])

	u_Potential_excl = u.ufloat(Potential_excl[i], Potential_excl_std[i])
	u_Bond_excl = u.ufloat(Bond_excl[i], Bond_excl_std[i])
	u_Angle_excl = u.ufloat(Angle_excl[i], Angle_excl_std[i])
	u_Ryckaert_excl = u.ufloat(Ryckaert_excl[i], Ryckaert_excl_std[i])
	
	u_Z = u_Pressure * bar_to_mpa * MW / ( RHO_GCC  * R_const * u_T_K )[i]
	Z_std.append(u_Z.std_dev)	# u_Z.nominal_value
	u_Ures = ((u_Potential_excl - u_Bond_excl  - u_Angle_excl - u_Ryckaert_excl)/8.314/u_T_K/TOT_MOL*1000)[i]    
	Ures_std.append(u_Ures.std_dev)	# u_Ures.nominal_value
	
	
print('T_K RHO_GCC Z Z_std Ures Ures_std N')
for i in range(0, len(T_K)):
	print(T_K[i], RHO_GCC[i], Z[i], Ures[i], Z_std[i], Ures_std[i], TOT_MOL[i])
