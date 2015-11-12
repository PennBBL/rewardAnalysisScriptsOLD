#!/usr/bin/env bash

#creates joint intensity fusion template 

btpDir=/data/jag/BBL/projects/rewardAnalysis/template/4_targetedTemplate/
inputTemplate=${btpDir}/targetedtemplate.nii.gz
outDir=/data/jag/BBL/projects/rewardAnalysis/template/5_JIF
jifCall=/data/jag/BBL/projects/rewardAnalysis/rewardAnalysisScripts/template/5_JIF/callJif.sh
export ANTSDIR=/data/jag/BBL/applications/ants_20151007/bin

#template is already padded

#generate intensity only images
echo ""
lastImg=/data/jag/BBL/projects/rewardAnalysis/template/4_targetedTemplate/targetedinitial199949_9044_t1deformed_normalised.nii.gz
if [ ! -e "$lastImg" ]; then
	echo "normalising and padding warped images"
	warpedImages=$(ls $btpDir/*t1deformed.nii.gz)
	for x in $warpedImages; do 
		echo "working on $x"
		imgName=$(echo $x | cut -d. -f1)
		$ANTSDIR/ImageMath 3 ${imgName}_normalised.nii.gz Normalize $x
	done
else
	echo "warped images padded and normalized already"
fi

#assemble list of images for JIF call
rm -f $jifCall
echo "#!/usr/bin/env bash" >> $jifCall
params=" -r 1 -v 1 -s 2 -p 2 -a 0.05 -b 4 -c 0 "
echo -n "$ANTSDIR/antsJointFusion -v -d 3 -t $inputTemplate -o $outDir/jifTemplate.nii.gz $params" >> $jifCall
imgs=$(ls $btpDir/*_normalised.nii.gz)
for i in $imgs; do 
	echo -n " -g $i" >> $jifCall
done

chmod 755 $jifCall
qsub -V -b y -j y -m beas -M rastko@mail.med.upenn.edu -l h_vmem=20.5G,s_vmem=20G -cwd $jifCall
