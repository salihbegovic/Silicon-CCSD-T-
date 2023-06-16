declare -a interstitials=("bulk" "C3V" "X" "T" "H" "V")

{

for pos in "${interstitials[@]}"
do

echo "$pos.16	CCSD	CCSD(T)			FiniteSize	BasisSet"

orbitals=1

for name in `ls -v cc4s.out.POSCAR.$pos.16.*` 
do

#echo $name
ccsd=`grep -i "CCSD correlation energy:" $name | tail -1 | awk '{print $4}'`
ccsdT=`grep -i "(T) correlation energy:" $name | tail -1 | awk '{print $4}'`
fsec=`grep -i "Finite-size energy correction:" $name | tail -1 | awk '{print $4}'`
bsec=`grep -i "CCSD-BSIE energy correction" $name | tail -1 | awk '{print $4}'`
orbitals=$(($orbitals+5))

echo "$orbitals	$ccsd $ccsdT $fsec $bsec"


done

done

} | column -t




#declare -a interstitials=("bulk" "C3V" "X" "T" "H" "V")
#
#{
#
#for pos in "${interstitials[@]}"
#do
#
#echo $pos
#
#orbitals=1
#
#for name in `ls -v  OUTCAR.HF.POSCAR.$pos.16.*`
#do
#
##echo $name
#HF=`grep -i "TOTEN  =" $name | tail -1 | awk '{print $5}'`
#
#echo "$HF"
#
#done
#
#done
#
#} | column -t
#
