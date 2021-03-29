public virtual class StringBuilder {
	protected List<String> buffer = new List<String>();
	/**
	 * Construct an empty StringBuilder
	 **/
	public StringBuilder() {
	}

	/**
	 * Construct a StringBuilder with the given values
	 **/
	public StringBuilder(List<String> values) {
		add(values);
	}

	/**
	 * Add the given values to the StringBuilder
	 **/
	public virtual void add(List<String> values) {
		buffer.addAll(values);
	}

	/**
	 * Add the given value to the StringBuilder
	 **/
	public virtual void add(String value) {
		buffer.add(value);
	}

	public virtual override String toString() {
		return String.join(buffer, '');
	}

	/**
	 * Return the state of the StringBuilder
	 **/
	public virtual String getStringValue() {
		return toString();
	}

	/**
	 * Subclasses the StringBuilder to produce a comma delimited concatenation of strings
	 **/
	public virtual with sharing class CommaDelimitedListBuilder extends StringBuilder {
		String itemPrefix = '';
		String delimiter = ',';
		public CommaDelimitedListBuilder() {
		}

		public CommaDelimitedListBuilder(List<String> values) {
			super(values);
		}

		public void setItemPrefix(String itemPrefix) {
			this.itemPrefix = itemPrefix;
		}

		public void setDelimiter(String delimiter) {
			this.delimiter = delimiter;
		}

		public String getStringValue(String itemPrefix) {
			setItemPrefix(itemPrefix);
			return toString();
		}

		public override String toString() {
			return itemPrefix + String.join(buffer, delimiter + itemPrefix);
		}
	}

	/**
	 * Subclasses the StringCommaDelimitedBuilder to accept native SObjectField tokens and optional FieldSet definitions to concatinate when building queries
	 **/
	public virtual with sharing class FieldListBuilder extends CommaDelimitedListBuilder {
		public FieldListBuilder(List<Schema.SObjectField> values) {
			this(values, null);
		}

		public FieldListBuilder(List<Schema.SObjectField> values, List<Schema.FieldSet> fieldSets) {
			// Create a distinct set of fields (or field paths) to select
			for (Schema.SObjectField value : values)
				add(String.valueOf(value));
			// Alternative to value.getDescribe().getName()

			if (fieldSets != null)
				for (Schema.Fieldset fieldSet : fieldSets)
					for (Schema.FieldSetMember fieldSetMember : fieldSet.getFields())
						add(fieldSetMember.getFieldPath());
		}
	}

	/**
	 * Subclasses the FieldListBuilder to auto sense and include when needed the CurrencyIsoCode field in the field list
	 **/
	public with sharing class MultiCurrencyFieldListBuilder extends FieldListBuilder {
		public MultiCurrencyFieldListBuilder(List<Schema.SObjectField> values) {
			this(values, null);
		}

		public MultiCurrencyFieldListBuilder(List<Schema.SObjectField> values, List<Schema.FieldSet> fieldSets) {
			super(values, fieldSets);

			// Dynamically add CurrencyIsoCode field for multi-currency organisations
			if (UserInfo.isMultiCurrencyOrganization())
				add('CurrencyIsoCode');
		}
	}
}