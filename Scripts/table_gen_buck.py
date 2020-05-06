import numpy as np
import sys
delr=float(sys.argv[1])
rcut=float(sys.argv[2])
r_cutlow=float(sys.argv[3])
A_coef = float(sys.argv[4])
B_coef = float(sys.argv[5])
C_coef = float(sys.argv[6])

A_coef = 1.0
C_coef = 1.0

nbins=int( (rcut+1)/delr ) + 1

def scientific(x):
    return '{0:1.10e}'.format(x)


for j in range(0,nbins):
    r = delr*j
    if r == 0:
        print(scientific(0),scientific(0), scientific(0), scientific(0), scientific(0), scientific(0), scientific(0))
    elif r <= r_cutlow:
        print(scientific(r),scientific(0), scientific(0), scientific(0), scientific(0), scientific(0), scientific(0))
    else:
        #print(  scientific(r),scientific(1/r), scientific(1/(r*r)), scientific(-1*C_coef/(r**6)), scientific(-6*C_coef/(r**7)), scientific(A_coef*np.exp(-B_coef*r)), scientific(A_coef*B_coef*np.exp(-B_coef*r))     )
        print(  scientific(r),scientific(1/r), scientific(1/(r*r)), scientific(-1/(r**6)), scientific(-6/(r**7)), scientific(np.exp(-B_coef*r)), scientific(B_coef*np.exp(-B_coef*r))     )