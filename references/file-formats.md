# Fitness File Formats

## Overview

Strava supports three main fitness file formats for activity uploads. Each format has different capabilities and metadata support.

## FIT Format (.fit)

### Description
**FIT** (Flexible and Interoperable Data Transfer) is a binary format developed by Garmin for fitness devices. It's the most feature-rich format supported by Strava.

### Characteristics
- **Type:** Binary format
- **Extension:** `.fit`
- **Max Size:** 25MB
- **Compression:** None (already compact)
- **Metadata:** Extensive

### Supported Data
| Data Type | FIT Support | Notes |
|-----------|-------------|-------|
| GPS Tracks | ✅ Full | Latitude, longitude, elevation |
| Timestamps | ✅ Full | Millisecond precision |
| Heart Rate | ✅ Full | BPM data |
| Cadence | ✅ Full | Running cadence, cycling RPM |
| Power | ✅ Full | Cycling power in watts |
| Temperature | ✅ Full | Ambient temperature |
| Calories | ✅ Full | Estimated calories burned |
| Steps | ✅ Full | For running activities |
| Swimming | ✅ Full | Strokes, pool length |
| Device Info | ✅ Full | Manufacturer, model, serial |

### Advantages
1. **Most comprehensive** - Supports all data types
2. **Compact** - Binary format is space-efficient
3. **Standardized** - Widely adopted by fitness devices
4. **Rich metadata** - Includes device information

### Disadvantages
1. **Binary format** - Not human-readable
2. **Complex parsing** - Requires specialized libraries
3. **Proprietary** - Garmin-controlled specification

### Common Sources
- Garmin watches (Forerunner, Fenix, etc.)
- Garmin cycling computers (Edge series)
- Wahoo fitness devices
- Other ANT+/BLE compatible devices

## GPX Format (.gpx)

### Description
**GPX** (GPS Exchange Format) is an XML schema for GPS data. It's an open standard maintained by the GPS community.

### Characteristics
- **Type:** XML text format
- **Extension:** `.gpx`
- **Max Size:** 25MB
- **Compression:** Can be gzipped (.gpx.gz)
- **Metadata:** Basic

### Supported Data
| Data Type | GPX Support | Notes |
|-----------|-------------|-------|
| GPS Tracks | ✅ Full | `<trkpt>` elements |
| Timestamps | ✅ Basic | ISO 8601 format |
| Heart Rate | ⚠️ Limited | Via extensions |
| Cadence | ⚠️ Limited | Via extensions |
| Power | ❌ No | Not in standard |
| Elevation | ✅ Full | Included in track points |
| Waypoints | ✅ Full | Points of interest |
| Routes | ✅ Full | Planned paths |

### Advantages
1. **Human-readable** - XML format, easy to inspect
2. **Open standard** - Not proprietary
3. **Wide support** - Most GPS software can read/write
4. **Extensible** - Can add custom data via extensions

### Disadvantages
1. **Limited fitness data** - No native support for HR, power, etc.
2. **Verbose** - XML is less compact than binary
3. **Inconsistent extensions** - Device-specific extensions vary

### Common Sources
- Smartphone GPS apps (Strava, MapMyRun, etc.)
- Web-based route planners
- Older GPS devices
- Export from mapping software

## TCX Format (.tcx)

### Description
**TCX** (Training Center XML) is Garmin's XML-based format for storing fitness data, part of their Training Center software.

### Characteristics
- **Type:** XML text format
- **Extension:** `.tcx`
- **Max Size:** 25MB
- **Compression:** None typically
- **Metadata:** Moderate

### Supported Data
| Data Type | TCX Support | Notes |
|-----------|-------------|-------|
| GPS Tracks | ✅ Full | `<Trackpoint>` elements |
| Timestamps | ✅ Full | ISO 8601 format |
| Heart Rate | ✅ Full | `<HeartRateBpm>` element |
| Cadence | ✅ Full | Running cadence |
| Power | ✅ Limited | Cycling power (some devices) |
| Calories | ✅ Full | Estimated calories |
| Steps | ✅ Limited | Running metrics |
| Lap Data | ✅ Full | Split information |
| Device Info | ✅ Basic | Limited to Garmin devices |

