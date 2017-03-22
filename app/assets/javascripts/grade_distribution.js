function plotGradeDistribution() {
  // eslint-disable-next-line no-undef
  Plotly.newPlot('grade_distro', gradeDistroData, gradeDistroLayout, {displayModeBar: false});
}

var $gradeDistro = $('#grade_distro');
if ($gradeDistro.length) {
  var dataSet = JSON.parse($gradeDistro.attr('data-scores'));
  var scores = dataSet.scores;
  var userScore = dataSet.user_score[0];

  var gradeDistroData = [{
    x: scores,
    type: 'box'
  }];

  var gradeDistroLayout = {
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

  if ($gradeDistro.hasClass('student-distro')) {
    gradeDistroLayout.height = 130;
    if (userScore) {
      gradeDistroLayout.annotations = [{
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
  plotGradeDistribution();
  resizeEnd(plotGradeDistribution);
}
