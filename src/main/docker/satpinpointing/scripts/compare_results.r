#!/usr/bin/env Rscript


mergeBy <- "query"
selectedColumns <- c("didTimeOut","time","nJust")
mergedSelectedColumns <- c(mergeBy, paste0(selectedColumns, ".x"), paste0(selectedColumns, ".y"))


args <- commandArgs(TRUE)

requiredArgCount = 2
if(length(args) < requiredArgCount) {
	cat(sprintf("Expected %d arguments!\n", requiredArgCount))
	q(status=1)
}


X <- read.csv(args[1])
Y <- read.csv(args[2])

cat("\n")
cat("X:", args[1], "\n")
cat("number of records:", length(X[[mergeBy]]), "\n")
summary(X[, selectedColumns])

cat("\n")
cat("Y:", args[2], "\n")
cat("number of records:", length(Y[[mergeBy]]), "\n")
summary(Y[, selectedColumns])


M <- merge(X, Y, by=mergeBy)


xTimedOut <- M$didTimeOut.x & !M$didTimeOut.y

cat("\n")
cat("X timed out and Y did not:\n")
if(max(xTimedOut)) {
	result <- M[xTimedOut, mergedSelectedColumns]
	cat("count:", length(result[[mergeBy]]), "\n")
	print(result)
} else {
	cat("Never\n")
}


yTimedOut <- M$didTimeOut.y & !M$didTimeOut.x

cat("\n")
cat("Y timed out and X did not:\n")
if(max(yTimedOut)) {
	result <- M[yTimedOut, mergedSelectedColumns]
	cat("count:", length(result[[mergeBy]]), "\n")
	print(result)
} else {
	cat("Never\n")
}


diff.nJust <- M$nJust.x != M$nJust.y & !M$didTimeOut.x & !M$didTimeOut.y

cat("\n")
cat("different number of justifications:\n")
if(max(diff.nJust)) {
	result <- M[diff.nJust, mergedSelectedColumns]
	cat("count:", length(result[[mergeBy]]), "\n")
	print(result)
} else {
	cat("No difference.\n")
}

