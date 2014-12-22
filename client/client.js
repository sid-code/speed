$(function() {

  // var host = location.hash.slice(1) || "localhost";

  var ws = new WebSocket("ws://"+location.host+":8081");
  var game;

  ws.onopen = function() {
    var oldSend = this.send;
    this.send = function(mtype, message, channel) {
      if (!channel) channel = "";

      oldSend.call(this, [channel, mtype, message].join('|'));
    }

    $(".search").click(function() {
      $(".searchmsg").show();
      ws.send("search", $(".searchnum").val());
    });

    $(".name").click(function() {
      $(this).hide();
      $(".nameinput").show();
      $(".namefield").val($(this).text()).focus();
    });

    $(".namebutton").click(function() {
      var name = $(".namefield").val();
      localStorage.setItem("setname", name);
      ws.send("rename", name);
    });

    var name = localStorage.getItem("setname");
    if (name) {
      ws.send("rename", name);
    }
  };

  ws.onmessage = function(msg) {
    console.log("< " + msg.data);
    var parts = msg.data.split('|');
    var channel = parts[0];
    var mtype = parts[1];
    var rest = parts.slice(2);

    switch (mtype) {
      case 'name':
        updateName(rest[0]); break;
      case 'nameerror':
        nameError(rest[0]); break;
      case 'newgame':
        $(".nongameview").hide();
        game = new Game(channel);
        game.show();
        break;
      case 'start':
        game.start();
        break;
      case 'update':
        game.updateView(
          rest[0].split(",").map(cardFromString), 
          rest[1], 
          rest[2].split(",").map(cardFromString),
          rest[3].split(",")
        );
        break;
      case 'stuck':
        game.showFlip(); break;
      case 'flip':
        game.hideWait(); break;
      case 'win':
        game.winner(rest[0]); break;
    }
  };

  ws.onclose = function(msg) {
    console.log("Connection closed");
  };

  ws.onerror = function(err) {};


  var Game = function(id) {
    this.id = id;
    this.makeView();
  };

  Game.prototype.makeView = function() {
    var $view = $(".generic-gameview").clone().toggleClass("generic-gameview");

    var _this = this;
    $view.find(".reset").click(resetView).hide();
    $view.find(".start").click(function() {
      ws.send("start", '', _this.id);
      $(this).hide();
      $(".waiting").show();
    });

    $view.find(".flip").click(function() {
      ws.send("flip", '', _this.id);
      $(this).hide();
      $(".waiting").show();
    }).hide();

    this.$view = $view;
    this.hideWait();
  };

  Game.prototype.show = function() {
    this.$view.show().appendTo(document.body);
  };

  Game.prototype.hideWait = function() {
    this.$view.find(".waiting").hide();
  };

  Game.prototype.start = function() {
    this.hideWait();
  };

  Game.prototype.winner = function(who) {
    var $winner = this.$view.find(".winner");
    var $reset = this.$view.find(".reset");
    $winner.show();
    if (who === $(".name").text()) {
      $winner.text("You won!");
    } else {    
      $winner.text(who + " won. Better luck next time.");
    }

    $reset.show();
  };

  Game.prototype.showFlip = function() {
    this.$view.find(".flip").show();
  };

  Game.prototype.updateView = function(hand, reserveSize, piles, players) {
    var reserveText = "You have " + reserveSize + 
      (reserveSize === 1 ? " card" : " cards") + " in reserve.";

    this.$view.find(".reserve").text(reserveText);

    this.$view.find(".players").text("Players: " + players.join(" - "));
    
    var $hl = this.$view.find(".hand").html("");
    var $pl = this.$view.find(".piles").html("");
    hand.forEach(function($card, index) {
      $card.toggleClass('card')
        .attr("draggable", true)
        .data("index", index).on("dragstart", function(e) {
        e.originalEvent.dataTransfer.setData("index", $(this).data("index"));
      });

      $hl.append($card);
    });

    piles.forEach(function($card, index) {
      $card.toggleClass("card")
        .data("index", index).on("dragover", function() {
        return false;
      }).on('dragenter', function() {
        return false;
      }).on('drop', function(e) {
        var droppedIndex = parseInt(e.originalEvent.dataTransfer.getData("index"));
        var thisIndex = parseInt($(this).data("index"));

        if (!isNaN(droppedIndex)) {
          ws.send("play", [droppedIndex, thisIndex].join("|"), game.id);
        }
        return false;
      });

      $pl.append($card);
    });
  };


  resetView();

  $(".nameerror").click(function() {
    $(".nameerror").hide();
  });

  $(".namefield").keydown(function(e) {
    if (e.which == 27) {
      updateName();
    } else if (e.which == 13) {
      $(".namebutton").click();
    }
  }).blur(function() {
    updateName();
  });

});

function updateName(name) {
  $(".name").show();
  if (name != null) {
    $(".name").text(name);
  }

  $(".nameinput").hide();
}

function nameError(err) {
  $(".nameerror").text("Error: " + err + " (click to hide)");
}

function resetView() {
  $(".nongameview").show();
  $(".searchmsg").hide();
  $(".gameview:not(.generic-gameview)").detach();
  $(".nameinput").hide();
}


function cardFromString(str) {
  var parts = str.split(':');
  var rank = parseInt(parts[0]);
  var suit = parts[1];
  rank = {11: 'j', 12: 'q', 13: 'k'}[rank] || rank;

  var src;
  if (rank == 0) {
    src = "./card-images/b1fv.png";
  } else {
    src = "./card-images/" + suit[0].toLowerCase() + rank + ".png";
  }

  return $("<img>").attr("src", src);
  
}
