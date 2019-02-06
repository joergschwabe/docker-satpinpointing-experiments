#!/usr/bin/env Rscript

timeCol = "time"

args <- commandArgs(TRUE)
requiredArgCount = 1
if(length(args) < requiredArgCount) {
	cat(sprintf("Expected %d arguments!\n", requiredArgCount))
	q(status=1)
}

X <- read.csv(args[1])

result = ceiling(sum(X[[timeCol]]) / 1000.0)

cat(sprintf("%d\n", result))

