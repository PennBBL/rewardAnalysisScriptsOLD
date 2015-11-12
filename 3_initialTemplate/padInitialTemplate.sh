#!/usr/bin/env bash

imgDir=/data/jag/BBL/projects/rewardAnalysis/template/3_initialTemplate/
ANTSDIR=/data/jag/BBL/applications/ants_20151007/bin/

inputTemplate=${imgDir}/initial1template.nii.gz

#pad template
if [ ! -e "$imgDir/initial1template_padded.nii.gz" ]; then
	echo "padding initial BTP tempalte"
	$ANTSDIR/ImageMath 3 $imgDir/initial1template_padded.nii.gz PadImage $inputTemplate 5
else
	echo "padded template present"
fi
