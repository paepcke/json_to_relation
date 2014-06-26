 #!/usr/bin/env bash                                                                                                     

# Run simple, full backup for all the relevant OpenEdX databases:
#   Edx
#   EdxPrivate
#   EdxForum
#   EdxPiazza

# If used outside of Stanford: change the target disk,
# which at Stanford is /lfs/datastage/1/MySQLBackup/

# Create new directory with name including current date and time:
# The part `echo \`date\` | sed -e 's/[ ]/_/g'`:
# ...  \'date\': get date as string like "Fri Jun 20 08:54:42 PDT 2014"
# ... | sed -e 's/[ ]/_/g'` remove spaces within the date, and replace them with underscore
# Result example: "backupEdx_Fri_Jun_20_08:54:42_PDT_2014"

newDir=/lfs/datastage/1/MySQLBackup/backupEdx_`echo \`date\` | sed -e 's/[ ]/_/g'`
#echo $newDir

# The following will ask for sudo PWD, which limits 
# automatic run for now. Need to fix this:
sudo mkdir $newDir

# Use mysqlhotcopy to grab one MySQL db at a time:
sudo mysqlhotcopy Edx $newDir            # ~3hrs
sudo mysqlhotcopy EdxForum $newDir       # instantaneous
sudo mysqlhotcopy EdxPiazza $newDir      # instantaneous
sudo mysqlhotcopy EdxPrivate $newDir     # ~3min
                                                                                                                         
                                                   