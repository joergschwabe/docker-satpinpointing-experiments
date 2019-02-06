#!/bin/bash

EXE=$1
TIMEOUT=$2
GLOBAL_TIMEOUT=$3
QUERY_FILE=$4
ENCODING_DIR=$5
OUTPUT_DIR=$6

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

echo "query,didTimeOut,time,realTime,cpuTime,nJust" > $OUTPUT_DIR/record.csv

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
	
	LOG_DIR=$OUTPUT_DIR/$QUERY_SHA1
	mkdir -p $LOG_DIR
	
	START_NANO=`date +%s%N`
	cat $QUERY_DIR/encoding.h $QUERY_DIR/encoding.cnf | timeout -s9 $(($TIMEOUT + 10)) $EXE -assumptions=$QUERY_DIR/encoding.assumptions -question=$QUERY_DIR/encoding.question -cpu-lim=$TIMEOUT -rotate=1 -no-eldbg -reduce=0 -modelClauses -keepSearch -minimal 2>&1 > $LOG_DIR/out.log | tee $LOG_DIR/err.log 1>&2
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
	if grep "(unsat:" $LOG_DIR/out.log > /dev/null 2> /dev/null
	then
		PT=`grep "Parse time" $LOG_DIR/out.log | sed "s/[^0-9]*\([0-9]\+\.\?[0-9]*\)[^0-9]*/\1/g"`
        	CT=`grep "CPU time" $LOG_DIR/out.log | sed "s/[^0-9]*\([0-9]\+\.\?[0-9]*\)[^0-9]*/\1/g"`
        	echo -n `echo "scale=6; $CT * 1000 - $PT * 1000" | bc`, >> $OUTPUT_DIR/record.csv
        	JS=`grep "(unsat:" $LOG_DIR/out.log | sed "s/[^(]*(unsat: \([0-9]\+\.\?[0-9]*\))[^)]*/\1/g"`
        	echo $JS >> $OUTPUT_DIR/record.csv
	else
		echo -n $RUN_TIME_MILLIS, >> $OUTPUT_DIR/record.csv
		echo 0 >> $OUTPUT_DIR/record.csv
	fi
	
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


