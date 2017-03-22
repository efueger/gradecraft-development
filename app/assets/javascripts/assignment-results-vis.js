function plotAssignmentDistro() {
  // eslint-disable-next-line no-undef
  Plotly.newPlot('grades_per_assign', assignmentDistroData, assignmentDistroLayout, {displayModeBar: false});
}

var $assignmentDistro = $('#grades_per_assign');
if ($assignmentDistro.length) {
  var dataSet = JSON.parse($assignmentDistro.attr('data-scores'));
  var scores = dataSet.scores;
  var userScore = dataSet.user_score;

  var assignmentDistroData = [{
    x: scores,
    type: 'box'
  }];

  var assignmentDistroLayout = {
    showlegend: false,
    height: 100,
    hovermode: !1,
    margin: {
      l: 8,
      r: 8,
      b: 40,
      t: 4,
      pad: 8
    },
    xaxis: {
      fixedrange: true
    },
    yaxis: {
      fixedrange: true,
      showticklabels: false
    },
    marker: {
      size: 4
    }
  };

  if ($assignmentDistro.hasClass('student-distro')) {
    assignmentDistroLayout.height = 130;
    if (userScore) {
      assignmentDistroLayout.annotations = [{
        x: userScore,
        y: 0,
        xref: 'x',
        yref: 'y',
        text: 'Your Score:<br>' + userScore.toLocaleString(),
        showarrow: true,
        arrowhead: 2,
        arrowsize: 1,
        arrowwidth: 2,
        ax: 0,
        ay: -40
      }]
    }
  }
  plotAssignmentDistro();
  resizeEnd(plotAssignmentDistro);
}

function plotNumberComplete() {
  // eslint-disable-next-line no-undef
  Plotly.newPlot('numberComplete', participationData, pieLayout, {displayModeBar: false});
}

var $numberComplete = $('#numberComplete');
if ($numberComplete.length) {
  var percentParticipated = JSON.parse($numberComplete.attr('data-percent'));
  var percentNotParticipated = 100 - percentParticipated;
  var participationData = [{
    values: [percentParticipated, percentNotParticipated],
    labels: ['Students Participated, Not Participated'],
    type: 'pie',
    hole: .6,
    text: [percentParticipated + '%', null],
    textinfo: 'text',
    marker: {
      colors: ['rgba(31, 119, 180, 0.5)', 'rgba(222,227,229, 0.5)' ],
      line: {
        color: 'rgba(31, 119, 180, 1)',
        width: 2
      }
    }
  }];

  var pieLayout = {
    showlegend: false,
    height: 220,
    width: 220,
    hovermode: !1,
    margin: {
      l: 8,
      r: 8,
      b: 40,
      t: 4,
      pad: 8
    },
    annotations: [{
      font: {
        size: 16
      },
      showarrow: false,
      text: 'Students<br> Participated',
      x: 0.5,
      y: 0.5
    }]
  };
  plotNumberComplete();
  resizeEnd(plotNumberComplete);
}

function plotAssignmentBarChart() {
  // eslint-disable-next-line no-undef
  Plotly.newPlot('levels_per_assignment', assignmentBarChartData, assignmentBarChartLayout, {displayModeBar: false});
}

if ($('#levels_per_assignment').length) {
  var assignmentGrades = JSON.parse($('#levels_per_assignment').attr('data-levels'));
  var studentGrade = JSON.parse($('#levels_per_assignment').attr('data-scores')).user_score;
  var grades = assignmentGrades.scores;
  
  var xValues = [];
  var yValues = [];
  var colors = [];
  var outlineColors = [];
  var yStudentMarker;
  
  grades.forEach(function(grade) {
    var xValue = grade.name;
    xValues.push(xValue);
    
    var yValue = grade.data;
    yValues.push(yValue);
    
    if (xValue === studentGrade) {
      yStudentMarker = yValue;
      colors.push('rgba(109, 214, 119, 0.5)');
      outlineColors.push('rgba(109, 214, 119, 1)');
    } else {
      colors.push('rgba(31, 119, 180, 0.5)');
      outlineColors.push('rgba(31, 119, 180, 1)');
    }
  });
  
  var assignmentBarChartData = [
    {
      x: xValues,
      y: yValues,
      type: 'bar',
      marker: {
        size: 4,
        color: colors,
        line: {
          color: outlineColors,
          width: 2
        }
      }
    }
  ];

  var assignmentBarChartLayout = {
    showlegend: false,
    hovermode: !1,
    height: 240,
    margin: {
      l: 50,
      r: 20,
      b: 60,
      t: 4,
      pad: 8
    },
    xaxis: {
      fixedrange: true,
      title: 'Score'
    },
    yaxis: {
      fixedrange: true,
      title: '# of Students',
      tickformat: ',d'
    }
  };

  if ($('#levels_per_assignment').hasClass('student-distro')) {
      assignmentBarChartLayout.height = 230;
      if (studentGrade) {
        assignmentBarChartLayout.annotations = [{
          x: studentGrade,
          y: yStudentMarker,
          xref: 'x',
          yref: 'y',
          yanchor: 'bottom',
          xanchor: 'center',
          text: 'Your Score',
          showarrow: true,
          arrowhead: 2,
          arrowsize: 1,
          arrowwidth: 2,
          ax: 0,
          ay: -20
        }]
      }
    }
  plotAssignmentBarChart();
  resizeEnd(plotAssignmentBarChart);
}
