mafft --auto JL.fasta > JL.mafft.fasta

trimal -in JL.mafft.fasta -out JL.mafft.trimal.fasta -automated1

modeltest-ng-static -i JL.mafft.trimal.fasta -d nt

iqtree -s JL.mafft.trimal.fasta -pre JL -m TIM2+F+I+G4 -B 1000
