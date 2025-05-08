# Roland SVD Backup Tool (v5)

A utility for unpacking and repacking backup files from Roland synthesizers using the SVD format (version 5).
This program can be compiled using a [Free Pascal](https://www.freepascal.org) compiler.

## Features

- Easily copy, replace, or move components within a backup.
- Tested with:
  - Roland SH-4d
  - Roland JD-08
- May also work with other Roland synthesizers that use the same version of the SVD encoding (basic protection is included to prevent use with incompatible versions)

## ⚠️ Warning

**Use with great care!**

Before using this utility for real tasks, perform the following safety check:

1. Unpack a backup file from your synthesizer.
2. Repack it immediately without making any changes.
3. Compare the original and resulting files.

If they match exactly, the utility is safe to use with your backup.

## Unpacking

To unpack a backup file, run:

```
svd5tool unpack <input.svd>
```

Numbered files representing individual backup components will be created in the current folder.
These components can be copied and moved between backups of the same synthesizer model.

**Note:** When rearranging the positions of subordinate blocks and links within tracks may become inconsistent. This will not damage the device, but connections between track elements may be disrupted.

A checksum in the format `[xxxx]` is included at the end of each file name to quickly compare file identity.
The part of the filename after the `-` symbol is arbitrary and added for convenience only.

## Repacking

After rearranging the elements as needed, repack the backup:

```
svd5tool pack <output.svd>
```

Make sure that the size of the resulting file matches the original.
You can now upload the file to the synthesizer.
