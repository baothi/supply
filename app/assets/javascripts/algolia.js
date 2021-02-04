$(document).on('ready page:load', function(){
  window.algolia = { widgets: {} };

    window.algolia.widgets.excludeIneligibleProducts = {
        init: function(options) {
            const helper = options.helper;
            $('#excludeIneligibleProducts').change(function() {
                helper.setQueryParameter('facets', ['eligible_for_international_sale']);
                if($(this).prop('checked') === true) {
                    helper.addFacetRefinement('eligible_for_international_sale', true);
                }  else {
                    helper.clearRefinements('eligible_for_international_sale', true);
                }
                helper.search();
            });
        }
    }

  window.algolia.widgets.excludeShopifyProducts = {
    init: function(options) {
      const helper = options.helper;


      $('#excludeShopifyProducts').change(function() {
          const internal_identifiers = window.live_shopify_products_identifiers;
          const product_identifiers = window.retailer_black_listed_products;
          const supplier_identifiers = window.retailer_black_listed_suppliers;

        if ( (internal_identifiers.length > 0) && ($(this).prop('checked') === true) ) {
            helper.setQueryParameter('facets', ['internal_identifier', 'supplier_internal_identifier']);
            helper.setQueryParameter('facetsExcludes', {
              internal_identifier: internal_identifiers.concat(product_identifiers),
              supplier_internal_identifier: supplier_identifiers
          } );
        } else {
            helper.setQueryParameter('facets', ['internal_identifier', 'supplier_internal_identifier']);
            helper.setQueryParameter('facetsExcludes',
            {
                internal_identifier: product_identifiers,
                supplier_internal_identifier: supplier_identifiers
            });
        }
        helper.search();
      });
    }
  };

  window.algolia.widgets.excludeZeroInventoryProducts = {
    init: function(options) {
      const helper = options.helper;
      $('#excludeZeroInventoryProducts').change(function() {
        if($(this).prop('checked') === true) {
          helper.addNumericRefinement('stock_quantity', '>', 0);
        }  else {
          helper.clearRefinements('stock_quantity', '>', 0);
        }
        helper.search();
      });
    }
  }

  window.algolia.widgets.excludeBlackListedProducts = {
    init: function(options) {
      const helper = options.helper;
      const product_identifiers = window.retailer_black_listed_products;
      const supplier_identifiers = window.retailer_black_listed_suppliers;
      helper.setQueryParameter('facets', ['internal_identifier', 'supplier_internal_identifier']);
      helper.setQueryParameter('facetsExcludes',
          {
              internal_identifier: product_identifiers,
              supplier_internal_identifier: supplier_identifiers
          });
      helper.search();
    }
  };

});
