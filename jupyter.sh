#### jupyter.sh START ####
#!/bin/bash
#$ -cwd
# error = Merged with joblog
#$ -o jupyter_log.$JOB_ID
#$ -e jupyter_err.$JOB_ID
#$ -j n
## Edit the line below as needed:
#$ -l h_rt=24:00:00,h_data=20G
## Modify the parallel environment
## and the number of cores as needed:
#$ -pe shared 4

# remove all logs except for the current one
ls jupyter_log* | grep -xv "jupyter_log.${JOB_ID}" | xargs rm
ls jupyter_err* | grep -xv "jupyter_err.${JOB_ID}" | xargs rm

# get tunneling info
XDG_RUNTIME_DIR=""
node=$(hostname -s)
user=$(whoami)

# print tunneling instructions jupyter-log
echo -e "
# Note: below 8888 is used to signify the port.
#       However, it may be another number if 8888 is in use.
#       Check $SGE_STDERR_PATH to find the port.

# Command to create SSH tunnel:
ssh -N -f -L 8888:${node}:8888 ${user}@hoffman2.idre.ucla.edu

# Use a browser on your local machine to go to:
http://localhost:8888/
"
. /u/local/Modules/default/init/modules.sh
module load python

cd ~/.julia/dev/WindTunnelFlow/examples
jupyter-notebook --no-browser --ip=${node}

# keep it alive
sleep 36000

