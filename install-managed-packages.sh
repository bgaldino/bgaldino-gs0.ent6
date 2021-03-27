#!/bin/sh
# Comment out the packages that you don't want to install in your org

# Salesforce CPQ 230.6 (SBQQ)
sfdx force:package:install -p 04t4N000000szN1QAI

# Salesforce Billing (230.2) (blng)
sfdx force:package:install -p 04t0K000001CpjYQAS

# Salesforce Advanced Approvals (230.1)
sfdx force:package:install -p 04t4W000002LinGQAS

# Mock Payment Adapter
sfdx force:package:install -p 04t2x000003t1MY

#Launch Flow in Modal (1.10)
sfdx force:package:install -p 04t2E000003VsVW