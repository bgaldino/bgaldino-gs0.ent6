#!/bin/sh
# Use this command to create a new store.
# The name of the store can be passed as a parameter.

storename=""
urlprefix="storefront"
if [ -z "$1" ]
then
    echo "A new store will be created... Please enter the name of the store: "
    read storename
else
    storename=$1
fi
sfdx force:community:create --name "$storename" --templatename "B2B Commerce" --urlpathprefix "$urlprefix" --description "Store $storename based on standard B2B Commerce Template."
echo "When your site (community) is ready it will appear in the list. After verifying that the new store is created, run the quickstart-setup-store.sh script with the store name ('$storename') as parameter."