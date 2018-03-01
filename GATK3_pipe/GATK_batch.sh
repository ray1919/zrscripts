for i in $(seq 2 10); do
    echo $i
    bash GATK_individual.sh -XP -g "GCH1 GCHFR PAH PCBD1 PTS QDPR" -a CTGTCTCTTATA -A CTGTCTCTTATA pku$i
done

