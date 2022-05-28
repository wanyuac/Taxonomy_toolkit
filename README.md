# Kraken\_tools
Scripts facilitating taxonomical analysis using kraken 2 and bracken.

By Yu Wan

Latest update of documentation: 28 May 2022

<br/>

## System settings

Code in this repository has been tested under the following settings. However, the code may work under other settings with necessary customisation.

- Linux high-performance computing (HPC) cluster
- Portable Batch System (PBS)
- Anaconda with package [Kraken](https://github.com/DerrickWood/kraken2) v2.1.2 installed in an environment
- [Bracken](https://github.com/jenniferlu717/Bracken) v2.6.2 (Standard-alone installation)
<br/>
## 1. Prerequisite

Solving Issues [508](https://github.com/DerrickWood/kraken2/issues/508) and [518](https://github.com/DerrickWood/kraken2/issues/518): "`rsync_from_ncbi.pl: unexpected FTP path (new server?)`)"

- Replace `rsync_from_ncbi.pl` in `kraken2.1/libexec` in Kraken2's installation directory. For anaconda users, the path is: `$HOME/anaconda3/envs/[kraken environment name]/libexec`.

<br/>

## 2. Building Kraken taxonomical and sequence databases

- `build_kraken_database.pbs`
- Example: `qsub -v "conda_module=anaconda3/personal,env=kraken2.1,lib=bacteria,db=bacteria_220526,wd=$PWD" ~/Kraken_toolkit/build_database.pbs*`

<br/>

## 3. Building a Bracken database

- `build_bracken_database.pbs`
- Example: `qsub -v "k=35,len=150,db=$HOME/database/kraken2/$db,x=$HOME/anaconda3/envs/kraken2.1/bin" build_bracken_database.pbs`

<br/>