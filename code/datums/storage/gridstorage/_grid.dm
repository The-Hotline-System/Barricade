/**
 * Grid Storage Subtype
 *
 * A specialized storage datum that implements grid-based inventory (Resident Evil 4-style).
 * Items occupy multiple cells based on their dimensions and can be positioned via drag-and-drop.
 * This is a clean refactor that separates grid-specific logic from the base storage system.
 */
/datum/storage/grid
	// Grid dimensions
	/// Size of each grid cell in pixels
	var/grid_box_size = 32
	/// Number of columns in the grid
	var/grid_columns = 3
	/// Number of rows in the grid
	var/grid_rows = 8

	/// maximum amount of columns and rows a grid storage object can have
	screen_max_columns = 8
	screen_max_rows = 8

	/// Visual offset X for grid items (accounts for grid background borders/padding)
	var/grid_visual_offset_x = 32
	/// Visual offset Y for grid items (accounts for grid background borders/padding)
	var/grid_visual_offset_y = 32

	/// If TRUE, ignores max_slots, max_specific_storage, and max_total_storage limits
	/// Only grid dimensions and type restrictions apply
	var/truegrid = FALSE

	/// If set, forces the grid UI to always open at this fixed screen location.
	/// Format: "screen_x:pixel_x,screen_y:pixel_y" (e.g., "CENTER-2:16,CENTER:16")
	/// When set, the grid will calculate all positions relative to this origin point
	/// instead of using the default screen_start_x/screen_start_y values.
	var/fixed_grid_origin = "CENTER-7:10,CENTER+2:16"

	// Coordinate tracking
	/// Maps "x,y" coordinate strings to item references
	var/list/grid_coordinates_to_item
	/// Maps item references to lists of "x,y" coordinate strings they occupy
	var/list/item_to_grid_coordinates
	/// Maps item references to list(x, y) of their top-left corner coordinate
	var/list/first_coordinates_item
	/// Maps item references to their rotation angle in degrees (0, 90, 180, 270)
	var/list/item_rotation_angles

	// Visual caching
	/// Static cache of generated underlay appearances by size
	var/static/list/mutable_appearance/underlay_cache

	// Phantom preview system
	/// The phantom preview object shown when hovering with an item
	var/atom/movable/screen/phantom_preview
	/// Whether the phantom is currently showing a valid placement (green) or invalid (red)
	var/phantom_valid = TRUE

/**
 * Setter for grid_rows - triggers UI refresh when changed
 *
 * @param new_rows - The new number of rows
 */
/datum/storage/grid/proc/set_grid_rows(new_rows)
	if(grid_rows == new_rows)
		return

	grid_rows = new_rows

	// Refresh the UI for all viewers by hiding and showing contents
	// This will recalculate the grid layout with the new dimensions
	refresh_views()

/**
 * Setter for grid_columns - triggers UI refresh when changed
 *
 * @param new_columns - The new number of columns
 */
/datum/storage/grid/proc/set_grid_columns(new_columns)
	if(grid_columns == new_columns)
		return

	grid_columns = new_columns

	// Refresh the UI for all viewers by hiding and showing contents
	// This will recalculate the grid layout with the new dimensions
	refresh_views()

/**
 * Override: Initialize grid storage with grid-specific screen object
 *
 * Creates a grid-specific screen object that captures cursor position information
 * for precise item placement based on click/drop location.
 */
/datum/storage/grid/New(
	atom/parent,
	max_slots,
	max_specific_storage,
	max_total_storage,
	numerical_stacking,
	allow_quick_gather,
	allow_quick_empty,
	collection_mode,
	attack_hand_interact
)
	// Call parent New() but we'll replace the boxes object
	. = ..()

	// Initialize grid-specific tracking lists
	grid_coordinates_to_item = list()
	item_to_grid_coordinates = list()
	first_coordinates_item = list()
	item_rotation_angles = list()

	// Replace the standard storage screen object with our grid-specific one
	if(boxes)
		qdel(boxes)
	boxes = new /atom/movable/screen/storage/grid(null, null, src)
	boxes.icon = 'icons/hud/storage.dmi'
	boxes.icon_state = "background"

/**
 * Converts a screen location string to grid coordinates
 *
 * Takes a BYOND screen_loc format ("screen_x:pixel_x,screen_y:pixel_y") and converts it
 * to grid coordinates ("x,y") based on the grid's position and cell size.
 *
 * @param screen_loc - The screen location string to convert
 * @return A string in "x,y" format representing grid coordinates, or null if invalid
 */
/datum/storage/grid/proc/screen_loc_to_grid_coordinates(screen_loc)
	if(!screen_loc)
		return null

	// Get the resolved origin (handles both fixed_grid_origin and numeric positioning)
	var/list/origin = resolve_grid_origin()
	var/origin_x = origin[1]
	var/origin_pixel_x = origin[2]
	var/origin_y = origin[3]
	var/origin_pixel_y = origin[4]

	// Parse screen_x and pixel_x from the format "screen_x:pixel_x"
	var/screen_x = copytext(screen_loc, 1, findtext(screen_loc, ","))
	var/screen_pixel_x = text2num(copytext(screen_x, findtext(screen_x, ":") + 1))
	screen_x = text2num(copytext(screen_x, 1, findtext(screen_x, ":")))

	// Parse screen_y and pixel_y from the format "screen_y:pixel_y"
	var/screen_y = copytext(screen_loc, findtext(screen_loc, ",") + 1)
	var/screen_pixel_y = text2num(copytext(screen_y, findtext(screen_y, ":") + 1))
	screen_y = text2num(copytext(screen_y, 1, findtext(screen_y, ":")))

	// Convert screen coordinates to absolute pixel positions
	var/screen_x_pixels = (screen_x * world.icon_size) + screen_pixel_x
	// Subtract the grid's starting position to get relative pixels
	screen_x_pixels -= (origin_x * world.icon_size) + origin_pixel_x
	// Subtract the visual offset to account for grid background borders/padding
	screen_x_pixels -= grid_visual_offset_x
	// Convert pixels to grid cell coordinates
	screen_x_pixels = FLOOR(screen_x_pixels / grid_box_size, 1)

	// Same process for Y coordinate
	var/screen_y_pixels = (screen_y * world.icon_size) + screen_pixel_y
	// Y coordinate calculation accounts for grid growing downward from origin_y
	screen_y_pixels -= ((origin_y - grid_rows + 1) * world.icon_size) + origin_pixel_y
	// Subtract the visual offset to account for grid background borders/padding
	screen_y_pixels -= grid_visual_offset_y
	screen_y_pixels = FLOOR(screen_y_pixels / grid_box_size, 1)

	return "[screen_x_pixels],[screen_y_pixels]"

/**
 * Converts grid coordinates to a screen location string
 *
 * Takes grid coordinates ("x,y") and converts them to BYOND screen_loc format
 * ("screen_x:pixel_x,screen_y:pixel_y") for HUD positioning.
 *
 * @param coordinates - The grid coordinates string in "x,y" format
 * @return A screen location string in BYOND format, or null if invalid
 */
/datum/storage/grid/proc/grid_coordinates_to_screen_loc(coordinates)
	if(!coordinates)
		return null

	// Get the resolved origin (handles both fixed_grid_origin and numeric positioning)
	var/list/origin = resolve_grid_origin()
	var/origin_x = origin[1]
	var/origin_pixel_x = origin[2]
	var/origin_y = origin[3]
	var/origin_pixel_y = origin[4]

	// Parse grid coordinates from "x,y" format
	var/coordinate_x = copytext(coordinates, 1, findtext(coordinates, ","))
	coordinate_x = text2num(coordinate_x)

	var/coordinate_y = copytext(coordinates, findtext(coordinates, ",") + 1)
	coordinate_y = text2num(coordinate_y)

	// Convert grid coordinates to absolute pixel positions
	var/screen_x_pixels = coordinate_x * grid_box_size
	// Add the grid's starting position
	screen_x_pixels += (origin_x * world.icon_size) + origin_pixel_x

	var/screen_y_pixels = coordinate_y * grid_box_size
	// Y coordinate calculation accounts for grid growing downward from origin_y
	screen_y_pixels += ((origin_y - grid_rows + 1) * world.icon_size) + origin_pixel_y

	// Convert absolute pixels to screen tile coordinates and pixel offsets
	var/screen_x = FLOOR(screen_x_pixels / world.icon_size, 1)
	var/screen_pixel_x = screen_x_pixels % world.icon_size

	var/screen_y = FLOOR(screen_y_pixels / world.icon_size, 1)
	var/screen_pixel_y = screen_y_pixels % world.icon_size

	// Normalize coordinates to prevent screen tearing when screen tile is 0
	// Convert "0:X" to "1:(X-32)" format
	if(screen_x == 0)
		screen_x = 1
		screen_pixel_x -= world.icon_size

	if(screen_y == 0)
		screen_y = 1
		screen_pixel_y -= world.icon_size

	return "[screen_x]:[screen_pixel_x],[screen_y]:[screen_pixel_y]"

