public without sharing class AccountUtilitiesController {

    public Id AccountId { get; set; }
    private ApexPages.StandardController Controller;
    private Id[] QuotesToDelete;

    //CONSTRUCTOR for VF Pages
    public AccountUtilitiesController(ApexPages.StandardController stdController) {
        this.AccountId = stdController.getId();
        this.Controller = stdController;
    }

    public PageReference resetAccount() {
        this.disableBillingTriggers();
        this.deleteDiscScheds();
        this.deletePaymentTransactions();
        this.deletePayments();
        this.deleteCreditNotes();
        this.deleteDebitNotes();
        this.deleteRefunds();
        this.deleteInvoices();
        this.deleteQuotes();
        this.deleteAssets();
        this.deleteSubscriptions();
        this.deleteContracts();
        this.deleteOrders();
        this.deleteCreditNotes();
        this.deleteOpportunities();
        this.enableBillingTriggers();

        System.debug('Total Number of SOQL Queries in this apex code context: ' + Limits.getQueries());

        return this.Controller.view();
    }

    private Boolean disableBillingTriggers() {
        blng__BillingConfig__c triggerConfig = [SELECT Id, Name, blng__BooleanValue__c FROM blng__BillingConfig__c WHERE Name = 'DISABLE_TRIGGERS'];
        triggerConfig.blng__BooleanValue__c = true;
        SObject s = (SObject) triggerConfig;
        Database.SaveResult sr = Database.updateImmediate(s);
        if (sr.isSuccess()) {
            System.debug('Successfully disabled Billing Triggers');
            return true;
        } else {
            for (Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }
            return false;
        }
    }

    private Boolean enableBillingTriggers() {
        blng__BillingConfig__c triggerConfig = [SELECT Id, Name, blng__BooleanValue__c FROM blng__BillingConfig__c WHERE Name = 'DISABLE_TRIGGERS'];
        triggerConfig.blng__BooleanValue__c = false;
        SObject s = (SObject) triggerConfig;
        Database.SaveResult sr = Database.updateImmediate(s);
        if (sr.isSuccess()) {
            System.debug('Successfully enabled Billing Triggers');
            return true;
        } else {
            for (Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }
            return false;
        }
    }

    private Boolean deleteDiscScheds() {
        Id a = this.AccountId;
        SBQQ__DiscountSchedule__c[] dsToDelete = [SELECT Id FROM SBQQ__DiscountSchedule__c WHERE SBQQ__Account__c = :a];
        if (!dsToDelete.isEmpty()) {
            Database.delete(dsToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteDiscScheds(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteProcessInputValues(Set<Id> quotes) {
        //Id a = this.AccountId;
        SBQQ__ProcessInputValue__c[] valuesToDelete = [SELECT Id FROM SBQQ__ProcessInputValue__c WHERE SBQQ__QuoteId__c IN :quotes];
        if (!valuesToDelete.isEmpty()) {
            Database.delete(valuesToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteProcessInputValues(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deletePaymentTransactions() {
        Id a = this.AccountId;
        blng__PaymentTransaction__c[] trxToDelete = [SELECT Id FROM blng__PaymentTransaction__c WHERE blng__Account__c = :a];
        if (!trxToDelete.isEmpty()) {
            Database.delete(trxToDelete);
        }

        System.debug('Total Number of SOQL Queries after deletePaymentTransactions(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteCreditNotes() {
        Id a = this.AccountId;
        blng__CreditNote__c[] creditNotesToDelete = [SELECT Id FROM blng__CreditNote__c WHERE blng__Account__c = :a];
        if (!creditNotesToDelete.isEmpty()) {
            Database.delete(creditNotesToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteCreditNotes(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteDebitNotes() {
        Id a = this.AccountId;
        blng__DebitNote__c[] debitNotesToDelete = [SELECT Id FROM blng__DebitNote__c WHERE blng__Account__c = :a];
        if (!debitNotesToDelete.isEmpty()) {
            Database.delete(debitNotesToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteDebitNotes(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteInvoices() {
        Id a = this.AccountId;
        blng__Invoice__c[] invoicesToDelete = [SELECT Id, blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Account__r.Id = :a];
        if (!invoicesToDelete.isEmpty()) {
            Set<Id> invoiceIds = new Set<Id>();
            blng__Invoice__c[] invoicesToUpdate = new List<blng__Invoice__c>();

            for (blng__Invoice__c invoice : invoicesToDelete) {
                invoiceIds.add(invoice.Id);
                if (invoice.blng__InvoiceStatus__c == 'Posted') {
                    blng.InvoiceAPI.creditInvoice(invoice.Id, 'Cancel and Re-bill');
                    invoicesToUpdate.add(invoice);
                }
            }
            if (!invoicesToUpdate.isEmpty()) {
                Database.update(invoicesToUpdate);
            }
            blng__InvoiceLine__c[] invoiceLines = getInvoiceLines(invoiceIds);
            if (!invoiceLines.isEmpty()) {
                this.deleteRevenueSchedules(invoiceLines);
            }
            Database.delete(invoicesToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteInvoices(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteOrders() {
        Id a = this.AccountId;
        Order[] ordersToDelete = [SELECT Id FROM Order WHERE AccountId = :a];
        if (!ordersToDelete.isEmpty()) {
            Set<Id> orderIds = new Set<Id>();
            for (Order o : ordersToDelete) {
                orderIds.add(o.Id);
                o.Status = 'Draft';
                o.SBQQ__Contracted__c = false;
            }
            OrderItem[] orderItems = getOrderItems(orderIds);
            if (!orderItems.isEmpty()) {
                for (OrderItem oi : orderItems) {
                    oi.SBQQ__Contracted__c = false;
                }

                this.deleteRevenueSchedules(orderItems);
                this.deleteUsages(orderItems);
                this.deleteUsageSummaries(orderItems);
                Database.update(orderItems);
            }
            Database.update(ordersToDelete);
            Database.delete(ordersToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteOrders(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteUsages(OrderItem[] orderItems) {
        if (!orderItems.isEmpty()) {
            Set<Id> orderItemIds = new Set<Id>();
            for (OrderItem oi : orderItems) {
                orderItemIds.add(oi.Id);
            }
            blng__Usage__c[] usagesToDelete = [SELECT Id FROM blng__Usage__c WHERE blng__OrderProduct__c IN :orderItemIds];
            if (!usagesToDelete.isEmpty()) {
                Database.delete(usagesToDelete);
            }
        }

        System.debug('Total Number of SOQL Queries after deleteUsages(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteUsageSummaries(OrderItem[] orderItems) {
        if (!orderItems.isEmpty()) {
            Set<Id> orderItemIds = new Set<Id>();
            for (OrderItem oi : orderItems) {
                orderItemIds.add(oi.Id);
            }
            blng__UsageSummary__c[] usageSummariesToDelete = [SELECT Id FROM blng__UsageSummary__c WHERE blng__OrderProduct__c IN :orderItemIds];
            if (!usageSummariesToDelete.isEmpty()) {
                Database.delete(usageSummariesToDelete);
            }
        }

        System.debug('Total Number of SOQL Queries after deleteUsageSummaries(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteRevenueSchedules(OrderItem[] orderItems) {
        if (!orderItems.isEmpty()) {
            Set<Id> orderItemIds = new Set<Id>();
            for (OrderItem oi : orderItems) {
                orderItemIds.add(oi.Id);
            }
            blng__RevenueSchedule__c[] revenueSchedulesToDelete = [SELECT Id FROM blng__RevenueSchedule__c WHERE blng__OrderProduct__c IN :orderItemIds];
            if (!revenueSchedulesToDelete.isEmpty()) {
                Database.delete(revenueSchedulesToDelete);
            }
        }

        System.debug('Total Number of SOQL Queries after deleteRevenueSchedules(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteRevenueSchedules(blng__InvoiceLine__c[] invLines) {
        if (!invLines.isEmpty()) {
            Set<Id> invLineIds = new Set<Id>();
            for (blng__InvoiceLine__c line : invLines) {
                invLineIds.add(line.Id);
            }
            blng__RevenueSchedule__c[] revenueSchedulesToDelete = [SELECT Id FROM blng__RevenueSchedule__c WHERE blng__InvoiceLine__c IN :invLineIds];
            if (!revenueSchedulesToDelete.isEmpty()) {
                Database.delete(revenueSchedulesToDelete);
            }
        }

        System.debug('Total Number of SOQL Queries after deleteRevenueSchedules(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteOpportunities() {
        Id a = this.AccountId;
        Opportunity[] opportinitiesToDelete = [SELECT Id FROM Opportunity WHERE AccountId = :a];
        if (!opportinitiesToDelete.isEmpty()) {
            Database.delete(opportinitiesToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteOpportunities(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteAssets() {
        Id a = this.AccountId;
        Id assetDeletionAccountId = [SELECT Id FROM Account WHERE Name = 'AssetDeletionIsland - DO NOT DELETE'].get(0).Id;
        
        Asset[] assetsToDelete = [SELECT Id FROM Asset WHERE AccountId = :a];
        if (!assetsToDelete.isEmpty()) {
            for(Asset asst: assetsToDelete){
                asst.AccountId = assetDeletionAccountId;
            }
            
            database.update(assetsToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteAssets(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteSubscriptions() {
        Id a = this.AccountId;
        SBQQ__Subscription__c[] subscriptionsToDelete = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Account__r.Id = :a];
        if (!subscriptionsToDelete.isEmpty()) {
            Database.delete(subscriptionsToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteSubscriptions(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteContracts() {
        Id a = this.AccountId;
        Contract[] contractsToDelete = [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE AccountId = :a];
        if (!contractsToDelete.isEmpty()) {
            for (Contract c : contractsToDelete) {
                c.SBQQ__RenewalOpportunity__c = null;
            }
            Database.update(contractsToDelete);
            Database.delete(contractsToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteContracts(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteQuotes() {
        Id a = this.AccountId;
        SBQQ__Quote__c[] quotesToDelete = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__r.Id = :a];
        if (!quotesToDelete.isEmpty()) {
            Set<Id> quoteIds = new Set<Id>();
            for (SBQQ__Quote__c q : quotesToDelete) {
                quoteIds.add(q.Id);
            }
            this.deleteProcessInputValues(quoteIds);
            Database.delete(quotesToDelete);
        }

        System.debug('Total Number of SOQL Queries after deleteQuotes(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deletePayments() {
        Id a = this.AccountId;
        blng__Payment__c[] payments = [SELECT Id FROM blng__Payment__c WHERE blng__Account__c = :a];
        if (!payments.isEmpty()) {
            Database.delete(payments);
        }

        System.debug('Total Number of SOQL Queries after deletePayments(): ' + Limits.getQueries());

        return true;
    }

    private Boolean deleteRefunds() {
        Id a = this.AccountId;
        blng__Refund__c[] refunds = [SELECT Id FROM blng__Refund__c WHERE blng__Account__c = :a];
        if (!refunds.isEmpty()) {
            Database.delete(refunds);
        }

        System.debug('Total Number of SOQL Queries after deleteRefunds(): ' + Limits.getQueries());

        return true;
    }

    private static List<OrderItem> getOrderItems(Set<Id> orderIds) {
        OrderItem[] orderItems = [SELECT Id FROM OrderItem WHERE OrderId IN :orderIds];
        return orderItems;
    }

    private static List<blng__InvoiceLine__c> getInvoiceLines(Set<Id> invoiceIds) {
        blng__InvoiceLine__c[] invoiceLines = [SELECT Id FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN :invoiceIds];
        return invoiceLines;
    }
}