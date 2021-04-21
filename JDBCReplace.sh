#!/bin/bash
set -f
su - gsh
echo "" > execution.sh
filename=$1
jdbcstring=$2
jdbcpassword=$3
while read line; do
# reading each line
echo $line
echo 'sed -i "s~<url>jdbc:oracle:thin:@whf00fxh.in.oracle.com:1521/prodpdb</url>~<url>'$jdbcstring'</url><password-encrypted>'$jdbcpassword'</password-encrypted>~g" /scratch/gsh/kernel144/user_projects/domains/integrated/config/jdbc/'$line >> execution.sh
echo 'sed -i "s~<password-encrypted></password-encrypted>~<password-encrypted>'$jdbcpassword'</password-encrypted>~g" /scratch/gsh/kernel144/user_projects/domains/integrated/config/jdbc/'$line >> execution.sh
done < $filename
set +f
sh execution.sh