/**
 * Parses the fixed_grid_origin string and returns the components
 *
 * Extracts screen_x, pixel_x, screen_y, and pixel_y from the fixed origin string.
 * Format expected: "screen_x:pixel_x,screen_y:pixel_y"
 *
 * @return A list with [screen_x, pixel_x, screen_y, pixel_y] or null if parsing fails
 */
/datum/storage/grid/proc/parse_fixed_origin()
	if(!fixed_grid_origin)
		return null

	// Parse the fixed origin format "screen_x:pixel_x,screen_y:pixel_y"
	var/screen_x_part = copytext(fixed_grid_origin, 1, findtext(fixed_grid_origin, ","))
	var/screen_y_part = copytext(fixed_grid_origin, findtext(fixed_grid_origin, ",") + 1)

	var/origin_screen_x = copytext(screen_x_part, 1, findtext(screen_x_part, ":"))
	var/origin_pixel_x = text2num(copytext(screen_x_part, findtext(screen_x_part, ":") + 1))

	var/origin_screen_y = copytext(screen_y_part, 1, findtext(screen_y_part, ":"))
	var/origin_pixel_y = text2num(copytext(screen_y_part, findtext(screen_y_part, ":") + 1))

	return list(origin_screen_x, origin_pixel_x, origin_screen_y, origin_pixel_y)

/**
 * Resolves the grid origin to numeric screen coordinates
 *
 * If fixed_grid_origin is set, parses it and converts any CENTER/NORTH/SOUTH/EAST/WEST
 * keywords to numeric coordinates. Otherwise, returns the default screen_start_x/y values.
 * This ensures coordinate calculations use the same origin as the grid background positioning.
 *
 * @return A list with [screen_x, pixel_x, screen_y, pixel_y] as numeric values
 */
/datum/storage/grid/proc/resolve_grid_origin()
	// If no fixed origin is set, use the default numeric values
	if(!fixed_grid_origin)
		return list(screen_start_x, screen_pixel_x, screen_start_y, screen_pixel_y)

	// Parse the fixed origin
	var/list/origin = parse_fixed_origin()
	if(!origin)
		return list(screen_start_x, screen_pixel_x, screen_start_y, screen_pixel_y)

	var/origin_screen_x = origin[1]  // May be string like "CENTER-7" or numeric
	var/origin_pixel_x = origin[2]   // Already numeric
	var/origin_screen_y = origin[3]  // May be string like "CENTER+2" or numeric
	var/origin_pixel_y = origin[4]   // Already numeric

	// Resolve screen_x if it contains keywords
	var/resolved_x = resolve_screen_keyword(origin_screen_x, TRUE)
	var/resolved_y = resolve_screen_keyword(origin_screen_y, FALSE)

	return list(resolved_x, origin_pixel_x, resolved_y, origin_pixel_y)

/**
 * Resolves screen location keywords (CENTER, NORTH, SOUTH, EAST, WEST) to numeric coordinates
 *
 * Parses strings like "CENTER-7", "NORTH+2", etc. and converts them to numeric screen coordinates.
 * Uses a default screen size assumption of 15x15 tiles, which is standard for most BYOND clients.
 *
 * @param keyword_string - The string to parse (e.g., "CENTER-7", "10", "NORTH+2")
 * @param is_x_axis - TRUE if resolving X coordinate, FALSE for Y coordinate
 * @return Numeric screen coordinate value
 */
/datum/storage/grid/proc/resolve_screen_keyword(keyword_string, is_x_axis = TRUE)
	// If already numeric, return it
	var/numeric_test = text2num(keyword_string)
	if(numeric_test)
		return numeric_test

	// Extract base keyword and offset
	var/base_keyword = keyword_string
	var/offset = 0

	// Check for + or - operators
	var/plus_pos = findtext(keyword_string, "+")
	var/minus_pos = findtext(keyword_string, "-")

	if(plus_pos)
		base_keyword = copytext(keyword_string, 1, plus_pos)
		offset = text2num(copytext(keyword_string, plus_pos + 1))
	else if(minus_pos)
		base_keyword = copytext(keyword_string, 1, minus_pos)
		offset = -text2num(copytext(keyword_string, minus_pos + 1))

	// Default screen size assumption (15x15 is standard for most clients)
	// This could be made configurable if needed
	var/screen_size = 15

	// Resolve keyword to numeric coordinate
	switch(base_keyword)
		if("CENTER")
			return FLOOR(screen_size / 2, 1) + offset
		if("NORTH")
			return screen_size + offset
		if("SOUTH")
			return 1 + offset
		if("EAST")
			return screen_size + offset
		if("WEST")
			return 1 + offset
		else
			// Fallback: try to parse as numeric
			var/fallback = text2num(base_keyword)
			return fallback ? (fallback + offset) : (is_x_axis ? screen_start_x : screen_start_y)

/**
 * Calculates the ending screen location for the grid when using fixed_grid_origin
 *
 * Takes the fixed origin and extends it by the grid dimensions to create
 * the "to" portion of a screen_loc range.
 *
 * @param rows - Number of rows in the grid
 * @param cols - Number of columns in the grid
 * @return A screen location string for the end of the grid range
 */
/datum/storage/grid/proc/get_fixed_origin_end(rows, cols)
	var/list/origin = parse_fixed_origin()
	if(!origin)
		return fixed_grid_origin

	var/origin_screen_x = origin[1]
	var/origin_pixel_x = origin[2]
	var/origin_screen_y = origin[3]
	var/origin_pixel_y = origin[4]

	// Calculate the end position based on grid dimensions
	// X extends to the right, Y extends downward (so we subtract rows)
	return "[origin_screen_x]+[cols-1]:[origin_pixel_x],[origin_screen_y]-[rows-1]:[origin_pixel_y]"

/**
 * Validates whether an item can be placed at the given grid coordinates
 *
 * Checks both bounds (coordinates within grid dimensions) and overlap (cells available
 * or occupied by the dragged item itself). This ensures items don't extend beyond the
 * grid or overlap with other items.
 *
 * @param coordinates - The grid coordinates string in "x,y" format
 * @param grid_width - The width of the item in pixels
 * @param grid_height - The height of the item in pixels
 * @param dragged_item - The item being placed (cells it currently occupies are ignored)
 * @return TRUE if the placement is valid, FALSE otherwise
 */
/datum/storage/grid/proc/validate_grid_coordinates(coordinates, grid_width, grid_height, obj/item/dragged_item)
	if(!coordinates)
		return FALSE

	// Parse the starting coordinates
	var/start_x = text2num(copytext(coordinates, 1, findtext(coordinates, ",")))
	var/start_y = text2num(copytext(coordinates, findtext(coordinates, ",") + 1))

	// Calculate how many grid cells the item occupies
	// var/grid_box_ratio = (world.icon_size / grid_box_size) // Not needed since grid_box_size is in pixels.
	var/cells_wide = CEILING(grid_width / grid_box_size, 1)
	var/cells_tall = CEILING(grid_height / grid_box_size, 1)

	// Check bounds - ensure item doesn't extend beyond grid dimensions
	if(start_x < 0 || start_y < 0)
		return FALSE
	if(start_x + cells_wide > grid_columns)
		return FALSE
	if(start_y + cells_tall > grid_rows)
		return FALSE

	// Check overlap - ensure all cells are available
	for(var/x in start_x to (start_x + cells_wide - 1))
		for(var/y in start_y to (start_y + cells_tall - 1))
			var/check_coords = "[x],[y]"
			var/obj/item/occupying_item = grid_coordinates_to_item?[check_coords]

			// Cell is occupied by a different item - invalid placement
			if(occupying_item && occupying_item != dragged_item)
				return FALSE

	return TRUE

/**
 * Adds an item to the grid at the specified coordinates
 *
 * Updates the coordinate tracking mappings to record which cells the item occupies
 * and where the item is positioned. This is called after validation to actually
 * place the item in the grid.
 *
 * @param storing - The item to add to the grid
 * @param coordinates - The grid coordinates string in "x,y" format for the top-left corner
 * @return TRUE on success, FALSE on failure
 */
