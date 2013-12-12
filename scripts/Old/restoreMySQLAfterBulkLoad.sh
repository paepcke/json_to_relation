#!/bin/bash

# Re-enables indexes, and updates them
# in memory into a perfectly balanced tree.

sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/EdxTrackEvent.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/Account.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/Answer.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/CorrectMap.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/InputState.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/LoadInfo.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/Edx/State.MYI
sudo  myisamchk -rq /lfs/datastage/0/home/mysql/tables/mysql/EdxPrivate/Account.MYI
