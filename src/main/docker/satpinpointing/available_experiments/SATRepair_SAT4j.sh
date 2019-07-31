#!/bin/bash

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
OUTPUT_DIR=$1
shift

java $JAVA_MEMORY_OPTIONS -Dlog4j.configurationFile=log4j2-paramfiles.xml -Dlog.file.out=$OUTPUT_DIR/out.log -Dlog.file.err=$OUTPUT_DIR/err.log -cp "$CLASSPATH" com.github.joergschwabe.RunJustificationExperiments -t "$TIMEOUT"000 -g "$GLOBAL_TIMEOUT"000 --progress $OUTPUT_DIR/record.csv $QUERY_FILE com.github.joergschwabe.experiments.SatFactoryJustificationExperiment -- $ENCODING_DIR com.github.joergschwabe.SatRepairComputationSat4j
