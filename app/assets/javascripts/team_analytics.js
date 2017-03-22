// truncate function until plotlyjs handles axis label resizing
function truncateLabel(label, max) {
  return label.length > max ? label.substr(0, max-1) + '…' : label;
}

function plotLeaderboard() {
  // eslint-disable-next-line no-undef
  Plotly.newPlot('leaderboardBarChart', data, layout, {displayModeBar: false});  
}

if ($('#leaderboardBarChart').length) {
  var teamScores = JSON.parse($('#leaderboardBarChart').attr('data-scores'));
  var studentTeam = $('#leaderboardBarChart').attr('data-team');

  var xValues = [];
  var xValueLabels = [];
  var yValues = [];
  var colors = [];
  var outlineColors = [];
  var yStudentMarker;

  teamScores.forEach(function(score) {
    var xValue = score.name;
    xValueLabels.push(score.name);
    var truncatedXValue = truncateLabel(score.name, 10);
    xValues.push(truncatedXValue);

    var yValue = score.data;
    yValues.push(yValue);

    if (xValue === studentTeam) {
      yStudentMarker = yValue;
      colors.push('rgba(109, 214, 119, 0.5)');
      outlineColors.push('rgba(109, 214, 119, 1)');
    } else {
      colors.push('rgba(31, 119, 180, 0.5)');
      outlineColors.push('rgba(31, 119, 180, 1)');
    }
  });

  var tooltips = xValueLabels.map(function (label, index) {
    return label + '<br>' + yValues[index].toLocaleString();
  });

  var data = [
    {
      x: xValues,
      y: yValues,
      type: 'bar',
      text: tooltips,
      hoverinfo: 'text',
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

  var layout = {
    showlegend: false,
    height: 400,
    hovermode: 'closest',
    margin: {
      l: 80,
      r: 40,
      b: 60,
      t: 4,
      pad: 8
    },
    xaxis: {
      fixedrange: true
    },
    yaxis: {
      fixedrange: true,
      title: 'Score',
      tickprefix: '     ',
      tickformat: ',d',
      rangemode: 'nonnegative'
    }
  };

  if (studentTeam) {
      layout.annotations = [{
        x: truncateLabel(studentTeam, 10),
        y: yStudentMarker,
        xref: 'x',
        yref: 'y',
        yanchor: 'bottom',
        xanchor: 'center',
        text: 'Your Team',
        showarrow: true,
        arrowhead: 2,
        arrowsize: 1,
        arrowwidth: 2,
        ax: 0,
        ay: -20
      }]
    }
  
  plotLeaderboard();
  resizeEnd(plotLeaderboard);
}
