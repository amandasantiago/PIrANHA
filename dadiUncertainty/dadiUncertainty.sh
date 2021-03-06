#!/bin/sh

##########################################################################################
#  __  o  __   __   __  |__   __                                                         #
# |__) | |  ' (__( |  ) |  ) (__(                                                        # 
# |                                                                                      #
#                          dadiUncertainty v0.1.0, October 2017                          #
#  SHELL SCRIPT AUTOMATING UNCERTAINTY ANALYSIS IN ∂a∂i, INCLUDING GENERATION OF BOOT-   #
#  STRAPPED SNP FILES FOR PARAMETER STANDARD DEVIATION ESTIMATION USING THE GIM METHOD,  #
#  AS WELL AS STANDARD DEVIATION ESTIMATION USING THE FIM METHOD (ORIG. DATA ONLY)       #
#  Copyright (c)2017 Justinc C. Bagley, Virginia Commonwealth University, Richmond, VA,  #
#  USA; Universidade de Brasília, Brasília, DF, Brazil. See README and license on GitHub #
#  (http://github.com/justincbagley) for further info. Last update: October 3, 2017.     #
#  For questions, please e-mail jcbagley@vcu.edu.                                        #
##########################################################################################


############ SCRIPT OPTIONS
## OPTION DEFAULTS ##
MY_INPUT_VCF=input.vcf
MY_ASSIGNMENT_FILE=assignments.txt
MY_POP_IDS=\'name1\',\'name2\',\'name3\'		## SWWP LCPorder IDs: 'LP','core','periphery'
My_PROJECTION_VALUES=val1,val2,val3				## SWWP LCPorder projs: 98,46,156
MY_NUM_BOOT_DATASETS=100
UNCERT_METHOD_SWITCH=1
MY_DADI_MODEL_SCRIPT=model.py
MY_BESTMOD_PARAM_ESTIMATES=0.1,0.1,0.1,0.1,0.1,0.1
DELETE_ORIG_VCF=0

############ CREATE USAGE & HELP TEXTS
Usage="Usage: $(basename "$0") [Help: -h help] [Options: -a i p n m s e d] inputVCFFile
 ## Help:
  -h   help text (also: -help)

 ## Options:
  -a   assignmentFile (def: $MY_ASSIGNMENT_FILE) Name of population/species assignment file,
       a plain text file with one sample name and its corresponding population/species 
       assignment codes on each line
  -i   popIDs (def: $MY_POP_IDS) comma-separated string of population IDs 
       to be passed to ∂a∂i. Each ID (up to 3) must be enclosed by a single quote that is 
       commented out using a backslash, and be comma-separated
  -p   projections (def: $My_PROJECTION_VALUES) comma-separated string of projection values to
       be passed to ∂a∂i
  -n   numBootstraps (def: $MY_NUM_BOOT_DATASETS) Number of bootstrapped SNP datasets to create
  -m   method (def: 1=GIM; other: 2=FIM) perform uncertainty analysis using either the Godambe
       Information Matrix (GIM) or the Fisher Information Matrix (FIM)
  -s   modelScript (def: $MY_DADI_MODEL_SCRIPT) Name of ∂a∂i demographic model Python script that original
       model run relied on
  -e   paramEstimates (def: $MY_BESTMOD_PARAM_ESTIMATES) comma-separated string of best parameter
       estimates from original model run (beforehand)
  -d   deleteOrig (def: 0=no; other: 1=yes) specifies whether or not to delete the original
       input .vcf file

 OVERVIEW
 THIS SCRIPT automates conducting uncertainty analysis in ∂a∂i v1.7+ (Gutenkunst et al. 
 2009), in order to obtain parameter standard deviation estimates that can be converted by
 the user into lower and upper 95% confidence intervals (CIs) for each parameter in a given
 demographic model, which has already been run (to estimate best-fit parameters, best-
 supported model out of suite of candidate models, etc.). The script starts from a working
 directory containing the following: (1) the original VCF file containing SNP data that were
 analyzed in the original model (run beforehand); (2) a population assignment file, assigning
 each individual in the VCF file to population/species; (3) the original python file corres-
 ponding to the ∂a∂i model being evaluated; (4) the site frequency spectrum file used during
 the original model analysis; and (5) this script, with correct permissions set.
 
 From the above starting conditions, dadiUncertainty.sh will automate file preparation and 
 processing, as well as either one or both of the following uncertainty analyses described
 in the ∂a∂i user manual: (A) uncertainty estimation using the Godambe Information Matrix 
 (GIM), in which case the user must specify the number of bootstrapped datasets that the 
 analysis should be based on; or (B) uncertainty estimation using a Fisher Information Matrix
 (FIM), in which case no bootstrap files will be generated or used. It will generally be 
 more appropriate for the user to run a GIM analysis, as in most cases it will be more 
 realistic for SNP data to assume that they possess at least _some degree_ of linkage
 disequilibrium (e.g. created by physical proximity, or by gene flow). However, if the user
 has some _a priori_ reason to believe that their SNPs are unlinked, then a FIM analysis
 may be justified.
 
 In the case of a GIM analysis, the software will output a 'bootstrap_data' folder containing
 the bootstrapped datasets, a 'bootstrap_fs' folder of frequency spectrum files (corresponding 
 1-to-1 to the bootstrapped datasets), and an 'uncerts_GIM.txt' output file containing the 
 GIM-based standard deviations. In the case of FIM analysis, the software will output only a 
 single 'uncerts_FIM.txt' file containing the FIM-based standard deviations. 
 
 For additional details about GIM and FIM analyses, see the ∂a∂i user's manual as well as 
 the paper by Coffman et al. (2015).
 
		## Usage examples: 
		##--Example from 'real' analysis of a three-population southwestern white pine dataset
		##--containing a downsample of 6330 SNPs (1 per ddRAD-seq contig), in which 250 bootstrapped
		##--datasets are generated and analyzed using the GIM approach. _NOTE: '\' indicates that a
		##--command carries over to the next line. When this is the case, all lines separated by this
		##--character would actually be run from the command line as a single string/line._

		./dadiUncertainty.sh -a assignments.txt -i \'LP\',\'core\',\'periphery\' -p 98,46,156 \\
		-n 250 -m 1 -s M4.py -e 0.72828532,0.29458734,0.96806661,5.30191219,6.90827885,\\
		4.35076242,8.80921022,0.0349316,0.00881585 55Pops.recode.6330IDs.vcf
 
		## Same as above, except specifying the FIM method for unlinked SNPs:
 
		./dadiUncertainty.sh -a assignments.txt -i \'LP\',\'core\',\'periphery\' -p 98,46,156 \\
		-n 250 -m 2 -s M4.py -e 0.72828532,0.29458734,0.96806661,5.30191219,6.90827885,\\
		4.35076242,8.80921022,0.0349316,0.00881585 55Pops.recode.6330IDs.vcf
 
 CITATION
 Bagley, J.C. 2017. PIrANHA. GitHub package, Available at: 
	<http://github.com/justincbagley/PIrANHA>.
 or
 Bagley, J.C. 2017. PIrANHA. [Data set] Zenodo, Available at: 
	<http://doi.org/10.5281/zenodo.596766>.
 or
 Bagley, J.C. 2017. justincbagley/PIrANHA. GitHub package, Available at: 
	<http://doi.org/10.5281/zenodo.596766>.

 REFERENCES
 Coffman AJ, Hsieh PH, Gravel S, Gutenkunst RN (2015) Computationally efficient composite 
    likelihood statistics for demographic inference. Molecular Biology and Evolution, 33(2), 
    591-593.
 Gutenkunst RN, Hernandez RD, Williamson SH, Bustamante CD (2009) Inferring the joint 
 	demographic history of multiple populations from multidimensional SNP frequency data. 
 	PLoS Genetics, 5(10), e1000695.
