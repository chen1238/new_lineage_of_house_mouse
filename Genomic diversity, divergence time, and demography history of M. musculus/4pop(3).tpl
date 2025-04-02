//Parameters for the coalescence simulation program : fastsimcoal.exe
5
//Population effective sizes (number of genes=2*NumIndividuals): 
NCAS1
NCAS2
NDOM
NGR
NMUS
//Samples sizes and samples age
12
12
12
12
12
//Growth rates  : negative growth implies population expansion
0
0
0
0
0
//Number of migration matrices : 0 implies no migration between demes
0
//historical event: time, source, sink, migrants, new deme size, new growth rate, migration mat$
4 historical event
TDIV1 1 0 1 1 0 0
TDIV2 4 0 1 1 0 0
TDIV3 3 0 1 1 0 0
TDIV4 2 0 1 1 0 0
//Number of independent loci [chromosome]
1 0
//Per chromosome: Number of contiguous linkage Block: a block is a set of contiguous loci
1
//per Block:data type, number of loci, per generation recombination and mutation rates and opti$
FREQ 1 0 4.1e-9 OUTEXP
