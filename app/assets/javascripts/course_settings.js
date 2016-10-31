//Reveal settings menu on form card and disable settings menu if card feature is not enabled
$('.button-advanced-settings').on('click', function(e) {
  var $formCard = $(this).closest('.form-card');

  e.preventDefault();

  if (!$formCard.hasClass('disabled') && $formCard.find('input.has-settings-menu').is(':checked')) {
    $(this).parent().next().slideToggle('slow');
  }
});

$('.button-close').on('click',function(){
    $(this).parent().slideToggle('slow');
});

// Disable settings menu button if form card feature is not checked
function disableSettingsButton($thisInput) {
  var $thisSettingsBtn = $thisInput.closest('.form-card').find('.button-advanced-settings');
  
  if ($thisInput.is(':checked')) {
    $thisSettingsBtn.prop('disabled', false);
  } else {
    $thisSettingsBtn.prop('disabled', true);
  }  
}

$('input.has-settings-menu').change(function() {
  disableSettingsButton($(this));
});

$('input.has-settings-menu').each(function() {
  disableSettingsButton($(this));
});


// Section leaderboards and challenges are dependent on Sections feature being enabled
function formDependencies() {
  var $dependentOnSection = $('.dependent-on-section');
  var $card = $dependentOnSection.parent().parent();
  var $sectionsCheckbox = $('input[id="course_has_teams"]');

  if($sectionsCheckbox.is(":checked")) {
    $dependentOnSection.prop("disabled", false);
    $card.removeClass("disabled");
  } else {
    $dependentOnSection.prop("disabled", true);
    $card.addClass("disabled");
  }
}

$('input[id="course_has_teams"]').change(formDependencies);
formDependencies();

// Remember the last active tab in order to redirect to same tab after save
$(function() {
   $( ".course-settings-tabs" ).tabs({
     activate:function(event,ui){
       localStorage.setItem("lastTab",ui.newTab.index() );
     },
     active: localStorage.getItem("lastTab") || 0
   });
});
