public with sharing class B2BCreateQuote {
	@InvocableMethod
	public static List<B2BQuote> getQuoteItems(List<String> opptyID) {

		String x = opptyID[0];
		return new List<B2BQuote>{getQuote(x)};
	}

	public static B2BQuote getQuote(String opptyID) {
		//Get ID and AccountID from Opportunity
		//Get list of Products from Opportunity Product
		//List<Opportunity> Oppty = [SELECT ID, AccountID FROM Opportunity WHERE ID = :opptyID];
		//List<OpportunityLineItem> OpptyLIs = [SELECT Product2Id, Quantity, TotalPrice, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :opptyID];

		List<Opportunity> oppty = [SELECT Id, AccountID, Pricebook2Id, Cart__c
		                           FROM Opportunity
		                           WHERE Id = :opptyID];
		List<CartItem> cartItems = [SELECT Product2Id, Quantity, TotalPrice
		                            FROM CartItem
		                            WHERE CartID = :oppty[0].Cart__c];


		//Get Standard Price Book ID
		List<Pricebook2> pb = [SELECT Id
		                       from Pricebook2
		                       WHERE Name = 'Standard Price Book'];

		//Create Quote
		//Pricebook2Id: HARDCODE Standard PriceBook
		SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Primary__c = true, SBQQ__Account__c = oppty[0].AccountID, SBQQ__Opportunity2__c = oppty[0].ID, SBQQ__StartDate__c = system.today(), SBQQ__SubscriptionTerm__c = 12, SBQQ__Status__c = 'Draft', SBQQ__Type__c = 'eCommerce Request', SBQQ__PricebookId__c = oppty[0].Pricebook2Id, SBQQ__Pricebook__c = oppty[0].Pricebook2Id, SBQQ__ExpirationDate__c = system.today()+30);

		List<Contact> contactList = [SELECT Id
		                             FROM Contact
		                             WHERE AccountId = :oppty[0].AccountID
		                             LIMIT 1];
		if (contactList.size() > 0) {
			q.SBQQ__PrimaryContact__c = contactList.get(0).Id;
		}

		//Disable CPQ Triggers for Quote Insert
		SBQQ.TriggerControl.disable();
		//Database.insert(q);

		// Insert the quote
		try {
			Database.insert(q);
			System.debug('Successfully inserted new Quote: ' + q.Id);
		} catch (DmlException e) {
			System.debug('An error occurred inserting the Quote: ' + e);
			System.debug('Stack trace:' + e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}

		List<B2BQuote> listOfQuotes = new List<B2BQuote>{};
		B2BQuote a = new B2BQuote();
		a.cool_quoteID = q.id;
		listOfQuotes.add(a);

		List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>{};

		//Create Quote Lines by looping through Cart Items
		for (CartItem currentCartItem : cartItems) {
			SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
			ql.SBQQ__Product__c = currentCartItem.Product2ID;
			ql.SBQQ__Quantity__c = currentCartItem.Quantity;
			ql.SBQQ__Number__c = currentCartItem.Quantity;
			ql.SBQQ__Quote__c = q.id;
			ql.SBQQ__ProrateMultiplier__c = 1;
			ql.SBQQ__SubscriptionTerm__c = 12;
			ql.SBQQ__SubscriptionPricing__c = 'Fixed Price';
			ql.SBQQ__ChargeType__c = 'Recurring';
			ql.SBQQ__BillingType__c = 'Advance';
			ql.SBQQ__BillingFrequency__c = 'Monthly';

			//Retrieve PriceBook Entry for STANDARD PRICE BOOK for the Product
			List<PricebookEntry> pbe = [SELECT Id, UnitPrice
			                            FROM PricebookEntry
			                            WHERE Pricebook2Id = :pb[0].ID AND Product2Id = :currentCartItem.Product2ID];

			ql.SBQQ__PricebookEntryId__c = pbe[0].id;
			ql.SBQQ__ListPrice__c = pbe[0].UnitPrice;
			ql.SBQQ__NetPrice__c = pbe[0].UnitPrice;
			ql.SBQQ__CustomerPrice__c = pbe[0].UnitPrice;
			ql.SBQQ__RegularPrice__c = pbe[0].UnitPrice;
			lines.add(ql);
		}

		try {
			Database.insert(lines);
			System.debug('Successfully inserted new Quote Lines');
		} catch (DmlException e) {
			System.debug('An error occurred inserting the Quote Lines: ' + e);
			System.debug('Stack trace:' + e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}

		SBQQ.TriggerControl.enable();

		QuoteModel newQuoteModel = readQuote(q.Id);
		calculateQuote(newQuoteModel, 'RC_CPQAPICallback');

		//QuoteModel savedQuote = calculate(newQuoteModel);

		System.debug('****** Debug :   ' + listOfQuotes[0]);
		return listOfQuotes[0];
	}

	// Dummy Model for frontend input that we use to deserialize
	private class Model {
		@Auraenabled
		public String code;
		@Auraenabled
		public Integer quant;
	}

	/*
	 * CPQ Product APIs
	 */
	public static QuoteModel addProduct(QuoteModel quote, ProductModel[] products, Integer groupKey) {
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

	public static ProductModel readProduct(Id productId, Id pricebookId, String currencyCode) {
		ProductReaderContext ctx = new ProductReaderContext(pricebookId, currencyCode);
		String productJSON = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', productId, JSON.serialize(ctx));
		return (ProductModel)JSON.deserialize(productJSON, ProductModel.class);
	}

	private class ProductReaderContext {
		private Id pricebookId;
		private String currencyCode;
		private ProductReaderContext(Id pricebookId, String currencyCode) {
			this.pricebookId = pricebookId;
			this.currencyCode = currencyCode;
		}
	}

	/*
	 * CPQ Quote API functions
	 */
	public static QuoteModel readQuote(String quoteId) {
		String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
		return (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.class);
	}

	public static QuoteModel saveQuote(QuoteModel quote) {
		String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
		return (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.class);
	}

	public static void calculateQuote(QuoteModel quote, String callbackClass) {
		QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, callbackClass);
		SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
	}

	public static QuoteModel calculate(QuoteModel quote) {
		QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote);
		String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
		return (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.class);
	}

	public void calculate(QuoteModel quote, String callbackClass) {
		QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, callbackClass);
		SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
	}

	public with sharing class QuoteCalculatorContext {
		private QuoteModel quote;
		private String callbackClass;
		public QuoteCalculatorContext(QuoteModel quote, String callbackClass) {
			this.quote = quote;
			this.callbackClass = callbackClass;
		}

		public QuoteCalculatorContext(QuoteModel quote) {
			this.quote = quote;
			this.callbackClass = null;
		}
	}
}