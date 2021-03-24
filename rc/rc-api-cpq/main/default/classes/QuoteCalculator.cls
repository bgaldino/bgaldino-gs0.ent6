public with sharing class QuoteCalculator {
	public void calculate(QuoteModel quote, String callbackClass) {
		QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, callbackClass);
		SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
	}

	private class QuoteCalculatorContext {
		private QuoteModel quote;             //The quote and callbackClass properties are called in the API code by the exact names seen here.
		private String callbackClass;         //Altering these property names will cause calculator API calls to fail.
		private QuoteCalculatorContext(QuoteModel quote, String callbackClass) {
			this.quote = quote;
			this.callbackClass = callbackClass;
		}
	}
}