#!/bin/sh

set -e

image="kubenow-v020a1"
if glance image-list | grep $image > /dev/null
then
    echo "$image already exists - nothing needed to be done"
else
    echo "$image does not exist - execute create command"
    glance --os-image-api-version 1 image-create --copy-from https://swift-se.citycloud.com/v1/AUTH_17bcdf88f1fd40de85f53b5038722681/kubenow-images/kubenow-v020a1.qcow2 --disk-format qcow2 --min-disk 20 --container-format bare --name kubenow-v020a1 --progress
fi
