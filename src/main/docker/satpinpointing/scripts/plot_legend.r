#!/usr/bin/env Rscript


legends <- commandArgs(TRUE)


#size = 5
#size = 1.61
#footerRatio = 0.15
size = 1.61*1.7
footerRatio = 0.15/1.7

pdf(width=size*1.35, height=size * footerRatio)
#colors = c("red", "green3", "blue", "magenta")
#lineTypes = c("44", "1343", "73", "2262")

#library(tikzDevice)

#tikz(file="plot-resolution-strategies-legends.tex", width=size*1.35, height=size * footerRatio)
#colors = c("red", "blue", "green3")
#lineTypes = c("44", "73", "1343")

#tikz(file="plot-sat-vs-elk-infs-el2mus-legends.tex", width=size*1.35, height=size * footerRatio)
#colors = c("red", "blue")
#lineTypes = c("44", "73")

#tikz(file="plot-allalgs-legends.tex", width=size*1.35, height=size * footerRatio)
colors = c("magenta", "red", "blue", "green3")
lineTypes = c("121242", "44", "73", "1343")

par(cex=par("cex") * 2/3)
par(mar=c(0, 0, 0, 0))
par(mgp=c(-2.2, -1, 0))

plot.new()
legend("center", c(legends, "minimum"), col=c(rep(colors, length.out=length(legends)), "black"),
		lty=c(rep(lineTypes, length.out=length(legends)), "solid"), lwd=c(rep(2, length.out=length(legends)), 1),
		horiz=TRUE, bty="n")


dev.off()

