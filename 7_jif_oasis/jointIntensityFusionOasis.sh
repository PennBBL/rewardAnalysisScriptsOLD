#creates joint intensity fusion template 

jlfTarget=/data/jag/BBL/projects/rewardAnalysis/template/5_JIF/jifTemplate2.nii.gz
outDir=/data/jag/BBL/projects/rewardAnalysis/template/7_jif_oasis
jifCall=/data/jag/BBL/projects/rewardAnalysis/rewardAnalysisScripts/template/7_jif_oasis/callJifOasis.sh
inDir=/data/jag/BBL/projects/rewardAnalysis/template/6_labels

export ANTSDIR=/data/jag/BBL/applications/ants_20151007/bin


#assemble list of images and labels for jlf call
rm -f $jifCall
params=" -r 1 -v 1 -s 2 -p 2 -a 0.05 -b 4 -c 0 "
echo -n "$ANTSDIR/antsJointFusion -v -d 3 -r -t $jlfTarget  -o [$outDir/jlfLabels.nii.gz,$outDir/jlfIntensity.nii.gz,$outDir/jlf_Posteriors%02d.nii.gz]" >> $jifCall


#get warped image and label for each registered oasis image
imgs=$(ls $inDir/*_Warped.nii.gz)
for img in $imgs; do 
	echo ""
	echo "****"
	echo $img
	#fslinfo $img
	id=$(basename $img | cut -d_ -f2)
	
	echo""
	labelImg=$(ls $inDir/*${id}*WarpedLabels.nii.gz)
	echo $labelImg
#	fslinfo $labelImg
	echo -n " -g $img -l $labelImg" >> $jifCall
done

chmod 755 $jifCall
qsub -V -b y -j y -m beas -M rastko@upenn.edu -l h_vmem=10.5G,s_vmem=10G -cwd $jifCall
