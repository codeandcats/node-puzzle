fs = require 'fs'

class IPRange
	constructor: (@from, @to, @country) ->
		@left = @right = null

exports.ip2long = (ip) ->
	ip = ip.split '.', 4
	+ip[0] * 16777216 + +ip[1] * 65536 + +ip[2] * 256 + +ip[3]

root = null

# Adds an IP Address Range to our custom binary tree
addRange = (from, to, country) ->
	# Guards
	throw new Error "From not defined" unless from?
	throw new Error "To not defined" unless to?
	throw new Error "Country not defined" unless country?
	
	if not root
		return root = new IPRange from, to, country
	else
		parent = root
		
		while true
			if to < parent.from
				if parent.left
					parent = parent.left
				else
					return parent.left = new IPRange from, to, country
			else if from > parent.to
				if parent.right
					parent = parent.right
				else
					return parent.right = new IPRange from, to, country
			else
				throw new Error "IP Range overlaps with existing country: #{parent.country}"

# Loads country data
exports.load = ->
	# Column Indices
	GEO_FIELD_MIN = 0
	GEO_FIELD_MAX = 1
	GEO_FIELD_COUNTRY = 3
	
	# Load IP Address ranges from data file
	data = fs.readFileSync "#{__dirname}/../data/geo.txt", 'utf8'
	data = data.toString().split '\n'
	
	tempList = []
	for line in data when line
		line = line.split '\t'
		tempList.push [+line[GEO_FIELD_MIN], +line[GEO_FIELD_MAX], line[GEO_FIELD_COUNTRY]]
	
	# Shuffle the temp list for a quick and dirty balanced tree
	tempList = tempList.sort -> Math.random() - .5
	
	# Add all the ranges in the list to the tree
	addRange row[0], row[1], row[2] for row in tempList

# Looks up country code for IP Address. Returns null if not matched, -1 if no ip specified
exports.lookup = (ip) ->
	return -1 unless ip
	
	ip = this.ip2long ip
	
	node = root
	found = false
	while (node and not found)
		if ip < node.from
			node = node.left
		else if ip > node.to
			node = node.right
		else
			found = true
	node
