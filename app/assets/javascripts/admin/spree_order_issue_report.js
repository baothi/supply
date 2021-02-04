$(document).ready(function() {
  $('#decline-issue-action-item').click(function(e) {
    e.stopPropagation();  // prevent Rails UJS click event
    e.preventDefault();

    ActiveAdmin.modal_dialog(
      "Please tell retailer why you're declining this",
      { reason: 'textarea' },
      function(inputs) {
        var reportId = $(e.target).data('report-id');
        var token = $(e.target).data('auth-token');
        $.post(
          '/active/admin/order_issue_reports/' + reportId + '/decline',
          { reason: inputs.reason, authenticity_token: token },
          function(result) {
            window.location.reload();
          }
        );
      }
    );
  })

  $('.approve-issue-report').click(function(e) {
    e.stopPropagation();  // prevent Rails UJS click event
    e.preventDefault();

    var orderTotal = $(this).data('order-total');
    var submitUrl = $(this).data('submit-url');
    var token = $(this).data('auth-token');

    ActiveAdmin.modal_dialog(
      'How much do you want to credit retailer? Order total is ' + orderTotal,
      { amount: 'number' },
      function(inputs) {
        $.post(
          submitUrl,
          { amount: inputs.amount, authenticity_token: token },
          function(data) {
            window.location.reload();
          }
        ).fail(function() {
          window.location.reload();
        });
      }
    );
  })
})