/datum/storage/grid/proc/grid_add_item(obj/item/storing, coordinates)
	if(!storing || !coordinates)
		return FALSE

	// Initialize coordinate tracking lists if needed
	if(!grid_coordinates_to_item)
		grid_coordinates_to_item = list()
	if(!item_to_grid_coordinates)
		item_to_grid_coordinates = list()
	if(!first_coordinates_item)
		first_coordinates_item = list()

	// Parse the starting coordinates
	var/start_x = text2num(copytext(coordinates, 1, findtext(coordinates, ",")))
	var/start_y = text2num(copytext(coordinates, findtext(coordinates, ",") + 1))

	// Get item dimensions using the same method as validation
	var/list/dimensions = get_item_dimensions(storing)
	var/item_width = dimensions[1]
	var/item_height = dimensions[2]

	// Calculate how many grid cells the item occupies
	var/cells_wide = CEILING(item_width / grid_box_size, 1)
	var/cells_tall = CEILING(item_height / grid_box_size, 1)

	// Store the top-left corner coordinate for this item
	first_coordinates_item[storing] = list(start_x, start_y)

	// Initialize the list of coordinates this item occupies
	var/list/occupied_coords = list()

	// Mark all cells this item occupies
	for(var/x in start_x to (start_x + cells_wide - 1))
		for(var/y in start_y to (start_y + cells_tall - 1))
			var/cell_coords = "[x],[y]"
			grid_coordinates_to_item[cell_coords] = storing
			occupied_coords += cell_coords

	// Store the list of all coordinates this item occupies
	item_to_grid_coordinates[storing] = occupied_coords

	return TRUE

/**
 * Removes an item from the grid
 *
 * Clears all coordinate tracking mappings for the item, freeing up the cells it
 * occupied. Removes storage-specific visual elements (underlays and maptext) while
 * preserving the item's original overlays. The rotation data (grid_storage_transform
 * and grid_storage_rotation_angle) is preserved for reuse when the item is placed
 * back in storage.
 *
 * @param removed - The item to remove from the grid
 * @return TRUE on success, FALSE on failure
 */
/datum/storage/grid/proc/grid_remove_item(obj/item/removed)
	if(!removed)
		return FALSE

	// Remove the first coordinate mapping
	if(first_coordinates_item)
		first_coordinates_item -= removed

	// Get all coordinates this item occupies
	var/list/occupied_coords = item_to_grid_coordinates?[removed]
	if(occupied_coords)
		// Clear each cell in the grid_coordinates_to_item mapping
		for(var/coords in occupied_coords)
			grid_coordinates_to_item -= coords

		// Remove the item from item_to_grid_coordinates
		item_to_grid_coordinates -= removed

	// Remove storage-specific visual underlays from the item
	if(removed.underlays)
		removed.underlays.Cut()

	// Clear storage-specific maptext (numerical stacking display)
	removed.maptext = ""

	// Note: We don't clear overlays here because:
	// 1. orient_item_boxes() clears overlays before adding storage-specific ones when displaying
	// 2. Items should retain their original overlays when outside storage
	// 3. Storage-specific overlays (numerical stacking) are managed by orient_item_boxes()

	// Reset the visual transform (but keep grid_storage_transform and grid_storage_rotation_angle for reuse)
	removed.transform = null

	return TRUE

/**
 * Updates an item's position in the grid
 *
 * This is used after rotation or when an item's dimensions change. It removes the
 * item from its current position and re-adds it at the same coordinates with the
 * new dimensions, recalculating which cells it occupies.
 *
 * @param item - The item to update
 * @return TRUE on success, FALSE on failure
 */
/datum/storage/grid/proc/update_item_position(obj/item/item)
	if(!item)
		return FALSE

	// Get the item's current top-left coordinates
	var/list/first_coords = first_coordinates_item?[item]
	if(!first_coords || length(first_coords) < 2)
		return FALSE

	var/coordinates = "[first_coords[1]],[first_coords[2]]"

	// Remove the item from its current position
	grid_remove_item(item)

	// Re-add the item at the same coordinates with updated dimensions
	return grid_add_item(item, coordinates)

/**
 * Gets the dimensions of an item for grid storage
 *
 * Returns the item's explicit grid_width and grid_height if set, otherwise
 * calculates dimensions based on the item's w_class value using standard sizing rules.
 * When dimensions are calculated, they are assigned to the item for future use.
 *
 * @param thing - The item to get dimensions for
 * @return A list containing [width, height] in pixels
 */
/datum/storage/grid/proc/get_item_dimensions(obj/item/thing)
	if(!thing)
		return list(world.icon_size, world.icon_size)

	// If item has explicit dimensions, use those
	if(thing.grid_width && thing.grid_height)
		return list(thing.grid_width, thing.grid_height)

	// Auto-calculate dimensions from w_class and assign them to the item
	var/calculated_width
	var/calculated_height

	switch(thing.w_class)
		if(WEIGHT_CLASS_TINY)
			calculated_width = 32   // 1x1 cell
			calculated_height = 32
		if(WEIGHT_CLASS_SMALL)
			calculated_width = 32   // 1x2 cells
			calculated_height = 64
		if(WEIGHT_CLASS_NORMAL)
			calculated_width = 64   // 2x2 cells
			calculated_height = 64
		if(WEIGHT_CLASS_BULKY)
			calculated_width = 64   // 2x3 cells
			calculated_height = 96
		if(WEIGHT_CLASS_HUGE)
			calculated_width = 96   // 3x3 cells
			calculated_height = 96
		else
			// Default fallback for any other weight class
			calculated_width = world.icon_size
			calculated_height = world.icon_size

	// Assign the calculated dimensions to the item
	thing.grid_width = calculated_width
	thing.grid_height = calculated_height

	return list(calculated_width, calculated_height)

/**
 * Retrieves a cached underlay appearance for the given dimensions and styles
 *
 * Checks the static underlay_cache for a previously generated appearance matching
 * the specified grid dimensions and style configuration. This improves performance
 * by avoiding regeneration of identical underlays.
 *
 * @param grid_width - The width of the item in pixels
 * @param grid_height - The height of the item in pixels
 * @param item - The item to get the underlay for (optional, used for style flags and umbrella style)
 * @return A cached mutable_appearance if found, null otherwise
 */
/datum/storage/grid/proc/get_bound_underlay(grid_width, grid_height, obj/item/item = null)
	if(!grid_width || !grid_height)
		return null

	// Initialize the cache if it doesn't exist
	if(!underlay_cache)
		underlay_cache = list()

	// Determine style suffix based on umbrella style and enabled flags
	var/border_suffix = ""
	if(item && item.grid_style_border && item.grid_style)
		border_suffix = "_[item.grid_style]"

	var/corner_suffix = ""
	if(item && item.grid_style_corner && item.grid_style)
		corner_suffix = "_[item.grid_style]"

	var/under_suffix = ""
	if(item && item.grid_style_under && item.grid_style)
		under_suffix = "_[item.grid_style]"

	// Create a unique key for this size and style combination
	var/cache_key = "[grid_width]x[grid_height][border_suffix][corner_suffix][under_suffix]"

	// Return the cached appearance if it exists
	return underlay_cache[cache_key]

/**
 * Generates a visual boundary underlay for an item in the grid
 *
 * Creates a mutable_appearance with scaled borders and corners to visually indicate
 * the item's bounding box in the grid. The appearance is cached for reuse to improve
 * performance. Uses icon operations to create a properly scaled border around the
 * item based on its dimensions. Supports custom styling via boolean flags and umbrella style.
 *
 * @param grid_width - The width of the item in pixels (defaults to world.icon_size)
 * @param grid_height - The height of the item in pixels (defaults to world.icon_size)
 * @param item - The item to generate the underlay for (optional, used for style flags and umbrella style)
 * @return A mutable_appearance representing the visual boundary
 */
