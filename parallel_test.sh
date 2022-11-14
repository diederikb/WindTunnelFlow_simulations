#### jupyter.sh START ####
#!/bin/bash
#$ -N array_job_test
#$ -t 1-2:1
#$ -cwd
#$ -o logs/$JOB_ID.out
#$ -e logs/$JOB_ID.err
#$ -j n
#$ -l h_rt=24:00:00,h_data=10G,highp

PROJECT_SUBDIR="cawt_job"
CASE_TYPE="AFUWT_NACA0009_gaussian_suction"
PACKAGE_DIR="/u/home/b/beckers/.julia/dev/WindTunnelFlow"
PARAMETERS_FILE="${CASE_TYPE}.json"
JULIA_SCRIPT="${PACKAGE_DIR}/examples/${CASE_TYPE}.jl"
JULIA_PROJECT="${PACKAGE_DIR}/Project.toml"

QRATIO_ARRAY=(0.05 0.1 0.15 0.2 0.25)
AOA_ARRAY=(0 2 4 6 8 10 12 14 16 18 20)
RE_ARRAY=(400)
GRID_RE_ARRAY=(6)

COUNTER=1
for GRID_RE_COUNTER in ${GRID_RE_ARRAY[@]}; do
    for RE_COUNTER in "${RE_ARRAY[@]}"; do
        for AOA_COUNTER in "${AOA_ARRAY[@]}"; do
            for QRATIO_COUNTER in "${QRATIO_ARRAY[@]}"; do
                if [ $COUNTER -eq $SGE_TASK_ID ]
                then
                    GRID_RE="$GRID_RE_COUNTER"
                    RE="$RE_COUNTER"
                    AOA="$AOA_COUNTER"
                    QRATIO="$QRATIO_COUNTER"
                fi
                COUNTER=$((COUNTER + 1))
            done
        done
    done
done

NUM_OPTIONS=$(( ${#QRATIO_ARRAY[@]} * ${#AOA_ARRAY[@]} * ${#RE_ARRAY[@]} * ${#GRID_RE_ARRAY[@]} ))
if [ $COUNTER -eq $SGE_TASK_ID ]
then
    exit 0
fi

WORKING_DIR="/u/home/b/beckers/project-sofia/windtunnel/${PROJECT_SUBDIR}_${JOB_ID}_${SGE_TASK_ID}_${CASE_TYPE}_Grid_Re_${GRID_RE}_Re_${RE}_aoa_${AOA}_Qratio_${QRATIO}"
if [ ! -d "${WORKING_DIR}" ]; then
    mkdir -p "${WORKING_DIR}"
fi

cd $WORKING_DIR
cp $PACKAGE_DIR/examples/$PARAMETERS_FILE $WORKING_DIR/$PARAMETERS_FILE

awk '/case/{sub(/\"[^\"]*\",?$/,"\"a_b\"")}1' a="${JOB_ID}" b="${SGE_TASK_ID}" $WORKING_DIR/$PARAMETERS_FILE
#awk '/alpha/{sub(/\"[^\"]*\",?$/,"\"$AOA\"")}1' $PARAMETERS_TEMPLATE
#awk '/Re/{sub(/\"[^\"]*\",?$/,"\"$RE\"")}1' $PARAMETERS_TEMPLATE
#awk '/grid_Re/{sub(/\"[^\"]*\",?$/,"\"$RE\"")}1' $PARAMETERS_TEMPLATE
#awk '/Q_SD_over_Q_in/{sub(/\"[^\"]*\",?$/,"\"$QRATIO\"")}1' $PARAMETERS_TEMPLATE

#awk '/"case"/{$1="     "$1;$3="\042${JOB_ID}_${SGE_TASK_ID}\042\054"} 1' $PARAMETERS_FILE

STATS_FILE="${WORKING_DIR}/${JOB_ID}_${SGE_TASK_ID}_stats.txt"
START_TIME=`date`
printf "JOB_ID: ${JOB_ID}\nSGE_TASK_ID: ${SGE_TASK_ID}\nGRID_RE: ${GRID_RE}\nRE: ${RE}\nAOA: ${AOA}\nQRATIO: ${QRATIO}\nSTART_TIME: ${START_TIME}\n" >> $STATS_FILE

#julia --project=$JULIA_PROJECT $JULIA_SCRIPT
END_TIME=`date`
printf "END_TIME: ${END_TIME}\n" >> $STATS_FILE


