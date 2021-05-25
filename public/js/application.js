(function($) {
    // If a fetch error occurs, log it to the console and show it in the UI.
    function handleFetchResult(result) {
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
    }
    
    // Create a Checkout Session with the selected plan ID
    function createCheckoutSession(product_id) {
      return fetch("/checkout/session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          product_id: product_id
        })
      }).then(handleFetchResult);
    }
    
    // Handle any errors returned from Checkout
    function handleResult(result) {
        if (result.error) {
            showErrorMessage(result.error.message);
        }
    }
    
    function showErrorMessage(message) {
        var errorEl = document.getElementById("error-message")
        errorEl.textContent = message;
        errorEl.style.display = "block";
    }
    
    function initPrice(stripe) {
        return function (price) {
	    console.log('Initializing price', price);
            if (price.price_id == null) throw new Error("Price ID should not be null");
            if (price.product_id == null) throw new Error("Product ID should not be null");
            var $elem = $("#btn-" + price.product_id);

	    if ($elem.length === 0) throw new Error('Could not find button for product:' + price.product_id);

            // TODO: return price or create a Checkout class and return it's instance
            $elem.on('click', function() {
                console.log('Creating session for ', price);
                createCheckoutSession(price.product_id).then(function(data) {
		    if (data.status === 'error') {
			throw new Error(data.message);
		    }
		    else {
			stripe.redirectToCheckout({ sessionId: data.sessionId }).then(handleResult);
		    }
                });
            });
        }
    }

    if (Mentoring.state.authenticated === true) {
	fetch("/checkout/setup")
	    .then(handleFetchResult)
	    .then(function(json) {
		var publishableKey = json.pub_key;
		var stripe = Stripe(publishableKey);
		json.prices.forEach(initPrice(stripe));
	    });
    }
    else {
	$('.btn-select-product').click(function() {
	    window.location = '/login?ref=%2F';
	});
    }
    
    // Initialize unobtrusive posts
    $('[data-method=post]').each(function() {
        var $elem = $(this);
        console.log($elem);
        $elem.on('click', function() {
            // TODO: collect other data attributes to pass as data
            $.ajax({
                url: $elem.attr('href'),
                method: "POST",
		contentType: 'application/javascript',
		dataType: 'json',
		success: function(response) {
		    if (response.redirect != null) {
			window.location = response.redirect;
		    }
		}
            });
            return false;
        });
    });

}).call(window, jQuery);