/datum/storage/grid/proc/generate_bound_underlay(grid_width = world.icon_size, grid_height = world.icon_size, obj/item/item = null)
	// Create the base appearance with UI flags
	var/mutable_appearance/final_appearance = mutable_appearance()
	final_appearance.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	final_appearance.layer = 1  // Higher layer to appear above other items on the same plane

	// Create a blank icon scaled to the item's dimensions
	var/icon/final_icon = icon('icons/hud/storage.dmi', "blank")
	final_icon.Scale(grid_width, grid_height)

	// Determine style suffix based on umbrella style and enabled flags
	var/border_suffix = ""
	if(item && item.grid_style_border && item.grid_style)
		border_suffix = "_[item.grid_style]"

	var/corner_suffix = ""
	if(item && item.grid_style_corner && item.grid_style)
		corner_suffix = "_[item.grid_style]"

	var/under_suffix = ""
	if(item && item.grid_style_under && item.grid_style)
		under_suffix = "_[item.grid_style]"

	// Define which icon states need to be scaled in which directions
	var/static/list/scale_both = list("block_under")  // Background - scale both dimensions
	var/list/scale_x_states = list("up[border_suffix]", "down[border_suffix]")  // Top/bottom borders - scale width only
	var/list/scale_y_states = list("right[border_suffix]", "left[border_suffix]")  // Left/right borders - scale height only

	// Calculate offsets for positioning borders and corners
	var/width_offset = world.icon_size * ((grid_width / world.icon_size) - 1)
	var/height_offset = world.icon_size * ((grid_height / world.icon_size) - 1)

	// Blend the background (scaled to full dimensions) - uses under_suffix if enabled
	var/icon/scaled_icon
	for(var/scaled_both in scale_both)
		scaled_icon = icon('icons/hud/storage.dmi', "[scaled_both][under_suffix]")
		scaled_icon.Scale(grid_width, grid_height)
		final_icon.Blend(scaled_icon, ICON_OVERLAY)

	// Blend the top and bottom borders (scaled horizontally) - uses border_suffix if enabled
	var/multiplier = 0
	for(var/scaled_x in scale_x_states)
		multiplier = !multiplier  // Alternates between 0 and 1 for top/bottom positioning
		scaled_icon = icon('icons/hud/storage.dmi', scaled_x)
		scaled_icon.Scale(grid_width, world.icon_size)
		final_icon.Blend(scaled_icon, ICON_OVERLAY, 1, 1 + (height_offset * multiplier))

	// Blend the left and right borders (scaled vertically) - uses border_suffix if enabled
	multiplier = 0
	for(var/scaled_y in scale_y_states)
		multiplier = !multiplier  // Alternates between 0 and 1 for left/right positioning
		scaled_icon = icon('icons/hud/storage.dmi', scaled_y)
		scaled_icon.Scale(world.icon_size, grid_height)
		final_icon.Blend(scaled_icon, ICON_OVERLAY, 1 + (width_offset * multiplier), 1)

	// Calculate corner positions
	var/corner_pos_x = 1 + (grid_width - world.icon_size)
	var/corner_pos_y = 1 + (grid_height - world.icon_size)

	// Blend all four corners - uses corner_suffix if enabled
	var/icon/corner_left_down = icon('icons/hud/storage.dmi', "corner_left_down[corner_suffix]")
	final_icon.Blend(corner_left_down, ICON_OVERLAY, 1, 1)

	var/icon/corner_right_down = icon('icons/hud/storage.dmi', "corner_right_down[corner_suffix]")
	final_icon.Blend(corner_right_down, ICON_OVERLAY, corner_pos_x, 1)

	var/icon/corner_left_up = icon('icons/hud/storage.dmi', "corner_left_up[corner_suffix]")
	final_icon.Blend(corner_left_up, ICON_OVERLAY, 1, corner_pos_y)

	var/icon/corner_right_up = icon('icons/hud/storage.dmi', "corner_right_up[corner_suffix]")
	final_icon.Blend(corner_right_up, ICON_OVERLAY, corner_pos_x, corner_pos_y)

	// Apply the final icon to the appearance
	final_appearance.icon = final_icon

	// Transform to center the appearance (offset by half the extra width/height)
	final_appearance.transform = final_appearance.transform.Translate(-width_offset / 2, -height_offset / 2)

	// Cache the appearance for reuse (include all style suffixes in cache key)
	if(!underlay_cache)
		underlay_cache = list()
	var/cache_key = "[grid_width]x[grid_height][border_suffix][corner_suffix][under_suffix]"
	underlay_cache[cache_key] = final_appearance

	return final_appearance

/**
 * Generates a phantom underlay for preview purposes
 *
 * Creates a colored underlay to show where an item will be placed before the user commits to the insertion.
 * Color priority: Red (invalid) > Yellow (too large/over capacity) > Purple (stackable) > Green (valid)
 * Supports custom styling via boolean flags and umbrella style.
 *
 * @param grid_width - The width of the item in pixels
 * @param grid_height - The height of the item in pixels
 * @param is_valid - Whether the placement is valid (green) or invalid (red)
 * @param is_too_large - Whether the item is too large for storage (yellow)
 * @param is_over_capacity - Whether storage is at capacity (yellow)
 * @param is_stackable - Whether the item can stack with an existing item (purple)
 * @param item - The item to generate the underlay for (optional, used for style flags and umbrella style)
 * @return A mutable_appearance representing the phantom underlay
 */
/datum/storage/grid/proc/generate_phantom_underlay(grid_width = world.icon_size, grid_height = world.icon_size, is_valid = TRUE, is_too_large = FALSE, is_over_capacity = FALSE, is_stackable = FALSE, obj/item/item = null)
	// Create the base appearance with UI flags
	var/mutable_appearance/final_appearance = mutable_appearance()
	final_appearance.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	final_appearance.layer = 1  // Higher layer to appear above stored items

	// Create a blank icon scaled to the item's dimensions
	var/icon/final_icon = icon('icons/hud/storage.dmi', "blank")
	final_icon.Scale(grid_width, grid_height)

	// Determine style suffix based on umbrella style and enabled flags
	var/border_suffix = ""
	if(item && item.grid_style_border && item.grid_style)
		border_suffix = "_[item.grid_style]"

	var/corner_suffix = ""
	if(item && item.grid_style_corner && item.grid_style)
		corner_suffix = "_[item.grid_style]"

	var/under_suffix = ""
	if(item && item.grid_style_under && item.grid_style)
		under_suffix = "_[item.grid_style]"

	// Define which icon states need to be scaled in which directions
	var/static/list/scale_both = list("block_under")
	var/list/scale_x_states = list("up[border_suffix]", "down[border_suffix]")
	var/list/scale_y_states = list("right[border_suffix]", "left[border_suffix]")

	// Calculate offsets for positioning borders and corners
	var/width_offset = world.icon_size * ((grid_width / world.icon_size) - 1)
	var/height_offset = world.icon_size * ((grid_height / world.icon_size) - 1)

	// Choose color based on priority: Red > Yellow > Purple > Green
	var/underlay_color
	if(!is_valid)
		underlay_color = "#FF000080"  // Red with transparency (invalid placement) - HIGHEST PRIORITY
	else if(is_too_large || is_over_capacity)
		underlay_color = "#FFFF0080"  // Yellow with transparency (too large or over capacity)
	else if(is_stackable)
		underlay_color = "#FF00FF80"  // Purple with transparency (stackable with existing item)
	else
		underlay_color = "#00FF0080"  // Green with transparency (valid placement)

	// Blend the background (scaled to full dimensions) - uses under_suffix if enabled
	var/icon/scaled_icon
	for(var/scaled_both in scale_both)
		scaled_icon = icon('icons/hud/storage.dmi', "[scaled_both][under_suffix]")
		scaled_icon.Scale(grid_width, grid_height)
		scaled_icon.Blend(underlay_color, ICON_MULTIPLY)
		final_icon.Blend(scaled_icon, ICON_OVERLAY)

	// Blend the top and bottom borders (scaled horizontally) - uses border_suffix if enabled
	var/multiplier = 0
	for(var/scaled_x in scale_x_states)
		multiplier = !multiplier
		scaled_icon = icon('icons/hud/storage.dmi', scaled_x)
		scaled_icon.Scale(grid_width, world.icon_size)
		scaled_icon.Blend(underlay_color, ICON_MULTIPLY)
		final_icon.Blend(scaled_icon, ICON_OVERLAY, 1, 1 + (height_offset * multiplier))

	// Blend the left and right borders (scaled vertically) - uses border_suffix if enabled
	multiplier = 0
	for(var/scaled_y in scale_y_states)
		multiplier = !multiplier
		scaled_icon = icon('icons/hud/storage.dmi', scaled_y)
		scaled_icon.Scale(world.icon_size, grid_height)
		scaled_icon.Blend(underlay_color, ICON_MULTIPLY)
		final_icon.Blend(scaled_icon, ICON_OVERLAY, 1 + (width_offset * multiplier), 1)

	// Calculate corner positions
	var/corner_pos_x = 1 + (grid_width - world.icon_size)
	var/corner_pos_y = 1 + (grid_height - world.icon_size)

	// Blend all four corners - uses corner_suffix if enabled
	var/icon/corner_left_down = icon('icons/hud/storage.dmi', "corner_left_down[corner_suffix]")
	corner_left_down.Blend(underlay_color, ICON_MULTIPLY)
	final_icon.Blend(corner_left_down, ICON_OVERLAY, 1, 1)

	var/icon/corner_right_down = icon('icons/hud/storage.dmi', "corner_right_down[corner_suffix]")
	corner_right_down.Blend(underlay_color, ICON_MULTIPLY)
	final_icon.Blend(corner_right_down, ICON_OVERLAY, corner_pos_x, 1)

	var/icon/corner_left_up = icon('icons/hud/storage.dmi', "corner_left_up[corner_suffix]")
	corner_left_up.Blend(underlay_color, ICON_MULTIPLY)
	final_icon.Blend(corner_left_up, ICON_OVERLAY, 1, corner_pos_y)

	var/icon/corner_right_up = icon('icons/hud/storage.dmi', "corner_right_up[corner_suffix]")
	corner_right_up.Blend(underlay_color, ICON_MULTIPLY)
	final_icon.Blend(corner_right_up, ICON_OVERLAY, corner_pos_x, corner_pos_y)

	// Apply the final icon to the appearance
	final_appearance.icon = final_icon

	// Transform to center the appearance
	final_appearance.transform = final_appearance.transform.Translate(-width_offset / 2, -height_offset / 2)

	return final_appearance

