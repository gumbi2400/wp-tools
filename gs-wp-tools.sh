#!/bin/bash

# This is a work in progress! BACK EVERYTHING UP!
# Useful to define the site ID for absolute paths

siteid=`pwd | awk -F "/" '{print $3}'`

#Build functions for later

function HOME_MENU {
wpinstall_list="$(find /home/$siteid/domains/ -type f -name wp-config.php | rev | cut -d"/" -f2- |rev) Done"

# Use echo  $wpinstall_list if a sanity check is needed
#$wpinstall_list now has all WordPress installations!

PS3='Pick one: '
#sets up the select prompt for a menu

working_wp=""
until [ "$working_wp" == "Done" ]; do
    printf "%b" "\a\n\nWhich WordPress install do you want to work on?\n"
	select working_wp in $wpinstall_list; do
        
		if [ "$working_wp" = "Done" ]; then
                        echo "Goodbye"
                        break
		
		elif [ -n "$working_wp" ]; then
           		working_wp="`echo $working_wp`/" #set up a proper path
			echo "Selected install path is $working_wp"
			#Let's do something with this!
			SUBMENU
			break
		else
			echo  "Invalid Selection"
		fi
        done  
done    
}

#The SUBMENU function creates the sub menu

function SUBMENU {
    echo "You are currently working with the WordPress installation at $working_wp"
#set up prompt and the list to chose from
    echo 'Setting up variables.'

# Set up database variables for later use
    dbhost="internal-db.s$siteid.gridserver.com"
    dbuser=`cat $working_wp/wp-config.php|grep DB_USER |awk -F "'" '{print $4}'`
    dbpass=`cat $working_wp/wp-config.php|grep DB_PASS |awk -F "'" '{print $4}'`
    dbname=`cat $working_wp/wp-config.php|grep DB_NAME |awk -F "'" '{print $4}'`
    dbprefix=`cat $working_wp/wp-config.php |grep table_prefix |awk -F"'" '{print $2}'`
    OPS3=$PS3 #save the old prompt
    PS3='Choose action: '
    action_select=""	#Clean up the old $action_select variables
    option_list="check database connection,check WordPress version,disable plugins,enable plugins,Done"	#Set up the option list
    OIFS=$IFS #save the current IFS (Internal Field Separator)
    IFS=',' #Create a new IFS for multi-word options! 

#build the list and select an action
    until [ "$action_select" == "Done" ]; do
        printf "%b" "\a\n\nWhat would you like to do with this WordPress install?\n"
        select action_select in $option_list; do
        
        if [ "$action_select" = "check database connection" ]; then
		WPDBCHECK
            
        elif [ "$action_select" = "check WordPress version" ]; then
		WPVERCHECK

        elif [ "$action_select" = "disable plugins" ]; then
                DISABLEPLUGIN

        elif [ "$action_select" = "enable plugins" ]; then
		ENABLEPLUGIN

        elif [ "$action_select" = "Done" ]; then
            echo "Returning to Main Menu"
            # Clean up variables 
            IFS=$OIFS
            PS3=$OPS3
            dbhost=""
            dbuser=""
            dbpass=""
            dbname=""
            dbprefix=""
            #rm plugin_list.tmp commented out till ENABLEPLUGIN works
            break    

        else 
            echo "Invalid Selection"
                
        fi
        done
    done
}

#The WPDBCHECK function checks the connection to the WordPress database 
function WPDBCHECK {
    echo "
    Database host is $dbhost
    "
    echo "
    Database user is $dbuser
    "
    echo "
    Database password is $dbpass
    "
    echo "
    Database name is $dbname
    "
    dbname_test=`mysql -h$dbhost -u$dbuser -p$dbpass -e "show databases;" |grep  $dbname`
#now see if the database names match, or if it's even there
    echo 'Testing the database connection.'
    dbname_test=`mysql -h$dbhost -u$dbuser -p$dbpass -e "show databases;" |grep  $dbname`
        if [ "$dbname_test" = "$dbname" ]; then
            echo 'The database name in the wp-config.php is valid and connection to database was successful. If you still cannot connect, you may want to check the database host name'
        else
            echo 'It looks like the database name in the wp.config.php is not valid, or the connection was not successful'
        fi
    break
}        

# The WPVERCHECK function just checks the WordPress version                

function WPVERCHECK {
    #set up $wp_version to be the version number and tell it to the user
    wp_version=`grep "wp_version =" $working_wp/wp-includes/version.php |awk -F"'" '{print $2}'`
    echo "The WordPress version for the installation at $working_wp is $wp_version"
    break
}
#The DISABLEPLUGIN function does just that... disable plugins

function DISABLEPLUGIN {

echo "Disabling active plugins
"

# Just rename active_plugins to something else to disable them temporarily
mysql -h$dbhost -u$dbuser -p$dbpass -e"UPDATE `echo $dbname.$dbprefix`options SET option_name=\"mt_disabled_plugins\" WHERE option_name=\"active_plugins\";"

echo "Active plugins disabled"

break
}

# ENABLEPLUGIN enables plugins!

function ENABLEPLUGIN {
echo "Re-enabling plugins
"

mysql -h$dbhost -u$dbuser -p$dbpass -e"UPDATE `echo $dbname.$dbprefix`options SET option_name=\"active_plugins\" WHERE option_name=\"mt_disabled_plugins\";"
echo "Plugins re-enabled
"

break

}

#Right, now lets actually start things off!

HOME_MENU
