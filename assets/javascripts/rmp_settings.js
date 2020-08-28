$(document).ready(function () {
  if ($('#settings_save_button').length == 1) {
    $('#settings input[type=submit]').addClass('main-form-button').prependTo('#settings_save_button');
  }

  $('a[rel=tooltip]').tooltip({placement:'right'});
});