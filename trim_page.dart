import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/NewPages/bloc/event.dart';
import 'package:client/NewPages/bloc/manager.dart';
import 'package:client/NewPages/bloc/state.dart';
import 'package:process_run/shell.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class TrimPage extends StatefulWidget {
  final String videoPath;

  const TrimPage(this.videoPath, {super.key});

  @override
  State createState() => _TrimPageState();
}

class _TrimPageState extends State<TrimPage> {
  late VideoPlayerController _controller;
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isVideoLoaded = false;
  bool _isPlaying = false;
  bool _isTrimming = false;
  String _ffmpegPath = 'ffmpeg'; // Default path

  @override
  void initState() {
    super.initState();
    _loadVideo();
    _checkFFmpegPath();
  }

  Future<void> _checkFFmpegPath() async {
    try {
      // Try to detect FFmpeg in common locations
      final possiblePaths = [
        'ffmpeg',
        'C:\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe',
      ];

      for (final testPath in possiblePaths) {
        try {
          final shell = Shell();
          await shell.run('$testPath -version');
          setState(() => _ffmpegPath = testPath);
          print('Found FFmpeg at: $testPath');
          return;
        } catch (e) {
          // Continue trying other paths
        }
      }

      print('FFmpeg not found in common locations');
    } catch (e) {
      print('Error checking FFmpeg: $e');
    }
  }

  Future<void> _loadVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    await _controller.initialize().then((_) {
      setState(() {
        _isVideoLoaded = true;
        _endValue = _controller.value.duration.inMilliseconds.toDouble();
        // Add a listener to update the UI when video position changes
        _controller.addListener(_videoListener);
      });
    }).catchError((error) {
      print("Video loading error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: $error')),
      );
    });
  }

  void _videoListener() {
    // Only update if the video is playing
    if (_controller.value.isPlaying) {
      final currentPosition = _controller.value.position.inMilliseconds.toDouble();

      // Check if video reached the end trimming point
      if (currentPosition >= _endValue) {
        _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
        if (_isPlaying) {
          _controller.play();
        }
      }

      // Update UI when position changes
      setState(() {});
    }
  }

  void _playPauseVideo() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        // If at the end, restart from the beginning of the trimmed section
        if (_controller.value.position.inMilliseconds >= _endValue) {
          _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
        }
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _seekToPosition(double position) {
    final seekPosition = position.clamp(_startValue, _endValue);
    _controller.seekTo(Duration(milliseconds: seekPosition.toInt()));
  }

  Future<String> _getOutputPath() async {
    // Determine the file extension from the source video
    final extension = path.extension(widget.videoPath).toLowerCase();
    final directory = Directory.systemTemp.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Use the same extension as the input file, or fallback to .mp4 if no extension found
    final fileExtension = extension.isNotEmpty ? extension : '.mp4';
    return '$directory/trimmed_video_$timestamp$fileExtension';
  }

  Future<void> _showFFmpegPathDialog() async {
    final TextEditingController textController = TextEditingController(text: _ffmpegPath);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FFmpeg Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'FFmpeg was not found in your system PATH. Please enter the full path to the FFmpeg executable:',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'e.g., C:\\ffmpeg\\bin\\ffmpeg.exe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can download FFmpeg from https://ffmpeg.org/download.html',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _ffmpegPath = textController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTrimmedVideo() async {
    if (_endValue <= _startValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid trim range')),
      );
      return;
    }

    // Check if FFmpeg is available
    try {
      final shell = Shell();
      await shell.run('$_ffmpegPath -version');
    } catch (e) {
      await _showFFmpegPathDialog();
      return;
    }

    setState(() => _isTrimming = true);

    final start = Duration(milliseconds: _startValue.toInt());
    final end = Duration(milliseconds: _endValue.toInt());
    final duration = end - start;

    final outputPath = await _getOutputPath();
    final command =
        '$_ffmpegPath -ss ${start.inSeconds} -i "${widget.videoPath}" -t ${duration.inSeconds} -c copy "$outputPath"';

    try {
      final shell = Shell();
      await shell.run(command);

      setState(() => _isTrimming = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video trimmed successfully to $outputPath')),
      );
      context.read<AppBloc>().add(TrimCompleted(outputPath));
    } catch (e) {
      setState(() => _isTrimming = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error trimming video: $e')),
      );
    }
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showFFmpegPathDialog,
            tooltip: 'Set FFmpeg path',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_isVideoLoaded)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 300,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 50.0,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: _playPauseVideo,
                    ),
                  ],
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 10),

              // Video progress indicator
              if (_isVideoLoaded)
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).primaryColor,
                    bufferedColor: Theme.of(context).primaryColorLight,
                    backgroundColor: Colors.grey,
                  ),
                ),

              const SizedBox(height: 20),

              // Trim range display
              if (_isVideoLoaded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start: ${_formatDuration(_startValue)}'),
                    Text('End: ${_formatDuration(_endValue)}'),
                  ],
                ),

              const SizedBox(height: 10),

              // Trim range slider
              if (_isVideoLoaded)
                RangeSlider(
                  values: RangeValues(_startValue, _endValue),
                  min: 0,
                  max: _controller.value.duration.inMilliseconds.toDouble(),
                  divisions: (_controller.value.duration.inMilliseconds ~/ 100).clamp(1, 1000),
                  labels: RangeLabels(
                    _formatDuration(_startValue),
                    _formatDuration(_endValue),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _startValue = values.start;
                      _endValue = values.end;

                      // Seek to start position when adjusting the range
                      _seekToPosition(_startValue);
                    });
                  },
                ),

              const SizedBox(height: 20),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isVideoLoaded ? () => _seekToPosition(_startValue) : null,
                    icon: const Icon(Icons.skip_previous),
                    label: const Text('Start'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isVideoLoaded ? _playPauseVideo : null,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isVideoLoaded ? () => _seekToPosition(_endValue) : null,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('End'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isVideoLoaded && !_isTrimming ? _saveTrimmedVideo : null,
                child: _isTrimming
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Processing...'),
                  ],
                )
                    : const Text('Save Trimmed Video'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }
}