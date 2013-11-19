#!/bin/bash

# Turns off indexing during bulk load of Edx log files to speed up the loads.
# You need to call restoreMySQLAfterBulkLoad.sh when done
# with the load. It will re-enable indexes, and update them
# in memory into a perfectly balanced tree.

sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/EdxTrackEvent.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/Account.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/Answer.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/CorrectMap.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/InputState.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/LoadInfo.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/State.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/EdxPrivate/Account.MYI
