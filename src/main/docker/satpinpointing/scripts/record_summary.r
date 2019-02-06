#!/usr/bin/env Rscript

queryCol = "query"
timeoutCol = "didTimeOut"

args <- commandArgs(TRUE)
requiredArgCount = 1
if(length(args) < requiredArgCount) {
	cat(sprintf("Expected %d arguments!\n", requiredArgCount))
	q(status=1)
}

X <- read.csv(args[1])

nRecords = length(X[[queryCol]])
nTimeouts = sum(X[[timeoutCol]])

cat(args[1], "\n")
cat(sprintf("#records: %d, #timeouts: %d, %%timeouts: %f\n", nRecords, nTimeouts, nTimeouts / nRecords * 100))

