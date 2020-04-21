# This script computes the weighted rms deviation between simulation and true data. The data in true_data_file and dsim_data_file should be consistent in terms of order of lines. 

import numpy
import sys


MW = float(sys.argv[1])
true_data_file = sys.argv[2]               # The file that is used to minimize the deviations against
dsim_data_file = sys.argv[3]               # The file that contains MBAR results at ITIC state points
weights_file = sys.argv[4]

R_const = 8.31446261815324  

# Conversion factors
atm_to_mpa = 0.101325
kcalmol_to_kjmol = 4.184

bar_to_mpa = 0.1
kelvin_to_kjmol = 0.0083

# Import data
true_data = numpy.loadtxt(true_data_file, skiprows=1)
true_temp_k = true_data[:,0]
true_rho_gcc = true_data[:,1]
true_z = true_data[:,2]
true_u_res = true_data[:,3]
true_zminus1overRho = ( true_z - 1 ) / true_rho_gcc

dsim_data = numpy.loadtxt(dsim_data_file, skiprows=1)
dsim_temp_k = dsim_data[:,0]
dsim_rho_gcc = dsim_data[:,1]
dsim_z = dsim_data[:,2]
dsim_u_res = dsim_data[:,3]
dsim_z_err = dsim_data[:,4]
dsim_u_res_err = dsim_data[:,5]
dsim_Nmolec = dsim_data[:,6]
dsim_zminus1overRho = ( dsim_z - 1 ) / dsim_rho_gcc
#dsim_zminus1overRho_err = dsim_z_err / dsim_rho_gcc

# Obtain weights
z_wt = numpy.loadtxt(weights_file, skiprows=1, usecols=[0])
u_wt = numpy.loadtxt(weights_file, skiprows=1, usecols=[1])
sum_z_wt = numpy.sum(z_wt)
sum_u_wt = numpy.sum(u_wt)
sum_wt = sum_z_wt + sum_u_wt

# Calculate RMSE
z_sse = numpy.sum( (dsim_zminus1overRho - true_zminus1overRho)**2 * z_wt  )   
u_sse = numpy.sum( (dsim_u_res - true_u_res)**2 * u_wt  )   

# Calculate score
total_rmse = numpy.sqrt( (z_sse + u_sse) / sum_wt)
z_rmse = numpy.sqrt(z_sse / sum_z_wt)
u_rmse = numpy.sqrt(u_sse / sum_u_wt)
print(total_rmse, z_rmse, u_rmse)
