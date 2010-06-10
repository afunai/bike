$(document).ready(function() {
  if ($('.error').length > 0) {
    $('.error:input:enabled:first').select();
  }
  else {
    $(':input:enabled:first').select();
  }
});
