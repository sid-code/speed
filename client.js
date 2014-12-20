$(function() {
  var ws = new WebSocket("ws://localhost:8081");

  ws.onopen = function() {
    var oldSend = this.send;
    this.send = function(mtype, message, channel) {
      if (!channel) channel = "";

      oldSend.call(this, [channel, mtype, message].join('|'));
    }

    $(".search").click(function() {
      ws.send("search")
    });

    $(".start").click(function() {
      ws.send("start")
      $(this).hide();
    });
  };

  ws.onmessage = function(msg) {
    console.log("< " + msg.data);
    var parts = msg.data.split('|');
    var channel = parts[0];
    var mtype = parts[1];
    var rest = parts.slice(2);

    switch (mtype) {
      case 'newgame':
        game.newGame(); break;
      case 'start':
        game.start(); break;
      case 'update':
        game.updateView(JSON.parse(rest[0])); break;
    }
  };

  ws.onclose = function(msg) {
    console.log("Connection closed");
  };

  ws.onerror = function(err) {};

  $(".start").hide();
  var game = {
    newGame: function() {
      $(".gameview").show();
    }
  };
});
