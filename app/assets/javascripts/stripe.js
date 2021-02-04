$(document).ready(function() {

  var stripeKey = $('meta[name="stripe-public-key"]').attr('content');
  var stripe = Stripe(stripeKey);
  var elements = stripe.elements();

  var card = elements.create('card', {
    hidePostalCode: true,
    style: {
      base: {
        iconColor: '#F99A52',
        color: '#32315E',
        lineHeight: '48px',
        fontWeight: 400,
        fontFamily: '"Helvetica Neue", "Helvetica", sans-serif',
        fontSize: '15px',

        '::placeholder': {
          color: '#CFD7DF',
        }
      },
    }
  });
  card.mount('#card-element');

  function setOutcome(result) {
    // successElement.classList.remove('visible');
     $('.stripe-error').css("display", "none");

    if (result.token) {
      // Use the token to create a charge or a customer
      // https://stripe.com/docs/charges
      $('.stripe-success').css("display", "block");
      $('.token').val(result.token.id)
      $("#stripe-form").trigger('submit.rails');
      card.clear();

    } else if (result.error) {
      $('.stripe-error').text(result.error.message);
      $('.stripe-error').css("display", "block");
    }
  }

  card.on('change', function(event) {
    setOutcome(event);
  });

  $("#stripe-form").on('submit', function(e) {
    e.preventDefault();
    // var form = $("#stripe-form");
    var extraDetails = {
      name: $('form input[name=cardholder-name]').val(),
      address_zip: $('form input[name=address-zip]').val()
    };
    stripe.createToken(card, extraDetails).then(setOutcome);
  });
})