"

if [[ "$1" == "-h" ]] || [[ "$1" == "-help" ]]; then
	echo "$Usage"
	exit
fi

############ PARSE THE OPTIONS
while getopts 'a:i:p:n:m:s:e:d:' opt ; do
  case $opt in

## vcfSubsampler options:
    a) MY_ASSIGNMENT_FILE=$OPTARG ;;
    i) MY_POP_IDS=$OPTARG ;;
    p) My_PROJECTION_VALUES=$OPTARG ;;
    n) MY_NUM_BOOT_DATASETS=$OPTARG ;;
    m) UNCERT_METHOD_SWITCH=$OPTARG ;;
    s) MY_DADI_MODEL_SCRIPT=$OPTARG ;;
    e) MY_BESTMOD_PARAM_ESTIMATES=$OPTARG ;;
    d) DELETE_ORIG_VCF=$OPTARG ;;

## Missing and illegal options:
    :) printf "Missing argument for -%s\n" "$OPTARG" >&2
       echo "$Usage" >&2
       exit 1 ;;
   \?) printf "Illegal option: -%s\n" "$OPTARG" >&2
       echo "$Usage" >&2
       exit 1 ;;
  esac
done

############ SKIP OVER THE PROCESSED OPTIONS
shift $((OPTIND-1)) 
# Check for mandatory positional parameters
if [ $# -lt 1 ]; then
echo "$Usage"
  exit 1
fi
## Make input file a mandatory parameter:
MY_INPUT_VCF="$1"


echo "
##########################################################################################
#                          dadiUncertainty v0.1.0, October 2017                          #
##########################################################################################
"

######################################## START ###########################################
echo "INFO      | $(date) | Starting dadiUncertainty analysis... "

###### Set paths and filetypes as different variables:
	MY_WORKING_DIR="$(pwd)"
	echo "INFO      | $(date) | Setting working directory to: "
	echo "$MY_WORKING_DIR "	

	TAB=$(printf '\t');
	calc () {
		bc -l <<< "$@" 
	}


################# SECTION I. PREP BOOTSTRAPPED SNP DATA FILES, AND FREQUENCY SPECTRA FOR UNCERTAINTY ANALYSIS:

####### makePerlScripts.sh

echo "INFO      | $(date) | STEP #1: MAKE VCF AND BOOTSTRAP PERL SCRIPTS. "

####### MAKE MIKHAIL MATZ PERL SCRIPTS

##--Use special cat procedure (https://stackoverflow.com/questions/11279335/bash-write-to-file-without-echo)
##--to make text of Perl scripts for going vcf to dadi format, and for creating basic boot-
##--strapped datasets, resampling by gene. I acknowledge Mikhail Matz's contribution and attribute
##--the dadiBoot.pl script to him, but here (https://groups.google.com/forum/#!searchin/dadi-user/Mikhail$20dadiBoot.pl%7Csort:relevance/dadi-user/kvzhF4XSyng/idVM5lLUpt0J )
##--Matz claims that the vcf2dadi.pl script was 'cannibalized' from somewhere else he didn't 
##--recall, and thus was not his. However, his dadiBoot.pl script is incomplete because it 
##--resamples by gene with replacement, but leaving _duplicate Gene names_, which could 
##--cause problems. Here, I have included code within dadiUncertainty.sh that corrects this
##--issue and ensures that all Gene names are unique. 

	###################################### vcf2dadi.pl #######################################

cat <<EOF > vcf2dadi.pl

#!/usr/bin/env perl
use strict;
use warnings;
#use Bio::SeqIO;

## my \$usage=\quote
## 
## Usage: perl vcf2dadi.pl <vcf file> <list file>
## 
## Genome file is in fasta format;
## List file gives population designations, like this:
## 
## sample1    population1
## sample2    population1
## sample3    population2
## 
## \quote;

my \$usage=000000000;

if (!\$ARGV[1]) { die \$usage;}
my (\$VCF,\$list)=@ARGV;

my %list;
open(IN,\quote< \$list\quote)||die\quote\$!\quote;
while (<IN>) {
    chomp;
    next if(/^\#/);
    my @a=split(/\s+/);
    \$list{\$a[0]}=\$a[1];
}
close IN;

my %vcf;
my %pop;
my %record;
my %crec;
my @chroms;
open(IN,\quote< \$VCF\quote);
while (<IN>) {
    chomp;
    next if(/^##/);
    if(/^#/){
        my @a=split(/\s+/);
        for(my \$i=9;\$i<@a;\$i++){
            next if(!exists \$list{\$a[\$i]});
#            die\quote\$a[\$i] does not exists in \$list\n\quote if(!exists \$list{\$a[\$i]});
            \$record{\$i}=\$list{\$a[\$i]};
        }
        next;
    }
    my @a=split(/\s+/);
    my (\$chr,\$pos,\$ref,\$alt)=(\$a[0],\$a[1],\$a[3],\$a[4]);
    if (!\$crec{\$chr}) {
\TAB    push @chroms, \$chr;
\TAB    \$crec{\$chr}=1;
#print \quote@chroms\n-----\n\quote;
\TAB}
    next if(\$alt=~/,/);

    \$vcf{\$chr}{\$pos}{ref}=\$ref;
    \$vcf{\$chr}{\$pos}{alt}=\$alt;
#   print \quote--------------\n\$ref\t\$alt\n\quote;
    foreach my \$i(keys %record){
        my \$indv=\$record{\$i};
        \$pop{\$indv}=1;
#       print \quote\$indv\t\quote;
        my \$geno=\$a[\$i];
#       print \quote\$geno\t\quote;
        \$geno=~/^(.)[\/\|](.):/;
        my \$tempa=\$1;
        my \$tempb=\$2;
#       print \quote\$tempa \$tempb\n\quote;
        my (\$a1,\$a2)=(0,0);
        if(\$tempa eq \quote.\quote || \$tempb eq \quote.\quote){
            \$a1=0;
            \$a2=0;
        }
        elsif (\$tempa+\$tempb == 1) {
            \$a1=1;
            \$a2=1;
        }
        elsif (\$tempa+\$tempb == 2) {
            \$a1=0;
            \$a2=2;
        }
        elsif (\$tempa+\$tempb == 0) {
            \$a1=2;
            \$a2=0;
        }
        \$vcf{\$chr}{\$pos}{\$indv}{a1}+=\$a1;
        \$vcf{\$chr}{\$pos}{\$indv}{a2}+=\$a2;
    }
    #last;
}
close IN;

\$VCF=~s/\..+//;
my \$outname=\$VCF.\quote_dadi.data\quote;
open(O,\quote> \$outname\quote);
my \$title=\quoteNAME\tOUT\tAllele1\quote;
foreach my \$pop(sort keys %pop){
    \$title.=\quote\t\$pop\quote;
}
\$title.=\quote\tAllele2\quote;
foreach my \$pop(sort keys %pop){
    \$title.=\quote\t\$pop\quote;
}
\$title.=\quote\tGene\tPostion\n\quote;
print O \quote\$title\quote;
foreach my \$id (@chroms){
#print \quotechrom \$id...\n\quote;
    foreach my \$pos (sort {\$a<=>\$b} keys %{\$vcf{\$id}}){
        my \$ref=\quoteA\quote.\$vcf{\$id}{\$pos}{ref}.\quoteA\quote;
        my \$line=\quote\$ref\t\$ref\t\$vcf{\$id}{\$pos}{ref}\quote;
        foreach my \$pop(sort keys %pop){
            my \$num=\$vcf{\$id}{\$pos}{\$pop}{a1};
            \$line.=\quote\t\$num\quote;
        }
        \$line.=\quote\t\$vcf{\$id}{\$pos}{alt}\quote;
        foreach my \$pop(sort keys %pop){
            my \$num=\$vcf{\$id}{\$pos}{\$pop}{a2};
            \$line.=\quote\t\$num\quote;
        }
        \$line.=\quote\t\$id\t\$pos\n\quote;
        print O \quote\$line\quote;
    }
}
close O;

EOF

	sed -i '' 's/\\quote/\"/g' ./vcf2dadi.pl
	sed -i '' $'s/\TAB/\t/g' ./vcf2dadi.pl
	sed -i '' 's/^\\//g' ./vcf2dadi.pl



###################################### dadiBoot.pl #######################################


cat <<EOF > dadiBoot.pl

#!/usr/bin/env perl

## \$usage=\quote
## 
## dadiBoot.pl: generates bootstrapped dadi data
## 
## Arguments:
## 
## in=[filename] : file generated by vcf2dadi.pl. Bootstrap will be done with replacement
##                 over entries in the \\quoteGene\\quote column.
##                 
## boot=[integer]: number of bootstrap replicates. Default 100.
## 
## Output: 
## Files named as the infile with \\quote.boot[repnum]\\quote appended
## (the last digit in the coordinates of SNPs in the bootstrapped files is the repeat 
## number for that gene; this is to make all the last column entries unique) 
## 
## Mikhail Matz, UT Austin, matz\@utexas.edu
## \quote;

my \$usage=000000000;

my \$inname;
my \$nboot=100;
if (\quote@ARGV\quote=~/in=(\S+)/) {  \$inname=\$1; } else { die \$usage;}
if (\quote@ARGV\quote=~/boot=(\d+)/) {  \$nboot=\$1; }

my %bygene={};

open IN, \quote\$inname\quote or die \quotecannot open \$inname\n\quote;
my \$g=0;
my \$header;
while (<IN>) {
\TABif (\$g==0) {
\TAB\TAB\$header=\$_;
\TAB\TABmy @h=split(\singlequote\s\singlequote,\$header);
\TAB\TABfor (\$g=0;\$h[\$g] ne \quoteGene\quote;\$g++){}
print \quotegenecolumn: \quote,\$g+1,\quote\n\quote;
\TAB\TABnext;
\TAB}
\TABmy @l=split(\singlequote\s\singlequote,\$_);
\TAB\$bygene{\$l[\$g]}.=\$_;
}

my @genes=keys(%bygene);
my \$ngenes=\$#genes+1;
print \quote\$ngenes genes detected\n\quote;
my \$b=0;
for (\$b=1;\$b<=\$nboot;\$b++){
\TABmy \$bootfile =\$inname.\quote.boot\quote.\$b;
print \quoteboot \$b\n\quote;
\TABopen BOOT, \quote>\$bootfile\quote or die \quotecannot create \$bootfile\n\quote;
\TABprint {BOOT} \$header;
\TABmy %seen;
\TABfor (\$g=0;\$g<\$ngenes;\$g++){
\TAB\TABmy \$gene=int(rand(\$#genes));
\TAB\TAB\$seen{\$gene}++;
\TAB\TABmy \$gname=\$genes[\$gene];
\TAB\TABmy \$line=\$bygene{\$gname};
\TAB\TAB\$line=~s/\n/\$seen{\$gene}\n/g;\TAB\TAB
\TAB\TABprint {BOOT} \$bygene{\$genes[\$gene]};
\TAB}
\TABclose BOOT;
}

EOF

	sed -i '' 's/\\quote/\"/g' ./dadiBoot.pl
	sed -i '' "s/\\singlequote/'/g" ./dadiBoot.pl
	sed -i '' $'s/\TAB/\t/g' ./dadiBoot.pl
	sed -i '' 's/^\\//g' ./dadiBoot.pl
	perl -p -i -e 's/\t\\\t/\t\t/g' dadiBoot.pl
	sed -i '' 's/\;\\/\;/g' ./dadiBoot.pl
	perl -p -i -e 's/\\'\''\\s\\'\''/'\''\\s'\''/g' dadiBoot.pl


################# SECTION II. PREP BOOTSTRAPPED SNP DATA FILES & SPECTRA FOR UNCERTAINTY ANALYSIS:

echo "INFO      | $(date) | STEP #2: FIX SCRIPT PERMISSIONS, CONVERT VCF TO DADI AND MAKE FIRST-ROUND BOOTSTRAPPED DATA FILES. "
#######
##--Ensure correct execute permissions on shell and perl scripts in current working dir:
	chmod u+x ./*.sh ./*.pl

##--Use vcf2dadi.pl perl script to convert vcf to dadi (dictionary) input file:
	perl vcf2dadi.pl "$MY_INPUT_VCF" "$MY_ASSIGNMENT_FILE"


##--Use dadiBoot.pl perl script to make first round of bootstrapped SNP dataset files, which 
##--will contain the following string near the end of the filename: 'data.boot'
	MY_DADI_DATA_FROM_VCF2DADI="$(find . -name "*dadi.data" -type f)"
	perl dadiBoot.pl in="$MY_DADI_DATA_FROM_VCF2DADI"


echo "INFO      | $(date) | STEP #3: FIX BOOTSTRAPPED DATA FILES SO THAT ALL GENE NAMES ARE UNIQUE. "
##--Make all Gene names (in 'Gene' column) _unique_ in bootstrapped data files:
	(
		for i in ./*dadi.data.boot*; do
		echo "$i"

				count=0
				while read line; do 
					echo "$line" > ./file1.tmp; 
					sed "s/$TAB\([0-9]\{1,3\}\)$/\_$count$TAB\1/g" ./file1.tmp >> ./file2.tmp; 
					COUNT_PLUS_ONE="$((count++))"; 
				done < ./"$i"

			rm "$i"
			mv ./file2.tmp "$i"
		done
	)


echo "INFO      | $(date) | STEP #4: GENERATE AND USE CUSTOM PYTHON SCRIPTS TO MAKE SITE FREQUENCY SPECTRA "
echo "INFO      | $(date) |          (.fs FILES) FOR EACH BOOTSTRAPPED DATA FILE. "
#######
##--Make frequency spectra for all bootstrapped data files:


################# A. DRAFT CUSTOM PYTHON SCRIPT TO MAKE CONTENT/BODY CODE FOR FINAL PYTHON SCRIPT:
##--Draft custom Python script:

MY_NUM_BOOT_DATASETS_PLUSONE="$(calc $MY_NUM_BOOT_DATASETS + 1)"
MY_DADI_DATA_BOOT_BASENAME="$(ls ./*dadi.data.boot* | head -n1 | sed 's/\.\///; s/\(^.*boot\)[0-9]*$/\1/g')"

echo "
#!/usr/bin/env python

import dadi
import pylab
import numpy as np
from numpy import array
from dadi import Misc,Spectrum,Numerics,PhiManip,Integration
import json


i=0

step1_make_dd_code = \quotedd%i = Misc.make_data_dict('$MY_DADI_DATA_BOOT_BASENAME%i')\quote
step2_make_fs = \quotefs%i = Spectrum.from_data_dict(dd%i, pop_ids=[$MY_POP_IDS], projections=[$My_PROJECTION_VALUES], polarized=False)\quote
step3_reset_fs = \quotefs = fs%i\quote
step4_save_fs_file = \quotefs.to_file('%i.fs')\quote

for i in range(1,$MY_NUM_BOOT_DATASETS_PLUSONE):
\TABiter=i
\TABiter_duple=(i, i)
\TABiter_tuple=(i, i, i)
\TABprint(step1_make_dd_code % iter_duple)
\TABprint(step2_make_fs % iter_duple)
\TABprint(step3_reset_fs % iter)
\TABprint(step4_save_fs_file % iter)

" > scriptMaker.py

##--Fix "\quote" in ./scriptMaker.py by adding in real double quote, '\"'; fix \TAB by adding in 
##--real tab, '\t'. Do this using in-place sed editing (-i flag):
	sed -i '' 's/\\quote/\"/g' ./scriptMaker.py
	sed -i '' $'s/\TAB/\t/g' ./scriptMaker.py
	sed -i '' 's/^\\//g' ./scriptMaker.py


################# B. DRAFT CUSTOM makeBootFS PYTHON SCRIPT THAT WILL ACTUALLY MAKE THE BOOTSTRAP FS FILES:
##--Make first-draft makeBootFS python script:
	python ./scriptMaker.py >> ./makeBootFS.py.tmp
	sed -i '' '/error.*$/d' ./makeBootFS.py.tmp

##--Make python header for final python file:
echo "
#!/usr/bin/env python

import dadi
import pylab
import numpy as np
from numpy import array
from dadi import Misc,Spectrum,Numerics,PhiManip,Integration
import json

" > py_header.tmp

##--Make final makeBootFS.py python script that, when called, will use ∂a∂i to create a data 
##--dictionary and make the fs for each bootstrapped dataset: 
	cat ./py_header.tmp ./makeBootFS.py.tmp > ./makeBootFS.py


################# C. MAKE SITE FREQUENCY SPECTRA (.fs) FILES FOR ALL BOOTSTRAPPED DATASETS USING makeBootFS.py:
##--Call final makeBootFS.py python script to make all of the .fs files for the bootstrapped
##--datasets:
	python ./makeBootFS.py


################# D. FIX NAMES OF SITE FREQUENCY SPECTRA TO BE FROM 00.fs TO y.fs, WHERE y IS THE TOTAL NUMBER
#################    OF BOOTSTRAPPED DATASETS MINUS ONE (y = n - 1) AND y SPANS TWO CHARACTERS, AND CLEAN 
#################    UP WORKING DIR.
##--In practice, just change the last boot*.fs file to be named 'boot00.fs':
	mv ./"$MY_NUM_BOOT_DATASETS".fs ./00.fs
	mv ./1.fs ./01.fs
	mv ./2.fs ./02.fs
	mv ./3.fs ./03.fs
	mv ./4.fs ./04.fs
	mv ./5.fs ./05.fs
	mv ./6.fs ./06.fs
	mv ./7.fs ./07.fs
	mv ./8.fs ./08.fs
	mv ./9.fs ./09.fs

##--Clean up bootstrap fs files by creating a 'bootstrap_fs' directory and placing all of 
##--them in that directory for safe keeping and analysis:
	mkdir ./bootstrap_fs/
	cp ./*.fs ./bootstrap_fs/
	rm ./*.fs

##--Also clean up original bootstrapped datasets by creating 'bootstrap_data' folder and 
##--placing all bootstrapped datasets in that directory for safe keeping:
	mkdir ./bootstrap_data/
	cp ./*dadi.data.boot* ./bootstrap_data/
	rm ./*dadi.data.boot*

##--Check to make sure you have the correct number of bootstrap .fs files in the 'bootstrap_fs'
##--folder. If not, throw error message to screen out (and save to file) but continue analysis 
##--with/despite error(s)...
	MY_NUM_BOOT_FS_FILES="$(ls ./bootstrap_fs/* | wc -l)"
	if [[ "$MY_NUM_BOOT_FS_FILES" = "$MY_NUM_BOOT_DATASETS" ]]; then 
		echo "INFO      | $(date) |          $MY_NUM_BOOT_FS_FILES files present in bootstrap_fs directory: Bootstrap .fs file check PASSED! Continuing without errors... "
	elif [[ "$MY_NUM_BOOT_FS_FILES" != "$MY_NUM_BOOT_DATASETS" ]]; then
		echo "WARNING!  | $(date) |          $MY_NUM_BOOT_FS_FILES files present in bootstrap_fs directory: Bootstrap .fs file check FAILED! Continuing WITH ERRORS... "
		echo "WARNING!  | $(date) |          $MY_NUM_BOOT_FS_FILES files present in bootstrap_fs directory: Bootstrap .fs file check FAILED! Continuing WITH ERRORS... " >> errors.txt
	fi

##--Cleanup temporary files (i.e. delete Matz perl scripts and any tmp files):
	if [[ -n $(find . -name "*.pl" -type f) ]]; then rm ./*.pl; fi
	if [[ -n $(find . -name "*.tmp" -type f) ]]; then rm ./*.tmp; fi





################# SECTION III. RUN FINAL UNCERTAINTY ANALYSES WITH/WITHOUT BOOTSTRAP .fs FILES:
echo "INFO      | $(date) | STEP #5: CONDUCT FINAL ∂a∂i UNCERTAINTY ANALYSES AS SPECIFIED BY USER. "
#######

	if [[ "$UNCERT_METHOD_SWITCH" = "1" ]]; then

	######### A. GIM ANALYSIS: THIS SECTION WILL MAKE A CUSTOM PYTHON SCRIPT AND THEN USE IT TO RUN
	######### THE GIM ANALYSIS AND SAVE RESULTS TO FILE

	##### GOALS:
	## In the case of a GIM analysis, the software will output a folder of bootstrapped datasets,
	## a folder of frequency spectrum files (corresponding 1-to-1 to the bootstrapped datasets),
	## and an output file containing the GIM-based standard deviations. In the case of FIM analysis, 
	## the software will output only a single output file containing the FIM-based standard 
	## deviations. 

	## Let's start with automating a GIM analysis...

	##--Rules: (1) the first line of the .py ∂a∂i input file should contain the python env shebang,
	##--and the second or third line should start importing modules, thus begin with the 'import'
	##--command. (2) The final executable function of the .py file should be named 'func_ex', and 
	##--the first time this function name should be used should be the point at which it is defined
	##--(this will usually be the case). The line where the grid points are defined must be the
	##--first line with a list of numbers in square brackets (this is usually the case; it is also
	##--a good idea [though not required] for this variable name to be some variation that starts 
	##--with the string 'pts').

	echo "INFO      | $(date) |          Prepping custom Python script for GIM-based uncertainty analysis in ∂a∂i... "
	##--Line at which the preamble of .py file starts is assumed to be 2nd line or 3rd line,
	##--but start with 2nd by default:
	MY_PY_PREAMBLE_START=2

	##--The second important number is the first line where 'func_ex' occurs and is defined,
	##--which we find this way:
	MY_PY_PREAMBLE_STOP="$(grep -n "func\_ex" ./M6_run_8.py | head -n1 | sed 's/\:.*//g')"

	##--Now pull the preamble from the original .py script file ($MY_DADI_MODEL_SCRIPT):
	sed -n "$MY_PY_PREAMBLE_START","$MY_PY_PREAMBLE_STOP"p "$MY_DADI_MODEL_SCRIPT" > ./py_preamble.tmp

	##--Now make new py shebang header for GIM anaysis:
echo "
#!/usr/bin/env python

###  GIM ANALYSIS  ###
" > py_shebang_header.tmp
sed -i '' '1d' ./py_shebang_header.tmp 

	##--Automatically detect whether spectra are folded (no outgroup) or not folded (polarized,
	##--that is, having the ancestral state known, because an outgroup was available to determine
	##--the ancestral state for each SNP/variant), and use this information to make custom 
	##--Python script for GIM analysis:
	
	##### Folded test:
	if [[ -n $(find . -name "*.fs" -type f) ]]; then 
		MY_FOLDED_TEST="$(grep -n "folded" ./*.fs | sed 's/\:.*//g')"
	fi
	if [[ -n $(find . -name "*.sfs" -type f) ]]; then 
		MY_FOLDED_TEST="$(grep -n "folded" ./*.sfs | sed 's/\:.*//g')"
	fi


	##### Make custom popt var w/ best parameter estimates from actual demographic model run:
	if [[ "$MY_FOLDED_TEST" = "0" ]] || [[ -z "$MY_FOLDED_TEST" ]]; then

echo "
## Unfolded case: Save best-fit parameter estimates from the run in popt:
popt = [$MY_BESTMOD_PARAM_ESTIMATES]
" > popt.tmp

	elif [[ "$MY_FOLDED_TEST" -gt "0" ]]; then

echo "
## Folded case: Save best-fit parameter estimates from the run in popt:
popt = array([$MY_BESTMOD_PARAM_ESTIMATES])
" > popt.tmp

	fi

	##### Make part of custom GIM py file that will (1) place all frequency spectra from bootstrapped
	## datasets into 'all_boot' variable using absolute path, and (2) conduct GIM analysis. Make
	## sure that the folded test is used to choose the correct code, depending on whether the
	## spectra are folded or not. Before making the actual tmp python code, check the name
	## of the pts var in the user's demographic model .py file and make sure you place that same
	## var name in the code to follow:
	MY_PTS_VAR_NAME="$(grep -h '\[[0-9]*\,[0-9]*' $MY_DADI_MODEL_SCRIPT | head -n1 | sed 's/\=.*//g; s/\ //g')"

echo "
## Place all frequency spectra from bootstrapped datsets into 'all_boot' var:
all_boot = [dadi.Spectrum.from_file(\'$MY_WORKING_DIR/bootstrap_fs/{0:02d}.fs'.format(ii))
             for ii in range($MY_NUM_BOOT_DATASETS)]

uncerts_GIM = dadi.Godambe.GIM_uncert(func_ex, $MY_PTS_VAR_NAME, all_boot, popt, data, multinom=True)


" > all_boot_runGIM.tmp

##--Use sed to unescape the escaped single quote in the 'all_boot =...' line of all_boot_runGIM.tmp
	sed -i '' 's/file(\\/file(/g' ./all_boot_runGIM.tmp

##--ADD ONE MORE SECTION TO SCRIPT HERE (python file) TO PRINT RESULTS TO FILE --##
echo "
## Print FIM results to screen
uncerts_GIM

## Save uncertainty estimates from numpy array to file:
np.savetxt('uncerts_GIM.tmp', uncerts_GIM, fmt='%2.10f', delimiter=',')

" > ./printResults.tmp
	
##--Use cat to make final custom GIM analysis script:
	cat ./py_shebang_header.tmp ./py_preamble.tmp ./popt*tmp ./all_boot_runGIM.tmp ./printResults.tmp > ./customGIM.py

##--RUN CUSTOM GIM SCRIPT:
	echo "INFO      | $(date) |          Running uncertainty analysis using the GIM... "
	python ./customGIM.py

##--Fix output uncerts_GIM.tmp file so that it contains each parameter name followed by its 
##--stdev estimate, in tab-separated text file format:
	if [[ -n $(find . -name "uncerts_GIM.tmp" -type f) ]]; then 
		grep -h "\=\ params\|params\ \=" ./"$MY_DADI_MODEL_SCRIPT" | head -n1 | sed 's/\ //g; s/\=//g; s/params//g' | perl -pe 's/\t//g' > ./params.tmp.txt
		perl -p -i -e 's/\,/\n/g' ./params.tmp.txt
		echo "theta" >> ./params.tmp.txt		## Since multinom=True in dadi.Godambe.GIM_uncert(...) function, there is an extra entry (at end) in the standard deviations (which is too large to make any sense at all) that corresponds to theta, which was not estimated in the model. Of course, the theta stdev is meaningless; but this line adds a label for it to the first column of the results file.
#		
		paste ./params.tmp.txt ./uncerts_GIM.tmp > ./uncerts_GIM.txt
	fi

fi




	if [[ "$UNCERT_METHOD_SWITCH" = "2" ]]; then
		## Run FIM analysis (unlinked SNPs only) - make custom python script to run analysis, then call it.

	######### B. FIM ANALYSIS: THIS SECTION WILL MAKE A CUSTOM PYTHON SCRIPT AND THEN USE IT TO RUN
	######### THE FIM ANALYSIS AND SAVE RESULTS TO FILE

	## Now, let's automate a FIM analysis...

	##--Rules for files are the same as for the GIM analysis, only the uncertainty estimation
	##--and output files differ.

	echo "INFO      | $(date) |          Prepping custom Python script for FIM-based uncertainty analysis in ∂a∂i... "
	##--Line at which the preamble of .py file starts is assumed to be 2nd line or 3rd line,
	##--but start with 2nd by default:
	MY_PY_PREAMBLE_START=2

	##--The second important number is the first line where 'func_ex' occurs and is defined,
	##--which we find this way:
	MY_PY_PREAMBLE_STOP="$(grep -n "func\_ex" ./M6_run_8.py | head -n1 | sed 's/\:.*//g')"

	##--Now pull the preamble from the original .py script file ($MY_DADI_MODEL_SCRIPT):
	sed -n "$MY_PY_PREAMBLE_START","$MY_PY_PREAMBLE_STOP"p "$MY_DADI_MODEL_SCRIPT" > ./py_preamble.tmp

	##--Now make new py shebang header for FIM anaysis:
echo "
#!/usr/bin/env python

###  FIM ANALYSIS  ###
" > py_shebang_header.tmp
sed -i '' '1d' ./py_shebang_header.tmp 

	##--Automatically detect whether spectra are folded (no outgroup) or not folded (polarized,
	##--that is, having the ancestral state known, because an outgroup was available to determine
	##--the ancestral state for each SNP/variant), and use this information to make custom 
	##--Python script for FIM analysis:
	
	##### Folded test:
	if [[ -n $(find . -name "*.fs" -type f) ]]; then 
		MY_FOLDED_TEST="$(grep -n "folded" ./*.fs | sed 's/\:.*//g')"
	fi
	if [[ -n $(find . -name "*.sfs" -type f) ]]; then 
		MY_FOLDED_TEST="$(grep -n "folded" ./*.sfs | sed 's/\:.*//g')"
	fi


	##### Make custom popt var w/ best parameter estimates from actual demographic model run:
	if [[ "$MY_FOLDED_TEST" = "0" ]] || [[ -z "$MY_FOLDED_TEST" ]]; then

echo "
## Unfolded case: Save best-fit parameter estimates from the run in popt:
popt = [$MY_BESTMOD_PARAM_ESTIMATES]
" > popt.tmp

	elif [[ "$MY_FOLDED_TEST" -gt "0" ]]; then

echo "
## Folded case: Save best-fit parameter estimates from the run in popt:
popt = array([$MY_BESTMOD_PARAM_ESTIMATES])
" > popt.tmp

	fi

	##### Make part of custom FIM py file that will (1) place all frequency spectra from bootstrapped
	## datasets into 'all_boot' variable using absolute path, and (2) conduct FIM analysis. Make
	## sure that the folded test is used to choose the correct code, depending on whether the
	## spectra are folded or not. Before making the actual tmp python code, check the name
	## of the pts var in the user's demographic model .py file and make sure you place that same
	## var name in the code to follow:
	MY_PTS_VAR_NAME="$(grep -h '\[[0-9]*\,[0-9]*' $MY_DADI_MODEL_SCRIPT | head -n1 | sed 's/\=.*//g; s/\ //g')"

echo "
## Place all frequency spectra from bootstrapped datsets into 'all_boot' var:
all_boot = [dadi.Spectrum.from_file(\'$MY_WORKING_DIR/bootstrap_fs/{0:02d}.fs'.format(ii))
             for ii in range($MY_NUM_BOOT_DATASETS)]

uncerts_FIM = dadi.Godambe.FIM_uncert(func_ex, $MY_PTS_VAR_NAME, popt, data, multinom=True)

" > all_boot_runFIM.tmp

##--Use sed to unescape the escaped single quote in the 'all_boot =...' line of all_boot_runFIM.tmp
	sed -i '' 's/file(\\/file(/g' ./all_boot_runFIM.tmp

##--ADD ONE MORE SECTION TO SCRIPT HERE (python file) TO PRINT RESULTS TO FILE --##
echo "
## Print FIM results to screen
uncerts_FIM

## Save uncertainty estimates from numpy array to file:
np.savetxt('uncerts_FIM.tmp', uncerts_FIM, fmt='%2.10f', delimiter=',')

" > ./printResults.tmp
	
##--Use cat to make final custom FIM analysis script:
	cat ./py_shebang_header.tmp ./py_preamble.tmp ./popt*tmp ./all_boot_runFIM.tmp ./printResults.tmp > ./customFIM.py

##--RUN CUSTOM GIM SCRIPT:
	echo "INFO      | $(date) |          Running uncertainty analysis using the FIM... "
	python ./customFIM.py

##--Fix output uncerts_GIM.tmp file so that it contains each parameter name followed by its 
##--stdev estimate, in tab-separated text file format:
	if [[ -n $(find . -name "uncerts_FIM.tmp" -type f) ]]; then 
		grep -h "\=\ params\|params\ \=" ./"$MY_DADI_MODEL_SCRIPT" | head -n1 | sed 's/\ //g; s/\=//g; s/params//g' | perl -pe 's/\t//g' > ./params.tmp.txt
		perl -p -i -e 's/\,/\n/g' ./params.tmp.txt
		echo "theta" >> ./params.tmp.txt		## Since multinom=True in dadi.Godambe.GIM_uncert(...) function, there is an extra entry (at end) in the standard deviations (which is too large to make any sense at all) that corresponds to theta, which was not estimated in the model. Of course, the theta stdev is meaningless; but this line adds a label for it to the first column of the results file.
#		
		paste ./params.tmp.txt ./uncerts_FIM.tmp > ./uncerts_FIM.txt
	fi

fi



################# 

echo "INFO      | $(date) | STEP #6: CLEAN UP WORK ENVIRONMENT (TEMPORARY FILES). "
##--Cleanup temporary files (i.e. delete Matz perl scripts and any tmp files):
	rm ./*.tmp;


##--Final cleanup:
##--Delete the original .vcf file if user has specified to do so:
	if [[ "$DELETE_ORIG_VCF" = 0 ]]; then
		echo ""
	elif [[ "$DELETE_ORIG_VCF" = 1 ]]; then
		rm ./"$MY_INPUT_VCF"
	fi


echo "INFO      | $(date) | Done creating bootstrapped SNP datasets and conducting uncertainty analysis in ∂a∂i "
echo "INFO      | $(date) | using the dadiUncertainty pipeline in PIrANHA." 
echo "INFO      | $(date) | Bye.
"
#
#
#
######################################### END ############################################

exit 0
