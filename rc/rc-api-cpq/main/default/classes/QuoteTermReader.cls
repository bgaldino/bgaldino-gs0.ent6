public with sharing class QuoteTermReader {
    
    public List<QuoteTermModel> load(Id quoteId, Id templateId, String language) {
        TermContext ctx = new TermContext(templateId, language);
        String quoteTermsJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteTermAPI.Load', quoteId, JSON.serialize(ctx));
        return (List<QuoteTermModel>) JSON.deserialize(quoteTermsJSON, List<QuoteTermModel>.class);
    }

    private class TermContext {
        private Id templateId;
        private String language;
    
        private TermContext(Id templateId, String language) {
            this.templateId = templateId;
            this.language = language;
        }
    }
}