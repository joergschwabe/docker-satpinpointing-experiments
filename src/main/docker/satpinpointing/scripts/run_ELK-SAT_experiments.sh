#!/bin/bash

TIMEOUT=$1
shift
GLOBAL_TIMEOUT=$1
shift
SOURCE=$1
shift
INPUT=$1
shift
MACHINE_NAME=$1
shift
SCRIPTS_DIR=$1
shift
WORKSPACE_DIR=$1
shift
QUERY_GENERATION_OPTIONS=$1
shift

INPUT_DIR=$WORKSPACE_DIR/input
ONTOLOGIES_DIR=$WORKSPACE_DIR/ontologies
QUERIES_DIR=$WORKSPACE_DIR/queries
INFS_DIR=$WORKSPACE_DIR/inferences
EXPERIMENT_DIR=$WORKSPACE_DIR/experiments
LOGS_DIR=$WORKSPACE_DIR/logs
RESULTS_DIR=$WORKSPACE_DIR/results
PLOTS_DIR=$RESULTS_DIR/plots
RESULTS_ARCHIVE=$WORKSPACE_DIR/results.zip



DATE=`date +%y-%m-%d`
TIME_LOG_FORMAT='+%y-%m-%d %H:%M:%S'



# Obtain the ontologies

INPUT_FILE=""
if [ $SOURCE == "file" ]
then
	
	INPUT_FILE=$INPUT
	
elif [ $SOURCE == "web" ]
then
	
	echo `date "$TIME_LOG_FORMAT"` "downloading the input ontologies"
	
	rm -rf $INPUT_DIR
	mkdir -p $INPUT_DIR
	
	CURRENT_DIR=`pwd`
	cd $INPUT_DIR

	wget -nv $INPUT
	INPUT_FILE=$(realpath $(ls -1 | head -n1))

	cd $CURRENT_DIR
	
else
	
	>&2 echo `date "$TIME_LOG_FORMAT"` "Wrong option for the 3rd argument! Must be one of {file,web}."
	exit 2
	
fi

rm -rf $ONTOLOGIES_DIR
mkdir -p $ONTOLOGIES_DIR

if [[ $INPUT_FILE == *.tar.gz ]] ||  [[ $INPUT_FILE == *.tgz ]]
then
	
	echo `date "$TIME_LOG_FORMAT"` "extracting the input ontologies"
	
	ABSPLUTE_ONTOLOGIES_ARCHIVE=`realpath $INPUT_FILE`
	CURRENT_DIR=`pwd`
	cd $ONTOLOGIES_DIR
	
	tar xzf $ABSPLUTE_ONTOLOGIES_ARCHIVE
	
	cd $CURRENT_DIR
	
elif [[ $INPUT_FILE == *.zip ]]
then
	
	echo `date "$TIME_LOG_FORMAT"` "extracting the input ontologies"
	
	ABSPLUTE_ONTOLOGIES_ARCHIVE=`realpath $INPUT_FILE`
	CURRENT_DIR=`pwd`
	cd $ONTOLOGIES_DIR
	
	unzip -q $ABSPLUTE_ONTOLOGIES_ARCHIVE
	
	cd $CURRENT_DIR
	
else
	
	cp $INPUT_FILE $ONTOLOGIES_DIR
	
fi



# Generate queries

if [ -e $QUERIES_DIR ] && [ ! -d $QUERIES_DIR ]
then
	rm -rf $QUERIES_DIR
fi
mkdir -p $QUERIES_DIR

for ONTOLOGY in `ls -1 $ONTOLOGIES_DIR`
do
	
	NAME=`basename -s ".owl" $ONTOLOGY`
	echo `date "$TIME_LOG_FORMAT"` "generating queries for $NAME"
	java $JAVA_MEMORY_OPTIONS -Dlog4j.configurationFile=log4j2-paramfiles.xml -Dlog.file.out=$QUERIES_DIR/$NAME.sorted.out.log -Dlog.file.err=$QUERIES_DIR/$NAME.sorted.err.log -cp "$CLASSPATH" org.liveontologies.pinpointing.ExtractSubsumptions $QUERY_GENERATION_OPTIONS --sort $ONTOLOGIES_DIR/$ONTOLOGY $QUERIES_DIR/$NAME.queries.sorted
	java $JAVA_MEMORY_OPTIONS -cp "$CLASSPATH" org.liveontologies.pinpointing.Shuffler 1 < $QUERIES_DIR/$NAME.queries.sorted > $QUERIES_DIR/$NAME.queries.seed1
	java $JAVA_MEMORY_OPTIONS -Dlog4j.configurationFile=log4j2-paramfiles.xml -Dlog.file.out=$QUERIES_DIR/$NAME.bottom_up.out.log -Dlog.file.err=$QUERIES_DIR/$NAME.bottom_up.err.log -cp "$CLASSPATH" org.liveontologies.pinpointing.ExtractSubsumptions $QUERY_GENERATION_OPTIONS --traversal BOTTOM_UP --collection SUB_TO_SUPER $ONTOLOGIES_DIR/$ONTOLOGY $QUERIES_DIR/$NAME.queries.bottom_up
