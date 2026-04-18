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



## Software 

NCI helpdesk staff install commonly used software to a globally available filesystem called `/apps`. To view these modules, run: 

```bash
module avail 
```

If software you want to run is not available, you should use Singularity