/**
 * Updates the phantom preview for an item being held over the grid
 *
 * Creates or updates a semi-transparent preview showing where the item will be placed
 * and whether the placement is valid (green), blocked (red), or too large (yellow).
 *
 * @param item - The item being previewed
 * @param params - Mouse parameters containing screen-loc
 * @param user - The mob holding the item
 */
/datum/storage/grid/proc/update_phantom_preview(obj/item/item, params, mob/user)
	if(!item || !params || !user)
		return

	// Parse params to get screen-loc
	var/list/param_list = params2list(params)
	var/screen_loc = param_list["screen-loc"]
	if(!screen_loc)
		return

	// Get item dimensions
	var/list/dimensions = get_item_dimensions(item)
	var/item_width = dimensions[1]
	var/item_height = dimensions[2]

	// Convert screen-loc to grid coordinates
	var/coordinates = screen_loc_to_grid_coordinates(screen_loc)
	if(!coordinates)
		return

	// Parse initial coordinates
	var/coord_x = text2num(copytext(coordinates, 1, findtext(coordinates, ",")))
	var/coord_y = text2num(copytext(coordinates, findtext(coordinates, ",") + 1))

	var/cells_wide = CEILING(item_width / grid_box_size, 1)
	var/cells_tall = CEILING(item_height / grid_box_size, 1)

	// Offset coordinates to treat cursor as center of item instead of top-left corner
	// For multi-cell items, shift the top-left corner back by half the item size
	coord_x -= FLOOR(cells_wide / 2, 1)
	coord_y -= FLOOR(cells_tall / 2, 1)

	// Clamp coordinates to keep within bounds
	if(coord_x < 0)
		coord_x = 0
	if(coord_x + cells_wide > grid_columns)
		coord_x = grid_columns - cells_wide
	if(coord_y < 0)
		coord_y = 0
	if(coord_y + cells_tall > grid_rows)
		coord_y = grid_rows - cells_tall
	if(coord_x < 0)
		coord_x = 0
	if(coord_y < 0)
		coord_y = 0

	coordinates = "[coord_x],[coord_y]"

	// Check if item is too large for storage (weight class check) - disabled when truegrid is enabled
	var/is_too_large = FALSE
	if(!truegrid)
		is_too_large = !check_weight_class(item)

	// Check if storage has capacity (unless truegrid is enabled)
	var/is_over_capacity = FALSE
	if(!truegrid && !can_insert(item, user, FALSE))
		is_over_capacity = TRUE

	// Check if numerical stacking is enabled AND item can stack with an existing item
	var/is_stackable = FALSE
	var/obj/item/stack_target = null
	if(numerical_stacking)
		// Check if there's an existing item of the same type that this can stack with
		for(var/obj/item/existing in contents_for_display())
			if(existing.type == item.type || existing.name == item.name)
				stack_target = existing
				is_stackable = TRUE
				break

	// Check if placement is valid (grid position check)
	var/is_valid = validate_grid_coordinates(coordinates, item_width, item_height, item)

	// If item is stackable, position phantom over the existing stack
	if(is_stackable && stack_target)
		var/list/stack_coords = first_coordinates_item?[stack_target]
		if(stack_coords && length(stack_coords) >= 2)
			coordinates = "[stack_coords[1]],[stack_coords[2]]"

	// Create or update phantom
	if(!phantom_preview)
		phantom_preview = new /atom/movable/screen()
		phantom_preview.plane = ABOVE_HUD_PLANE + 1  // Slightly higher plane to appear above stored items
		phantom_preview.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		user.client?.screen += phantom_preview

	// Update phantom appearance - copy from item
	phantom_preview.icon = item.icon
	phantom_preview.icon_state = item.icon_state
	phantom_preview.alpha = 128  // Semi-transparent

	// Copy item's overlays to phantom so they're visible in preview
	phantom_preview.overlays.Cut()
	if(item.overlays && length(item.overlays))
		for(var/overlay in item.overlays)
			phantom_preview.overlays += overlay

	// Copy rotation from item's grid storage transform
	if(item.grid_storage_transform)
		phantom_preview.transform = item.grid_storage_transform
	else
		phantom_preview.transform = null

	// Generate and apply colored underlay
	// Priority: Purple (stackable) > Yellow (too large or over capacity) > Red (invalid placement) > Green (valid)
	var/mutable_appearance/phantom_underlay = generate_phantom_underlay(item_width, item_height, is_valid, is_too_large, is_over_capacity, is_stackable, item)
	if(phantom_underlay)
		phantom_preview.underlays.Cut()
		phantom_preview.underlays += phantom_underlay

	// Calculate screen position
	var/display_screen_loc = grid_coordinates_to_screen_loc(coordinates)
	if(!display_screen_loc)
		return

	// Apply visual offset and centering
	var/center_offset_x = FLOOR((item_width - world.icon_size) / 2, 1)
	var/center_offset_y = FLOOR((item_height - world.icon_size) / 2, 1)

	var/screen_x = copytext(display_screen_loc, 1, findtext(display_screen_loc, ","))
	var/pixel_x = text2num(copytext(screen_x, findtext(screen_x, ":") + 1)) + grid_visual_offset_x + center_offset_x
	screen_x = copytext(screen_x, 1, findtext(screen_x, ":"))

	var/screen_y = copytext(display_screen_loc, findtext(display_screen_loc, ",") + 1)
	var/pixel_y = text2num(copytext(screen_y, findtext(screen_y, ":") + 1)) + grid_visual_offset_y + center_offset_y
	screen_y = copytext(screen_y, 1, findtext(screen_y, ":"))

	phantom_preview.screen_loc = "[screen_x]:[pixel_x],[screen_y]:[pixel_y]"
	phantom_valid = is_valid && !is_too_large

/**
 * Clears the phantom preview from the user's screen
 *
 * Removes and deletes the phantom preview object.
 *
 * @param user - The mob whose screen to clear
 */
/datum/storage/grid/proc/clear_phantom_preview(mob/user)
	if(phantom_preview)
		user?.client?.screen -= phantom_preview
		qdel(phantom_preview)
		phantom_preview = null
		phantom_valid = TRUE

/**
 * Override: Validates if an item can be inserted into grid storage
 *
 * Extends the base storage validation with grid-specific checks. When truegrid is enabled,
 * bypasses max_slots, max_specific_storage, and max_total_storage checks - only grid
 * dimensions and type restrictions apply.
 *
 * @param to_insert - The item to validate for insertion
 * @param user - The mob attempting the insertion
 * @param messages - Whether to show feedback messages
 * @param force - Whether to bypass locked storage checks
 * @return TRUE if the item can be inserted, FALSE otherwise
 */
