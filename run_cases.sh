#!/bin/bash
#$ -N array_job_test
#$ -t 1-3:1
#$ -cwd
#$ -o logs/$JOB_ID_$TASK_ID.out
#$ -e logs/$JOB_ID_$TASK_ID.err
#$ -j n
#$ -l h_rt=2:00:00,h_data=10G -pe shared 1

. /u/local/Modules/default/init/modules.sh
module load julia/1.8.1

CURRENT_WORKING_DIRECTORY=$(pwd)
echo $CURRENT_WORKING_DIRECTORY

PROJECT_SUBDIR=cawt_job
CASE_TYPE=AFUWT_NACA0009_gaussian_suction
PACKAGE_DIR=/u/home/b/beckers/.julia/dev/WindTunnelFlow
PARAMETERS_FILE=${CASE_TYPE}.json
JULIA_SCRIPT=${PACKAGE_DIR}/examples/${CASE_TYPE}.jl
JULIA_PROJECT=${PACKAGE_DIR}/Project.toml

QRATIO_ARRAY=(0.05 0.1 0.15 0.2 0.25)
AOA_ARRAY=(0 2 4 6 8 10 12 14 16 18 20)
RE_ARRAY=(100)
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

WORKING_DIR=${PROJECT_SUBDIR}_${JOB_ID}_${SGE_TASK_ID}_${CASE_TYPE}_Grid_Re_${GRID_RE}_Re_${RE}_aoa_${AOA}_Qratio_${QRATIO}
if [ ! -d ${WORKING_DIR} ]; then
    mkdir -p ${WORKING_DIR}
fi

cd $WORKING_DIR
cp $PACKAGE_DIR/examples/$PARAMETERS_FILE .

sed -i 's/\"case\":.*/\"case\": '\"${JOB_ID}_${SGE_TASK_ID}\",'/g' $PARAMETERS_FILE
sed -i 's/\"alpha\":.*/\"alpha\": '${AOA},'/g' $PARAMETERS_FILE
sed -i 's/\"Re\":.*/\"Re\": '${RE},'/g' $PARAMETERS_FILE
sed -i 's/\"Q_SD_over_Q_in\":.*/\"Q_SD_over_Q_in\": '${QRATIO},'/g' $PARAMETERS_FILE
sed -i 's/\"grid_Re\":.*/\"grid_Re\": '${GRID_RE}'/g' $PARAMETERS_FILE

STATS_FILE=${JOB_ID}_${SGE_TASK_ID}_out.txt
START_TIME=`date`
printf "JOB_ID: ${JOB_ID}\nSGE_TASK_ID: ${SGE_TASK_ID}\nGRID_RE: ${GRID_RE}\nRE: ${RE}\nAOA: ${AOA}\nQRATIO: ${QRATIO}\nSTART_TIME: ${START_TIME}\n" >> $STATS_FILE
julia --project=$JULIA_PROJECT $JULIA_SCRIPT >> STATS_FILE 2>&1
END_TIME=`date`
printf "END_TIME: ${END_TIME}\n" >> $STATS_FILE

cd $CURRENT_WORKING_DIRECTORY

