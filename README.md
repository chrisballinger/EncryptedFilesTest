# Encrypted Files Test

This is a quick hack / example of using [RNCryptor](https://github.com/RNCryptor/RNCryptor) and [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) to serve encrypted media files on the fly.

From my experiments, it appears that mp4/mov files cannot be served via this method even when using mov files created with "fast start" hinting. MP3 files are troublesome as well because they appear to play, but do not support seeking so it shows as a "live" broadcast and may be frustrating to end users. JPG files work.

Because RNCryptor's current implementation only allows for sequential decryption (no seeking within a file) we need to serve chunked HTTP responses and cannot serve arbitrary HTTP byte ranges. This limitation seems to cause problems for the built-in iOS media player, QuickTime, and VLC.

The RNCryptor v3 format uses AES-CBC so it is technically possible to decrypt arbitrary byte ranges but would require significant work to modify the existing library to support this functionality.