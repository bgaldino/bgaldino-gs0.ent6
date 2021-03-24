public with sharing class ConfigLoader {
	public ProductModel load(Id productId, QuoteModel quote, ProductModel parentProduct) {
		ConfigLoadContext ctx = new ConfigLoadContext(quote, parentProduct);
		String productJSON = SBQQ.ServiceRouter.load('SBQQ.ConfigAPI.ConfigLoader', productId, JSON.serialize(ctx));
		return (ProductModel)JSON.deserialize(productJSON, ProductModel.class);
	}

	private class ConfigLoadContext {
		private QuoteModel quote;
		private ProductModel parentProduct;
		private ConfigLoadContext(QuoteModel quote, ProductModel parentProduct) {
			this.quote = quote;
			this.parentProduct = parentProduct;
		}
	}
}