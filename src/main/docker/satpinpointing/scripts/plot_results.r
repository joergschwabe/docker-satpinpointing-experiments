#!/usr/bin/env Rscript


#library(tikzDevice)
#tikz(file="plot-results.tex", width=5, height=5)


column <- "time"
xlim <- c(0,100)
ylim <- c(0.001,100)
mergeBy <- "query"


args <- commandArgs(TRUE)

requiredArgCount <- 3
if(length(args) < requiredArgCount) {
	cat(sprintf("Expected %d arguments!\n", requiredArgCount))
	q(status=1)
}


xvalues = list()
yvalues = list()
colors = list()

title <- args[1]
argIndex <- 2
legend <- args[argIndex]
argIndex <- argIndex + 1
X <- read.csv(args[argIndex])

dataIndex <- 1
step <- 100 / length(X[[column]])
xvalues[[dataIndex]] <- seq(step, 100, step)
timeOrder <- order(X[[column]])
yvalues[[dataIndex]] <- X[[column]][timeOrder] / 1000
colorIndex <- 2
colors[[dataIndex]] <- colorIndex
legendStyle <- colorIndex

names(X) <- paste0(names(X), ".", dataIndex)
M <- X

while (argIndex + 1 < length(args)) {
	argIndex <- argIndex + 1
	legend <- c(legend, args[argIndex])
	argIndex <- argIndex + 1
	X <- read.csv(args[argIndex])

	dataIndex <- dataIndex + 1
	step <- 100 / length(X[[column]])
	xvalues[[dataIndex]] <- seq(step, 100, step)
	timeOrder <- order(X[[column]])
	yvalues[[dataIndex]] <- X[[column]][timeOrder] / 1000
	colorIndex <- colorIndex + 1
	colors[[dataIndex]] <- colorIndex
	legendStyle <- c(legendStyle, colorIndex)

	names(X) <- paste0(names(X), ".", dataIndex)
	M <- merge(M, X, all=TRUE, by.x=paste0(mergeBy, ".1"), by.y=paste0(mergeBy, ".", dataIndex))

}


min.na.rm <- function(...) {
	min(..., na.rm=TRUE)
}
M[[column]] <- apply(M[,paste0(column, ".", seq(dataIndex))], 1, min.na.rm)
timeOrder <- order(M[[column]])
step <- 100 / length(M[[column]])
plot(seq(step, 100, step), M[[column]][timeOrder] / 1000, type="l", col=1, lty=1, log="y", main=title, xlab="\\% of queries", ylab="time in seconds", xlim=xlim, ylim=ylim)


for (i in 1:length(xvalues)) {
	lines(xvalues[[i]], yvalues[[i]], col=colors[[i]], lty=colors[[i]])
}


legend <- c(legend, "minimal")
legendStyle <- c(legendStyle, 1)
legend(xlim[1], ylim[2], legend, col=legendStyle, lty=legendStyle)


dev.off()

