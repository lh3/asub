## FAQs

#### What is asub used for?

`asub` stands for "array submission". It greatly simplifies batch job
submission on LSF (or Grid Engine with limited support). Briefly, it reads mutually independent
command lines from stdin or from a shell script and creates a job array with
each job for one or multiple command lines in the input.

#### What is job array? What is the benefit?

A [job array][ja] is an array of LSF/Grid Engine jobs that are submitted
together and have the same JobID. It has two major advantages. Firstly, job
array is convenient for a batch jobs having similar input/output. You can
kill/stop/resume/modify the whole array or some jobs in the array easily by
specifying, for example, `JobID` or `JobID[10-100]`. You can also specify how
many jobs in the array should be run at the same time with `bmod -J%10 JodID`.
Secondly, [Tim Cutts][tc] from the Sanger Institute used to show that job
arrays put less stress on the LSF scheduler. This makes array jobs submitted
much faster and also reduces the burden on the entire LSF system.

#### Why do we need asub?

Submitting array jobs is harder. You have to learn the mechanism of job arrays
and frequently need to write a bsub script that takes an array job index as the
input. `asub` simplifies this procedure. You can easily submit a job array if
you have your *independent* command lines kept in a file/stream (see examples
below).

In addition to array submission, `asub` also simplifies resource requirement.
You can submit a multi-threaded job without `-R'span[hosts=1]'`, or set a
memory limit without `-R'rusage[mem=4096]'` (and you don't need to remember
4096 is the per-task limit, not the total limit). `asub` can also optionally
group multiple command lines into one job. This feature could be helpful if
each individual command line runs too fast.

`asub` is easily my mostly used Perl script in nearly ten years.

#### Does asub support Grid Engine?

For now, `asub` only has limited support of Grid Engine. I used to have a
better version for SGE, but have lost it. Contribution welcomed!

#### Does asub support SLURM?

Yes, but not as well supported as LSF.

#### How does asub work?

`asub` has two modes: submission mode and laucher mode. Endusers only need to
care about the submission mode. In this mode, `asub` writes the input command
lines into `JobID.sh` and generates an on-the-fly bsub script that calls `asub
-k ${LSB_JOBINDEX} JobID.sh` to execute command lines. Here `-k <lineno>` puts
`asub` in the launcher mode. Without `-g`, it runs the `<lineno>`-th command
line in `JobID.sh`.

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

[tc]: https://www.linkedin.com/profile/view?id=117849235
[ja]: http://www.ccs.miami.edu/hpc/lsf/7.0.6/admin/jobarrays.html
