FROM openjdk:8u151-jdk

ENV CLASSPATH 'maven/*'
ENV EL2MCS_DIR_REPAIR el2mcs_repair
ENV EL2MCS_DIR_JUSTIFICATION el2mcs_justification
ENV EL2MUS_DIR el2mus
ENV SATPIN_EXE SATPin

ENV JAVA_MEMORY_OPTIONS '-Xmx6G -Xms2G'

WORKDIR /home/satpinpointing

COPY . /home/satpinpointing

RUN apt-get update && apt-get install -y --no-install-recommends \
		bc \
		r-base-core \
	&& rm -rf /var/lib/apt/lists/*

RUN find /home -type f -exec chmod 777 {} +

ARG PORT=3030
ENV PORT $PORT

EXPOSE $PORT

# Must be in the shell form so that the variable substitution works
CMD java -cp 'maven/*' com.github.joergschwabe.ExperimentServer --port $PORT --exps available_experiments --workspace workspace \
	./scripts/run_ELK-SAT_experiments.sh '<t>' '<g>' '<s>' '<o>' docker scripts workspace '<q>'
