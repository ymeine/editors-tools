/**
 * This creates the builder object, used by the parser to create nodes of the graph, from the building functions.
 */

require! {
	_: lodash

	string

	'./building-functions'
}


# Pre-processing ---------------------------------------------------------------

/**
 * Append suffixes to building functions, from their categories.
 *
 * Building functions follow a naming convention to categorize them: statements, expressions, etc.
 *
 * To avoid boilerplate in function naming, these function can be defined in categories, which are container objects whose name match the naming conventions mentionned above.
 *
 * The name of the categories are appended as suffix to the name of the functions they contain. Moreover, categories could be nested, but the same principle applies.
 *
 * Example:
 * {
 *   Statement:
 *     empty: -> ...
 * }
 * will give at top-level:
 * {
 *   emptyStatement: -> ...
 * }
 */
functions = {}
applyCategories = (container, suffix = '') -> for key, value of container
	key = "#key#suffix"
	switch typeof! value
	| 'Function' => functions[key] = value
	| 'Object' => applyCategories value, key
applyCategories buildingFunctions

/**
 * Returns a node:
 * 	{
 * 		type
 * 		key # The key under which its unique parent refers to
 * 		source: {location, value}
 * 		links: {
 * 			children: {list, index}
 * 			parent
 * 			previous
 * 			next
 * 		}
 * 	}
 */
module.exports = {[functionName, let functionName, fn => ->
	# We extract from the actual arguments the arguments which have been explicitely defined in the building functions (called below)
	# The implicit args are either common to all building functions (source, position, things not related to semantics), or are specific to some functions.
	implicitArgsNumber = switch functionName.toLowerCase!
	| 'literal' => 2
	| _ => 1
	explicitArgs = (_.toArray &)[to fn.length - 1 + implicitArgsNumber]

	# We create a new node with some properties and get the ones from the parser
	node =
		type: string.capitalize functionName
		source: {}
		links: {}
	fn.apply node, explicitArgs



	# Source (value) -----------------------------------------------------------
	# For 'Literal' nodes only!!

	# Raw value of a literal node
	# XXX Once again, I don't understand the stuff with the explicitArgs array slicing...
	if implicitArgsNumber > 1 => node.source.value = explicitArgs[* - implicitArgsNumber + 1]

	# Source (location) --------------------------------------------------------

	node.source.location = explicitArgs[* - implicitArgsNumber]{start, end, range}



	# Links --------------------------------------------------------------------

	if node.links.children?
		# Children list --------------------------------------------------------
		# Computed for current node

		children = that
		unorderedList = _.reject (_.flatten _.toArray children.index), -> not it?

		groupedByLine = unorderedList `_.groupBy` (.source.location.start.line)
		children.list = _.flatten [groupedByLine[..] `_.sortBy` (.source.location.start.column) for (_.keys groupedByLine) `_.sortBy` -> it]

		# Key ------------------------------------------------------------------
		# Computed for each child

		for key, child of children.index => child <<< {key}

		# Links (for children) -------------------------------------------------
		# Computed for each child

		previous = void
		for current in children.list
			# Parent -----------------------------------------------------------

			current.links.parent = node

			# Siblings (next & previous) ---------------------------------------

			if previous?
				# Previous -----------------------------------------------------
				# Computed for current child

				current.links.previous = that

				# Next ---------------------------------------------------------
				# Computed for previous child

				that.links.next = current

			previous = current

	return node

] for functionName, fn of functions}