/datum/storage/grid/can_insert(obj/item/to_insert, mob/user, messages = TRUE, force = FALSE)
	// Perform basic validation checks (not weight/slot related)
	if(QDELETED(to_insert) || !isitem(to_insert))
		return FALSE

	if(to_insert.item_flags & ABSTRACT)
		return FALSE

	if(parent.flags_1 & HOLOGRAM_1)
		if(!(to_insert.flags_1 & HOLOGRAM_1))
			return FALSE
	else if(to_insert.flags_1 & HOLOGRAM_1)
		return FALSE

	if(user && !user.canUnequipItem(to_insert))
		return FALSE

	if(!can_manipulate_contents(user, force, !messages))
		return FALSE

	if(locked && !force)
		return FALSE

	if((to_insert == parent) || (to_insert == real_location))
		return FALSE

	// If truegrid is enabled, skip weight and slot checks
	if(!truegrid)
		// Perform standard weight and slot checks
		if(!check_weight_class(to_insert))
			if(messages && user)
				to_chat(user, span_warning("\The [to_insert] is too large for \the [parent]."))
			return FALSE

		if(!check_slots_full(to_insert))
			if(messages && user)
				to_chat(user, span_warning("\The [to_insert] cannot fit into \the [parent]."))
			return FALSE

		if(!check_total_weight(to_insert))
			if(messages && user)
				to_chat(user, span_warning("\The [to_insert] cannot fit into \the [parent]."))
			return FALSE

	// Always check type restrictions (even with truegrid)
	if(!check_typecache_for_item(to_insert))
		if(messages && user)
			to_chat(user, span_warning("\The [parent] cannot hold \the [to_insert]."))
		return FALSE

	if(is_type_in_typecache(to_insert, cant_hold) || HAS_TRAIT(to_insert, TRAIT_NO_STORAGE_INSERT) || (can_hold_trait && !HAS_TRAIT(to_insert, can_hold_trait)))
		if(messages && user)
			to_chat(user, span_warning("\The [parent] cannot hold \the [to_insert]."))
		return FALSE

	if(HAS_TRAIT(to_insert, TRAIT_NODROP))
		if(messages)
			to_chat(user, span_warning("\The [to_insert] is stuck on your hand."))
		return FALSE

	// Check parent container constraints (even with truegrid)
	var/datum/storage/biggerfish = parent.loc.atom_storage
	if(biggerfish && biggerfish.max_specific_storage < max_specific_storage)
		if(messages && user)
			to_chat(user, span_warning("[to_insert] cannot fit in [parent] while [parent.loc] is in the way."))
		return FALSE

	// Check storage nesting (even with truegrid)
	if(isitem(parent))
		var/obj/item/item_parent = parent
		var/datum/storage/item_storage = to_insert.atom_storage
		if((to_insert.w_class >= item_parent.w_class) && item_storage && !allow_big_nesting)
			if(messages && user)
				to_chat(user, span_warning("[parent] cannot hold [to_insert] as it's a storage item of the same size!"))
			return FALSE

	// Check signals (even with truegrid)
	if(SEND_SIGNAL(src, COMSIG_STORAGE_CAN_INSERT, to_insert, user, messages, force) & STORAGE_NO_INSERT)
		return FALSE

	// Grid-specific validation will be handled in attempt_insert()
	// where we have access to the screen-loc params for coordinate validation
	// For now, just ensure the item has valid dimensions
	var/list/dimensions = get_item_dimensions(to_insert)
	if(!dimensions || length(dimensions) < 2)
		if(messages && user)
			to_chat(user, span_warning("\The [to_insert] has invalid dimensions."))
		return FALSE

	return TRUE

/**
 * Override: Attempts to insert an item into grid storage at specific coordinates
 *
 * Handles grid-specific insertion logic including coordinate extraction, validation,
 * auto-placement fallback, and visual underlay generation. Calls the parent method
 * to handle standard insertion logic (moving item, emitting signals, etc.).
 *
 * @param to_insert - The item to insert
 * @param user - The mob performing the insertion
 * @param override - See item_insertion_feedback()
 * @param force - Whether to bypass locked storage checks
 * @param params - Optional parameters containing screen-loc for grid positioning
 * @return TRUE on successful insertion, FALSE otherwise
 */
/datum/storage/grid/attempt_insert(obj/item/to_insert, mob/user, override = FALSE, force = FALSE, params)
	// Perform validation first
	if(!can_insert(to_insert, user, force = force))
		return FALSE

	// Get item dimensions
	var/list/dimensions = get_item_dimensions(to_insert)
	var/item_width = dimensions[1]
	var/item_height = dimensions[2]

	// Extract screen-loc from params if provided
	var/screen_loc = null
	var/coordinates = null

	// Check if numerical stacking is enabled and if there's already an item of the same type
	var/using_stack_coordinates = FALSE
	if(numerical_stacking)
		for(var/obj/item/existing in real_location.contents)
			// Check if same type and name (for stacking)
			if(existing.type == to_insert.type && existing.name == to_insert.name)
				// Use the existing item's coordinates
				var/list/existing_coords = first_coordinates_item?[existing]
				if(existing_coords && length(existing_coords) >= 2)
					coordinates = "[existing_coords[1]],[existing_coords[2]]"
					using_stack_coordinates = TRUE
					break

	if(params)
		// Parse params to extract screen-loc
		// Params format: "icon-x=X;icon-y=Y;screen-loc=SCREEN_LOC;..."
		var/list/param_list = params2list(params)
		screen_loc = param_list["screen-loc"]

	// Convert screen-loc to grid coordinates if we have it (and not using existing stack coordinates)
	if(screen_loc && !coordinates)
		coordinates = screen_loc_to_grid_coordinates(screen_loc)

		// Adjust coordinates to keep multi-cell items within bounds
		// Treat the clicked position as the "center" of the item
		if(coordinates)
			var/coord_x = text2num(copytext(coordinates, 1, findtext(coordinates, ",")))
			var/coord_y = text2num(copytext(coordinates, findtext(coordinates, ",") + 1))

			// Calculate how many cells the item occupies
			var/cells_wide = CEILING(item_width / grid_box_size, 1)
			var/cells_tall = CEILING(item_height / grid_box_size, 1)

			// Offset coordinates to treat cursor as center of item instead of top-left corner
			// For multi-cell items, shift the top-left corner back by half the item size
			coord_x -= FLOOR(cells_wide / 2, 1)
			coord_y -= FLOOR(cells_tall / 2, 1)

			// Clamp X coordinate to keep item within horizontal bounds
			// Left edge: coord_x must be >= 0
			if(coord_x < 0)
				coord_x = 0

			// Right edge: coord_x + cells_wide must be <= grid_columns
			if(coord_x + cells_wide > grid_columns)
				coord_x = grid_columns - cells_wide

			// Clamp Y coordinate to keep item within vertical bounds
			// Top edge: coord_y must be >= 0
			if(coord_y < 0)
				coord_y = 0

			// Bottom edge: coord_y + cells_tall must be <= grid_rows
			if(coord_y + cells_tall > grid_rows)
				coord_y = grid_rows - cells_tall

			// Final safety check - ensure coordinates are still non-negative after all adjustments
			if(coord_x < 0)
				coord_x = 0
			if(coord_y < 0)
				coord_y = 0

			// Reconstruct coordinates string
			coordinates = "[coord_x],[coord_y]"

	// Validate coordinates for item dimensions (skip if using stack coordinates from numerical stacking)
	if(coordinates && !using_stack_coordinates && !validate_grid_coordinates(coordinates, item_width, item_height, to_insert))
		// If user provided explicit coordinates (via click), reject the insertion
		if(params && screen_loc)
			if(user)
				to_chat(user, span_warning("\The [to_insert] cannot fit there!"))
			return FALSE
		// Otherwise, allow auto-placement
		coordinates = null

	// Auto-placement: find first available position if coordinates are invalid or not provided
	// This only happens when no params were provided (e.g., programmatic insertion)
	// Skip auto-placement if using stack coordinates
	// Iterate X first (columns), then Y (rows) to stack items vertically
	if(!coordinates && !using_stack_coordinates)
		var/found = FALSE
		for(var/x in 0 to (grid_columns - 1))
			for(var/y in 0 to (grid_rows - 1))
				var/test_coords = "[x],[y]"
				if(validate_grid_coordinates(test_coords, item_width, item_height, to_insert))
					coordinates = test_coords
					found = TRUE
					break
			if(found)
				break

		// No valid position found - reject insertion
		if(!coordinates)
			if(user)
				to_chat(user, span_warning("\The [to_insert] cannot fit in \the [parent]."))
			return FALSE

	// Add item to grid at the validated coordinates
	if(!grid_add_item(to_insert, coordinates))
		return FALSE

	// Generate and apply visual underlay
	var/mutable_appearance/underlay = get_bound_underlay(item_width, item_height)
	if(!underlay)
		underlay = generate_bound_underlay(item_width, item_height)

	if(underlay)
		to_insert.underlays += underlay

	// Call parent to handle standard insertion logic
	// This moves the item, emits signals, plays sounds, etc.
	return ..()

