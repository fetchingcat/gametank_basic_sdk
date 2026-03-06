/**
 * midiconvert.js - MIDI to GameTank song converter (adapted from C SDK)
 *
 * Converts MIDI files to XC-BASIC3 DATA AS BYTE statements or binary .bin.
 * Based on gametank_sdk/scripts/converters/midiconvert.js with added
 * DATA AS BYTE output for the BASIC SDK.
 *
 * Requires: npm install midi-file
 *
 * Usage:
 *   node midiconvert.js <input.mid> [options]
 *
 * Options:
 *   -o <file>           Output file (default: stdout for basic, .bin for binary)
 *   --format basic|bin  Output format (default: basic)
 *   --instruments 3,0,0,0   Comma-separated instrument IDs (default: 0,0,0,0)
 *   --label <name>      DATA label name (default: derived from filename)
 *   --velocity          Include velocity data
 *   --info              Print MIDI info and exit
 *
 * Instrument IDs (1-indexed to match C SDK):
 *   piano=1, guitar=2, guitar2=3, slapbass=4,
 *   snare=5, sitar=6, horn=7
 */

const fs = require("fs");
const parseMidi = require("midi-file").parseMidi;
const path = require("path");

// --- Argument parsing ---

function parseArgs(argv) {
    const args = {
        input: null,
        output: null,
        format: "basic",
        instruments: [1, 1, 1, 1],  // piano on all channels (1-indexed)
        label: null,
        useVelocity: false,
        info: false,
    };

    let i = 2; // skip node and script path
    while (i < argv.length) {
        const arg = argv[i];
        if (arg === "-o" || arg === "--output") {
            args.output = argv[++i];
        } else if (arg === "--format" || arg === "-f") {
            args.format = argv[++i];
        } else if (arg === "--instruments" || arg === "-i") {
            args.instruments = argv[++i].split(",").map((s) => {
                const names = { piano:1, guitar:2, guitar2:3, slapbass:4, snare:5, sitar:6, horn:7 };
                s = s.trim();
                return names[s.toLowerCase()] !== undefined ? names[s.toLowerCase()] : parseInt(s, 10);
            });
            while (args.instruments.length < 4) args.instruments.push(0);
        } else if (arg === "--label" || arg === "-l") {
            args.label = argv[++i];
        } else if (arg === "--velocity" || arg === "-v") {
            args.useVelocity = true;
        } else if (arg === "--info") {
            args.info = true;
        } else if (!arg.startsWith("-")) {
            args.input = arg;
        }
        i++;
    }
    return args;
}

const args = parseArgs(process.argv);

if (!args.input) {
    console.error("Usage: node midiconvert.js <input.mid> [options]");
    console.error("  --info              Print MIDI info and exit");
    console.error("  --format basic|bin  Output format (default: basic)");
    console.error("  --instruments 3,0,0,0  Instrument IDs or names");
    console.error("  --label <name>      DATA label name");
    console.error("  --velocity          Include velocity data");
    console.error("  -o <file>           Output file");
    process.exit(1);
}

// --- MIDI parsing (unchanged from C SDK) ---

const SongFlags = {
    useVelocity: 1,
};

var inputFile = fs.readFileSync(args.input);
var parsedInput = parseMidi(inputFile);

var bytesPerNote = 1;
if (args.useVelocity) bytesPerNote++;

var microsecondsPerFrame = 16666.666667;

// --- Info mode ---

if (args.info) {
    const header = parsedInput.header;
    console.log(`File:           ${args.input}`);
    console.log(`Format:         ${header.format}`);
    console.log(`Tracks:         ${header.numTracks}`);
    console.log(`Ticks/beat:     ${header.ticksPerBeat}`);

    const channelNotes = {};
    parsedInput.tracks.forEach((track) => {
        track.forEach((evt) => {
            if (evt.type === "noteOn" && evt.velocity > 0) {
                channelNotes[evt.channel] = (channelNotes[evt.channel] || 0) + 1;
            }
        });
    });

    const channels = Object.keys(channelNotes).map(Number).sort((a, b) => a - b);
    console.log(`Channels used:  [${channels.join(", ")}]`);
    channels.forEach((ch) => {
        console.log(`  Channel ${ch}: ${channelNotes[ch]} notes`);
    });
    if (channels.some((ch) => ch > 3)) {
        console.log(`Warning: channels > 3 will be ignored (GameTank supports 4 channels)`);
    }
    process.exit(0);
}

// --- Merge tracks and compute absolute frame times ---

var mergedTracks = [];
var tempo = 120;

parsedInput.tracks.forEach((track, i) => {
    var absTime = 0;

    track.forEach((trackEvent) => {
        if (trackEvent.type == "setTempo") {
            tempo = 60000000 / trackEvent.microsecondsPerBeat;
        }

        absTime +=
            (trackEvent.deltaTime * 60000000) /
            (tempo * parsedInput.header.ticksPerBeat);
        trackEvent.absTime = absTime;
        trackEvent.absFrames = Math.floor(absTime / microsecondsPerFrame);
        trackEvent.trackNum = i;
    });
    mergedTracks = mergedTracks.concat(track);
});

