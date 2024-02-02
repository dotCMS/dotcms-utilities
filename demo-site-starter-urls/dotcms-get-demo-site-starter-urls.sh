#!/usr/bin/env bash

# You can install dotCMS with the "demo site" content as seen on https://demo.dotcms.com
# by setting the CUSTOM_STARTER_URL environment variable.
# This is great for testing and for learning your way around dotCMS.

# The correct starter file url varies by dotCMS version.

# This script checks out github.com/dotCMS/core then prints the 
# CUSTOM_STARTER_URL env var to use in docker-compose.yml or k8s

# This env var must be present the first time you start dotCMS.
# https://github.com/dotCMS/dotcms-utilities

if ! which git > /dev/null
then
    echo "'git' must be installed to run this script"
    echo
    exit 0
fi

gitdir=/var/tmp/dotcms-get-starter-urls-repo

if [ ! -d $gitdir ]
then
    echo "Initial clone of dotcms repo to $gitdir - this will take some time"
    echo
    git clone https://github.com/dotCMS/core.git $gitdir
fi

pushd  $gitdir >/dev/null
git checkout -q master
git pull -q
for version in $(git tag -l v* | sed 's/^v//' | sort -n | uniq | grep -v MM.YY)
do
    echo
    git checkout -q v${version}
    if [ -f dotCMS/build.gradle ]
    then
        starter_date=$(grep 'starter group' dotCMS/build.gradle | grep -v empty_ | awk -F \' '{print $6}')
    elif [ -f starter/pom.xml ]
    then
        starter_date=$(grep starter.zip.location.src/main/resources/local-zips/starter_20 starter/pom.xml | awk -F starter_ '{print $2}' | awk -F .zip '{print $1}')
    fi
    cat <<EOF
  dotcms:
    image: dotcms/dotcms:${version}
    environment:
      CUSTOM_STARTER_URL: https://repo.dotcms.com/artifactory/libs-release-local/com/dotcms/starter/${starter_date}/starter-${starter_date}.zip
EOF
done
git checkout -q master
echo
pushd >/dev/null