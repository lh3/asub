`asub` stands for "array submission". It greatly simplifies job submission with
LSF (or Grid Engine with limited support) and is easily my most frequently used
perl script in nearly ten years.

`asub` reads command lines from stdin or from a shell script and creates a job
array with each job for one command line. The effective use of `asub` relies
on constructing command lines. I will show with examples.

## Basic Examples

* Compress large FASTQ files:
  ```sh
  ls *.fq | xargs -i echo gzip {} | asub -j run-gzip
  ```
  The *i*-th job in the job array compresses the *i*-th file.

* Compress large FASTQ files with parallel jobs:
  ```sh
  ls *.fq | xargs -i echo gzip {} | asub -g2 -q mcore
  ```
  The *i*-th job compresses the 2*i*-1 and 2*i* files *in parallele*. The
  example is only useful under particular settings (e.g. at HMS). Usually we
  would not want to do this.

* Compress small FASTQ files by serial batching:
  ```sh
  ls *.fq | xargs -i echo gzip {} | asub -Gg2
  ```
  The *i*-th job compresses the 2*i*-1 and 2*i* files *in turn*. This can be
  used to group short processes such that the whole job takes reasonable amount
  of time. Too many short jobs hurt LSF performance.
