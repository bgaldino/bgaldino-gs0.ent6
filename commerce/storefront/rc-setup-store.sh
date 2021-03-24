#!/bin/bash
# Use this command followed by a store name.
#
# Before running this script make sure that you completed all the previous steps in the setup
# (run convert-examples-to-sfdx.sh, execute sfdx force:source:push -f, create store)
#
# This script will:
# - register the Apex classes needed for checkout integrations and map them to your store
# - associate the clone of the checkout flow to the checkout component in your store
# - add the Customer Community Plus Profile clone to the list of members for the store
# - import Products and necessary related store data in order to get you started
# - create a Buyer User and attach a Buyer Profile to it
# - create a Buyer Account and add it to the relevant Buyer Group
# - add Contact Point Addresses for Shipping and Billing to your new buyer Account
# - activate the store
# - publish your store so that the changes are reflected

if [ -z "$1" ]
then
	echo "You need to specify the name of the store."
else
	#############################
	#    Retrieve Store Info    #
	#############################

	communityNetworkName=$1
	# If the name of the store starts with a digit, the CustomSite name will have a prepended X.
	communitySiteName="$(echo $1 | sed -E 's/(^[0-9])/X\1/g')"
	# The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
	communityExperienceBundleName="$communitySiteName"1

	# Replace the names of the components that will be retrieved.
	sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" quickstart-config/package-retrieve-template.xml > package-retrieve.xml

	echo "Using this to retrieve your store info:"
	cat package-retrieve.xml

	echo "Retrieving the store metadata and extracting it from the zip file."
	sfdx force:mdapi:retrieve -r experience-bundle-package -k package-retrieve.xml
	unzip -d experience-bundle-package experience-bundle-package/unpackaged.zip

    #############################
	#       Update Store        #
	#############################

	storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`

	# Register Apex classes needed for checkout integrations and map them to the store
	echo "1. Setting up your integrations."

# For each Apex class needed for integrations, register it and map to the store
	function register_and_map_integration() {
		# $1 is Apex class name
		# $2 is DeveloperName
		# $3 is ExternalServiceProviderType

		echo "Registering Apex class $1 ($2) for $3 integration."

		 # Get the Id of the Apex class
		local apexClassId=`sfdx force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`
		if [ -z "$apexClassId" ]
		then
			echo "There was a problem getting the ID of the Apex class $1 for checkout integrations."
			echo "The registration and mapping for this class will be skipped!"
			echo "Make sure that you run convert-examples-to-sfdx.sh and execute sfdx force:source:push -f before setting up your store."
		else
			# Register the Apex class. If the class is already registered, a "duplicate value found" error will be displayed but the script will continue.
			sfdx force:data:record:create -s RegisteredExternalService -v "DeveloperName=$2 ExternalServiceProviderId=$apexClassId ExternalServiceProviderType=$3 MasterLabel=$2"

			# Map the Apex class to the store if no other mapping exists for the same Service Provider Type
			local storeIntegratedServiceId=`sfdx force:data:soql:query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$3' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
			if [ -z "$storeIntegratedServiceId" ]
			then
				# No mapping exists, so we will create one
				local registeredExternalServiceId=`sfdx force:data:soql:query -q "SELECT Id FROM RegisteredExternalService WHERE ExternalServiceProviderId='$apexClassId' LIMIT 1" -r csv |tail -n +2`
				sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$registeredExternalServiceId StoreId=$storeId ServiceProviderType=$3"
			else
				echo "There is already a mapping in this store for $3 ServiceProviderType: $storeIntegratedServiceId"
			fi
		fi
	}

	function register_and_map_pricing_integration {
		local serviceProviderType="Price"
		local integrationName="Price__B2B_STOREFRONT__StandardPricing"

		echo "Registering internal pricing ($integrationName) for $serviceProviderType integration."

		local pricingIntegrationId=`sfdx force:data:soql:query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$serviceProviderType' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
		if [ -z "$pricingIntegrationId" ]
		then
			sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$integrationName StoreId=$storeId ServiceProviderType=$serviceProviderType"
			echo "To register an external pricing integration, delete the internal pricing mapping and then add the external pricing mapping.  See the code for details how."
		else
			echo "There is already a mapping in this store for Price ServiceProviderType: $pricingIntegrationId"
		fi
	}

	function register_and_map_credit_card_payment_integration {
		echo "Registering credit card payment integration."

		# Creating Payment Gateway Provider
		apexClassId=`sfdx force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='SalesforceAdapter' LIMIT 1" -r csv |tail -n +2`
		echo "Creating PaymentGatewayProvider record using ApexAdapterId=$apexClassId."
		sfdx force:data:record:create -s PaymentGatewayProvider -v "DeveloperName=SalesforcePGP ApexAdapterId=$apexClassId MasterLabel=SalesforcePGP IdempotencySupported=Yes Comments=Comments"

		# Creating Payment Gateway
		paymentGatewayProviderId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGatewayProvider WHERE DeveloperName='SalesforcePGP' LIMIT 1" -r csv | tail -n +2`
		namedCredentialId=`sfdx force:data:soql:query -q "SELECT Id FROM NamedCredential WHERE MasterLabel='Salesforce' LIMIT 1" -r csv | tail -n +2`
		echo "Creating PaymentGateway record using MerchantCredentialId=$namedCredentialId, PaymentGatewayProviderId=$paymentGatewayProviderId."
		sfdx force:data:record:create -s PaymentGateway -v "MerchantCredentialId=$namedCredentialId PaymentGatewayName=SalesforcePG PaymentGatewayProviderId=$paymentGatewayProviderId Status=Active"

		# Creating Store Integrated Service
		storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$communityNetworkName' LIMIT 1" -r csv | tail -n +2`
		paymentGatewayId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGateway WHERE PaymentGatewayName='SalesforcePG' LIMIT 1" -r csv | tail -n +2`

		echo "Creating StoreIntegratedService using the $communityNetworkName store and Integration=$paymentGatewayId (PaymentGatewayId)"
		sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$paymentGatewayId StoreId=$storeId ServiceProviderType=Payment"
	}


	register_and_map_integration "B2BCheckInventorySample" "CHECK_INVENTORY" "Inventory"
	register_and_map_integration "B2BDeliverySample" "COMPUTE_SHIPPING" "Shipment"
	register_and_map_integration "B2BTaxSample" "COMPUTE_TAXES" "Tax"

	# By default, use the internal pricing integration
	register_and_map_pricing_integration
	# To use an external integration instead, use the code below:
	# register_and_map_integration "B2BPricingSample" "COMPUTE_PRICE" "Price"
	# Or follow the documentation for setting up the integration manually:
	# https://developer.salesforce.com/docs/atlas.en-us.b2b_comm_lex_dev.meta/b2b_comm_lex_dev/b2b_comm_lex_integration_setup.htm

	register_and_map_credit_card_payment_integration

	echo "You can view the results of the mapping in the Store Integrations page at /lightning/page/storeDetail?lightning__webStoreId=$storeId&storeDetail__selectedTab=store_integrations"

	# Map the checkout flow with the checkout component in the store
	echo "2. Updating flow associated to checkout."
	checkoutMetaFile="experience-bundle-package/unpackaged/experiences/$communityExperienceBundleName/views/checkout.json"
	tmpfile=$(mktemp)
	# This determines the name of the main flow as it will always be the only flow to terminate in "Checkout.flow"
	mainFlowName=`ls ../examples/checkout/framework/flows/*Checkout.flow | sed 's/.*flows\/\(.*\).flow/\1/'`
	sed "s/sfdc_checkout__CheckoutTemplate/$mainFlowName/g" $checkoutMetaFile > $tmpfile
	mv -f $tmpfile $checkoutMetaFile

	# Add the Customer Community Plus Profile clone to the list of members for the store
	#    + add value 'Live' to field 'status' to activate community
	echo "3. Updating members list and activating community."
	networkMetaFile="experience-bundle-package/unpackaged/networks/$communityNetworkName".network
	tmpfile=$(mktemp)
	sed "s/<networkMemberGroups>/<networkMemberGroups><profile>buyer_user_profile_from_quickstart<\/profile>/g;s/<status>.*/<status>Live<\/status>/g" $networkMetaFile > $tmpfile
	mv -f $tmpfile $networkMetaFile

    	# Import Products and related data
	# Get new Buyer Group Name
	echo "4. Importing products."
	buyergroupName=$(bash ./import_products.sh $1 | tail -n 1)

    
fi