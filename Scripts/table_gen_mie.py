import numpy as np
import sys
delr=float(sys.argv[1])
rcut=float(sys.argv[2])
r_cutlow=float(sys.argv[3])
n_exp=int(sys.argv[4])


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
        print(scientific(r),scientific(1/r), scientific(1/(r*r)), scientific(-1/(r**6)), scientific(-6/(r**7)), scientific(1/(r**n_exp)), scientific(n_exp/(r**(n_exp+1))))