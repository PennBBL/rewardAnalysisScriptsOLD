#!/usr/bin/env bash

###################################################################
# This script creates symbolic links to all MPRAGEs to be used in
# generating a template for the reward dataset.
###################################################################

###################################################################
# required inputs
###################################################################
IDPATH=/data/jag/BBL/templates/rewardTemplate2/templateCreation/0_cohortSelect/output/templateCohort.csv
IMGPATH=/data/jag/BBL/studies/reward/t1/nifti/
LNDIRPATH=/data/jag/BBL/templates/rewardTemplate2/templateCreation/1_initialTemplate/input/

###################################################################
# Generate symlinks
###################################################################
subjects=$(cat $IDPATH)
for s in $subjects
   do
   bblid=$(echo $s|cut -d"," -f1)
   scanid=$(echo $s|cut -d"," -f2)
   t1=${IMGPATH}/${bblid}/*x${scanid}/*x${scanid}.nii.gz
   t1chk=$(ls -d1 ${t1})
   if [ ! -z "${t1chk}" ]
      then
      ln $t1 ${LNDIRPATH}/${bblid}_${scanid}.nii.gz
   else
      echo "T1 image not present for ${bblid} ${scanid}"
   fi
done
