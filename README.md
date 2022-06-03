# Scripts facilitating taxonomical analysis using Kraken 2 and Bracken
By Yu Wan

<br/>  

## System settings

Code in this repository has been tested under the following settings. However, the code may work under other settings with necessary customisation.

- Linux high-performance computing (HPC) cluster
- Portable Batch System (PBS)
- Anaconda with package [Kraken](https://github.com/DerrickWood/kraken2) v2.1.2 installed in an environment
- [Bracken](https://github.com/jenniferlu717/Bracken) v2.6.2 (Standard-alone installation)
- Python v3 and the pandas package

<br/>  

## 1. Prerequisite

- Updating script `rsync_from_ncbi.pl` of Kraken2 to solve Issues [508](https://github.com/DerrickWood/kraken2/issues/508) and [518](https://github.com/DerrickWood/kraken2/issues/518): "`rsync_from_ncbi.pl: unexpected FTP path (new server?)`)"
    - Replace `rsync_from_ncbi.pl` in `kraken2.1/libexec` in Kraken2's installation directory. For anaconda users, the path is: `$HOME/anaconda3/envs/[kraken environment name]/libexec`.
- Creating a Conda environment for Kraken2, Python 3, and the pandas Python package.

<br/>  

## 2. Building a Kraken database

- `build_kraken_database.pbs`
- Example: `qsub -v "conda_module=anaconda3/personal,env=kraken2.1,lib=bacteria,db=bacteria_220526,wd=$PWD" ~/Kraken_toolkit/build_database.pbs*`

<br/>  

## 3. Building a Bracken database

- `build_bracken_database.pbs`
- Example: `qsub -v "k=35,len=150,db=$HOME/database/kraken2/$db,x=$HOME/anaconda3/envs/kraken2.1/bin" build_bracken_database.pbs`

<br/>



## 4.   Running the pipeline

I recommend running the pipeline in a screen session on your HPC.

```bash
# mkdir tmp
nextflow -Djava.io.tmpdir=tmp run analyse_taxa.nf -c analyse_taxa.config --fastq "*_{1,2}.fastq.gz" --db /rds/general/project/hrpu2wgs/live/imp/database/kraken2/bacteria_220526 --outdir "output" --queueSize 10 --cpus 8 --mem 64 --conda_env kraken2.1 --bracken_dir $HOME/software/Bracken --read_len 150 --script_dir $PWD
```

Note that `-Djava.io.tmpdir=tmp` is not necessary if you have access to `/tmp`.

Sometimes the jobs of Kraken2 are killed by the PBS when they are using memories exceeding those allocated, causing the workflow to pause, so please use `qstats` command to monitor job status.