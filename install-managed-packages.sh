#!/bin/sh
# Comment out the packages that you don't want to install in your org

# TO DO:  Use env or org API version variable to determine package versions to install

# Salesforce CPQ 230.6 (SBQQ)
#sfdx force:package:install -p 04t4N000000szN1QAI
# Salesforce CPQ 232.2 (SBQQ)
#sfdx force:package:install -p 04t4N000000GkFyQAK

# Salesforce CPQ 234.0 (SBQQ)
sfdx force:package:install -p 04t4N000000GkLSQA0

# Salesforce Billing (230.2) (blng)
#sfdx force:package:install -p 04t0K000001CpjYQAS
# Salesforce Billing (232.2) (blng)
#sfdx force:package:install -p 04t0K000001RuGTQA0

# Salesforce Billing (234.0) (blng)
sfdx force:package:install -p 04t0K000001RuHvQAK

# Salesforce Advanced Approvals (230.1)
#sfdx force:package:install -p 04t4W000002LinGQAS
# Salesforce Advanced Approvals (232.2)
#sfdx force:package:install -p 04t4W000002d9axQAA

# Salesforce Advanced Approvals (234.0)
sfdx force:package:install -p 04t4W000002d9sPQAQ

# Mock Payment Adapter
sfdx force:package:install -p 04t2x000003t1MY

#Launch Flow in Modal (1.12)
sfdx force:package:install -p 04t2E000003VssGQAS

#B2B LE Connector
sfdx force:package:install -p 04t4x0000001S4rAAE