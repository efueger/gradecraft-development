@gradecraft.factory 'CourseBadge', ['EarnedBadge', (EarnedBadge) ->
  class CourseBadge
    constructor: (attrs={}) ->
	  	@id = attrs.id if attrs.id
	  	@name = attrs.name if attrs.name
	  	@description = attrs.description if attrs.description
	  	@point_total = attrs.point_total if attrs.point_total
	  	@icon = attrs.icon if attrs.icon
	  	@multiple = attrs.multiple if attrs.multiple

  ]
