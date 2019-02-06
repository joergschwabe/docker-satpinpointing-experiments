#!/usr/bin/env Rscript


#library(tikzDevice)
#tikz(file="plot-results.tex", width=5, height=5)


transform.proportions = function(x, from, to) {
	base = 1 + 1/(to - 1)
	base ^ (x / from) * from
}

from.prop = 10
to.prop = 5

xtrans = function(x) {
	transform.proportions(x, from.prop, to.prop)
}


column <- "time"
timeout <- 60
#xlim <- c(xtrans(0),xtrans(100))
xlim <- NULL
ylim <- c(0.001,timeout)
mergeBy <- "query"

cut.timeout = function(x) {
	sapply(x, function(e) min(e,timeout))
}


args <- commandArgs(TRUE)

requiredArgCount <- 3
if(length(args) < requiredArgCount) {
	cat(sprintf("Expected %d arguments!\n", requiredArgCount))
	q(status=1)
}


xvalues = list()
yvalues = list()
colors = list()

argIndex <- 1
title <- args[argIndex]

argIndex <- argIndex + 1
legend <- args[argIndex]
argIndex <- argIndex + 1
X <- read.csv(args[argIndex])

dataIndex <- 1
names(X) <- paste0(names(X), ".", dataIndex)
M <- X

while (argIndex + 1 < length(args)) {
	argIndex <- argIndex + 1
	legend <- c(legend, args[argIndex])
	argIndex <- argIndex + 1
	X <- read.csv(args[argIndex])

	dataIndex <- dataIndex + 1
	names(X) <- paste0(names(X), ".", dataIndex)
	M <- merge(M, X, by.x=paste0(mergeBy, ".1"), by.y=paste0(mergeBy, ".", dataIndex))
}

min.na.rm <- function(...) {
	min(..., na.rm=TRUE)
}
M[[column]] <- apply(M[,paste0(column, ".", seq(dataIndex))], 1, min.na.rm)
data <- M[[column]]
timeOrder <- order(data)
step <- 100 / length(data)
xvalues <- seq(step, 100, step)
plot(xtrans(xvalues), cut.timeout(data[timeOrder] / 1000), type="l", log="y", axes=FALSE, main=title, xlab="\\% of queries", ylab="time in seconds", xlim=xlim, ylim=ylim)
xticks = seq(0, 100, 10)
axis(1, at=xtrans(xticks), labels=xticks)
yticks = c(0.001, 0.01, 0.1, 1, 10, 60, 100)
ylabels = c("0.001", "0.01", "0.1", "1", "10", "60", "100")
axis(2, at=yticks, labels=ylabels)
abline(h=yticks, v=xtrans(xticks), col="lightgray", lty=3)
box()

colorIndex <- 2
legendStyle <- c()
for (i in seq(dataIndex)) {
	data <- M[[paste0(column, ".", i)]]
	timeOrder <- order(data)
	step <- 100 / length(data)
	xvalues <- seq(step, 100, step)
	lines(xtrans(xvalues), cut.timeout(data[timeOrder] / 1000), col=colorIndex, lty=colorIndex)

	legendStyle <- c(legendStyle, colorIndex)
	colorIndex <- colorIndex + 1
}

legend <- c(legend, "minimal")
legendStyle <- c(legendStyle, 1)
legend(xtrans(0), ylim[2], legend, col=legendStyle, lty=legendStyle, bg="white")


dev.off()

