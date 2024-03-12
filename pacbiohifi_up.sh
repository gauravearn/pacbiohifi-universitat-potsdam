#!/usr/bin/bash 
# an entire workflow for the running of the high throughput cluster on the analysis of the genomes
# coming from the pacbiohifi using the verkko, hifiasm, genomeasm4pg
# below is a complete slurm configuration for the same
# Author Gaurav Sablok
# Universitat Potsdam
# Date: 2024-3-11
##################
                     echo "there are two assembly configurations available, either perform the assembly"
            echo "on the single reads or perform the assembly using the paternal and the maternal sequences"
            echo "you can easily integrate this into the snakemake patterns"
read -r -p "please select the option:" option
read -r -p "please provide the path to the directory on the slurmserver where the fastq files are located:" directory
read -r -p "please provide the path to the scratch directory on the slurmserver where the fastq files will be analyzed:" scratch
read -r -p "please provide the file with the links to the external fetch:" fetchfile
read -r -p "please select the assembly configuration:" configuration

if [[ ${configuration} == "singlereads" && "${option}" == "all" && \
		        ${directory} && ${scratch} ]]; then

echo "writing the sbatch configuration for the slurmruns"
echo #!/bin/bash
echo #SBATCH --partition=all
echo #SBATCH --nodes=1
echo #SBATCH --ntasks=1
echo #SBATCH --cpus-per-task=1
echo #SBATCH --mem=5G
echo #SBATCH --time=0-05:00
echo #SBATCH --chdir="${hostname}"
echo #SBATCH --mail-type=ALL
echo #SBATCH --output=slurm-%j.out
module list 
module load lang/Anaconda3/2021.05
### moving the files for the analysis
cp -r ${directory}/*.fastq.gz ${scratch} 
cd ${scratch}
for i in *.gz; do gunzip "${i}"; done
### creating and activating the conda environment
conda create -n verkko 
conda install -n verkko -c conda-forge -c bioconda defaults verkko
conda clean -t 
conda create -n quast 
source activate quast 
pip3 install quast 
source deactivate
conda clean -t 
echo "the environment for the analysis have been created and modified"
source activate verkko
declare -a files=()
for i in $(ls -l *.fastq.gz)
  do 
     files+=("${i}")
  done
for i in files 
   do 
      echo verkko -d "${i%.**}" --hifi "${i}" 
   done
mkdir fasta_files_assembly
for i in "${scratch}"/"${i%.**}"/assembly.fasta
   do 
	cp -r "${scratch}"/"${i%.**}"/assembly.fasta fasta_files_assembly/"${i%.**}".fasta
   done
      echo "the assembly files for the verkko have been moved and assembled and you can find them in the address"
      echo "${scratch}/fasta_files_assembly"
source deactivate verkko
echo "starting out with the hifiasm assembly"
for i in files
 do 
    echo hifiasm -o ${i%.**}.asm -l0 ${i} "2>" ${i%.**}.log
 done 
echo "the hifiassembly using the hifiasm has been completed" 
echo "thank you for using the hifi cluster computing services"

elif [[ ${configuration} == "singlereads" && "${option}" == "all" && \
		        ${directory} && ${scratch} && ${fetchfile} ]]; then
echo "writing the configuration files for the slurmruns and fetching the files from the fetch link provided"
echo #!/bin/bash
echo #SBATCH --partition=all
echo #SBATCH --nodes=1
echo #SBATCH --ntasks=1
echo #SBATCH --cpus-per-task=1
echo #SBATCH --mem=5G
echo #SBATCH --time=0-05:00
echo #SBATCH --chdir="${hostname}"
echo #SBATCH --mail-type=ALL
echo #SBATCH --output=slurm-%j.out
module list
module load lang/Anaconda3/2021.05
wget -F "${fetchfile}" -o links.txt
declare -a fetchfiles=()
cat links.txt | while read line
   do 
      fectchfiles += (${line})
   done
for i in fetchfiles
   do 
      echo verkko -d "${i%.**}" --hifi "${i}" 
   done
mkdir fasta_files_assembly
for i in "${scratch}"/"${i%.**}"/assembly.fasta
   do 
	cp -r "${scratch}"/"${i%.**}"/assembly.fasta fasta_files_assembly/"${i%.**}".fasta
   done
   echo "the assembly files for the verkko have been moved and assembled and you can find them in the address"
   echo "${scratch}/fasta_files_assembly"
echo "starting out with the hifiasm assembly"
for i in files
 do 
    echo hifiasm -o ${i%.**}.asm -l0 ${i} "2>" ${i%.**}.log
 done 
echo "the hifiassembly using the hifiasm has been completed" 
echo "thank you for using the hifi cluster computing services"
elif [[ ${configuration} == "parents" && "${option}" == "all" && \
		        ${directory} && ${scratch} ]]; then
read -r -p "please provide the path to the maternal sequences:" maternal
read -r -p "please provide the path to the paternal sequences:" paternal
read -r -p "please provide the path to the child ones:" child
read -r -p "please provide the kmer for the estimation of the trio binning method:" selectedkmer
read -r -p "do you want to evaluate the different kmers for the trio binning method:" different
if [[ "${selectedkmer}" && "${different}" == "" ]]; then
mkdir makingkmers
cd makingkmers
meryl count compress k=30 threads="${cpus-per-task}" memory="${mem}" "${maternal}"/*.fastq.gz output maternalkmers."${selectedkmer}".meryl
meryl count compress k=30 threads="${cpus-per-task}" memory="${mem}" "${paternal}"/*.fastq.gz output paternalkmers."${selectedkmer}".meryl
meryl count compress k=30 threads="${cpus-per-task}" memory="${mem}" "${child}"/*.fastq.gz output paternalkmers."${selectedkmer}".meryl
cd ..
echo "cloning merqury for making the hapmap datasets"
git clone https://github.com/marbl/merqury.git
sh $(pwd)/merqury/hapmers.sh $(pwd)/makingkmers/maternalkmers."${selectedkmer}".meryl \
                                     $(pwd)/makingkmers/maternalkmers."${selectedkmer}".meryl \ 
                                                   $(pwd)/makingkmers/maternalkmers."${selectedkmer}".meryl
elif [[ "${selectedkmer}" && ${different} == "yes" ]]; then
read -r -p "how many kmers:" kmers
declare -a arraystorage=()
while [[ "${kmers}" -le "${#arraystorage[*]}" ]]; 
do
  read -r -p "please enter the kmers:" kmer
   arraystorage+=("${kmer}")
  if [ "${#arraystorage[*]}" -eq "${kmers}" ]; then
   break
 fi  
done
touch storingvariablekmers.sh
for i in ${#arraystorage[*]}; 
   do 
      echo meryl count compress k="${i}" threads="${cpus-per-task}" memory="${mem}" "${maternal}"/*.fastq.gz output maternalkmers."${i}".meryl
      echo meryl count compress k="{i}" threads="${cpus-per-task}" memory="${mem}" "${paternal}"/*.fastq.gz output paternalkmers."${i}".meryl
      echo meryl count compress k="{i}" threads="${cpus-per-task}" memory="${mem}" "${child}"/*.fastq.gz output paternalkmers."${i}".meryl
   done >> sotringvariablekmers.sh 

if [[ -z $(cat storingvariablekmers.sh | wc -l ) ]]; then
   echo "variables are not properly formatted and stored"
fi
