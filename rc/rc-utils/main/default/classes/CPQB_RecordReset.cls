public with sharing class CPQB_RecordReset {
  // public static void delObjects(String targetObject, String lookupField, Id matchId) {
  //     String dbQuery = 'SELECT Id,' + lookupField + ' FROM ' + targetObject + ' WHERE ' + lookupField + ' = :matchId';
  //     SObject[] sObjsToDelete = Database.query(dbQuery);
  //     try {
  //         Database.delete(sObjsToDelete);
  //     } catch (DmlException e) {
  //         System.debug(e);
  //         throw new AuraHandledException(e.getMessage());
  //     }
  // }

  public static Boolean disableBillingTriggers(Boolean triggersDisabled) {
    blng__BillingConfig__c triggerConfig = [
      SELECT Id, Name, blng__BooleanValue__c
      FROM blng__BillingConfig__c
      WHERE Name = 'DISABLE_TRIGGERS'
    ];
    triggerConfig.blng__BooleanValue__c = triggersDisabled;
    SObject so = (SObject) triggerConfig;
    Database.SaveResult sr = Database.updateImmediate(so);
    if (sr.isSuccess()) {
      String msg = triggersDisabled ? 'disabled' : 'enabled';
      System.debug('Successfully ' + msg + ' Billing Triggers');
      return true;
    } else {
      for (Database.Error err : sr.getErrors()) {
        System.debug('The following error has occurred.');
        System.debug(err.getStatusCode() + ': ' + err.getMessage());
        throw new AuraHandledException(err.getMessage());
      }
      return false;
    }
  }

  public static Boolean setAccountResetStatus(Id accId, Boolean reset) {
    Account accToReset = [SELECT Id, Reset__c FROM Account WHERE Id = :accId];
    accToReset.Reset__c = reset;
    SObject so = (SObject) accToReset;
    Database.SaveResult sr = Database.updateImmediate(so);
    if (sr.isSuccess()) {
      String msg = reset ? 'disabled' : 'enabled';
      System.debug('Successfully ' + msg + ' Account Reset Flag');
      return true;
    } else {
      for (Database.Error err : sr.getErrors()) {
        System.debug('The following error has occurred.');
        System.debug(err.getStatusCode() + ': ' + err.getMessage());
        throw new AuraHandledException(err.getMessage());
      }
      return false;
    }
  }

  public static void deleteDiscScheds(Id accId) {
    SBQQ__DiscountSchedule__c[] dsToDelete = [
      SELECT Id, SBQQ__Account__c
      FROM SBQQ__DiscountSchedule__c
      WHERE SBQQ__Account__c = :accId
    ];
    try {
      Database.delete(dsToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteProcessInputValues(Set<Id> quotes) {
    SBQQ__ProcessInputValue__c[] valuesToDelete = [
      SELECT Id, SBQQ__QuoteId__c
      FROM SBQQ__ProcessInputValue__c
      WHERE SBQQ__QuoteId__c IN :quotes
    ];
    try {
      Database.delete(valuesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteOrders(Id accId) {
    blng__BillingSchedule__c[] BS = [
      SELECT Id, blng__OrderProduct__r.Order.AccountId
      FROM blng__BillingSchedule__c
      WHERE blng__OrderProduct__r.Order.AccountId = :accId
    ];
    try {
      Database.delete(BS);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }

    Map<Id, Order> ordersToDelete = new Map<Id, Order>(
      [SELECT Id, AccountId FROM Order WHERE AccountId = :accId]
    );
    if (ordersToDelete.isEmpty()) {
      return;
    }
    for (Order o : ordersToDelete.values()) {
      o.SBQQ__Contracted__c = false;
    }
    Database.update(ordersToDelete.values());

    Map<Id, OrderItem> orderItems = new Map<Id, OrderItem>(
      [SELECT Id FROM OrderItem WHERE OrderId IN :ordersToDelete.keyset()]
    );
    if (!orderItems.isEmpty()) {
      for (OrderItem oi : orderItems.values()) {
        oi.SBQQ__Contracted__c = false;
      }

      CPQB_RecordReset.deleteOIRevenueSchedules(orderItems.keySet());
      CPQB_RecordReset.deleteUsages(orderItems.keySet());
      CPQB_RecordReset.deleteUsageSummaries(orderItems.keySet());
      CPQB_RecordReset.deleteOrderConsumption(orderItems.keySet());
      Database.update(orderItems.values());
    }
    for (Order o : ordersToDelete.values()) {
      o.Status = 'Draft';
      o.SBQQ__Contracted__c = false;
    }

    try {
      Database.update(ordersToDelete.values());
      Database.delete(ordersToDelete.values());
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  // Delete Opps
  public static void deleteOpportunities(Id accId) {
    Opportunity[] opportinitiesToDelete = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE AccountId = :accId
    ];
    try {
      Database.delete(opportinitiesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  // Delete Assets
  public static void deleteAssets(Id accId) {
    //        Asset[] assetsToDelete = [SELECT Id, AccountId FROM Asset WHERE AccountId = :accId AND HasLifecycleManagement = FALSE];
    try {
      //            Database.delete(assetsToDelete);
      Id assetDeletionAccountId = [
          SELECT Id
          FROM Account
          WHERE Name = 'AssetDeletionIsland - DO NOT DELETE'
        ]
        .get(0)
        .Id;

      Asset[] assetsToDelete = [SELECT Id FROM Asset WHERE AccountId = :accId];
      if (!assetsToDelete.isEmpty()) {
        for (Asset asst : assetsToDelete) {
          asst.AccountId = assetDeletionAccountId;
        }

        database.update(assetsToDelete);
      }
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  // Delete Subs
  public static void deleteSubscriptions(Id accId) {
    SBQQ__Subscription__c[] subscriptionsToDelete = [
      SELECT Id, SBQQ__Account__r.Id
      FROM SBQQ__Subscription__c
      WHERE SBQQ__Account__r.Id = :accId
    ];
    try {
      Database.delete(subscriptionsToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteContracts(Id accId) {
    Contract[] contractsToDelete = [
      SELECT Id, SBQQ__RenewalOpportunity__c, AccountId
      FROM Contract
      WHERE AccountId = :accId
    ];
    if (!contractsToDelete.isEmpty()) {
      for (Contract c : contractsToDelete) {
        c.SBQQ__RenewalOpportunity__c = null;
      }
      try {
        Database.update(contractsToDelete);
        Database.delete(contractsToDelete);
      } catch (DmlException e) {
        System.debug(e);
        throw new AuraHandledException(e.getMessage());
      }
    }
  }

  public static void deleteQuotes(Id accId) {
    Map<Id, SBQQ__Quote__c> quotesToDelete = new Map<Id, SBQQ__Quote__c>(
      [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__r.Id = :accId]
    );
    if (quotesToDelete.isEmpty()) {
      return;
    }

    CPQB_RecordReset.deleteProcessInputValues(quotesToDelete.keySet());

    try {
      Database.delete(quotesToDelete.values());
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteContractedPrices(Id accId) {
    SBQQ__ContractedPrice__c[] cpToDelete = [
      SELECT Id
      FROM SBQQ__ContractedPrice__c
      WHERE SBQQ__Account__c = :accId
    ];
    try {
      Database.delete(cpToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteOrderConsumption(Set<Id> orderItemIds) {
    SBQQ__OrderItemConsumptionSchedule__c[] ocToDelete = [
      SELECT Id
      FROM SBQQ__OrderItemConsumptionSchedule__c
      WHERE SBQQ__OrderItem__c IN :orderItemIds
    ];
    try {
      Database.delete(ocToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * blng Object reset
   *
   *
   *
   *
   *
   */

  public static void deletePaymentTransactions(Id accId) {
    blng__PaymentTransaction__c[] trxToDelete = [
      SELECT Id, blng__Account__c
      FROM blng__PaymentTransaction__c
      WHERE blng__Account__c = :accId
    ];
    try {
      Database.delete(trxToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteCreditNotes(Id accId) {
    blng__CreditNote__c[] creditNotesToDelete = [
      SELECT Id, blng__Account__c
      FROM blng__CreditNote__c
      WHERE blng__Account__c = :accId
    ];
    try {
      Database.delete(creditNotesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteDebitNotes(Id accId) {
    blng__DebitNote__c[] debitNotesToDelete = [
      SELECT Id, blng__Account__c
      FROM blng__DebitNote__c
      WHERE blng__Account__c = :accId
    ];
    try {
      Database.delete(debitNotesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deletePayments(Id accId) {
    blng__Payment__c[] payments = [
      SELECT Id, blng__Account__c
      FROM blng__Payment__c
      WHERE blng__Account__c = :accId
    ];
    try {
      Database.delete(payments);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteRefunds(Id accId) {
    blng__Refund__c[] refunds = [
      SELECT Id, blng__Account__c
      FROM blng__Refund__c
      WHERE blng__Account__c = :accId
    ];
    try {
      Database.delete(refunds);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteInvoices(Id accId) {
    blng__Invoice__c[] invoicesToDelete = [
      SELECT Id, blng__InvoiceStatus__c, blng__Account__r.Id, Reset__c
      FROM blng__Invoice__c
      WHERE blng__Account__r.Id = :accId
    ];

    if (!invoicesToDelete.isEmpty()) {
      Set<Id> invoiceIds = new Set<Id>();
      blng__Invoice__c[] invoicesToUpdate = new List<blng__Invoice__c>();

      for (blng__Invoice__c invoice : invoicesToDelete) {
        invoiceIds.add(invoice.Id);
        blng.InvoiceAPI.creditInvoice(invoice.Id, 'Cancel and Re-bill');
        invoicesToUpdate.add(invoice);
      }
      if (!invoicesToUpdate.isEmpty()) {
        Database.update(invoicesToUpdate);
      }

      Map<Id, blng__InvoiceLine__c> invoiceLines = new Map<Id, blng__InvoiceLine__c>(
        [
          SELECT Id, blng__Invoice__c
          FROM blng__InvoiceLine__c
          WHERE blng__Invoice__c IN :invoiceIds
        ]
      );
      if (!invoiceLines.isEmpty()) {
        CPQB_RecordReset.deleteILRevenueSchedules(invoiceLines.keySet());
      }
      Database.delete(invoicesToDelete);
    }

    System.debug(
      'Total Number of SOQL Queries after deleteInvoices(): ' +
      Limits.getQueries()
    );
  }

  public static void deleteUsages(Set<Id> orderItemIds) {
    blng__Usage__c[] usagesToDelete = [
      SELECT Id, blng__OrderProduct__c
      FROM blng__Usage__c
      WHERE blng__OrderProduct__c IN :orderItemIds
    ];
    try {
      Database.delete(usagesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteUsageSummaries(Set<Id> orderItemIds) {
    blng__UsageSummary__c[] usageSummariesToDelete = [
      SELECT Id, blng__OrderProduct__c
      FROM blng__UsageSummary__c
      WHERE blng__OrderProduct__c IN :orderItemIds
    ];
    try {
      Database.delete(usageSummariesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteOIRevenueSchedules(Set<Id> orderItemIds) {
    blng__RevenueSchedule__c[] revenueSchedulesToDelete = [
      SELECT Id, blng__OrderProduct__c
      FROM blng__RevenueSchedule__c
      WHERE blng__OrderProduct__c IN :orderItemIds
    ];
    try {
      Database.delete(revenueSchedulesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteILRevenueSchedules(Set<Id> invLineIds) {
    blng__RevenueSchedule__c[] revenueSchedulesToDelete = [
      SELECT Id
      FROM blng__RevenueSchedule__c
      WHERE blng__InvoiceLine__c IN :invLineIds
    ];
    try {
      Database.delete(revenueSchedulesToDelete);
    } catch (DmlException e) {
      System.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void deleteFinanceTransactions(Id accountId) {
    List<Id> idsToDel = new List<Id>();
    List<Id> ids = FinanceTransactionAPI.doGet(accountId);
    if (ids.size() > 200) {
      Integer count = ids.size();
      while (count > 200) {
        Integer i = 0;
        for (Id id : ids) {
          idsToDel.add(ids[i]);
          ids.remove(i);
          i++;
        }
      }
      if (idsToDel.size() < 200) {
        FinanceTransactionAPI.doDeleteComposite(idsToDel);
      }
    } else {
      FinanceTransactionAPI.doDeleteComposite(ids);
    }
  }
}
