import numpy as np
import sys
import uncertainties as u

from scipy.optimize import least_squares

def objective_function(rmin, sigma, epsilon, alpha):
	return np.absolute(epsilon/(1-(6/alpha))*((6/alpha)*np.exp(alpha-(alpha*sigma/rmin))-(rmin/sigma)**6))

sigma = float(sys.argv[1])
epsilon = float(sys.argv[2])
alpha = float(sys.argv[3])

kelvin_to_kjmol = 0.008314462811444

lb = [sigma]
ub = [10*sigma]
initial_guess = [sigma+0.01]

rmin = least_squares(objective_function, initial_guess, bounds=(lb, ub), method='trf', verbose=0, args=(sigma, epsilon, alpha)).x[0]
#sigma = least_squares(objective_function, initial_guess, bounds=(lb, ub), method='trf', verbose=0, args=(rmin, epsilon, alpha)).x[0]

A_coef = 6*epsilon/(alpha-6)*np.exp(alpha) * kelvin_to_kjmol		# A [kJ/mol] = 6*eps[K]/(alpha-6)*exp(alpha)*0.008314462811444
B_coef = alpha/rmin * 10.0											# B [1/nm] = alpha/rmin[A] * 10
C_coef = epsilon*alpha*rmin**6/(alpha-6) * kelvin_to_kjmol * 1e-6	# C [kJ/mol*nm^6] = eps[K]*alpha*rmin[A]^6/(alpha-6) * 0.008314462811444 / 10^6

print(rmin, A_coef, B_coef, C_coef)