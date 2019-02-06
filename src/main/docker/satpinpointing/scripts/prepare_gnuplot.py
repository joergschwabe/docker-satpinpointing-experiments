#!/usr/bin/python

import sys, os
import argparse
import csv
from string import Template

MIN_X_RANGE = 0
MAX_X_RANGE = 100
MIN_Y_RANGE = 0.000001
DEFAULT_COLUMN = 'time'

def parse_x_range(s):
	x_range = float(s)
	if x_range < MIN_X_RANGE or MAX_X_RANGE < x_range:
		raise argparse.ArgumentTypeError('x_range must be within %s and %s' % (MIN_X_RANGE, MAX_X_RANGE))
	return x_range

parser = argparse.ArgumentParser(description='Prepare gnuplot script from the supplied data files.')
parser.add_argument('-t', '--title', default='', help='The plot title.')
parser.add_argument('data', nargs='+', help='Sequence of the data files, ' +
				'each of which may be followed by names of columns that should be plotted.')
parser.add_argument('--lower_x_range', type=parse_x_range, default=100.0,
				help='The lower bound of the x axis.')

GNUPLOT_SCRIPT_TEMPLATE = Template("""

reset

set terminal lua tikz latex
set output "plot.tex"

${set_title}
set style data lines
set key left top
set logscale y
#set tics axis
#shrink = 0.1
set xrange[${lower_x_range}:${upper_x_range}]
set yrange[${lower_y_range}:${upper_y_range}]
#set xtics shrink/2
#set ytics shrink/2
#set size square
set xlabel "\\\\% of queries"
set ylabel "time in seconds"

plot ${plot_cmd}
${data}
pause -1

""")

if __name__ == "__main__":
	
	args = parser.parse_args()
	if not os.path.exists(args.data[0]):
		parser.error('the first data is not a file')
	
	# TODO debug !!!
#	print args
	
	input_data = {}
	current_file = None
	current_columns = []
	for arg in args.data:
		if os.path.exists(arg):
			# save the collected data and start collecting new ones
			if current_file:
				if current_columns:
					input_data[current_file] = current_columns
				else:
					input_data[current_file] = [DEFAULT_COLUMN]
			current_file = arg
			current_columns = []
		else:
			current_columns.append(arg)
	if current_columns:
		input_data[current_file] = current_columns
	else:
		input_data[current_file] = [DEFAULT_COLUMN]
	
	plot_cmd = ""
	data_string = ""
	min_data = sys.float_info.max
	max_data = sys.float_info.min
	for data_file in input_data.keys():
		for column in input_data[data_file]:
			
			if column == DEFAULT_COLUMN:
				plot_cmd += """'-' title "%s", """ % data_file
			else:
				plot_cmd += """'-' title "%s %s", """ % (data_file, column)
			
			with open(data_file) as fd:
				reader = csv.reader(fd, delimiter=',', quotechar='"')
				header = reader.next()
	#			print header
				time_index = header.index(column)
# 				time_index = 0
# 				for h in header:
# 					if h.find(column) >= 0:
# 						break
# 					time_index += 1
				# collect the data
				data = []
				for line in reader:
					data.append(float(line[time_index])/1000)
				data.sort()
 				
				md = data[int(len(data) * (1.0 - (args.lower_x_range/100)))]
				if md < min_data:
					min_data = md
				if data[len(data) - 1] > max_data:
					max_data = data[len(data) - 1]
				
				step = 100.0/len(data)
				x = step
				for d in data:
					data_string += "%f\t%f\n" % (x, d)
					x += step
				data_string += "e\n"
			
			pass
	
	min_data = max(min_data, MIN_Y_RANGE)
	
	set_title = ''
	if args.title:
		set_title = 'set title "%s"' % args.title
	print GNUPLOT_SCRIPT_TEMPLATE.substitute(set_title=set_title,
											plot_cmd=plot_cmd,
											data=data_string,
											lower_x_range=args.lower_x_range,
											upper_x_range=MAX_X_RANGE,
											lower_y_range=min_data,
											upper_y_range=max_data)
	
	pass







