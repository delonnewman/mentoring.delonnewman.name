// If a fetch error occurs, log it to the console and show it in the UI.
var handleFetchResult = function(result) {
  if (!result.ok) {
    return result.json().then(function(json) {
      if (json.error && json.error.message) {
        throw new Error(result.url + ' ' + result.status + ' ' + json.error.message);
      }
    }).catch(function(err) {
      showErrorMessage(err);
      throw err;
    });
  }
  return result.json();
};

// Create a Checkout Session with the selected plan ID
var createCheckoutSession = function(priceId) {
  return fetch("/checkout/session", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      priceId: priceId
    })
  }).then(handleFetchResult);
};

// Handle any errors returned from Checkout
var handleResult = function(result) {
  if (result.error) {
    showErrorMessage(result.error.message);
  }
};

var showErrorMessage = function(message) {
  var errorEl = document.getElementById("error-message")
  errorEl.textContent = message;
  errorEl.style.display = "block";
};

function initPrice(stripe) {
    return function (price) {
        if (price.price_id == null) throw new Error("Price ID should not be null");
        var elemId = "btn-" + price.price_id;
        console.log('initializing ', elemId, ' with ', price);

        // TODO: return price or create a Checkout class and return it's instance
        return document
          .getElementById(elemId)
          .addEventListener("click", function(evt) {
              console.log('Creating session for ', price);
              createCheckoutSession(price.price_id).then(function(data) {
                  stripe
                    .redirectToCheckout({ sessionId: data.sessionId })
                    .then(handleResult);
            });
          });
    }
}

/* Get your Stripe publishable key to initialize Stripe.js */
fetch("/checkout/setup")
  .then(handleFetchResult)
  .then(function(json) {
    var publishableKey = json.pub_key;
    var stripe = Stripe(publishableKey);
    json.prices.forEach(initPrice(stripe));
  });

$('[data-method=post]').each(function() {
    var $elem = $(this);
    $elem.on('click', function() {
        // TODO: collect other data attributes to pass as data
        $.ajax({
            url: $elem.attr('href'),
            dataType: 'script',
            type: "POST"
        });
        return false;
    });
});
