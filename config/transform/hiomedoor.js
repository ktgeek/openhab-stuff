(function(i) {
  var parsed = JSON.parse(i);

  return parsed.val === "closed" ? "CLOSED" : "OPEN";
})(input);
