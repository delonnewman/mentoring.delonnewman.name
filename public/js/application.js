(function ($) {
    // If a fetch error occurs, log it to the console and show it in the UI.
    function handleFetchResult(result) {
        if (!result.ok) {
            return result
                .json()
                .then(function (json) {
                    if (json.error && json.error.message) {
                        throw new Error(result.url + " " + result.status + " " + json.error.message);
                    }
                })
                .catch(function (err) {
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
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                product_id: product_id,
            }),
        }).then(handleFetchResult);
    }

    // Handle any errors returned from Checkout
    function handleResult(result) {
        if (result.error) {
            showErrorMessage(result.error.message);
        }
    }

    function showErrorMessage(message) {
        var errorEl = document.getElementById("error-message");
        errorEl.textContent = message;
        errorEl.style.display = "block";
    }

    function initPrice(stripe) {
        return function (price) {
            if (price.price_id == null) throw new Error("Price ID should not be null");
            if (price.product_id == null) throw new Error("Product ID should not be null");

            var $elem = $("#btn-" + price.product_id);

            if ($elem.length === 0)
                throw new Error("Could not find button for product:" + price.product_id);

            // TODO: return price or create a Checkout class and return it's instance
            $elem.on("click", function () {
                console.log("Creating session for ", price);
                createCheckoutSession(price.product_id).then(function (data) {
                    if (data.status === "error") {
                        throw new Error(data.message);
                    } else {
                        stripe.redirectToCheckout({ sessionId: data.sessionId }).then(handleResult);
                    }
                });
            });
        };
    }

    if (Mentoring.state.authenticated === true) {
        fetch("/checkout/setup")
            .then(handleFetchResult)
            .then(function (json) {
                var publishableKey = json.pub_key;
                var stripe = Stripe(publishableKey);
                json.prices.forEach(initPrice(stripe));
            });
    } else {
        $(".btn-select-product").click(function () {
            window.location = "/login?ref=%2F";
        });
    }

    // Initialize unobtrusive posts
    $("[data-method=post]").each(function () {
        var $elem = $(this);
        console.log($elem);
        $elem.on("click", function () {
            // TODO: collect other data attributes to pass as data
            $.ajax({
                url: $elem.attr("href"),
                method: "POST",
                contentType: "application/javascript",
                dataType: "json",
                success: function (response) {
                    if (response.redirect != null) {
                        window.location = response.redirect;
                    }
                },
            });
            return false;
        });
    });

    function str() {
        return Array.prototype.slice.call(arguments).join("");
    }

    function padZeros(n, nDigits) {
        var digits = nDigits || 2;
        var nStr = n.toString();
        var m = Math.pow(10, digits - 1);
        if (n >= m) return nStr;
        else {
            var nZeros = digits - nStr.length;
            var buffer = [];
            for (var i = 0; i < nZeros; i++) buffer.push("0");
            buffer.push(nStr);
            return buffer.join("");
        }
    }

    function inDayLightSavings() {
        var d = new Date();

        return (
            (d.getMonth() >= 2 || (d.getMonth() === 2 && d.getDate() >= 14)) &&
                (d.getMonth() < 10 || (d.getMonth() === 10 && d.getDate() < 7))
        );
    }

    const OFFSET_FROM_GMT = inDayLightSavings() ? 360 : 420; // TODO: workout for daylight savings

    function atHour(hour, offset) {
        var d = new Date();
        d = new Date(d.getFullYear(), d.getMonth(), d.getDate(), hour);

        if (offset !== OFFSET_FROM_GMT) {
            var diff = (OFFSET_FROM_GMT - offset) / 60;
            d.setUTCHours(d.getUTCHours() + diff);
        }

        return d;
    }

    function atOffset(offset) {
        var t = new Date();
        return new Date(Date.UTC(t.getFullYear(), t.getMonth(), t.getDate(), t.getHours(), t.getMinutes()) + (offset * 60 * 60 * 1000));
    }

    const WEEKDAYS_LIST = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
    ];

    function weekday(t) {
        return WEEKDAYS_LIST[t.getDay()];
    }

    function fmtTime(t) {
        var hours = t.getHours();
        var minutes = padZeros(t.getMinutes(), 2);
        var ampm = hours >= 12 ? "PM" : "AM";
        var h = hours == 24 ? 12 : hours > 12 ? hours % 12 : hours;

        if (minutes === "00") {
            return str(h, " ", ampm);
        }

        return str(h, ":", minutes, " ", ampm);
    }

    $("input.mentor-availability").each(function () {
        var $elem = $(this);
        var offset = new Date().getTimezoneOffset();

        var times = JSON.parse($elem.val())
            .map((t) => {
                var start = fmtTime(atHour(t.start, offset));
                var end = fmtTime(atHour(t.end, offset));
                return str("<div>", t.day, " ", start, " - ", end, "</div>");
            })
            .join("\n");

        console.log(times);

        $elem.parent().append(times);
    });

    function setCurrentTime($elem, offset) {
        return () => {
            var d = atOffset(offset);
            $elem.text(weekday(d) + " " + fmtTime(d));
        };
    }

    $("#mentor-current-time").each(function () {
        var $elem = $(this);
        var offset = parseInt($elem.find(".offset").text());
        var setTime = setCurrentTime($elem, offset);

        setTime();
        setInterval(setTime, 30000); // update time every 30 seconds
    });
}.call(window, jQuery));
