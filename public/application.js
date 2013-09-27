$(document).ready(function() {

  $(document).on("click", "form#hit_button input", function() {
    // alert("You chose to hit");

    $.ajax({
      type: 'POST',
      url: '/blackjack/player_hit'
    }).done(function(msg) {
      $("div#game").replaceWith(msg);
    });

    return false;
  });

  $(document).on("click", "form#stay_button input", function() {
    // alert("You chose to stay");

    $.ajax({
      type: 'POST',
      url: '/blackjack/player_stay'
    }).done(function(msg) {
      $("div#game").replaceWith(msg);
    });

    return false;
  });

  $(document).on("click", "form#dealer_hit input", function() {
    // alert("Dealing card to dealer...");

    $.ajax({
      type: 'POST',
      url: '/blackjack/dealer_hit'
    }).done(function(msg) {
      $("div#game").replaceWith(msg);
    });

    return false;
  });

});