# Salesforce Revenue Cloud Quickstart

This project lets users automate the installation and configuration of Salesforce Revenue Cloud and includes modules for including advanced functionality and cross-cloud connectors. It's designed to be org-agnostic, so it can be run in almost any existing environment.  It has been thoroughly tested with the CDO and blank developer or enterprise orgs.

This project is in Salesforce DX source format, and the included scripts can be modified to your needs.  There are also DX config files that support working in scratch orgs.

The following modules are included:

1. **rc-base** contains base items, including a generic HttpService class to use for API calls in other modules
   
2. **rc-api-cpq** contains the latest Salesforce CPQ API models and reference classes for working with the [Salesforce CPQ API](https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_get_started.htm).
   
3. **rc-utils** contains useful tools for resetting demo data and contains quick actions for generating a quick quote or invoice from an Account record.

4. **rc-calm** contains everything needed to include [Customer Asset Lifecycle Management](https://help.salesforce.com/s/articleView?id=sf.lifecycle_mgmt.htm&type=5) functionality in your org.  There is also a lightning component for the Account page for asset-invoked amendments.
   
5. **rc-revenue** contains classes and metadata for including the [Recognize Revenue Service](https://developer.salesforce.com/docs/atlas.en-us.blng_dev.meta/blng_dev/apex_blng_RevenueRecognition_intro.htm) in your org using apex.
   
6. **rc-pilot** contains everyting you need to include new Subscription Management pilot functionality into your org.  This is designed for rudimentary co-existance with the managed packages.  Note: Salesforce Subscription Management is currently in pilot and is subject to change.  This module is for advanced users who have already provisioned pilot functionality.  This is not meant to replace the [Developer Preview](https://github.com/bgaldino/sm-dev-preview).