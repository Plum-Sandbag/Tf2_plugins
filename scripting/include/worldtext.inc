#if defined _worldtext_included_
  #endinput
#endif
#define _worldtext_included_

enum WorldText_Font
{
	FONT_TF2_BULKY = 0,
	FONT_TF2_BULKY_NO_OUTLINE,
	FONT_TF2,
	FONT_TF2_NO_OUTLINE,
	FONT_LIBERATION_SANS,
	FONT_LIBERATION_SANS_NO_OUTLINE,
	FONT_TF2_PROFESSOR,
	FONT_TF2_PROFESSOR_NO_OUTLINE,
	FONT_ROBOTO_MONO,
	FONT_ROBOTO_MONO_NO_OUTLINE,
	FONT_ROBOTO_MONO_SHADOW_ONLY,
	FONT_ROBOTO_MONO_GREEN_GLOW,
	FONT_TF2_BULKY_SOFT_EDGES
};

enum WorldText_Orientation
{
	ORIENTATION_STATIONARY = 0,
	ORIENTATION_ALWAYS_FACE_PLAYER,
	ORIENTATION_IGNORE_PITCH
};

/**
 * Spawns a point_worldtext at the given coordinates.
 *
 * @param pos			The position to spawn the worldtext at.
 * @param ang			The angles to spawn the worldtext with (this does nothing unless orientation is set to ORIENTATION_STATIONARY).
 * @param message		The message displayed by the worldtext.
 * @param size			The size of the worldtext message.
 * @param xSpacing		The spacing between each letter on the X-axis.
 * @param ySpacing		The spacing between each letter on the Y-axis. Ignored if the message does not contain multiple lines (indicated by \n).
 * @param font			The font to be used.
 * @param r				The red value of the worldtext's color (0-255).
 * @param g				The green value of the worldtext's color (0-255).
 * @param b				The blue value of the worldtext's color (0-255).
 * @param a				The alpha value of the worldtext's color (0-255).
 * @param rainbow		If true, the text will be rainbow instead of using the values of R, G, and B.
 * @param orientation	The orientation of the text.
 *
 * @return		The entity index of the created point_worldtext, or -1 on failure.
 */
native int WorldText_Create(float pos[3], float ang[3], char[] message, float size, float xSpacing = 1.0, float ySpacing = 2.0, WorldText_Font font = FONT_TF2_BULKY, int r = 255, int g = 255, int b = 255, int a = 255, bool rainbow = false, WorldText_Orientation orientation = ORIENTATION_ALWAYS_FACE_PLAYER);

/**
 * Changes a point_worldtext's message.
 *
 * @param worldText			The point_worldtext to change.
 * @param newMessage		The message to set.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetMessage(int worldText, char[] newMessage);

/**
 * Changes a point_worldtext's size.
 *
 * @param worldText			The point_worldtext to change.
 * @param newSize		The size to set.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetSize(int worldText, float newSize);

/**
 * Changes a point_worldtext's X and/or Y spacing.
 *
 * @param worldText			The point_worldtext to change.
 * @param newXSpacing		The new X spacing to set.
 * @param applyXSPacing		True to apply the new X spacing, false to leave it unchanged.
 * @param newYSpacing		The new Y spacing to set.
 * @param applyYSpacing		True to apply the new Y spacing, false to leave it unchanged.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetSpacing(int worldText, float newXSpacing, bool applyXSpacing, float newYSpacing, bool applyYSpacing);

/**
 * Changes a point_worldtext's font.
 *
 * @param worldText			The point_worldtext to change.
 * @param newFont			The font to set.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetFont(int worldText, WorldText_Font newFont);

/**
 * Changes a point_worldtext's color.
 *
 * @param worldText			The point_worldtext to change.
 * @param r					The new color's R value.
 * @param g					The new color's G value.
 * @param b					The new color's B value.
 * @param a					The new color's A value.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetColor(int worldText, int r = 255, int g = 255, int b = 255, int a = 255);

/**
 * Enables or disables the rainbow effect of a given point_worldtext.
 *
 * @param worldText			The point_worldtext to change.
 * @param rainbow			True to activate the rainbow effect, false otherwise.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetRainbow(int worldText, bool rainbow);

/**
 * Changes a point_worldtext's orientation.
 *
 * @param worldText			The point_worldtext to change.
 * @param newOrientation	The orientation to set.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_SetOrientation(int worldText, WorldText_Orientation newOrientation);

/**
 * Attaches a point_worldtext to a given entity.
 *
 * @param worldText			The point_worldtext to attach.
 * @param targetEntity		The entity to be attached to.
 * @param attachmentPoint	The attachment point to attach the text to.
 * @param xOffset			X-axis offset from the attachment point, in hammer units.
 * @param yOffset			Y-axis offset from the attachment point, in hammer units.
 * @param zOffset			Z-axis offset from the attachment point, in hammer units.
 *
 * @error	Invalid entity index passed to worldText and/or targetEntity.
 */
native void WorldText_AttachToEntity(int worldText, int targetEntity, char[] attachmentPoint, float xOffset = 0.0, float yOffset = 0.0, float zOffset = 0.0);

/**
 * Detaches a point_worldtext from its parent, if it has one.
 *
 * @param worldText			The point_worldtext to detach.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_Detach(int worldText);

/**
 * Causes a point_worldtext entity to gradually fade out and float upwards, similar to the numbers that appear when you hit a player.
 * The text entity will automatically be removed if its alpha falls to 0.
 *
 * @param worldText			The point_worldtext to fade out.
 * @param fadeDelay			The time until the text's alpha begins to fade.
 * @param fadeRate			Alpha lost per frame once fade begins.
 * @param upRate			The rate at which the text floats up.
 *
 * @error	Invalid entity index passed to worldText.
 */
native void WorldText_MimicHitNumbers(int worldText, float fadeDelay = 1.5, float fadeRate = 6.0, float upRate = 1.0);