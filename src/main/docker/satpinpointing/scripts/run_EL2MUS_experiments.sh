#!/bin/bash

EXE=$1
shift
TIMEOUT=$1
shift
GLOBAL_TIMEOUT=$1
shift
QUERY_FILE=$1
shift
ENCODING_DIR=$1
shift
SCRIPTS_DIR=$1
shift
TOOLS_DIR=$1
shift
OUTPUT_DIR=$1
shift
ONLY_ONE_JUST=$1
shift

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

echo "query,didTimeOut,time,realTime,cpuTime,nJust,meanJustSize" > $OUTPUT_DIR/record.csv

START_TIME_NANOS=`date +%s%N`
TOTAL_TIME_NANOS=0

REPORT_INTERVAL_NANOS=1000000000
TOTAL_QUERIES=`wc -l $QUERY_FILE | cut -d" " -f1`
DONE_QUERIES=0

function report_progress {
	CURRENT_NANOS=`date +%s%N`
	PERCENT=`echo "scale=2; 100*$DONE_QUERIES/$TOTAL_QUERIES" | bc`
	ELAPSED_NANOS=$(($CURRENT_NANOS - $START_TIME_NANOS))
	ELAPSED_SECONDS=$(($ELAPSED_NANOS / 1000000000))
	ETA_NANOS=`echo "scale=9; $ELAPSED_NANOS * ($TOTAL_QUERIES - $DONE_QUERIES) / $DONE_QUERIES" | bc`
	ETA_SECONDS=`echo "scale=0; $ETA_NANOS / 1000000000" | bc`
	printf "\r%*d/%d %6.2f%%  elapsed: %02d:%02d:%02d  ETA: %02d:%02d:%02d" ${#TOTAL_QUERIES} $DONE_QUERIES $TOTAL_QUERIES $PERCENT "$((ELAPSED_SECONDS/3600%24))" "$((ELAPSED_SECONDS/60%60))" "$((ELAPSED_SECONDS%60))" "$((ETA_SECONDS/3600%24))" "$((ETA_SECONDS/60%60))" "$((ETA_SECONDS%60))"
	NEXT_REPORT_AFTER_NANOS=$((`date +%s%N` + $REPORT_INTERVAL_NANOS))
}

printf "%*d/%d %6.2f%%  elapsed: 00:00:00" ${#TOTAL_QUERIES} $DONE_QUERIES $TOTAL_QUERIES 0.0
NEXT_REPORT_AFTER_NANOS=$((`date +%s%N` + $REPORT_INTERVAL_NANOS))

cat $QUERY_FILE | while read LINE
do
	
	QUERY_SHA1=`perl -e "print qq($LINE)" | sha1sum | cut -d" " -f1`
	
	QUERY_DIR=$ENCODING_DIR/$QUERY_SHA1
	if [ ! -s $QUERY_DIR ]
	then
		>&2 echo "No Input Dir: " $QUERY_DIR
		break
	fi
	
	echo -n '"'$LINE'"', >> $OUTPUT_DIR/record.csv
	
	LITERAL=`cat $QUERY_DIR/encoding.q`
	INPUT_FILE=$QUERY_DIR/encoding.$LITERAL.wcnf
	if [ ! -s $INPUT_FILE ]
	then
		$SCRIPTS_DIR/create-wcnf encoding $QUERY_DIR $QUERY_DIR/encoding.q $QUERY_DIR $TOOLS_DIR no-opt
	fi
	
	ARGS=""
	if [[ $ONLY_ONE_JUST == "true" ]]
	then
		ARGS="$ARGS -nmus 1"
	fi
	
	LOG_DIR=$OUTPUT_DIR/$QUERY_SHA1
	mkdir -p $LOG_DIR
	
	START_NANO=`date +%s%N`
	timeout -s9 $(($TIMEOUT + 10)) $EXE -T $TIMEOUT $ARGS $INPUT_FILE 2>&1 > $LOG_DIR/out.log | tee $LOG_DIR/err.log 1>&2
	END_NANO=`date +%s%N`
	
	RUN_TIME_NANOS=$(($END_NANO - $START_NANO))
	RUN_TIME_MILLIS=`echo "scale=6; $RUN_TIME_NANOS/1000000.0" | bc`
	
	if [ $(( $TIMEOUT * 1000000000 )) -lt $RUN_TIME_NANOS ]
	then
		echo -n TRUE, >> $OUTPUT_DIR/record.csv
	else
		echo -n FALSE, >> $OUTPUT_DIR/record.csv
	fi
	echo -n $RUN_TIME_MILLIS, >> $OUTPUT_DIR/record.csv
	echo -n $RUN_TIME_MILLIS, >> $OUTPUT_DIR/record.csv
	if grep "Number of MUSes" $LOG_DIR/out.log > /dev/null 2> /dev/null
	then
		PT=`grep "Parsing CPU Time" $LOG_DIR/out.log | sed "s/[^0-9]*\([0-9]\+\.\?[0-9]*\)[^0-9]*/\1/g"`
        	CT=`grep "c CPU Time" $LOG_DIR/out.log | sed "s/[^0-9]*\([0-9]\+\.\?[0-9]*\)[^0-9]*/\1/g"`
        	echo -n `echo "scale=6; $CT * 1000 - $PT * 1000" | bc`, >> $OUTPUT_DIR/record.csv
        	JS=`grep "Number of MUSes" $LOG_DIR/out.log | sed "s/[^0-9]*\([0-9]\+\.\?[0-9]*\)[^0-9]*/\1/g"`
        	echo -n $JS, >> $OUTPUT_DIR/record.csv
	else
		echo -n $RUN_TIME_MILLIS, >> $OUTPUT_DIR/record.csv
		echo -n 0, >> $OUTPUT_DIR/record.csv
	fi
	MEAN_SIZE=`grep "^c.* MUS: " $LOG_DIR/out.log | sed "s/^c.* MUS: \(.*\)$/\1/g" | awk '{ sum += NF } END { if (NR > 0) print sum / NR }'`
	echo $MEAN_SIZE >> $OUTPUT_DIR/record.csv
	
	TOTAL_TIME_NANOS=$(( $TOTAL_TIME_NANOS + $RUN_TIME_NANOS ))
	if [ $(( $GLOBAL_TIMEOUT * 1000000000 )) -lt $TOTAL_TIME_NANOS ]
	then
		break
	fi
	
	DONE_QUERIES=$(($DONE_QUERIES + 1))
	
	CURRENT_NANOS=`date +%s%N`
	if (($CURRENT_NANOS >= $NEXT_REPORT_AFTER_NANOS))
	then
		report_progress
	fi
	
done

# changes to DONE_QUERIES are not visible outside of the loop
DONE_QUERIES=`wc -l $OUTPUT_DIR/record.csv | cut -d" " -f1`
DONE_QUERIES=$(($DONE_QUERIES - 1))
report_progress
echo ""


