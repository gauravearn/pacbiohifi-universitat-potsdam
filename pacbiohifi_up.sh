# an entire workflow for the running of the high throughput cluster on the analysis of the genomes
# coming from the pacbiohifi using the verkko, hifiasm, genomeasm4pg
# below is a complete slurm configuration for the same
# Author Gaurav Sablok
# Universitat Potsdam
# Date: 2024-3-11
# please change the variables or else use the version tomorrow which has the complete support for the auxillary analysis also.  
##########
read -r -p "please provide the username:" username
read -r -p "please select the option:" option
read -r -p "please provide the path to the directory on the slurmserver:" directory
read -r -p "please provide the path to the scratch directory on the slurmserver:" scratch
read -r -p "please provide the file with the links to the external fetch:" fetchfile
if [[ "${option}" == "all" && \
		        ${directory} && ${scratch} \
				              && ${username} ]]; then
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
cp -r ${directory}/*.fastqgz ${scratch} 
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
for i in ls -l *.fastq.gz
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
elif [[ "${option}" == "all" && \
		     ${directory} && ${scratch} \
				              && ${username} && ${fetchfile} ]]; then
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

declare -a fetchfiles=()
cat ${fetchfiles} | while read line; do 
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
fi 