done



# Encode ELK inferences to SAT

if [ -e $INFS_DIR ] && [ ! -d $INFS_DIR ]
then
	rm -rf $INFS_DIR
fi
mkdir -p $INFS_DIR

if [ -e $INFS_DIR/elk ] && [ ! -d $INFS_DIR/elk ]
then
	rm -rf $INFS_DIR/elk
fi
mkdir -p $INFS_DIR/elk

for ONTOLOGY in `ls -1 $ONTOLOGIES_DIR`
do
	
	NAME=`basename -s ".owl" $ONTOLOGY`
	echo `date "$TIME_LOG_FORMAT"` "tracing elk inferences for $NAME"
	PROPS='-Delk.reasoner.tracing.evictor=RecencyEvictor(1000000,0.75)'
	java $JAVA_MEMORY_OPTIONS $PROPS -Dlog4j.configurationFile=log4j2-paramfiles.xml -Dlog.file.out=$INFS_DIR/elk/$NAME.out.log -Dlog.file.err=$INFS_DIR/elk/$NAME.err.log -cp "$CLASSPATH" org.liveontologies.pinpointing.DirectSatEncodingUsingElkCsvQuery $ONTOLOGIES_DIR/$ONTOLOGY $QUERIES_DIR/$NAME.queries.bottom_up $INFS_DIR/elk/$NAME --minimal --progress
	
done



# Run the experiments

rm -rf $RESULTS_DIR
mkdir -p $RESULTS_DIR

for INF_TYPE in `ls -1 $INFS_DIR`
do
	
	echo `date "$TIME_LOG_FORMAT"` "running experiments on $INF_TYPE inferences"
	
	for EXPERIMENT in `ls -1 $EXPERIMENT_DIR`
	do
		
		EXPERIMENT_NAME=`basename -s ".sh" $EXPERIMENT`
		echo `date "$TIME_LOG_FORMAT"` "running experiment $EXPERIMENT_NAME ..."
		
		for NAME in `ls -1 $INFS_DIR/$INF_TYPE/`
		do
			if [ ! -d $INFS_DIR/$INF_TYPE/$NAME ]
			then
				continue
			fi
			
			echo `date "$TIME_LOG_FORMAT"` "... on $NAME"
			DIR_NAME=$DATE.$NAME.$EXPERIMENT_NAME.$MACHINE_NAME.$INF_TYPE
			rm -rf $LOGS_DIR/$DIR_NAME
			mkdir -p $LOGS_DIR/$DIR_NAME
			$EXPERIMENT_DIR/$EXPERIMENT $TIMEOUT $GLOBAL_TIMEOUT $QUERIES_DIR/$NAME.queries.seed1 $INFS_DIR/$INF_TYPE/$NAME $SCRIPTS_DIR $LOGS_DIR/$DIR_NAME
			cp $LOGS_DIR/$DIR_NAME/record.csv $RESULTS_DIR/$DIR_NAME.csv
			
		done
		
	done
	
done



# Plot the plots

echo `date "$TIME_LOG_FORMAT"` "plotting"

mkdir -p $PLOTS_DIR

for INF_TYPE in `ls -1 $INFS_DIR`
do
	
	PLOT_LEGEND=""
	PLOT_ARGS=""
	for EXPERIMENT in `ls -1 $EXPERIMENT_DIR`
	do
		
		EXPERIMENT_NAME=`basename -s ".sh" $EXPERIMENT`
		PLOT_ARGS="$PLOT_ARGS $EXPERIMENT_NAME"
		
		PLOT_LEGEND=""
		for NAME in `ls -1 $INFS_DIR/$INF_TYPE/`
		do
			if [ ! -d $INFS_DIR/$INF_TYPE/$NAME ]
			then
				continue
			fi
			
			PLOT_LEGEND="$PLOT_LEGEND $NAME"
			
			DIR_NAME=$DATE.$NAME.$EXPERIMENT_NAME.$MACHINE_NAME.$INF_TYPE
			RECORD=$LOGS_DIR/$DIR_NAME/record.csv
			
			PLOT_ARGS="$PLOT_ARGS $RECORD"
			
		done
		
	done
	
	$SCRIPTS_DIR/plot_row.r $PLOTS_DIR/plot.$INF_TYPE.svg $PLOT_LEGEND -- $PLOT_ARGS >/dev/null 2>/dev/null
	
done



# Pack the results

echo `date "$TIME_LOG_FORMAT"` "packing the results"

CURRENT_DIR=`pwd`
ABSPLUTE_RESULTS_ARCHIVE=`realpath $RESULTS_ARCHIVE`
cd $WORKSPACE_DIR

zip -r -q $ABSPLUTE_RESULTS_ARCHIVE `basename $RESULTS_DIR`

cd $CURRENT_DIR



echo `date "$TIME_LOG_FORMAT"` "Done."



