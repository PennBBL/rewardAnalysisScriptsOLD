tDir=/data/jag/BBL/projects/rewardAnalysis/template/

imgDir=${tDir}/3_initialTemplate/

cohort=${tDir}/1_cohortSelect/templateCohort.csv
cohort=$(cat $cohort)

for s in $cohort
   do
   bblid=$(echo $s|cut -d"," -f1)
   scanid=$(echo $s|cut -d"," -f2)
   img=${imgDir}/initial1${bblid}_${scanid}
   fslmaths $img ${img}_t1
done
