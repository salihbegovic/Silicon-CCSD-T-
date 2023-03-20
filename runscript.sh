#!/bin/bash

#Slurm configuration for the VSC4
 
#SBATCH -J interstitials
#SBATCH -N 8
#SBATCH --ntasks-per-node=48
#SBATCH --threads-per-core=1
#SBATCH --ntasks-per-core=1
#SBATCH --partition=mem_0384
##SBATCH --qos=mem_0096
##SBATCH --account=p71035 
##SBATCH --time=2:00:00

#Load modules from modules file, else the modules specified.
[[ -f modules ]] && source modules || {
#	module purge
#	module load intel/19.1.2
#	module load intel-mpi/2019.8
#	module load intel-mkl/2020.2
#	module load cmake/3.15.1-intel-19.1.1.217-nkzxutj
#	module load python/3.6.6-gcc-9.1.0-mkqdc62
#	module load py-pyyaml/3.13-gcc-9.1.0-f4qcohf	
module purge
module load intel-mpi/2021.4.0 mkl/2021.4.0 compiler/2022.0.1
module load cmake/3.15.1-intel-19.1.1.217-nkzxutj
module load python/3.6.6-gcc-9.1.0-mkqdc62
module load py-pyyaml/3.13-gcc-9.1.0-f4qcohf
}

#OMP config
export OMP_NUM_THREADS=1
export MKL_DISABLE_FAST_MM=1

#VSC4 environment variables
ntasks=$SLURM_NTASKS
NTASKS=$SLURM_NTASKS

#Vasp and cc4s executable locations
VASPBIN="/gpfs/data/fs71337/fsalihbe/Si_interstitials-ccsdpt/new_code/importantfiles/vasp_std_new"
CC4SBIN="/gpfs/data/fs71337/fsalihbe/Si_interstitials-ccsdpt/new_code/importantfiles/Cc4s_new"
VASP="mpirun --machinefile machinefile -np 96 $VASPBIN"
CC4S="mpirun --machinefile machinefile -np 96 $CC4SBIN"

#Vasp variables
enc=400
egw=300
NCORE=2

#Number of random kpoints (names the files with .$kpoints at the end)
for kpoints in 1 2 3 4 5 6 7 8 9 10
do

#three random numbers (between 0 and 0.5 with 5 digits of precision)
rand1=`echo "scale=5; $RANDOM/65534" | bc -l`
rand2=`echo "scale=5; $RANDOM/65534" | bc -l`
rand3=`echo "scale=5; $RANDOM/65534" | bc -l`

#Creating the KPOINTS file for vasp
cat >KPOINTS<<!
Automatic mesh
0
Gamma
1 1 1
0$rand1 0$rand2 0$rand3
!

#Read the same kpoints that were used in old calculation (specified in outputold)
#grep -A4 -m$kpoints "Automatic mesh" outputold | tail -5 > KPOINTS

#show kpoints file
cat KPOINTS

#Select the poscars with regex

#only one
#for pos in POSCAR.bulk.16

#all of them
for pos in `ls POSCAR.*.16`
do

#create POSCAR file
cp $pos POSCAR

echo "POSCAR = " $pos

#DFT calculation
[[ -f OUTCAR.DFT.$pos.$kpoints ]] && echo "OUTCAR.DFT.$pos.$kpoints dft done" || {

#Remove WAVECAR from previous calculations
rm WAVECAR

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
EDIFF = 1E-6
ISYM=-1
#NCORE=$NCORE
!
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
cp OUTCAR OUTCAR.DFT.$pos.$kpoints

}

#HF calculation
[[ -f OUTCAR.HF.$pos.$kpoints ]] && echo "OUTCAR.HF.$pos.$kpoints hf done" || {

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
EDIFF = 1E-6
ISYM=-1
LHFCALC=.TRUE.
AEXX=1.0
ALGO=C
NELM=1000
#NCORE=$NCORE
!
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
cp OUTCAR OUTCAR.HF.$pos.$kpoints

}

