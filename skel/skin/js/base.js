$(document).ready(function() {
  $(':input').hover(
    function(){
      $('+ span.error',this).fadeIn(150);
    },
    function(){
      if ($(this).is(':not(.focused)')) $('+ span.error',this).fadeOut(100);
    }
  );
  $(':input').focus(
    function(){
      $(this).addClass('focused');
      $('+ span.error',this).fadeIn(150);
    }
  );
  $(':input').blur(
    function(){
      $(this).removeClass('focused');
      $('+ span.error',this).fadeOut(100);
    }
  );

  $('span.error').hide().css({
    'color':              'white',
    'background':         'red',
    'opacity':            '0.5',
    'position':           'absolute',
    'margin-left':        '0',
    'margin-top':         '2px',
    'padding':            '.3em 1em .3em 1em',
    '-moz-border-radius': '.3em'
  });

  if ($('.error').length > 0) {
    $('.error:input:enabled:first').focus().select();
  }
  else {
    $(':input:enabled:first').focus().select();
  }
});
