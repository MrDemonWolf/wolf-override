import { crc32, deflateRawSync } from 'node:zlib';

/*
 * A minimal, deterministic ZIP writer for the press kit (scripts/build-press-kit.ts). Deterministic
 * means the same files always give the same bytes: every entry carries one fixed timestamp and no
 * extra fields, so the committed zip can be checked for drift by rebuilding it and comparing bytes.
 * The docs app has no ZIP dependency and the `zip` command stamps each file's modification time,
 * which differs per clone, so neither can make a byte-stable archive.
 * Format: PKWARE APPNOTE 6.3.10 (local headers, central directory, end record); no ZIP64, so the
 * archive and each file must stay under 4 GiB, far above the press kit's 25 MB budget.
 */

/** One file in the archive: its path inside the zip (forward slashes, no leading slash) and its bytes. */
export type ZipEntry = { name: string; data: Uint8Array };

// 1 January 2026, 00:00, in MS-DOS date and time format; a fixed stamp keeps the bytes stable.
const dosTime = 0;
const dosDate = ((2026 - 1980) << 9) | (1 << 5) | 1;

// General-purpose flag bit 11: the file names are UTF-8.
const utf8Flag = 0x0800;

/**
 * Builds a ZIP archive of `entries`, in the given order. Each file is deflated, or stored when
 * deflating would not make it smaller (PNG and WebP are already compressed). Throws on an empty or
 * duplicate name, or one with a backslash or leading slash, which unzip tools treat inconsistently.
 */
export function buildZip(entries: ZipEntry[]): Buffer {
  const locals: Buffer[] = [];
  const centrals: Buffer[] = [];
  const seen = new Set<string>();
  let offset = 0;
  for (const { name, data } of entries) {
    if (!name || name.startsWith('/') || name.includes('\\') || seen.has(name)) throw new Error(`Bad or duplicate zip entry name: "${name}"`);
    seen.add(name);
    const nameBytes = Buffer.from(name, 'utf8');
    const deflated = deflateRawSync(data, { level: 9 });
    const stored = deflated.length >= data.length;
    const body = stored ? Buffer.from(data) : deflated;
    const crc = crc32(data);

    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0); // local file header signature
    local.writeUInt16LE(20, 4); // version needed to extract: 2.0 (deflate)
    local.writeUInt16LE(utf8Flag, 6);
    local.writeUInt16LE(stored ? 0 : 8, 8); // method: 0 stored, 8 deflate
    local.writeUInt16LE(dosTime, 10);
    local.writeUInt16LE(dosDate, 12);
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(body.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(nameBytes.length, 26);
    local.writeUInt16LE(0, 28); // no extra field
    locals.push(local, nameBytes, body);

    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0); // central directory header signature
    central.writeUInt16LE(20, 4); // version made by: 2.0, MS-DOS attributes
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(utf8Flag, 8);
    central.writeUInt16LE(stored ? 0 : 8, 10);
    central.writeUInt16LE(dosTime, 12);
    central.writeUInt16LE(dosDate, 14);
    central.writeUInt32LE(crc, 16);
    central.writeUInt32LE(body.length, 20);
    central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(nameBytes.length, 28);
    // Extra field and comment lengths, disk number and internal and external attributes stay 0.
    central.writeUInt32LE(offset, 42); // where this file's local header starts
    centrals.push(central, nameBytes);

    offset += local.length + nameBytes.length + body.length;
  }
  const directory = Buffer.concat(centrals);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0); // end of central directory signature
  end.writeUInt16LE(entries.length, 8); // entries on this disk
  end.writeUInt16LE(entries.length, 10); // entries in total
  end.writeUInt32LE(directory.length, 12);
  end.writeUInt32LE(offset, 16); // where the central directory starts
  return Buffer.concat([...locals, directory, end]);
}