#Read out the maximum number of plane waves (gamma version of vasp)
##nb=`awk <OUTCAR.HF.$pos.$kpoints "/maximum number of plane-waves:/ { print \\$5*2-1 }"`
#Read out the maximum number of plane waves (std veriosn of vasp)
nb=`awk <OUTCAR.HF.$pos.$kpoints "/maximum number of plane-waves:/ { print \\$5 }"`

echo "going to use $nb bands"

#HF full virtual space
[[ -f OUTCAR.HFdiag.$pos.$kpoints ]] && echo "OUTCAR.HFdiag.$pos.$kpoints hf-diag done" || {

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
EDIFF = 1E-6
ISYM=-1
LHFCALC=.TRUE.
AEXX=1.0
ALGO = sub ; NELM = 1
NBANDS = $nb
#NCORE=$NCORE
!
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
cp OUTCAR OUTCAR.HFdiag.$pos.$kpoints

}

#MP2 calculation
[[ -f OUTCAR.MP2full.$pos.$kpoints ]] && echo "OUTCAR.MP2full.$pos.$kpoints MP2full done" || {

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
LHFCALC=.TRUE.
AEXX=1.0
ISYM=-1
ALGO = MP2 
NBANDS = $nb
LSFACTOR=.TRUE.
!
rm WAVEDER
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
cp OUTCAR OUTCAR.MP2full.$pos.$kpoints

}

#Natural orbitals
[[ -f OUTCAR.MP2NO.$pos.$kpoints ]] && echo "OUTCAR.MP2NO.$pos.$kpoints MP2NO done" || {

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
LHFCALC=.TRUE.
AEXX=1.0
ISYM=-1
ALGO = MP2NO ;
NBANDS = $nb
LAPPROX=.TRUE.
!
rm WAVEDER
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
cp OUTCAR OUTCAR.MP2NO.$pos.$kpoints
cp WAVECAR.FNO WAVECAR.FNO.$pos.$kpoints

}

#choose your (Nv+Nocc)/Nocc
for nbfp in 11
do

echo "for fpX we need " $nbfp
#Transform it to number of bands
nbno=`awk <OUTCAR.MP2NO.$pos.$kpoints "/NELEC/ { print \\$3/2*$nbfp }"`
echo "for fpX we need $nbno  bands"

#HF diagonalization
[[ -f OUTCAR.HFdiag.no.$nbfp.$pos.$kpoints ]] && echo "OUTCAR.HFdiag.no.$nbfp.$pos.$kpoints done" || {

cp WAVECAR.FNO.$pos.$kpoints WAVECAR

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
EDIFF = 1E-6
LHFCALC=.TRUE.
AEXX=1.0
ISYM=-1
ALGO = sub ; NELM = 1
NBANDS = $nbno
NBANDSHIGH = $nbno
!
rm WAVEDER
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
cp OUTCAR OUTCAR.HFdiag.no.$nbfp.$pos.$kpoints

}

#Write out all the data
[[ -f OUTCAR.FTODDUMP.$pos.$kpoints.$nbfp ]] && echo "OUTCAR.FTODDUMP.$pos.$kpoints.$nbfp done" || {

#Create INCAR file
cat >INCAR <<!
ENCUT = $enc
SIGMA=0.0001
EDIFF = 1E-6
LHFCALC=.TRUE.
AEXX=1.0
ISYM=-1
ALGO=CC4S
NBANDS = $nbno
NBANDSHIGH = $nbno
ENCUTGW=$egw
ENCUTGWSOFT=$egw
!
cat INCAR

#Run vasp and and benchmark time
SECONDS=0
$VASP
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

#save output to file
#save output to file
cp OUTCAR OUTCAR.FTODDUMP.$pos.$kpoints.$nbfp

}

#Run cc4s
[[ -f cc4s.out.$pos.$kpoints.$nbfp ]] && echo "cc4s.out.$pos.$kpoints.$nbfp done" || {

echo "Starting cc4s.$pos.$kpoints $nbno"
SECONDS=0
$CC4S -i cc4s.in 2>&1 | tee cc4s.out.$pos.$kpoints.$nbfp
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

}

done

done

done
