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

```
Queue              Max   Tot Ena Str   Que   Run   Hld   Wat   Trn   Ext Type
---------------- ----- ----- --- --- ----- ----- ----- ----- ----- ----- ----
normal               0  1684 yes yes   680     0  1001     3     0     0 Rou*
normal-exec          0  2171 yes yes    88  1417   666     0     0     0 Exe*
express              0     0 yes yes     0     0     0     0     0     0 Rou*
express-exec         0     4 yes yes     0     2     2     0     0     0 Exe*
copyq                0    29 yes yes     0     0     0    29     0     0 Rou*
copyq-exec           0     9 yes yes     0     7     2     0     0     0 Exe*
gpuvolta             0   500 yes yes   500     0     0     0     0     0 Rou*
gpuvolta-exec        0   447 yes yes   167   236    36     0     0     0 Exe*
hugemem-exec         0    29 yes yes     1    28     0     0     0     0 Exe*
hugemem              0     0 yes yes     0     0     0     0     0     0 Rou*
biodev               0     0 yes yes     0     0     0     0     0     0 Rou*
biodev-exec          0     0 yes yes     0     0     0     0     0     0 Exe*
megamembw-exec       0    13 yes yes     0     1    12     0     0     0 Exe*
megamembw            0     0 yes yes     0     0     0     0     0     0 Rou*
normalbw-exec        0   149 yes yes     1   134    13     0     0     1 Exe*
normalbw             0     5 yes yes     0     0     0     5     0     0 Rou*
expressbw-exec       0     6 yes yes     0     3     3     0     0     0 Exe*
expressbw            0     0 yes yes     0     0     0     0     0     0 Rou*
normalsl-exec        0    13 yes yes     0    12     1     0     0     0 Exe*
normalsl             0     0 yes yes     0     0     0     0     0     0 Rou*
hugemembw-exec       0    13 yes yes     5     7     1     0     0     0 Exe*
hugemembw            0     0 yes yes     0     0     0     0     0     0 Rou*
megamem              0     0 yes yes     0     0     0     0     0     0 Rou*
megamem-exec         0    46 yes yes    44     2     0     0     0     0 Exe*
gpursaa              0     0 yes yes     0     0     0     0     0     0 Rou*
gpursaa-exec         0     2 yes yes     0     2     0     0     0     0 Exe*
analysis             0     0 yes yes     0     0     0     0     0     0 Rou*
analysis-exec        0     1 yes yes     0     1     0     0     0     0 Exe*
dgxa100              0    24 yes yes    24     0     0     0     0     0 Rou*
dgxa100-exec         0    38 yes yes    32     4     2     0     0     0 Exe*
normalsr             0     0 yes yes     0     0     0     0     0     0 Rou*
normalsr-exec        0   221 yes yes     7    47   167     0     0     0 Exe*
expresssr            0     0 yes yes     0     0     0     0     0     0 Rou*
expresssr-exec       0     0 yes yes     0     0     0     0     0     0 Exe*
rsaa                 0     0 yes yes     0     0     0     0     0     0 Rou*
rsaa-exec            0    10 yes yes     0    10     0     0     0     0 Exe*
workflow             0     0 yes yes     0     0     0     0     0     0 Rou*
workflow-exec        0     0 yes yes     0     0     0     0     0     0 Exe*
gpuhopper            0   130 yes yes   130     0     0     0     0     0 Rou*
gpuhopper-exec       0   259 yes yes   185    53    21     0     0     0 Exe*
```

Unlike most other HPCs, Gadi has a unique set up whereby your submitted jobs are run on differently named queues e.g. gpuhopper vs gpuhopper-exec". The queues with -exec are where your jobs actually run. 

Once your jobs are complete, run the following script to summarise the outputs of your benchmarking job: 

```bash
bash benchmark-summary.sh
```