/**
 * Override: Attempts to remove an item from grid storage
 *
 * Handles grid-specific removal logic including clearing coordinate mappings and
 * visual underlays. Calls the parent method to handle standard removal logic
 * (moving item, emitting signals, etc.).
 *
 * @param thing - The item to remove
 * @param newLoc - Where to move the item
 * @param silent - Whether to suppress exit sounds
 * @param user - The mob performing the removal
 * @return TRUE on successful removal, FALSE otherwise
 */
/datum/storage/grid/attempt_remove(obj/item/thing, atom/newLoc, silent = FALSE, mob/living/user)
	// Check if removal is allowed first (locked storage, etc.)
	if(!can_manipulate_contents(user, silent = silent))
		return FALSE

	// Remove item from grid coordinate tracking BEFORE moving it
	grid_remove_item(thing)

	// Call parent to handle the actual removal (moving, signals, etc.)
	// Note: We already checked can_manipulate_contents, so parent will succeed
	return ..()  // Parent handles moving the item and triggering handle_exit which calls reset_item

/**
 * Override: Updates the storage UI to fit all objects in grid layout
 *
 * Positions items at their grid coordinates instead of using the standard list-based
 * layout. Handles both numerical stacking display and standard display modes. Also
 * positions the close button based on grid dimensions.
 */
/datum/storage/grid/orient_to_hud()
	// Process numerical display if enabled
	var/list/datum/numbered_display/numbered_contents
	if(numerical_stacking)
		numbered_contents = process_numerical_display()

	// For grid storage, we use the full grid dimensions
	orient_item_boxes(grid_rows, grid_columns, numbered_contents)

/**
 * Override: Generates the actual UI objects, their location, and alignments for grid storage
 *
 * Positions items based on their grid coordinates rather than sequential layout.
 * Centers multi-cell items within their bounds and applies visual underlays.
 * Sets proper plane (ABOVE_HUD_PLANE) for all items.
 *
 * @param rows - Number of rows in the grid (grid_rows)
 * @param cols - Number of columns in the grid (grid_columns)
 * @param numerical_display_contents - Optional list of numbered display datums for stacking mode
 */
/datum/storage/grid/orient_item_boxes(rows, cols, list/obj/item/numerical_display_contents)
	// Set the boxes screen_loc to cover the full grid dimensions
	// If fixed_grid_origin is set, use that as the starting point, otherwise use dynamic positioning
	if(fixed_grid_origin)
		boxes.screen_loc = "[fixed_grid_origin] to [get_fixed_origin_end(rows, cols)]"
	else
		boxes.screen_loc = "[screen_start_x]:[screen_pixel_x],[screen_start_y]:[screen_pixel_y] to [screen_start_x+cols-1]:[screen_pixel_x],[screen_start_y-rows+1]:[screen_pixel_y]"

	// Handle numerical stacking display mode
	if(islist(numerical_display_contents))
		for(var/type in numerical_display_contents)
			var/datum/numbered_display/numberdisplay = numerical_display_contents[type]
			var/obj/item/sample = numberdisplay.sample_object

			// Get the item's grid coordinates
			var/list/first_coords = first_coordinates_item?[sample]
			if(!first_coords || length(first_coords) < 2)
				continue

			var/coordinates = "[first_coords[1]],[first_coords[2]]"

			// Convert grid coordinates to screen location
			var/screen_loc = grid_coordinates_to_screen_loc(coordinates)
			if(!screen_loc)
				continue

			// Get item dimensions for centering
			var/list/dimensions = get_item_dimensions(sample)
			var/item_width = dimensions[1]
			var/item_height = dimensions[2]

			// Calculate pixel offsets to center multi-cell items
			var/center_offset_x = FLOOR((item_width - world.icon_size) / 2, 1)
			var/center_offset_y = FLOOR((item_height - world.icon_size) / 2, 1)

			// Add visual offset to account for grid background borders/padding
			// Then add centering offset to center items within their grid cells
			var/screen_x = copytext(screen_loc, 1, findtext(screen_loc, ","))
			var/pixel_x = text2num(copytext(screen_x, findtext(screen_x, ":") + 1)) + grid_visual_offset_x + center_offset_x
			screen_x = copytext(screen_x, 1, findtext(screen_x, ":"))

			var/screen_y = copytext(screen_loc, findtext(screen_loc, ",") + 1)
			var/pixel_y = text2num(copytext(screen_y, findtext(screen_y, ":") + 1)) + grid_visual_offset_y + center_offset_y
			screen_y = copytext(screen_y, 1, findtext(screen_y, ":"))

			// Set item properties
			sample.mouse_opacity = MOUSE_OPACITY_OPAQUE
			sample.screen_loc = "[screen_x]:[pixel_x],[screen_y]:[pixel_y]"
			sample.plane = ABOVE_HUD_PLANE

			// Apply rotation transform if item has one stored in grid storage
			if(sample.grid_storage_transform)
				sample.transform = sample.grid_storage_transform
			else
				// Reset transform if no rotation stored
				sample.transform = null

			// Apply maptext as overlay to avoid rotation
			if(numberdisplay.number > 1)
				var/image/number_overlay = image(icon = null, loc = sample)
				number_overlay.maptext = MAPTEXT("<font color='white'>[numberdisplay.number]</font>")
				number_overlay.maptext_width = 64
				number_overlay.maptext_height = 32
				number_overlay.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE
				number_overlay.plane = ABOVE_HUD_PLANE
				number_overlay.layer = 10
				sample.overlays.Cut()
				sample.overlays += number_overlay
				sample.maptext = ""
			else
				sample.overlays.Cut()
				sample.maptext = ""

			// Apply visual underlay
			var/mutable_appearance/underlay = get_bound_underlay(item_width, item_height, sample)
			if(!underlay)
				underlay = generate_bound_underlay(item_width, item_height, sample)
			if(underlay && sample.underlays)
				sample.underlays.Cut()
				sample.underlays += underlay

	// Handle standard display mode
	else
		for(var/obj/item/item in contents_for_display())
			// Get the item's grid coordinates
			var/list/first_coords = first_coordinates_item?[item]
			if(!first_coords || length(first_coords) < 2)
				continue

			var/coordinates = "[first_coords[1]],[first_coords[2]]"

			// Convert grid coordinates to screen location
			var/screen_loc = grid_coordinates_to_screen_loc(coordinates)
			if(!screen_loc)
				continue

			// Get item dimensions for centering
			var/list/dimensions = get_item_dimensions(item)
			var/item_width = dimensions[1]
			var/item_height = dimensions[2]

			// Calculate pixel offsets to center multi-cell items
			var/center_offset_x = FLOOR((item_width - world.icon_size) / 2, 1)
			var/center_offset_y = FLOOR((item_height - world.icon_size) / 2, 1)

			// Add visual offset to account for grid background borders/padding
			// Then add centering offset to center items within their grid cells
			var/screen_x = copytext(screen_loc, 1, findtext(screen_loc, ","))
			var/pixel_x = text2num(copytext(screen_x, findtext(screen_x, ":") + 1)) + grid_visual_offset_x + center_offset_x
			screen_x = copytext(screen_x, 1, findtext(screen_x, ":"))

			var/screen_y = copytext(screen_loc, findtext(screen_loc, ",") + 1)
			var/pixel_y = text2num(copytext(screen_y, findtext(screen_y, ":") + 1)) + grid_visual_offset_y + center_offset_y
			screen_y = copytext(screen_y, 1, findtext(screen_y, ":"))

			// Set item properties
			item.mouse_opacity = MOUSE_OPACITY_OPAQUE
			item.screen_loc = "[screen_x]:[pixel_x],[screen_y]:[pixel_y]"
			if(numerical_stacking)
				item.maptext = ""
			item.plane = ABOVE_HUD_PLANE

			// Apply rotation transform if item has one stored in grid storage
			if(item.grid_storage_transform)
				item.transform = item.grid_storage_transform
			else
				// Reset transform if no rotation stored
				item.transform = null

			// Apply visual underlay
			var/mutable_appearance/underlay = get_bound_underlay(item_width, item_height, item)
			if(!underlay)
				underlay = generate_bound_underlay(item_width, item_height, item)
			if(underlay && item.underlays)
				item.underlays.Cut()
				item.underlays += underlay

	// Update the close button position based on grid dimensions
	update_closer(rows, cols)

/**
 * Updates the close button position and appearance based on grid dimensions
 *
 * Positions the close button to the right of the grid and adjusts its appearance
 * to span multiple rows if needed. This is adapted from the old grid storage component.
 *
 * @param rows - Number of rows in the grid
 * @param cols - Number of columns in the grid
 */
