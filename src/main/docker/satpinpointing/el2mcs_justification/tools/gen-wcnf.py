#!/usr/bin/env python
import sys

name = sys.argv[1]
cnf_path = sys.argv[2]
assump_path = sys.argv[3]
query = sys.argv[4]
opt = sys.argv[5]

top_var = 0
nclauses = 0
naxioms = 0

# count number of clauses and determine top var
for line in open(cnf_path):
	nclauses += 1
	tokens = line.split();
	for t in tokens[:-1]:
		var = abs(int(t))
		if var > top_var:
			top_var = var

# count number of assumptions and store them
assumptions = []
if opt == "no-opt":
	for line in open(assump_path):
		naxioms += 1
		tokens = line.split()
		assumptions.append(tokens[0])		

elif opt == "coi":
	for line in open(assump_path):
		tokens = line.split()
		naxioms = len(tokens)-1
		for t in tokens[:-1]:
			assumptions.append(t)
		break;

# print wcnf file
header = "p wcnf " + str(top_var) + " " + str(nclauses+naxioms+1) + " " + str(top_var+1);
print header

for line in open(cnf_path):
	tokens = line.split()
	output = str(top_var+1)
	for t in tokens:
		output += " " + t
	print output


print str(top_var+1) + " -" + str(query)  + " 0"

for a in assumptions:
	print "1 " + a + " 0"









