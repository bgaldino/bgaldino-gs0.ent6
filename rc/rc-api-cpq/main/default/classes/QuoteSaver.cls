public with sharing class QuoteSaver {
	public QuoteModel save(QuoteModel quote) {
		String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
		return (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.class);
	}
}