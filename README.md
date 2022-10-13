# Scripts facilitating analysis of bacterial whole-genome short-read data for taxonomical identification
By Yu Wan  
Last update: 13 Oct 2022
<br/>

Pipelines
- Kraken 2 and Bracken
- KmerFinder
<br/>

## System settings
Code in this repository has been tested under the following settings. However, the code may work under other settings with necessary customisation.

- Linux high-performance computing (HPC) cluster
- Portable Batch System (PBS)
- [Anaconda](https://www.anaconda.com) with package [Kraken](https://github.com/DerrickWood/kraken2) v2.1.2 installed in an environment
- [Bracken](https://github.com/jenniferlu717/Bracken) v2.6.2 (Standard-alone installation)
- Python v3 and the pandas (<1.4) package
- Nextflow v22
<br/>  

## 1. Prerequisite
- Manually editng script `rsync_from_ncbi.pl` of Kraken2 to solve Issues [508](https://github.com/DerrickWood/kraken2/issues/508) and [518](https://github.com/DerrickWood/kraken2/issues/518): "`rsync_from_ncbi.pl: unexpected FTP path (new server?)`)"
    - Replace `rsync_from_ncbi.pl` in `kraken2.1/libexec` in Kraken2's installation directory. For anaconda users, the path is: `$HOME/anaconda3/envs/[kraken environment name]/libexec`.
- Creating a Conda environment for Kraken2, Python 3, and the Python package pandas (<1.4).

```bash
module load anaconda3/personal  # On my HPC; you may not need this command or need to load a different module
conda create --name kraken2.1 python=3
conda activate kraken2.1  # Some systems use 'source activate kraken2.1'
conda install -c bioconda nextflow
conda install pandas
conda install -c bioconda kraken2
conda install -c bioconda bracken
```
<br/>  

## 2. Building a Kraken database
- Use script `build_kraken_database.pbs`
- Parameters:
    - `conda_module`, module name for loading conda
    - `env`, name of the conda environment for Kraken2
    - `library`, name of the Kraken library to build (set to "bacteria")
    - `db`, name of the output database
    - `wd`, working directory
- A minimum of 64 GB RAM and eight cores are required by this script because this step is memory-consuming and computation-intensive. You may edit the PBS header in the script to adjust the memory and CPU allocations. 
- Example command: `qsub -v "conda_module=anaconda3/personal,env=kraken2.1,lib=bacteria,db=bacteria_220526,wd=$PWD" ~/Kraken_toolkit/build_database.pbs`
<br/>  

## 3. Building a Bracken database
- Use script `build_bracken_database.pbs`
- Parameters:
    - `db`, path to a Kraken database
    - `len`, length of input reads
    - `k`, k-mer length
    - `wd`, working directory
    - `x`, path to the "bin" subdirectory in Kraken2's installation directory
    - `p`, the directory where program `bracken-build` is installed
    - `mod`, (optional) module name where conda/python is installed
    - `con`, (optional) name of the conda environment where Python is installed
- By default, this script uses a 35-bp k-mer length and 100-bp read length. You may set arguments `k` and `len` to adjust the k-mer and read lengths, respectively.
- Example command: `qsub -v "k=35,len=150,db=$HOME/database/kraken2/$db,x=$HOME/anaconda3/envs/kraken2.1/bin,p=$HOME/anaconda3/envs/kraken2.1/bin" build_bracken_database.pbs`
<br/>  

## 4. Running the Kraken-Bracken Nextflow pipeline
- Script `kraken2.nf` and its configuration file `kraken2.config`.
- Parameters:
    - `fastq`, a glob for FASTQ files.
    - `db`, absolute path of the reference Kraken2 database
    - `outdir`, absolute path of the output directory; subdirectories to be created automatically: `kraken`, `bracken`, `top3_taxa`.
    - `queueSize`, number of concurrent jobs
    - `cpus`, number of cores for each job (default: 8)
    - `mem`, memory size for each job (default: 64 GB)
    - `conda_env`, name of the Conda environment to be loaded
    - `bracken_dir`, absolute path of the directory containing program `bracken`
    - `bracken_level`, taxonomical level for summary (default: 'S', species)
    - `read_len`, read length used for building the Bracken database (default: 100 bp)
    - `script_dir`, absolute path to the directory in which script `top3_bracken_taxa.py` is stored.
- I would recommend running the pipeline in a screen session on your HPC because it takes time to finish.
```bash
module load anaconda3/personal
conda activate kraken2.1
cd taxa  # Your preferred working directory
mkdir tmp
nextflow -Djava.io.tmpdir=tmp run $HOME/software/Taxonomy_toolkit/kraken2.nf -c $HOME/software/Taxonomy_toolkit/kraken2.config --fastq "*_{1,2}.fastq.gz" --db $HOME/database/kraken2/bacteria_220526 --outdir "output" --bracken_level S --queueSize 10 --cpus 8 --mem 64 --conda_env kraken2.1 --bracken_dir $HOME/software/Bracken --read_len 150 --script_dir $HOME/software/Taxonomy_toolkit
```

Note that `-Djava.io.tmpdir=tmp` is not necessary if you have access to `/tmp` (Some system admins disabled such an access).

Sometimes the jobs of Kraken2 are killed by the PBS when they are using memories exceeding those allocated, causing the workflow to pause, so please use `qstats` command to monitor job status.
<br/>

## 5. Running the KmerFinder Nextflow pipeline
- Script `kmerfinder.nf` and its configuration file `kmerfinder.config`
- Parameters:
    - `fasta`, a glob of input FASTA files (default: `*.fasta`)
    - `db`, absolute path of the KmerFinder reference database (*.ATG) (default: `bacteria.ATG`)
    - `tax`, taxonomy file (*.tax) of the KmerFinder reference database (default: `bacteria.tax`)
    - `outdir`, absolute path of the output directory (default: `output`)
    - `queueSize`, number of concurrent jobs (default: 15)
    - `mem`, memory requested per job (default: 16 GB)
    - `conda_env`, name of the Conda environment where KMA and Python 3 are installed
    - `kmerfinder_dir`, directory where `kmerfinder.py` is stored
    - `kma_dir`, directory in which KMA is installed (the path must be ended with the forward slash) (default: `~/anaconda3/envs/kmerfinder/bin/`)
- Example command: `nextflow -Djava.io.tmpdir=$PWD run $HOME/software/Taxonomy_toolkit/kmerfinder.nf --db "$HOME/databases/kmerfinder/bacteria\_20220606/bacteria/bacteria.ATG" --tax "$HOME/databases/kmerfinder/bacteria\_20220606/bacteria/bacteria.tax" --outdir "${PWD}/output" --fasta "assemblies/*.fasta" --queueSize 15 -c kmerfinder.config`.