### Advantages
1. **Good balance** - More data than GPX, readable like XML
2. **Garmin ecosystem** - Works well with Garmin devices
3. **Structured laps** - Good for interval training
4. **Heart rate support** - Native HR data support

### Disadvantages
1. **Garmin-centric** - Less support from other manufacturers
2. **Verbose** - XML format is larger than FIT
3. **Aging format** - Being replaced by FIT in newer devices

### Common Sources
- Garmin Training Center exports
- Older Garmin devices
- Some third-party apps
- Manual export from Garmin Connect

## Format Comparison

| Feature | FIT | GPX | TCX |
|---------|-----|-----|-----|
| **Format** | Binary | XML | XML |
| **Readability** | ❌ Hard | ✅ Easy | ✅ Easy |
| **File Size** | ✅ Small | ❌ Large | ❌ Large |
| **GPS Data** | ✅ Excellent | ✅ Good | ✅ Good |
| **Heart Rate** | ✅ Native | ⚠️ Extensions | ✅ Native |
| **Power Data** | ✅ Native | ❌ No | ⚠️ Limited |
| **Cadence** | ✅ Native | ⚠️ Extensions | ✅ Native |
| **Device Info** | ✅ Full | ❌ No | ⚠️ Limited |
| **Strava Support** | ✅ Best | ✅ Good | ✅ Good |

## Choosing the Right Format

### For Maximum Data Fidelity
**Use FIT format** when:
- Uploading from modern fitness devices
- You have heart rate, power, or cadence data
- You want all available metrics
- File size is a concern

### For Compatibility
**Use GPX format** when:
- Sharing routes with others
- Using non-Garmin devices
- Human inspection is needed
- Interoperability is important

### For Garmin Users
**Use TCX format** when:
- Exporting from Garmin Training Center
- You need lap/split information
- Heart rate data is important
- Working with older Garmin devices

## File Validation

### Basic Checks
```bash
# Check file type
file activity.fit
# Output: activity.fit: data (FIT file)

# Check file size
ls -lh activity.fit
# Output: -rw-r--r-- 1 user staff 2.4M Mar 30 22:41 activity.fit

# Check if file is valid (FIT specific)
python -c "import fitparse; fit = fitparse.FitFile('activity.fit'); print('Valid FIT file')"
```

### Size Limits
- **Strava Limit:** 25MB per file
- **Recommended:** <10MB for faster processing
- **Large files:** Consider splitting or compressing

## Conversion Tools

### FIT to GPX/TCX
```bash
# Using gpsbabel
gpsbabel -i garmin_fit -f input.fit -o gpx -F output.gpx
gpsbabel -i garmin_fit -f input.fit -o gtrnctr -F output.tcx

# Using Python (fitparse + gpxpy)
python fit_to_gpx.py input.fit output.gpx
```

### GPX to TCX
```bash
# Using gpsbabel
gpsbabel -i gpx -f input.gpx -o gtrnctr -F output.tcx
```

### Online Converters
- [GPS Visualizer](https://www.gpsvisualizer.com/convert_input)
- [FIT File Tools](https://www.fitfiletools.com/)
- [Strava GPX to TCX](https://www.strava.com/upload/select)

## Troubleshooting

### Common Issues

1. **"Invalid file format"**
   - Check file extension matches actual format
   - Try opening in a text editor (GPX/TCX should be readable)
   - Use `file` command to identify actual format

2. **"File too large"**
   - Compress with gzip: `gzip -9 activity.gpx`
   - Split into multiple activities
   - Reduce recording frequency on device

3. **Missing data after upload**
   - Check if format supports the data type
   - Verify device recorded the data
   - Try FIT format for maximum compatibility

4. **Duplicate activities**
   - Strava detects duplicates by file hash
   - Rename file doesn't help
   - Modify timestamp or add small GPS offset

### Debugging Tips

1. **View file contents:**
   ```bash
   # GPX/TCX
   head -50 activity.gpx
   
   # FIT (requires tools)
   fitdump activity.fit | head -100
   ```

2. **Check recording frequency:**
   - High frequency = larger files
   - 1-second recording is usually sufficient
   - Reduce to 5-10 seconds for long activities

3. **Validate before upload:**
   - Use Strava's web upload first
   - Check processing results
   - Then automate with API