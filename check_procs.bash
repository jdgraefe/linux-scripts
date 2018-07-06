

# Checks for a process running without a username. Useful when checking a system after migrating to direcotry serverices.
# It will flag any procs whos user was removed but there is no directory account.

#!/bin/bash
for i in `ps -ef |awk '{print $1}' |sort -u`
do
        myvar=$i
          if [[ $myvar =~ [^[:digit:]] ]]
           then
                #echo Has some nondigits
                :
           else
                echo "There are processes running with only UID listed in process list:"
                #echo all digits: $i
                ps -ef |grep ^$i
                echo ""
          fi
done


