
 EL2MUS/HgMUS: Efficient SAT-Based Axiom Pinpointing in EL+
-------------------------------------------------------------

The distribution folder contains the following directories/files:

1) hgmus/
  - Binary executable of the Horn group-MUS enumerator HgMUS (Linux-64bit)

2) tools/
  - Some "internal" scripts
  - It is necessary to copy el+sat tools here (see below)

3) scripts/
  - Scripts for classifying an EL+ ontology and generating subsumption query instances for el2mcs (with different optimizations)

4) example/
  - files with an example



++++++++++++++++++++++++++ EL2MUS/HgMUS USAGE ++++++++++++++++++++++++++++++++++++++

EL2MUS integrates a state-of-the-art group-MUS enumeration tool, named HgMUS[1].

In order to solve axiom pinpointing problems in EL+, it is necessary to first generate 
a wcnf formula encoding the problem instance (see below). Then, HgMUS is called on this formula for solving the problem.


 + hgmus usage:
	usage: HgMUS [ <option> ... ] <input> 
        where <option> is one of the following:
            -h         prints this help and exits
            -T   TTT   specify timeout [default: -T 3600]
            -st        compute and print stats
            -nw        do not write MUSes [default: off]
            -wmcs      write MCSes [default: off]
            -rcpu      report CPU time with MUSes/MCSes [default: off]
            -nmus NNN  limit number of MUSes to NNN=0(all),1,... [default: 0]
            -nmcs NNN  limit number of MCSes to NNN=0(all),1,... [default: 0]

        and <input> is a WCNF file

 HgMUS is based on implicit hitting set dualization MUS enumeration (e.g. [4,5,6]). So, it enumerates Minimal Correction Subsets (MCSes) and Minimal Unsatisfiable Subformulas (MUSes) in an arbitrary order.

 MCSes correspond to minimal repairs of an EL+ ontology w.r.t. a given subsumption relation. These are printed on stdout each one in a line starting by "c MCS: ".

 MUSes correspond to minimal axiom sets (minAs) w.r.t. a given subsumption relation. These are printed on stdout each one in a  line starting by "c MUS: ".

Both MCSes and MUSes are sequences of numbers, where each number corresponds to an index identifier of either an original GCI or an original RI.



++++++++++++++ GENERATING AXIOM PINPOINTING WCNF QUERY INSTANCES (4 steps) +++++++++++++++


STEP 1. Download EL+SAT tools [2,3]
   - [Step 1 is to be taken only once]

   - Available on http://disi.unitn.it/~rseba/elsat/

   - Copy the two 64-bit executables el2sat_all and el2sat_all_mina into tools/

   - Copyright note: EL+SAT is property of M. Vescovi and R. Sebastiani

 
