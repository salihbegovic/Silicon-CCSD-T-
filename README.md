# Silicon-CCSD-T
This repository contains all the necessary files to calculate the CCSD(T) formation energies of silicon.

runscript.sh contains the whole workflow described in the Paper.
You only need to change the VASPBIN and CC4SBIN in the runscript.sh, as well as the VASP and CC4S varibles.

The kpoint loop can be commented on and off.
I highly recommend to save the output of every calculation.
Thers is the option to repeat a specific kpoint calculation in case of failure.

What exactly the runscript.sh does is described in the paper under section Numerical Details.
