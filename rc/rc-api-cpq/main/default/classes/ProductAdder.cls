public with sharing class ProductAdder {
	public QuoteModel add(QuoteModel quote, ProductModel[] products, Integer groupKey) {
		AddProductsContext ctx = new AddProductsContext(quote, products, groupKey);
		String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, JSON.serialize(ctx));
		return (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.class);
	}

	private class AddProductsContext {
		private QuoteModel quote;
		private ProductModel[] products;
		private Integer groupKey;
		private final Boolean ignoreCalculate = true; //Must be hardcoded to true
		private AddProductsContext(QuoteModel quote, ProductModel[] products, Integer groupKey) {
			this.quote = quote;
			this.products = products;
			this.groupKey = groupKey;
		}
	}
}