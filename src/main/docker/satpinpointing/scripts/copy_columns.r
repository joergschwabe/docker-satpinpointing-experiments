#!/usr/bin/env Rscript


args <- commandArgs(TRUE)

requiredArgCount <- 4
if(length(args) < requiredArgCount) {
	cat(sprintf("Expected %d arguments!\n", requiredArgCount))
	q(status=1)
}

inputFile <- args[1]
idColumn <- args[2]
newColumnName <- args[3]
columns <- args[4:length(args)]



X <- read.csv(inputFile)

columnIndex = 1
while (columnIndex <= length(columns)) {
	result = list()
	result[[idColumn]] = X[[idColumn]]
	result[[newColumnName]] = X[[columns[columnIndex]]]
	write.csv(data.frame(result), file=paste0(inputFile, ".", columns[columnIndex]), row.names=FALSE, na="\"\"")
	columnIndex = columnIndex + 1
}