/datum/storage/grid/proc/update_closer(rows = 0, cols = 0)
	closer.cut_overlays()
	closer.icon = 'icons/hud/storage.dmi'
	closer.icon_state = "close"

	var/half_rows = FLOOR((rows - 1) * 0.5, 1)
	var/half_row_ceil = CEILING((rows - 1) * 0.5, 1)

	var/extra = 0
	if(ISEVEN(rows))
		extra = 1

	// Position the close button to the right of the grid
	if(fixed_grid_origin)
		// Get the resolved origin to calculate the close button position
		var/list/origin = resolve_grid_origin()
		var/origin_x = origin[1]
		var/origin_pixel_x = origin[2]
		var/origin_y = origin[3]
		var/origin_pixel_y = origin[4]

		// Position close button to the right of the grid
		// Add grid_visual_offset_x to shift right by 32px
		// Calculate Y position to align with middle of grid
		var/close_x = origin_x + cols
		var/close_pixel_x = origin_pixel_x + grid_visual_offset_x

		// Calculate Y position - the grid grows downward from origin_y
		// Center the close button vertically: start at top of grid and move down by half the grid height
		// Grid top is at: origin_y - (rows - 1)
		// Grid center is at: origin_y - (rows - 1) + FLOOR((rows - 1) / 2, 1)
		// Simplified: origin_y - CEILING((rows - 1) / 2, 1)
		var/close_y = origin_y - CEILING((rows - 1) / 2, 1)
		var/close_pixel_y = origin_pixel_y + grid_visual_offset_y

		closer.screen_loc = "[close_x]:[close_pixel_x],[close_y]:[close_pixel_y]"
	else
		// Add grid_visual_offset_x to shift right by 32px
		// Add an additional 32px down shift
		var/close_pixel_x = screen_pixel_x + grid_visual_offset_x
		var/close_pixel_y = screen_pixel_y + grid_visual_offset_y - 32

		closer.screen_loc = "[screen_start_x + cols]:[close_pixel_x],[screen_start_y]:[close_pixel_y]"


	// Adjust icon state based on number of rows
	switch(rows)
		if(-INFINITY to 1)
			closer.icon_state = "close"
		if(2)
			closer.icon_state = "close_left"
		if(3 to INFINITY)
			closer.icon_state = "close_mid"

	// Add overlays for multi-row close buttons
	var/image/offset_image
	for(var/overlayer in 1 to half_rows)
		var/state = (overlayer >= half_rows) ? "close_right" : "close_mid"
		offset_image = image(closer.icon, state)
		offset_image.transform = offset_image.transform.Translate(0, world.icon_size * -overlayer)
		closer.add_overlay(offset_image)

	for(var/overlayer in 1 to half_row_ceil)
		var/state = (overlayer >= half_row_ceil) ? "close_left" : "close_mid"
		offset_image = image(closer.icon, state)
		offset_image.transform = offset_image.transform.Translate(0, world.icon_size * overlayer)
		closer.add_overlay(offset_image)

	if(rows > 1)
		var/image/close_overlay = image(closer.icon, "close_overlay")
		close_overlay.transform = close_overlay.transform.Translate(0, world.icon_size * ((((rows - 1) * 0.5) + extra) - (half_row_ceil)))
		closer.add_overlay(close_overlay)


/**
 * Grid Storage Screen Object
 *
 * A specialized screen object for grid-based storage that captures cursor position
 * information on hover and click events. This allows precise grid coordinate calculation
 * for item placement based on where the user clicks within the grid.
 */
/atom/movable/screen/storage/grid
	name = "grid storage"

/**
 * Override: Handles click events with grid coordinate tracking
 *
 * Captures the cursor position relative to the grid and passes it to the storage
 * datum for precise item placement at the clicked grid cell.
 *
 * @param location - The location parameter from the click
 * @param control - The control parameter from the click
 * @param params - Click parameters including icon-x, icon-y, and screen-loc
 * @return TRUE if handled, FALSE otherwise
 */
/atom/movable/screen/storage/grid/Click(location, control, params)

	// Check if this is a right-click BEFORE calling parent
	var/list/param_list = params2list(params)
	var/right_click = param_list["right"]

	var/obj/item/held_item = usr?.get_active_held_item()
	if(held_item && right_click)
		var/datum/storage/grid/storage_master = master_ref?.resolve()
		if(!istype(storage_master))
			return FALSE

		// Rotate the item, passing the grid storage reference so rotation is tracked
		held_item.inventory_flip(usr, FALSE, storage_master)

		// Immediately update phantom preview to show new dimensions
		storage_master.update_phantom_preview(held_item, params, usr)

		return TRUE

	// Now call parent for normal click handling
	if(..())
		return TRUE

	var/datum/storage/grid/storage_master = master_ref?.resolve()
	if(!istype(storage_master))
		return FALSE

	if(world.time <= usr.next_move)
		return TRUE
	if(usr.incapacitated())
		return TRUE
	if(ismecha(usr.loc))
		return TRUE

	if(held_item)
		// Clear phantom before inserting
		storage_master.clear_phantom_preview(usr)
		// Pass params to attempt_insert so it can extract cursor position
		// Signature: attempt_insert(to_insert, user, override, force, params)
		storage_master.attempt_insert(held_item, usr, FALSE, FALSE, params)

	return TRUE

/**
 * Override: Handles mouse drop events with grid coordinate tracking
 *
 * Captures the cursor position relative to the grid when an item is dropped
 * onto the grid, allowing precise placement at the drop location.
 *
 * @param dropping - The atom being dropped
 * @param user - The mob performing the drop
 * @param params - Drop parameters including icon-x, icon-y, and screen-loc
 * @return TRUE if handled, FALSE otherwise
 */
/atom/movable/screen/storage/grid/MouseDroppedOn(atom/dropping, mob/user, params)
	var/datum/storage/grid/storage_master = master_ref?.resolve()

	if(!istype(storage_master))
		return FALSE

	if(!isitem(dropping))
		return TRUE

	if(world.time <= user.next_move)
		return TRUE

	if(user.incapacitated())
		return TRUE

	if(ismecha(user.loc))
		return TRUE

	if(!dropping.IsReachableBy(user))
		return TRUE

	var/obj/item/I = dropping
	if(!(user.is_holding(I) || (I.item_flags & IN_STORAGE)))
		return TRUE

	// Pass params to attempt_insert so it can extract cursor position
	// Signature: attempt_insert(to_insert, user, override, force, params)
	storage_master.attempt_insert(dropping, user, FALSE, FALSE, params)

	return TRUE

/**
 * Override: Handles mouse hover events for grid coordinate preview
 *
 * Shows a phantom preview of the item being held, indicating where it will be placed
 * and whether the placement is valid (green underlay) or invalid (red underlay).
 *
 * @param location - The location parameter from the hover
 * @param control - The control parameter from the hover
 * @param params - Hover parameters including icon-x, icon-y, and screen-loc
 */
/atom/movable/screen/storage/grid/MouseEntered(location, control, params)
	. = ..()

	var/datum/storage/grid/storage_master = master_ref?.resolve()
	if(!istype(storage_master))
		return

	// Get the item the user is holding
	var/obj/item/held_item = usr?.get_active_held_item()
	if(!held_item)
		return

	// Update or create the phantom preview
	storage_master.update_phantom_preview(held_item, params, usr)

/**
 * Override: Handles mouse exit events to clean up phantom preview
 *
 * Removes the phantom preview when the cursor leaves the grid.
 *
 * @param location - The location parameter from the exit
 * @param control - The control parameter from the exit
 * @param params - Exit parameters
 */
/atom/movable/screen/storage/grid/MouseExited(location, control, params)
	. = ..()

	var/datum/storage/grid/storage_master = master_ref?.resolve()
	if(!istype(storage_master))
		return

	// Remove the phantom preview
	storage_master.clear_phantom_preview(usr)

/**
 * Override: Handles mouse movement within the grid
 *
 * Updates the phantom preview position as the cursor moves.
 *
 * @param location - The location parameter
 * @param control - The control parameter
 * @param params - Movement parameters including screen-loc
 */
/atom/movable/screen/storage/grid/MouseMove(location, control, params)
	. = ..()

	var/datum/storage/grid/storage_master = master_ref?.resolve()
	if(!istype(storage_master))
		return

	// Get the item the user is holding
	var/obj/item/held_item = usr?.get_active_held_item()
	if(!held_item)
		storage_master.clear_phantom_preview(usr)
		return

	// Update phantom position
	storage_master.update_phantom_preview(held_item, params, usr)