STEP 2. Encode the classification of an ontology

   - [Step 2 only needs to be taken once for each ontology]

   - Run script/gen-sat-enc
      + usage: ./gen-sat-enc <name> <ontology-file> <output_dir> <tools-dir>
        with <name>: user defined name prefix for the classification files
             <ontology-file>: path to the ontology file (KRSS format)
             <output-dir>: path to the directory for the classification files 
             <tools-dir>: path to /tools  

   - Note: gen-sat-enc invokes el2sat_all[2,3].

 Example:
 --------

  Given the following ontology file ./ontologies/med-example.krss: 

   ********************** med-example.krss **********************************************
    (define-primitive-concept Endocarditis (and Inflammation (some hasLoc Endocardium)))
    (define-primitive-concept Inflammation (and Disease (some actsOn Tissue)))
    (define-primitive-concept Endocardium (and Tissue (some contIn HeartValve)))
    (define-primitive-concept HeartValve  (some contIn Heart))
    (define-concept HeartDisease (and Disease (some hasLoc Heart)))
   **************************************************************************************


  We execute the following command

    ./scripts/get-sat-enc med ontologies/med-example.krss med/class ./tools
 
  As a result, the directory med/class is created, containing the following files:
    - med.assumptions  
    - med.cnf  
    - med.h  
    - med.ppp  
    - med.ppp.g.u  
    - med.zzz
    - med.zzz.gci
    - med.zzz.map  
    - med.zzz.ri

  For user's purposes, the interesting files are the following *.zzz* ones.

   - mez.zzz.gci contains the orinigal GCI axioms, each one with a corresponding index

    ********************** med/class/med.zzz.gci *******************************
     1 (implies Endocarditis (and Inflammation (some hasLoc Endocardium)) )
     2 (implies Inflammation (and Disease (some actsOn Tissue)) )
     3 (implies Endocardium (and Tissue (some contIn HeartValve)) )
     4 (implies HeartValve (some contIn Heart) )
     5 (implies HeartDisease (and Disease (some hasLoc Heart)) )
     5 (implies (and Disease (some hasLoc Heart)) HeartDisease )
    ****************************************************************************

    Note that equivalences are split into two GCIs sharing the same index (e.g. 5 above)

 
   - mez.zzz.ri contains the orinigal RI axioms, each one with a corresponding index

    ********************** med/class/med.zzz.ri *******************************
     6 (transitive contIn)
     7 (role-inclusion (compose hasLoc contIn) hasLoc)
    ****************************************************************************


   - mez.zzz: contains the normalized and inferred axioms after classification, 
              each one with a corresponding index.

    *********************** med/class/med.zzz *******************************
      8 (implies Endocarditis Inflammation )
      9 (implies Inflammation Disease )
     10 (implies Endocardium Tissue )
     11 (implies HeartDisease Disease )
     12 (implies Endocarditis (some hasLoc Endocardium) )
     13 (implies Inflammation (some actsOn Tissue) )
     14 (implies Endocardium (some contIn HeartValve) )
     15 (implies HeartValve (some contIn Heart) )
     16 (implies HeartDisease (some hasLoc Heart) )
     17 (implies (and Disease #19) HeartDisease )
     18 (implies (some hasLoc Heart) #19 )
     19 (implies Endocarditis Disease )
     20 (implies Endocarditis (some actsOn Tissue) )
     21 (implies Endocarditis (some hasLoc HeartValve) )
     22 (implies Endocardium (some contIn Heart) )
     23 (implies HeartDisease #19 )
     24 (implies Endocarditis (some hasLoc Heart) )
     25 (implies Endocarditis #19 )
     26 (implies Endocarditis HeartDisease )
    ****************************************************************************

  Note that normalization created a new primitive concept name, "#19"



STEP 3. Create a query file with axiom pinpointing queries before generating wcnf instances

  - [ Step 3 needs to be taken once for each query (or set of queries) ]

  - The file must contain one index per line, corresponding to a subsumption relation in the file "<name>.zzz". This will allow for generating one wcnf instance per query.


  Example:
  --------
  
  Suppose one wants to get justifications for the inferred subsumption relations:
     22 (implies Endocardium (some contIn Heart) ) and
     26 (implies Endocarditis HeartDisease )

  Then, it is necessary to create a file (e.g. med/queries.q) like this:

   ************** med/queries.q ********************************
   22
   26
   *************************************************************


   For this, it is enough to do:
     > echo 22 > med/queries.q
     > echo 26 >> med/queries.q



STEP 4: Generate WCNF instances

   - [Step 4 needs to be taken once for each query (or set of queries) and optimization]

   - Run script/create-wcnf
      + usage: create-wcnf <name> <class-dir> <query-file> <output-dir> <tools-dir> opt

        with <name>: user defined name prefix for the classification files
             <class-dir>: path to directory containing the classification files (see step 2)
             <query-file>: path to the querie file (see step 3)
             <output-path>: path to the directory for the wcnf instances
             <tools-dir>: path to /tools 
             <opt>: no-opt | coi | x2
                 - no-opt: no optimizations
                 - coi: perform Cone-Of-Influence modularization
                 - x2: perform COI, extract the module, reclassify it and perform COI again
		   

   - Note: create-wcnf invokes el2sat_all and el2sat_all_mina[2,3].


 Example
 --------

  Let's create WCNF files for the queries specified in med/queries.q
  
  A) Without any optimizations:
  
     ./scripts/create-wcnf med med/class med/queries.q med/nop tools/ no-opt

     As a result, the folder med/nop is created, containing 2 files:
       - med.22.wcnf: wcnf file to be fed to hgmus, corresponding to query
          22 (implies Endocardium (some contIn Heart) )

       - med.26.wcnf: wcnf file to be fed to hgmus, corresponding to query
          26 (implies Endocarditis HeartDisease )

   B) With the COI optimization

     ./scripts/create-wcnf med med/class med/queries.q med/coi tools/ coi

     As a result, the folder med/coi is created, containing:
       - med.22.coi.wcnf: wcnf file to be fed to hgmus, corresponding to query 22
       - med.22.module.axioms: COI module for query 22 (axioms that may take part in some justifications)
       - med.26.coi.wcnf: wcnf file to be fed to hgmus, corresponding to query 26
       - med.26.module.axioms: COI module for query 26 (axioms that may take part in some justifications)


   3) With the x2 optimization

      ./scripts/create-wcnf med med/class med/queries.q med/x2 tools/ x2
 
       As a result, the folder med/x2 is created, containing:
       - med.22.x2.wcnf: wcnf file to be fed to hgmus, corresponding to query 22
       - med.22.krss: file with the subontology for query 22
       - med.22.x2.map: list of GCIs and RIs that may be involved in some justifications with their new and original indices (in med/class/med.zzz.gci and med/class/med.zzz.ri)

         ************** med/x2/ *******************************************
          1 3 (implies Endocardium (and Tissue (some contIn HeartValve)) ) 
          2 4 (implies HeartValve (some contIn Heart) ) 
          3 6 (transitive contIn)
         ******************************************************************
             
        HgMUS will print MCSes and MUSes as lists of indices from the first column.
          

       - med.26.x2.wcnf: wcnf file to be fed to hgmus, corresponding to query 26
       - med.26.module.axioms: COI module for query 26 (axioms that may take part in some justifications)
  
  
  Note: HgMUS performs best with the x2 optimization.

  Note: For queries on axioms with new primitive concept names, coi and x2 may not work properly. Thus, it is recommended not to perform any optimizations in these cases. These axioms are the result of the normalization process, and so axiom pinpointing is expected to be very efficient even without optimizations.




++++++++++++++++++++++++ RUNNING THE EXAMPLE WCNF WITH HgMUS ++++++++++++++++++++++++++++++++

  To finish the example, we show how to solve the axiom pinpointing wcnf instance with hgmus: 22 (implies Endocardium (some contIn Heart) )

  With both no optimizations and coi we interpret the output in the same way:

   ./hgmus -wcms med/nop/med.22.wcnf
    
    (or ./hgmus -wmcs med/coi/med.22.coi.wcnf)

    Note the option -wmcs is provided so that MCSes are written (this is optional)

    ******************** hgmus output ********************************
    c *** HgMUS: Group-MUS Enumeration of Horn Formulae ***
    c 
    c *** instance: ../example/med/nop/med.22.wcnf ***
    c 
    c Parsing ...
    c Parsing CPU Time: 0
    c 
    c Running HgMUS ...
    c MUS: 3 4 6 
    c MCS: 6 
    c MCS: 3 
    c MCS: 4 
    c 
    c Number of MCSes: 3
    c Number of MUSes: 1
    c 
    c Terminating HgMUS ...
    c CPU Time: 0
    ******************************************************************

   
    There are 3 MCSes (minimal repairs) and 1 MUS (minA). 
    The MUS is {3,4,6}, which looking at the classification files med/class/med.zzz.gci and med/class/med.zzz.gci, corresponds to the axioms:

        3 (implies Endocardium (and Tissue (some contIn HeartValve)) )
        4 (implies HeartValve (some contIn Heart) )
        6 (transitive contIn)



  With the x2 optimization we get the same MCSes and MUSes, but with different indices

    ./hgmus -wmcs med/x2/med.22.x2.wcnf

    ******************** el2mcs output (x2) **************************
    c *** HgMUS: Group-MUS Enumeration of Horn Formulae ***
    c 
    c *** instance: ../example/med/x2/med.22.x2.wcnf ***
    c 
    c Parsing ...
    c Parsing CPU Time: 0
    c 
    c Running HgMUS ...
    c MUS: 1 2 3 
    c MCS: 3 
    c MCS: 1 
    c MCS: 2 
    c 
    c Number of MCSes: 3
    c Number of MUSes: 1
    c 
    c Terminating HgMUS ...
    c CPU Time: 0
    ******************************************************************

   In this case, we get the same MCSes and MUSes. To check this, we look at the file
    med/x2/x2.22.map and observe that the MUS {3,2,1} corresponds to the axioms:

        1 3 (implies Endocardium (and Tissue (some contIn HeartValve)) )
        2 4 (implies HeartValve (some contIn Heart) ) 
        3 6 (transitive contIn)
          
          



++++++++++++++++++++ FURTHER NOTES ++++++++++++++++++++++++++
 
 Regarding the instances used in our experiments, the following ontologies are available on (http://wwwtcs.inf.tu-dresden.de/~meng/toyont.html)  
    - FULL-GALEN ontology
    - NOT-GALEN onotology
    - NCI ontology
    - GENE ontology
   
  - SNOMED ontology is available from HTSDO under non-disclosure agreement.




Refereces
---------
 
[1] M. Fareed Arif, Carlos Mencia, and Joao Marques-Silva. "Efficient MUS Enumeration of Horn Formulae with Applications to Axiom Pinpointing". SAT 2015

[2] Roberto Sebastiani, Michele Vescovi. "Axiom Pinpointing in Lightweight Description Logics via Horn-SAT Encoding and Conflict Analysis". CADE 2009.

[3] Roberto Sebastiani, Michele Vescovi. "Axiom pinpointing in large EL+ ontologies via SAT and SMT techniques". Technical Report DISI-15-010, DISI, University of Trento, Italy, April 2015. Under Journal Submission. http://disi.unitn.it/rseba/elsat/elsat_techrep.pdf

[4] Alessandro Previti, Joao Marques-Silva. Partial MUS enumeration". AAAI 2013

[5] Liffiton, M.H., Malik, A.: "Enumerating infeasibility: finding multiple MUSes quickly". CPAIOR 2013.

[6] Liffiton, M.H., Previti, A., Malik, A., Marques-Silva, J.: "Fast, flexible MUS enumeration". Constraints (2015).


****** END **********

