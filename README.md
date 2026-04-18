# intro-2-hpc-skills

## Log in to Gadi 

From your local terminal: 

```bash
ssh <username>@gadi.nci.org.au
```

Or, log in to [NCI's ARE platform](https://are.nci.org.au/) with your NCI credentials and open a Gadi terminal. 

## Filesystem 

You'll be logged into home (/home). Navigate to our working space: 

```
cd /scratch/qc03 
```

You will likely find a directory here for your username. To keep things tidy and avoid clashes, move into your personal work directory and download this repository: 

```
cd /scratch/qc03/<username>
git clone https://github.com/Sydney-Informatics-Hub/intro-2-hpc-skills.git
```

If you can't find your username directory, create one, move into it, and download this repository: 

```
mkdir <username> && cd $_
```

## Accounting 

NCI provides a number of helper utilities for monitoring your project allocations and storage. You can also sticky beak at what other project members have been up to.  

```
bash scripts/1-storage.sh
```

