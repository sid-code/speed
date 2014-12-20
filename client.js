(function() {
  var ws = new WebSocket("ws://localhost:8081");

  ws.onopen = function() {
    console.log("WOO");
  };

  ws.onmessage = function(msg) {
    console.log("< " + msg.data);
  }
})();
