declare -a interstitials=("bulk" "C3V" "X" "T" "H" "V")

{

echo "POSCAR KPONTS ORBITALS FORMATION-ENERGY"

for pos in "${interstitials[@]}"
do

#echo "$pos.16"

kpoints=1

refbulk=bulk.16
for name1 in `ls -v  ../HF-kpoints/OUTCAR.HF.POSCAR.$pos.16.*` 
do


#echo $name1
HF=`grep -i "TOTEN  =" $name1 | tail -1 | awk '{print $5}'`
HFbulk=`grep -i "TOTEN  =" ../HF-kpoints/OUTCAR.HF.POSCAR.$refbulk.$kpoints | tail -1 | awk '{print $5}'`

#echo $HF
#echo $HFbulk 

#echo "$kpoints $HF"


orbitals=6


for name in `ls -v cc4s.out.POSCAR.$pos.16.*` 
do

bulkorbitals=$(($orbitals*32))

#echo $name
ccsd=`grep -i "CCSD correlation energy:" $name | tail -1 | awk '{print $4}'`
ccsdT=`grep -i "(T) correlation energy:" $name | tail -1 | awk '{print $4}'`
fsec=`grep -i "Finite-size energy correction:" $name | tail -1 | awk '{print $4}'`
bsec=`grep -i "CCSD-BSIE energy correction" $name | tail -1 | awk '{print $4}'`
Tstar=`echo "scale=19;$ccsdT*($ccsd+$bsec)/$ccsd" | bc`

ccsdbulk=`grep -i "CCSD correlation energy:" cc4s.out.POSCAR.$refbulk.$bulkorbitals | tail -1 | awk '{print $4}'`
ccsdTbulk=`grep -i "(T) correlation energy:" cc4s.out.POSCAR.$refbulk.$bulkorbitals | tail -1 | awk '{print $4}'`
fsecbulk=`grep -i "Finite-size energy correction:" cc4s.out.POSCAR.$refbulk.$bulkorbitals | tail -1 | awk '{print $4}'`
bsecbulk=`grep -i "CCSD-BSIE energy correction" cc4s.out.POSCAR.$refbulk.$bulkorbitals | tail -1 | awk '{print $4}'`
Tstarbulk=`echo "scale=19;$ccsdTbulk*($ccsdbulk+$bsecbulk)/$ccsdbulk" | bc`

printf "$pos\t$kpoints\t$orbitals\t"

if [ "$pos" = "V" ]; then
	echo "scale=19;$HF+$ccsd+$Tstar+$fsec+$bsec-15/16*($HFbulk+$ccsdbulk+$Tstarbulk+$fsecbulk+$bsecbulk)" | bc
else
	echo "scale=19;$HF+$ccsd+$Tstar+$fsec+$bsec-17/16*($HFbulk+$ccsdbulk+$Tstarbulk+$fsecbulk+$bsecbulk)" | bc
fi

orbitals=$(($orbitals+5))

done

kpoints=$(($kpoints+1))

done

done

} | column -t



