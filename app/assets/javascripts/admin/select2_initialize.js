$(document).ready(function(e) {
  permittableSelect2();
  selectPermittableDefaultOption();

  retailerSelect2();
});

function permittableSelect2() {
  $('#selling-authority-permittable-string').select2({
    ajax: {
      url: "/active/admin/spree_selling_authorities/search_permittable.json",
      dataType: 'json',
      delay: 250
    },
    placeholder: 'Search for a Product/Supplier',
    minimumInputLength: 0
  });
}

function selectPermittableDefaultOption() {
  var pathname = document.location.pathname;
  if (!pathname.match(/active\/admin\/spree_selling_authorities\/\d+\/edit/)) return null

  edit_id = pathname.split('/')[4];
  permittableSelect = $('#selling-authority-permittable-string');

  $.ajax({
    type: 'GET',
    url: "/active/admin/spree_selling_authorities/search_permittable.json?edit_id=" + edit_id
  }).then(function (data) {
    var option = new Option(data.text, data.id, true, true);
    permittableSelect.append(option).trigger('change');

    permittableSelect.trigger({
      type: 'select2:select',
      params: {
        data: data
      }
    });
  });
}

function retailerSelect2() {
  $('#selling-authority-retailer-id').select2({
    ajax: {
      url: "/active/admin/spree_selling_authorities/search_retailers.json",
      dataType: 'json',
      delay: 250
    },
    placeholder: 'Search for a Retailer',
    minimumInputLength: 0
  });
}
