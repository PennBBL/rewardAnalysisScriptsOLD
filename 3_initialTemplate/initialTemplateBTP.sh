imgDir=/data/jag/BBL/templates/rewardTemplate2/templateCreation/1_initialTemplate/input
ANTSDIR=/data/jag/BBL/applications/ants_20151007/bin/

cd $imgDir
pwd
$ANTSDIR/buildtemplateparallel.sh -d 3 -m 1x1x0 -r 1  -c 1 -o initial1  *_*.nii.gz
