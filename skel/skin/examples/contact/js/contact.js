$(document).ready(function() {
  // just a makeshift :-p
  // native support for various summaries (sum, avg, count, min and max) is on the way.
  var sum = 0;
  var num = 0;
  $('.rating').each(
    function(i){
      sum += parseInt($(this).text());
      num += 1;
    }
  );
  if (num > 0) $('.rating-avg').text('Average: ' + parseInt(sum * 10 / num) / 10);
});
