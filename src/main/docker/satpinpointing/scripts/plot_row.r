#!/usr/bin/env Rscript


plot.results = function(
		args,
		isFirst=TRUE,
		main=NULL,
		column="time",
		mergeBy="query",
		timeout=60,
		xlim=NULL,
		ylim=c(0.001,timeout),
		from.prop=15,
		to.prop=2,
		pixels.in.plot.size=NULL,
		xlab="\\% of queries",
		ylab="time in seconds",
		colors=c("red", "green3", "blue", "magenta"),
		lineTypes=c("44", "1343", "73", "2262")) {

	transform.proportions = function(x, from, to) {
		base = 1 + 1/(to - 1)
		base ^ (x / from) * from
	}

	xtrans = function(x) {
		transform.proportions(x, from.prop, to.prop)
	}


	max.xvalue = 100
	#xlim <- c(xtrans(0),xtrans(max.xvalue))

	cut.timeout = function(x) {
		sapply(x, function(e) min(e,timeout))
	}


	min.x.interval = -Inf
	if (!is.null(pixels.in.plot.size)) {
		min.x.interval = max.xvalue / pixels.in.plot.size
	}
	reduce.data = function(x, y) {
		if (length(x) != length(y)) {
			stop("x and y has differet length!")
		}
		xIndex = 1
		newX = x[xIndex]
		newY = y[xIndex]
		lastNewX = x[xIndex]
		xIndex = xIndex + 1
		while (xIndex <= length(x)) {
			if (x[xIndex] - lastNewX >= min.x.interval) {
				newX = c(newX, x[xIndex])
				newY = c(newY, y[xIndex])
				lastNewX = x[xIndex]
			}
			xIndex = xIndex + 1
		}
		return(list(x=newX, y=newY))
	}


	xvalues = list()
	yvalues = list()

	argIndex <- 1
	X <- read.csv(args[argIndex])

	dataIndex <- 1
	names(X) <- paste0(names(X), ".", dataIndex)
	M <- X

	while (argIndex < length(args)) {
		argIndex <- argIndex + 1
		X <- read.csv(args[argIndex])

		dataIndex <- dataIndex + 1
		names(X) <- paste0(names(X), ".", dataIndex)
		M <- merge(M, X, by.x=paste0(mergeBy, ".1"), by.y=paste0(mergeBy, ".", dataIndex))
	}

	par(mar=c(0, 0, 0, 0))
	par(mgp=c(-2.2, -1, 0))

	M[[column]] <- apply(M[,paste0(column, ".", seq(dataIndex))], 1, function(x) min(x, na.rm=TRUE))
	data <- M[[column]]
	data <- data[order(data)]
	step <- max.xvalue / length(data)
	xvalues <- seq(step, max.xvalue, step)
	xvalues <- xtrans(xvalues)
	reduced.data <- reduce.data(xvalues, data)
	if (length(reduced.data$y) < length(data)) {
		cat(sprintf("data length reduced from %d to %d\n", length(data), length(reduced.data$y)))
	}
	plot(reduced.data$x, cut.timeout(reduced.data$y / 1000),
			type="l", log="y", axes=FALSE,
			xlab="", ylab="", xlim=xlim, ylim=ylim)
	xticks = seq(0, max.xvalue, 10)
	axis(1, at=xtrans(xticks), labels=xticks, lty=0)
	yticks = c(0.001, 0.01, 0.1, 1, 10, 60, 100)
	ylabels = c("", "0.01", "0.1", "1", "10", "60", "100")
	axis(2, at=yticks, labels=ylabels, lty=0)
	abline(h=yticks, v=xtrans(xticks), col="gray", lty=3)
	box()
	title(main=main, line=-2)
	title(xlab=xlab, line=-2.2)
	title(ylab=ylab, line=-2.2, adj=0.8)

	colorIndex <- 1
	for (i in seq(dataIndex)) {
		data <- M[[paste0(column, ".", i)]]
		data <- data[order(data)]
		step <- max.xvalue / length(data)
		xvalues <- seq(step, max.xvalue, step)
		xvalues <- xtrans(xvalues)
		reduced.data <- reduce.data(xvalues, data)
		if (length(reduced.data$y) < length(data)) {
			cat(sprintf("data length reduced from %d to %d\n", length(data), length(reduced.data$y)))
		}
		lines(reduced.data$x, cut.timeout(reduced.data$y / 1000),
				col=rep(colors, length.out=colorIndex)[colorIndex],
				lty=rep(lineTypes, length.out=colorIndex)[colorIndex],
				lwd=2)

		colorIndex <- colorIndex + 1
	}

}


separator = "--"

args <- commandArgs(TRUE)

argIndex <- 1

