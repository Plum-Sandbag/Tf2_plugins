/**
 * Get a sound's duration (does not read VPKs)
 *
 * @param       Path to file
 * @return      Length in seconds
 */
native int SMFFMPEG_GetSoundDuration(char[] file);

/**
 * Flush the sound duration cache
 */
native void SMFFMPEG_FlushSoundDurationCache();
