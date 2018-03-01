#!/bin/bash
# Date: 2017-11-23
# Author: Zhao
# Purpose: rename fasta seq label as sequential ids

# Usage:
# rename_fasta <sequence.fa> <new_label>

FAFILE=$1
NEW=$2
OLDNAMES=($(fastalength $FAFILE |cut -f2 -d' '))

for ((i=0; i<=${#OLDNAMES[@]}-1; i++ )); do
    OLDNAME=${OLDNAMES[$i]}
    NEWNAME="${NEW}_$i $OLDNAME"
    echo $NEWNAME
    echo $OLDNAME
    sed -i -e "s/$OLDNAME/$NEWNAME/" $FAFILE
done
