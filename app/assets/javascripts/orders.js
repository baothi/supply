$(document).ready(function() {
  autoDiagnoseOrder();

  $("#buildProducts").modal('show');
  $(".sk-fading-circle").hide();

  $(".open-order-payment-modal").click(function () {
    $('#order-amount').text("$ " + $(this).data('amount'));
    $('#order-number').text($(this).data('order'));
    $('#order-date').text($(this).data('date'));
    $('#payment-form-order-id').val($(this).data('order'));
    $('#payment-form-order-internal-id').val($(this).data('identifier'));
  })

  $("#continue-payment-method").on("click", function(){
    // $("#payWith").show();
  });

  $('.close').on('click', function() {
      $(this).parents('.modal').modal('hide');
  });

  $(".open-variant-pairing-modal").click(function () {
    $('#line_item_identifier, #line_item_id').val($(this).data('line-item-id'))
    $('#selecting-variant-for-product').html("Selecting Variant for " + $(this).data('line-item-name'))
  });

  $(".manual-variant-display-list").on("click", function(){
    $('.show-variants').html("<div class='spinner'></div>")
    var variant_id = $(this).attr("id");
    var line_item_id = $("#line_item_identifier").val();
    $.ajax({
      type: "get",
      url: "/retailer/orders/manual_variant_finder",
      data: { variant_id:  variant_id, line_item_id: line_item_id }
    })
  })

  $('#find-order').on('click', function () {
    var myForm = $("form#find-order-form");
    if (myForm) {
      $('#find-order').attr("disabled", "disabled");
      $(myForm).submit();
    }
  });

  $('#diagnose-order').on('click', function () {
    var myForm = $("form#order-diagnosis-form");
    var order_name = $("#order-diagnosis-form #shopify_order_number").val()
    if(order_name === ''){
      return
    }
    if (myForm) {
      $('#diagnose-order').attr("disabled", "disabled");
      $(myForm).submit();
    }
  });

  $('.selectable-item').on('change', function () {
    var n = $(".selectable-item:checked").length;
    if(n === 0) {
      hideBatchAction()
    } else {
      showBatchAction();
    }
  });

  $(".order-select-tr").on("click", function(e){

        // stop the bubbling to prevent firing the row's click event
         // e.stopPropagation();
    if (e.target.type != "button") {

        // stop the bubbling to prevent firing the row's click event
        e.stopPropagation();
    }
  })

  $('.selectable-all').on('click', function () {
    if($(this).is(':checked')) {
     showBatchAction();

    } else {
     hideBatchAction()
    }
  });

   function submitDetailsForm() {
       $("#batch-action-form").submit();
    }

  // show spinner on AJAX start
  $(document).ajaxStart(function(){
    $(".sk-fading-circle").show();
  });

  // hide spinner on AJAX stop
  $(document).ajaxStop(function(){
    $(".sk-fading-circle").hide();
  });

  // $(".select-other-payment-div").on('click', function(){
  //   card = $(this).find("label").text();
  //   $("#current-pay-with-card").text(card);
  //   $('#payWith').modal('show');
  // })

  function showBatchAction(){
    $(".orders-header").hide();
    $(".orders-batch-action-header").show();
     $( '.bg-blue-grey-100' ).each(function () {
        this.style.setProperty('background-color', 'white', 'important');

    });
     var selected = $('.selectable-item:checked').size();
     order = 'Order'
     if(selected > 1) {
        order = order + 's'
     }
     $(".selected-orders-text").text(selected + " " + order + " selected")
    // var checkboxes = $('.selectable-item').size();
    // if(selected === checkboxes){
    //   $('.export-all-message').css('display', 'inline')
    //   $('.select-all-page-span').text('All ' + selected + ' orders on this page selected');
    // }
    // else{
    //   $('.export-all-message').hide();
    //   $('.select-all-page-span').text('')
    // }

  }

  function autoDiagnoseOrder(){
    var order_name = $("#order-diagnosis-form #shopify_order_number").val()
    if(order_name === ''){
      return
    }
    $("#diagnose-order" ).trigger( "click" );
  }

  function hideBatchAction(){
     $(".orders-header").show();
    $(".orders-batch-action-header").hide();
    $(".bg-blue-grey-100").css("background-color", "#f3f7f9");
    $(".selected-orders-text").text("")
    // $('#all').val('');
    // $('.select-all-orders').text('Click Here to Select All')
  }

  $(".back-to-payment").on('click', function(){
    $('#payWith').modal('show');
    $('#paymentInformation, #newPaymentMethod').modal('hide');
  })

  $("#select-other-payment").on('click', function(){
    $('#payWith').modal('hide');
  })

  $('#newPaymentMethod').on('shown.bs.modal', function (e) {
    $('.stripe-error').text('');
  $('.stripe-error').css("display", "none");
  })

  $(".back-to-payment").on('click', function(){
    $('#payWith').modal('show');
  })

  $('#refundLineItem').on('show.bs.modal', function (e) {

    var lineItemId = $(e.relatedTarget).data('id');
    var sku = $(e.relatedTarget).data('sku');
    var base_link = $(e.relatedTarget).data('baselink');
    var new_link = base_link + "?id=" + lineItemId

    $("#refund-line-item-link").attr("href", new_link)

    $(this).find(".confirm-line-item-sku").empty().append(sku);
  });

  $('#cancelLineItem').on('show.bs.modal', function (e) {

    var lineItemId = $(e.relatedTarget).data('id');
    var base_link = $(e.relatedTarget).data('baselink');
    var sku = $(e.relatedTarget).data('sku');

    var new_link = base_link + "?id=" + lineItemId

    $("#cancel-line-item-link").attr("href", new_link)

    $(this).find(".confirm-line-item-sku").empty().append(sku);
  });

  $('#per_page').on('change', function(e) {
    $("#set-per-page").submit();
 });
})
