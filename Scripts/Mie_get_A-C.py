import numpy as np
import sys
import uncertainties as u

from scipy.optimize import least_squares

def objective_function(rmin, sigma, epsilon, alpha):
	return np.absolute(epsilon/(1-(6/alpha))*((6/alpha)*np.exp(alpha-(alpha*sigma/rmin))-(rmin/sigma)**6))

sigma = float(sys.argv[1])
epsilon = float(sys.argv[2])
n_exp = float(sys.argv[3])

kelvin_to_kjmol = 0.008314462811444

lb = [sigma]
ub = [10*sigma]
initial_guess = [sigma+0.01]

Cn = (n_exp/(n_exp-6))*(n_exp/6)**(6/(n_exp-6))

epsilon_kjmol = epsilon * kelvin_to_kjmol
sigma_nm = sigma * 0.1


C_coef = Cn*epsilon_kjmol*sigma_nm**6
A_coef = Cn*epsilon_kjmol*sigma_nm**n_exp

print(C_coef, A_coef)