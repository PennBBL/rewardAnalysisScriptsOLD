imgDir=/data/jag/BBL/projects/rewardAnalysis/template/3_initialTemplate/
ANTSDIR=/data/jag/BBL/applications/ants_20151007/bin/

cd $imgDir
pwd
$ANTSDIR/buildtemplateparallel.sh -d 3 -z ${imgDir}/initial1template_padded.nii.gz -o targeted  *t1.nii.gz 

