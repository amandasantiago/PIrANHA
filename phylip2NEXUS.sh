#!/bin/sh

##########################################################################################
#  __  o  __   __   __  |__   __                                                         #
# |__) | |  ' (__( |  ) |  ) (__(                                                        # 
# |                                                                                      #
#                          phylip2NEXUS v1.0, August 2016                                #
#   SHELL SCRIPT FOR CONVERTING A PHYLIP-FORMAT DNA SEQUENCE ALIGNMENT FILE TO NEXUS     #
#   FORMATTED FILE                                                                       #
#   Copyright (c)2016 Justin C. Bagley, Universidade de Brasília, Brasília, DF, Brazil.  #
#   See the README and license files on GitHub (http://github.com/justincbagley) for     #
#   further information. Last update: August 11, 2016. For questions, please email       #
#   jcbagley@unb.br.                                                                     #
##########################################################################################

echo "
##########################################################################################
#                          phylip2NEXUS v1.0, August 2016                                #
##########################################################################################
"

############ STEP #1: SETUP VARIABLES AND SETUP FUNCTIONS
###### Set working directory and filetypes as different variables:
echo "##########  STATUS: Examining current directory, setting variables... "
MY_WORKING_DIR="$(pwd)"
MY_PHYLIP="$(ls . | egrep '.phy$')"
MY_PHYLIP_LENGTH="$(cat $MY_PHYLIP | wc -l | sed 's/(\ )*//g')"

	calc () {										## Make the "handy bash function 'calc'" for subsequent use.
    	bc -l <<< "$@"
	}

MY_BODY_LENGTH="$(calc $MY_PHYLIP_LENGTH - 1)"
## This "MY_BODY_LENGTH" is number of lines comprised by sequence and eof lines; was going to call it "MY_SEQUENCE_AND_EOF_LINES" but thought that name was too long.

tail -n$MY_BODY_LENGTH $MY_PHYLIP > sequences.tmp

MY_NTAX="$(head -n1 $MY_PHYLIP | sed 's/\ [0-9]*//g'| sed 's/[\]*//g')"
MY_NCHAR="$(head -n1 $MY_PHYLIP | sed 's/^[0-9]*\ //g'| sed 's/[\]*//g')"

###### Make NEXUS format file:
echo "##########  STATUS: Making NEXUS formatted file... "

echo "#NEXUS

BEGIN DATA;
	DIMENSIONS NTAX="$MY_NTAX" NCHAR="$MY_NCHAR";
	FORMAT DATATYPE=DNA GAP=- MISSING=N;
	MATRIX" > NEXUS_top.tmp

echo ";
END;
" > NEXUS_bottom.tmp


MY_PHYLIP_BASENAME="$(echo $MY_PHYLIP | sed 's/\.phy//g')"

cat ./NEXUS_top.tmp ./sequences.tmp ./NEXUS_bottom.tmp > ./"$MY_PHYLIP_BASENAME"_p2N.nex


###### Remove temporary or unnecessary files created above:
echo "##########  Removing temporary files... "
rm ./NEXUS_top.tmp ./sequences.tmp ./NEXUS_bottom.tmp

echo "##########  Done converting Phylip-formatted DNA sequence alignment to NEXUS format. Bye.
"
#
#
#
######################################### END ############################################

exit 0
