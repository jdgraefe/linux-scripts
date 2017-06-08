# Script to install nginx, get an html file from github, and start the webserver on port 8000

LOGFILE=/tmp/install-nginx.log
CONFIGFILE=/etc/nginx/conf.d/default.conf
echo "Begining install of nginx-"$(date) >>$LOGFILE

# Install the nginx rpms from the repo
installnginx()
{
        yum list installed |grep nginx
        if [ $? = 0 ]
         then
           echo "nginx is already installed" >>$LOGFILE
         else
          yum install -y nginx
              if [ $? != 0 ]
               then
                 echo "Yum install of nginx failed" >>$LOGFILE
                exit
              fi
        fi

}

# Check if index file exists (create a backup just in case) and get new one from GitHub. If the wget works then move the new one into place
getcontent()
{
        if [ -f /usr/share/nginx/html/index.html ]
           then
                cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.$$
                echo "Created backup of index.hml" >>$LOGFILE
        fi
        wget -O /tmp/new-index.html https://raw.githubusercontent.com/puppetlabs/exercise-webpage/master/index.html
        if [ $? != 0 ]
         then echo "Not able to get new content from GitHub" >>$LOGFILE
        else
         echo "Content downloaded from GitHub" >>$LOGFILE
         mv /tmp/new-index.html /usr/share/nginx/html/index.html
        fi
}

# Check if anything is running on port 8000
# Configure the port to be 8000 and start nginx
confignginx()
{
        netstat -an |grep "listen.*8000\;" "$CONFIGFILE"
        if [ $? = 0 ]
        then
         echo "Something appears to be listening on port 8000 already!" >>$LOGFILE
        else
        if [ ! -f "$CONFIGFILE" ]
         then
          echo "$CONFIGFILE file does not exist" >> $LOGFILE
         else
           sed -i.$$ 's/listen.*80/listen   8000/' "$CONFIGFILE"
            systemctl start nginx.service
            systemctl enable nginx
               if [ $? != 0 ]
                then
                 echo "Nginx failed to start" >>$LOGFILE
               fi
        fi
        fi
}


installnginx
getcontent
confignginx

echo "Finished install of nginx-"$(date) >>$LOGFILE
