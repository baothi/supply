App.job_notifications = App.cable.subscriptions.create("JobNotificationsChannel", {
  connected: function() {
    // Called when the subscription is ready for use on the server
  },

  disconnected: function() {
    // Called when the subscription has been terminated by the server
  },

  received: function(data) {
    switch(data.kind){
      case 'manual_order_finder':
        displayOrderImportForm(data)
        break;
      case 'manual_order_import':
        displayOrderLink(data);
        break;
      case 'order_diagnosis':
        displayReport(data);
        break;
      default:
        
    }
  }
});

function displayOrderImportForm(data){
$('#find-order').attr("enabled", "enabled");
  $('#find-order').removeAttr("disabled");
  $('#manual-order-import-div').html(data.content);
  $(".open-variant-pairing-modal").click(function () {
    $('#line_item_identifier, #line_item_id').val($(this).data('line-item-id'))
    $('#selecting-variant-for-product').html("Selecting Variant for " + $(this).data('line-item-name'))
  });
}

function displayOrderLink(data){
  $('#manual-order-import-div').html(data.content);
}

function displayReport(data){
  $('#diagnose-order').attr("enabled", "enabled");
  $('#diagnose-order').removeAttr("disabled");
  $('#order-diagnosis-report-div').html(data.content);
}

