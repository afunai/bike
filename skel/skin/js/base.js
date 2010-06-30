$(document).ready(function() {
  $('span.error').hover(
    function(){
      $('.error_message', this).fadeIn(150);
    },
    function(){
      if ($(this).is(':not(.focused)')) $('.error_message', this).fadeOut(50);
    }
  );

  $(':input', $('span.error')).focus(
    function(){
      var d = $(this).closest('span.error');
      d.addClass('focused');
      $('.error_message', d).fadeIn(150);
    }
  ).blur(
    function(){
      var d = $(this).closest('span.error');
      d.removeClass('focused');
      $('.error_message', d).fadeOut(50);
    }
  ).change(
    function(){
      var d = $(this).closest('span.error');
      d.removeClass('error');
      d.removeClass('focused');
      $('.error_message', d).hide();
    }
  );

  $('.error_message').hide().css({
    'color':                 'white',
    'background':            'red',
    'opacity':               '0.9',
    'position':              'absolute',
    'margin-left':           '0',
    'margin-top':            '2px',
    'padding':               '.3em 1em .3em 1em',
    '-moz-border-radius':    '.3em',
    '-webkit-border-radius': '.3em'
  });

  if ($('span.error').length > 0) {
    $(':input:enabled:first', $('span.error:first')).focus().select();
  }
  else {
    $(':input:enabled:first').focus().select();
  }
});
