function plotPointBreakdown() {
  // eslint-disable-next-line no-undef
  Plotly.newPlot('point-breakdown-chart', pointBreakdownData, pointBreakdownLayout, {displayModeBar: false});

  // set tooltip border color on hover
  document.getElementById('point-breakdown-chart').on('plotly_hover', function(pointBreakdownData) {
    var barColor = pointBreakdownData.points[0].fullData.marker.color;
    $('.hovertext path').attr('data-color', barColor);
  });
}

var $pointBreakdownChart = $('#point-breakdown-chart');
if ($pointBreakdownChart.length) {
  var assignmentTypeTotals = JSON.parse($('#point-breakdown-chart').attr('data-pointbreakdown'));
  var scores = assignmentTypeTotals.scores;
  var xMaxValue = assignmentTypeTotals.course_total;

  var traces = [];
  var colors = [
    '#00274F',
    '#215089',
    '#2E70BE',
    '#B9D6F2',
    '#8ED0FF',
    '#490454',
    '#8F27A1',
    '#9FE88D',
    '#6DD677',
    '#25B256',
    '#D1495B',
    '#FEB130',
    '#FFCF06'
  ];

  scores.forEach(function(score, index) {
    var points = score.data;
    var name = score.name;
    var tooltip = name + '<br>' + points.toLocaleString() + ' points';
    var colorsCount = colors.length;

    var trace = {
      x: [points],
      name: name,
      orientation: 'h',
      marker: {
        color: colors[index % colorsCount],
        size: 1
      },
      type: 'bar',
      text: [tooltip],
      hoverinfo: 'text'
    };
    traces.push(trace);
  });

  var pointBreakdownData = traces;

  var pointBreakdownLayout = {
    showlegend: false,
    hovermode: 'closest',
    height: 100,
    barmode: 'stack',
    margin: {
      l: 8,
      r: 8,
      b: 40,
      t: 8,
      pad: 8
    },
    xaxis: {
      fixedrange: true,
      range: [0, xMaxValue]
    },
    yaxis: {
      autorange: true,
      showgrid: false,
      zeroline: false,
      showline: false,
      autotick: true,
      ticks: '',
      showticklabels: false,
      fixedrange: true
    }
  };

  plotPointBreakdown();
  resizeEnd(plotPointBreakdown);
}

// Filter my planner items in "due this week" module
$('#my-planner').click(function() {
  $('#my-planner').attr('aria-pressed', true).addClass("selected");
  $('#course-planner').attr('aria-pressed', false).removeClass("selected");
  $('.my-planner-list').show().attr('aria-hidden', 'false');
  $('.course-planner-list').hide().attr('aria-hidden', 'true');
});

$('#course-planner').click(function() {
  $('#course-planner').attr('aria-pressed', true).addClass("selected");
  $('#my-planner').attr('aria-pressed', false).removeClass("selected");
  $('.course-planner-list').show().attr('aria-hidden', 'false');
  $('.my-planner-list').hide().attr('aria-hidden', 'true');
});

//Find event with closest date
if($("#dashboard-timeline").length) {
  $.ajax({
    type: 'GET',
    url: 'api/timeline_events',
    dataType: 'json',
    contentType: 'application/json',
    success: function (json) {
      setInitialEventSlide(json);
    }
 });
}

function setInitialEventSlide(eventJson){
  var events = eventJson.timeline.date;
  var todaysDate = new Date();
  var startIndex = null;

  for (var i = 0; i < events.length; i++) {
    var eventEndDate = new Date(events[i].endDate);
    if (eventEndDate >= todaysDate) {
      startIndex = i;
      break;
    }
  }

  if (startIndex === null) {
    $('.slide-container').append('<div class="event-slide last-slide"><p>This class has no upcoming events!</p></div>');
    startIndex = events.length;
  }

  $('#events-loading-spinner').hide();
  initSlickSlider(startIndex);
}

// Initialize slick slider for course events
function initSlickSlider(startIndex) {
  $('.slide-container').slick({
    prevArrow: '<a class="fa fa-chevron-left previous slider-direction-button" aria-label="View previous course event"></a>',
    nextArrow: '<a class="fa fa-chevron-right next slider-direction-button" aria-label="View next course event"></a>',
    initialSlide: startIndex,
    adaptiveHeight: true,
    infinite: false
  });

  $('.slide-header').each(function () {
      var $slide = $(this).parent();
      if ($slide.attr('aria-describedby') != undefined) { // ignore extra/cloned slides
          $(this).attr('id', $slide.attr('aria-describedby'));
      }
  });
}



// Open class info card and submenu in top nav on click and hide on body click
$(document).on('click', function(event) {
  var $this = $(event.target);
  var $dropdownContent = $('.dropdown-content');

  if ($this.parent().hasClass('dropdown')) {
    var $thisDropdownContent = $this.siblings('.dropdown-content');
    $dropdownContent.not($thisDropdownContent).hide();
    $thisDropdownContent.toggle();
  } else if (!$this.closest('.dropdown').length) {
    $dropdownContent.hide();
  }
});
