

This will do the job. You could include it as a function in the customer_post_script. Feel free to modify as needed.

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


