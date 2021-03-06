// run checkDropdown when any unlock conditions select changes
$(document).on('change', '.conditions .assignment-or-badge select', function () {
  checkDropdown(this);
});

// run checkDropdown on page load to make previously selected conditions are correct
$('.conditions .assignment-or-badge select').each(function (index, element) {
  checkDropdown(element);
});

function checkDropdown(select) {
  var $conditions = $(select).closest('.conditions');
  var $unlockConditionsLists = $conditions.find('.unlock-conditions-list');
  var selectedList = $(select).find('option:selected').text();
  var selectedListId = '#' + selectedList.toLowerCase().replace(/\s/g, '-') + 's-list';
  var $thisSelectedList = $conditions.find(selectedListId);

  //hide and disable all inputs in all conditions lists
  $unlockConditionsLists.hide();
  $unlockConditionsLists.find('select, input').attr('disabled', true);

  //show the selected list and remove disabled attribute from inputs
  $($thisSelectedList).show();
  $($thisSelectedList).find('select, input').attr('disabled', false);
}

//Show and hide conditional form items (used on assignment and badge edit)
function showConditionalOptions($thisInput) {
  var $thisConditionalOptionsList = $thisInput.closest('.form-item-with-options').next('.conditional-options');
  
  if ($thisInput.is(':checked')) {
    $thisConditionalOptionsList.show();
  } else {
    $thisConditionalOptionsList.hide();
  }
}

$('input.has-conditional-options').change(function() {
  showConditionalOptions($(this));
});

$('input.has-conditional-options').each(function() {
  showConditionalOptions($(this));
});


// add and delete buttons for unlock conditions
var $form = $('form');
$form.on('click', '.remove-unlock-condition', function(event) {
  event.preventDefault();
  removeUnlockCondition($(this));
  showVisibilityOptions();
});

$form.on('click', '.add-unlock-condition', function(event) {
  event.preventDefault();
  addUnlockCondition();
  showVisibilityOptions();
});

function removeUnlockCondition($link) {
  $link.prev('input.destroy').val(true);
  $link.closest('fieldset.unlock-condition').hide();
}

function addUnlockCondition() {
  var $wrapper = $('.unlock-conditions');
  var template = $('#unlock-condition-template').html().replace(/child_index/g, $wrapper.children('.unlock-condition').length);
  $wrapper.append(template);
}
// show visibility form items only if there are unlock requirements
function showVisibilityOptions() {
  if ($('fieldset.unlock-condition:visible').length) {
    $('.unlock-visibility-settings').show();
  } else {
    $('.unlock-visibility-settings').hide();
  }
}
showVisibilityOptions();

// for student rubric feedback tab panels
function showSelectedTab($tab) {
  var tabPanelId = '#' + $tab.attr('aria-controls');
  var $tabPanel = $(tabPanelId);

    // remove selected class from all tabs and assoc. tab panel other than clicked
    $tab.siblings().removeClass('selected').attr('aria-selected', 'false').attr('tabindex', '-1');
    $tabPanel.siblings().removeClass('selected').attr('aria-hidden', 'true');
    // add selected class on clicked tab and associated tab panel
    $tab.addClass('selected').attr('aria-selected', 'true').attr('tabindex', '0');
    $tabPanel.addClass('selected').attr('aria-hidden', 'false');
}

$('ul.level-tabs li').click(function() {
  showSelectedTab($(this));
});

$('ul.level-tabs li').keydown(function(e) {
  var $tab = $(this);
  var $selectedTab = null;
  var $firstTab = $tab.parent().children().first();
  var $lastTab = $tab.parent().children().last();

  if (e.which === 37) {
    if ($tab.is($firstTab)) {
      $selectedTab = $lastTab;
    } else {
      $selectedTab = $tab.prev();
    }
  } else if (e.which === 39) {
    if ($tab.is($lastTab)) {
      $selectedTab = $firstTab;
    } else {
      $selectedTab = $tab.next();
    }
  }
  
  $selectedTab.focus();
  showSelectedTab($selectedTab);
});

// toggle class analytics on rubric feedback
$('#class-analytics-toggle').change(function(){
  if ($(this).prop("checked")) {
    $('.graded-students').show();
  } else {
    $('.graded-students').hide();
  }
});

// If screen is at mobile size, initialize slider for rubric feedback and destroy it when screen size is larger than mobile
function rubricScreenSize() {
  var $tabPanelContainer = $('.tab-panel-container');
  // rather than testing window size which varies in browser, using MQ to hide level tabs on mobile
  if ($('.level-tabs').css('display') === 'none') {
    // Initialize slick slider on mobile for graded rubrics if not already initialized
    if (!$tabPanelContainer.hasClass('slick-initialized')) {
      $tabPanelContainer.each(function() {
        var $thisSlider = $(this);

        $thisSlider.slick({
          prevArrow: '<a class="fa fa-caret-left previous rubric-slider-button"></a>',
          nextArrow: '<a class="fa fa-caret-right next rubric-slider-button"></a>',
          initialSlide: $thisSlider.data("start-index"),
          adaptiveHeight: true,
          infinite: false
        });
      });
    }
  } else {
    if ($tabPanelContainer.hasClass('slick-initialized')) {
      $tabPanelContainer.slick("unslick");
    }
  }
}
rubricScreenSize();
$(window).resize(rubricScreenSize);
