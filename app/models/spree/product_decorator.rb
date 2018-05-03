module Spree
  Product.class_eval do
    translates :name, :description, :meta_description, :meta_keywords,
      fallbacks_for_empty_translations: true

    include SolidusGlobalize::Translatable

    translation_class.class_eval do
      # Paranoia soft-deletes the associated records only if they are paranoid themselves.
      acts_as_paranoid

      # Paranoid sets the default scope and Globalize rewrites all query methods.
      # Therefore we prefer to unset the default_scopes over injecting 'unscope'
      # in every Globalize query method.
      self.default_scopes = []

      
    end

    # Allow to filter products through their translations, too
    def self.like_any(fields, values)
      translations = Spree::Product::Translation.arel_table
      source = fields.product(values, [translations, arel_table])
      clauses = source.map do |(field, value, arel)|
        arel[field].matches("%#{value}%")
      end.inject(:or)

      joins(:translations).where(translations[:locale].eq(I18n.locale)).where(clauses)
    end

    def duplicate_extra(old_product)
      duplicate_translations(old_product)
    end

    private

    def duplicate_translations(old_product)
      old_product.translations.each do |translation|
        self.translations << translation.dup
      end
    end
  end
end
