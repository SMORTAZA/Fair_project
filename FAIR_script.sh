mkdir Project
mkdir Project/samples
mkdir Project/annotations
mkdir Project/bowtie2
mkdir Project/fastqc
mkdir Project/genome
mkdir Project/graphics
mkdir Project/htseq
mkdir Project/reference
mkdir Project/samtools

echo "=============================================================="
echo "Download data from SRA"
echo "=============================================================="

cd Project/samples

IFS=$'\n'       # make newlines the only separator
for j in $(tail -n +2 ../../conditions.txt)
do

	#Get important informations from the line
    access=$( echo "${j}" | cut -f6 )
    id=$( echo "${j}" | cut -f1 )
    md5=$( echo "${j}" | cut -f7 )

    echo "--------------------------------------------------------------"
    echo ${id}
    echo "--------------------------------------------------------------"
    
    #wget ${access} # wget method #mis en commentaire car déjà téléchargé
    md5_local="$(md5sum ${id}.fastq.gz | cut -d' ' -f1)"
    echo ${md5_local}

    if [ "${md5_local}" == "${md5}" ]
    then
        echo "MD5SUM : Ok"
    else
        echo "MD5SUM : error"
        exit 1
    fi
done

cd ../..

echo "=============================================================="
echo "Download annotations"
echo "=============================================================="

#wget https://raw.githubusercontent.com/thomasdenecker/FAIR_Bioinfo/master/Data/O.tauri_annotation.gff -P Project/annotations

echo "=============================================================="
echo "Download genome"
echo "=============================================================="

#wget https://raw.githubusercontent.com/thomasdenecker/FAIR_Bioinfo/master/Data/O.tauri_genome.fna -P Project/genome

# Liste des fichiers fastq.gz à analyser
dirlist=$(find Project/samples/*.fastq.gz)
# nom du fichier contenant le génome de référence
genome="./Project/genome/O.tauri_genome.fna"
# nom du fichier contenant les annotations
annotations="./Project/annotations/O.tauri_annotation.gff"

for file in ${dirlist}
do
    # Name without path
    file_name="$(basename $file)"
    # Name without path and .gz
    nameFastq="${file_name%.*}"
    # Name without path, .gz and fastq
    sample="${nameFastq%.*}"

    echo "====================================================================="
    echo "Contrôle qualité - échantillon ${sample}"
    echo "====================================================================="
    fastqc Project/samples/${sample}.fastq.gz --outdir Project/fastqc/

    echo "====================================================================="
    echo "Indexation du génome de référence"
    echo "====================================================================="
    bowtie2-build ${genome} O_tauri

    echo "====================================================================="
    echo "Alignement des reads sur le génome de référence - échantillon ${sample}"
    echo "====================================================================="
    bowtie2 -x O_tauri -U Project/samples/${sample}.fastq.gz -S Project/bowtie2/bowtie-${sample}.sam 2> Project/bowtie2/bowtie-${sample}.out

    echo "====================================================================="
    echo "Conversion en binaire, tri et indexation des reads alignés - échantillon ${sample}"
    echo "====================================================================="
    samtools view -b Project/bowtie2/bowtie-${sample}.sam > Project/samtools/bowtie-${sample}.bam
    samtools sort Project/samtools/bowtie-${sample}.bam -o Project/samtools/bowtie-${sample}.sorted.bam
    samtools index Project/samtools/bowtie-${sample}.sorted.bam

    echo "====================================================================="
    echo "Comptage - échantillon ${sample}"
    echo "====================================================================="
    htseq-count --stranded=no --type='gene' --idattr='ID' --order=name --format=bam Project/samtools/bowtie-${sample}.sorted.bam ${annotations} > Project/htseq/count-${sample}.txt

    echo "=============================================================="
    echo "Nettoyage des fichiers inutiles - échantillon ${sample}"
    echo "=============================================================="
    rm -f Project/samtools/bowtie-${sample}.sam Project/bowtie2/bowtie-${sample}.bam

done
