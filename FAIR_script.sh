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
    
    wget ${access} # wget method
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

exit 0