#!/usr/bin/env python

import sys
import os

gcipath = sys.argv[1]
ripath = sys.argv[2]
modulepath = sys.argv[3]
name = sys.argv[4]
outpath = sys.argv[5]


command = "cat " + gcipath + " " + ripath + " > auxgcis"
os.system(command)

for line in open(modulepath):
	tokens = line.split();
	axioms = tokens[:-1]


#print axioms

ontologyname = outpath + "/" + name + ".krss"
f = open(ontologyname, 'w')

index = 1;
axmap = {}
for a in axioms:
	#print a
	command = "grep \"^" + a + " \" auxgcis  > auxfilegrep";
	#print command
	
	os.system(command)

        nlines = 0;
	for line in open("auxfilegrep"):
		nlines += 1

	for line in open("auxfilegrep"):
		tokens = line.split()
		axmap[a] = index;
		
		if(nlines == 2):
			tokens[1] = "(equivalent";

		result = ""
		for t in tokens[1:]:
			result += str(t) + " "
		f.write(result + "\n");
		axmap[a] = [index, result]
		if(nlines == 2):
			break;
	

	index += 1;

f.close()

mapname = outpath + "/" + name + ".map"
f = open(mapname, 'w')
for a in axioms:
	result = str(axmap[a][0]) + " " + str(a) + " " + str(axmap[a][1]) +  "\n"
	f.write(result)
f.close();

os.system("rm auxgcis auxfilegrep")

