# intro-2-hpc-skills

## Log in to Gadi 

From your local terminal: 

```bash
ssh <username>@gadi.nci.org.au
```

Or, log in to [NCI's ARE platform](https://are.nci.org.au/) with your NCI credentials and open a Gadi terminal. 

## Filesystem 

You'll be logged into home (/home). Navigate to our working space: 

```bash
cd /scratch/qc03 
```

You will likely find a directory here for your username. To keep things tidy and avoid clashes, move into your personal work directory and download this repository: 

```
cd /scratch/qc03/<username>
git clone https://github.com/Sydney-Informatics-Hub/intro-2-hpc-skills.git
```

If you can't find your username directory, create one, move into it, and download this repository: 

```bash
mkdir <username> && cd $_
```

## Accounting 

NCI provides a number of helper utilities for monitoring your project allocations and storage. 

### Storage and KSU summary

Run the following command to get a summary report of [nci accounting utilities](https://opus.nci.org.au/spaces/Help/pages/477823298/Filesystems...#Filesystems...-QuotaAccountingTools): `quota`, `lquota`, `nci_account`, `nci-files-report`, `nci-file-expiry`.

```bash
bash scripts/gadi-stats.sh -p qc03
```

### Point the finger 

You can also sticky beak at what other project members have been up to by running these utilities in verbose modes. Run the following command to get a summary report of allocation consumption for all project members: 

```bash
bash scripts/point-the-finger.sh -p qc03
```

## Job monitoring 

Submit a series of benchmarking jobs, monitor it while it runs, and inspect the resource usage after it completes. Use the benchmarking script to compare resource usage of all the runs.

Run the example benchmarking script for BWA, submitting jobs to the `normalbw` queue: 

```bash
bash bwa-benchmark-run.sh normalbw
```

You'll get the following output: 

```
[gs5517@gadi-login-05 scripts]$ bash bwa-benchmark-run.sh normalbw

Benchmarking bwa on queue normalbw for bwa-benchmark with 1 NCPUS and 9 MEM with job ID: 166489215.gadi-pbs


Benchmarking bwa on queue normalbw for bwa-benchmark with 7 NCPUS and 63 MEM with job ID: 166489216.gadi-pbs


Benchmarking bwa on queue normalbw for bwa-benchmark with 14 NCPUS and 126 MEM with job ID: 166489217.gadi-pbs


Benchmarking bwa on queue normalbw for bwa-benchmark with 28 NCPUS and 250 MEM with job ID: 166489219.gadi-pbs
```

Check the status of the jobs: 

```bash
qstat 
```

Your jobs may not instantly run, see the "S" column in the output table. Jobs that have a "Q" in that column are still in the queue, waiting to run. Once they're running that will change to "R". 

`qstat` has a lot of functionality, see their help menu for different output formats:

```bash
qstat [-f] [-J] [-p] [-t] [-x] [-E] [-F format | -w] [-D delim] [ job_identifier... | destination... ]
qstat [-a|-i|-r|-H|-T] [-J] [-t] [-u user] [-n] [-s] [-G|-M] [-1] [-w]
        [ job_identifier... | destination... ]
qstat -Q [-f] [-F format] [-D delim] [ destination... ]
qstat -q [-G|-M] [ destination... ]
qstat -B [-f] [-F format] [-D delim] [ server_name... ]
qstat --version
```

Let's also take a look at all jobs running on all queues: 

```bash
qstat -Q
```

Unlike most other HPCs, Gadi has a unique set up whereby your submitted jobs are run on differently named queues e.g. gpuhopper vs gpuhopper-exec". The queues with -exec are where your jobs actually run. 

Once your jobs are complete, run the following script to summarise the outputs of your benchmarking job: 

```bash
bash benchmark-summary.sh
```