arg = args[argIndex]
argIndex = argIndex + 1
plot.filename=arg

titles = c()
while (argIndex <= length(args)) {
	arg = args[argIndex]
	argIndex = argIndex + 1
	if (arg == separator) {
		break
	}
	titles = c(titles, arg)
}

if (argIndex >= length(args)) {
	cat(sprintf("Missing data arguments!\n"))
	q(status=1)
}
arg = args[argIndex]
argIndex = argIndex + 1
legends = arg
arg = args[argIndex]
argIndex = argIndex + 1
if (!file.exists(arg)) {
	cat(sprintf("Legend wuthout data file: %s\n", arg))
	q(status=1)
}
fileArray = c()
files = arg
while (argIndex <= length(args)) {
	arg = args[argIndex]
	argIndex = argIndex + 1
	if (length(files) < length(titles)) {
		if (!file.exists(arg)) {
			cat(sprintf("Legend wuthout data file: %s\n", arg))
			q(status=1)
		}
		files = c(files, arg)
	} else {
		if (length(files) != length(titles)) {
			cat(sprintf("Wrong number of data files for legend: %s\n", legends[length(legends)]))
			q(status=1)
		}
		legends = c(legends, arg)
		arg = args[argIndex]
		argIndex = argIndex + 1
		if (!file.exists(arg)) {
			cat(sprintf("Legend wuthout data file: %s\n", arg))
			q(status=1)
		}
		fileArray = cbind(fileArray, files)
		files = arg
	}
}
fileArray = cbind(fileArray, files)
if (length(files) != length(titles)) {
	cat(sprintf("Wrong number of data files for legend: %s\n", legends[length(legends)]))
	q(status=1)
}


size = 5
#size = 1.61
footerRatio = 0.15
#size = 1.61*1.7
#footerRatio = 0.15/1.7
from.prop=15
to.prop=2

#pdf(filename=plot.filename, width=length(titles)*size, height=size * (1 + footerRatio))
svg(filename=plot.filename, width=length(titles)*size, height=size * (1 + footerRatio))
#colors = c("red", "green3", "blue", "magenta")
#lineTypes = c("44", "1343", "73", "2262")
colors = c("red", "green3", "blue", "cyan", "magenta", "yellow")
lineTypes = c("44", "22", "1343", "73", "131343", "2262")

#library(tikzDevice)

#tikz(file="plot-resolution-strategies.tex", width=length(titles)*size, height=size * (1 + footerRatio))
#tikz(file="plot-resolution-strategies.tex", width=length(titles)*size, height=size)
#colors = c("red", "blue", "green3")
#lineTypes = c("44", "73", "1343")
#../src/scripts/plot_row.r '\textsc{GO-Plus}' '\textsc{Galen}' '\textsc{Snomed}' -- BottomUp results/final/17-04-11.go-plus.resolution.bottomup.dell.elk.record.csv results/final/17-04-11.galen7.resolution.bottomup.dell.elk.record.csv results/final/17-04-11.snomed2015.resolution.bottomup.dell.elk.record.csv TopDown results/final/17-04-11.go-plus.resolution.topdown.dell.elk.record.csv results/final/17-04-11.galen7.resolution.topdown.dell.elk.record.csv results/final/17-04-11.snomed2015.resolution.topdown.dell.elk.record.csv Threshold results/final/17-04-11.go-plus.resolution.threshold.dell.elk.record.csv results/final/17-04-11.galen7.resolution.threshold.dell.elk.record.csv results/final/17-04-11.snomed2015.resolution.threshold.dell.elk.record.csv
#tikz(file="plot-resolution-strategies-sat.tex", width=length(titles)*size, height=size * (1 + footerRatio))
#colors = c("blue", "green3")
#lineTypes = c("73", "1343")
#../src/scripts/plot_row.r '\textsc{GO-Plus}' '\textsc{Galen}' '\textsc{Snomed}' -- TopDown results/final/17-05-03.go-plus.resolution.topdown.dell.sat.record.csv results/final/17-05-03.galen7.resolution.topdown.dell.sat.record.csv results/final/17-05-03.snomed2015.resolution.topdown.dell.sat.record.csv Threshold results/final/17-05-03.go-plus.resolution.threshold.dell.sat.record.csv results/final/17-05-03.galen7.resolution.threshold.dell.sat.record.csv results/final/17-05-03.snomed2015.resolution.threshold.dell.sat.record.csv

