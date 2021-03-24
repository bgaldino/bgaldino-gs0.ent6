global with sharing class RC_CPQAPICallback implements SBQQ.CalculateCallback {
    global void callback(String quoteJSON) {
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);
    }
}