mergedTracks.sort((a, b) => a.absFrames - b.absFrames);

var lastAbsTime = mergedTracks[0].absFrames;
mergedTracks.forEach((event) => {
    event.deltaTime = event.absFrames - lastAbsTime;
    lastAbsTime = event.absFrames;
});

// --- Group into time buckets ---

var timeBucketedTracks = [];
var currentBucket = [];
lastAbsTime = 0;

mergedTracks.forEach((event) => {
    if (event.absFrames > lastAbsTime) {
        timeBucketedTracks.push(currentBucket);
        currentBucket = [];
        lastAbsTime = event.absFrames;
    }
    currentBucket.push(event);
});

if (currentBucket.length > 0) {
    timeBucketedTracks.push(currentBucket);
}

timeBucketedTracks.forEach((bucket) => {
    bucket.sort((a, b) => a.absTime - b.absTime);
});

// --- Build frame buffers (unchanged C SDK logic) ---

var frameBuffers = timeBucketedTracks.map((bucket) => {
    var frame = {};
    var deltaTime = 0;
    bucket.forEach((event) => {
        if (event.deltaTime > 0) {
            deltaTime = event.deltaTime;
        }
        if (event.type == "noteOn" || event.type == "noteOff") {
            frame[event.channel] = {
                note: event.type == "noteOn" ? event.noteNumber : 0,
                type: event.type,
                channel: event.channel,
                velocity: event.velocity,
            };
        }
    });
    var noteCount = 0;
    var noteMask = 0;
    var tracks = [];
    for (var i in frame) {
        if (frame[i].channel > 3) continue;
        noteCount++;
        noteMask |= 1 << frame[i].channel;
        tracks.push(i);
    }
    tracks.sort();
    var extraTime = 0;
    if (deltaTime > 255) {
        extraTime = deltaTime - 255;
        deltaTime = 255;
    }
    var frameBuf = Buffer.alloc(
        bytesPerNote * noteCount + 2 + 2 * Math.ceil(extraTime / 128)
    );
    var offset = 0;
    while (extraTime > 0) {
        frameBuf.writeUint8(Math.min(128, extraTime), offset++);
        frameBuf.writeUint8(0, offset++);
        extraTime -= 128;
    }
    frameBuf.writeUint8(deltaTime, offset++);
    frameBuf.writeUint8(noteMask, offset++);
    tracks.forEach((n) => {
        frameBuf.writeUint8(frame[n].note, offset++);
        if (args.useVelocity) {
            frameBuf.writeUint8(
                Math.round(frame[n].velocity * (6 / 8)),
                offset++
            );
        }
    });
    return frameBuf;
});

// --- Build final song byte array ---

var songConfigHeader = 0;
if (args.useVelocity) {
    songConfigHeader |= SongFlags.useVelocity;
}

// Assemble all bytes into a single array
var allBytes = [];

// Config byte
allBytes.push(songConfigHeader);

// 4 instrument bytes
for (var idx = 0; idx < 4; idx++) {
    allBytes.push(args.instruments[idx] || 0);
}

// Event data from frame buffers
frameBuffers.forEach((buf) => {
    for (var j = 0; j < buf.length; j++) {
        allBytes.push(buf[j]);
    }
});

// Single-byte terminator: delay=0 means end-of-song (matches C SDK)
allBytes.push(0);

// --- Output ---

// Derive label
var label = args.label;
if (!label) {
    var base = path.basename(args.input, path.extname(args.input));
    label = base.replace(/[^a-zA-Z0-9_]/g, "_") + "_song";
}

// Print summary to stderr
console.error(`Converted: ${args.input}`);
console.error(`Size:      ${allBytes.length} bytes`);
console.error(`Label:     ${label}`);

if (args.format === "bin") {
    // Binary output
    var outputFilename = args.output || (path.basename(args.input, path.extname(args.input)) + ".bin");
    var outBuf = Buffer.from(allBytes);
    fs.writeFileSync(outputFilename, outBuf);
    console.error(`Written:   ${outputFilename}`);
} else {
    // DATA AS BYTE output
    var lines = [];
    lines.push(label + ":");

    for (var i = 0; i < allBytes.length; i += 16) {
        var chunk = allBytes.slice(i, i + 16);
        var hexVals = chunk
            .map((b) => "$" + b.toString(16).toUpperCase().padStart(2, "0"))
            .join(", ");
        lines.push("DATA AS BYTE " + hexVals);
    }

    var output = lines.join("\n") + "\n";

    if (args.output) {
        fs.writeFileSync(args.output, output);
        console.error(`Written:   ${args.output}`);
    } else {
        process.stdout.write(output);
    }
}