#tikz(file="plot-sat-vs-elk-infs-el2mus.tex", width=length(titles)*size, height=size * (1 + footerRatio))
#colors = c("red", "blue")
#lineTypes = c("44", "73")
#../src/scripts/plot_row.r '\textsc{GO-Plus}' '\textsc{Galen}' '\textsc{Snomed}' -- "EL2MUS \ensuremath{\mathsf{elk}}" results/final/17-04-04.go-plus.el2mus.dell.elk.record.csv results/final/17-04-04.galen7.el2mus.dell.elk.record.csv results/final/17-04-11.snomed2015.el2mus.dell.elk.record.csv "EL2MUS \ensuremath{\mathsf{sat}}" results/final/17-03-28.go-plus.el2mus.dell.sat.record.csv results/final/17-03-15.galen7.el2mus.dell.sat.record.csv results/final/17-04-11.snomed2015.el2mus.dell.sat.record.csv

#tikz(file="plot-allalgs-elkinfs.tex", width=length(titles)*size, height=size * (1 + footerRatio))
#tikz(file="plot-allalgs-elkinfs.tex", width=length(titles)*size, height=size)
#colors = c("magenta", "red", "blue", "green3")
#lineTypes = c("121242", "44", "73", "1343")
#../src/scripts/plot_row.r '\textsc{GO-Plus}' '\textsc{Galen}' '\textsc{Snomed}' -- SATPin results/final/17-04-12.go-plus.SATPin.dell.elk.record.csv results/final/17-04-12.galen7.SATPin.dell.elk.record.csv results/final/17-04-12.snomed2015.SATPin.dell.elk.record.csv EL2MCS results/final/17-04-04.go-plus.el2mcs.dell.elk.record.csv results/final/17-04-04.galen7.el2mcs.dell.elk.record.csv results/final/17-04-11.snomed2015.el2mcs.dell.elk.record.csv EL2MUS results/final/17-04-04.go-plus.el2mus.dell.elk.record.csv results/final/17-04-04.galen7.el2mus.dell.elk.record.csv results/final/17-04-11.snomed2015.el2mus.dell.elk.record.csv Threshold results/final/17-04-11.go-plus.resolution.threshold.dell.elk.record.csv results/final/17-04-11.galen7.resolution.threshold.dell.elk.record.csv results/final/17-04-11.snomed2015.resolution.threshold.dell.elk.record.csv
#tikz(file="plot-allalgs-satinfs.tex", width=length(titles)*size, height=size * (1 + footerRatio))
#../src/scripts/plot_row.r '\textsc{GO-Plus}' '\textsc{Galen}' '\textsc{Snomed}' -- SATPin results/final/17-04-26.go-plus.SATPin.dell.sat.record.csv results/final/17-04-26.galen7.SATPin.dell.sat.record.csv results/final/17-04-26.snomed2015.SATPin.dell.sat.record.csv EL2MCS results/final/17-03-28.go-plus.el2mcs.dell.sat.record.csv results/final/17-03-17.galen7.el2mcs.dell.sat.record.csv results/final/17-04-11.snomed2015.el2mcs.dell.sat.record.csv EL2MUS results/final/17-03-28.go-plus.el2mus.dell.sat.record.csv results/final/17-03-15.galen7.el2mus.dell.sat.record.csv results/final/17-04-11.snomed2015.el2mus.dell.sat.record.csv Threshold results/final/17-04-11.go-plus.resolution.threshold.dell.elk.record.csv results/final/17-04-11.galen7.resolution.threshold.dell.elk.record.csv results/final/17-04-11.snomed2015.resolution.threshold.dell.elk.record.csv

#tikz(file="plot-resolution.tex", width=length(titles)*size/2, height=size*2)

pixelSizeInch = 1/96#1/72
pixelsInSize = size / pixelSizeInch

#par(mfrow=c(1, length(titles)))
#par(mfrow=c(2, length(titles)/2))
par(cex=par("cex") * 2/3)
isFirst = TRUE
colIndex = 1
while (colIndex <= length(titles)) {
	print(titles[colIndex])
	print(fileArray[colIndex,])
	par(fig=c((colIndex-1) / length(titles), colIndex / length(titles), footerRatio, 1), new=TRUE)
	plot.results(fileArray[colIndex,], isFirst=isFirst, main=titles[colIndex],
			colors=colors, lineTypes=lineTypes, from.prop=from.prop, to.prop=to.prop,
			pixels.in.plot.size=pixelsInSize)
	colIndex = colIndex + 1
	if (isFirst) {
		isFirst = FALSE
	}
}
par(fig=c(0, 1, 0, footerRatio), new=TRUE)
plot.new()
legend("center", c(legends, "minimum"), col=c(rep(colors, length.out=length(legends)), "black"),
		lty=c(rep(lineTypes, length.out=length(legends)), "solid"), lwd=c(rep(2, length.out=length(legends)), 1),
		horiz=TRUE, bty="n")


dev.off()

